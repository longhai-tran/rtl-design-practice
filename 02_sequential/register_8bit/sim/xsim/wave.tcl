# XSIM waveform config for register_8bit
log_wave -recursive /

add_wave_divider "System"
add_wave /register_8bit_tb/clk
add_wave /register_8bit_tb/rst_n

add_wave_divider "Inputs"
add_wave /register_8bit_tb/d

add_wave_divider "Outputs"
add_wave /register_8bit_tb/q

add_wave_divider "Expected Outputs"
add_wave /register_8bit_tb/expected_q

add_wave -radix dec /register_8bit_tb/error_count

run all
# quit
