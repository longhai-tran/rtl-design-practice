# XSIM waveform config for dff_async_reset
log_wave -recursive /

add_wave_divider "System"
add_wave /dff_async_reset_tb/clk
add_wave /dff_async_reset_tb/rst_n

add_wave_divider "Inputs"
add_wave /dff_async_reset_tb/d

add_wave_divider "Outputs"
add_wave /dff_async_reset_tb/q

add_wave_divider "Expected Outputs"
add_wave /dff_async_reset_tb/expected_q

add_wave -radix dec /dff_async_reset_tb/error_count

run all
# quit
