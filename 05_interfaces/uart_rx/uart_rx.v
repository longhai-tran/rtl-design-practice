/*******************************************************************************
 * Module: uart_rx.v                                                           *
 * Description: Parameterized UART receiver with input synchronization,       *
 *              center sampling, 8N1 framing, and framing-error detection.    *
 * File Created: Tuesday, 21st July 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 22nd July 2026                                      *
 * Modified By: Long Hai                                                       *
 *******************************************************************************/


`timescale 1ns/1ps

module uart_rx #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE   = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        rx_busy,
    output reg        rx_done_valid,
    output reg        framing_error
);

    // Round to the nearest integer number of clocks per UART bit — identical formula to uart_tx.
    localparam integer CLKS_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;
    // Guard: if CLKS_PER_BIT is 1 (very low ratio), HALF_BIT must be at least 1 to avoid
    // a zero-count start-validation window that would skip the start-bit check entirely.
    localparam integer HALF_BIT     = (CLKS_PER_BIT < 2) ? 1 : (CLKS_PER_BIT / 2);

    localparam [2:0] STATE_IDLE      = 3'd0;
    localparam [2:0] STATE_START     = 3'd1;
    localparam [2:0] STATE_DATA      = 3'd2;
    localparam [2:0] STATE_STOP      = 3'd3;
    localparam [2:0] STATE_WAIT_IDLE = 3'd4;

    reg       rx_meta;
    reg       rx_sync;
    reg [2:0] state;
    reg [2:0] bit_index;
    reg [7:0] data_shift;
    integer   baud_count; // TODO: replace with [$clog2(CLKS_PER_BIT)-1:0] for tighter area

    // Two-FF synchronizer: rx_meta absorbs metastability; all FSM logic reads rx_sync.
    // rx defaults HIGH (UART idle/mark state) so reset releases into a valid idle condition.
    always @(posedge clk) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;      // stage 1 — may be metastable
            rx_sync <= rx_meta; // stage 2 — stable for FSM use
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state         <= STATE_IDLE;
            bit_index     <= 3'd0;
            data_shift    <= 8'h00;
            data_out      <= 8'h00;
            baud_count    <= 0;
            rx_busy       <= 1'b0;
            rx_done_valid <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            rx_done_valid <= 1'b0;
            framing_error <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    rx_busy    <= 1'b0; // [FRAME: IDLE] — line HIGH, waiting for start
                    baud_count <= 0;
                    bit_index  <= 3'd0;

                    if (!rx_sync) begin          // [FRAME: START BIT detected] — HIGH→LOW edge
                        rx_busy <= 1'b1;
                        state   <= STATE_START;  // begin half-bit wait before center sample
                    end
                end

                STATE_START: begin
                    if (baud_count == (HALF_BIT - 1)) begin // wait half a bit period
                        baud_count <= 0;

                        if (!rx_sync) begin          // [FRAME: START valid] — still LOW at center
                            state <= STATE_DATA;     // commit to receiving data bits
                        end else begin               // [FRAME: false start] — glitch; abort
                            rx_busy <= 1'b0;
                            state   <= STATE_IDLE;
                        end
                    end else begin
                        baud_count <= baud_count + 1; // hold in start-validation window
                    end
                end

                STATE_DATA: begin
                    if (baud_count == (CLKS_PER_BIT - 1)) begin // sample at bit center
                        baud_count            <= 0;
                        data_shift[bit_index] <= rx_sync; // [FRAME: D0–D7] — LSB-first, no reversal needed

                        if (bit_index == 3'd7) begin
                            state <= STATE_STOP;                  // all 8 bits received
                        end else begin
                            bit_index <= bit_index + 1'b1;        // advance to next bit
                        end
                    end else begin
                        baud_count <= baud_count + 1; // hold position until bit center
                    end
                end

                STATE_STOP: begin
                    if (baud_count == (CLKS_PER_BIT - 1)) begin // sample stop bit at its center
                        baud_count <= 0;
                        rx_busy    <= 1'b0;

                        if (rx_sync) begin                    // [FRAME: STOP valid] — line HIGH as expected
                            data_out      <= data_shift;      // commit received byte to output
                            rx_done_valid <= 1'b1;            // pulse rx_done_valid for exactly one clock
                            state         <= STATE_IDLE;
                        end else begin                   // [FRAME: STOP LOW] — framing error
                            framing_error <= 1'b1;       // pulse framing_error for exactly one clock
                            state         <= STATE_WAIT_IDLE; // hold until line returns HIGH
                        end
                    end else begin
                        baud_count <= baud_count + 1; // hold position until stop-bit center
                    end
                end

                STATE_WAIT_IDLE: begin
                    rx_busy <= 1'b0; // [FRAME: BREAK/ERROR] — wait for line to return HIGH

                    if (rx_sync)     // line recovered; safe to accept a new start bit
                        state <= STATE_IDLE;
                end

                default: begin
                    state      <= STATE_IDLE;
                    baud_count <= 0;
                    rx_busy    <= 1'b0;
                end
            endcase
        end
    end

endmodule
