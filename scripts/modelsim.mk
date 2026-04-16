# =============================================================================
# scripts/modelsim.mk — Shared ModelSim / Questa build rules
# =============================================================================
# Usage: include this file at the end of each module's Makefile.
#   TOP  and SRCS are auto-detected from the directory structure:
#     - TOP  defaults to <module_name>_tb  (2 levels above sim/modelsim/)
#     - SRCS defaults to all *.v / *.sv files in the module directory
#   Override either variable before the include line if needed.
#
# Targets:
#   make sim    — Batch / headless simulation (no GUI)
#   make gui    — GUI mode with pre-configured waveform (loads wave.do)
#   make do     — Portable: run entirely via simulate.do (no make required)
#   make clean  — Remove all build artifacts
# =============================================================================

# --- Auto-detect defaults (override in per-project Makefile if needed) --------
TOP  ?= $(notdir $(abspath $(CURDIR)/../..))_tb
SRCS ?= $(wildcard ../../*.v) $(wildcard ../../*.sv)

.PHONY: all sim gui do clean

all: sim

# -----------------------------------------------------------------------------
# sim — Batch / headless (fastest, CI-friendly)
# -----------------------------------------------------------------------------
sim:
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -c work.$(TOP) -do "run -all; quit -f"

# -----------------------------------------------------------------------------
# gui — Open ModelSim GUI with pre-configured waveform (wave.do)
# -----------------------------------------------------------------------------
gui:
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -voptargs=+acc work.$(TOP) -do wave.do -do "run -all"

# -----------------------------------------------------------------------------
# do — Portable: run entirely via simulate.do (no make required)
# Usage: vsim -c -do simulate.do
# -----------------------------------------------------------------------------
do:
	vsim -c -do simulate.do

# -----------------------------------------------------------------------------
# clean — Remove all generated artifacts
# -----------------------------------------------------------------------------
clean:
	rm -rf work/ transcript *.wlf wlf* *.log modelsim.ini
	@echo "Cleaned."
