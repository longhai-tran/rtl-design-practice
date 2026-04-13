# wave.do — ModelSim Waveform Configuration
# Module: alu_4bit
# Description: Waveform setup for alu_4bit simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.alu_4bit_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms
quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- Inputs ---
add wave -divider Inputs
add wave -noupdate /alu_4bit_tb/a
add wave -noupdate /alu_4bit_tb/b
add wave -noupdate /alu_4bit_tb/op

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -color orange /alu_4bit_tb/y
add wave -noupdate -color orange /alu_4bit_tb/carry
add wave -noupdate -color orange /alu_4bit_tb/zero

# --- Expected Outputs ---
add wave -divider Expected_Outputs
add wave -noupdate -color yellow /alu_4bit_tb/expected_y
add wave -noupdate -color yellow /alu_4bit_tb/expected_carry
add wave -noupdate -color yellow /alu_4bit_tb/expected_zero

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
