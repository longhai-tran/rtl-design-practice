/*******************************************************************************
 * Module: full_adder.v                                                        *
 * Description:                                                                *
 * File Created: Wednesday, 8th April 2026 4:52:04 pm                          *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 8th April 2026 4:54:45 pm                         *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module full_adder #(
    parameter WIDTH = 1
)(
    input  wire [WIDTH-1:0] a,    // Operand A
    input  wire [WIDTH-1:0] b,    // Operand B
    input  wire             cin,  // Carry input
    output wire [WIDTH-1:0] sum,  // Sum output
    output wire             cout  // Carry output
);
    assign {cout, sum} = a + b + cin;
endmodule

