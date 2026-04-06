# =============================================================================
# Makefile — mux_2to1 | ModelSim / Questa
# =============================================================================
# Targets:
#   make sim    — Batch / headless simulation (no GUI)
#   make gui    — GUI mode with styled waveform (loads wave.do)
#   make do     — Portable: run entirely via simulate.do (no make required)
#   make clean  — Remove all build artifacts
# =============================================================================

TOP  = mux_2to1_tb
SRCS = ../../mux_2to1.v ../../mux_2to1_tb.v

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
	rm -rf work/ transcript *.wlf *.log modelsim.ini
	@echo "Cleaned."
