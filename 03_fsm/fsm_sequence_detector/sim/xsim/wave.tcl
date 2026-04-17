# wave.tcl — XSIM Waveform Configuration
# Module  : fsm_sequence_detector
# Tool    : Xilinx XSIM
# Description: Waveform setup for Mealy FSM sequence detector (detects 1011)
#
# HOW TO USE:
#   Loaded automatically by simulate.tcl in GUI mode
#   Or manually: xsim <snapshot> -gui -tclbatch wave.tcl
# ---------------------------------------------------------------------------

# Log all signals recursively for full post-sim replay
log_wave -recursive /

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

# --- System ---
add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

# --- Inputs ---
add_wave_divider "Inputs"
add_wave /$TB/din

# --- DUT Internal ---
add_wave_divider "DUT Internal"
add_wave -radix unsigned /$TB/dut/state
add_wave -radix unsigned /$TB/dut/next_state

# --- Outputs ---
add_wave_divider "Outputs"
add_wave /$TB/detected

# --- Expected Outputs ---
add_wave_divider "Expected Outputs"
add_wave /$TB/expected_detect

# --- Error Count ---
add_wave_divider "Error Count"
add_wave -radix dec /$TB/error_count

# Run simulation (with timeout as safety guard)
run 100ns
# run all
