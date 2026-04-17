log_wave -recursive /

# Get the top-level testbench scope
# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

add_wave_divider "Inputs"
add_wave /$TB/a
add_wave /$TB/b
add_wave /$TB/op

add_wave_divider "Outputs"
add_wave /$TB/y
add_wave /$TB/carry
add_wave /$TB/zero

add_wave_divider "Expected Outputs"
add_wave /$TB/expected_y
add_wave /$TB/expected_carry
add_wave /$TB/expected_zero

run all
