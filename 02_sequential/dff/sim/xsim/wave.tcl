log_wave -recursive /

add_wave_divider "System"
add_wave /dff_tb/clk
add_wave /dff_tb/rst_n

add_wave_divider "Inputs"
add_wave /dff_tb/d

add_wave_divider "Outputs"
add_wave /dff_tb/q

add_wave_divider "Expected Outputs"
add_wave /dff_tb/expected_q

run all
# quit
