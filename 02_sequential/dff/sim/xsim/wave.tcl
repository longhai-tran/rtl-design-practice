log_wave -recursive /

# Get the top-level testbench scope
# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "Inputs"
add_wave /$TB/d

add_wave_divider "Outputs"
add_wave /$TB/q

add_wave_divider "Expected Outputs"
add_wave /$TB/expected_q

run all
# quit
