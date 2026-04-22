log_wave -recursive /

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

# add_wave /$TB/*

# ---------------------------------------------------------------------------
# --- System signals ---
# ---------------------------------------------------------------------------
add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

# ---------------------------------------------------------------------------
# --- Inputs ---
# ---------------------------------------------------------------------------
add_wave_divider "Inputs"
add_wave /$TB/coin_5
add_wave /$TB/coin_10

# ---------------------------------------------------------------------------
# --- DUT signals ---
# ---------------------------------------------------------------------------
add_wave_divider "DUT"
add_wave /$TB/dut/state
add_wave /$TB/dut/next_state

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add_wave_divider "Outputs"
add_wave /$TB/vend
add_wave /$TB/change_5

# ---------------------------------------------------------------------------
# --- Verification ---
# ---------------------------------------------------------------------------
add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count


run all
