/*******************************************************************************
 * Module: carry_lookahead_adder.v                                            *
 * Description: Parameterizable carry-lookahead adder (combinational)         *
 * File Created: Friday, 10th April 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 10th April 2026                                     *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module carry_lookahead_adder #(
    parameter WIDTH = 4  // Data bus width for input operands and sum
)(
    input  wire [WIDTH-1:0] a,    // Operand A
    input  wire [WIDTH-1:0] b,    // Operand B
    input  wire             cin,  // Carry input
    output wire [WIDTH-1:0] sum,  // Sum output
    output wire             cout  // Carry output
);
    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    // Bit-level generate (g) and propagate (p) terms — fully parallel, O(1) logic
    wire [WIDTH-1:0] p;        // p[i] = a[i] ^ b[i] : carry propagate
    wire [WIDTH-1:0] g;        // g[i] = a[i] & b[i] : carry generate
    /* verilator lint_off UNOPTFLAT */
    wire [WIDTH:0]   c;        // Lookahead carry chain: c[0]=cin, c[WIDTH]=cout
    /* verilator lint_on UNOPTFLAT */

    genvar i;

    // -------------------------------------------------------------------------
    // Generate: bit-level propagate and generate
    // -------------------------------------------------------------------------
    assign p = a ^ b;
    assign g = a & b;

    // -------------------------------------------------------------------------
    // Generate: lookahead carry chain
    // c[i+1] = g[i] | (p[i] & c[i])
    // Each stage is an independent parallel gate — fully unrolled by synthesis
    // -------------------------------------------------------------------------
    assign c[0] = cin;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_cla_carry
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign sum  = p ^ c[WIDTH-1:0];
    assign cout = c[WIDTH];

endmodule

