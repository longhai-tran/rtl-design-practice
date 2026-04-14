# wave.do — ModelSim Waveform Configuration
# Module: register_8bit
# Description: Waveform setup for register_8bit simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.register_8bit_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms
quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- System ---
add wave -divider System
add wave -noupdate /register_8bit_tb/clk
add wave -noupdate /register_8bit_tb/rst_n

# --- Inputs ---
add wave -divider Inputs
add wave -noupdate /register_8bit_tb/d

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -color orange /register_8bit_tb/q

# --- Expected Outputs ---
add wave -divider Expected_Outputs
add wave -noupdate -color yellow /register_8bit_tb/expected_q

add wave -divider Error_Count
add wave -radix decimal -noupdate -color red /register_8bit_tb/error_count

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
