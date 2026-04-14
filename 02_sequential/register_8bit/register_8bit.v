/*******************************************************************************
 * Module: register_8bit.v                                                     *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 1:55:54 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th April 2026 2:26:29 pm                          *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module register_8bit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'b0;
        else
            q <= d;
    end
endmodule
