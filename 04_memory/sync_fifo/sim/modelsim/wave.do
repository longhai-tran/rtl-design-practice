# wave.do - ModelSim Waveform Configuration
# Module: sync_fifo
# Description: Waveform setup for sync_fifo simulation
# ---------------------------------------------------------------------------
# Usage: loaded automatically from simulate.do in GUI mode
# ---------------------------------------------------------------------------

set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

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
add wave -noupdate /$TB/wr_en
add wave -noupdate /$TB/rd_en
add wave -noupdate -radix hex /$TB/din

# ---------------------------------------------------------------------------
# --- DUT Internal ---
# ---------------------------------------------------------------------------
add wave -divider {DUT Internal}
add wave -noupdate -radix unsigned -color yellow /$TB/dut/wr_ptr
add wave -noupdate -radix unsigned -color yellow /$TB/dut/rd_ptr
add wave -noupdate -radix unsigned -color yellow /$TB/level
add wave -noupdate -color yellow /$TB/full
add wave -noupdate -color yellow /$TB/empty
add wave -noupdate -radix hex -color yellow /$TB/dut/mem

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add wave -divider {Outputs}
add wave -noupdate -radix hex -color orange /$TB/dout

# ---------------------------------------------------------------------------
# --- Verification ---
# ---------------------------------------------------------------------------
add wave -divider {Verification}
add wave -noupdate -radix dec /$TB/model_count
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
