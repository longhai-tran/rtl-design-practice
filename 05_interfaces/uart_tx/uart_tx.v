/*******************************************************************************
 * Module: uart_tx.v                                                           *
 * Description: Parameterized UART transmitter with an internal baud divider, *
 *              8N1 framing, and start/busy/done handshake.                   *
 * File Created: Friday, 17th July 2026 3:17:35 pm                             *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 21st July 2026 3:36:55 pm                           *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module uart_tx #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE   = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        tx_busy,
    output reg        tx_done
);

    // Round to the nearest integer number of clocks per UART bit.
    localparam integer CLKS_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;

    localparam [2:0] STATE_IDLE  = 3'd0;
    localparam [2:0] STATE_START = 3'd1;
    localparam [2:0] STATE_DATA  = 3'd2;
    localparam [2:0] STATE_STOP  = 3'd3;

    reg [2:0] state;
    reg [2:0] bit_index;
    reg [7:0] data_latched;
    integer   baud_count;

    always @(posedge clk) begin
        if (!rst_n) begin
            state        <= STATE_IDLE;
            bit_index    <= 3'd0;
            data_latched <= 8'h00;
            baud_count   <= 0;
            tx            <= 1'b1;
            tx_busy       <= 1'b0;
            tx_done       <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    tx          <= 1'b1; // [FRAME: IDLE] — line held HIGH (mark state)
                    tx_busy     <= 1'b0;
                    baud_count <= 0;
                    bit_index  <= 3'd0;

                    if (tx_start) begin
                        data_latched <= data_in;  // latch payload before frame begins
                        tx            <= 1'b0;    // [FRAME: START BIT] — HIGH→LOW edge synchronizes receiver
                        tx_busy       <= 1'b1;
                        state         <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (baud_count == (CLKS_PER_BIT - 1)) begin
                        baud_count <= 0;
                        tx          <= data_latched[0]; // [FRAME: D0] — LSB first, per UART convention
                        state       <= STATE_DATA;
                    end else begin
                        baud_count <= baud_count + 1;  // hold START bit for 1 full bit period
                    end
                end

                STATE_DATA: begin
                    if (baud_count == (CLKS_PER_BIT - 1)) begin
                        baud_count <= 0;

                        if (bit_index == 3'd7) begin
                            tx    <= 1'b1;   // [FRAME: STOP BIT] — line returns HIGH after MSB (D7)
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx        <= data_latched[bit_index + 1'b1]; // [FRAME: D1–D7] — next data bit (LSB-first)
                        end
                    end else begin
                        baud_count <= baud_count + 1; // hold current data bit for 1 full bit period
                    end
                end

                STATE_STOP: begin
                    if (baud_count == (CLKS_PER_BIT - 1)) begin
                        baud_count <= 0;
                        tx          <= 1'b1;  // [FRAME: IDLE] — frame complete, line returns to mark state
                        tx_busy     <= 1'b0;
                        tx_done     <= 1'b1;  // pulse 1 clock: signals upper layer that byte was sent
                        state       <= STATE_IDLE;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                default: begin
                    state      <= STATE_IDLE;
                    baud_count <= 0;
                    tx          <= 1'b1;
                    tx_busy     <= 1'b0;
                end
            endcase
        end
    end

endmodule
