if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../encoder_8to3.v
vlog ../../encoder_8to3_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.encoder_8to3_tb
    run -all
    quit -f
} else {
    vsim work.encoder_8to3_tb
    do wave.do
    run -all
}
