# I2C Top — Integrated Controller & Target

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![Protocol](https://img.shields.io/badge/Protocol-I²C-green.svg)
![Address](https://img.shields.io/badge/Address-7--bit-orange.svg)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20xsim-blueviolet.svg)

A synthesizable I²C subsystem integrating `i2c_master` and `i2c_slave` on a shared two-wire open-drain bus.
`i2c_top` performs one-byte read or write transactions and exposes the resolved SCL/SDA bus for waveform
inspection. The wrapper is purely structural: no hidden buffering or arbitration — the open-drain bus model
is resolved by combinational wired-AND logic.

> 📖 For full I²C protocol background, see [`docs/i2c_theory.md`](../../docs/i2c_theory.md)
> (open-drain bus, START/STOP conditions, address frame, ACK/NACK, MSB-first bit order, multi-slave).

---

## 📋 Specification

| Property             | Value                                                         |
|----------------------|---------------------------------------------------------------|
| Protocol             | I²C — Inter-Integrated Circuit                               |
| Address width        | 7-bit target address, MSB-first                               |
| Data width           | 1 byte per transaction                                        |
| Duplex               | Half-duplex; SDA shared between controller and target         |
| Transactions         | Write and Read, each consisting of one address + one data byte |
| ACK/NACK             | Target ACKs matching address and received write byte; controller NACKs after last read byte |
| Bus model            | Wired-AND open-drain (ideal pull-ups); `scl` and `sda` resolved in top |
| Clock source         | Internal divider — `f_scl = f_clk / (2 × max(CLK_DIV, 2))`  |
| Target clock domain  | System-clocked edge detector on SCL and SDA                   |
| Request policy       | `start` accepted only while `master_busy = 0`                 |
| Completion signals   | Independent `master_done` and `slave_done` one-clock pulses   |
| Reset style          | Active-low synchronous, shared by both endpoints              |

---

## 🏗️ Architecture

### Parameters

| Parameter    | Default   | Description                                                  |
|--------------|----------:|--------------------------------------------------------------|
| `CLK_DIV`    |       `4` | System clocks per SCL half-period; values below 2 are clamped to 2 |
| `SLAVE_ADDR` | `7'h42`   | 7-bit address recognized by the integrated target            |

> **Note:** `CLK_DIV < 2` is clamped to `2` so the system-clocked slave can reliably detect each SCL edge.
>
> `f_scl = f_clk / (2 × max(CLK_DIV, 2))`

### Dependencies

`i2c_top.v` instantiates these sibling modules:

```text
05_interfaces/i2c_top/
├── i2c_master.v      ← RTL: I2C controller, owns SCL / SDA drive timing
├── i2c_slave.v       ← RTL: I2C target,  edge-detects SCL / SDA
├── i2c_top.v         ← Structural wrapper + open-drain bus resolution
├── i2c_top_tb.v      ← Self-checking integration TB (6 TCs, 96 checks)
├── docs/
│   └── test_plan.md
└── sim/
    ├── modelsim/
    └── xsim/
```

### Top-Level Block Diagram

```text
  master_tx_data                         slave_tx_data
        │                                      │
        ▼                                      ▼
 ┌─────────────┐    SCL (open-drain)   ┌─────────────┐
 │ i2c_master  │──────────────────────>│ i2c_slave   │
 │             │<──────────────────────│             │
 └─────────────┘    SDA (open-drain)   └─────────────┘
        │                                      │
        │                                      │
        │                                      │
        ▼                                      ▼
 master_rx_data                        slave_rx_data
```

The internal open-drain bus is resolved by the top-level wrapper:

```verilog
assign scl = master_scl_drive_low ? 1'b0 : 1'b1;
assign sda = (master_sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1;
```

The resolved `sda` is fed back to both endpoints, allowing the master to read the
target's ACK and the target to detect START/STOP conditions.

### Sub-Module Port Diagrams

```text
                         +----------------------+
       clk ------------->|                      |-----> scl_drive_low
     rst_n ------------->|                      |-----> sda_drive_low
     start ------------->|      i2c_master      |-----> busy
        rw ------------->|                      |-----> done
 target_addr[6:0] ------>|                      |-----> ack_error
   tx_data[7:0] -------->|                      |-----> rx_data[7:0]
       sda ------------->|                      |
                         +----------------------+
```

```text
                         +----------------------+
       clk ------------->|                      |-----> sda_drive_low
     rst_n ------------->|                      |-----> rx_data[7:0]
       scl ------------->|      i2c_slave       |-----> rx_valid
       sda ------------->|                      |-----> busy
   tx_data[7:0] -------->|                      |-----> done
                         +----------------------+
```

### Supported Transactions

```text
Write: START | addr[6:0] + W | ACK | data from master | ACK  | STOP
Read : START | addr[6:0] + R | ACK | data from slave  | NACK | STOP
```

---

## 🔌 Port List / Interface

| Signal           | Dir    | Width | Active | Description                                                    |
|------------------|--------|------:|--------|----------------------------------------------------------------|
| `clk`            | Input  |     1 | ↑      | Shared system clock                                            |
| `rst_n`          | Input  |     1 | LOW    | Active-low synchronous reset                                   |
| `start`          | Input  |     1 | HIGH   | One-clock request to begin a transaction                       |
| `rw`             | Input  |     1 | —      | `0` = write, `1` = read                                        |
| `target_addr`    | Input  |     7 | —      | 7-bit address transmitted by the controller                    |
| `master_tx_data` | Input  |     8 | —      | Byte sent during a write transaction                           |
| `slave_tx_data`  | Input  |     8 | —      | Byte returned by the target during a read transaction          |
| `master_rx_data` | Output |     8 | —      | Completed read byte received by the controller                 |
| `slave_rx_data`  | Output |     8 | —      | Completed write byte received by the target                    |
| `slave_rx_valid` | Output |     1 | HIGH   | One-clock pulse when a write byte is accepted by the target    |
| `master_busy`    | Output |     1 | HIGH   | Controller transaction in progress                             |
| `master_done`    | Output |     1 | HIGH   | One-clock pulse after STOP completes                           |
| `slave_busy`     | Output |     1 | HIGH   | Target is processing a matching or active frame                |
| `slave_done`     | Output |     1 | HIGH   | One-clock pulse when the selected frame ends                   |
| `ack_error`      | Output |     1 | HIGH   | Address or write-data NACK; cleared by next request or reset   |
| `scl`            | Output |     1 | —      | Resolved open-drain serial clock (observable)                  |
| `sda`            | Output |     1 | —      | Resolved open-drain serial data (observable)                   |

**Signal timing notes:**
- `start` must be asserted for exactly **one** `clk` rising edge while `master_busy = 0`.
- `start` while `master_busy = 1` is silently ignored — no effect on the active transaction.
- `target_addr`, `rw`, `master_tx_data`, and `slave_tx_data` are **captured** when the idle
  controller accepts `start`; input changes after that do not affect the active transaction.
- `master_done` and `slave_done` are each **one clock wide**; capture with a flag register if needed.
- `slave_done` arrives `CLK_DIV − 1` clocks **before** `master_done`: the slave edge-detects STOP one system-clock after SDA rises, while the master still needs one full `half_tick` (`CLK_DIV` cycles) in `ST_STOP_FREE` before pulsing `done`.

---

## 🔄 Transaction Flow

### Write

```text
START → addr[6:0]+W → ACK → data[7:0] → ACK → STOP
```

```text
      start __|‾|__________________________________________________________
  master_busy _____|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|________
        sda  ‾‾‾\_____[A6..A0,W]___[ACK]___[D7..D0]___[ACK]___/‾‾‾‾‾‾‾‾‾‾‾‾
        scl  ‾‾‾‾‾‾‾|_|‾|_|‾|_ ··· _|‾|_··_|‾|_ ····· _|‾|_.._|‾|_|‾|_|‾‾‾‾
  slave_done __________________________________________________|‾|_________
 master_done _____________________________________________________|‾|______
```

- Target ACKs both address and data frames by pulling SDA LOW.
- `slave_rx_valid` pulses one clock after the data ACK (on the SCL falling edge).

### Read

```text
START → addr[6:0]+R → ACK → data[7:0] → NACK → STOP
```

- Target drives data bits on each SCL falling edge; controller samples on each SCL falling edge.
- Controller sends open-drain NACK (releases SDA — pull-up holds HIGH) on a dedicated 18th SCL cycle.

### Address NACK

```text
START → addr[6:0]+R/W → NACK → STOP   →   ack_error = 1  (9 SCL edges only)
```

### Completion Timing

- `slave_done` fires `CLK_DIV − 1` clocks **before** `master_done`: the target edge-detects STOP one system-clock after SDA rises, while the controller waits one more `half_tick` in `ST_STOP_FREE`.

---

## 🖥️ Simulation Results

Run from either `sim/modelsim` or `sim/xsim` to validate the design.

```text
=== i2c_top self-checking integration testbench ===

--- [0 ps] TC1: Reset and idle bus         ---

--- [60000 ps] TC2: Directed write transactions ---

--- [5000 ns] TC3: Directed read transactions  ---

--- [9000 ns] TC4: Address NACK handling       ---

--- [10000 ns] TC5: Request while busy ignored  ---

--- [12000 ns] TC6: Reset abort and recovery    ---

-----------------------------------------------
=== PASS: 6 test cases, all 87 checks passed ===
-----------------------------------------------
```
> Timestamps are in **ps** (`timescale 1ns/1ps`). `[1390000]` = 1390 ns.

---

## 🚀 How to Run

### Vivado xsim

```bash
cd sim/xsim && make sim

# Open waveform GUI view:
make gui

# Clean up simulation generated files:
make clean
```

### ModelSim / Questa

```bash
cd sim/modelsim && make sim

# Open waveform GUI view:
make gui

# Clean up simulation generated files:
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

| #  | Test                       | Condition                                         | Expected                                                        | Result  |
|----|----------------------------|---------------------------------------------------|-----------------------------------------------------------------|---------|
| 1  | Reset & idle               | Assert `rst_n=0`, release                         | `scl=1`, `sda=1`, `busy=0`, `done=0`, `ack_error=0`            | ✅ Pass |
| 2  | Directed write × 3         | Send `0xA5`, `0x00`, `0xFF` to `SLAVE_ADDR`       | `slave_rx_data` matches; 18 SCL edges, 1 START, 1 STOP per transaction | ✅ Pass |
| 3  | Directed read × 3          | Read `0x3C`, `0x00`, `0xFF` from `SLAVE_ADDR`     | `master_rx_data` matches; 18 SCL edges, `slave_rx_valid` never pulses | ✅ Pass |
| 4  | Address NACK               | Send to wrong address `0x43`                      | `ack_error=1`; only 9 SCL edges; slave not activated            | ✅ Pass |
| 5  | Busy rejection             | Assert `start` mid-transaction with new payload   | Active transaction unchanged; rejected `start` ignored          | ✅ Pass |
| 6  | Reset abort & recovery     | Assert `rst_n=0` mid-transaction                  | Bus released immediately; clean restart accepted                | ✅ Pass |

Detailed verification intent is recorded in [docs/test_plan.md](docs/test_plan.md).

---

## ⚙️ SCL Frequency Reference

| `f_clk` (MHz) | `CLK_DIV` | `f_scl` (MHz) | I²C Mode            |
|--------------:|----------:|--------------:|---------------------|
|            50 |         2 |         12.50 | — (sim only)        |
|            50 |         4 |          6.25 | — (sim only, default) |
|            50 |        25 |          1.00 | Fast-mode Plus (Fm+)|
|            50 |        50 |          0.50 | Fast-mode (Fm)      |
|            50 |       250 |          0.10 | Standard-mode (Sm)  |
|           100 |        50 |          1.00 | Fast-mode Plus (Fm+)|
|           100 |       250 |          0.20 | — (between Sm/Fm)   |

> Select `CLK_DIV ≥ 2` to ensure the system-clocked target can sample each SCL edge reliably.
> For real hardware, choose `CLK_DIV` so `f_scl` matches the target device's rated speed
> (Standard-mode 100 kHz, Fast-mode 400 kHz, or Fast-mode Plus 1 MHz).

---

## ⚠️ Known Limitations

| # | Limitation                                                   | Suggested Extension                                    |
|---|--------------------------------------------------------------|--------------------------------------------------------|
| 1 | 1 controller and 1 integrated target only                    | Add address decoder + multiple target instances        |
| 2 | One byte per transaction; no burst or repeated START         | Add burst mode with repeated START support             |
| 3 | No multi-controller arbitration                              | Add SDA read-back arbitration in master FSM            |
| 4 | No clock stretching                                          | Read back SCL after releasing; wait for HIGH           |
| 5 | No 10-bit addressing or general-call support                 | Add 10-bit address frame and general-call decode       |
| 6 | Target edge detection requires SCL half-period ≥ 2 `clk` cycles | Enforce `CLK_DIV ≥ 2` via parameter assertion      |
| 7 | Ideal pull-ups; board-level rise time not modeled            | Add RC rise-time model or tri-state `inout` ports      |

---

## 📚 References

| # | Title | Source |
|---|-------|--------|
| [1] | **I²C Protocol — Lý Thuyết Giao Thức I²C** | [`docs/i2c_theory.md`](../../docs/i2c_theory.md) — Open-drain bus, START/STOP, address frame, ACK/NACK, FSM architecture |
| [2] | **I²C-bus specification and user manual Rev. 7.0** | [NXP UM10204](https://www.nxp.com/docs/en/user-guide/UM10204.pdf) |
| [3] | **Understanding the I²C Bus** | [Texas Instruments SLVA704](https://www.ti.com/lit/an/slva704/slva704.pdf?ts=1699596969514&ref_url=https%3A%2F%2Fwww.google.com%2F) |
| [4] | **Wikipedia — I²C** | [wikipedia.org](https://en.wikipedia.org/wiki/I%C2%B2C) |
| [5] | **Giao thức I2C — E-Lab** | [blog.deviot.vn](https://blog.deviot.vn/posts/lap-trinh-vi-dieu-khien/giao-thuc-i2c) |

---

*Module: `i2c_top.v` · Author: Long Hai · Protocol: I²C 7-bit half-duplex*
