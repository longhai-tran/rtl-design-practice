log_wave -recursive /

# Get the top-level testbench scope
# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb
add_wave /$TB/d
add_wave /$TB/y
add_wave /$TB/valid
add_wave /$TB/expected_y
add_wave /$TB/expected_valid
run all
