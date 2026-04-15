# wave.do — ModelSim Waveform Configuration
# Module: encoder_8to3
# Description: Waveform setup for encoder_8to3 simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.encoder_8to3_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- Inputs ---
add wave -divider Inputs
add wave -noupdate -label "d"   -color Cyan   /$TB/d

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -label "y"   -color Orange   /$TB/y
add wave -noupdate -label "valid"   -color Red   /$TB/valid
add wave -noupdate -label "expected_y"   -color Green   /$TB/expected_y
add wave -noupdate -label "expected_valid"   -color Blue   /$TB/expected_valid

# --- Wave display settings ---
WaveRestoreZoom {0 ns} {200 ns}

configure wave -namecolwidth  150
configure wave -valuecolwidth  60
configure wave -justifyvalue  left
configure wave -snapdistance   10
configure wave -datasetprefix  0
configure wave -rowmargin      4
configure wave -childrowmargin 2

# Force wave window to render all signals after adding
update
