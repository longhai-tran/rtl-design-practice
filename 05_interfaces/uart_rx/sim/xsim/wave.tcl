# wave.tcl - Vivado xsim waveform configuration for uart_rx

log_wave -recursive /
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "UART Input"
add_wave /$TB/rx
add_wave /$TB/dut/rx_meta
add_wave /$TB/dut/rx_sync

add_wave_divider "Receive Output"
add_wave -radix hex /$TB/data_out
add_wave /$TB/rx_busy
add_wave /$TB/rx_done_valid
add_wave /$TB/framing_error

add_wave_divider "DUT Internal"
add_wave -radix unsigned /$TB/dut/state
add_wave -radix unsigned /$TB/dut/baud_count
add_wave -radix unsigned /$TB/dut/bit_index
add_wave -radix hex /$TB/dut/data_shift

add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count
add_wave -radix dec /$TB/valid_count
add_wave -radix dec /$TB/error_count

run all
