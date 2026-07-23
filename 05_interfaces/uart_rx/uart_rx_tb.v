/*******************************************************************************
 * Module: uart_rx_tb.v                                                        *
 * Description: Directed self-checking testbench for the UART receiver.       *
 * File Created: Tuesday, 21st July 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 22nd July 2026                                      *
 * Modified By: Long Hai                                                       *
 *******************************************************************************/

`timescale 1ns/1ps

module uart_rx_tb;

    localparam integer CLK_FREQ_HZ  = 8_000_000;
    localparam integer BAUD_RATE    = 1_000_000;
    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    // 0x69 = 8'b01101001 — alternating-group pattern that exercises both
    // noise-resilience (each bit flips near the end) and LSB-first ordering.
    localparam [7:0] NOISE_BYTE = 8'h69;

    reg        clk;
    reg        rst_n;
    reg        rx;
    wire [7:0] data_out;
    wire       rx_busy;
    wire       rx_done_valid;
    wire       framing_error;

    integer pass_count;
    integer fail_count;
    integer done_count;
    integer error_count;
    integer i;
    integer count_before;
    reg [7:0] previous_data;

    uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(data_out),
        .rx_busy(rx_busy),
        .rx_done_valid(rx_done_valid),
        .framing_error(framing_error)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Autonomous event counters — increment whenever the DUT pulses each output.
    always @(posedge clk) begin
        if (!rst_n) begin
            done_count <= 0;
            error_count <= 0;
        end else begin
            if (rx_done_valid) done_count <= done_count + 1;
            if (framing_error) error_count <= error_count + 1;
        end
    end

    // -------------------------------------------------------------------------
    // Utility tasks
    // -------------------------------------------------------------------------

    task check;
        input cond;
        input [8*120-1:0] msg;
        begin
            if (cond) begin
                pass_count = pass_count + 1;
                $display("[%0t] PASS: %0s", $time, msg);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t] FAIL: %0s", $time, msg);
            end
        end
    endtask

    // Drive rx at a fixed level for exactly one full bit period.
    task hold_bit;
        input level;
        begin
            rx = level;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    // Assert reset, verify all outputs clear, then release.
    task apply_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            rx    = 1'b1;
            repeat (3) @(posedge clk);
            #1;
            check((data_out === 8'h00) && (rx_busy === 1'b0) &&
                  (rx_done_valid === 1'b0) && (framing_error === 1'b0),
                  "Reset restores receiver outputs");
            @(negedge clk);
            rst_n = 1'b1;
            repeat (3) @(posedge clk);
        end
    endtask

    // Drive a complete 8N1 frame, with a configurable stop-bit level.
    // Leaves rx HIGH and waits 4 clocks for DUT outputs to settle.
    task drive_frame;
        input [7:0] payload;
        input       stop_level;
        begin
            @(negedge clk);
            hold_bit(1'b0);                          // start bit
            for (i = 0; i < 8; i = i + 1)
                hold_bit(payload[i]);                // D0–D7 LSB-first
            hold_bit(stop_level);                    // stop bit (valid or injected error)
            rx = 1'b1;
            repeat (4) @(posedge clk);
            #1;
        end
    endtask

    // Drive a complete 8N1 frame immediately after the current clock edge
    // (no @negedge alignment), allowing back-to-back frame testing.
    task drive_frame_no_gap;
        input [7:0] payload;
        begin
            hold_bit(1'b0);
            for (i = 0; i < 8; i = i + 1)
                hold_bit(payload[i]);
            hold_bit(1'b1);
        end
    endtask

    // Drive a frame where each data bit flips to its complement during the
    // final 2 clocks of its wire period, simulating late-edge signal noise.
    //
    // Why the FSM still samples correctly:
    //   STATE_START waits HALF_BIT clocks before entering STATE_DATA, so the
    //   FSM's baud_count is phase-shifted by HALF_BIT relative to the bit
    //   boundary on the wire.  When baud_count reaches CLKS_PER_BIT-1, it
    //   points to the CENTER of the data bit (HALF_BIT clocks into the bit),
    //   not the end.  Noise is injected at CLKS_PER_BIT-2 from the bit start,
    //   which is 2 clocks AFTER the sample point → no corruption.
    task drive_frame_with_late_noise;
        input [7:0] payload;
        begin
            @(negedge clk);
            hold_bit(1'b0);                          // start bit — no noise
            for (i = 0; i < 8; i = i + 1) begin
                rx = payload[i];
                repeat (CLKS_PER_BIT - 2) @(posedge clk); // stable at center
                rx = ~payload[i];                    // inject noise near bit edge
                repeat (2) @(posedge clk);           // hold noise briefly
            end
            hold_bit(1'b1);                          // stop bit — no noise
            rx = 1'b1;
            repeat (4) @(posedge clk);
            #1;
        end
    endtask

    // Drive a valid frame and assert all four standard post-frame conditions.
    task receive_and_check;
        input [7:0] payload;
        input [8*120-1:0] msg;
        integer valid_before;
        integer error_before;
        begin
            valid_before = done_count;
            error_before = error_count;
            drive_frame(payload, 1'b1);
            check(done_count == (valid_before + 1), "Valid frame creates one rx_done_valid pulse");
            check(error_count == error_before,       "Valid frame does not create framing_error");
            check((rx_busy === 1'b0) && (rx_done_valid === 1'b0) &&
                  (framing_error === 1'b0), "Receiver returns to idle after valid frame");
            check(data_out === payload, msg);
        end
    endtask

    // -------------------------------------------------------------------------
    // Watchdog
    // -------------------------------------------------------------------------

    initial begin
        #30_000;
        $display("[FAIL] Timeout waiting for UART RX testbench completion");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------

    initial begin
        pass_count    = 0;
        fail_count    = 0;
        done_count   = 0;
        error_count   = 0;
        rst_n         = 1'b1;
        rx            = 1'b1;
        previous_data = 8'h00;

        $display("=== uart_rx Testbench (directed self-check) ===");

        // TC1: Reset clears all outputs; idle-high line does not trigger a frame.
        $display("\n--- TC1: Reset and idle behavior ---");
        apply_reset();
        repeat (3 * CLKS_PER_BIT) @(posedge clk); #1;
        check((rx_busy === 1'b0) && (rx_done_valid === 1'b0) &&
              (framing_error === 1'b0), "Idle-high line does not start a frame");

        // TC2: Representative and boundary payloads decoded correctly.
        $display("\n--- TC2: Alternating and boundary patterns ---");
        receive_and_check(8'h55, "0x55 decoded correctly");
        receive_and_check(8'hA3, "0xA3 decoded correctly");
        receive_and_check(8'h00, "0x00 (all-zero) decoded correctly");
        receive_and_check(8'hFF, "0xFF (all-one) decoded correctly");

        // TC3: Two frames sent with no idle gap between stop and next start.
        $display("\n--- TC3: Back-to-back frames ---");
        count_before = done_count;
        @(negedge clk);
        drive_frame_no_gap(8'h3C);
        check(data_out === 8'h3C, "Frame 1 (0x3C) decoded correctly");
        drive_frame_no_gap(8'hC3);
        rx = 1'b1;
        repeat (4) @(posedge clk); #1;
        check(data_out === 8'hC3, "Frame 2 (0xC3) decoded correctly");
        check(done_count == (count_before + 2), "Two back-to-back frames produce two rx_done_valid pulses");
        check((rx_busy === 1'b0) && (framing_error === 1'b0),
              "Receiver is idle after back-to-back frames");

        // TC4: A short LOW glitch (< HALF_BIT) is rejected as a false start.
        $display("\n--- TC4: False-start rejection ---");
        previous_data = data_out;
        count_before  = done_count;
        @(negedge clk);
        rx = 1'b0;
        repeat (2) @(posedge clk);    // 2 clocks < HALF_BIT (4 clocks) — too short
        rx = 1'b1;
        repeat (2 * CLKS_PER_BIT) @(posedge clk); #1;
        check(done_count == count_before,    "Short LOW pulse rejected; no rx_done_valid asserted");
        check(data_out === previous_data,     "False start does not overwrite data_out");
        check((rx_busy === 1'b0) && (framing_error === 1'b0),
              "False start returns receiver to idle without an error");

        // TC5: A LOW stop bit triggers framing_error and leaves data_out unchanged;
        //      receiver must accept a new valid frame immediately after.
        $display("\n--- TC5: Framing-error detection and recovery ---");
        previous_data = data_out;
        count_before  = error_count;
        drive_frame(8'h5A, 1'b0);
        check(error_count == (count_before + 1), "Low stop bit triggers framing_error");
        check(data_out === previous_data,        "data_out preserved after framing error");
        receive_and_check(8'h96, "Receiver recovers and accepts next valid frame");

        // TC6: Each bit flips to its complement in the last 2 wire-clocks of the
        //      bit period.  Because STATE_START's HALF_BIT wait phase-shifts the
        //      FSM by HALF_BIT clocks, baud_count == CLKS_PER_BIT-1 lands at the
        //      CENTER of each bit (HALF_BIT clocks in), not the end.  The sample
        //      therefore occurs 2 clocks BEFORE the noise, so data is unaffected.
        $display("\n--- TC6: Noise after center sample is tolerated ---");
        drive_frame_with_late_noise(NOISE_BYTE);
        check(data_out === NOISE_BYTE, "Noise after center sample does not corrupt data");

        // TC7: Assert reset after the start bit and D0 have been transmitted —
        //      the FSM is mid-frame and rx_busy is HIGH.  Reset must immediately
        //      return the receiver to idle without producing rx_done_valid or
        //      framing_error, and the DUT must then accept a new frame cleanly.
        $display("\n--- TC7: Reset aborts an active frame ---");
        @(negedge clk);
        hold_bit(1'b0); // start bit
        hold_bit(1'b1); // D0 — receiver is now in STATE_DATA
        rst_n = 1'b0;
        repeat (2) @(posedge clk); #1;
        check((rx_busy === 1'b0) && (rx_done_valid === 1'b0) &&
              (framing_error === 1'b0), "Reset aborts an active receive operation");
        rx = 1'b1;
        @(negedge clk);
        rst_n = 1'b1;
        repeat (3) @(posedge clk);
        receive_and_check(8'hF0, "Receiver accepts a new frame after reset abort");

        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: 7 TCs, all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: 7 TCs, %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
