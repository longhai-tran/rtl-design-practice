/*******************************************************************************
 * Module: i2c_top_tb.v                                                        *
 * Description: Self-checking integration testbench for i2c_top.               *
 * File Created: Friday, 31st July 2026 10:29:32 am                            *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 4th August 2026 11:36:40 am                         *
 * Modified By: Long Hai                                                       *
 *******************************************************************************/

/*
 * Testbench Strategy
 * ==================
 * This is a self-checking, regression-style integration testbench.
 * It instantiates i2c_top (master + slave on a simulated open-drain bus)
 * and runs six independent test cases.  Each check() call increments either
 * pass_count or fail_count.  The simulation ends with a summary and uses
 * $fatal to indicate failure to the calling simulator / Makefile.
 *
 * Global monitors (always blocks outside initial):
 *   - Pulse-width checker: flags any done/valid signal that stays HIGH for
 *     more than one clock cycle (expected to be exactly one-cycle pulses).
 *   - SCL rising-edge counter: counts edges to verify exact frame lengths.
 *   - START/STOP condition counters: verify exactly one of each per transfer.
 *
 * Test cases:
 *   TC1  Reset and idle bus — bus lines HIGH, all status signals cleared
 *   TC2  Directed write (3 patterns: 0xA5, 0x00, 0xFF)
 *   TC3  Directed read  (3 patterns: 0x3C, 0x00, 0xFF)
 *   TC4  Address NACK   — wrong address; master stops after address frame
 *   TC5  Request while busy — second start ignored; original data unaffected
 *   TC6  Reset abort and recovery — mid-transfer reset; new transfer succeeds
 *
 * Timing constants:
 *   CLK_PERIOD = 10 ns  → f_clk = 100 MHz
 *   CLK_DIV    =  4     → SCL half-period = 4 cycles = 40 ns → f_scl = 12.5 MHz
 *   Full I2C frame (8 addr + 1 ack + 8 data + 1 ack) = 18 SCL rising edges
 */

