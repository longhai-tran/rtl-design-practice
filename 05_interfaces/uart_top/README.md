# UART Top — Full-Duplex 8N1 Interface

![Language](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Status](https://img.shields.io/badge/Status-Verified-success.svg)
![Protocol](https://img.shields.io/badge/Protocol-UART%208N1-green.svg)
![Mode](https://img.shields.io/badge/Mode-Full--Duplex-orange.svg)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20xsim-blueviolet.svg)

A parameterized, fully synthesizable full-duplex UART wrapper implementing the **8N1** frame format.
`uart_top` integrates the repository's `uart_tx` and `uart_rx` blocks into a single top-level module
whose transmit and receive paths operate **independently and simultaneously**. The wrapper is intentionally
structural — it adds no buffering, arbitration, or hidden state around either child module, so the timing
and handshake contracts remain identical to the verified standalone TX and RX implementations.

> 📖 For full UART protocol background, see [`docs/uart_theory.md`](../../docs/uart_theory.md)
> (idle state, 8N1 frame structure, baud rate tolerance, framing/overrun/parity errors).

---

## 📋 Specification

| Property | Value |
|---|---|
| Frame format | 8N1 — 8 data bits, no parity, 1 stop bit |
| Duplex mode | Full duplex; TX and RX operate simultaneously and independently |
| Bit order | LSB (D0) first |
| Idle level | Logic HIGH |
| Start bit | Logic LOW — 1 bit period |
| Stop bit | Logic HIGH — 1 bit period |
| Reset style | Active-low synchronous, shared by TX and RX |
| Baud generation | Independent rounded integer divider in each child block |
| TX handshake | `tx_start` / `tx_busy` / one-clock `tx_done` |
| RX handshake | `rx_busy` / one-clock `rx_done_valid` |
| RX synchronization | Two flip-flop metastability chain inside `uart_rx` |
| Error reporting | One-clock `framing_error` pulse for a sampled LOW stop bit |

---

## 🏗️ Architecture

### Parameters

| Parameter | Default | Description |
|---|---:|---|
| `CLK_FREQ_HZ` | `50_000_000` | System clock frequency in Hz |
| `BAUD_RATE` | `115_200` | Target UART baud rate in bps |

Both child blocks receive the same parameters. The baud divisor is computed at elaboration time
with round-to-nearest division:

```verilog
localparam integer CLKS_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;
```

Use a clock/baud pair that gives **at least 8 system clocks per UART bit**. The actual baud error
should remain within the tolerance of the remote UART endpoint (typically ±2 %).

### Dependencies

`uart_top.v` instantiates these sibling modules:

```text
05_interfaces/
├── uart_tx/uart_tx.v
├── uart_rx/uart_rx.v
└── uart_top/uart_top.v
```

Compile the child RTL before or together with `uart_top.v`. The supplied ModelSim/Questa and
Vivado xsim runners use an explicit source list so dependency resolution does not depend on
simulator search behavior.

### Top-Level Block Diagram

```text
                          +--------------------------+
       clk -------------->|                          |
     rst_n -------------->|         uart_top         |
                          |                          |
  tx_start -------------->|  +---------+             |----> tx
tx_data[7:0] ------------>|  | uart_tx |             |----> tx_busy
                          |  +---------+             |----> tx_done
                          |                          |
        rx -------------->|  +---------+             |----> rx_data[7:0]
                          |  | uart_rx |             |----> rx_busy
                          |  +---------+             |----> rx_done_valid
                          |                          |----> framing_error
                          +--------------------------+
```

---

## 🔌 Port List / Interface

| Signal | Dir | Width | Active | Description |
|---|---|---:|---|---|
| `clk` | In | 1 | Rising edge | System clock |
| `rst_n` | In | 1 | LOW | Active-low synchronous reset |
| `tx_start` | In | 1 | HIGH | One-cycle request to transmit `tx_data` |
| `tx_data` | In | 8 | — | Byte to transmit; captured on acceptance |
| `tx` | Out | 1 | — | UART serial output; HIGH while idle |
| `tx_busy` | Out | 1 | HIGH | Asserted from acceptance through stop bit |
| `tx_done` | Out | 1 | HIGH | Single-clock pulse when stop bit completes |
| `rx` | In | 1 | — | Asynchronous UART serial input; HIGH while idle |
| `rx_data` | Out | 8 | — | Last correctly received byte; persistent until next valid frame |
| `rx_busy` | Out | 1 | HIGH | Asserted while start/data/stop reception is active |
| `rx_done_valid` | Out | 1 | HIGH | Single-clock pulse when `rx_data` is updated |
| `framing_error` | Out | 1 | HIGH | Single-clock pulse when the sampled stop bit is LOW |

**Signal timing notes:**
- `tx_start` must be asserted for exactly **one** `clk` rising edge while `tx_busy = 0`.
- `tx_start` while `tx_busy = 1` is silently ignored (no side effects on the active frame).
- `tx_data` may change freely after the cycle where `tx_start` is accepted.
- `tx_done` is **one clock wide**; capture it with a flag register if needed.
- `rx_done_valid` and `framing_error` are mutually exclusive for any completed frame.
- `rx_data` remains unchanged after a false start, framing error, or reset.

---

## 🔄 Full-Duplex Operation

`uart_top` achieves full-duplex by keeping the TX and RX paths entirely separate:

As a result, a byte may be received while another byte is being transmitted, and both
operations complete with their own independent done pulses (`tx_done`, `rx_done_valid`).

> **Note:** The testbench connects `rx = tx` (loopback) for self-verification only.
> There is **no internal loopback path** inside synthesizable `uart_top.v`.

---

## 🖥️ Simulation Results

Run simulation from either `sim/modelsim` or `sim/xsim` to validate the design.

```text
=== uart_top Testbench (full-duplex self-check) ===

--- TC1: Reset and idle behavior ---
[36000] PASS: Reset restores both UART directions to idle
[296000] PASS: Idle UART lines remain inactive

--- TC2: TX-to-RX loopback payloads ---
[306000] PASS: TX request starts a UART frame
[1106000] PASS: Loopback transfers 0x55 correctly
[1106000] PASS: Loopback produces one RX valid event
[1116000] PASS: TX produces one completion event
[1116000] PASS: Both directions return to idle after loopback
...
[3576000] PASS: Both directions return to idle after loopback

--- TC3: TX busy request rejection ---
[3586000] PASS: TX request starts a UART frame
[3836000] PASS: Second TX request is ignored while busy
[4386000] PASS: Busy rejection preserves active TX payload
[4386000] PASS: Busy rejection creates no extra RX frame
[5216000] PASS: Both directions return to idle after loopback

--- TC4: RX framing error through top wrapper ---
[6056000] PASS: RX framing error reaches top-level output
[6056000] PASS: Invalid RX frame does not commit payload
[6876000] PASS: Both directions return to idle after loopback

--- TC5: Reset aborts active full-duplex transaction ---
[6886000] PASS: TX request starts a UART frame
[7066000] PASS: Reset aborts TX and RX state machines together
[7916000] PASS: Both directions return to idle after loopback
-----------------------------------------------
=== PASS: 5 TCs, all 45 checks passed ===
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
| 1 | Reset & idle | Assert `rst_n=0`, release | `tx=1`, `tx_busy=0`, `rx_busy=0`, `rx_done_valid=0` | ✅ Pass |
| 2 | TX-to-RX loopback | Send `0x55`, `0xA3`, `0x00`, `0xFF` via loopback | RX receives identical payload; one `rx_done_valid` per frame | ✅ Pass |
| 3 | TX busy rejection | Assert `tx_start` mid-frame with new payload | Active frame unchanged; rejected byte transmits cleanly after `tx_done` | ✅ Pass |
| 4 | RX framing error | Drive LOW stop bit on `rx` | `framing_error` pulses; `rx_data` unchanged; FSM recovers and accepts next frame | ✅ Pass |
| 5 | Reset during transaction | Assert `rst_n=0` mid TX+RX | Both FSMs abort; `tx_busy=0`, `rx_busy=0`, `tx_done=0`, `rx_done_valid=0`; clean restart | ✅ Pass |

Detailed verification intent is recorded in [docs/test_plan.md](docs/test_plan.md).

---

## ⚙️ Baud Rate Reference

| `CLK_FREQ_HZ` | `BAUD_RATE` | `CLKS_PER_BIT` | Error |
|---|---|---|---|
| 50 000 000 | 115 200 | 434 | +0.006 % ✅ |
| 50 000 000 | 9 600 | 5 208 | +0.006 % ✅ |
| 100 000 000 | 115 200 | 868 | +0.006 % ✅ |
| 12 000 000 | 115 200 | 104 | +0.160 % ✅ |
| 8 000 000 | 1 000 000 | 8 | +0.000 % ✅ |

> Baud error below **±2 %** is universally accepted; above ±5 % causes framing errors.
> Select parameters that produce **at least 8 system clocks per UART bit** for useful sampling margin.

---

## ⚠️ Known Limitations

| # | Limitation | Suggested Extension |
|---:|---|---|
| 1 | No TX or RX FIFO | Add independent FIFOs and ready/valid interfaces |
| 2 | Frame format is fixed at 8N1 | Parameterize parity, data width, and stop bits |
| 3 | TX requests while busy are silently dropped | Add a request queue or a `tx_ready` back-pressure signal |
| 4 | RX reports framing errors only | Add parity, overrun, and break detection |
| 5 | RX uses one center sample per bit | Add 8× or 16× oversampling with majority voting |
| 6 | Integer baud divider has finite error | Add a fractional baud-rate accumulator |
| 7 | No hardware flow control | Add RTS/CTS signals and policy logic |

---

## 📚 References

| # | Title | Source |
|---|---|---|
| [1] | **UART Protocol — Lý Thuyết Giao Thức UART** | [`docs/uart_theory.md`](../../docs/uart_theory.md) — Idle state, 8N1 frame structure, baud rate, parity, framing/overrun errors, flow control |
| [2] | **Basics of UART Communication** | [circuitbasics.com](https://www.circuitbasics.com/basics-uart-communication/) |
| [3] | **Wikipedia — UART** | [wikipedia.org](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver-transmitter) |


---

*Module: `uart_top.v` · Author: Long Hai · Protocol: UART 8N1 full duplex*
