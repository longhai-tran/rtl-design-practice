# wave.tcl - Vivado xsim waveform configuration for spi_top

log_wave -recursive /
set TB spi_top_tb

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n
add_wave -radix unsigned /$TB/active_mode

add_wave_divider "Payloads"
add_wave /$TB/start_cmd
add_wave -radix hex /$TB/master_tx_data
add_wave -radix hex /$TB/slave_tx_data
add_wave -radix hex /$TB/active_master_rx
add_wave -radix hex /$TB/active_slave_rx

add_wave_divider "Active SPI Bus"
add_wave /$TB/active_cs_n
add_wave /$TB/active_sclk
add_wave /$TB/active_mosi
add_wave /$TB/active_miso

add_wave_divider "Endpoint Status"
add_wave /$TB/active_master_busy
add_wave /$TB/active_master_done
add_wave /$TB/active_slave_busy
add_wave /$TB/active_slave_done

add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count
add_wave -radix dec /$TB/master_done_count
add_wave -radix dec /$TB/slave_done_count
add_wave -radix dec /$TB/edge_count

run all
