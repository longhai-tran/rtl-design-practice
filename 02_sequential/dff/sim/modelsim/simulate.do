if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../dff.v
vlog ../../dff_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.dff_tb
    run -all
    quit -f
} else {
    vsim work.dff_tb
    do wave.do
    run -all
}
