# wave.do — ModelSim/QuestaSim Waveform Configuration
# Module     : fsm_traffic_light
# Testbench  : fsm_traffic_light_tb
# Description: Waveform setup for fsm_traffic_light simulation
#
# HOW TO USE:
#   Loaded automatically by simulate.do in GUI mode.
#   Or manually: vsim work.fsm_traffic_light_tb -do wave.do
# ---------------------------------------------------------------------------

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

# Clear any pre-existing waveform pane content
quietly WaveActivateNextPane {} 0

# Show short signal names (e.g. 'clk' instead of '/fsm_traffic_light_tb/clk')
configure wave -signalnamewidth 1

# ---------------------------------------------------------------------------
# --- System signals ---
# ---------------------------------------------------------------------------
add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

# ---------------------------------------------------------------------------
# --- DUT Internal ---
# ---------------------------------------------------------------------------
add wave -divider {DUT Internal}
add wave -noupdate -color yellow                     /$TB/dut/state
add wave -noupdate -color "light blue"               /$TB/dut/next_state
add wave -noupdate -color "light blue" -radix unsigned    /$TB/dut/count

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add wave -divider {NS Light}
add wave -noupdate -color orange /$TB/ns_light

add wave -divider {EW Light}
add wave -noupdate -color orange /$TB/ew_light

# ---------------------------------------------------------------------------
# --- Verification ---
# ---------------------------------------------------------------------------
add wave -divider {Verification}
add wave -noupdate -radix dec /$TB/error_count

# ---------------------------------------------------------------------------
# --- Wave display settings ---
# ---------------------------------------------------------------------------
WaveRestoreZoom {0 ns} {250 ns}

configure wave -namecolwidth  180
configure wave -valuecolwidth  80
configure wave -justifyvalue   left
configure wave -snapdistance   10
configure wave -datasetprefix   0
configure wave -rowmargin       4
configure wave -childrowmargin  2

# Redraw waveform pane after all signal additions
update
