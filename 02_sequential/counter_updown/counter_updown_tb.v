/*******************************************************************************
 * Module: counter_updown_tb.v                                                 *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 1:55:54 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 15th April 2026 3:05:10 pm                        *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module counter_updown_tb;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg        clk, rst_n, up_down;
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
    counter_updown dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .up_down (up_down),
        .q       (q)
    );

    // -------------------------------------------------------------------------
    // Clock generation — 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: advance one clock, update golden model, check output
    // -------------------------------------------------------------------------
    task tick_and_check;
        begin
            if (up_down)
                expected_q = expected_q + 1;
            else
                expected_q = expected_q - 1;

            @(posedge clk); #1;
            if (q !== expected_q) begin
                // $display("FAIL  TC%0d | t=%0t | up_down=%b | q=%0d (exp %0d)",
                //           tc, $time, up_down, q, expected_q);
                $display("%-7s | %4d | %8t | up_down=%b | q=%0d", "FAIL", tc, $time, up_down, q);
                error_count = error_count + 1;
            end else
                // $display("PASS  TC%0d | t=%0t | up_down=%b | q=%0d",
                //           tc, $time, up_down, q);
                $display("%-7s | %4d | %8t | up_down=%b | q=%0d", "PASS", tc, $time, up_down, q);
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
        up_down     = 1'b1;

        $display("=== COUNTER_UPDOWN Testbench (4-bit Up/Down Counter) ===");
        $display(" status |  TC  |   time   | up_down | q (dec)");
        $display("--------------------------------------------------");

        // --- Reset check ---
        @(posedge clk); #1;
        if (q !== 4'b0) begin
            // $display("FAIL  TC0 | Reset: q=%0d (exp 0)", q);
            $display("%-7s | %4s | %8t | Reset: q=%0d", "FAIL", "0", $time, q);
            error_count = error_count + 1;
        end else
            // $display("PASS  TC0 | Reset: q=%0d", q);
            $display("%-7s | %4s | %8t | Reset: q=%0d", "PASS", "0", $time, q);

        rst_n = 1'b1;

        // --- Count up: 0 -> 7 ---
        $display("--- Count UP: 0 -> 7 ---");
        up_down = 1'b1;
        repeat (7) tick_and_check;

        // --- Switch direction: count down 7 -> 0 ---
        $display("--- Count DOWN: 7 -> 0 ---");
        up_down = 1'b0;
        repeat (7) tick_and_check;

        // --- Down rollover: 0 -> 15 (wrap) ---
        $display("--- Down rollover: 0 -> 15 ---");
        tick_and_check;

        // --- Count up from 15 back to 4 ---
        $display("--- Count UP: 15 -> high values ---");
        up_down = 1'b1;
        repeat (5) tick_and_check;

        // --- Async reset mid-count ---
        rst_n      = 1'b0;
        expected_q = 4'b0;
        #3;
        if (q !== 4'b0) begin
            // $display("FAIL  RST | Async reset: q=%0d (exp 0)", q);
            $display("%-7s | %4s | %8t | Async reset: q=%0d", "FAIL", "RST", $time, q);
            error_count = error_count + 1;
        end else
            // $display("PASS  RST | Async reset: q=%0d", q);
            $display("%-7s | %4s | %8t | Async reset: q=%0d", "PASS", "RST", $time, q);
        rst_n = 1'b1;
        #7;

        // --- Summary ---
        $display("--------------------------------------------------");
        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end

endmodule
