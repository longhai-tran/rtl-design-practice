# =============================================================================
# scripts/xsim.mk — Shared Vivado xsim build rules
# =============================================================================
# Usage: include this file at the end of each module's Makefile.
#   TOP  and SRCS are auto-detected from the directory structure:
#     - TOP  defaults to <module_name>_tb  (2 levels above sim/xsim/)
#     - SRCS defaults to all *.v / *.sv files in the module directory
#   Override either variable before the include line if needed
# =============================================================================

SHELL := bash

# --- Auto-detect defaults (override in per-project Makefile if needed) --------
TOP  ?= $(notdir $(abspath $(CURDIR)/../..))_tb
SRCS ?= $(wildcard ../../*.v) $(wildcard ../../*.sv)

SNAP = $(TOP)_snap

.PHONY: all sim gui do clean help

all: sim

sim: ## Run batch / headless simulation (fastest, CI-friendly)
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP)
	xsim $(SNAP) -runall -log sim.log

gui: ## Open Vivado waveform viewer with pre-configured wave.tcl
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP) -debug typical
	xsim $(SNAP) -gui -tclbatch wave.tcl

do: ## Portable: run entirely via simulate.tcl  (usage: xtclsh simulate.tcl)
	xtclsh simulate.tcl

clean: ## Remove all generated artifacts (xsim.dir, logs, journals, waveforms)
	rm -rf xsim.dir/ *.pb *.log *.jou *.wdb webtalk/ .Xil/ dfx_runtime.txt vivado*.str
	@echo "Cleaned."

help: ## Show this help message
	@printf "\n\033[1;36m  Vivado xsim — available targets\033[0m\n"
	@printf '%.0s─' {1..44}; printf '\n'
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[1;32m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\n  \033[1;36mVariables\033[0m  \033[90m(override in per-project Makefile if needed)\033[0m\n"
	@printf "  \033[33mTOP \033[0m = %s\n" "$(TOP)"
	@printf "  \033[33mSRCS\033[0m = $(words $(SRCS)) file(s) detected\n"
	@printf "\n"
