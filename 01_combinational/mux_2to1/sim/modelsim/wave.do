# wave.do — ModelSim Waveform Configuration
# Module: mux_2to1
# Description: Waveform setup for mux_2to1 simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.mux_2to1_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- Inputs ---
add wave -divider Inputs
add wave -noupdate -label "a"   -color Cyan   /$TB/a
add wave -noupdate -label "b"   -color Yellow /$TB/b
add wave -noupdate -label "sel" -color Orange /$TB/sel

# --- Output ---
add wave -divider Output
add wave -noupdate -label "y"   -color Green  /$TB/y

# --- DUT Internal ---
add wave -divider DUT Ports
add wave -noupdate -label "dut.a"   /$TB/dut/a
add wave -noupdate -label "dut.b"   /$TB/dut/b
add wave -noupdate -label "dut.sel" /$TB/dut/sel
add wave -noupdate -label "dut.y"   /$TB/dut/y

# --- Wave display settings ---
WaveRestoreZoom {0 ns} {100 ns}

configure wave -namecolwidth  150
configure wave -valuecolwidth  60
configure wave -justifyvalue  left
configure wave -snapdistance   10
configure wave -datasetprefix  0
configure wave -rowmargin      4
configure wave -childrowmargin 2

# Force wave window to render all signals after adding
update
