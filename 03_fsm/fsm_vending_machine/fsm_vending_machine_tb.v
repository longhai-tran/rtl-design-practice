/*******************************************************************************
 * Module      : fsm_vending_machine_tb                                        *
 * File        : fsm_vending_machine_tb.v                                      *
 * Description : Self-checking testbench for fsm_vending_machine.              *
 *               Verifies all legal coin sequences leading to vend/change       *
 *               outputs, mid-sequence reset behaviour, and input corner cases. *
 * File Created: Thursday, 16th April 2026 11:54:11 am                        *
 * Author      : Long Hai                                                      *
 * -----                                                                       *
 * Last Modified: Sunday, 20th April 2026 2:54:00 pm                          *
 * Modified By : Long Hai                                                      *
 *******************************************************************************
 *
 * Test Plan:
 *   TC1 : S0 --(5u)--> S5  --(10u)--> S0  : vend=1, change=0  (5+10=15u)
 *   TC2 : S0 --(10u)--> S10 --(10u)--> S0 : vend=1, change=1  (10+10=20u)
 *   TC3 : S0 --(5u)--> S5  --(5u)-->  S10 --(5u)--> S0        (5+5+5=15u)
 *                                           vend=1, change=0
 *   TC4 : S0 --(10u)--> S10 --(5u)--> S0  : vend=1, change=0  (10+5=15u)
 *   TC5 : S0 --(5u)--> S5  then rst_n -> S0 : verify mid-sequence reset
 *   TC6 : S0 --(coin_5 & coin_10 simultaneously) : coin_10 wins (priority check)
 *
 ******************************************************************************/

