/*******************************************************************************
 * Module: spi_top_tb.v                                                        *
 * Description: Self-checking integration testbench for the SPI master/slave   *
 *              top across all four SPI modes (0-3).                           *
 * File Created: Tuesday, 28th July 2026 11:45:56 am                           *
 * Author: Long Hai                                                             *
 * -----                                                                        *
 * Last Modified: Tuesday, 29th July 2026 3:36:00 pm                           *
 * Modified By: Long Hai                                                        *
 *******************************************************************************/

`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// Test strategy: 4 DUT instances are elaborated in parallel — one per SPI
// mode (CPOL,CPHA) — so a single `active_mode` selector routes stimulus to
// exactly one DUT at a time.  This avoids re-elaboration between modes and
// lets all four idle-SCLK levels be checked simultaneously at reset.
// ---------------------------------------------------------------------------
module spi_top_tb;

    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    localparam integer DATA_WIDTH = 8;   // payload width (bits)
    localparam integer CLK_DIV    = 3;   // SCLK = sys_clk / (2*CLK_DIV)

    // -----------------------------------------------------------------------
    // Stimulus signals (driven by the testbench)
    // -----------------------------------------------------------------------
    reg                   clk;
    reg                   rst_n;          // active-low synchronous reset
    reg                   start_cmd;      // 1-cycle start pulse to spi_top
    reg  [DATA_WIDTH-1:0] master_tx_data; // byte the master sends to slave
    reg  [DATA_WIDTH-1:0] slave_tx_data;  // byte the slave sends to master
    reg  [1:0]            active_mode;    // selects which DUT is under test

    // -----------------------------------------------------------------------
    // DUT output buses — one entry per SPI mode
    //   index 0: Mode 0 (CPOL=0, CPHA=0)
    //   index 1: Mode 1 (CPOL=0, CPHA=1)
    //   index 2: Mode 2 (CPOL=1, CPHA=0)
    //   index 3: Mode 3 (CPOL=1, CPHA=1)
    // -----------------------------------------------------------------------
    wire [3:0] sclk_bus;
    wire [3:0] mosi_bus;
    wire [3:0] miso_bus;
    wire [3:0] cs_n_bus;
    wire [3:0] master_busy_bus;
    wire [3:0] master_done_bus;
    wire [3:0] slave_busy_bus;
    wire [3:0] slave_done_bus;

    wire [DATA_WIDTH-1:0] master_rx0, master_rx1, master_rx2, master_rx3;
    wire [DATA_WIDTH-1:0] slave_rx0,  slave_rx1,  slave_rx2,  slave_rx3;

    // -----------------------------------------------------------------------
    // "Active" aliases — always reflect the DUT selected by `active_mode`
    // -----------------------------------------------------------------------
    wire                  active_sclk;
    wire                  active_mosi;
    wire                  active_miso;
    wire                  active_cs_n;
    wire                  active_master_busy;
    wire                  active_master_done;
    wire                  active_slave_busy;
    wire                  active_slave_done;
    wire [DATA_WIDTH-1:0] active_master_rx;
    wire [DATA_WIDTH-1:0] active_slave_rx;

    // -----------------------------------------------------------------------
    // Scoreboard counters
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer master_done_count; // cumulative master_done pulses (active DUT)
    integer slave_done_count;  // cumulative slave_done  pulses (active DUT)
    integer edge_count;        // SCLK edges counted during a transaction
    integer count_before;      // snapshot of master_done_count before TC4

    // -----------------------------------------------------------------------
    // Active-mode mux: route the selected DUT's outputs to a single alias
    // -----------------------------------------------------------------------
    assign active_sclk        = sclk_bus[active_mode];
    assign active_mosi        = mosi_bus[active_mode];
    assign active_miso        = miso_bus[active_mode];
    assign active_cs_n        = cs_n_bus[active_mode];
    assign active_master_busy = master_busy_bus[active_mode];
    assign active_master_done = master_done_bus[active_mode];
    assign active_slave_busy  = slave_busy_bus[active_mode];
    assign active_slave_done  = slave_done_bus[active_mode];

    assign active_master_rx = (active_mode == 2'd0) ? master_rx0 :
                              (active_mode == 2'd1) ? master_rx1 :
                              (active_mode == 2'd2) ? master_rx2 : master_rx3;
    assign active_slave_rx  = (active_mode == 2'd0) ? slave_rx0  :
                              (active_mode == 2'd1) ? slave_rx1  :
                              (active_mode == 2'd2) ? slave_rx2  : slave_rx3;

    // -----------------------------------------------------------------------
    // DUT instantiation — all four modes run concurrently.
    // The `start` input is gated so only the selected DUT receives the pulse.
    // CPOL encoding: mode bit[1] => CPOL=0 for modes 0/1, CPOL=1 for modes 2/3
    // CPHA encoding: mode bit[0] => CPHA=0 for modes 0/2, CPHA=1 for modes 1/3
    // -----------------------------------------------------------------------
    spi_top #(.DATA_WIDTH(DATA_WIDTH), .CLK_DIV(CLK_DIV), .CPOL(0), .CPHA(0)) dut0 (
        .clk(clk), .rst_n(rst_n), .start(start_cmd && (active_mode == 0)),
        .master_tx_data(master_tx_data), .slave_tx_data(slave_tx_data),
        .master_rx_data(master_rx0), .slave_rx_data(slave_rx0),
        .master_busy(master_busy_bus[0]), .master_done(master_done_bus[0]),
        .slave_busy(slave_busy_bus[0]),   .slave_done(slave_done_bus[0]),
        .sclk(sclk_bus[0]), .mosi(mosi_bus[0]), .miso(miso_bus[0]), .cs_n(cs_n_bus[0])
    );
    spi_top #(.DATA_WIDTH(DATA_WIDTH), .CLK_DIV(CLK_DIV), .CPOL(0), .CPHA(1)) dut1 (
        .clk(clk), .rst_n(rst_n), .start(start_cmd && (active_mode == 1)),
        .master_tx_data(master_tx_data), .slave_tx_data(slave_tx_data),
        .master_rx_data(master_rx1), .slave_rx_data(slave_rx1),
        .master_busy(master_busy_bus[1]), .master_done(master_done_bus[1]),
        .slave_busy(slave_busy_bus[1]),   .slave_done(slave_done_bus[1]),
        .sclk(sclk_bus[1]), .mosi(mosi_bus[1]), .miso(miso_bus[1]), .cs_n(cs_n_bus[1])
    );
    spi_top #(.DATA_WIDTH(DATA_WIDTH), .CLK_DIV(CLK_DIV), .CPOL(1), .CPHA(0)) dut2 (
        .clk(clk), .rst_n(rst_n), .start(start_cmd && (active_mode == 2)),
        .master_tx_data(master_tx_data), .slave_tx_data(slave_tx_data),
        .master_rx_data(master_rx2), .slave_rx_data(slave_rx2),
        .master_busy(master_busy_bus[2]), .master_done(master_done_bus[2]),
        .slave_busy(slave_busy_bus[2]),   .slave_done(slave_done_bus[2]),
        .sclk(sclk_bus[2]), .mosi(mosi_bus[2]), .miso(miso_bus[2]), .cs_n(cs_n_bus[2])
    );
    spi_top #(.DATA_WIDTH(DATA_WIDTH), .CLK_DIV(CLK_DIV), .CPOL(1), .CPHA(1)) dut3 (
        .clk(clk), .rst_n(rst_n), .start(start_cmd && (active_mode == 3)),
        .master_tx_data(master_tx_data), .slave_tx_data(slave_tx_data),
        .master_rx_data(master_rx3), .slave_rx_data(slave_rx3),
        .master_busy(master_busy_bus[3]), .master_done(master_done_bus[3]),
        .slave_busy(slave_busy_bus[3]),   .slave_done(slave_done_bus[3]),
        .sclk(sclk_bus[3]), .mosi(mosi_bus[3]), .miso(miso_bus[3]), .cs_n(cs_n_bus[3])
    );

    // -----------------------------------------------------------------------
    // Clock generation: 10 ns period (100 MHz)
    // -----------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -----------------------------------------------------------------------
    // Done-pulse counters (synchronous, reset-aware)
    // Counting cumulative pulses (not just level) lets TC4 verify that a
    // rejected start does NOT generate an extra completion event.
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            master_done_count <= 0;
            slave_done_count  <= 0;
        end else begin
            if (active_master_done) master_done_count <= master_done_count + 1;
            if (active_slave_done)  slave_done_count  <= slave_done_count  + 1;
        end
    end

    // -----------------------------------------------------------------------
    // SCLK edge counter (combinational/event-driven, not clock-synchronous)
    // Counts both rising AND falling edges while CS_N is asserted (low).
    // Expected value after a complete transaction: 2 * DATA_WIDTH
    // (one rising + one falling edge per bit).
    // Note: uses blocking assignment because it is not clock-synchronous.
    // -----------------------------------------------------------------------
    always @(posedge active_sclk or negedge active_sclk) begin
        if (!active_cs_n)
            edge_count = edge_count + 1;
    end

    // -----------------------------------------------------------------------
    // Task: check
    // Evaluates `cond`; increments pass_count or fail_count and prints result.
    // -----------------------------------------------------------------------
    task check;
        input             cond;
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

    // -----------------------------------------------------------------------
    // Task: apply_reset
    // Asserts rst_n for 3 clock cycles then releases it.
    // Checks that ALL four DUTs simultaneously reach their idle state:
    //   - CS_N = 1111 (all deasserted)
    //   - busy/done = 0 for every endpoint
    //   - sclk_bus = 4'b1100 because modes 2/3 have CPOL=1 (idle-high SCLK)
    //                          while modes 0/1 have CPOL=0 (idle-low  SCLK)
    // -----------------------------------------------------------------------
    task apply_reset;
        begin
            @(negedge clk);
            rst_n     = 1'b0;
            start_cmd = 1'b0;
            repeat (3) @(posedge clk);
            #1; // small delta to let combinational outputs settle

            // sclk_bus[3:0]: index 3=Mode3(CPOL=1), 2=Mode2(CPOL=1),
            //                       1=Mode1(CPOL=0), 0=Mode0(CPOL=0)
            // => idle SCLK pattern = 4'b1100
            check((cs_n_bus        === 4'b1111) &&
                  (master_busy_bus === 4'b0000) &&
                  (slave_busy_bus  === 4'b0000) &&
                  (master_done_bus === 4'b0000) &&
                  (slave_done_bus  === 4'b0000) &&
                  (sclk_bus        === 4'b1100),
                  "Reset restores all integrated SPI modes to idle");

            @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(posedge clk); // allow DUT to exit reset state
        end
    endtask

    // -----------------------------------------------------------------------
    // Task: run_transaction
    // Drives one complete SPI transaction on the selected DUT and performs
    // 9 self-checks after completion.
    //
    // Arguments:
    //   mode        — 2-bit SPI mode (0-3); also routes the start gate
    //   master_word — byte the master shifts out to the slave
    //   slave_word  — byte the slave pre-loads and shifts back to the master
    //   msg         — label printed for the master-RX data check
    // -----------------------------------------------------------------------
    task run_transaction;
        input [1:0]       mode;
        input [DATA_WIDTH-1:0] master_word;
        input [DATA_WIDTH-1:0] slave_word;
        input [8*120-1:0] msg;

        // Local snapshot variables (must be declared before begin in Verilog-2001)
        integer master_before;
        integer slave_before;
        begin
            // -- Announce transaction ----------------------------------------
            $display("[%0t] >> run_transaction: mode=%0d  master_tx=0x%02h  slave_tx=0x%02h",
                     $time, mode, master_word, slave_word);

            // -- Setup -------------------------------------------------------
            active_mode    = mode;
            master_tx_data = master_word;
            slave_tx_data  = slave_word;
            edge_count     = 0;                   // reset SCLK edge counter
            master_before  = master_done_count;   // snapshot for delta-check
            slave_before   = slave_done_count;

            // -- Issue start pulse (1 clock wide) ----------------------------
            @(negedge clk);
            start_cmd = 1'b1;
            @(posedge clk); #1;
            // Master should latch tx_data and assert busy + CS_N immediately
            check((active_master_busy === 1'b1) && (active_cs_n === 1'b0),
                  "Top accepts request and asserts master bus controls");

            @(negedge clk);
            start_cmd = 1'b0;          // deassert after one cycle
            @(posedge clk); #1;
            // Slave samples CS_N and enters busy state
            check(active_slave_busy === 1'b1,
                  "Integrated slave detects active chip select");

            // -- Wait for transaction to complete ----------------------------
            wait (active_master_done === 1'b1);
            wait (active_slave_done  === 1'b1);
            @(posedge clk); #1; // advance one cycle: done pulses should be gone

            // -- Data integrity checks ---------------------------------------
            // Master received what the slave pre-loaded
            check(active_master_rx === slave_word,  msg);
            // Slave received what the master transmitted
            check(active_slave_rx  === master_word,
                  "Integrated slave receives the master payload");

            // -- Protocol timing check ---------------------------------------
            // Each bit generates exactly one rising + one falling SCLK edge.
            check(edge_count == (2 * DATA_WIDTH),
                  "Integrated bus generates exactly two SCLK edges per bit");

            // -- Completion-event checks -------------------------------------
            // Verify exactly one done pulse per endpoint (no extra pulses)
            check(master_done_count == (master_before + 1),
                  "Master generates one completion event");
            check(slave_done_count  == (slave_before  + 1),
                  "Slave generates one completion event");
            // One clock after done was seen, both pulses must be de-asserted
            check((active_master_done === 1'b0) && (active_slave_done === 1'b0),
                  "Master and slave done pulses are one clock wide");

            // -- Idle-state checks -------------------------------------------
            check((active_master_busy === 1'b0) &&
                  (active_slave_busy  === 1'b0) && (active_cs_n === 1'b1),
                  "Both endpoints return to idle after transaction");

            // CPOL is encoded in bit[1] of the mode number:
            //   mode 0/1 → CPOL=0 → SCLK idles LOW  (mode[1]=0)
            //   mode 2/3 → CPOL=1 → SCLK idles HIGH (mode[1]=1)
            check(active_sclk === mode[1],
                  "Integrated SCLK returns to configured CPOL level");
        end
    endtask

    // -----------------------------------------------------------------------
    // Global timeout guard — prevents infinite simulation on a hung DUT
    // -----------------------------------------------------------------------
    initial begin
        #50_000;
        $display("[FAIL] Timeout waiting for SPI top testbench completion");
        $finish;
    end

    // -----------------------------------------------------------------------
    // Main test sequence
    // -----------------------------------------------------------------------
    initial begin
        // -- Initialize scoreboard and stimulus --------------------------------
        pass_count        = 0;
        fail_count        = 0;
        master_done_count = 0;
        slave_done_count  = 0;
        edge_count        = 0;
        count_before      = 0;
        rst_n             = 1'b1;
        start_cmd         = 1'b0;
        master_tx_data    = 8'h00;
        slave_tx_data     = 8'h00;
        active_mode       = 2'd0;

        $display("=== spi_top Testbench (master/slave integration) ===");

        // ==================================================================
        // TC1: Reset and idle polarity
        // Verifies that asserting rst_n forces every DUT to a known idle
        // state and that SCLK settles to the correct CPOL level.
        // ==================================================================
        $display("\n--- TC1: Reset and idle polarity ---");
        apply_reset();

        // ==================================================================
        // TC2: Full-duplex integration across all SPI modes
        // One run_transaction call per mode; each call issues 9 checks.
        // Payloads are chosen to be non-trivial and asymmetric so that
        // master_rx ≠ slave_rx, catching any MOSI/MISO swap bugs.
        // ==================================================================
        $display("\n--- TC2: Full-duplex integration in all SPI modes ---");
        run_transaction(2'd0, 8'hA5, 8'h3C, "Mode 0 master receives slave payload");
        run_transaction(2'd1, 8'hC3, 8'h5A, "Mode 1 master receives slave payload");
        run_transaction(2'd2, 8'h96, 8'h69, "Mode 2 master receives slave payload");
        run_transaction(2'd3, 8'hF0, 8'h0F, "Mode 3 master receives slave payload");

        // ==================================================================
        // TC3: Boundary payloads (all-ones and all-zeros)
        // Exercises the shift register at its extremes: only 1-bits on MISO
        // (slave sends 0xFF) and only 0-bits on MISO (slave sends 0x00).
        // ==================================================================
        $display("\n--- TC3: Boundary payloads ---");
        run_transaction(2'd0, 8'h00, 8'hFF, "All-one slave word reaches master");
        run_transaction(2'd3, 8'hFF, 8'h00, "All-zero slave word reaches master");

        // ==================================================================
        // TC4: Request while master is busy
        // Sends a second start pulse mid-transaction and verifies:
        //   (a) the DUT remains busy (request rejected),
        //   (b) the original payload is preserved (no corruption),
        //   (c) only one completion event fires (no phantom transaction).
        // ==================================================================
        $display("\n--- TC4: Request while master is busy ---");
        active_mode    = 2'd0;
        master_tx_data = 8'h3C;     // first (real) transaction data
        slave_tx_data  = 8'hA6;
        count_before   = master_done_count;

        // Kick off the real transaction
        @(negedge clk); start_cmd = 1'b1;
        @(negedge clk); start_cmd = 1'b0;

        // Wait a few cycles so the transaction is clearly in progress
        repeat (4) @(posedge clk);

        // Attempt a second start with different data — should be ignored.
        @(negedge clk);
        master_tx_data = 8'hF0;    // injected "bad" payload
        slave_tx_data  = 8'h0F;
        start_cmd      = 1'b1;

        @(negedge clk); start_cmd = 1'b0;

        // Wait for the original transaction to finish
        wait (active_master_done === 1'b1);
        wait (active_slave_done  === 1'b1);
        @(posedge clk); #1;

        // Original payloads must be intact
        check(active_slave_rx  === 8'h3C,
              "Busy rejection preserves original master payload");
        check(active_master_rx === 8'hA6,
              "Busy rejection preserves latched slave payload");
        // Exactly one completion event — the rejected start must not create another
        check(master_done_count == (count_before + 1),
              "Busy request does not create an extra transaction");

        // ==================================================================
        // TC5: Shared reset abort and recovery
        // Asserts rst_n mid-transaction to verify:
        //   (a) the DUT aborts cleanly (no busy/done, CS_N deasserted),
        //   (b) SCLK returns to CPOL idle,
        //   (c) a subsequent transaction completes correctly (no state residue).
        // ==================================================================
        $display("\n--- TC5: Shared reset abort and recovery ---");
        active_mode    = 2'd2;     // Mode 2 (CPOL=1): idle SCLK = HIGH
        master_tx_data = 8'h69;
        slave_tx_data  = 8'h96;

        // Start a transaction
        @(negedge clk); start_cmd = 1'b1;
        @(negedge clk); start_cmd = 1'b0;

        // Let it run for a few cycles, then abort with reset
        repeat (5) @(posedge clk);
        rst_n = 1'b0;
        repeat (2) @(posedge clk); #1;

        check((active_master_busy === 1'b0) &&
              (active_slave_busy  === 1'b0) && (active_cs_n === 1'b1) &&
              (active_master_done === 1'b0) && (active_slave_done === 1'b0) &&
              (active_sclk        === 1'b1),        // CPOL=1 → idle HIGH
              "Shared reset aborts both endpoints and restores CPOL");

        // Release reset and run a clean transaction to confirm recovery
        @(negedge clk); rst_n = 1'b1;
        repeat (2) @(posedge clk);
        run_transaction(2'd2, 8'h69, 8'h96,
                        "Integrated pair recovers after reset abort");

        // ==================================================================
        // Final summary
        // ==================================================================
        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: 5 TCS, all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
