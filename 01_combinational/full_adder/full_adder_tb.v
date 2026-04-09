/*******************************************************************************
 * Module: full_adder_tb.v                                                     *
 * Description:                                                                *
 * File Created: Wednesday, 8th April 2026 4:52:15 pm                          *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 8th April 2026 4:54:36 pm                         *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module full_adder_tb;
    reg  a, b, cin;
    wire sum, cout;

    reg expected_sum, expected_cout;
    integer i;
    integer error_count;

    full_adder #(.WIDTH(1)) dut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout)
    );

    initial begin
        error_count = 0;
        $display("=== FULL ADDER Testbench ===");
        $display(" time | a b cin | sum cout | exp_sum exp_cout | result");
        $display("--------------------------------------------------------");

        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #10;

            {expected_cout, expected_sum} = a + b + cin;

            if ({cout, sum} !== {expected_cout, expected_sum}) begin
                error_count = error_count + 1;
                $display("%4t | %b %b  %b  |  %b    %b   |    %b       %b    | FAIL",
                         $time, a, b, cin, sum, cout, expected_sum, expected_cout);
            end else begin
                $display("%4t | %b %b  %b  |  %b    %b   |    %b       %b    | PASS",
                         $time, a, b, cin, sum, cout, expected_sum, expected_cout);
            end
        end

        if (error_count == 0) begin
            $display("=== PASS: all 8 test vectors matched ===");
        end else begin
            $display("=== FAIL: %0d mismatches detected ===", error_count);
        end

        $finish;
    end
endmodule

