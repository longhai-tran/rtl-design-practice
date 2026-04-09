# sim/modelsim/simulate.do — ModelSim / Questa
# Compatible: ModelSim PE/DE, Questa Sim
#
# HOW TO USE:
#   vsim -c -do simulate.do          (batch/headless mode)
#   vsim -do simulate.do             (GUI mode — loads wave.do automatically)
# ---------------------------------------------------------------------------

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog ../../full_adder.v
vlog ../../full_adder_tb.v

if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    vsim -c work.full_adder_tb
    run -all
    quit -f
} else {
    vsim work.full_adder_tb
    do wave.do
    run -all
}

