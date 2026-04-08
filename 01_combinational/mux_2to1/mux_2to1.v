/*******************************************************************************
 * Module: mux_2to1.v                                                          *
 * Description:                                                                *
 * File Created: Friday, 3rd April 2026 1:20:44 pm                             *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 8th April 2026 11:56:26 am                        *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module mux_2to1 #(
    parameter WIDTH = 1
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             sel,
    output wire [WIDTH-1:0] y
);
    assign y = sel ? b : a;
endmodule






