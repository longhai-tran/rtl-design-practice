# =============================================================================
# simulate.tcl - Portable xsim runner
# Usage: xtclsh simulate.tcl
# TOP + SOURCES auto-detected from path: <module>/sim/xsim/simulate.tcl
# =============================================================================

set script_dir [file dirname [file normalize [info script]]]
set TOP        "[file tail [file dirname [file dirname $script_dir]]]_tb"
set SOURCES    [lsort [glob -nocomplain ../../*.v ../../*.sv]]
set SNAP       "sim_snapshot"

if {[llength $SOURCES] == 0} {
    puts "\[ERROR\] No source files found in ../../"
    exit 1
}

puts "\[TCL\] TOP     = $TOP"
puts "\[TCL\] SOURCES = $SOURCES"

if {[catch {exec xvlog {*}$SOURCES >@stdout} err]} {
    puts "\[ERROR\] Compilation failed:\n$err"
    exit 1
}
if {[catch {exec xelab $TOP -s $SNAP >@stdout} err]} {
    puts "\[ERROR\] Elaboration failed:\n$err"
    exit 1
}
if {[catch {exec xsim $SNAP -R >@stdout} err]} {
    puts "\[ERROR\] Simulation failed:\n$err"
    exit 1
}
puts "\[TCL\] Simulation completed successfully!"

