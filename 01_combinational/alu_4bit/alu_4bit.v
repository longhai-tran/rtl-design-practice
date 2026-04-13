/*******************************************************************************
 * Module: alu_4bit.v                                                          *
 * Description: Parameterizable combinational ALU                              *
 * File Created: Thursday, 9th April 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                     *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module alu_4bit #(
    parameter WIDTH = 4  // Data width for ALU operands and output
)(
    input  wire [WIDTH-1:0] a,      // Operand A
    input  wire [WIDTH-1:0] b,      // Operand B
    input  wire [2:0]       op,     // Operation select
    output reg  [WIDTH-1:0] y,      // ALU result
    output reg              carry,  // Carry/borrow flag for arithmetic ops
    output wire             zero    // High when result is zero
);
    localparam [2:0] OP_ADD   = 3'b000;
    localparam [2:0] OP_SUB   = 3'b001;
    localparam [2:0] OP_AND   = 3'b010;
    localparam [2:0] OP_OR    = 3'b011;
    localparam [2:0] OP_XOR   = 3'b100;
    localparam [2:0] OP_NOT_A = 3'b101;
    localparam [2:0] OP_PASSA = 3'b110;
    localparam [2:0] OP_PASSB = 3'b111;

    reg [WIDTH:0] tmp;

    always @(*) begin
        y = {WIDTH{1'b0}};
        carry = 1'b0;
        tmp = {(WIDTH+1){1'b0}};

        case (op)
            OP_ADD: begin
                tmp = a + b;
                y = tmp[WIDTH-1:0];
                carry = tmp[WIDTH];
            end
            OP_SUB: begin
                tmp = {1'b0, a} - {1'b0, b};
                y = tmp[WIDTH-1:0];
                carry = tmp[WIDTH];
            end
            OP_AND: y = a & b;
            OP_OR:  y = a | b;
            OP_XOR: y = a ^ b;
            OP_NOT_A: y = ~a;
            OP_PASSA: y = a;
            OP_PASSB: y = b;
            default: begin
                y = {WIDTH{1'b0}};
                carry = 1'b0;
            end
        endcase
    end

    assign zero = (y == {WIDTH{1'b0}});
endmodule
