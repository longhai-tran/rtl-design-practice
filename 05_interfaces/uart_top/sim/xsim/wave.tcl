# wave.tcl - Vivado xsim waveform configuration for uart_top

log_wave -recursive /
set TB uart_top_tb

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "TX Request and Status"
add_wave /$TB/tx_start
add_wave -radix hex /$TB/tx_data
add_wave /$TB/tx
add_wave /$TB/tx_busy
add_wave /$TB/tx_done

add_wave_divider "RX Input and Status"
add_wave /$TB/loopback_enable
add_wave /$TB/rx
add_wave -radix hex /$TB/rx_data
add_wave /$TB/rx_busy
add_wave /$TB/rx_done_valid
add_wave /$TB/framing_error

add_wave_divider "TX Internal"
add_wave -radix unsigned /$TB/dut/u_tx/state
add_wave -radix unsigned /$TB/dut/u_tx/baud_count
add_wave -radix unsigned /$TB/dut/u_tx/bit_index
add_wave -radix hex /$TB/dut/u_tx/data_latched

add_wave_divider "RX Internal"
add_wave /$TB/dut/u_rx/rx_meta
add_wave /$TB/dut/u_rx/rx_sync
add_wave -radix unsigned /$TB/dut/u_rx/state
add_wave -radix unsigned /$TB/dut/u_rx/baud_count
add_wave -radix unsigned /$TB/dut/u_rx/bit_index
add_wave -radix hex /$TB/dut/u_rx/data_shift

add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count
add_wave -radix dec /$TB/tx_done_count
add_wave -radix dec /$TB/rx_valid_count
add_wave -radix dec /$TB/error_count

run all
