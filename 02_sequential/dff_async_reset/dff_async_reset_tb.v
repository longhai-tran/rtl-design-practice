/*******************************************************************************
 * Module: dff_async_reset_tb.v                                                *
 * Description: Self-checking testbench for D Flip-Flop (asynchronous reset)   *
 * File Created: Monday, 13th April 2026 4:22:14 pm                            *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th April 2026 11:15:20 am                         *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module dff_async_reset_tb;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg  clk, rst_n, d;
    wire q;

    // -------------------------------------------------------------------------
    // Scoreboard
    // -------------------------------------------------------------------------
    integer error_count;
    reg expected_q;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    dff_async_reset dut (
        .clk   (clk),
        .rst_n (rst_n),
        .d     (d),
        .q     (q)
    );

    // -------------------------------------------------------------------------
    // Clock generation — 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: apply one stimulus, wait one clock, check output
    // -------------------------------------------------------------------------
    task apply_and_check;
        input d_in;
        input exp_q;
        begin
            d = d_in;
            expected_q = exp_q;
            @(posedge clk); #1;
            if (q !== expected_q) begin
                // $display("FAIL  t=%0t | rst_n=%b d=%b | q=%b (exp %b)",
                //           $time, rst_n, d_in, q, expected_q);
                $display(" FAIL   | %8t |   %b    %b | %b (exp %b)| ", $time, rst_n, d_in, q, expected_q);
                error_count = error_count + 1;
            end else
                // $display("PASS  t=%0t | rst_n=%b d=%b | q=%b",
                //           $time, rst_n, d_in, q);
                $display(" PASS   | %8t |   %b    %b | %b (exp %b)| ", $time, rst_n, d_in, q, expected_q);
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: assert async reset and verify immediately (no clock needed)
    // -------------------------------------------------------------------------
    task async_reset_check;
        begin
            d     = 1'b1;
            rst_n = 1'b0;           // assert reset asynchronously
            expected_q = 1'b0;
            #3;                     // wait 3 ns (less than half clock period)
            if (q !== expected_q) begin
                // $display("FAIL  t=%0t | Async reset: q=%b (exp 0) [should clear without clock]",
                //           $time, q);
                $display(" FAIL   | %8t |   Async reset: q=%b (exp 0) [should clear without clock]", $time, q);
                error_count = error_count + 1;
            end else
                // $display("PASS  t=%0t | Async reset cleared q immediately", $time);
                $display(" PASS   | %8t |   Async reset cleared q (q=%b) immediately", $time, q);
            rst_n = 1'b1;
            #2;
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $timeformat(-12, 0, "", 8); // Set time format to ns, 0 decimal places, no unit string, 8 characters wide
        error_count = 0;
        rst_n = 1'b0;
        d     = 1'b0;

        $display("=== DFF_ASYNC_RESET Testbench ===");
        // $display(" status | time   | rst_n d | q");
        $display(" status | %8s |  rst_n d | q | note", "time");
        $display("------------------------------------------");

        // --- Initial reset ---
        #12;
        if (q !== 1'b0) begin
            // $display("FAIL  t=%0t | Initial reset: q=%b (exp 0)", $time, q);
            $display(" FAIL   | %8t |   0    x | %b (exp 0)| reset holds", $time, q);
            error_count = error_count + 1;
        end else
            // $display("PASS  t=%0t | Initial async reset holds q=0", $time);
            $display(" PASS   | %8t |   0    x | %b (exp 0)| reset holds", $time, q);

        rst_n = 1'b1;

        // --- Functional phase ---
        apply_and_check(1'b1, 1'b1);
        apply_and_check(1'b0, 1'b0);
        apply_and_check(1'b1, 1'b1);

        // --- Async reset mid-operation (key test vs sync DFF) ---
        async_reset_check;

        // --- Resume normal operation ---
        apply_and_check(1'b1, 1'b1);
        apply_and_check(1'b0, 1'b0);

        // --- Summary ---
        $display("------------------------------------------");
        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end

endmodule