`timescale 1ns/1ps

module i2c_top_tb;

    // -------------------------------------------------------------------------
    // Simulation parameters
    // -------------------------------------------------------------------------
    localparam integer CLK_PERIOD = 10;   // System clock period in ns
    localparam integer CLK_DIV    = 4;    // SCL half-period in system-clock cycles
    localparam [6:0]   SLAVE_ADDR = 7'h42; // I2C address the slave responds to

    // -------------------------------------------------------------------------
    // DUT stimulus registers
    // -------------------------------------------------------------------------
    reg        clk;            // System clock driven by always block below
    reg        rst_n;          // Active-low reset
    reg        start;          // Trigger a new I2C transfer
    reg        rw;             // Transfer direction: 0=write, 1=read
    reg [6:0]  target_addr;    // Address sent on bus by master
    reg [7:0]  master_tx_data; // Byte master writes to slave
    reg [7:0]  slave_tx_data;  // Byte slave returns to master on a read

    // -------------------------------------------------------------------------
    // DUT output wires
    // -------------------------------------------------------------------------
    wire [7:0] master_rx_data; // Byte captured by master during a read
    wire [7:0] slave_rx_data;  // Byte captured by slave during a write
    wire       slave_rx_valid; // One-cycle pulse: slave_rx_data is ready
    wire       master_busy;    // HIGH while master is running a transaction
    wire       master_done;    // One-cycle pulse: master transaction complete
    wire       slave_busy;     // HIGH while slave is engaged
    wire       slave_done;     // One-cycle pulse: slave transaction complete
    wire       ack_error;      // HIGH if master received a NACK
    wire       scl;            // Resolved I2C clock line (for waveform inspection)
    wire       sda;            // Resolved I2C data  line (for waveform inspection)

    // -------------------------------------------------------------------------
    // Scoreboard counters
    // -------------------------------------------------------------------------
    integer pass_count;           // Total assertions passed across all test cases
    integer fail_count;           // Total assertions failed  across all test cases
    integer master_done_count;    // Cumulative count of master_done pulses seen
    integer slave_done_count;     // Cumulative count of slave_done  pulses seen
    integer slave_rx_valid_count; // Cumulative count of slave_rx_valid pulses seen
    integer scl_rise_count;       // Cumulative count of SCL rising edges (data/addr phases)
    integer start_count;          // Cumulative count of I2C START conditions detected
    integer stop_count;           // Cumulative count of I2C STOP  conditions detected
    integer pulse_error_count;    // Count of done/valid signals that lasted >1 cycle

    // Delayed copies used to detect multi-cycle pulses
    reg master_done_d;
    reg slave_done_d;
    reg slave_rx_valid_d;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    i2c_top #(
        .CLK_DIV   (CLK_DIV),
        .SLAVE_ADDR(SLAVE_ADDR)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .rw            (rw),
        .target_addr   (target_addr),
        .master_tx_data(master_tx_data),
        .slave_tx_data (slave_tx_data),
        .master_rx_data(master_rx_data),
        .slave_rx_data (slave_rx_data),
        .slave_rx_valid(slave_rx_valid),
        .master_busy   (master_busy),
        .master_done   (master_done),
        .slave_busy    (slave_busy),
        .slave_done    (slave_done),
        .ack_error     (ack_error),
        .scl           (scl),
        .sda           (sda)
    );

    // -------------------------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Global monitor: pulse-width and event counters
    // -------------------------------------------------------------------------
    // Runs continuously to catch multi-cycle pulses that violate the protocol
    // (master_done, slave_done, slave_rx_valid must each be exactly one cycle wide).
    always @(posedge clk) begin
        if (!rst_n) begin
            master_done_d    <= 1'b0;
            slave_done_d     <= 1'b0;
            slave_rx_valid_d <= 1'b0;
        end else begin
            // Accumulate event counts for post-transfer checks
            if (master_done)    master_done_count    = master_done_count    + 1;
            if (slave_done)     slave_done_count     = slave_done_count     + 1;
            if (slave_rx_valid) slave_rx_valid_count = slave_rx_valid_count + 1;

            // Flag any signal that is still HIGH on the cycle after it first appeared
            if (master_done    && master_done_d)    pulse_error_count = pulse_error_count + 1;
            if (slave_done     && slave_done_d)     pulse_error_count = pulse_error_count + 1;
            if (slave_rx_valid && slave_rx_valid_d) pulse_error_count = pulse_error_count + 1;

            master_done_d    <= master_done;
            slave_done_d     <= slave_done;
            slave_rx_valid_d <= slave_rx_valid;
        end
    end

    // -------------------------------------------------------------------------
    // Global monitor: SCL rising-edge counter
    // -------------------------------------------------------------------------
    // Counts only during active master data/address phases (states 0–7).
    // Used to verify that exactly 18 SCL pulses appear per complete frame
    // (8 address + 1 ACK + 8 data + 1 ACK = 18).
    always @(posedge scl) begin
        if (rst_n && master_busy && dut.u_master.state <= 4'd7)
            scl_rise_count = scl_rise_count + 1;
    end

    // -------------------------------------------------------------------------
    // Global monitors: START and STOP condition detection
    // -------------------------------------------------------------------------
    // I2C START: SDA falling while SCL is HIGH
    always @(negedge sda) begin
        if (rst_n && scl)
            start_count = start_count + 1;
    end

    // I2C STOP: SDA rising while SCL is HIGH
    always @(posedge sda) begin
        if (rst_n && scl)
            stop_count = stop_count + 1;
    end

    // =========================================================================
    // Task library
    // =========================================================================

    // ── check ─────────────────────────────────────────────────────────────────
    // Self-checking assertion.  Increments pass_count or fail_count and prints
    // a timestamped result.  message is 96-character max to cover typical strings.
    task check;
        input condition;
        input [8*96-1:0] message;
        begin
            if (condition) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
                $display("  [%0t ns] FAIL: %0s", $time/1000, message);
            end
        end
    endtask

    // ── apply_reset ───────────────────────────────────────────────────────────
    // Assert reset for 3 clock cycles then deassert.  Synchronised to negedge
    // to avoid glitches near the sampling edge of any flip-flop.
    task apply_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            repeat (3) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk); // Allow outputs to settle after reset release
        end
    endtask

    // ── issue_start ───────────────────────────────────────────────────────────
    // Drive all master inputs for one clock cycle then deassert start.
    // This mirrors the expected user-facing handshake: present data, pulse start.
    task issue_start;
        input       direction;    // rw value (0=write, 1=read)
        input [6:0] address;      // target_addr value
        input [7:0] master_word;  // master_tx_data value
        input [7:0] slave_word;   // slave_tx_data value
        begin
            @(negedge clk);
            rw             = direction;
            target_addr    = address;
            master_tx_data = master_word;
            slave_tx_data  = slave_word;
            start          = 1'b1;
            @(negedge clk);
            start          = 1'b0; // Deassert: master latches inputs on the first cycle
        end
    endtask

    // ── wait_for_completion ───────────────────────────────────────────────────
    // Block until master_done is seen or a timeout of 1000 cycles is reached.
    // The timeout guards against infinite loops if the DUT hangs.
    // Three extra cycles are added after completion for outputs to settle.
    task wait_for_completion;
        integer timeout;
        begin
            timeout = 0;
            while (!master_done && timeout < 1000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout > 1000)
                $display("  [%0t ns] FAIL: Transaction timeout", $time/1000);
            repeat (3) @(posedge clk); // Output settling time
        end
    endtask

    // ── run_write ─────────────────────────────────────────────────────────────
    // Execute a complete write transaction with the given byte, then verify:
    //   - master_busy asserted immediately
    //   - no ACK error (slave ACKed both address and data)
    //   - slave captured the correct byte
    //   - exactly one master_done, slave_done, and slave_rx_valid event
    //   - exactly 18 SCL rising edges (8 addr + 1 ACK + 8 data + 1 ACK)
    //   - exactly one START and one STOP condition
    //   - bus and endpoints return to idle afterwards
    //
    // A stale stimulus is set after issue_start to confirm the master ignores
    // inputs that arrive after it has latched start (busy-ignore sub-test).
    task run_write;
        input [7:0] value;        // Byte to write to the slave
        integer md_before;        // master_done_count snapshot before transaction
        integer sd_before;        // slave_done_count  snapshot
        integer rv_before;        // slave_rx_valid_count snapshot
        integer edge_before;      // scl_rise_count snapshot
        integer start_before;     // start_count snapshot
        integer stop_before;      // stop_count snapshot
        begin
            // Capture pre-transaction baselines for delta checks
            md_before    = master_done_count;
            sd_before    = slave_done_count;
            rv_before    = slave_rx_valid_count;
            edge_before  = scl_rise_count;
            start_before = start_count;
            stop_before  = stop_count;

            issue_start(1'b0, SLAVE_ADDR, value, 8'h00);

            // // Apply stale / conflicting stimulus after latching to confirm isolation
            // rw             = 1'b1;   // Opposite direction — should be ignored
            // target_addr    = 7'h43;  // Wrong address — should be ignored
            // master_tx_data = ~value; // Inverted data — should be ignored

            @(posedge clk);
            check(master_busy, "Write request asserts master_busy");

            wait_for_completion;

            // ── Functional checks ──────────────────────────────────────────
            check(!ack_error,               "Address and write-data ACKs are received");
            check(slave_rx_data == value,   "Slave receives the exact write byte");
            // ── Protocol-level checks ──────────────────────────────────────
            check(master_done_count    == md_before + 1,  "Write produces one master_done event");
            check(slave_done_count     == sd_before + 1,  "Write produces one slave_done event");
            check(slave_rx_valid_count == rv_before + 1,  "Write produces one slave_rx_valid event");
            check(scl_rise_count       == edge_before + 18, "Write contains 18 SCL rising edges");
            check(start_count          == start_before + 1, "Write contains one START condition");
            check(stop_count           == stop_before  + 1, "Write contains one STOP condition");
            check(!master_busy && !slave_busy && scl && sda,
                  "Write returns bus and endpoints to idle");
        end
    endtask

    // ── run_read ──────────────────────────────────────────────────────────────
    // Execute a complete read transaction.  Slave will return 'value';
    // stale conflicting stimulus is applied after issue_start.
    // Checks mirror run_write except slave_rx_valid must NOT fire (no write data).
    task run_read;
        input [7:0] value;        // Byte the slave should return to the master
        integer md_before;
        integer sd_before;
        integer rv_before;
        integer edge_before;
        integer start_before;
        integer stop_before;
        begin
            md_before    = master_done_count;
            sd_before    = slave_done_count;
            rv_before    = slave_rx_valid_count;
            edge_before  = scl_rise_count;
            start_before = start_count;
            stop_before  = stop_count;

            issue_start(1'b1, SLAVE_ADDR, 8'h00, value);

            // // Apply stale stimulus; these must not affect the in-progress transfer
            // rw            = 1'b0;
            // target_addr   = 7'h43;
            // slave_tx_data = ~value; // Inverted; slave has already latched 'value'

            @(posedge clk);
            check(master_busy, "Read request asserts master_busy");

            wait_for_completion;

            check(!ack_error,                 "Read address ACK is received");
            check(master_rx_data == value,    "Master receives the exact slave byte");
            check(master_done_count    == md_before + 1,  "Read produces one master_done event");
            check(slave_done_count     == sd_before + 1,  "Read produces one slave_done event");
            // No data written by master → slave_rx_valid must not fire
            check(slave_rx_valid_count == rv_before,      "Read does not assert slave_rx_valid");
            check(scl_rise_count       == edge_before + 18, "Read contains 18 SCL rising edges");
            check(start_count          == start_before + 1, "Read contains one START condition");
            check(stop_count           == stop_before  + 1, "Read contains one STOP condition");
            check(!master_busy && !slave_busy && scl && sda,
                  "Read returns bus and endpoints to idle");
        end
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    initial begin
        // ── Initialise all stimulus and scoreboard variables ─────────────────
        clk                  = 1'b0;
        rst_n                = 1'b0;
        start                = 1'b0;
        rw                   = 1'b0;
        target_addr          = SLAVE_ADDR;
        master_tx_data       = 8'h00;
        slave_tx_data        = 8'h00;
        pass_count           = 0;
        fail_count           = 0;
        master_done_count    = 0;
        slave_done_count     = 0;
        slave_rx_valid_count = 0;
        scl_rise_count       = 0;
        start_count          = 0;
        stop_count           = 0;
        pulse_error_count    = 0;
        master_done_d        = 1'b0;
        slave_done_d         = 1'b0;
        slave_rx_valid_d     = 1'b0;

        $display("=== i2c_top self-checking integration testbench ===");

        // ── TC1: Reset and idle bus ──────────────────────────────────────────
        // Verify that after reset both bus lines are HIGH (pull-up dominant),
        // all busy/done/error flags are cleared, and bus is fully idle.
        $display("\n--- [%0t ps] TC1: Reset and idle bus         ---", $time);
        apply_reset;
        check(scl && sda,                                "Reset releases both open-drain bus lines HIGH");
        check(!master_busy && !slave_busy,               "Reset clears endpoint busy status");
        check(!master_done && !slave_done && !slave_rx_valid, "Reset clears pulse outputs");
        check(!ack_error,                                "Reset clears acknowledge error status");

        // ── TC2: Directed write transactions ─────────────────────────────────
        // Three data patterns (walking ones, all-zeros, all-ones) ensure coverage
        // of every bit position and the all-zero / all-one boundary cases.
        $display("\n--- [%0t ps] TC2: Directed write transactions --- ", $time);
        run_write(8'hA5); // 1010_0101 — alternating bits
        run_write(8'h00); // All zeros  — SDA held LOW entire data phase
        run_write(8'hFF); // All ones   — SDA stays HIGH entire data phase

        // ── TC3: Directed read transactions ──────────────────────────────────
        // Same three patterns exercised in the read direction.
        $display("\n--- [%0t ns] TC3: Directed read transactions  ---", $time/1000);
        run_read(8'h3C); // 0011_1100
        run_read(8'h00);
        run_read(8'hFF);

        // ── TC4: Address NACK handling ────────────────────────────────────────
        // Send to 7'h43 (≠ SLAVE_ADDR = 7'h42).  The slave will not ACK the
        // address frame, so the master must:
        //   - set ack_error
        //   - stop after 9 SCL rising edges (8 addr + 1 NACK clock)
        //   - still issue a STOP and pulse master_done
        $display("\n--- [%0t ns] TC4: Address NACK handling       ---", $time/1000);
        begin : nack_test
            integer md_before;
            integer sd_before;
            integer rv_before;
            integer edge_before;
            md_before   = master_done_count;
            sd_before   = slave_done_count;
            rv_before   = slave_rx_valid_count;
            edge_before = scl_rise_count;
            issue_start(1'b0, 7'h43, 8'h5A, 8'h00); // Wrong address
            wait_for_completion;
            check(ack_error,                                   "Wrong target address sets ack_error");
            check(master_done_count    == md_before + 1,       "NACK path still completes master transaction");
            check(slave_done_count     == sd_before,           "Unselected slave does not assert done");
            check(slave_rx_valid_count == rv_before,           "Unselected slave does not accept write data");
            check(scl_rise_count       == edge_before + 9,     "Address NACK stops after nine SCL rising edges");
            check(scl && sda && !master_busy && !slave_busy,   "NACK path releases the bus cleanly");
        end

        // ── TC5: Request while busy is ignored ───────────────────────────────
        // Launch a write, then assert start mid-transfer with different parameters.
        // The master must ignore the second request; the first must complete correctly.
        $display("\n--- [%0t ns] TC5: Request while busy ignored  ---", $time/1000);
        begin : busy_test
            integer md_before;
            integer sd_before;
            md_before = master_done_count;
            sd_before = slave_done_count;
            issue_start(1'b0, SLAVE_ADDR, 8'h69, 8'h00); // First request: write 0x69
            repeat (12) @(posedge clk);                   // Wait until clearly mid-transfer
            // Assert conflicting second request while the first is still active
            rw             = 1'b1;
            target_addr    = 7'h43;
            master_tx_data = 8'h96;
            slave_tx_data  = 8'hC3;
            start          = 1'b1;
            @(negedge clk);
            start          = 1'b0;
            wait_for_completion;
            check(slave_rx_data    == 8'h69, "Busy request does not replace latched write data");
            check(!ack_error,                "Busy request does not replace latched address/direction");
            check(master_done_count == md_before + 1, "Busy request creates no extra master transaction");
            check(slave_done_count  == sd_before + 1, "Busy request creates no extra slave transaction");
        end

        // ── TC6: Reset abort and recovery ────────────────────────────────────
        // Assert reset mid-transfer (while SCL is LOW to create a clear abort point).
        // After reset and re-release, verify that a new transaction succeeds,
        // proving the FSMs recover cleanly from an incomplete transfer.
        $display("\n--- [%0t ns] TC6: Reset abort and recovery    ---", $time/1000);
        issue_start(1'b0, SLAVE_ADDR, 8'hD2, 8'h00);
        wait(master_busy && !scl);      // Wait until master is mid-transfer with SCL LOW
        repeat (5) @(posedge clk);      // Let the state machine advance a few cycles
        rst_n = 1'b0;                   // Assert reset — should immediately release all drivers
        repeat (2) @(posedge clk);
        check(scl && sda && !master_busy && !slave_busy,
              "Reset abort immediately restores idle bus state");
        rst_n = 1'b1;
        repeat (2) @(posedge clk);      // Allow outputs to settle after reset release
        run_read(8'h96);                // Recovery read: slave must return 0x96 correctly
        check(master_rx_data == 8'h96, "Integrated pair recovers after reset abort");

        // ── Global pulse-width check ─────────────────────────────────────────
        // Must run AFTER all transactions since pulse_error_count accumulates
        // asynchronously in the background monitor.
        check(pulse_error_count == 0, "done and valid outputs remain exactly one clock wide");

        // ── Final summary ─────────────────────────────────────────────────────
        $display("\n-----------------------------------------------");
        if (fail_count == 0) begin
            $display("=== PASS: 6 test cases, all %0d checks passed ===", pass_count);
            $display("-----------------------------------------------");
            $finish;
        end else begin
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);
            $display("-----------------------------------------------");
            $fatal(1, "Self-checking I2C regression failed");
        end
    end

    // -------------------------------------------------------------------------
    // Watchdog timer
    // -------------------------------------------------------------------------
    // If the DUT hangs (e.g., FSM deadlock), force a fatal failure after
    // 200 µs of simulation time so the run does not stall a CI pipeline.
    initial begin
        #200000;
        $fatal(1, "[WATCHDOG] simulation timeout at %0t ns", $time/1000);
    end

endmodule
