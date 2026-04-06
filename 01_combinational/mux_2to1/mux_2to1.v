/*******************************************************************************
 * Module: mux_2to1.v                                                          *
 * Description:                                                                *
 * File Created: Friday, 3rd April 2026 1:20:44 pm                             *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 3rd April 2026 2:02:02 pm                            *
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






