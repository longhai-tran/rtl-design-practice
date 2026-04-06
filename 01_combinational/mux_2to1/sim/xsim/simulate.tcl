# ==============================================================================
# simulate.tcl — Standalone script for Vivado xsim
# ==============================================================================
# Purpose: Compile, elaborate, and run simulation without using Makefile.
# Usage:   xtclsh simulate.tcl
# ==============================================================================

set TOP "mux_2to1_tb"
set SOURCES [list "../../mux_2to1.v" "../../mux_2to1_tb.v"]
set SNAP "sim_snapshot"

puts "\[TCL\] Starting standalone simulation for $TOP..."

# ------------------------------------------------------------------------------
# 1. Compile (xvlog)
# ------------------------------------------------------------------------------
puts "\n\[TCL\] --- Step 1: Compiling ---"
if {[catch {exec xvlog {*}$SOURCES >@stdout} err]} {
    puts "\[ERROR\] Compilation failed:\n$err"
    exit 1
}

# ------------------------------------------------------------------------------
# 2. Elaborate (xelab)
# ------------------------------------------------------------------------------
puts "\n\[TCL\] --- Step 2: Elaborating ---"
if {[catch {exec xelab $TOP -s $SNAP >@stdout} err]} {
    puts "\[ERROR\] Elaboration failed:\n$err"
    exit 1
}

# ------------------------------------------------------------------------------
# 3. Simulate (xsim)
# ------------------------------------------------------------------------------
puts "\n\[TCL\] --- Step 3: Simulating ---"
# Run with batch mode (-R alias for -runall)
if {[catch {exec xsim $SNAP -R >@stdout} err]} {
    puts "\[ERROR\] Simulation failed:\n$err"
    exit 1
}

puts "\n\[TCL\] Simulation completed successfully!"