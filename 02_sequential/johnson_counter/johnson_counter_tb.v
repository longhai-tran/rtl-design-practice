/*******************************************************************************
 * Module: johnson_counter_tb.v                                                *
 * Description:                                                                *
 * File Created: Wednesday, 15th April 2026 4:30:15 pm                         *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 15th April 2026 9:42:38 pm                        *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module johnson_counter_tb;

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
    // Golden model — 8-state Johnson sequence
    // -------------------------------------------------------------------------
    reg [3:0] johnson_seq [0:7];

    integer i;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    johnson_counter dut (
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
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $timeformat(-12, 0, "", 8); // Set time format to ns, 0 decimal places, no unit string, 8 characters wide

        // Pre-load expected Johnson sequence
        johnson_seq[0] = 4'b0001;
        johnson_seq[1] = 4'b0011;
        johnson_seq[2] = 4'b0111;
        johnson_seq[3] = 4'b1111;
        johnson_seq[4] = 4'b1110;
        johnson_seq[5] = 4'b1100;
        johnson_seq[6] = 4'b1000;
        johnson_seq[7] = 4'b0000;

        error_count = 0;
        tc          = 1;
        rst_n       = 1'b0;

        $display("=== JOHNSON_COUNTER Testbench (4-bit, 8-state) ===");
        $display(" status |  TC  |   time   | q (bin)");
        $display("-------------------------------------------");

        // --- Reset check ---
        @(posedge clk); #1;
        if (q !== 4'b0) begin
            // $display("FAIL  TC0 | Reset: q=%b (exp 0000)", q);
            $display("%-7s | %4s | %8t | Reset: q=%b (exp 0000)", "FAIL", "0", $time, q);
            error_count = error_count + 1;
        end else
            // $display("PASS  TC0 | Reset: q=%b", q);
            $display("%-7s | %4s | %8t | Reset: q=%b", "PASS", "0", $time, q);

        rst_n = 1'b1;

        // --- Verify 2 full Johnson cycles (16 clocks) ---
        for (i = 0; i < 2; i = i + 1) begin
            $display("--- Cycle %0d ---", i + 1);
            begin : CYCLE
                integer s;
                for (s = 0; s < 8; s = s + 1) begin
                    expected_q = johnson_seq[s];
                    @(posedge clk); #1;
                    if (q !== expected_q) begin
                        // $display("FAIL  TC%0d | t=%0t | q=%b (exp %b)",
                        //           tc, $time, q, expected_q);
                        $display("%-7s | %4d | %8t | q=%b (exp %b)", "FAIL", tc, $time, q, expected_q);
                        error_count = error_count + 1;
                    end else
                        // $display("PASS  TC%0d | t=%0t | q=%b", tc, $time, q);
                        $display("%-7s | %4d | %8t | q=%b", "PASS", tc, $time, q);
                    tc = tc + 1;
                end
            end
        end

        // --- Async reset mid-sequence ---
        rst_n = 1'b0;
        #3;
        if (q !== 4'b0) begin
            // $display("FAIL  RST | Async reset: q=%b (exp 0000)", q);
            $display("%-7s | %4s | %8t | Async reset: q=%b (exp 0000)", "FAIL", "RST", $time, q);
            error_count = error_count + 1;
        end else
            // $display("PASS  RST | Async reset: q=%b", q);
            $display("%-7s | %4s | %8t | Async reset: q=%b", "PASS", "RST", $time, q);
        rst_n = 1'b1;
        #4;

        // --- Verify one more cycle after reset ---
        $display("--- Cycle after reset ---");
        begin : POST_RST
            integer s;
            for (s = 0; s < 8; s = s + 1) begin
                expected_q = johnson_seq[s];
                @(posedge clk); #1;
                if (q !== expected_q) begin
                    // $display("FAIL  TC%0d | t=%0t | q=%b (exp %b)",
                    //           tc, $time, q, expected_q);
                    $display("%-7s | %4d | %8t | q=%b (exp %b)", "FAIL", tc, $time, q, expected_q);
                    error_count = error_count + 1;
                end else
                    // $display("PASS  TC%0d | t=%0t | q=%b", tc, $time, q);
                    $display("%-7s | %4d | %8t | q=%b", "PASS", tc, $time, q);
                tc = tc + 1;
            end
        end

        // --- Summary ---
        $display("-------------------------------------------");
        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end

endmodule
