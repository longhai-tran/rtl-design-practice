/*******************************************************************************
 * Module: dff_async_reset.v                                                   *
 * Description:                                                                *
 * File Created: Monday, 13th April 2026 4:22:14 pm                            *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th April 2026 11:16:10 am                         *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module dff_async_reset (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule
