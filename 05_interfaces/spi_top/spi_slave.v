/*******************************************************************************
 * Module: spi_slave.v                                                         *
 * Description: System-clocked SPI slave for modes 0-3 with full-duplex        *
 *              MSB-first transfers and transaction completion signaling.      *
 * File Created: Tuesday, 28th July 2026 11:44:27 am                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 28th July 2026 1:48:58 pm                           *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

// Design note:
//   spi_slave does NOT use sclk/cs_n as flip-flop clocks.
//   Instead, it samples them every system-clock cycle using sclk_d / cs_n_d
//   (one-cycle delayed copies) to detect edges — an "edge detector" pattern.
//   This keeps the entire module in the system-clock domain and avoids all
//   clock-domain-crossing (CDC) hazards.

`timescale 1ns/1ps

module spi_slave #(
    parameter integer DATA_WIDTH = 8,   // bits per transfer (each direction)
    parameter integer CPOL       = 0,   // must match master's CPOL
    parameter integer CPHA       = 0    // must match master's CPHA
) (
    input  wire                  clk,       // system clock (same domain as spi_top)
    input  wire                  rst_n,     // active-low synchronous reset
    input  wire                  sclk,      // SPI clock from master (treated as data)
    input  wire                  cs_n,      // chip select from master, active-low
    input  wire                  mosi,      // serial data from master
    input  wire [DATA_WIDTH-1:0] tx_data,   // word slave sends on MISO (latched at CS↓)
    output reg                   miso,      // serial data to master
    output reg                   busy,      // HIGH while CS_N is asserted
    output reg                   done,      // 1-cycle pulse when transaction ends (CS↑)
    output reg  [DATA_WIDTH-1:0] rx_data    // received word (valid at done pulse)
);

    // -------------------------------------------------------------------------
    // Localparams
    // -------------------------------------------------------------------------

    // Minimum bit-width to count 0..(DATA_WIDTH-1)
    localparam integer   BIT_BITS     = (DATA_WIDTH < 2) ? 1 : $clog2(DATA_WIDTH);

    // Width-typed constants for width-clean comparisons (avoids WIDTHEXPAND warnings)
    // Truncation is safe: DATA_WIDTH-1 always fits in BIT_BITS bits by clog2 construction
    // verilator lint_off WIDTHTRUNC
    localparam [BIT_BITS-1:0] BIT_MAX      = DATA_WIDTH - 1;  // max value of bit_index
    localparam [BIT_BITS-1:0] BIT_ADDR_MAX = DATA_WIDTH - 1;  // MSB index for bit addressing
    // verilator lint_on WIDTHTRUNC

    // SCLK resting level matches master's CPOL
    localparam SCLK_IDLE = CPOL[0];

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------

    reg sclk_d;                     // sclk delayed by 1 system clock (for edge detection)
    reg cs_n_d;                     // cs_n delayed by 1 system clock (for edge detection)
    reg [DATA_WIDTH-1:0] tx_latched; // tx_data snapshot taken at CS↓
    reg [DATA_WIDTH-1:0] rx_shift;   // accumulates incoming MOSI bits
    reg [BIT_BITS-1:0]   bit_index;  // current bit position (0 = MSB)

    // -------------------------------------------------------------------------
    // Edge detector — combinational
    //   Compare current value vs. one-cycle-old value to find transitions.
    //   All four events are used as triggers inside the sequential block.
    // -------------------------------------------------------------------------

    wire cs_falling;        // CS_N: 1→0 (master selects slave — start of transaction)
    wire cs_rising;         // CS_N: 0→1 (master deselects slave — end of transaction)
    wire leading_edge;      // SCLK: idle→active edge (first edge of each SCLK cycle)
    wire trailing_edge;     // SCLK: active→idle edge (second edge of each SCLK cycle)

    assign cs_falling    = cs_n_d && !cs_n;                                // was HIGH, now LOW
    assign cs_rising     = !cs_n_d && cs_n;                                // was LOW, now HIGH
    assign leading_edge  = !cs_n && (sclk_d == SCLK_IDLE) && (sclk != SCLK_IDLE); // idle→active
    assign trailing_edge = !cs_n && (sclk_d != SCLK_IDLE) && (sclk == SCLK_IDLE); // active→idle

    // -------------------------------------------------------------------------
    // Helper functions (same pattern as spi_master for consistency)
    // -------------------------------------------------------------------------

    // Return bit at position `index` from the MSB end (index 0 = MSB)
    function tx_bit;
        input [DATA_WIDTH-1:0] word;
        input [BIT_BITS-1:0] index;
        begin
            tx_bit = word[BIT_ADDR_MAX - index];
        end
    endfunction

    // Insert `sample` into position `index` (from MSB) of `word`; return updated word.
    // In Verilog-2001 a function "returns" by assigning to the function name itself.
    // verilator lint_off BLKSEQ
    function [DATA_WIDTH-1:0] rx_insert;
        input [DATA_WIDTH-1:0] word;
        input [BIT_BITS-1:0] index;
        input sample;
        reg [DATA_WIDTH-1:0] updated;
        begin
            updated = word;
            updated[BIT_ADDR_MAX - index] = sample;
            rx_insert = updated;         // return value
        end
    endfunction
    // verilator lint_on BLKSEQ

    // -------------------------------------------------------------------------
    // Sequential logic — single always block, system-clock domain
    // -------------------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            // Return all outputs and internal state to a known idle condition
            sclk_d     <= SCLK_IDLE;
            cs_n_d     <= 1'b1;
            tx_latched <= {DATA_WIDTH{1'b0}};
            rx_shift   <= {DATA_WIDTH{1'b0}};
            rx_data    <= {DATA_WIDTH{1'b0}};
            bit_index  <= 0;
            miso       <= 1'b0;
            busy       <= 1'b0;
            done       <= 1'b0;
        end else begin
            // Update the one-cycle-delayed copies every tick (feeds edge detectors)
            sclk_d <= sclk;
            cs_n_d <= cs_n;
            done   <= 1'b0;     // done is a 1-cycle pulse; clear by default

            // -----------------------------------------------------------------
            // CS_N falling: master just selected this slave — begin transaction
            // -----------------------------------------------------------------
            if (cs_falling) begin
                tx_latched <= tx_data;              // snapshot tx_data; safe to change it after
                rx_shift   <= {DATA_WIDTH{1'b0}};  // clear receive accumulator
                bit_index  <= 0;
                busy       <= 1'b1;

                // CPHA=0: pre-drive MSB on MISO now, before the first SCLK edge
                // CPHA=1: MISO will be updated on the first leading edge itself
                miso <= (CPHA == 0) ? tx_bit(tx_data, 0) : 1'b0;

            // -----------------------------------------------------------------
            // CS_N rising: master deselected — commit received word, signal done
            // -----------------------------------------------------------------
            end else if (cs_rising) begin
                rx_data <= rx_shift;    // make the completed word available to user logic
                miso    <= 1'b0;        // release MISO
                busy    <= 1'b0;
                done    <= 1'b1;        // 1-cycle completion pulse

            // -----------------------------------------------------------------
            // Mid-transaction: CS_N still asserted — process SCLK edges
            // -----------------------------------------------------------------
            end else if (!cs_n) begin

                // --- Leading edge: first edge of each SCLK cycle ---
                if (leading_edge) begin
                    if (CPHA == 0)
                        // Mode 0/2: sample MOSI on leading edge (RX)
                        rx_shift <= rx_insert(rx_shift, bit_index, mosi);
                    else
                        // Mode 1/3: drive MISO on leading edge (TX shift-out)
                        miso <= tx_bit(tx_latched, bit_index);
                end

                // --- Trailing edge: second edge of each SCLK cycle ---
                if (trailing_edge) begin
                    if (CPHA != 0)
                        // Mode 1/3: sample MOSI on trailing edge (RX)
                        rx_shift <= rx_insert(rx_shift, bit_index, mosi);

                    // Advance to next bit (if not the last one)
                    if (bit_index < BIT_MAX) begin
                        bit_index <= bit_index + 1'b1;

                        if (CPHA == 0)
                            // Mode 0/2: pre-drive next MISO bit before next leading edge
                            miso <= tx_bit(tx_latched, bit_index + 1'b1);
                        // Mode 1/3: next MISO bit will be driven on the next leading edge
                    end
                    // Last bit (bit_index == DATA_WIDTH-1): no advance; wait for CS↑
                end

            end
        end
    end

endmodule
