/*******************************************************************************
 * Module: shift_register_tb.v                                                 *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 1:55:54 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th April 2026 4:42:23 pm                          *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module shift_register_tb;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg        clk, rst_n, din;
    wire [3:0] q;

    // -------------------------------------------------------------------------
    // Scoreboard
    // -------------------------------------------------------------------------
    integer error_count;
    integer tc;
    reg [3:0] expected_q;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    shift_register dut (
        .clk   (clk),
        .rst_n (rst_n),
        .din   (din),
        .q     (q)
    );

    // -------------------------------------------------------------------------
    // Clock generation — 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: shift in one bit ,wait one clock, check q against golden model
    // -------------------------------------------------------------------------
    task shift_and_check;
        input din_in;
        begin
            din        = din_in;
            expected_q = {expected_q[2:0], din_in};
            @(posedge clk); #1;
            if (q !== expected_q) begin
                // $display(" FAIL   | TC%0d | t=%0t | din=%b | q=%b (exp %b)",
                //           tc, $time, din_in, q, expected_q);
                $display("%-7s | %4d | %6t |  %1d  | %b (expected %b)",
                         "FAIL", tc, $time, din, q, expected_q);
                error_count = error_count + 1;
            end else
                // $display(" PASS   | TC%0d | t=%0t | din=%b | q=%b",
                //           tc, $time, din_in, q);
                $display("%-7s | %4d | %6t |  %1d  | %4b",
                         "PASS", tc, $time, din, q);
            tc = tc + 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $timeformat(-12, 0, "", 8); // Set time format to ns, 0 decimal places, no unit string, 8 characters wide
        error_count = 0;
        tc          = 1;
        expected_q  = 4'b0;
        rst_n       = 1'b0;
        din         = 1'b0;

        $display("=== SHIFT_REGISTER Testbench (4-bit SIPO) ===");
        $display(" status |  TC  |   time   | din |   q");
        $display("--------+------+----------+-----+------");

        // --- Reset check ---
        @(posedge clk); #1;
        if (q !== 4'b0) begin
            // $display(" FAIL   | TC0 | Reset: q=%b (exp 0000)", q);
            $display("%-7s | %4s | %6t |  %1s  | %b (expected 0000)",
                    "FAIL", "0", $time, "-", q);
            error_count = error_count + 1;
        end else begin
            // $display(" PASS   | TC0 | Reset: q=%b", q);
            $display("%-7s | %4s | %6t |  %1s  | %s",
                    "PASS", "0", $time, "-", "Reset: q=0000");

        end
        rst_n = 1'b1;

        // --- Shift in pattern 1011 (MSB first) ---
        $display("--- Pattern 1011 ---");
        shift_and_check(1'b1);
        shift_and_check(1'b0);
        shift_and_check(1'b1);
        shift_and_check(1'b1);

        // --- Shift in all ones ---
        $display("--- All 1s ---");
        shift_and_check(1'b1);
        shift_and_check(1'b1);
        shift_and_check(1'b1);
        shift_and_check(1'b1);

        // --- Shift in all zeros ---
        $display("--- All 0s ---");
        shift_and_check(1'b0);
        shift_and_check(1'b0);
        shift_and_check(1'b0);
        shift_and_check(1'b0);

        // --- Async reset mid-shift ---
        din        = 1'b1;
        rst_n      = 1'b0;
        expected_q = 4'b0;
        #3;
        if (q !== 4'b0) begin
            // $display("FAIL  RST | Async reset mid-shift: q=%b (expected 0000)", q);
            $display("%-7s | %4s | %6t |  %1s  | Async reset mid-shift: q=%b (expected 0000)",
                    "FAIL", "RST", $time, "-", q);
            error_count = error_count + 1;
        end else
            // $display("PASS  RST | Async reset mid-shift: q=%b", q);
            $display("%-7s | %4s | %6t |  %1s  | %s",
                    "PASS", "RST", $time, "-", "Async reset mid-shift: q=0000");

        rst_n = 1'b1;
        // #7; // This delay has been removed to avoid skipping the positive edge of the clk


        // --- Resume with pattern 1010 ---
        $display("--- Pattern 1010 after reset ---");
        shift_and_check(1'b1);
        shift_and_check(1'b0);
        shift_and_check(1'b1);
        shift_and_check(1'b0);

        // --- Summary ---
        $display("-------------------------------------------");
        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end

endmodule
