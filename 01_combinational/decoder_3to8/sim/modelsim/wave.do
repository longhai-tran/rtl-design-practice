# wave.do — ModelSim Waveform Configuration
# Module: decoder_3to8
# Description: Waveform setup for decoder_3to8 simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.decoder_3to8_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms
quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- Inputs ---
add wave -divider Inputs
add wave -noupdate -label "in" -color green /decoder_3to8_tb/in
add wave -noupdate -label "en" -color green /decoder_3to8_tb/en

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -label "y" -color red /decoder_3to8_tb/y
add wave -noupdate -label "expected_y" -color orange /decoder_3to8_tb/expected_y
add wave -noupdate -label "error_count" -color yellow /decoder_3to8_tb/error_count

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
