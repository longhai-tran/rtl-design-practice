if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../dff_async_reset.v
vlog ../../dff_async_reset_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.dff_async_reset_tb
    run -all
    quit -f
} else {
    vsim work.dff_async_reset_tb
    do wave.do
    run -all
}
