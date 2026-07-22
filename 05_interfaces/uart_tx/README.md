# UART Transmitter — 8N1 Serial Interface

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![Protocol](https://img.shields.io/badge/Protocol-UART%208N1-green.svg)
![Style](https://img.shields.io/badge/Data-LSB--first-orange.svg)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20xsim-blueviolet.svg)

A parameterized, fully synthesizable UART transmitter implementing the **8N1** frame
format (1 start bit, 8 data bits LSB-first, 1 stop bit). The module generates its own
baud clock from the system clock using an integer divider — no external PLL or baud
clock required. A `tx_start` / `tx_busy` / `tx_done` handshake allows a host controller
to queue one byte at a time.

> 📖 For full UART protocol background, see [`docs/uart_theory.md`](../../docs/uart_theory.md)
> (idle state, frame structure, baud error tolerance, framing/overrun/parity errors).

---

## 📋 Specification

| Property | Value |
|---|---|
| Frame format | 8N1 — 8 data bits, no parity, 1 stop bit |
| Bit order | LSB (D0) first |
| Idle level | Logic HIGH |
| Start bit | Logic LOW — 1 bit period |
| Stop bit | Logic HIGH — 1 bit period |
| Reset style | Active-low synchronous |
| Baud generation | Internal integer divider, rounded to nearest |
| Request policy | `tx_start` accepted only while `tx_busy = 0` |
| Data capture | `data_in` latched at the cycle `tx_start` is accepted |
| Completion signal | `tx_done` pulses HIGH for **exactly one** clock cycle |

---

## 🏗️ Architecture

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `CLK_FREQ_HZ` | `50_000_000` | System clock frequency in Hz |
| `BAUD_RATE` | `115_200` | Target UART baud rate in bps |

The baud divisor is computed at elaboration time with round-to-nearest division:

```verilog
localparam integer CLKS_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;
```

### FSM State Machine

| State | Encoding | `tx` | `tx_busy` | Exit Condition |
|---|---|---|---|---|
| `IDLE` | `3'd0` | `1` | `0` | `tx_start` asserted |
| `START` | `3'd1` | `0` | `1` | `baud_count == CLKS_PER_BIT - 1` |
| `DATA` | `3'd2` | `data_latched[bit_index]` | `1` | `bit_index == 7` AND baud expires |
| `STOP` | `3'd3` | `1` | `1 → 0` | `baud_count == CLKS_PER_BIT - 1` |

### Top-Level Block Diagram

```text
                  +────────────────────+
     clk  ───────►│                    │
    rst_n ───────►│    uart_tx         ├──────► tx
 tx_start ───────►│                    ├──────► tx_busy
  data_in ───────►│  [CLK_FREQ_HZ]     ├──────► tx_done
          [7:0]   │  [BAUD_RATE]       │
                  +────────────────────+
```

---

## 🔌 Port List / Interface

| Signal | Dir | Width | Active | Description |
|---|---|---|---|---|
| `clk` | In | 1 | Rising edge | System clock |
| `rst_n` | In | 1 | LOW | Active-low synchronous reset |
| `tx_start` | In | 1 | HIGH | One-cycle request to transmit `data_in` |
| `data_in` | In | 8 | — | Byte to transmit; captured on acceptance |
| `tx` | Out | 1 | — | UART serial output; HIGH while idle |
| `tx_busy` | Out | 1 | HIGH | Asserted from acceptance through stop bit |
| `tx_done` | Out | 1 | HIGH | Single-clock pulse when stop bit completes |

**Signal timing notes:**
- `tx_start` must be held HIGH for exactly **one** `clk` rising edge.
- `tx_start` while `tx_busy=1` is silently ignored (no side effects).
- `data_in` may change freely after the cycle where `tx_start` is accepted.
- `tx_done` is **one clock wide**; capture it with a flag register if needed.
- `tx_busy` goes LOW on the **same cycle** `tx_done` goes HIGH.

### Frame Waveform

```text
clk       ___|‾|___|‾|___...                              (system clock)

tx_start  ___|‾|____________________________________________  (one-cycle pulse)

tx        ‾‾‾|_START_| D0 | D1 |D2|D3|D4|D5|D6|D7|‾STOP‾|‾‾‾  (serial out)
               ← N →  ←N→  ←N→ ...                 ← N →
               (N = CLKS_PER_BIT clock cycles per bit)

tx_busy   ___|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|____

tx_done   ____________________________________________|‾|__  (1-clock pulse)
```

---

## 🖥️ Simulation Results

Run simulation from either `sim/modelsim` or `sim/xsim` to view the waveform.

```text
=== uart_tx Testbench (directed self-check) ===

--- TC1: Reset and idle behavior ---
[26000] PASS: Reset restores idle outputs
[66000] PASS: Transmitter holds idle line high

--- TC2: Alternating-bit patterns ---
...
[876000] PASS: Frame 0x43 completed correctly
...
[1696000] PASS: Frame 0xA3 completed correctly

--- TC3: Boundary data patterns ---
...
[2516000] PASS: Frame 0x00 completed correctly
...
[3336000] PASS: Frame 0xFF completed correctly

--- TC4: Input changes and busy request are ignored ---
[3606000] PASS: Request while busy does not terminate active frame
[4156000] PASS: Active frame remains the originally latched byte

--- TC5: FSM recovery after TC4 busy-ignore ---
[4976000] PASS: FSM recovered cleanly: byte rejected in TC4 now transmits correctly
-----------------------------------------------
=== PASS: 5 TCs, all 81 checks passed ===
```

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

| # | Test | Condition | Expected | Result |
|---|---|---|---|---|
| 1 | Reset & idle | Assert `rst_n=0`, release | `tx=1`, `tx_busy=0`, `tx_done=0` | ✅ Pass |
| 2 | Alternating-bit patterns | `0x55`, `0xA3` | All 8 bits match, frame completes | ✅ Pass |
| 3 | Boundary data | `0x00`, `0xFF` | All zeros / all ones framed correctly | ✅ Pass |
| 4 | Busy-ignore + data latch | `tx_start` mid-frame with new `data_in` | Active frame unchanged; request dropped | ✅ Pass |
| 5 | FSM recovery | Transmit `0xF0` (rejected in TC4) after `tx_done` | FSM returns cleanly to IDLE, new frame succeeds | ✅ Pass |

---

## ⚙️ Baud Rate Reference

| `CLK_FREQ_HZ` | `BAUD_RATE` | `CLKS_PER_BIT` | Error |
|---|---|---|---|
| 50 000 000 | 115 200 | 434 | +0.006 % ✅ |
| 50 000 000 | 9 600 | 5 208 | +0.006 % ✅ |
| 100 000 000 | 115 200 | 868 | +0.006 % ✅ |
| 12 000 000 | 115 200 | 104 | +0.160 % ✅ |
| 8 000 000 | 1 000 000 | 8 | 0.000 % ✅ |

> Baud error below **±2 %** is universally accepted; above ±5 % causes framing errors.

---

## ⚠️ Known Limitations

| # | Limitation | Workaround |
|---|---|---|
| 1 | Fixed at **8N1** — no parity, no 7-bit or 2-stop variants | Parameterize parity and stop-bit count |
| 2 | **No FIFO** — `tx_start` while `tx_busy=1` is silently dropped | Add a shallow FIFO upstream |
| 3 | Integer baud divider introduces small error for some clock/baud pairs | See baud table above |
| 4 | `tx_start` must be synchronous to `clk` | Add a 2-FF synchronizer for async sources |
| 5 | `baud_count` declared as `integer` (32-bit) — wastes flops | Replace with `[$clog2(CLKS_PER_BIT)-1:0]` |

---

## 📚 References

| # | Title | Source |
|---|---|---|
| [1] | **UART Protocol — Lý Thuyết Giao Thức UART** | [`docs/uart_vi.md`](docs/uart_vi.md) — Idle state, 8N1 frame structure, baud rate, parity, framing/overrun errors, flow control (RTS/CTS, XON/XOFF) |
| [2] | **Basics of UART Communication** | [circuitbasics.com](https://www.circuitbasics.com/basics-uart-communication/) |
| [3] | **Wikipedia — UART** | [wikipedia.org](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver-transmitter) |

---

*Module: `uart_tx.v` · Author: Long Hai · Protocol: UART 8N1*
