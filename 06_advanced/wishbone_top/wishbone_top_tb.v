/*******************************************************************************
 * Module  : wishbone_top_tb.v
 * Brief   : Self-checking integration testbench for the Wishbone B4 subsystem.
 *
 * DUT     : wishbone_top (1 master, 1 interconnect, 2 register-bank slaves)
 *
 * Test Plan:
 *   TC0  Reset         — master idle, bus released, all slave registers = 0
 *   TC1  Write / Read  — full-word write then readback on slave 0
 *   TC2  Decode        — interconnect routes 0x1xxx to slave 1, slave 0 unaffected
 *   TC3  Byte select   — SEL=0101 updates only byte lanes 0 and 2
 *   TC4  ID register   — slave 0/1 return WBS0/WBS1; write returns ERR
 *   TC5  Error         — unmapped address and unaligned access both return ERR
 *   TC6  Busy policy   — command presented while busy is silently dropped
 *
 * Pass criterion: all 24 checks must pass; $finish is called either way.
 *
 * Author  : Long Hai
 *******************************************************************************/

`timescale 1ns/1ps

module wishbone_top_tb;

    // -------------------------------------------------------------------------
    // Clock and reset
    // -------------------------------------------------------------------------
    reg clk;
    reg rst_n;

    // -------------------------------------------------------------------------
    // Command interface (drives DUT inputs)
    // -------------------------------------------------------------------------
    reg        cmd_valid;
    reg        cmd_write;
    reg [15:0] cmd_addr;
    reg [31:0] cmd_wdata;
    reg  [3:0] cmd_sel;

    // -------------------------------------------------------------------------
    // Command interface (DUT outputs)
    // -------------------------------------------------------------------------
    wire        cmd_ready;
    wire        busy;
    wire        done;
    wire        error;
    wire [31:0] read_data;

    // -------------------------------------------------------------------------
    // Internal Wishbone bus — observed for debug and waveform inspection
    // -------------------------------------------------------------------------
    wire [15:0] wb_addr;
    wire [31:0] wb_wdata;
    wire [31:0] wb_rdata;
    wire  [3:0] wb_sel;
    wire        wb_we;
    wire        wb_cyc;
    wire        wb_stb;
    wire        wb_ack;
    wire        wb_err;

    // -------------------------------------------------------------------------
    // Slave register file outputs — observed for direct state verification
    // -------------------------------------------------------------------------
    wire [31:0] slave0_control, slave0_data, slave0_scratch;
    wire [31:0] slave1_control, slave1_data, slave1_scratch;

    // -------------------------------------------------------------------------
    // Bookkeeping
    // -------------------------------------------------------------------------
    integer pass_count, fail_count;
    reg         last_error;   // error flag captured after each transact()
    reg  [31:0] last_read;    // read_data captured after each transact()

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    wishbone_top dut (
        // Clock and reset
        .clk             (clk),
        .rst_n           (rst_n),
        // Command interface
        .cmd_valid       (cmd_valid),
        .cmd_write       (cmd_write),
        .cmd_addr        (cmd_addr),
        .cmd_wdata       (cmd_wdata),
        .cmd_sel         (cmd_sel),
        .cmd_ready       (cmd_ready),
        .read_data       (read_data),
        .busy            (busy),
        .done            (done),
        .error           (error),
        // Internal Wishbone bus (debug)
        .wb_addr         (wb_addr),
        .wb_wdata        (wb_wdata),
        .wb_rdata        (wb_rdata),
        .wb_sel          (wb_sel),
        .wb_we           (wb_we),
        .wb_cyc          (wb_cyc),
        .wb_stb          (wb_stb),
        .wb_ack          (wb_ack),
        .wb_err          (wb_err),
        // Slave register outputs
        .slave0_control  (slave0_control),
        .slave0_data     (slave0_data),
        .slave0_scratch  (slave0_scratch),
        .slave1_control  (slave1_control),
        .slave1_data     (slave1_data),
        .slave1_scratch  (slave1_scratch)
    );

    // =========================================================================
    // Clock generator: 100 MHz (period = 10 ns)
    // =========================================================================
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // =========================================================================
    // Global timeout watchdog
    // If the testbench hangs (e.g. transact() never sees done), this fires.
    // =========================================================================
    initial begin
        #100_000;
        $display("[FAIL] Watchdog: testbench did not complete within 100 us");
        $finish;
    end

    // =========================================================================
    // Task: check
    //   Increments pass_count or fail_count and prints a one-line result.
    // =========================================================================
    task check;
        input            condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                pass_count = pass_count + 1;
                $display("[%0t ns] PASS: %0s", $time, message);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t ns] FAIL: %0s", $time, message);
            end
        end
    endtask

    // =========================================================================
    // Task: apply_reset
    //   Asserts reset for 3 clock cycles, then verifies the idle bus state and
    //   that all slave register banks are cleared.
    // =========================================================================
    task apply_reset;
        begin
            @(negedge clk);
            rst_n     = 1'b0;
            cmd_valid = 1'b0;

            repeat (3) @(posedge clk);
            #1; // Small delta to let outputs settle after clock edge

            check(!busy && !done && cmd_ready && !wb_cyc && !wb_stb,
                  "Reset: master and bus return to idle");
            check(slave0_control == 0 && slave0_data == 0 && slave0_scratch == 0 &&
                  slave1_control == 0 && slave1_data == 0 && slave1_scratch == 0,
                  "Reset: all slave register banks cleared to zero");

            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    // =========================================================================
    // Task: transact
    //   Drives one complete Wishbone transaction through the command interface:
    //     1. Wait until the master is ready (cmd_ready = 1).
    //     2. Present the command for exactly one clock.
    //     3. Wait for the done pulse.
    //     4. Capture last_error and last_read for the caller to inspect.
    //     5. Verify that done is exactly one clock wide.
    // =========================================================================
    task transact;
        input        write_enable;  // 1 = write, 0 = read
        input [15:0] address;       // byte address
        input [31:0] write_value;   // write payload (ignored on reads)
        input  [3:0] byte_select;   // active byte lanes
        begin
            // Wait if a previous transaction is still in flight
            while (!cmd_ready) @(negedge clk);

            // Present the command on the falling edge (setup before rising edge)
            @(negedge clk);
            cmd_write = write_enable;
            cmd_addr  = address;
            cmd_wdata = write_value;
            cmd_sel   = byte_select;
            cmd_valid = 1'b1;

            // Hold cmd_valid for exactly one clock, then deassert
            @(negedge clk);
            cmd_valid = 1'b0;

            // Wait for the master to signal completion
            wait (done === 1'b1);
            #1; // Small delta so combinational signals driven by done are stable

            // Capture results for the caller
            last_error = error;
            last_read  = read_data;

            // Verify done is a single-clock pulse (not stuck high)
            @(posedge clk);
            #1;
            check(done === 1'b0, "done pulse is exactly one clock wide");
        end
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    initial begin
        // Initialise bookkeeping and all command-interface inputs
        pass_count = 0;
        fail_count = 0;
        last_error = 0;
        last_read  = 0;
        rst_n      = 1'b1;
        cmd_valid  = 1'b0;
        cmd_write  = 1'b0;
        cmd_addr   = 16'h0000;
        cmd_wdata  = 32'h0000_0000;
        cmd_sel    = 4'hF;

        $display("=== wishbone_top Testbench (1 master, 2 slaves) ===");

        // -----------------------------------------------------------------
        // TC0: Reset
        // -----------------------------------------------------------------
        apply_reset();

        // -----------------------------------------------------------------
        // TC1: Slave 0 — full-word write then read-back
        // -----------------------------------------------------------------
        $display("\n--- TC1: Slave 0 full-word write / read-back ---");

        transact(1, 16'h0000, 32'h1122_3344, 4'hF);
        check(!last_error && slave0_control === 32'h1122_3344,
              "TC1: slave 0 CONTROL register accepts full-word write");

        transact(0, 16'h0000, 32'h0, 4'hF);
        check(!last_error && last_read === 32'h1122_3344,
              "TC1: slave 0 CONTROL register returns written value on read");

        // -----------------------------------------------------------------
        // TC2: Address decode — slave 1 access must not disturb slave 0
        // -----------------------------------------------------------------
        $display("\n--- TC2: Slave 1 decode isolation ---");

        transact(1, 16'h1004, 32'hCAFE_BABE, 4'hF);
        check(!last_error && slave1_data === 32'hCAFE_BABE,
              "TC2: interconnect routes 0x1xxx writes to slave 1");
        check(slave0_data === 32'h0000_0000,
              "TC2: slave 0 DATA register unchanged by slave 1 access");

        // -----------------------------------------------------------------
        // TC3: Byte select — SEL=0101 updates only byte lanes 0 and 2
        //   Setup:    CONTROL = 0x1122_3344  (from TC1 write)
        //   Write:    data=0xAABB_CCDD, SEL=0101
        //   Expected: byte2=0xBB, byte0=0xDD, others unchanged
        //   Result:   0x11BB_33DD
        // -----------------------------------------------------------------
        $display("\n--- TC3: Byte select ---");

        transact(1, 16'h0000, 32'hAABB_CCDD, 4'b0101);
        transact(0, 16'h0000, 32'h0, 4'hF);
        check(last_read === 32'h11BB_33DD,
              "TC3: SEL=0101 updates only byte lanes 0 and 2");

        // -----------------------------------------------------------------
        // TC4: Read-only ID registers
        // -----------------------------------------------------------------
        $display("\n--- TC4: Read-only identification registers ---");

        transact(0, 16'h000C, 32'h0, 4'hF);
        check(!last_error && last_read === 32'h5742_5330,
              "TC4: slave 0 ID register returns 0x57425330 (\"WBS0\")");

        transact(0, 16'h100C, 32'h0, 4'hF);
        check(!last_error && last_read === 32'h5742_5331,
              "TC4: slave 1 ID register returns 0x57425331 (\"WBS1\")");

        transact(1, 16'h000C, 32'hFFFF_FFFF, 4'hF);
        check(last_error,
              "TC4: write to read-only ID register returns ERR");

        // -----------------------------------------------------------------
        // TC5: Error responses
        // -----------------------------------------------------------------
        $display("\n--- TC5: Error responses ---");

        transact(0, 16'h2000, 32'h0, 4'hF);
        check(last_error,
              "TC5: unmapped address (0x2000) returns ERR immediately");

        transact(0, 16'h1002, 32'h0, 4'hF);
        check(last_error,
              "TC5: unaligned address (ADR[1:0]=10) returns ERR");

        // -----------------------------------------------------------------
        // TC6: Busy policy — second command presented while master is busy
        //
        // This test cannot use transact() because it needs to inject a
        // second command while the first is still in flight (cmd_ready=0).
        // The second command must be silently dropped by the master.
        // -----------------------------------------------------------------
        $display("\n--- TC6: Command-while-busy is ignored ---");

        // Issue first command (write 0x1234_5678 to slave 0 SCRATCH)
        @(negedge clk);
        cmd_write = 1'b1;
        cmd_addr  = 16'h0008;
        cmd_wdata = 32'h1234_5678;
        cmd_sel   = 4'hF;
        cmd_valid = 1'b1;
        @(negedge clk);
        cmd_valid = 1'b0;

        // Immediately try a second command (write 0xDEAD_BEEF to slave 1 SCRATCH)
        // cmd_ready is 0 at this point, so the master must ignore this
        @(negedge clk);
        cmd_addr  = 16'h1008;
        cmd_wdata = 32'hDEAD_BEEF;
        cmd_valid = 1'b1;
        @(negedge clk);
        cmd_valid = 1'b0;

        // Wait for the first command to complete
        wait (done);
        @(posedge clk); #1;

        check(slave0_scratch === 32'h1234_5678,
              "TC6: first command completes without data corruption");
        check(slave1_scratch === 32'h0000_0000,
              "TC6: second command (while busy) is silently ignored");

        // -----------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------
        $display("\n-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
