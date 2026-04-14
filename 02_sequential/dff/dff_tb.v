/*******************************************************************************
 * Module: dff_tb.v                                                            *
 * Description: Self-checking testbench for D Flip-Flop (synchronous reset)   *
 * Author: Long Hai                                                            *
 *******************************************************************************/

`timescale 1ns/1ps

module dff_tb;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg  clk, rst_n, d;
    wire q;

    // -------------------------------------------------------------------------
    // Scoreboard
    // -------------------------------------------------------------------------
    integer error_count;
    reg     expected_q;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    dff dut (
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
            @(posedge clk); #1;           // sample 1 ns after rising edge
            expected_q = exp_q;
            if (q !== expected_q) begin
                $display("FAIL  t=%0t | rst_n=%b d=%b | q=%b (exp %b)",
                          $time, rst_n, d_in, q, expected_q);
                error_count = error_count + 1;
            end else begin
                    // $display("  PASS    t=%0t | rst_n=%b d=%b | q=%b",
                    //         $time, rst_n, d_in, q);
                $display(" PASS   | %8t |   %b    %b | %b | ", $time, rst_n, d_in, q);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $timeformat(-12, 0, "", 8); // Set time format to ns, 0 decimal places, no unit string, 8 characters wide
        error_count = 0;
        rst_n = 1'b0;
        d     = 1'b1;

        $display("=== DFF Testbench (Synchronous Reset) ===");
        // $display(" status | time    | rst_n   d   | q");
        // $display("------------------------------------------");
        $display(" status | %8s |  rst_n d | q | note", "time");
        $display("--------+----------+----------+---+----------------");

        // --- Reset phase ---
        @(posedge clk); #1;
        if (q !== 1'b0) begin
            $display("FAIL  t=%0t | Reset check: q=%b (exp 0)", $time, q);
            error_count = error_count + 1;
        end else
            // $display("  PASS    t=%5t | rst_n=0 d=x | q=%b (reset holds)", $time, q);
            $display(" PASS   | %8t |   0    x | %b | reset holds", $time, q);

        rst_n = 1'b1;

        // --- Functional phase ---
        apply_and_check(1'b1, 1'b1);   // d=1 -> q should be 1
        apply_and_check(1'b0, 1'b0);   // d=0 -> q should be 0
        apply_and_check(1'b1, 1'b1);
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
