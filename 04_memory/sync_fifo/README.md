# Sync FIFO - Single-Clock First-In-First-Out Buffer

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![Type](https://img.shields.io/badge/Type-Memory%20%7C%20FIFO-green.svg)
![Style](https://img.shields.io/badge/Clock-Synchronous-orange.svg)

A parameterized **single-clock synchronous FIFO** with registered read data,
`full` / `empty` flags, an occupancy `level` counter, and support for
simultaneous read/write cycles.

Verification uses a directed + random self-checking testbench with a reference
ring-buffer model.

---

## Specification

| Property | Value |
|----------|-------|
| Depth | `2^ADDR_WIDTH` entries (default: 16) |
| Data width | `DATA_WIDTH` bits (default: 8) |
| Clocking | Single clock (`clk`) |
| Reset | Active-low synchronous (`rst_n`) |
| Write guard | Writes are accepted only when not full, unless a valid read occurs in the same cycle |
| Read guard | Reads are accepted only when not empty |
| Output style | `dout` is registered |
| Occupancy | `level` reports `0..DEPTH` |

---

## Architecture

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 8 | Data width in bits |
| `ADDR_WIDTH` | 4 | Address width; FIFO depth = `2^ADDR_WIDTH` |

### Operation Qualification

| Signal | Logic | Description |
|--------|-------|-------------|
| `rd_fire` | `rd_en && !empty` | A read is committed only when data is available |
| `wr_fire` | `wr_en && (!full || rd_fire)` | A write is committed when space is available, or when a same-cycle read frees one entry |

### State Updates

| Operation | Pointer / Counter Behavior |
|-----------|----------------------------|
| Write only | Store `din`, increment `wr_ptr`, increment `level` |
| Read only | Drive `dout`, increment `rd_ptr`, decrement `level` |
| Read + write | Pop oldest data and push new data, pointers both advance, `level` unchanged |
| Full + read/write | Allowed; FIFO remains full after the cycle |
| Empty + read/write | Read is ignored, write is accepted; FIFO moves to level 1 |

### Top-Level Block Diagram

```text
             +----------------------------------+
             |             sync_fifo            |
             |                                  |
 clk   ----->| single-clock control             |
 rst_n ----->|                                  |
 wr_en ----->| write qualifier                  |----> full
 rd_en ----->| read qualifier                   |----> empty
 din   ----->| memory write port                |----> level
             |                                  |
             | registered read data             |----> dout
             +----------------------------------+
```

### Internal Architecture Diagram

```text
                    clk, rst_n
                       |
                       v
              +------------------+
 wr_en -----> | write/read       | <----- rd_en
 full  -----> | qualification    | <----- empty
              +----+--------+----+
                   |        |
             wr_fire        rd_fire
                   |        |
                   v        v
              +-------+  +-------+
              |wr_ptr |  |rd_ptr |
              +---+---+  +---+---+
                  |          |
                  v          v
              +------------------+
 din -------> | FIFO memory      | -----> dout register
              +------------------+
                       |
                       v
              +------------------+
              | level/full/empty |
              +------------------+
```

---

## Port List / Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | Input | 1 | Clock |
| `rst_n` | Input | 1 | Active-low synchronous reset |
| `wr_en` | Input | 1 | Write enable |
| `rd_en` | Input | 1 | Read enable |
| `din` | Input | `DATA_WIDTH` | Write data |
| `dout` | Output | `DATA_WIDTH` | Registered read data |
| `full` | Output | 1 | FIFO full flag |
| `empty` | Output | 1 | FIFO empty flag |
| `level` | Output | `ADDR_WIDTH+1` | Occupancy count from `0` to `DEPTH` |

---

## Simulation Results

Run simulation from either `sim/modelsim` or `sim/xsim` to view the waveform.

```text
=== sync_fifo Testbench (directed + random self-check) ===

--- TC1: Reset behavior ---
[26000] PASS: dout clears after reset
[26000] PASS: FIFO status after reset -- count=0 full=0 empty=1

--- TC2: Underflow guard ---
[46000] PASS: Read request while empty is ignored
[46000] PASS: Status matches reference model after cycle -- count=0 full=0 empty=1
...
[1666000] PASS: Status matches reference model after cycle -- count=0 full=0 empty=1
[1670000] PASS: Reference FIFO is empty at end of test
-----------------------------------------------
=== PASS: all 171 checks passed ===
```

---

## How to Run

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

## Test Cases / Coverage

| # | Test | Condition | Expected | Result |
|---|------|-----------|----------|--------|
| 1 | Reset behavior | Assert `rst_n=0` for multiple clocks | `empty=1`, `full=0`, `level=0`, `dout=0` | Pass |
| 2 | Underflow guard | Assert `rd_en` while empty | Read ignored; status unchanged | Pass |
| 3 | Fill to full | Write `DEPTH` entries | `full=1`, `level=DEPTH` | Pass |
| 4 | Overflow guard | Assert `wr_en` while full | Write ignored; data order preserved | Pass |
| 5 | Full-state read/write | Assert `wr_en` and `rd_en` while full | Oldest data pops, new data pushes, FIFO remains full | Pass |
| 6 | Drain to empty | Read all entries | FIFO order preserved, `empty=1` | Pass |
| 7 | Wrap-around | Mixed traffic across pointer wrap | Data order and level remain correct | Pass |
| 8 | Random stress | 80 random read/write request cycles | Reference model matches DUT | Pass |
| 9 | Final drain | Drain after random stress | FIFO ends empty with no mismatch | Pass |

---

## Known Limitations / Assumptions

| # | Description |
|---|-------------|
| 1 | `ADDR_WIDTH` is expected to be a positive integer; depth is power-of-2 only. |
| 2 | `dout` updates only on a valid read. Invalid reads leave the previous `dout` value unchanged. |
| 3 | No programmable almost-full or almost-empty thresholds are implemented. |
