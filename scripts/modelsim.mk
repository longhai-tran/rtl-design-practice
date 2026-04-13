# =============================================================================
# scripts/modelsim.mk — Shared ModelSim / Questa build rules
# =============================================================================
# Usage: include this file at the end of each module's Makefile after defining:
#   TOP  = <testbench_top_module>
#   SRCS = <space-separated list of source files>
#
# Targets:
#   make sim    — Batch / headless simulation (no GUI)
#   make gui    — GUI mode with pre-configured waveform (loads wave.do)
#   make do     — Portable: run entirely via simulate.do (no make required)
#   make clean  — Remove all build artifacts
# =============================================================================

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
