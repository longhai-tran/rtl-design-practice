# =============================================================================
# simulate.do - Portable ModelSim runner for uart_top
# =============================================================================

set TOP uart_top_tb
set SOURCES [list \
    ../../../uart_tx/uart_tx.v \
    ../../../uart_rx/uart_rx.v \
    ../../uart_top.v \
    ../../uart_top_tb.v]

if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

foreach f $SOURCES {
    if {![file exists $f]} {
        puts [format {[ERROR] Source not found: %s} $f]
        quit -f
    }
    vlog $f
}

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.$TOP
    run -all
    quit -f
} else {
    vsim work.$TOP
    do wave.do
    run -all
}
