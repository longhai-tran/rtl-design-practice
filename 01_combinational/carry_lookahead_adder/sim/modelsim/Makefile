# =============================================================================
# Makefile — carry_lookahead_adder | ModelSim / Questa
# =============================================================================
# Targets:
#   make sim    — Batch / headless simulation (no GUI)
#   make gui    — GUI mode with pre-configured waveform (loads wave.do)
#   make do     — Portable: run entirely via simulate.do (no make required)
#   make clean  — Remove all build artifacts
# =============================================================================

TOP  = carry_lookahead_adder_tb
SRCS = ../../carry_lookahead_adder.v ../../carry_lookahead_adder_tb.v

.PHONY: all sim gui do clean

all: sim

sim:
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -c work.$(TOP) -do "run -all; quit -f"

gui:
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -voptargs=+acc work.$(TOP) -do wave.do -do "run -all"

do:
	vsim -c -do simulate.do

clean:
	rm -rf work/ transcript *.wlf *.log modelsim.ini
	@echo "Cleaned."
