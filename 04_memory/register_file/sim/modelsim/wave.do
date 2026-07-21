# wave.do - ModelSim Waveform Configuration
# Module: register_file
# Description: Waveform setup for register_file simulation
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
add wave -noupdate /$TB/we
add wave -noupdate -radix unsigned /$TB/waddr
add wave -noupdate -radix hex /$TB/wdata
add wave -noupdate -radix unsigned /$TB/raddr1
add wave -noupdate -radix unsigned /$TB/raddr2

# ---------------------------------------------------------------------------
# --- DUT Internal ---
# ---------------------------------------------------------------------------
add wave -divider {DUT Internal}
add wave -noupdate -radix hex -color yellow /$TB/dut/regs

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add wave -divider {Outputs}
add wave -noupdate -radix hex -color orange /$TB/rdata1
add wave -noupdate -radix hex -color orange /$TB/rdata2

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
