/*******************************************************************************
 * Module      : fsm_traffic_light_tb
 * Description : Self-checking testbench for fsm_traffic_light.
 *
 * Test plan   :
 *   TC1 – Reset assertion: verify FSM starts in NS_G with correct outputs.
 *   TC2 – Full cycle: verify each phase holds for the correct number of cycles
 *          and outputs the correct light colours.
 *   TC3 – Safety invariant: NS and EW are NEVER simultaneously GREEN (entire run).
 *   TC4 – Mid-run reset: assert reset mid-sequence, verify clean return to NS_G.
 *   TC5 – Second full cycle: confirm FSM loops correctly after one full rotation.
 *
 * Parameters  (must match DUT instantiation below)
 *   GREEN_CYCLES  = 4
 *   YELLOW_CYCLES = 2
 *
 * File Created: Thursday, 16th April 2026 11:54:11 am
 * Author      : Long Hai
 * Last Modified: Friday, 17th April 2026
 *******************************************************************************/

`timescale 1ns/1ps

module fsm_traffic_light_tb;

    // -------------------------------------------------------------------------
    // Parameters – mirror the DUT instantiation values
    // -------------------------------------------------------------------------
    localparam integer GREEN_CYCLES  = 4;
    localparam integer YELLOW_CYCLES = 2;

    // Total cycles for one complete light rotation (NS_G→NS_Y→EW_G→EW_Y)
    localparam integer FULL_CYCLE = 2 * GREEN_CYCLES + 2 * YELLOW_CYCLES;

    // -------------------------------------------------------------------------
    // Light colour encoding (must match DUT)
    // -------------------------------------------------------------------------
    localparam [1:0]
        RED    = 2'b00,
        YELLOW = 2'b01,
        GREEN  = 2'b10;

    // -------------------------------------------------------------------------
    // DUT port connections
    // -------------------------------------------------------------------------
    reg  clk;
    reg  rst_n;
    wire [1:0] ns_light;
    wire [1:0] ew_light;

    // -------------------------------------------------------------------------
    // Verification bookkeeping
    // -------------------------------------------------------------------------
    integer error_count;
    integer i;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    fsm_traffic_light #(
        .GREEN_CYCLES  (GREEN_CYCLES),
        .YELLOW_CYCLES (YELLOW_CYCLES)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .ns_light (ns_light),
        .ew_light (ew_light)
    );

    // -------------------------------------------------------------------------
    // Clock generation — 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Waveform dump (VCD – portable across tools)
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("fsm_traffic_light_tb.vcd");
        $dumpvars(0, fsm_traffic_light_tb);
    end

    // -------------------------------------------------------------------------
    // Helper function: decode 2-bit light code → colour string
    // -------------------------------------------------------------------------
    function [55:0] color_name;
        input [1:0] code;
        begin
            case (code)
                RED    : color_name = "RED    ";
                YELLOW : color_name = "YELLOW ";
                GREEN  : color_name = "GREEN  ";
                default: color_name = "???    ";
            endcase
        end
    endfunction

    // -------------------------------------------------------------------------
    // Task: continuous safety check (TC3)
    //   Call every cycle. Fails if both roads are simultaneously GREEN.
    // -------------------------------------------------------------------------
    task check_safe;
        begin
            if (ns_light == GREEN && ew_light == GREEN) begin
                $display("[FAIL][TC3] t=%0t  Safety violation: NS=GREEN and EW=GREEN simultaneously!",
                         $time);
                error_count = error_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: check that a single phase holds the correct colour for N cycles
    //
    //   phase_name  – ASCII label for display (e.g. "NS_G")
    //   tc_id       – test-case number for output tagging
    //   exp_ns      – expected ns_light value during this phase
    //   exp_ew      – expected ew_light value during this phase
    //   duration    – number of cycles this phase should last
    // -------------------------------------------------------------------------
    task check_phase;
        input [31:0]  tc_id;
        input [63:0]  phase_name;
        input [1:0]   exp_ns;
        input [1:0]   exp_ew;
        input integer duration;
        integer       j;
        begin
            for (j = 0; j < duration; j = j + 1) begin
                check_safe;
                if (ns_light !== exp_ns || ew_light !== exp_ew) begin
                    $display("[FAIL][TC%0d] %6s cycle %0d  t=%0t: ns=%s ew=%s  (expected ns=%s ew=%s)",
                             tc_id, phase_name, j, $time,
                             color_name(ns_light), color_name(ew_light),
                             color_name(exp_ns),   color_name(exp_ew));
                    error_count = error_count + 1;
                end else begin
                    $display("[PASS][TC%0d] %4s cycle %0d  t=%0t  ns=%s ew=%s",
                             tc_id, phase_name, j, $time,
                             color_name(ns_light), color_name(ew_light));
                end
                @(posedge clk); #1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Main stimulus
    // -------------------------------------------------------------------------
    initial begin
        error_count = 0;

        $display("===========================================================");
        $display("  fsm_traffic_light_tb  (GREEN=%0d, YELLOW=%0d)",
                  GREEN_CYCLES, YELLOW_CYCLES);
        $display("===========================================================");

        // -------------------------------------------------------------------
        // TC1 – Reset assertion
        // -------------------------------------------------------------------
        $display("\n--- TC1: Reset assertion ---");
        rst_n = 1'b0;
        @(posedge clk); #1;

        if (ns_light !== GREEN || ew_light !== RED) begin
            $display("[FAIL][TC1] After reset: ns=%s ew=%s  (expected ns=GREEN ew=RED)",
                     color_name(ns_light), color_name(ew_light));
            error_count = error_count + 1;
        end else begin
            $display("[PASS][TC1] After reset: ns=%s ew=%s",
                     color_name(ns_light), color_name(ew_light));
        end

        // -------------------------------------------------------------------
        // TC2 – Full cycle: verify phase durations and output colours
        // -------------------------------------------------------------------
        $display("\n--- TC2: Full cycle phase verification ---");
        rst_n = 1'b1;

        check_phase(2, "NS_G", GREEN, RED,    GREEN_CYCLES);
        check_phase(2, "NS_Y", YELLOW, RED,   YELLOW_CYCLES);
        check_phase(2, "EW_G", RED,   GREEN,  GREEN_CYCLES);
        check_phase(2, "EW_Y", RED,   YELLOW, YELLOW_CYCLES);

        // -------------------------------------------------------------------
        // TC4 – Mid-run reset
        //   Run 2 cycles into EW_G, then assert reset and verify NS_G recovery.
        // -------------------------------------------------------------------
        $display("\n--- TC4: Mid-run reset ---");

        // Advance 2 cycles into NS_G of the second rotation
        @(posedge clk); #1;
        @(posedge clk); #1;

        // Assert reset
        rst_n = 1'b0;
        @(posedge clk); #1;

        if (ns_light !== GREEN || ew_light !== RED) begin
            $display("[FAIL][TC4] After mid-run reset: ns=%s ew=%s  (expected ns=GREEN ew=RED)",
                     color_name(ns_light), color_name(ew_light));
            error_count = error_count + 1;
        end else begin
            $display("[PASS][TC4] Mid-run reset: FSM correctly returned to NS_G  t=%0t", $time);
        end

        // -------------------------------------------------------------------
        // TC5 – Second full cycle (after TC4 reset)
        // -------------------------------------------------------------------
        $display("\n--- TC5: Second full cycle after reset ---");
        rst_n = 1'b1;

        check_phase(5, "NS_G", GREEN, RED,    GREEN_CYCLES);
        check_phase(5, "NS_Y", YELLOW, RED,   YELLOW_CYCLES);
        check_phase(5, "EW_G", RED,   GREEN,  GREEN_CYCLES);
        check_phase(5, "EW_Y", RED,   YELLOW, YELLOW_CYCLES);

        // -------------------------------------------------------------------
        // Summary
        // -------------------------------------------------------------------
        $display("\n===========================================================");
        if (error_count == 0)
            $display("  RESULT: PASS - all %0d test cases passed, 0 errors.",
                      5);
        else
            $display("  RESULT: FAIL - %0d error(s) detected.", error_count);
        $display("===========================================================");

        $finish;
    end

endmodule
