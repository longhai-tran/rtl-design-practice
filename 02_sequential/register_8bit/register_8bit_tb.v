/*******************************************************************************
 * Module: register_8bit_tb.v                                                  *
 * Description: Self-checking testbench for 8-bit parallel-load register       *
 * File Created: Tuesday, 14th April 2026 1:55:54 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th April 2026 2:26:25 pm                          *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module register_8bit_tb;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg        clk, rst_n;
    reg  [7:0] d;
    wire [7:0] q;

    // -------------------------------------------------------------------------
    // Scoreboard
    // -------------------------------------------------------------------------
    reg [7:0] expected_q;
    integer error_count;
    integer tc;           // test case index

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    register_8bit dut (
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
    // Task: load one value, wait one clock, check output
    // -------------------------------------------------------------------------
    task load_and_check;
        input [7:0] d_in;
        input [7:0] exp_q;
        begin
            d = d_in;
            expected_q = exp_q;
            @(posedge clk); #1;
            if (q !== exp_q) begin
                // $display("FAIL  TC%0d | t=%0t | rst_n=%b d=0x%02h | q=0x%02h (exp 0x%02h)",
                //           tc, $time, rst_n, d_in, q, exp_q);
                $display(" FAIL   | %4d | %6t |   1   | 0x%02h | 0x%02h (exp 0x%02h)", tc, $time, d_in, q, exp_q);
                error_count = error_count + 1;
            end else
                // $display(" PASS   | TC%0d | t=%0t | rst_n=%b d=0x%02h | q=0x%02h",
                //           tc, $time, rst_n, d_in, q);
                $display(" PASS   | %4d | %8t |   1   | 0x%02h | 0x%02h ", tc, $time, d_in, q);

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
        rst_n       = 1'b0;
        d           = 8'h00;
        expected_q  = 8'h00;

        $display("=== REGISTER_8BIT Testbench ===");
        $display(" status |  TC  |   time   | rst_n |   d  |   q");
        $display("--------+------+----------+-------+------+--------");
        // $display(" PASS   | RST   | Async reset mid-op: q=0x%02h", q);
        // $display(" PASS   | %3s | t=%0t | rst_n=%b d=0x%02h | q=0x%02h",
        //                   "TC", tc, $time, rst_n, d_in, q);

        // --- Reset check ---
        @(posedge clk); #1;
        if (q !== expected_q) begin
            $display(" FAIL   | %4d | %6t | Reset: q=0x%02h (exp 0x00)", tc, $time, q);
            error_count = error_count + 1;
        end else
            // $display("PASS  TC0 | Reset: q=0x%02h", q);
            $display(" PASS   | %4d | %6t |   0   |  --  | 0x%02h ", tc, $time, q);

        rst_n = 1'b1;

        // --- Directed test vectors ---
        load_and_check(8'hA5, 8'hA5);   // alternating bits
        load_and_check(8'h5A, 8'h5A);   // complement
        load_and_check(8'hFF, 8'hFF);   // all ones
        load_and_check(8'h00, 8'h00);   // all zeros
        load_and_check(8'h3C, 8'h3C);   // arbitrary
        load_and_check(8'hF0, 8'hF0);
        load_and_check(8'h0F, 8'h0F);

        // --- Reset mid-operation ---
        d     = 8'hBE;
        rst_n = 1'b0;
        expected_q = 8'h00;
        @(posedge clk); #1;
        if (q !== expected_q) begin
            $display("FAIL  RST | Async reset mid-op: q=0x%02h (exp 0x00)", q);
            error_count = error_count + 1;
        end else
            // $display(" PASS   | RST   | Async reset mid-op: q=0x%02h", q);
            $display(" PASS   |  RST | %8t |   0   |  --  | 0x%02h ", $time, q);
        rst_n = 1'b1;

        // --- Resume ---
        load_and_check(8'hDE, 8'hDE);

        // --- Summary ---
        $display("------------------------------------------------");
        if (error_count == 0)
            $display("=== PASS: all test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end

endmodule
