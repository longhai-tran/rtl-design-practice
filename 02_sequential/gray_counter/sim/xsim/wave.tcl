log_wave -recursive /

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb


add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "Outputs"
add_wave /$TB/q

add_wave_divider "Expected Outputs"
add_wave /$TB/expected_q

add_wave_divider "Error Count"
add_wave -radix dec /$TB/error_count
add_wave -radix dec /$TB/bit_toggle_count

run all
# quit
