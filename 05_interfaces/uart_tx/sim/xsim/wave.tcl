# wave.tcl - Vivado xsim waveform configuration for uart_tx

log_wave -recursive /
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "Request"
add_wave /$TB/tx_start
add_wave -radix hex /$TB/data_in

add_wave_divider "UART Output"
add_wave /$TB/tx
add_wave /$TB/tx_busy
add_wave /$TB/tx_done

add_wave_divider "DUT Internal"
add_wave -radix unsigned /$TB/dut/state
add_wave -radix unsigned /$TB/dut/baud_count
add_wave -radix unsigned /$TB/dut/bit_index
add_wave -radix hex /$TB/dut/data_latched

add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count

run all
