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
# --- DUT Internal ---
# ---------------------------------------------------------------------------
add_wave_divider "DUT Internal"
add_wave -radix unsigned /$TB/dut/state
add_wave -radix unsigned /$TB/dut/next_state
add_wave -radix unsigned /$TB/dut/count

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add_wave_divider "Outputs"
add_wave /$TB/ns_light
add_wave /$TB/ew_light

# --- Expected Outputs ---
# add_wave_divider "Expected Outputs"
# add_wave /$TB/exp_ns
# add_wave /$TB/exp_ew

# ---------------------------------------------------------------------------
# --- Verification ---
# ---------------------------------------------------------------------------
add_wave_divider "Error Count"
add_wave -radix dec /$TB/error_count


run all
