/*******************************************************************************
 * Module: dff.v                                                               *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 11:05:29 am                          *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th April 2026 11:11:09 am                         *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module dff (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    always @(posedge clk) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule
