if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../decoder_3to8.v
vlog ../../decoder_3to8_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.decoder_3to8_tb
    run -all
    quit -f
} else {
    vsim work.decoder_3to8_tb
    do wave.do
    run -all
}
