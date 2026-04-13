/*******************************************************************************
 * Module: decoder_3to8.v                                                      *
 * Description: 3-to-8 decoder with enable (combinational)                     *
 * File Created: Thursday, 9th April 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                     *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module decoder_3to8(
    input  wire [2:0] in,   // Select input
    input  wire       en,   // Enable input
    output wire [7:0] y     // One-hot decoded output
);
    assign y = en ? (8'b00000001 << in) : 8'b00000000;
endmodule
