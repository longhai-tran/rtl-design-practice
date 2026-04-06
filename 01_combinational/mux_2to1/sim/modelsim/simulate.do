# sim/modelsim/simulate.do — ModelSim / Questa
# Compatible: ModelSim PE/DE, Questa Sim
#
# HOW TO USE:
#   vsim -c -do simulate.do          (batch/headless mode)
#   vsim -do simulate.do             (GUI mode — loads wave.do automatically)
# ---------------------------------------------------------------------------

# --- 1. Setup work library ---
if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

# --- 2. Compile sources ---
vlog ../../mux_2to1.v     ;# DUT
vlog ../../mux_2to1_tb.v  ;# Testbench

# --- 3. Simulate ---
# Detect GUI vs batch mode: in batch mode, 'gui' namespace does not exist
if {[info exists ::env(VSIM_BATCH)] || [catch {gui_is_open} result]} {
    # Batch / headless mode
    vsim -c work.mux_2to1_tb
    run -all
    quit -f
} else {
    # GUI mode — load waveform config
    vsim work.mux_2to1_tb
    do wave.do
    run -all
}
