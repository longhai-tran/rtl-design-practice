/*******************************************************************************
 * Module: simple_cpu.v                                                        *
 * Description: Small, deterministic 8-bit CPU for RTL study and               *
 *              integration exercises.                                         *
 * File Created: Wednesday, 12th August 2026 4:37:56 pm                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 13th August 2026 11:01:50 am                       *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

/*
 * Simple CPU — Architecture & Design Notes
 * =========================================
 *
 * Overview
 * --------
 * A compact, synthesizable 8-bit processor intended to exercise RTL
 * control-path design skills.  All key internals (imem, dmem, regs) are
 * intentionally left visible for educational waveform inspection.
 * Production use would replace those arrays with instruction/data bus adapters.
 *
 * Instruction Format (16-bit fixed width)
 * ----------------------------------------
 *  [15:12]  opcode  — 4-bit operation selector
 *  [11:10]  rd      — 2-bit destination register index (R0–R3)
 *  [9:8]    rs      — 2-bit source register index      (R0–R3)
 *  [7:0]    imm     — 8-bit immediate / address field
 *
 * ISA Summary
 * -----------
 *  Opcode | Mnemonic | Operation
 *  -------+----------+------------------------------------------
 *  0x0    | NOP      | no operation
 *  0x1    | ADD      | rd = rd + rs
 *  0x2    | SUB      | rd = rd - rs
 *  0x3    | AND      | rd = rd & rs
 *  0x4    | OR       | rd = rd | rs
 *  0x5    | XOR      | rd = rd ^ rs
 *  0x6    | LOADI    | rd = imm        (load immediate)
 *  0x7    | LD       | rd = dmem[imm]  (load from data memory)
 *  0x8    | ST       | dmem[imm] = rd  (store to data memory)
 *  0x9    | JMP      | pc = imm        (unconditional jump)
 *  0xA    | BEQZ     | if (rd == 0) pc = imm, else pc++
 *  0xF    | HALT     | stop execution, pulse done, assert halted
 *
 * Pipeline / State Machine
 * ------------------------
 *  IDLE  : wait for start pulse, initialise pc = 0
 *  FETCH : load imem[pc] into instruction register (ir)
 *  EXEC  : decode & execute ir, update pc
 *  HALT  : remain idle; next start pulse resets pc and re-enters FETCH
 *
 *  All state transitions are single-cycle (no stall logic).
 *  The two-state FETCH→EXEC pipeline means each instruction costs 2 clock
 *  cycles from fetch to retire.
 *
 * Reset Behaviour
 * ---------------
 *  Synchronous active-low reset (rst_n).  All registers, memories, and
 *  control signals are cleared on the first rising clock edge after rst_n
 *  is de-asserted low.  imem contents survive reset — they must be loaded
 *  by the testbench or an external initialiser before start is asserted.
 *
 * Data Memory Bus
 * ---------------
 *  data_addr / data_wdata / data_we / data_rdata are exported for
 *  integration with an external memory model or AHB/APB bridge.
 *  In stand-alone simulation, dmem[] is accessed directly inside the module.
 */

