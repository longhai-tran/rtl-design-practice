log_wave -recursive /

# Get the top-level testbench scope
# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

add_wave /$TB/in
add_wave /$TB/en
add_wave /$TB/y
add_wave /$TB/expected_y
add_wave /$TB/error_count

run all
