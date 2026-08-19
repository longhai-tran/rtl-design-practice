set script_dir [file dirname [file normalize [info script]]]
set TOP "[file tail [file dirname [file dirname $script_dir]]]_tb"
set SOURCES [lsort [glob -nocomplain ../../*.v ../../*.sv]]
set SNAP sim_snapshot
if {[catch {exec xvlog {*}$SOURCES >@stdout} err]} { puts $err; exit 1 }
if {[catch {exec xelab $TOP -s $SNAP >@stdout} err]} { puts $err; exit 1 }
if {[catch {exec xsim $SNAP -R >@stdout} err]} { puts $err; exit 1 }
