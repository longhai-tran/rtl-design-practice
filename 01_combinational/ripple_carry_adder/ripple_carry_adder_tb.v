/*******************************************************************************
 * Module: ripple_carry_adder_tb.v                                            *
 * Description: Self-checking testbench for ripple_carry_adder                *
 * File Created: Thursday, 9th April 2026                                     *
 * Author: Long Hai                                                           *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                    *
 * Modified By: Long Hai                                                      *
*******************************************************************************/

`timescale 1ns/1ps

module ripple_carry_adder_tb;
    // -------------------------------------------------------------------------
    // DUT signal declarations
    // -------------------------------------------------------------------------
    localparam WIDTH = 4;
    localparam NUM_VECTORS = (1 << (2*WIDTH + 1));

    reg  [WIDTH-1:0] a;
    reg  [WIDTH-1:0] b;
    reg              cin;
    wire [WIDTH-1:0] sum;
    wire             cout;

    // -------------------------------------------------------------------------
    // Tracking variables
    // -------------------------------------------------------------------------
    reg  [WIDTH-1:0] expected_sum;
    reg              expected_cout;
    integer          error_count;
    integer          i;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    ripple_carry_adder #(.WIDTH(WIDTH)) dut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout)
    );

    // -------------------------------------------------------------------------
    // Test stimulus
    // -------------------------------------------------------------------------
    initial begin
        error_count = 0;

        $display("=== RIPPLE CARRY ADDER Testbench ===");
        $display("   time  |  a   b    cin | cout  sum | exp_cout exp_sum | result");
        $display("---------------------------------------------------------------");

        for (i = 0; i < NUM_VECTORS; i = i + 1) begin
            {a, b, cin} = i[2*WIDTH:0];
            {expected_cout, expected_sum} = a + b + cin;

            #10;

            if ({cout, sum} !== {expected_cout, expected_sum}) begin
                error_count = error_count + 1;
                $display("%8t | %4b %4b  %1b  | %1b   %4b | %1b        %4b   | FAIL",
                        $time, a, b, cin, cout, sum, expected_cout, expected_sum);
            end else begin
                $display("%8t | %4b %4b  %1b  | %1b   %4b | %1b        %4b   | PASS",
                        $time, a, b, cin, cout, sum, expected_cout, expected_sum);
            end
        end

        // ---------------------------------------------------------------------
        // Final verdict
        // ---------------------------------------------------------------------
        if (error_count == 0) begin
            $display("=== PASS: all %0d test vectors matched ===", NUM_VECTORS);
        end else begin
            $display("=== FAIL: %0d mismatches detected ===", error_count);
        end

        $finish;
    end
endmodule

