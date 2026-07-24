# =============================================================================
# simulate.tcl - Portable xsim runner for uart_top
# =============================================================================

set TOP uart_top_tb
set SOURCES [list \
    ../../../uart_tx/uart_tx.v \
    ../../../uart_rx/uart_rx.v \
    ../../uart_top.v \
    ../../uart_top_tb.v]
set SNAP sim_snapshot

foreach f $SOURCES {
    if {![file exists $f]} {
        puts [format {[ERROR] Source not found: %s} $f]
        exit 1
    }
}

if {[catch {exec xvlog {*}$SOURCES >@stdout} err]} {
    puts [format {[ERROR] Compilation failed:\n%s} $err]
    exit 1
}
if {[catch {exec xelab $TOP -s $SNAP >@stdout} err]} {
    puts [format {[ERROR] Elaboration failed:\n%s} $err]
    exit 1
}
if {[catch {exec xsim $SNAP -R >@stdout} err]} {
    puts [format {[ERROR] Simulation failed:\n%s} $err]
    exit 1
}
puts {[TCL] Simulation completed successfully!}
