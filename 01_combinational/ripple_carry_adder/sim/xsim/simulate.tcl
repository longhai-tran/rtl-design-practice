# ==============================================================================
# simulate.tcl — Standalone script for Vivado xsim
# ==============================================================================
# Purpose: Compile, elaborate, and run simulation without using Makefile.
# Usage:   xtclsh simulate.tcl
# ==============================================================================

set TOP "ripple_carry_adder_tb"
set SOURCES [list "../../ripple_carry_adder.v" "../../ripple_carry_adder_tb.v"]
set SNAP "sim_snapshot"

puts "\[TCL\] Starting standalone simulation for $TOP..."

puts "\n\[TCL\] --- Step 1: Compiling ---"
if {[catch {exec xvlog {*}$SOURCES >@stdout} err]} {
    puts "\[ERROR\] Compilation failed:\n$err"
    exit 1
}

puts "\n\[TCL\] --- Step 2: Elaborating ---"
if {[catch {exec xelab $TOP -s $SNAP >@stdout} err]} {
    puts "\[ERROR\] Elaboration failed:\n$err"
    exit 1
}

puts "\n\[TCL\] --- Step 3: Simulating ---"
if {[catch {exec xsim $SNAP -R >@stdout} err]} {
    puts "\[ERROR\] Simulation failed:\n$err"
    exit 1
}

puts "\n\[TCL\] Simulation completed successfully!"

