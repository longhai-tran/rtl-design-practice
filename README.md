# RTL Design Practice — Verilog Modules

[![Verilog Lint](https://github.com/longhai-tran/rtl-design-practice/actions/workflows/lint.yml/badge.svg)](https://github.com/longhai-tran/rtl-design-practice/actions/workflows/lint.yml)
![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Simulator](https://img.shields.io/badge/Sim-ModelSim%20%7C%20Vivado%20xsim-green)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

> RTL modules in Verilog — combinational, sequential, FSM, memory, and interfaces.
> Built as part of a structured VLSI engineering learning journey.

## 📁 Project Structure

| Category | Modules | Status |
|----------|---------|--------|
| `01_combinational` | mux_2to1, full_adder, alu_4bit | 🔄 In Progress |
| `02_sequential`    | dff, counter_4bit, shift_register | 📅 Planned |
| `03_fsm`           | sequence_detector, traffic_light | 📅 Planned |
| `04_memory`        | sync_fifo, async_fifo | 📅 Planned |
| `05_interfaces`    | uart_tx, uart_rx, spi_master | 📅 Planned |
| `06_advanced`      | simple_cpu, wishbone_slave | 📅 Planned |

## 🛠️ Tools & Environment

| Tool | Purpose |
|------|---------|
| Vivado xsim | Simulation (free) |
| ModelSim | Simulation |
| Verilator | Lint check (CI) |
| Git | Version control |

## 🚀 Quick Start (mux_2to1)

```bash
cd 01_combinational/mux_2to1/sim/xsim
make sim      # Run simulation
make wave     # Open waveform
make clean    # Clean artifacts
```

## 🔧 Developer Workflow

To maintain high code quality and prevent CI failures, I enforce a strict linting process before simulation.

```bash
# 1. Run local linting (verifies syntax and standards)
bash scripts/lint.sh

# 2. If lint passes, proceed to simulation
cd <module_path>/sim/xsim
make sim
```

> **CI/CD Enforcement**: All RTL code must pass the linting checks before committing. A final automated linting check will execute via GitHub Actions CI/CD upon push.