# RTL Design Practice — Verilog Modules

[![Verilog Lint](https://github.com/longhai-tran/rtl-design-practice/actions/workflows/lint.yml/badge.svg)](https://github.com/longhai-tran/rtl-design-practice/actions/workflows/lint.yml)
![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20Vivado%20xsim-green)
![Modules](https://img.shields.io/badge/Modules-27-informational)

RTL modules in Verilog covering combinational logic, sequential circuits, FSMs, memory primitives, serial interfaces, and a system-level bus integration. Each module includes a self-checking testbench and dual-simulator support (ModelSim + Vivado xsim).

---

## 📁 Modules

| Category | Modules |
|----------|---------|
| [01 · Combinational](01_combinational/) | `mux_2to1` `mux_4to1` `full_adder` `ripple_carry_adder` `carry_lookahead_adder` `decoder_3to8` `encoder_8to3` `alu_4bit` |
| [02 · Sequential](02_sequential/) | `dff` `dff_async_reset` `register_8bit` `shift_register` `counter_4bit` `counter_updown` `gray_counter` `johnson_counter` |
| [03 · FSM](03_fsm/) | `fsm_sequence_detector` `fsm_traffic_light` `fsm_vending_machine` |
| [04 · Memory](04_memory/) | `sync_fifo` `async_fifo` `single_port_sram` `register_file` |
| [05 · Interfaces](05_interfaces/) | `uart_tx` `uart_rx` `uart_top` `spi_top` `i2c_top` |
| [06 · Advanced](06_advanced/) | `simple_cpu` [`wishbone_top`](06_advanced/wishbone_top/) |

---

## ⭐ Featured: Wishbone B4 Bus System

[`06_advanced/wishbone_top`](06_advanced/wishbone_top/) — system-level integration with 1 master, address decoder/mux interconnect, and 2 peripheral slaves.

```
wishbone_master ──► wishbone_interconnect ──► wishbone_slave #0 (0x0xxx)
                                          └──► wishbone_slave #1 (0x1xxx)
```

- Full read/write transactions with ACK/ERR handshake
- Byte-select granularity (`SEL[3:0]`)
- Read-only ID registers with write-protection (returns ERR)
- Unmapped address → immediate ERR response
- 24/24 test cases passed on ModelSim & Vivado xsim

---

## 🚀 Quick Start

Every module follows the same structure:

```bash
cd <category>/<module>/sim/modelsim
make sim     # headless simulation
make gui     # open waveform viewer
make clean   # remove build artifacts
```

```bash
cd <category>/<module>/sim/xsim
make sim
make gui
make clean
```

---

## 🛠️ Tools

| Tool | Role |
|------|------|
| ModelSim (Questa Altera FSE) | Primary simulator |
| Vivado xsim | Secondary simulator |
| Verilator | Lint (CI/CD) |

---

## 🔧 Lint & CI

Local lint before commit:

```bash
bash scripts/lint.sh
```

GitHub Actions runs Verilator lint automatically on every push to `main` and `dev` — see [`.github/workflows/lint.yml`](.github/workflows/lint.yml).
