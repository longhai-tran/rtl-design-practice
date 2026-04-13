/*******************************************************************************
 * Module: encoder_8to3_tb.v                                                   *
 * Description: Self-checking testbench for encoder_8to3                      *
 * File Created: Thursday, 9th April 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                     *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module encoder_8to3_tb;
    reg  [7:0] d;
    wire [2:0] y;
    wire       valid;

    reg  [2:0] expected_y;
    reg        expected_valid;
    integer i;
    integer error_count;

    encoder_8to3 dut (
        .d(d),
        .y(y),
        .valid(valid)
    );

    task check_output;
        begin
            #10;
            if ((y !== expected_y) || (valid !== expected_valid)) begin
                error_count = error_count + 1;
                $display("%4t | d=%b | y=%b valid=%b | exp_y=%b exp_valid=%b | FAIL",
                         $time, d, y, valid, expected_y, expected_valid);
            end else begin
                $display("%4t | d=%b | y=%b valid=%b | exp_y=%b exp_valid=%b | PASS",
                         $time, d, y, valid, expected_y, expected_valid);
            end
        end
    endtask

    initial begin
        error_count = 0;
        $display("=== ENCODER 8to3 Testbench ===");

        for (i = 0; i < 8; i = i + 1) begin
            d = (8'b00000001 << i);
            expected_y = i[2:0];
            expected_valid = 1'b1;
            check_output;
        end

        d = 8'b00000000; expected_y = 3'b000; expected_valid = 1'b0; check_output;
        d = 8'b00000011; expected_y = 3'b000; expected_valid = 1'b0; check_output;
        d = 8'b10100000; expected_y = 3'b000; expected_valid = 1'b0; check_output;

        if (error_count == 0)
            $display("=== PASS: all 11 test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end
endmodule
