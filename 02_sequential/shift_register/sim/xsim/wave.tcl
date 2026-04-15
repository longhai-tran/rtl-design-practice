# XSIM waveform config for shift_register
log_wave -recursive /

add_wave_divider "System"
add_wave /shift_register_tb/clk
add_wave /shift_register_tb/rst_n

add_wave_divider "Inputs"
add_wave /shift_register_tb/din

add_wave_divider "Outputs"
add_wave /shift_register_tb/q

add_wave_divider "Expected Outputs"
add_wave /shift_register_tb/expected_q

add_wave -radix dec /shift_register_tb/error_count

run all
# quit
