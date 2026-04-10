# Carry Lookahead Adder

A parameterizable combinational carry-lookahead adder. It adds two WIDTH-bit operands and a carry-in to produce WIDTH-bit sum and carry-out. Verification uses directed exhaustive self-checking testbench.

## 📋 Specification / Architecture

| Parameter | Default | Description |
|-----------|---------|-------------|
| WIDTH     | 4       | Data bus width of inputs `a`, `b`, and output `sum` |

### Architecture Description

**Problems with Ripple Carry Adder (RCA):** carry must "ripple" one bit at a time from LSB to MSB — the next bit must wait for the previous bit to finish calculating → slow when WIDTH is large.

**Solution of CLA:** Calculate carry first, in parallel, based on 2 intermediate signals:

| Signal | Formula | Meaning |
|----------|-----------|---------|
| **Propagate** `p[i]` | `a[i] ^ b[i]` | This bit will *propagate* carry in if there is one |
| **Generate** `g[i]` | `a[i] & b[i]` | This bit will *generate* carry out even if carry in is 0 |

From these two signals, the carry of each bit is determined directly:

```
c[i+1] = g[i] | (p[i] & c[i])
```

> The carry bit `c[i+1]` is generated (`g[i]`) **or** is carried forward (`p[i]`) from the previous carry.

Finally, the sum of each bit: `sum[i] = p[i] ^ c[i]`

### Architecture Diagram

```text
                  carry_lookahead_adder #(WIDTH)

           a[3] b[3]       a[2] b[2]       a[1] b[1]       a[0] b[0]
             | |             | |             | |             | |
           + v v +         + v v +         + v v +         + v v +
           | P/G |         | P/G |         | P/G |         | P/G |
           |  3  |         |  2  |         |  1  |         |  0  |
           +-----+         +-----+         +-----+         +-----+
              | (p3,g3)       | (p2,g2)       | (p1,g1)       | (p0,g0)
              |               |               |               |
              v               v               v               v
    +-------------------------------------------------------------------+
    |                   Lookahead Carry Unit (LCU)                      |
<---+ cout (c[4])                                                   cin +<---
    |                                                                   |
    +-------------------------------------------------------------------+
             |               |               |               |
             | c[3]          | c[2]          | c[1]          | c[0]
             v               v               v               v
           +---+           +---+           +---+           +---+
           |SUM|           |SUM|           |SUM|           |SUM|
           | 3 |           | 2 |           | 1 |           | 0 |
           +---+           +---+           +---+           +---+
             |               |               |               |
             v               v               v               v
           sum[3]          sum[2]          sum[1]          sum[0]

    * Note: SUM calculation implicitly uses P[i] (where sum[i] = p[i] XOR c[i])

```

## 🔌 Port List / Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| a      | Input     | WIDTH | Operand A |
| b      | Input     | WIDTH | Operand B |
| cin    | Input     | 1     | Carry input |
| sum    | Output    | WIDTH | Sum output |
| cout   | Output    | 1     | Carry output |

## 🖥️ Simulation Results

Run simulation from either `sim/modelsim` or `sim/xsim` to view waveform.
![Waveform](image_results/xsim_wave_carry_lookahead_adder.png)

```text
=== CARRY LOOKAHEAD ADDER Testbench ===
   time  |  a   b    cin | cout  sum | exp_cout exp_sum | result
---------------------------------------------------------------
   10000 | 0000 0000  0  | 0   0000 | 0        0000   | PASS
   20000 | 0000 0000  1  | 0   0001 | 0        0001   | PASS
   30000 | 0000 0001  0  | 0   0001 | 0        0001   | PASS
   ...
   ...
   ...
 5110000 | 1111 1111  0  | 1   1110 | 1        1110   | PASS
 5120000 | 1111 1111  1  | 1   1111 | 1        1111   | PASS
=== PASS: all 512 test vectors matched ===
```

## 🚀 How to Run

### Vivado xsim
```bash
cd sim/xsim && make sim
# Or open the GUI:
make gui
# Clean simulation files:
make clean
```

### ModelSim / Questa
```bash
cd sim/modelsim && make sim
# Or open the GUI:
make gui
# Clean simulation files:
make clean
```

### Portable (no make)
```bash
# Vivado xsim
cd sim/xsim && xtclsh simulate.tcl

# ModelSim / Questa
cd sim/modelsim && vsim -c -do simulate.do
```

## ✅ Test Cases / Coverage

| Test | Input / Condition | Expected | Result |
|------|-------------------|----------|--------|
| exhaustive_width4 | All `{a,b,cin}` combinations for WIDTH=4 (512 vectors) | `{cout,sum} = a + b + cin` | Pass |
| corner_all_zero   | `a=0`, `b=0`, `cin=0` | `sum=0`, `cout=0` | Pass |
| corner_all_one    | `a=1111`, `b=1111`, `cin=1` | `sum=1111`, `cout=1` | Pass |

## 🐛 Bugs Found

| Bug ID | Description | Fixed |
|--------|-------------|-------|
| None   | No bugs found in directed test | N/A |
