/*******************************************************************************
 * Module: alu_4bit_tb.v                                                       *
 * Description: Self-checking testbench for alu_4bit                          *
 * File Created: Thursday, 9th April 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                     *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module alu_4bit_tb;
    localparam WIDTH = 4;

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg  [2:0]       op;
    wire [WIDTH-1:0] y;
    wire             carry;
    wire             zero;

    reg  [WIDTH-1:0] expected_y;
    reg              expected_carry;
    reg              expected_zero;
    reg  [WIDTH:0]   tmp;

    integer i, op_idx;
    integer error_count;

    alu_4bit #(.WIDTH(WIDTH)) dut (
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .carry(carry),
        .zero(zero)
    );

    task check_case;
        begin
            #10;
            if ((y !== expected_y) || (carry !== expected_carry) || (zero !== expected_zero)) begin
                error_count = error_count + 1;
                $display("%4t | op=%b a=%h b=%h | y=%h c=%b z=%b | exp_y=%h exp_c=%b exp_z=%b | FAIL",
                         $time, op, a, b, y, carry, zero, expected_y, expected_carry, expected_zero);
            end
            else begin
                $display("%4t | op=%b a=%h b=%h | y=%h c=%b z=%b | exp_y=%h exp_c=%b exp_z=%b | PASS",
                         $time, op, a, b, y, carry, zero, expected_y, expected_carry, expected_zero);
            end
        end
    endtask

    initial begin
        error_count = 0;
        $display("=== ALU 4bit Testbench ===");

        for (op_idx = 0; op_idx < 8; op_idx = op_idx + 1) begin
            for (i = 0; i < 16; i = i + 1) begin
            // for (i = 1; i < 2; i = i + 1) begin
                op = op_idx[2:0];
                a = i[3:0];
                b = 4'd15 - i[3:0];
                case (op)
                    3'b000: begin tmp = a + b; expected_y = tmp[WIDTH-1:0]; expected_carry = tmp[WIDTH]; end
                    3'b001: begin tmp = {1'b0,a} - {1'b0,b}; expected_y = tmp[WIDTH-1:0]; expected_carry = tmp[WIDTH]; end
                    3'b010: begin expected_y = a & b; expected_carry = 1'b0; end
                    3'b011: begin expected_y = a | b; expected_carry = 1'b0; end
                    3'b100: begin expected_y = a ^ b; expected_carry = 1'b0; end
                    3'b101: begin expected_y = ~a;    expected_carry = 1'b0; end
                    3'b110: begin expected_y = a;     expected_carry = 1'b0; end
                    3'b111: begin expected_y = b;     expected_carry = 1'b0; end
                    default: begin expected_y = 4'h0; expected_carry = 1'b0; end
                endcase
                expected_zero = (expected_y == 0);
                check_case;
            end
        end

        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end
endmodule
