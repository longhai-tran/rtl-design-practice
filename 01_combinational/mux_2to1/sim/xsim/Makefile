# =============================================================================
# Makefile — mux_2to1 | Vivado xsim
# =============================================================================
# Targets:
#   make sim    — Batch / headless simulation (no GUI)
#   make gui    — GUI mode with pre-configured waveform (loads wave.tcl)
#   make clean  — Remove all build artifacts
# =============================================================================

TOP  = mux_2to1_tb
SRCS = ../../mux_2to1.v ../../mux_2to1_tb.v
SNAP = $(TOP)_snap

.PHONY: all sim gui clean

all: sim

# -----------------------------------------------------------------------------
# sim — Batch / headless (fastest, CI-friendly)
# -----------------------------------------------------------------------------
sim:
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP)
	xsim $(SNAP) -runall -log sim.log

# -----------------------------------------------------------------------------
# gui — Open Vivado waveform viewer with pre-configured wave.tcl
# -----------------------------------------------------------------------------
gui:
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP) -debug typical
	xsim $(SNAP) -gui -tclbatch wave.tcl

# -----------------------------------------------------------------------------
# do — Portable: run entirely via simulate.tcl (no make required)
# Usage: xtclsh simulate.tcl
# -----------------------------------------------------------------------------
do:
	xtclsh simulate.tcl

# -----------------------------------------------------------------------------
# clean — Remove all generated artifacts
# -----------------------------------------------------------------------------
clean:
	rm -rf xsim.dir/ *.pb *.log *.jou *.wdb webtalk/ .Xil/ dfx_runtime.txt
	@echo "Cleaned."