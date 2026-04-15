if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../counter_4bit.v
vlog ../../counter_4bit_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.counter_4bit_tb
    run -all
    quit -f
} else {
    vsim work.counter_4bit_tb
    do wave.do
    run -all
}
