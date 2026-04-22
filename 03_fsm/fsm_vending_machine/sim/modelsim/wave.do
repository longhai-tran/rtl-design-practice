# wave.do - Generic ModelSim waveform setup
# Usage: loaded from simulate.do (GUI mode)

set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

# add wave -divider Testbench
# add wave -r /$TB/*

# ---------------------------------------------------------------------------
# --- System signals ---
# ---------------------------------------------------------------------------
add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

# ---------------------------------------------------------------------------
# --- Inputs ---
# ---------------------------------------------------------------------------
add wave -divider {Inputs}
add wave -noupdate /$TB/coin_5
add wave -noupdate /$TB/coin_10

# ---------------------------------------------------------------------------
# --- DUT Internal ---
# ---------------------------------------------------------------------------
add wave -divider {DUT Internal}
add wave -noupdate -color yellow                     /$TB/dut/state
add wave -noupdate -color "light blue"               /$TB/dut/next_state

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add wave -divider {Outputs}
add wave -noupdate -color orange /$TB/vend
add wave -noupdate -color orange /$TB/change_5

# ---------------------------------------------------------------------------
# --- Verification ---
# ---------------------------------------------------------------------------
add wave -divider {Verification}
add wave -noupdate -radix dec /$TB/pass_count
add wave -noupdate -radix dec /$TB/fail_count


WaveRestoreZoom {0 ns} {200 ns}
configure wave -namecolwidth 150
configure wave -valuecolwidth 60
configure wave -justifyvalue left
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

update
