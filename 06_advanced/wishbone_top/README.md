# Wishbone Top — Two-Slave Register Subsystem

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![Protocol](https://img.shields.io/badge/Protocol-Wishbone%20B4-green.svg)
![Topology](https://img.shields.io/badge/Topology-1M%20%2F%202S-orange.svg)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20xsim-blueviolet.svg)

A synthesizable Wishbone B4 Classic subsystem containing one command-driven master, a
one-to-two address-decoding interconnect, and two register-bank slaves.
`wishbone_top` demonstrates request/response timing, address decoding, response multiplexing,
byte enables, bus errors, and read-only registers — all in a single self-contained integration.

> 📖 For full Wishbone protocol background, see [`docs/wishbone_theory.md`](../../docs/wishbone_theory.md)
> (Classic single transfer, CYC/STB/ACK/ERR handshake, address decoding, byte enables).

---

## 📋 Specification

| Property                 | Value                                                          |
|--------------------------|----------------------------------------------------------------|
| Wishbone revision        | B4, Classic single transfer                                    |
| Address width            | 16 bits                                                        |
| Data width               | 32 bits                                                        |
| Granularity              | 8-bit byte lanes through `SEL[3:0]`                            |
| Outstanding transactions | One (single-outstanding master)                                |
| Reset                    | Active-low synchronous                                         |
| Termination              | Exactly one of `ACK`, `ERR`, or master timeout                 |
| Topology                 | 1 master → 1-to-2 interconnect → 2 slaves                      |
| Slave address regions    | `0x0000–0x0FFF` (Slave 0), `0x1000–0x1FFF` (Slave 1)          |

---

## 🏗️ Architecture

### Parameters

| Parameter        | Default | Module        | Description                                          |
|------------------|---------|---------------|------------------------------------------------------|
| `ADDR_WIDTH`     | `16`    | master, slave | Address bus width in bits                            |
| `DATA_WIDTH`     | `32`    | master, slave | Data bus width in bits                               |
| `TIMEOUT_CYCLES` | `16`    | master        | Max clocks to wait for ACK/ERR before forcing error  |
| `ID_VALUE`       | varies  | slave         | Read-only instance identifier returned at offset `0xC` |

Slave 0 is instantiated with `ID_VALUE = 32'h5742_5330` (`"WBS0"`),
Slave 1 with `ID_VALUE = 32'h5742_5331` (`"WBS1"`).

### File Structure

```text
06_advanced/wishbone_top/
├── wishbone_master.v       ← RTL: single-outstanding Wishbone B4 master + timeout
├── wishbone_interconnect.v ← RTL: address decode, request routing, response mux
├── wishbone_slave.v        ← RTL: 4-register bank (SEL, ACK, ERR, R/O ID)
├── wishbone_top.v          ← Structural wrapper: 1 master, interconnect, 2 slaves
├── wishbone_top_tb.v       ← Self-checking integration testbench (6 TCs, 24 checks)
├── README.md               ← This file
├── docs/
│   └── test_plan.md        ← Verification plan and test intent
└── sim/
    ├── modelsim/           ← make sim | make gui | make do | make clean
    └── xsim/              ← make sim | make gui | make clean
```

### Top-Level Block Diagram

```text
 Command interface
       |
       v
 +-----------+     Wishbone B4      +--------------------+
 |  master   |-------------------->| 1-to-2 interconnect|
 +-----------+                     +---------+----------+
                                             |
                                 +-----------+-----------+
                                 v                       v
                           +-----------+           +-----------+
                           | slave 0   |           | slave 1   |
                           | 0x0xxx    |           | 0x1xxx    |
                           +-----------+           +-----------+
```

### Sub-Module Responsibilities

| File                        | Responsibility                                                       |
|-----------------------------|----------------------------------------------------------------------|
| `wishbone_master.v`         | Converts one-cycle commands into Classic bus cycles; timeout guard   |
| `wishbone_interconnect.v`   | Decodes address region, routes requests, multiplexes responses       |
| `wishbone_slave.v`          | Reusable register bank with `SEL`, `ACK`, `ERR`, and read-only ID   |
| `wishbone_top.v`            | Integrates one master, interconnect, and two slave instances         |
| `wishbone_top_tb.v`         | Self-checking subsystem-level verification                           |

### Master State Machine

```text
  reset
    |
    v      cmd_valid             ACK / ERR / timeout
  S_IDLE  ────────────► S_BUSY ───────────────────────► S_IDLE
  (busy=0,              (busy=1,                      (busy=0,
  cmd_ready=1)          CYC/STB=1)                    done=1 pulse,
                                                      1 clock only)

```

| State    | Description                                                                     |
|----------|---------------------------------------------------------------------------------|
| `S_IDLE` | Waiting for `cmd_valid`; `cmd_ready = 1`, `busy = 0`                            |
| `S_BUSY` | `CYC/STB` held; address/data/`SEL`/`WE` stable on bus; timeout counter running  |
| `S_DONE` | One-clock `done` pulse; captures `read_data` and `error`; returns to `S_IDLE`   |

---

## 🗺️ Address Map

| Address range   | Target  | Description              |
|-----------------|---------|--------------------------|
| `0x0000–0x0FFF` | Slave 0 | Register peripheral 0    |
| `0x1000–0x1FFF` | Slave 1 | Register peripheral 1    |
| `0x2000–0xFFFF` | None    | Immediate `ERR` response |

Each slave decodes the low four address bits (word-aligned only):

| Offset | Name      | Access | Reset value     | Description                       |
|-------:|-----------|--------|----------------:|-----------------------------------|
| `0x0`  | `CONTROL` | R/W    | `32'h0`         | General control register          |
| `0x4`  | `DATA`    | R/W    | `32'h0`         | General data register             |
| `0x8`  | `SCRATCH` | R/W    | `32'h0`         | Software scratch register         |
| `0xC`  | `ID`      | R/O    | `WBS0` / `WBS1` | Read-only instance identification |

> **Error conditions**: unaligned access (`addr[1:0] != 2'b00`) or write to `ID`
> returns `ERR` without changing slave state.

---

## 🔌 Port List / Interface

### Command Interface (host → top)

| Signal      | Dir    | Width | Active | Description                                                          |
|-------------|--------|------:|--------|----------------------------------------------------------------------|
| `clk`       | Input  |     1 | ↑      | System clock (rising-edge triggered)                                 |
| `rst_n`     | Input  |     1 | LOW    | Active-low synchronous reset                                         |
| `cmd_valid` | Input  |     1 | HIGH   | One-clock request pulse, accepted only when `cmd_ready = 1`          |
| `cmd_write` | Input  |     1 | —      | `1` = write, `0` = read                                              |
| `cmd_addr`  | Input  |    16 | —      | Byte address                                                         |
| `cmd_wdata` | Input  |    32 | —      | Write payload (ignored on reads)                                     |
| `cmd_sel`   | Input  |     4 | HIGH   | Active byte lanes (`1` = update lane)                                |
| `cmd_ready` | Output |     1 | HIGH   | Master can accept a new command (`= !busy`)                          |
| `read_data` | Output |    32 | —      | Read result; valid when `done = 1` and `error = 0`                   |
| `busy`      | Output |     1 | HIGH   | Transaction is outstanding                                           |
| `done`      | Output |     1 | HIGH   | One-clock completion pulse                                           |
| `error`     | Output |     1 | HIGH   | Completion caused by `ERR` or master timeout                         |

**Signal timing notes:**
- `cmd_valid` must be asserted for exactly **one** `clk` rising edge while `cmd_ready = 1`.
- `cmd_valid` while `cmd_ready = 0` (busy) is silently ignored.
- `done` and `error` are each **one clock wide**; latch with a flag register if needed.
- `cmd_addr`, `cmd_wdata`, `cmd_sel`, `cmd_write` are **latched** when `cmd_valid && cmd_ready`;
  input changes after that do not affect the active transaction.

### Wishbone Bus (exposed for waveform / on-chip debug)

| Signal     | Dir    | Width | Description                     |
|------------|--------|------:|---------------------------------|
| `wb_addr`  | Output |    16 | Current bus address             |
| `wb_wdata` | Output |    32 | Write data (master → slave)     |
| `wb_rdata` | Output |    32 | Read data (slave → master)      |
| `wb_sel`   | Output |     4 | Active byte lanes               |
| `wb_we`    | Output |     1 | Write enable                    |
| `wb_cyc`   | Output |     1 | Bus cycle active                |
| `wb_stb`   | Output |     1 | Transfer request valid          |
| `wb_ack`   | Output |     1 | Normal termination from slave   |
| `wb_err`   | Output |     1 | Error termination from slave    |

### Slave Register Outputs (for waveform inspection)

| Signal           | Width | Description                            |
|------------------|------:|----------------------------------------|
| `slave0_control` |    32 | Live value of Slave 0 CONTROL register |
| `slave0_data`    |    32 | Live value of Slave 0 DATA register    |
| `slave0_scratch` |    32 | Live value of Slave 0 SCRATCH register |
| `slave1_control` |    32 | Live value of Slave 1 CONTROL register |
| `slave1_data`    |    32 | Live value of Slave 1 DATA register    |
| `slave1_scratch` |    32 | Live value of Slave 1 SCRATCH register |

---

## 🔄 Transaction Flow

```text
clk        _/\_/\_/\_/\_/\_/\_/\_
cmd_valid  ___/‾\__________________
cmd_ready  ‾‾‾‾‾\_____/‾‾‾‾‾‾‾‾‾‾‾‾   (deasserts when busy, reasserts after done)
CYC / STB  _____/‾‾‾‾‾\____________
ACK / ERR  _______/\_______________
done       __________/\____________
error      __________/\____________   (only on ERR or timeout)
```

1. Assert `cmd_valid` for one clock while `cmd_ready = 1`.
2. Master latches all command fields; drives `CYC`, `STB`, address, data, `WE`, `SEL`.
3. Interconnect decodes address, routes to the correct slave (or returns `ERR` for unmapped region).
4. Slave responds with `ACK` (or `ERR`) after one pipeline clock.
5. Master terminates cycle: deasserts `CYC/STB`, pulses `done`, captures `read_data`/`error`.

---

## 🖥️ Simulation Results

```text
=== wishbone_top Testbench (1 master, 2 slaves) ===
[36000 ns] PASS: Reset: master and bus return to idle
[36000 ns] PASS: Reset: all slave register banks cleared to zero

--- TC1: Slave 0 full-word write / read-back ---
[86000 ns] PASS: done pulse is exactly one clock wide
[86000 ns] PASS: TC1: slave 0 CONTROL register accepts full-word write
[126000 ns] PASS: done pulse is exactly one clock wide
[126000 ns] PASS: TC1: slave 0 CONTROL register returns written value on read

--- TC2: Slave 1 decode isolation ---
[166000 ns] PASS: done pulse is exactly one clock wide
[166000 ns] PASS: TC2: interconnect routes 0x1xxx writes to slave 1
[166000 ns] PASS: TC2: slave 0 DATA register unchanged by slave 1 access

--- TC3: Byte select ---
[206000 ns] PASS: done pulse is exactly one clock wide
[246000 ns] PASS: done pulse is exactly one clock wide
[246000 ns] PASS: TC3: SEL=0101 updates only byte lanes 0 and 2

--- TC4: Read-only identification registers ---
[286000 ns] PASS: done pulse is exactly one clock wide
[286000 ns] PASS: TC4: slave 0 ID register returns 0x57425330 ("WBS0")
[326000 ns] PASS: done pulse is exactly one clock wide
[326000 ns] PASS: TC4: slave 1 ID register returns 0x57425331 ("WBS1")
[366000 ns] PASS: done pulse is exactly one clock wide
[366000 ns] PASS: TC4: write to read-only ID register returns ERR

--- TC5: Error responses ---
[396000 ns] PASS: done pulse is exactly one clock wide
[396000 ns] PASS: TC5: unmapped address (0x2000) returns ERR immediately
[436000 ns] PASS: done pulse is exactly one clock wide
[436000 ns] PASS: TC5: unaligned address (ADR[1:0]=10) returns ERR

--- TC6: Command-while-busy is ignored ---
[476000 ns] PASS: TC6: first command completes without data corruption
[476000 ns] PASS: TC6: second command (while busy) is silently ignored

-----------------------------------------------
=== PASS: all 24 checks passed ===
```

> Timestamps are in **ns** (`timescale 1ns/1ps`). Simulation completed at **476 ns**.

```text
Questa/ModelSim 2025.2 : compile 0 errors, 0 warnings
Vivado xsim 2025.2     : compile and elaborate successful
Testbench              : PASS — all 24 checks passed at 476 ns
```

---

## 🚀 How to Run

### Vivado xsim

```bash
cd sim/xsim && make sim

# Open styled waveform GUI:
make gui

# Clean up generated files:
make clean
```

### ModelSim / Questa

```bash
cd sim/modelsim && make sim

# Open styled waveform GUI:
make gui

# Clean up generated files:
make clean
```

### Portable Environment (Without Make)

```bash
# Vivado xsim
cd sim/xsim && xtclsh simulate.tcl

# ModelSim / Questa
cd sim/modelsim && vsim -c -do simulate.do
```

---

## ✅ Test Cases / Coverage

| #  | Test                       | Condition                                           | Expected                                                            | Result  |
|----|----------------------------|-----------------------------------------------------|---------------------------------------------------------------------|---------|
| 1  | Reset & idle               | Assert `rst_n=0`, release                           | `busy=0`, `cmd_ready=1`, `wb_cyc=0`; both slave banks cleared       | ✅ Pass |
| 2  | Slave 0 write/read         | Write `0x1122_3344` to `0x0000`, read back          | `slave0_control` matches; `read_data` returns written value          | ✅ Pass |
| 3  | Slave 1 decode isolation   | Write `0xCAFE_BABE` to `0x1004`                     | Slave 1 `data` updated; Slave 0 `data` unchanged                    | ✅ Pass |
| 4  | Byte-enable write          | Write `0xAABB_CCDD` with `SEL=4'b0101` to `0x0000`  | Only byte lanes 0 and 2 updated; other lanes retain prior value     | ✅ Pass |
| 5  | Read-only ID registers     | Read `0x000C` and `0x100C`; write to `0x000C`       | Returns `"WBS0"` / `"WBS1"`; write returns `ERR`, no state change   | ✅ Pass |
| 6  | Unmapped address ERR       | Read `0x2000`                                       | `error=1` on `done`; no timeout delay                               | ✅ Pass |
| 7  | Unaligned access ERR       | Read `0x1002` (unaligned)                           | `error=1` on `done`; slave state unchanged                          | ✅ Pass |
| 8  | Command while busy ignored | Issue second `cmd_valid` during active transaction  | Active transaction completes cleanly; second command discarded      | ✅ Pass |

Detailed verification intent is recorded in [docs/test_plan.md](docs/test_plan.md).

---

## ⚠️ Known Limitations

| # | Limitation                       | Suggested Extension                                              |
|---|----------------------------------|------------------------------------------------------------------|
| 1 | One master only                  | Add round-robin multi-master arbitration                         |
| 2 | Classic cycles only              | Add pipelined or registered-feedback (STALL-based) cycles        |
| 3 | Fixed two-region decode          | Parameterize base/mask address tables for N slaves               |
| 4 | No `RTY` (retry) response        | Add `RTY` support and retry counter in master                    |
| 5 | Internal register slaves only    | Connect UART, SPI, timer, or GPIO peripherals as Wishbone slaves |
| 6 | Timeout fires silently           | Add interrupt output on timeout event                            |

The next useful integration exercise is to replace the command master with `simple_cpu`
load/store requests and expose these slaves as CPU memory-mapped peripherals.

---

## 📚 References

| #   | Title | Source |
|-----|-------|--------|
| [1] | **Wishbone B4 — Lý Thuyết Bus Wishbone** | [`docs/wishbone_theory.md`](../../docs/wishbone_theory.md) — Classic transfer, CYC/STB/ACK/ERR handshake, address decode, byte enables |
| [2] | **Wishbone B4 Bus Specification Rev. B4** | [OpenCores WISHBONE B4](https://cdn.opencores.org/downloads/wbspec_b4.pdf) |
| [3] | **Wishbone Interconnect — Wikipedia** | [wikipedia.org](https://en.wikipedia.org/wiki/Wishbone_(computer_bus)) |
| [4] | **Simple CPU integration target** | [`06_advanced/simple_cpu/README.md`](../simple_cpu/README.md) |

---

*Module: `wishbone_top.v` · Author: Long Hai · Protocol: Wishbone B4 Classic · Topology: 1M/2S*
