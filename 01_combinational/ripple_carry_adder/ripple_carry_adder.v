/*******************************************************************************
 * Module: ripple_carry_adder.v                                               *
 * Description: Parameterizable ripple-carry adder (combinational)            *
 * File Created: Thursday, 9th April 2026                                     *
 * Author: Long Hai                                                           *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                    *
 * Modified By: Long Hai                                                      *
*******************************************************************************/

`timescale 1ns/1ps

module ripple_carry_adder #(
    parameter WIDTH = 4  // Data bus width for input operands and sum
)(
    input  wire [WIDTH-1:0] a,    // Operand A
    input  wire [WIDTH-1:0] b,    // Operand B
    input  wire             cin,  // Carry input
    output wire [WIDTH-1:0] sum,  // Sum output
    output wire             cout  // Carry output
);
    // Internal carry chain: c[0] is cin, c[WIDTH] is final carry-out
    wire [WIDTH:0] c/* verilator split_var */;
    genvar i;

    assign c[0] = cin;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_ripple_stage
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign c[i+1] = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
        end
    endgenerate

    assign cout = c[WIDTH];
endmodule

