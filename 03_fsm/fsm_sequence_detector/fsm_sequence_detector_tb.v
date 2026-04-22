/*******************************************************************************
 * Module: fsm_sequence_detector_tb.v                                          *
 * Description: Testbench for Mealy FSM sequence detector (detects "1011")    *
 * File Created: Thursday, 16th April 2026 11:54:11 am                         *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 17th April 2026                                      *
 * Modified By: Long Hai                                                       *
 *******************************************************************************/

`timescale 1ns/1ps

module fsm_sequence_detector_tb;

    // -------------------------------------------------------------------------
    // Signal declarations
    // -------------------------------------------------------------------------
    reg  clk;
    reg  rst_n;
    reg  din;
    wire detected;

    integer error_count;
    integer test_num;
    reg expected_detect;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    fsm_sequence_detector dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .din      (din),
        .detected (detected)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 10 ns period
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: apply_bit
    //   Mealy FSM: detected is combinational (current state + current din).
    //   Correct sampling point is BEFORE posedge, after #1 for logic to settle.
    //   Then advance clock so state transitions for the next bit.
    // -------------------------------------------------------------------------
    task apply_bit;
        input bit_in;
        input exp_detect;
        begin
            din = bit_in;
            expected_detect = exp_detect;
            #1; // Let combinational logic settle
            if (detected !== exp_detect) begin
                $display("  FAIL  [%02d] t=%0t  din=%b  state=%0d  detected=%b  exp=%b",
                         test_num, $time, bit_in, dut.state, detected, exp_detect);
                error_count = error_count + 1;
            end else begin
                $display("  PASS  [%02d] t=%0t  din=%b  state=%0d  detected=%b",
                         test_num, $time, bit_in, dut.state, detected);
            end
            test_num = test_num + 1;
            @(posedge clk); #1; // Advance one clock cycle
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: do_reset
    //   Assert reset for one clock cycle then release.
    //   State returns to S0 on next posedge after release.
    // -------------------------------------------------------------------------
    task do_reset;
        begin
            rst_n = 1'b0;
            din   = 1'b0;
            @(posedge clk); #1;
            rst_n = 1'b1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $timeformat(-12, 0, "", 8); // Set time format to ns, 0 decimal places, no unit string, 8 characters wide

        error_count = 0;
        test_num    = 1;
        rst_n = 1'b0;
        din   = 1'b0;

        $display("=============================================================");
        $display("=== fsm_sequence_detector_tb  |  Target sequence: \"1011\" ===");
        $display("=============================================================");

        @(posedge clk); #2;
        rst_n = 1'b1;

        // -----------------------------------------------------------------
        // TC1: Basic stream with overlapping matches
        //   Stream : 1-0-1-1-0-1-1-1
        //   Detect :         ^       ^
        //   Overlap: last '1' of first match begins next match (10[1]1)
        // -----------------------------------------------------------------
        $display("--- TC1: Basic stream 1-0-1-1-0-1-1-1 (overlap check) ------");
        apply_bit(1'b1, 1'b0); // S0->S1
        apply_bit(1'b0, 1'b0); // S1->S2
        apply_bit(1'b1, 1'b0); // S2->S3
        apply_bit(1'b1, 1'b1); // S3->S1  DETECT (1011 complete)
        apply_bit(1'b0, 1'b0); // S1->S2
        apply_bit(1'b1, 1'b0); // S2->S3
        apply_bit(1'b1, 1'b1); // S3->S1  DETECT (overlap: 1[011])
        apply_bit(1'b1, 1'b0); // S1->S1  no detect

        // -----------------------------------------------------------------
        // TC2: All zeros - no detection expected
        // -----------------------------------------------------------------
        $display("--- TC2: All zeros 0-0-0-0 (no detect) --------------------");
        do_reset;
        apply_bit(1'b0, 1'b0);
        apply_bit(1'b0, 1'b0);
        apply_bit(1'b0, 1'b0);
        apply_bit(1'b0, 1'b0);

        // -----------------------------------------------------------------
        // TC3: All ones - no detection expected
        //   S0+1->S1, S1+1->S1, S1+1->S1, ...
        // -----------------------------------------------------------------
        $display("--- TC3: All ones 1-1-1-1 (no detect) ---------------------");
        do_reset;
        apply_bit(1'b1, 1'b0);
        apply_bit(1'b1, 1'b0);
        apply_bit(1'b1, 1'b0);
        apply_bit(1'b1, 1'b0);

        // -----------------------------------------------------------------
        // TC4: Reset mid-sequence, then complete a fresh 1011
        //   Verifies state correctly clears on rst_n
        // -----------------------------------------------------------------
        $display("--- TC4: Reset mid-sequence (1-0-1 | rst | 1-0-1-1) -------");
        do_reset;
        apply_bit(1'b1, 1'b0); // S0->S1
        apply_bit(1'b0, 1'b0); // S1->S2
        apply_bit(1'b1, 1'b0); // S2->S3  (partial match, would detect on next 1)
        do_reset;               // Reset while in S3 - state must go to S0
        apply_bit(1'b1, 1'b0); // S0->S1  (not S3->detect)
        apply_bit(1'b0, 1'b0); // S1->S2
        apply_bit(1'b1, 1'b0); // S2->S3
        apply_bit(1'b1, 1'b1); // S3->S1  DETECT - clean match after reset

        // -----------------------------------------------------------------
        // TC5: False starts then final detection
        //   Stream: 1-0-1-0-1-0-1-1
        //   False starts at positions 1,3,5 - real detection at last 1011
        // -----------------------------------------------------------------
        $display("--- TC5: False starts 1-0-1-0-1-0-1-1 (detect at end) -----");
        do_reset;
        apply_bit(1'b1, 1'b0); // S0->S1
        apply_bit(1'b0, 1'b0); // S1->S2
        apply_bit(1'b1, 1'b0); // S2->S3
        apply_bit(1'b0, 1'b0); // S3->S2  no detect (broken by 0)
        apply_bit(1'b1, 1'b0); // S2->S3
        apply_bit(1'b0, 1'b0); // S3->S2  no detect (broken again)
        apply_bit(1'b1, 1'b0); // S2->S3
        apply_bit(1'b1, 1'b1); // S3->S1  DETECT (1011 at bits 5-8)

        // -----------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------
        $display("=============================================================");
        if (error_count == 0)
            $display("=== PASS: all %0d test vectors matched ===", test_num - 1);
        else
            $display("=== FAIL: %0d mismatches out of %0d vectors ===",
                     error_count, test_num - 1);
        $display("=============================================================");

        $finish;
    end

endmodule
