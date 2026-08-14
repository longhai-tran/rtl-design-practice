# Simple CPU — 8-bit Processor Core

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![ISA](https://img.shields.io/badge/ISA-Custom%208--bit-orange.svg)
![Pipeline](https://img.shields.io/badge/Pipeline-Fetch%2FExec-yellow.svg)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20xsim-blueviolet.svg)

A compact, synthesizable 8-bit processor designed to exercise RTL control-path skills.
`simple_cpu` integrates an ALU, a 4-register file, instruction/data memory arrays, and a
2-stage fetch/execute pipeline controlled by a 4-state FSM — all in a single self-contained
Verilog module.

All key internals (`imem`, `dmem`, `regs`) are intentionally kept visible for educational
waveform inspection. A production integration would replace those arrays with
instruction/data bus adapters (AHB, APB, or Wishbone).

---

## 📋 Specification

| Property            | Value                                                      |
|---------------------|------------------------------------------------------------|
| Data width          | 8-bit                                                      |
| Instruction width   | 16-bit fixed                                               |
| Register file       | 4 × 8-bit general-purpose registers (R0–R3)                |
| Instruction memory  | 256 × 16-bit words (`imem`)                                |
| Data memory         | 256 × 8-bit bytes (`dmem`)                                 |
| Pipeline stages     | 2 — FETCH and EXEC (no stall logic)                        |
| Cycles per instruction | 2 (1 fetch + 1 execute)                               |
| Reset style         | Synchronous, active-low (`rst_n`)                          |
| Control interface   | `start` pulse → `busy` / `done` / `halted` handshake      |
| Data memory bus     | External `data_addr` / `data_wdata` / `data_we` / `data_rdata` |

---

## 🏗️ Architecture

### Parameters

| Parameter    | Default | Description                       |
|--------------|--------:|-----------------------------------|
| `DATA_WIDTH` | `8`     | Width of data bus, ALU, registers |
| `ADDR_WIDTH` | `8`     | Width of program counter and memory address (256 locations) |

### State Machine

```text


                                                    start
                             ┌───────────────────────────────────────────────────┐
    reset                    │                                                   │
      │                      │                     ┌────────► OP_HALT ───────► S_HALT
      ▼         start        ▼                     │
    S_IDLE  ────────────► S_FETCH ───────► S_EXEC ─┤
                                                   │
                                                   │
                                                   └────────────► S_FETCH
                                                     (non-HALT)
```



> **Reset** (`rst_n=0`) có thể đưa CPU về `S_IDLE` từ **bất kỳ trạng thái nào** (synchronous).

| State   | Description                                                   |
|---------|---------------------------------------------------------------|
| `IDLE`  | Waiting for `start` pulse; `busy = 0`                         |
| `FETCH` | Loads `imem[pc]` into instruction register `ir`               |
| `EXEC`  | Decodes and executes `ir`; updates `pc`, registers, memory    |
| `HALT`  | CPU stopped after `OP_HALT`; restarts on next `start` pulse   |

### Block Diagram

```text
                  ┌──────────────────────────────────────────┐
  clk, rst_n ───> │                                          │
  start      ───> │                simple_cpu                │──► busy, halted, done
                  │                                          │──► pc[7:0], acc[7:0]
                  │   ┌──────────┐    ┌──────────────────┐   │
                  │   │  imem[]  │───>│ Instruction Reg  │   │──► data_addr[7:0]
                  │   │ 256×16b  │    │   (ir[15:0])     │   │──► data_wdata[7:0]
                  │   └──────────┘    └────────┬─────────┘   │──► data_we
                  │                            │ decode      │──► data_rdata[7:0]
                  │                    ┌───────▼──────────┐  │
                  │   ┌──────────┐     │    FSM + ALU     │  │
                  │   │  dmem[]  │◄──► │  (FETCH/EXEC)    │  │
                  │   │ 256×8b   │     └───────┬──────────┘  │
                  │   └──────────┘             │             │
                  │   ┌──────────────────────┐ │             │
                  │   │   regs[] R0–R3       │◄┘             │
                  │   │   (4 × 8-bit)        │               │
                  │   └──────────────────────┘               │
                  └──────────────────────────────────────────┘
```

---

## 💻 ISA Reference (Instruction Set Architecture)

Instruction format: `[15:12] opcode | [11:10] rd | [9:8] rs | [7:0] immediate`

| Opcode | Mnemonic | Operation                         | Notes                             |
|:------:|----------|-----------------------------------|-----------------------------------|
| `0x0`  | `NOP`    | `pc++`                            | No operation                      |
| `0x1`  | `ADD`    | `rd = rd + rs`                    | Result also mirrored to `acc`     |
| `0x2`  | `SUB`    | `rd = rd - rs`                    | Result also mirrored to `acc`     |
| `0x3`  | `AND`    | `rd = rd & rs`                    | Result also mirrored to `acc`     |
| `0x4`  | `OR`     | `rd = rd \| rs`                   | Result also mirrored to `acc`     |
| `0x5`  | `XOR`    | `rd = rd ^ rs`                    | Result also mirrored to `acc`     |
| `0x6`  | `LOADI`  | `rd = imm`                        | Load 8-bit immediate              |
| `0x7`  | `LD`     | `rd = dmem[imm]`                  | Load from data memory             |
| `0x8`  | `ST`     | `dmem[imm] = rd`                  | Store to data memory; pulses `data_we` |
| `0x9`  | `JMP`    | `pc = imm`                        | Unconditional jump                |
| `0xA`  | `BEQZ`   | `if (rd==0) pc=imm else pc++`     | Branch if register equals zero    |
| `0xF`  | `HALT`   | Stop; pulse `done`, assert `halted` | CPU waits in HALT until `start` |

> **Encoding example:**
> `LOADI R0, 5` → `{4'h6, 2'd0, 2'd0, 8'd5}` = `16'h6005`
> `ADD R0, R1`  → `{4'h1, 2'd0, 2'd1, 8'd0}` = `16'h1040`

---

## 🔌 Port List / Interface

| Signal        | Dir    | Width            | Active | Description                                            |
|---------------|--------|:----------------:|--------|--------------------------------------------------------|
| `clk`         | Input  | 1                | ↑      | System clock (rising-edge triggered)                   |
| `rst_n`       | Input  | 1                | LOW    | Synchronous active-low reset                           |
| `start`       | Input  | 1                | HIGH   | One-cycle pulse to start or restart execution          |
| `busy`        | Output | 1                | HIGH   | HIGH while CPU is in FETCH or EXEC state               |
| `halted`      | Output | 1                | HIGH   | Asserted after `OP_HALT`; cleared by next `start`      |
| `done`        | Output | 1                | HIGH   | One-cycle pulse when `OP_HALT` is executed             |
| `pc`          | Output | `ADDR_WIDTH`     | —      | Current program counter value                          |
| `acc`         | Output | `DATA_WIDTH`     | —      | Last ALU result or loaded value (mirrors `rd` write)   |
| `data_addr`   | Output | `DATA_WIDTH`     | —      | Memory address driven during `LD` / `ST`               |
| `data_wdata`  | Output | `DATA_WIDTH`     | —      | Write data driven during `ST`                          |
| `data_we`     | Output | 1                | HIGH   | Write-enable; asserted for exactly one clock on `ST`   |
| `data_rdata`  | Output | `DATA_WIDTH`     | —      | Read data captured from `dmem` during `LD`             |

**Signal timing notes:**
- `start` must be asserted for exactly **one** `clk` rising edge.
- `start` while `busy = 1` is ignored — it has no effect on the running program.
- `done` is a **one-clock-wide** pulse; latch it with a flag register if needed.
- `data_we` is a **one-clock-wide** pulse asserted in the same cycle as `ST` execution.

---

## 🔄 Execution Flow

```text
Cycle:  1       2       3       4       5       6  ...
State: IDLE   FETCH   EXEC    FETCH   EXEC    FETCH ...
        ↑       ↑       ↑
      start  imem[0] execute
      pulse  loaded  instr[0]
```

Each instruction consumes **2 clock cycles**: one FETCH + one EXEC.
There is no stall, hazard detection, or forwarding logic — the ISA is designed to avoid data hazards within this simple pipeline.

---

## 🖥️ Simulation Results

```text
=== simple_cpu self-checking testbench ===
Check time: 175000 ps
PASS: CPU reaches HALT and drops busy
PASS: ADD computes R0 = 5 + 3
PASS: LOAD reads the stored value
PASS: STORE writes data memory
PASS: BEQZ takes the branch to HALT
PASS: CPU restarts deterministically
=== PASS: 6 checks passed ===
```

Simulation completed at **325 ns** (Vivado xsim v2025.2).

---

## 🚀 How to Run

### Vivado xsim

```bash
cd sim/xsim && make sim

# Open waveform GUI view:
make gui

# Clean up generated files:
make clean
```

### ModelSim / Questa

```bash
cd sim/modelsim && make sim

# Open waveform GUI view:
make gui

# Clean up generated files:
make clean
```

### Portable (without Make)

```bash
# Vivado xsim
cd sim/xsim && xtclsh simulate.tcl

# ModelSim / Questa
cd sim/modelsim && vsim -c -do simulate.do
```

---

## ✅ Test Cases / Coverage

| # | Test                        | Condition                                           | Expected                                            | Result   |
|---|-----------------------------|-----------------------------------------------------|-----------------------------------------------------|----------|
| 1 | Reset & HALT handshake      | Run program to HALT                                 | `halted=1`, `busy=0` after `done` pulse             | ✅ Pass  |
| 2 | ADD instruction             | `LOADI R0,5` → `LOADI R1,3` → `ADD R0,R1`          | `regs[0] == 8`                                      | ✅ Pass  |
| 3 | LOAD from data memory       | `ST R0, 0x20` → `LD R2, 0x20`                      | `regs[2] == 8`                                      | ✅ Pass  |
| 4 | STORE to data memory        | `ST R0, 0x20`                                       | `dmem[0x20] == 8`                                   | ✅ Pass  |
| 5 | BEQZ branch taken           | `R3 == 0` → `BEQZ R3, 7`                           | `pc == 7` (branch skips instruction [6])            | ✅ Pass  |
| 6 | Deterministic restart       | `start` again after `HALT`                          | `acc` matches first run; program re-executes cleanly | ✅ Pass  |

Detailed verification intent is recorded in [docs/test_plan.md](docs/test_plan.md).

---

## 📁 File Structure

```text
06_advanced/simple_cpu/
├── simple_cpu.v          ← RTL: CPU datapath + FSM (synthesizable)
├── simple_cpu_tb.v       ← Self-checking testbench (6 checks, watchdog guard)
├── README.md             ← This file
├── docs/
│   └── test_plan.md      ← Verification plan and test intent
└── sim/
    ├── modelsim/         ← make sim | make gui | make do | make clean
    └── xsim/             ← make sim | make gui | make clean
```

---

## ⚠️ Known Limitations

| # | Limitation                                         | Suggested Extension                                  |
|---|----------------------------------------------------|------------------------------------------------------|
| 1 | No pipeline hazard detection or forwarding         | Add forwarding path between EXEC and FETCH           |
| 2 | `imem` / `dmem` initialised only by testbench      | Add `$readmemh` or bus-accessible loader             |
| 3 | No interrupt or exception mechanism                | Add interrupt vector table and handler jump          |
| 4 | Only 4 registers (R0–R3)                           | Extend `rd`/`rs` to 3-bit for 8 registers            |
| 5 | No carry/zero flag in ALU                          | Add status register; extend BEQZ to branch on flags  |
| 6 | `data_rdata` is directly from `dmem` — no latency  | Add one-cycle read latency for SRAM compatibility    |

---

## 📚 References

### 🌐 Online Articles & Tutorials (Dễ đọc, dễ tìm)

| # | Tiêu đề | Link |
|---|---------|------|
| [1] | **How to design a simple CPU from first principles** | [Medium – Anan Mirji](https://medium.com/@anan.mirji/how-do-design-a-simple-cpu-from-first-principles-8e0415f714b6) |
| [2] | **Digital Design & Computer Architecture – Chapter 7 slides** (official companion) | [ddcabook.com](https://www.ddcabook.com) |

---

*Module: `simple_cpu.v` · Author: Long Hai · ISA: Custom 8-bit · Pipeline: 2-stage Fetch/Exec*
