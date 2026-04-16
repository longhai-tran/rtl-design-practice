# =============================================================================
# scripts/xsim.mk — Shared Vivado xsim build rules
# =============================================================================
# Usage: include this file at the end of each module's Makefile.
#   TOP  and SRCS are auto-detected from the directory structure:
#     - TOP  defaults to <module_name>_tb  (2 levels above sim/xsim/)
#     - SRCS defaults to all *.v / *.sv files in the module directory
#   Override either variable before the include line if needed.
#
# Targets:
#   make sim    — Batch / headless simulation (no GUI)
#   make gui    — GUI mode with pre-configured waveform (loads wave.tcl)
#   make do     — Portable: run entirely via simulate.tcl (no make required)
#   make clean  — Remove all build artifacts
# =============================================================================

# --- Auto-detect defaults (override in per-project Makefile if needed) --------
TOP  ?= $(notdir $(abspath $(CURDIR)/../..))_tb
SRCS ?= $(wildcard ../../*.v) $(wildcard ../../*.sv)

SNAP = $(TOP)_snap

.PHONY: all sim gui do clean

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
	rm -rf xsim.dir/ *.pb *.log *.jou *.wdb webtalk/ .Xil/ dfx_runtime.txt vivado*.str
	@echo "Cleaned."
