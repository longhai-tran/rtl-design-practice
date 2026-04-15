# wave.do — ModelSim Waveform Configuration
# Module: full_adder
# Description: Waveform setup for full_adder simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.full_adder_tb -do wave.do
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
add wave -noupdate -label "cin" -color Orange /$TB/cin

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -label "sum"  -color Green /$TB/sum
add wave -noupdate -label "cout" -color Magenta /$TB/cout

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
