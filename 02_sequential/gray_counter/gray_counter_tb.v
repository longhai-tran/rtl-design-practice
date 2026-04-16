/*******************************************************************************
 * Module      : gray_counter_tb
 * Description : Testbench for gray_counter (parameterized N-bit).
 *               Verifies: reset state, full Gray sequence, single-bit toggle
 *               property, rollover (max -> 0), and async reset mid-sequence.
 * Parameter   : WIDTH — must match DUT (default: 4)
 * Author      : Long Hai
 * Created     : 2026-04-16
 *******************************************************************************/

`timescale 1ns / 1ps

module gray_counter_tb;

    // -------------------------------------------------------------------------
    // Parameter (mirror the DUT)
    // -------------------------------------------------------------------------
    parameter WIDTH = 4;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg              clk;
    reg              rst_n;
    wire [WIDTH-1:0] q;

    // -------------------------------------------------------------------------
    // Scoreboard
    // -------------------------------------------------------------------------
    integer          error_count;
    integer          tc;
    reg [WIDTH-1:0]  expected_q;
    reg [WIDTH-1:0]  prev_q;
    integer          bit_toggle_count;
    integer          i, j;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    gray_counter #(.WIDTH(WIDTH)) dut (
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
    // Helper function: binary to Gray  [G = B ^ (B >> 1)]
    // -------------------------------------------------------------------------
    function [WIDTH-1:0] bin2gray;
        input [WIDTH-1:0] b;
        begin
            bin2gray = (b >> 1) ^ b;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Task: advance one clock and verify value + single-bit toggle property
    // -------------------------------------------------------------------------
    task tick_and_check;
        input [WIDTH-1:0] bin_value;
        begin
            expected_q = bin2gray(bin_value);
            prev_q     = q;

            @(posedge clk); #1;

            if (q !== expected_q) begin
                $display("%-7s | %4d | %8t | q=%b (exp %b)",
                         "FAIL", tc, $time, q, expected_q);
                error_count = error_count + 1;
            end else begin
                // Count how many bits toggled from previous Gray state
                bit_toggle_count = 0;
                for (j = 0; j < WIDTH; j = j + 1)
                    bit_toggle_count = bit_toggle_count + (prev_q[j] ^ q[j]);

                if (bit_toggle_count != 1) begin
                    $display("%-7s | %4d | %8t | transition=%b->%b (toggles=%0d, exp 1)",
                             "FAIL", tc, $time, prev_q, q, bit_toggle_count);
                    error_count = error_count + 1;
                end else begin
                    $display("%-7s | %4d | %8t | q=%b", "PASS", tc, $time, q);
                end
            end

            tc = tc + 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $timeformat(-12, 0, "", 8);

        error_count      = 0;
        tc               = 1;
        expected_q       = {WIDTH{1'b0}};
        prev_q           = {WIDTH{1'b0}};
        bit_toggle_count = 0;
        rst_n            = 1'b0;

        $display("=== GRAY_COUNTER Testbench (%0d-bit, mod-%0d) ===", WIDTH, (1 << WIDTH));
        $display(" status |  TC  |   time   | q (bin)");
        $display("-------------------------------------------");

        // --- TC0: Reset check ---
        @(posedge clk); #1;
        if (q !== {WIDTH{1'b0}}) begin
            $display("%-7s | %4s | %8t | Reset: q=%b (exp %b)",
                     "FAIL", "0", $time, q, {WIDTH{1'b0}});
            error_count = error_count + 1;
        end else begin
            $display("%-7s | %4s | %8t | Reset: q=%b", "PASS", "0", $time, q);
        end

        rst_n = 1'b1;

        // --- TC1 to (2^WIDTH - 1): Full Gray sequence ---
        for (i = 1; i < (1 << WIDTH); i = i + 1)
            tick_and_check(i[WIDTH-1:0]);

        // --- Rollover: verify max -> 0 wraps with 1-bit toggle ---
        tick_and_check({WIDTH{1'b0}});

        // --- Async reset mid-sequence ---
        repeat (4) @(posedge clk);
        #1;
        rst_n = 1'b0;
        #3;
        if (q !== {WIDTH{1'b0}}) begin
            $display("%-7s | %4s | %8t | Async reset: q=%b (exp %b)",
                     "FAIL", "RST", $time, q, {WIDTH{1'b0}});
            error_count = error_count + 1;
        end else begin
            $display("%-7s | %4s | %8t | Async reset: q=%b", "PASS", "RST", $time, q);
        end
        rst_n = 1'b1;
        #4;

        // --- Post-reset: verify first 5 states resume correctly ---
        tc = 1;
        for (i = 1; i <= 5; i = i + 1)
            tick_and_check(i[WIDTH-1:0]);

        // --- Summary ---
        $display("-------------------------------------------");
        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end

endmodule
