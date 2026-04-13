# wave.do — ModelSim Waveform Configuration
# Module: carry_lookahead_adder
# Description: Waveform setup for carry_lookahead_adder simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode
#   Or manually: vsim work.carry_lookahead_adder_tb -do wave.do
# ---------------------------------------------------------------------------

# Clear existing waveforms
quietly WaveActivateNextPane {} 0

# Global wave configuration to show short signal names (e.g. 'clk' instead of '/tb/clk')
configure wave -signalnamewidth 1

# --- Inputs ---
add wave -divider Inputs
add wave -noupdate -label "a"   -color Cyan   /carry_lookahead_adder_tb/a
add wave -noupdate -label "b"   -color Yellow /carry_lookahead_adder_tb/b
add wave -noupdate -label "cin" -color Orange /carry_lookahead_adder_tb/cin

# --- Outputs ---
add wave -divider Outputs
add wave -noupdate -label "sum"  -color Green   /carry_lookahead_adder_tb/sum
add wave -noupdate -label "cout" -color Magenta /carry_lookahead_adder_tb/cout

# --- Wave display settings ---
WaveRestoreZoom {0 ns} {5200 ns}

configure wave -namecolwidth  150
configure wave -valuecolwidth  60
configure wave -justifyvalue  left
configure wave -snapdistance   10
configure wave -datasetprefix  0
configure wave -rowmargin      4
configure wave -childrowmargin 2

# Force wave window to render all signals after adding
update
