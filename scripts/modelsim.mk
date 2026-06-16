# =============================================================================
# scripts/modelsim.mk — Shared ModelSim / Questa build rules
# =============================================================================
# Usage: include this file at the end of each module's Makefile.
#   TOP  and SRCS are auto-detected from the directory structure:
#     - TOP  defaults to <module_name>_tb  (2 levels above sim/modelsim/)
#     - SRCS defaults to all *.v / *.sv files in the module directory
#   Override either variable before the include line if needed.
# =============================================================================

SHELL := bash

# --- Auto-detect defaults (override in per-project Makefile if needed) --------
TOP  ?= $(notdir $(abspath $(CURDIR)/../..))_tb
SRCS ?= $(wildcard ../../*.v) $(wildcard ../../*.sv)

.PHONY: all sim gui do clean help

all: sim

sim: ## Run batch / headless simulation (fastest, CI-friendly)
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -c work.$(TOP) -do "run -all; quit -f"

gui: ## Open ModelSim GUI with pre-configured waveform (wave.do)
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -voptargs=+acc work.$(TOP) -do wave.do -do "run -all"

do: ## Portable: run entirely via simulate.do  (usage: vsim -c -do simulate.do)
	vsim -c -do simulate.do

clean: ## Remove all generated artifacts (work lib, transcripts, logs, waveforms)
	rm -rf work/ transcript *.wlf wlf* *.log modelsim.ini
	@echo "Cleaned."

help: ## Show this help message
	@printf "\n\033[1;36m  ModelSim / Questa — available targets\033[0m\n"
	@printf '%.0s─' {1..44}; printf '\n'
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[1;32m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\n  \033[1;36mVariables\033[0m  \033[90m(override in per-project Makefile if needed)\033[0m\n"
	@printf "  \033[33mTOP \033[0m = %s\n" "$(TOP)"
	@printf "  \033[33mSRCS\033[0m = $(words $(SRCS)) file(s) detected\n"
	@printf "\n"