`timescale 1ns/1ps

module fsm_vending_machine_tb;

    // -------------------------------------------------------------------------
    // DUT signal declarations
    // -------------------------------------------------------------------------
    reg  clk;
    reg  rst_n;
    reg  coin_5;
    reg  coin_10;
    wire vend;
    wire change_5;

    // -------------------------------------------------------------------------
    // Scoreboard counters
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    fsm_vending_machine dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .coin_5   (coin_5),
        .coin_10  (coin_10),
        .vend     (vend),
        .change_5 (change_5)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 100 MHz (period = 10 ns)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: apply_coin
    //   Drive coin inputs for one clock cycle, then sample outputs and compare
    //   against expected values. Coins are de-asserted after sampling.
    //
    //   Arguments:
    //     c5         : drive coin_5 for this cycle
    //     c10        : drive coin_10 for this cycle
    //     exp_vend   : expected vend output after the rising edge
    //     exp_change : expected change_5 output after the rising edge
    //     desc       : string label printed with PASS/FAIL message
    // -------------------------------------------------------------------------
    task apply_coin;
        input      c5;
        input      c10;
        input      exp_vend;
        input      exp_change;
        input [63:0] desc;       // 8-char ASCII label (e.g. "TC1_coin")
        begin
            coin_5  = c5;
            coin_10 = c10;
            @(posedge clk); #1; // Sample 1 ns after rising edge (post-clock)

            if ((vend !== exp_vend) || (change_5 !== exp_change)) begin
                $display("[FAIL] %-8s  t=%0t ns | c5=%b c10=%b | vend=%b(exp %b) chg=%b(exp %b)",
                         desc, $time, c5, c10,
                         vend, exp_vend, change_5, exp_change);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %-8s  t=%0t ns | c5=%b c10=%b | vend=%b chg=%b",
                         desc, $time, c5, c10, vend, change_5);
                pass_count = pass_count + 1;
            end

            // De-assert both coin inputs before next cycle
            coin_5  = 1'b0;
            coin_10 = 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: do_reset
    //   Assert rst_n low for N cycles then release.
    // -------------------------------------------------------------------------
    task do_reset;
        input integer cycles;
        begin
            rst_n = 1'b0;
            repeat (cycles) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk); // Allow one free cycle after reset release
        end
    endtask

    // -------------------------------------------------------------------------
    // Main stimulus
    // -------------------------------------------------------------------------
    initial begin
        // Initialise scoreboard and inputs
        pass_count = 0;
        fail_count = 0;
        coin_5     = 1'b0;
        coin_10    = 1'b0;

        $display("=========================================================");
        $display("===  fsm_vending_machine_tb ===");
        $display("=========================================================");

        // -----------------------------------------------------------------
        // Initial reset (3 cycles – ensures all FFs reach known state)
        // -----------------------------------------------------------------
        do_reset(3);
        $display("---------------------------------------------------------");
        $display("  TC1: 5u + 10u = 15u -> vend=1, change=0");
        $display("---------------------------------------------------------");
        // S0 --(coin_5)--> S5: no dispense yet
        apply_coin(1'b1, 1'b0, 1'b0, 1'b0, "TC1_c5  ");
        // S5 --(coin_10)--> S0: dispense, no change
        apply_coin(1'b0, 1'b1, 1'b1, 1'b0, "TC1_c10 ");

        $display("---------------------------------------------------------");
        $display("  TC2: 10u + 10u = 20u -> vend=1, change=1");
        $display("---------------------------------------------------------");
        // S0 --(coin_10)--> S10: no dispense yet
        apply_coin(1'b0, 1'b1, 1'b0, 1'b0, "TC2_c10 ");
        // S10 --(coin_10)--> S0: dispense + change
        apply_coin(1'b0, 1'b1, 1'b1, 1'b1, "TC2_c10b");

        $display("---------------------------------------------------------");
        $display("  TC3: 5u + 5u + 5u = 15u -> vend=1, change=0");
        $display("---------------------------------------------------------");
        // S0 --(coin_5)--> S5
        apply_coin(1'b1, 1'b0, 1'b0, 1'b0, "TC3_c5a ");
        // S5 --(coin_5)--> S10
        apply_coin(1'b1, 1'b0, 1'b0, 1'b0, "TC3_c5b ");
        // S10 --(coin_5)--> S0: dispense, no change
        apply_coin(1'b1, 1'b0, 1'b1, 1'b0, "TC3_c5c ");

        $display("---------------------------------------------------------");
        $display("  TC4: 10u + 5u = 15u -> vend=1, change=0");
        $display("---------------------------------------------------------");
        // S0 --(coin_10)--> S10
        apply_coin(1'b0, 1'b1, 1'b0, 1'b0, "TC4_c10 ");
        // S10 --(coin_5)--> S0: dispense, no change
        apply_coin(1'b1, 1'b0, 1'b1, 1'b0, "TC4_c5  ");

        $display("---------------------------------------------------------");
        $display("  TC5: Mid-sequence reset recovery");
        $display("---------------------------------------------------------");
        // S0 --(coin_5)--> S5: accumulate 5 units
        apply_coin(1'b1, 1'b0, 1'b0, 1'b0, "TC5_c5  ");
        // Assert reset mid-sequence (3 cycles) -> expect S0
        $display("        [INFO] Asserting reset mid-sequence...");
        do_reset(3);
        // After reset: S0 --(coin_10)--> S10, still no dispense
        apply_coin(1'b0, 1'b1, 1'b0, 1'b0, "TC5_rst ");
        // S10 --(coin_5)--> S0: dispense, no change (confirms we are in S10, not S5)
        apply_coin(1'b1, 1'b0, 1'b1, 1'b0, "TC5_disc");

        $display("---------------------------------------------------------");
        $display("  TC6: coin_5 & coin_10 simultaneously (coin_10 priority)");
        $display("---------------------------------------------------------");
        // Both asserted: coin_10 takes priority -> S0 --(coin_10)--> S10
        apply_coin(1'b1, 1'b1, 1'b0, 1'b0, "TC6_both");
        // S10 --(coin_5)--> S0: dispense, no change (confirms state = S10)
        apply_coin(1'b1, 1'b0, 1'b1, 1'b0, "TC6_disc");

        // -----------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------
        $display("=========================================================");
        $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count == 0)
            $display("  STATUS : ** ALL TESTS PASSED **");
        else
            $display("  STATUS : ** %0d TEST(S) FAILED **", fail_count);
        $display("=========================================================");

        $finish;
    end

endmodule