`timescale 1ns/1ps

module simple_cpu #(
    parameter integer DATA_WIDTH = 8,  // Width of data bus, ALU, and registers
    parameter integer ADDR_WIDTH = 8   // Width of program counter and memory address
) (
    // ── Clock & Reset ──────────────────────────────────────────────────────────
    input  wire                  clk,        // System clock (rising-edge triggered)
    input  wire                  rst_n,      // Synchronous active-low reset

    // ── Control ────────────────────────────────────────────────────────────────
    input  wire                  start,      // Pulse HIGH one cycle to start / restart execution
    output reg                   busy,       // HIGH while CPU is executing (FETCH or EXEC state)
    output reg                   halted,     // HIGH after HALT instruction is executed
    output reg                   done,       // One-cycle pulse when HALT is reached

    // ── Debug / Observation ────────────────────────────────────────────────────
    output reg  [ADDR_WIDTH-1:0] pc,         // Program Counter — current fetch address

    // ── Accumulator (last ALU / load result) ───────────────────────────────────
    output reg  [DATA_WIDTH-1:0] acc,        // Mirrors the result written to rd

    // ── External Data Memory Bus ───────────────────────────────────────────────
    output reg  [DATA_WIDTH-1:0] data_addr,  // Address driven during LD / ST
    output reg  [DATA_WIDTH-1:0] data_wdata, // Write data driven during ST
    output reg                   data_we,    // Write-enable: HIGH for exactly one cycle on ST
    output reg  [DATA_WIDTH-1:0] data_rdata  // Read data captured during LD
);

    // =========================================================================
    // Opcode definitions — must match ISA table in the design notes above
    // =========================================================================
    localparam [3:0] OP_NOP   = 4'h0,  // No operation
                     OP_ADD   = 4'h1,  // rd = rd + rs
                     OP_SUB   = 4'h2,  // rd = rd - rs
                     OP_AND   = 4'h3,  // rd = rd & rs
                     OP_OR    = 4'h4,  // rd = rd | rs
                     OP_XOR   = 4'h5,  // rd = rd ^ rs
                     OP_LOADI = 4'h6,  // rd = imm (load immediate)
                     OP_LD    = 4'h7,  // rd = dmem[imm]
                     OP_ST    = 4'h8,  // dmem[imm] = rd
                     OP_JMP   = 4'h9,  // pc = imm (unconditional jump)
                     OP_BEQZ  = 4'hA,  // if (rd == 0) pc = imm else pc++
                     OP_HALT  = 4'hF;  // halt execution

    // =========================================================================
    // State machine encoding (Gray-code friendly 2-bit values)
    // =========================================================================
    localparam [1:0] S_IDLE  = 2'd0,  // Waiting for start pulse
                     S_FETCH = 2'd1,  // Fetching instruction from imem[pc]
                     S_EXEC  = 2'd2,  // Decoding and executing ir
                     S_HALT  = 2'd3;  // CPU halted; awaiting next start pulse

    // =========================================================================
    // Internal registers & memory
    // =========================================================================
    reg [1:0] state;                               // Current FSM state

    reg [15:0]          imem [0:(1<<ADDR_WIDTH)-1]; // Instruction memory: 2^ADDR_WIDTH × 16-bit words
    reg [DATA_WIDTH-1:0] dmem [0:(1<<ADDR_WIDTH)-1]; // Data memory:        2^ADDR_WIDTH × DATA_WIDTH bytes
    reg [DATA_WIDTH-1:0] regs [0:3];               // General-purpose register file: R0–R3

    reg [15:0]          ir;                        // Instruction register (holds fetched word)

    integer i; // Loop variable used only during reset initialisation

    // =========================================================================
    // Instruction field decode (combinational aliases from ir)
    // =========================================================================
    wire [3:0]           opcode = ir[15:12];          // Operation selector
    wire [1:0]           rd     = ir[11:10];           // Destination register index
    wire [1:0]           rs     = ir[9:8];             // Source register index
    wire [DATA_WIDTH-1:0] imm   = ir[DATA_WIDTH-1:0];  // Immediate / address field (lower 8 bits)

    // =========================================================================
    // Combinational ALU — result available the same cycle as EXEC state
    // Computed once from the decoded opcode; both regs[rd] and acc are
    // driven from this single wire, avoiding expression duplication.
    // =========================================================================
    reg [DATA_WIDTH-1:0] alu_out;
    always @(*) begin
        case (opcode)
            OP_ADD:   alu_out = regs[rd] + regs[rs];
            OP_SUB:   alu_out = regs[rd] - regs[rs];
            OP_AND:   alu_out = regs[rd] & regs[rs];
            OP_OR:    alu_out = regs[rd] | regs[rs];
            OP_XOR:   alu_out = regs[rd] ^ regs[rs];
            default:  alu_out = {DATA_WIDTH{1'b0}};
        endcase
    end

    // =========================================================================
    // Main FSM — synchronous, active-low reset
    // =========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            // -----------------------------------------------------------------
            // Synchronous reset: clear all state and outputs.
            // imem[] and dmem[] are NOT cleared — they retain simulation-loaded
            // or power-on-random contents, matching real SRAM behaviour.
            // -----------------------------------------------------------------
            state      <= S_IDLE;
            busy       <= 1'b0;
            halted     <= 1'b0;
            done       <= 1'b0;
            pc         <= {ADDR_WIDTH{1'b0}};
            acc        <= {DATA_WIDTH{1'b0}};
            data_addr  <= {DATA_WIDTH{1'b0}};
            data_wdata <= {DATA_WIDTH{1'b0}};
            data_we    <= 1'b0;
            data_rdata <= {DATA_WIDTH{1'b0}};
            ir         <= 16'h0000;
            for (i = 0; i < 4; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};

        end else begin
            // -----------------------------------------------------------------
            // Default pulse signals: de-assert every cycle unless re-driven.
            // This prevents single-cycle pulses from staying HIGH.
            // -----------------------------------------------------------------
            done    <= 1'b0;
            data_we <= 1'b0;

            case (state)

                // -------------------------------------------------------------
                // S_IDLE: CPU is idle, waiting for the start pulse.
                // On start, reset pc to 0 and move to FETCH.
                // -------------------------------------------------------------
                S_IDLE: begin
                    if (start) begin
                        busy   <= 1'b1;
                        halted <= 1'b0;
                        pc     <= {ADDR_WIDTH{1'b0}};
                        state  <= S_FETCH;
                    end
                end

                // -------------------------------------------------------------
                // S_FETCH: Load instruction at imem[pc] into the IR.
                // Single-cycle — immediately proceeds to EXEC next cycle.
                // -------------------------------------------------------------
                S_FETCH: begin
                    ir    <= imem[pc];
                    state <= S_EXEC;
                end

                // -------------------------------------------------------------
                // S_EXEC: Decode the IR and execute the instruction.
                //   - ALU ops write back to regs[rd] and mirror result to acc.
                //   - Memory ops drive the external data bus (data_addr, etc.).
                //   - pc is incremented or overridden by jump/branch instructions.
                //   - After execution, returns to S_FETCH (except HALT).
                // -------------------------------------------------------------
                S_EXEC: begin
                    case (opcode)
                        // -- No operation: advance PC only --
                        OP_NOP: begin
                            pc <= pc + 1'b1;
                        end

                        // -- Arithmetic / logic: rd = alu_out, mirror to acc --
                        // alu_out is evaluated combinationally from the same opcode;
                        // both destinations are driven from the single wire.
                        OP_ADD,
                        OP_SUB,
                        OP_AND,
                        OP_OR,
                        OP_XOR: begin
                            regs[rd] <= alu_out;
                            acc      <= alu_out;
                            pc       <= pc + 1'b1;
                        end

                        // -- Load immediate: rd = imm --
                        OP_LOADI: begin
                            regs[rd] <= imm;
                            acc      <= imm;
                            pc       <= pc + 1'b1;
                        end

                        // -- Load from data memory: rd = dmem[imm] --
                        OP_LD: begin
                            data_addr  <= imm;                // drive external address
                            data_rdata <= dmem[imm];          // capture internal memory
                            regs[rd]   <= dmem[imm];
                            acc        <= dmem[imm];
                            pc         <= pc + 1'b1;
                        end

                        // -- Store to data memory: dmem[imm] = rd --
                        OP_ST: begin
                            data_addr  <= imm;                // drive external address
                            data_wdata <= regs[rd];           // drive write data
                            dmem[imm]  <= regs[rd];           // write internal memory
                            data_we    <= 1'b1;               // assert write-enable for this cycle
                            pc         <= pc + 1'b1;
                        end

                        // -- Unconditional jump: pc = imm --
                        OP_JMP: begin
                            pc <= imm;
                            // Note: no pc+1 — target is taken immediately
                        end

                        // -- Branch if rd == 0: pc = imm, else pc++ --
                        OP_BEQZ: begin
                            if (regs[rd] == {DATA_WIDTH{1'b0}})
                                pc <= imm;    // branch taken
                            else
                                pc <= pc + 1'b1; // branch not taken, fall through
                        end

                        // -- Halt: stop execution, pulse done, enter S_HALT --
                        OP_HALT: begin
                            busy   <= 1'b0;
                            halted <= 1'b1;
                            done   <= 1'b1;   // single-cycle pulse — de-asserted next cycle
                            state  <= S_HALT;
                        end

                        // -- Unknown opcode: treat as NOP for safety --
                        default: begin
                            pc <= pc + 1'b1;
                        end
                    endcase

                    // Return to FETCH after any non-HALT instruction
                    if (opcode != OP_HALT)
                        state <= S_FETCH;
                end

                // -------------------------------------------------------------
                // S_HALT: CPU has finished execution.
                // A new start pulse resets pc to 0 and re-enters FETCH,
                // allowing deterministic re-execution of the same program.
                // -------------------------------------------------------------
                S_HALT: begin
                    if (start) begin
                        busy   <= 1'b1;
                        halted <= 1'b0;
                        pc     <= {ADDR_WIDTH{1'b0}};
                        state  <= S_FETCH;
                    end
                end

                // -------------------------------------------------------------
                // Unreachable: return to IDLE as a safe default
                // -------------------------------------------------------------
                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
