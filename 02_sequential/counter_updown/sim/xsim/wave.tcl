# XSIM waveform config for counter_updown

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

log_wave -recursive /

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "Inputs"
add_wave /$TB/up_down

add_wave_divider "Outputs"
add_wave /$TB/q

add_wave_divider "Expected Outputs"
add_wave /$TB/expected_q

add_wave_divider "Error Count"
add_wave -radix dec /$TB/error_count
add_wave -radix dec /$TB/tc

run all
# quit
