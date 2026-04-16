# wave.do — ModelSim Waveform Configuration
# Module: alu_4bit
# Description: Waveform setup for alu_4bit simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.alu_4bit_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- Inputs ---
add wave -divider Inputs
add wave -noupdate /$TB/a
add wave -noupdate /$TB/b
add wave -noupdate /$TB/op

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -color orange /$TB/y
add wave -noupdate -color orange /$TB/carry
add wave -noupdate -color orange /$TB/zero

# --- Expected Outputs ---
add wave -divider Expected_Outputs
add wave -noupdate -color yellow /$TB/expected_y
add wave -noupdate -color yellow /$TB/expected_carry
add wave -noupdate -color yellow /$TB/expected_zero

# --- Wave display settings ---
WaveRestoreZoom {0 ns} {1500 ns}

configure wave -namecolwidth  150
configure wave -valuecolwidth  60
configure wave -justifyvalue  left
configure wave -snapdistance   10
configure wave -datasetprefix  0
configure wave -rowmargin      4
configure wave -childrowmargin 2

# Force wave window to render all signals after adding
update
