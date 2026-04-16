/*******************************************************************************
 * Module: gray_counter.v                                                      *
 * Description: N-bit Gray code counter with async active-low reset.           *
 *              Uses binary-to-Gray conversion: G = B XOR (B >> 1).            *
 * File Created: Thursday, 16th April 2026 10:54:23 am                         *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 16th April 2026 2:24:41 pm                         *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module gray_counter #(
    parameter WIDTH = 4
)(
    input  wire       clk,
    input  wire       rst_n,
    output reg  [WIDTH-1:0] q        // gray code output
);
    reg [WIDTH-1:0] bin_count;
    wire [WIDTH-1:0] bin_next = bin_count + 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_count <= {WIDTH{1'b0}};
            q         <= {WIDTH{1'b0}};
        end else begin
            bin_count <= bin_next;
            q         <= (bin_next >> 1) ^ bin_next;

            // method 2
            // q         <= {bin_count[3], bin_count[3:1] ^ bin_count[2:0]};
        end
    end
endmodule
