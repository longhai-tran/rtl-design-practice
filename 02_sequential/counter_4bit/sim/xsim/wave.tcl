# XSIM waveform config for shift_register
log_wave -recursive /

add_wave_divider "System"
add_wave /counter_4bit_tb/clk
add_wave /counter_4bit_tb/rst_n

add_wave_divider "Outputs"
add_wave /counter_4bit_tb/q

add_wave_divider "Expected Outputs"
add_wave /counter_4bit_tb/expected_q

add_wave -radix dec /counter_4bit_tb/error_count
add_wave -radix dec /counter_4bit_tb/tc

run all
# quit
