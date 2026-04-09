# =============================================================================
# Makefile — ripple_carry_adder | Vivado xsim
# =============================================================================
# Targets:
#   make sim    — Batch / headless simulation (no GUI)
#   make gui    — GUI mode with pre-configured waveform (loads wave.tcl)
#   make do     — Portable: run entirely via simulate.tcl (no make required)
#   make clean  — Remove all build artifacts
# =============================================================================

TOP  = ripple_carry_adder_tb
SRCS = ../../ripple_carry_adder.v ../../ripple_carry_adder_tb.v
SNAP = $(TOP)_snap

.PHONY: all sim gui do clean

all: sim

sim:
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP)
	xsim $(SNAP) -runall -log sim.log

gui:
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP) -debug typical
	xsim $(SNAP) -gui -tclbatch wave.tcl

do:
	xtclsh simulate.tcl

clean:
	rm -rf xsim.dir/ *.pb *.log *.jou *.wdb webtalk/ .Xil/ dfx_runtime.txt
	@echo "Cleaned."

