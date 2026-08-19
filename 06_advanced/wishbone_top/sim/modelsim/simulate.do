set MODULE [file tail [file dirname [file dirname [pwd]]]]
set TOP ${MODULE}_tb
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work
foreach f [lsort [glob -nocomplain ../../*.v]] { vlog $f }
vsim -c work.$TOP -do "run -all; quit -f"
