# wave.tcl - Vivado xsim waveform configuration for i2c_top

log_wave -recursive /
set TB i2c_top_tb

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "Command and Payloads"
add_wave /$TB/start
add_wave /$TB/rw
add_wave -radix hex /$TB/target_addr
add_wave -radix hex /$TB/master_tx_data
add_wave -radix hex /$TB/slave_tx_data
add_wave -radix hex /$TB/master_rx_data
add_wave -radix hex /$TB/slave_rx_data

add_wave_divider "I2C Bus"
add_wave /$TB/scl
add_wave /$TB/sda
add_wave /$TB/dut/master_scl_drive_low
add_wave /$TB/dut/master_sda_drive_low
add_wave /$TB/dut/slave_sda_drive_low

add_wave_divider "Status"
add_wave /$TB/master_busy
add_wave /$TB/master_done
add_wave /$TB/slave_busy
add_wave /$TB/slave_done
add_wave /$TB/slave_rx_valid
add_wave /$TB/ack_error

add_wave_divider "Internal State"
add_wave -name "master_state"     -color yellow -radix unsigned /$TB/dut/u_master/state
add_wave -name "master_bit_index" -color yellow -radix unsigned /$TB/dut/u_master/bit_index
add_wave -name "master_rx_shift"  -color yellow -radix hex     /$TB/dut/u_master/rx_shift

add_wave -name "slave_state"      -color cyan   -radix unsigned /$TB/dut/u_slave/state
add_wave -name "slave_bit_index"  -color cyan   -radix unsigned /$TB/dut/u_slave/bit_index
add_wave -name "slave_rx_shift"   -color cyan   -radix hex     /$TB/dut/u_slave/rx_shift

add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count
add_wave -radix dec /$TB/scl_rise_count
add_wave -radix dec /$TB/start_count
add_wave -radix dec /$TB/stop_count

run all
