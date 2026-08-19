# SPI Top — Integrated Master & Slave

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![Protocol](https://img.shields.io/badge/Protocol-SPI-green.svg)
![Modes](https://img.shields.io/badge/Modes-0%20to%203-orange.svg)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20xsim-blueviolet.svg)

A parameterized, fully synthesizable SPI subsystem supporting all four standard modes (**Mode 0–3**).
`spi_top` integrates `spi_master` and `spi_slave` on a shared four-wire bus — each transaction
simultaneously exchanges one word in both directions (**full-duplex**). The wrapper is purely
structural: no hidden FIFOs, buffering, or arbitration inside.

> 📖 For full SPI protocol background, see [`docs/spi_theory.md`](../../docs/spi_theory.md)
> (CPOL/CPHA modes, SCLK timing, MSB-first shift, CS polarity, multi-slave).

---

## 📋 Specification

| Property            | Value                                               |
|---------------------|-----------------------------------------------------|
| Protocol            | SPI — Serial Peripheral Interface                   |
| Modes               | Mode 0, 1, 2, 3 (CPOL × CPHA)                      |
| Duplex              | Full duplex; both endpoints exchange one word/cycle |
| Word width          | Parameterized `DATA_WIDTH` (default 8 bits)         |
| Bit order           | MSB-first                                           |
| CS polarity         | Active-low (`cs_n`)                                 |
| Master clock source | Internal divider — `f_sclk = f_clk / (2×CLK_DIV)` |
| Slave clock domain  | System-clocked edge detector on SCLK and CS         |
| Request policy      | `start` accepted only while `master_busy = 0`       |
| Completion signal   | Independent `master_done` and `slave_done` pulses   |
| Reset style         | Active-low synchronous, shared by both endpoints    |

---

## 🏗️ Architecture

### Parameters

| Parameter    | Default | Description                              |
|--------------|--------:|------------------------------------------|
| `DATA_WIDTH` |     `8` | Bits exchanged per direction per transfer |
| `CLK_DIV`    |     `3` | System clocks per SCLK half-period        |
| `CPOL`       |     `0` | SCLK idle polarity                        |
| `CPHA`       |     `0` | Launch / sample phase select              |

> **Note:** `CLK_DIV < 2` is clamped to `2` so the system-clocked slave can reliably detect each SCLK edge.
>
> `f_sclk = f_clk / (2 × max(CLK_DIV, 2))`

### Dependencies

`spi_top.v` instantiates these sibling modules:

```text
05_interfaces/spi_top/
├── spi_master.v      ← RTL: SPI master, owns SCLK / MOSI / CS_n
├── spi_slave.v       ← RTL: SPI slave,  edge-detects SCLK / CS_n
├── spi_top.v         ← Structural wrapper connecting the two
├── spi_top_tb.v      ← Integrated TB (4 DUTs × 5 TCs)
├── docs/
│   └── waveform.png
└── sim/
    ├── modelsim/
    └── xsim/
```

### Top-Level Block Diagram

```text
 master_tx_data                        slave_tx_data
        │                                    │
        ▼                                    ▼
 ┌─────────────┐       MOSI          ┌─────────────┐
 │  spi_master │────────────────────>│  spi_slave  │
 │             │<────────────────────│             │
 └─────────────┘       MISO          └─────────────┘
        │  │                                 │
        │  └────────── SCLK, CS_n ───────────┘
        ▼                                    ▼
 master_rx_data                      slave_rx_data
```

The internal `sclk`, `mosi`, `miso`, and `cs_n` wires are exposed as top-level output ports
for waveform inspection and hardware probing without modifying internal RTL.

### SPI Modes

| Mode | `CPOL` | `CPHA` | SCLK idle | Sample edge  | Shift edge   |
|-----:|-------:|-------:|-----------|--------------|--------------|
|    0 |      0 |      0 | LOW       | Leading (↑)  | Trailing (↓) |
|    1 |      0 |      1 | LOW       | Trailing (↓) | Leading (↑)  |
|    2 |      1 |      0 | HIGH      | Leading (↓)  | Trailing (↑) |
|    3 |      1 |      1 | HIGH      | Trailing (↑) | Leading (↓)  |

> **Sample edge** — the SCLK edge on which both sides **capture data** (RX): Master reads MISO, Slave reads MOSI.
>
> **Shift edge** — the opposite SCLK edge, on which both sides **update data** (TX): Master updates MOSI, Slave updates MISO. The new bit must be stable on the wire *before* the Sample edge arrives.
>
> **"Leading"** = the first edge of each SCLK cycle (idle → active); it is **not** always a rising edge.
> When CPOL=0: Leading = ↑. When CPOL=1: Leading = ↓.
>
> **RTL implementation note:** The master detects the Leading edge when `sclk == SCLK_IDLE` (about to *generate* the edge).
> The slave detects it when `sclk != SCLK_IDLE` (has just *seen* the edge, one system cycle later).
> This is why `CLK_DIV ≥ 2` is mandatory — the slave needs at least one system cycle to detect an edge before the next one occurs.

Both endpoints receive identical `CPOL`/`CPHA` — mode mismatch is structurally impossible.


---

## 🔌 Port List / Interface

| Signal           | Dir    | Width        | Active | Description                              |
|------------------|--------|-------------:|--------|------------------------------------------|
| `clk`            | Input  |            1 | ↑      | Shared system clock                      |
| `rst_n`          | Input  |            1 | LOW    | Active-low synchronous reset             |
| `start`          | Input  |            1 | HIGH   | One-cycle request to begin a transfer    |
| `master_tx_data` | Input  | `DATA_WIDTH` | —      | Word master sends on MOSI                |
| `slave_tx_data`  | Input  | `DATA_WIDTH` | —      | Word slave sends on MISO                 |
| `master_rx_data` | Output | `DATA_WIDTH` | —      | Word master received from MISO           |
| `slave_rx_data`  | Output | `DATA_WIDTH` | —      | Word slave received from MOSI            |
| `master_busy`    | Output |            1 | HIGH   | Master transaction in progress           |
| `master_done`    | Output |            1 | HIGH   | One-clock pulse: master completed        |
| `slave_busy`     | Output |            1 | HIGH   | Slave currently selected                 |
| `slave_done`     | Output |            1 | HIGH   | One-clock pulse: slave committed rx_data |
| `sclk`           | Output |            1 | —      | Internal SPI clock (observable)          |
| `mosi`           | Output |            1 | —      | Master → Slave data (observable)         |
| `miso`           | Output |            1 | —      | Slave → Master data (observable)         |
| `cs_n`           | Output |            1 | LOW    | Chip select active-low (observable)      |

**Signal timing notes:**
- `start` must be asserted for exactly **one** `clk` rising edge while `master_busy = 0`.
- `start` while `master_busy = 1` is silently ignored — no effect on the active transfer.
- Both tx words must be stable at the cycle `start` is accepted; they may change freely afterward.
- `master_done` and `slave_done` are each **one clock wide**; capture with a flag register if needed.
- `slave_done` arrives one or more clocks after `master_done` (slave detects CS-rise one cycle late).

---

## 🔄 Transaction Flow

```text
       start __|‾|__________________________________________
       cs_n  ‾‾‾|____________________________________|‾‾‾‾‾
       sclk      |‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|
       mosi       D7  D6  D5  D4  D3  D2  D1  D0
       miso       S7  S6  S5  S4  S3  S2  S1  S0
  master_done __________________________________________________|‾|__
   slave_done ___________________________________________________|‾|__
```

1. Assert `start` for 1 cycle while `master_busy == 0`.
2. Master latches tx word, drives `cs_n` LOW, begins generating SCLK.
3. Slave detects CS assertion one system clock later, latches its tx word.
4. Both words shift **MSB-first** simultaneously over the same SCLK edges.
5. Last bit completes → master releases CS → `master_done` pulses.
6. Slave detects CS-rise → commits `slave_rx_data` → `slave_done` pulses.

---

## 🖥️ Simulation Results

Run from either `sim/modelsim` or `sim/xsim` to validate the design.

```text
=== spi_top Testbench (master/slave integration) ===

--- TC1: Reset and idle polarity ---
[36000] PASS: Reset restores all integrated SPI modes to idle

--- TC2: Full-duplex integration in all SPI modes ---
[55000] >> run_transaction: mode=0  master_tx=0xa5  slave_tx=0x3c
[66000] PASS: Top accepts request and asserts master bus controls
[76000] PASS: Integrated slave detects active chip select
[576000] PASS: Mode 0 master receives slave payload
[576000] PASS: Integrated slave receives the master payload
[576000] PASS: Integrated bus generates exactly two SCLK edges per bit
[576000] PASS: Master generates one completion event
[576000] PASS: Slave generates one completion event
[576000] PASS: Master and slave done pulses are one clock wide
[576000] PASS: Both endpoints return to idle after transaction
[576000] PASS: Integrated SCLK returns to configured CPOL level
         (identical 10-check block for mode=1, 2, 3 — timestamps advance ~520 µs per mode)

--- TC3: Boundary payloads ---
[2136000] >> run_transaction: mode=0  master_tx=0x00  slave_tx=0xff
[2146000] PASS: Top accepts request and asserts master bus controls
[2156000] PASS: Integrated slave detects active chip select
[2656000] PASS: All-one slave word reaches master        (+ 7 further checks)
[2656000] >> run_transaction: mode=3  master_tx=0xff  slave_tx=0x00
[2666000] PASS: Top accepts request and asserts master bus controls
[2676000] PASS: Integrated slave detects active chip select
[3176000] PASS: All-zero slave word reaches master       (+ 7 further checks)

--- TC4: Request while master is busy ---
[3696000] PASS: Busy rejection preserves original master payload
[3696000] PASS: Busy rejection preserves latched slave payload
[3696000] PASS: Busy request does not create an extra transaction

--- TC5: Shared reset abort and recovery ---
[3776000] PASS: Shared reset aborts both endpoints and restores CPOL
[3795000] >> run_transaction: mode=2  master_tx=0x69  slave_tx=0x96
[3806000] PASS: Top accepts request and asserts master bus controls
[3816000] PASS: Integrated slave detects active chip select
[4316000] PASS: Integrated pair recovers after reset abort  (+ 7 further checks)
-----------------------------------------------
=== PASS: all 75 checks passed ===
```
> Timestamps are in **ps** (`timescale 1ns/1ps`). `[576000]` = 576 ns.

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

| # | Test                   | Condition                                       | Expected                                              | Result   |
|---|------------------------|-------------------------------------------------|-------------------------------------------------------|----------|
| 1 | Reset & idle           | Assert `rst_n=0`, release                       | `cs_n=1`, `busy=0`, `done=0`, SCLK at CPOL idle      | ✅ Pass  |
| 2 | Full-duplex exchange   | Send `0xA5`↔`0x3C` in Mode 0, 1, 2, 3          | Each endpoint receives the other's word; 16 SCLKs     | ✅ Pass  |
| 3 | Boundary payloads      | `0x00`↔`0xFF` in all 4 modes                    | All zeros / all ones framed correctly both directions | ✅ Pass  |
| 4 | Busy rejection         | Assert `start` mid-transfer with new data       | Active transfer unchanged; rejected `start` ignored   | ✅ Pass  |
| 5 | Reset during transfer  | Assert `rst_n=0` mid-exchange                   | Both FSMs abort; CS rises; clean restart accepted     | ✅ Pass  |

Detailed verification intent is recorded in [docs/test_plan.md](docs/test_plan.md).

---

## ⚙️ SCLK Frequency Reference

| `f_clk` (MHz) | `CLK_DIV` | `f_sclk` (MHz) | Notes                      |
|--------------:|----------:|---------------:|----------------------------|
|            50 |         2 |          12.50 | Minimum safe value         |
|            50 |         3 |           8.33 | Default                    |
|            50 |         8 |           3.13 | Conservative / breadboard  |
|           100 |         4 |          12.50 |                            |
|           100 |         2 |          25.00 | Minimum safe value         |

> Select `CLK_DIV ≥ 2` to ensure the system-clocked slave can sample each SCLK edge reliably.

---

## ⚠️ Known Limitations

| # | Limitation                                      | Suggested Extension                      |
|---|------------------------------------------------|------------------------------------------|
| 1 | 1 master ↔ 1 slave (internal only)              | Add multi-slave CS decode + indexed CS   |
| 2 | Slave uses system-clock domain (no CDC)         | Add 2-FF synchronizer for external SPI   |
| 3 | 1 word per request, no burst                    | Add burst mode + continuous CS support   |
| 4 | MSB-first only                                  | Add `LSB_FIRST` parameter                |
| 5 | No FIFOs                                        | Add buffered ready/valid interfaces      |
| 6 | CPOL/CPHA static (compile-time parameters)      | Add per-transaction mode configuration   |

---

## 📚 References

| # | Title | Source |
|---|-------|--------|
| [1] | **SPI Protocol — Lý Thuyết Giao Thức SPI** | [`docs/spi_theory.md`](../docs/spi_theory.md) — CPOL/CPHA modes, SCLK timing, CS polarity, MSB-first shift, multi-slave |
| [2] | **SPI — Wikipedia** | [wikipedia.org](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface) |
| [3] | **SPI Interface Guide** | [analog.com — AN-877](https://www.analog.com/media/en/analog-dialogue/volume-44/number-3/articles/introduction-to-spi-interface.pdf) |

---

*Module: `spi_top.v` · Author: Long Hai · Protocol: SPI Modes 0–3 full duplex*
