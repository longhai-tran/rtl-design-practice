/*******************************************************************************
 * Module: counter_4bit_tb.v                                                   *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 1:55:53 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 15th April 2026 11:21:21 am                       *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module counter_4bit_tb;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg        clk, rst_n;
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
    counter_4bit dut (
        .clk   (clk),
        .rst_n (rst_n),
        .q     (q)
    );

    // -------------------------------------------------------------------------
    // Clock generation — 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: advance one clock and verify against golden model
    // -------------------------------------------------------------------------
    task tick_and_check;
        begin
            expected_q = expected_q + 1;
            @(posedge clk); #1;
            if (q !== expected_q) begin
                $display("FAIL  TC%0d | t=%0t | q=%0d (exp %0d)",
                          tc, $time, q, expected_q);
                error_count = error_count + 1;
            end else
                // $display("PASS  TC%0d | t=%0t | q=%0d", tc, $time, q);
                $display("%-7s | %4d | %8t |  q=%0d", "PASS", tc, $time, q);

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

        $display("=== COUNTER_4BIT Testbench (4-bit Up Counter) ===");
        $display(" status |  TC  |   time   | q (dec)");
        $display("--------+------+----------+--------");

        // --- Reset check ---
        @(posedge clk); #1;
        if (q !== 4'b0) begin
            $display("FAIL  TC0 | Reset: q=%0d (exp 0)", q);
            error_count = error_count + 1;
        end else
            // $display("PASS  TC0 | Reset: q=%0d", q);
            $display("%-7s | %4s | %8t |  Reset: q=%0d", "PASS", "0", $time, q);

        rst_n = 1'b1;

        // --- Count through full 0..15 cycle ---
        $display("--- Count up 0 -> 15 ---");
        repeat (15) tick_and_check;

        // --- Verify rollover: 15 -> 0 ---
        expected_q = 4'd15;
        @(posedge clk); #1;
        expected_q = 4'd0;
        if (q !== expected_q) begin
            $display("FAIL  ROLL | t=%0t | rollover: q=%0d (exp 0)", $time, q);
            error_count = error_count + 1;
        end else
            // $display("PASS  ROLL | t=%0t | rollover: q=%0d", $time, q);
            $display("%-7s | %4s | %8t |  rollover: q=%0d", "PASS", "ROLL", $time, q);

        // --- Async reset mid-count ---
        repeat (4) @(posedge clk);
        #1;
        rst_n      = 1'b0;
        expected_q = 4'b0;
        #3;
        if (q !== 4'b0) begin
            $display("FAIL  RST | Async reset: q=%0d (exp 0)", q);
            error_count = error_count + 1;
        end else
            // $display("PASS  RST | Async reset: q=%0d", q);
            $display("%-7s | %4s | %8t |  Async reset: q=%0d", "PASS", "RST", $time, q);
        rst_n = 1'b1;
        #4;

        // --- Count a few more after reset ---
        $display("--- Count after reset ---");
        tc = 1; expected_q = 4'b0;
        repeat (5) tick_and_check;

        // --- Summary ---
        $display("--------------------------------------------");
        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end

endmodule
