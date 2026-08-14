/*******************************************************************************
 * Module: simple_cpu_tb.v                                                     *
 * Description: Self-checking testbench for simple_cpu.                        *
 *              Exercises reset, start/restart, ALU ops, load/store,           *
 *              conditional branch, HALT, and timeout protection.              *
 * File Created: Wednesday, 12th August 2026 4:37:57 pm                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 13th August 2026 11:02:22 am                       *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

/*
 * Testbench Strategy
 * ==================
 * A single program is loaded into imem and executed twice:
 *
 *  Instruction sequence:
 *   [0] LOADI R0, 5       ; R0 = 5
 *   [1] LOADI R1, 3       ; R1 = 3
 *   [2] ADD   R0, R1      ; R0 = R0 + R1 = 8
 *   [3] ST    R0, 0x20    ; dmem[0x20] = 8
 *   [4] LD    R2, 0x20    ; R2 = dmem[0x20] = 8
 *   [5] BEQZ  R3, 0x07    ; R3 == 0 → branch to addr 7 (HALT), skip [6]
 *   [6] LOADI R0, 0xFF    ; skipped — R0 must remain 8 after branch
 *   [7] HALT              ; stop execution
 *
 * Checks performed (first run):
 *   1. CPU asserts halted and clears busy after HALT
 *   2. ADD correctly computed R0 = 5 + 3 = 8
 *   3. LOAD correctly read the stored value back into R2
 *   4. STORE wrote 8 to dmem[0x20]
 *   5. BEQZ branch was taken (pc points to instruction [7])
 *
 * Checks performed (second run / restart):
 *   6. CPU produces the same acc value after re-start (deterministic restart)
 *
 * Timeout guard: simulation aborts with FAIL if done is not seen within
 * 100 µs — protects against infinite loops or stuck FSMs.
 *
 * Instruction encoding helper:
 *   enc(op, rd, rs, imm) → {op[3:0], rd[1:0], rs[1:0], imm[7:0]}
 */

`timescale 1ns/1ps

module simple_cpu_tb;

    // =========================================================================
    // DUT interface signals
    // =========================================================================
    reg  clk, rst_n, start;
    wire busy, halted, done, data_we;
    wire [7:0] pc, acc, data_addr, data_wdata, data_rdata;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    simple_cpu dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .busy      (busy),
        .halted    (halted),
        .done      (done),
        .pc        (pc),
        .acc       (acc),
        .data_addr (data_addr),
        .data_wdata(data_wdata),
        .data_we   (data_we),
        .data_rdata(data_rdata)
    );

    // =========================================================================
    // Clock generation — 100 MHz (10 ns period)
    // =========================================================================
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // =========================================================================
    // Test statistics
    // =========================================================================
    integer pass_count, fail_count;

    // =========================================================================
    // Utility: encode a 16-bit instruction word
    //   op  — 4-bit opcode
    //   rd  — 2-bit rd (destination)
    //   rs  — 2-bit rs (source)
    //   imm — 8-bit immediate / address
    // =========================================================================
    function [15:0] enc;
        input [3:0] op;
        input [1:0] rd, rs;
        input [7:0] imm;
        begin
            enc = {op, rd, rs, imm};
        end
    endfunction

    // =========================================================================
    // Task: check — compare a condition and log PASS/FAIL with a message
    // =========================================================================
    task check;
        input       cond;
        input [8*100-1:0] msg;   // up to 100-character message string
        begin
            if (cond) begin
                pass_count = pass_count + 1;
                $display("PASS: %0s", msg);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s", msg);
            end
        end
    endtask

    // =========================================================================
    // Task: reset_cpu — apply synchronous reset for 2 clock cycles
    // =========================================================================
    task reset_cpu;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            repeat (2) @(posedge clk);
            rst_n = 1'b1;   // release reset — CPU enters S_IDLE
        end
    endtask

    // =========================================================================
    // Task: run — pulse start for one cycle then wait for done
    // =========================================================================
    task run;
        begin
            @(negedge clk); start = 1'b1;  // assert start on negative edge
            @(negedge clk); start = 1'b0;  // de-assert one cycle later
            wait (done);                    // wait until HALT is reached
            @(posedge clk);                 // settle one more cycle
        end
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    initial begin
        // ── Initialise signals ───────────────────────────────────────────────
        clk        = 1'b0;
        rst_n      = 1'b1;
        start      = 1'b0;
        pass_count = 0;
        fail_count = 0;

        $display("=== simple_cpu self-checking testbench ===");

        // ── Apply reset ──────────────────────────────────────────────────────
        reset_cpu();

        // ── Load test program into instruction memory ────────────────────────
        // Instruction [0]: LOADI R0, 5  →  R0 = 5
        dut.imem[0] = enc(4'h6, 2'd0, 2'd0, 8'd5);

        // Instruction [1]: LOADI R1, 3  →  R1 = 3
        dut.imem[1] = enc(4'h6, 2'd1, 2'd0, 8'd3);

        // Instruction [2]: ADD R0, R1   →  R0 = R0 + R1 = 8
        dut.imem[2] = enc(4'h1, 2'd0, 2'd1, 8'd0);

        // Instruction [3]: ST R0, 0x20  →  dmem[0x20] = 8
        dut.imem[3] = enc(4'h8, 2'd0, 2'd0, 8'h20);

        // Instruction [4]: LD R2, 0x20  →  R2 = dmem[0x20] = 8
        dut.imem[4] = enc(4'h7, 2'd2, 2'd0, 8'h20);

        // Instruction [5]: BEQZ R3, 7   →  R3 == 0 → branch to address 7
        dut.imem[5] = enc(4'hA, 2'd3, 2'd0, 8'd7);

        // Instruction [6]: LOADI R0, 0xFF  (should be SKIPPED by branch)
        dut.imem[6] = enc(4'h6, 2'd0, 2'd0, 8'hFF);

        // Instruction [7]: HALT  →  stop execution
        dut.imem[7] = enc(4'hF, 2'd0, 2'd0, 8'd0);

        // ── First run ────────────────────────────────────────────────────────
        run();

        // Check 1: HALT reached — busy de-asserted, halted asserted
        $display("Check time: %0t ps", $time);
        check(halted && !busy, "CPU reaches HALT and drops busy");

        // Check 2: ADD result
        check(dut.regs[0] === 8'd8, "ADD computes R0 = 5 + 3");

        // Check 3: LOAD read the value stored by ST
        check(dut.regs[2] === 8'd8, "LOAD reads the stored value");

        // Check 4: STORE wrote to dmem
        check(dut.dmem[8'h20] === 8'd8, "STORE writes data memory");

        // Check 5: BEQZ branch taken (R3 == 0 → pc jumped to addr 7)
        check(pc === 8'd7, "BEQZ takes the branch to HALT");

        // ── Second run (restart) ─────────────────────────────────────────────
        // Verify the CPU re-executes the same program deterministically.
        @(negedge clk); start = 1'b1;
        @(negedge clk); start = 1'b0;
        wait (done);

        // Check 6: acc mirrors the last written register (R0 = 8 after ADD)
        check(acc === 8'd8, "CPU restarts deterministically");

        // ── Summary ──────────────────────────────────────────────────────────
        if (fail_count == 0)
            $display("=== PASS: %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

    // =========================================================================
    // Watchdog: abort simulation if done is not seen within 100 µs
    // Prevents the testbench from hanging on an infinite loop in the CPU.
    // =========================================================================
    initial begin
        #100_000;
        $display("FAIL: timeout — simulation exceeded 100 us watchdog");
        $finish;
    end

endmodule
