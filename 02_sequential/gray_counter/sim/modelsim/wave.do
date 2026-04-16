# wave.do - ModelSim Waveform Configuration
# Module: gray_counter
# Description: Waveform setup for gray_counter simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.gray_counter_tb -do wave.do
# ---------------------------------------------------------------------------

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- System ---
add wave -divider System
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -color orange /$TB/q

# --- Expected Outputs ---
add wave -divider Expected_Outputs
add wave -noupdate -color yellow /$TB/expected_q

# --- Error Count ---
add wave -divider Error_Count
add wave -radix decimal -noupdate -color red /$TB/error_count
add wave -radix decimal -noupdate -color green /$TB/bit_toggle_count


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
