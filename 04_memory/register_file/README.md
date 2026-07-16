# Register File - 2R1W CPU Register Storage

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![Type](https://img.shields.io/badge/Type-Memory-green.svg)
![Style](https://img.shields.io/badge/Ports-2R1W-orange.svg)

A parameterized **2-read / 1-write register file** for small CPU/datapath designs.
The write port is synchronous to `clk`; both read ports are combinational for
low-latency operand fetch. When `ZERO_REG_ENABLE=1`, register address zero is
hardwired to `0`, matching common RISC-style register file behavior.

Verification uses a directed self-checking testbench with a reference array model.

---

## Specification

| Property | Value |
|----------|-------|
| Register count | `2^ADDR_WIDTH` entries (default: 32) |
| Data width | `DATA_WIDTH` bits (default: 32) |
| Write ports | 1 synchronous write port |
| Read ports | 2 asynchronous/combinational read ports |
| Reset | Active-low synchronous (`rst_n`) |
| Zero register | Optional via `ZERO_REG_ENABLE` |
| Write guard | Writes to register zero are ignored when `ZERO_REG_ENABLE=1` |

---

## Architecture

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 32 | Data width in bits |
| `ADDR_WIDTH` | 5 | Address width; number of registers = `2^ADDR_WIDTH` |
| `ZERO_REG_ENABLE` | 1 | Hardwire register address zero to `0` when enabled |

### Behavior

| Operation | Timing | Description |
|-----------|--------|-------------|
| Reset | `posedge clk` while `rst_n=0` | Clears all storage entries |
| Write | `posedge clk` when `we=1` | Stores `wdata` into `regs[waddr]` |
| Read port 1 | Combinational | `rdata1` follows `regs[raddr1]` |
| Read port 2 | Combinational | `rdata2` follows `regs[raddr2]` |
| Zero register | Combinational + write guard | Reads as zero; writes are ignored |

### Top-Level Block Diagram

```text
             +----------------------------------+
             |          register_file           |
             |                                  |
 clk   ----->| synchronous write/reset          |
 rst_n ----->|                                  |
 we    ----->|                                  |
 waddr ----->|                                  |
 wdata ----->|                                  |
             |                                  |
 raddr1 ---->| combinational read port 1        |----> rdata1
 raddr2 ---->| combinational read port 2        |----> rdata2
             |                                  |
             +----------------------------------+
```

### Internal Architecture Diagram

```text
                         clk, rst_n
                            |
                            v
                    +----------------+
 waddr ------------>| write decoder  |
 wdata ------------>| + write guard  |
 we  -------------->|                |
                    +--------+-------+
                             |
                             v
                    +----------------+
                    | register array |
                    | 2^ADDR_WIDTH x |
                    | DATA_WIDTH     |
                    +---+--------+---+
                        |        |
        raddr1 ---------+        +--------- raddr2
                        |        |
                        v        v
                    +------+  +------+
                    | mux1 |  | mux2 |
                    +--+---+  +---+--+
                       |          |
                       v          v
                    rdata1     rdata2
```

---

## Port List / Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | Input | 1 | Clock |
| `rst_n` | Input | 1 | Active-low synchronous reset |
| `we` | Input | 1 | Write enable |
| `waddr` | Input | `ADDR_WIDTH` | Write register address |
| `wdata` | Input | `DATA_WIDTH` | Write data |
| `raddr1` | Input | `ADDR_WIDTH` | Read port 1 address |
| `raddr2` | Input | `ADDR_WIDTH` | Read port 2 address |
| `rdata1` | Output | `DATA_WIDTH` | Read port 1 data |
| `rdata2` | Output | `DATA_WIDTH` | Read port 2 data |

---

## Simulation Results

Run simulation from either `sim/modelsim` or `sim/xsim` to view the waveform.

```text
=== register_file Testbench (directed self-check) ===

--- TC1: Registers read as zero after reset ---
[27000] PASS: Registers read as zero after reset -- raddr1=0 rdata1=0x00, raddr2=1 rdata2=0x00
[28000] PASS: Registers read as zero after reset -- raddr1=2 rdata1=0x00, raddr2=3 rdata2=0x00
[29000] PASS: Registers read as zero after reset -- raddr1=4 rdata1=0x00, raddr2=5 rdata2=0x00
[30000] PASS: Registers read as zero after reset -- raddr1=6 rdata1=0x00, raddr2=7 rdata2=0x00

--- TC2: Write/read all writable registers ---
[47000] PASS: Written register matches model and x0 remains zero -- raddr1=1 rdata1=0x21, raddr2=0 rdata2=0x00
[57000] PASS: Written register matches model and x0 remains zero -- raddr1=2 rdata1=0x22, raddr2=0 rdata2=0x00
[67000] PASS: Written register matches model and x0 remains zero -- raddr1=3 rdata1=0x23, raddr2=0 rdata2=0x00
[77000] PASS: Written register matches model and x0 remains zero -- raddr1=4 rdata1=0x24, raddr2=0 rdata2=0x00
[87000] PASS: Written register matches model and x0 remains zero -- raddr1=5 rdata1=0x25, raddr2=0 rdata2=0x00
[97000] PASS: Written register matches model and x0 remains zero -- raddr1=6 rdata1=0x26, raddr2=0 rdata2=0x00
[107000] PASS: Written register matches model and x0 remains zero -- raddr1=7 rdata1=0x27, raddr2=0 rdata2=0x00

--- TC3: Dual-read from independent addresses ---
[108000] PASS: Dual read ports return independent registers -- raddr1=2 rdata1=0x22, raddr2=5 rdata2=0x25
[109000] PASS: Dual read ports support arbitrary address order -- raddr1=6 rdata1=0x26, raddr2=1 rdata2=0x21

--- TC4: Overwrite existing register ---
[117000] PASS: Overwrite updates selected register only -- raddr1=3 rdata1=0xa5, raddr2=4 rdata2=0x24

--- TC5: Write-disabled cycle must not update storage ---
[127000] PASS: Write-disabled cycle is ignored -- raddr1=4 rdata1=0x24, raddr2=3 rdata2=0xa5

--- TC6: Hardwired zero register ignores writes ---
[137000] PASS: Zero register ignores writes -- raddr1=0 rdata1=0x00, raddr2=3 rdata2=0xa5

--- TC7: Back-to-back writes ---
[157000] PASS: Back-to-back writes commit in order -- raddr1=6 rdata1=0x66, raddr2=7 rdata2=0x77

--- TC8: Reset after activity clears state ---
[187000] PASS: Registers read as zero after reset -- raddr1=0 rdata1=0x00, raddr2=1 rdata2=0x00
[188000] PASS: Registers read as zero after reset -- raddr1=2 rdata1=0x00, raddr2=3 rdata2=0x00
[189000] PASS: Registers read as zero after reset -- raddr1=4 rdata1=0x00, raddr2=5 rdata2=0x00
[190000] PASS: Registers read as zero after reset -- raddr1=6 rdata1=0x00, raddr2=7 rdata2=0x00
-----------------------------------------------
=== PASS: all 21 checks passed ===
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
| 1 | Reset behavior | Assert `rst_n=0` for multiple clock edges | All registers read as zero | Pass |
| 2 | Write/read sweep | Write every writable register | Read data matches reference model | Pass |
| 3 | Dual read | Read two independent addresses in the same cycle | Both ports return correct values | Pass |
| 4 | Overwrite | Write a new value to an existing register | Only selected register changes | Pass |
| 5 | Write disable | Drive write address/data with `we=0` | Storage remains unchanged | Pass |
| 6 | Zero register | Write nonzero data to address zero | Address zero still reads as zero | Pass |
| 7 | Back-to-back writes | Consecutive writes to different addresses | Both writes commit in order | Pass |
| 8 | Reset after activity | Reset after nonzero writes | All registers clear again | Pass |

---

## Known Limitations / Assumptions

| # | Description |
|---|-------------|
| 1 | Read ports are combinational, so downstream logic should account for address-to-data path delay. |
| 2 | There is no explicit same-cycle bypass path. A write updates storage on `posedge clk`; reads reflect the array contents after the write has committed. |
| 3 | `ADDR_WIDTH` is expected to be a positive integer; register count is power-of-2 only. |
