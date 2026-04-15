# wave.do — ModelSim Waveform Configuration
# Module: counter_4bit
# Description: Waveform setup for counter_4bit simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.counter_4bit_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms
quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- System ---
add wave -divider System
add wave -noupdate /counter_4bit_tb/clk
add wave -noupdate /counter_4bit_tb/rst_n

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -color orange /counter_4bit_tb/q

# --- Expected Outputs ---
add wave -divider Expected_Outputs
add wave -noupdate -color yellow /counter_4bit_tb/expected_q

add wave -divider Error_Count
add wave -radix decimal -noupdate /counter_4bit_tb/error_count
add wave -radix decimal -noupdate /counter_4bit_tb/tc

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
