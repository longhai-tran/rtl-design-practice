if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../alu_4bit.v
vlog ../../alu_4bit_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.alu_4bit_tb
    run -all
    quit -f
} else {
    vsim work.alu_4bit_tb
    do wave.do
    run -all
}
