# =============================================================================
# simulate.do - Portable ModelSim runner
# Usage: vsim -c -do simulate.do
# TOP + SOURCES auto-detected from path: <module>/sim/modelsim/simulate.do
# =============================================================================

# Auto-detect module name: 2 levels above sim/modelsim/
set MODULE [file tail [file dirname [file dirname [pwd]]]]
set TOP    ${MODULE}_tb

if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

set SOURCES [lsort [glob -nocomplain ../../*.v ../../*.sv]]
if {[llength $SOURCES] == 0} {
    puts "\[ERROR\] No source files found in ../../"
    quit -f
}

puts "\[DO\] TOP     = $TOP"
puts "\[DO\] SOURCES = $SOURCES"

foreach f $SOURCES { vlog $f }

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.$TOP
    run -all
    quit -f
} else {
    vsim work.$TOP
    do wave.do
    run -all
}

