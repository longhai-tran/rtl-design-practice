if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../shift_register.v
vlog ../../shift_register_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.shift_register_tb
    run -all
    quit -f
} else {
    vsim work.shift_register_tb
    do wave.do
    run -all
}
