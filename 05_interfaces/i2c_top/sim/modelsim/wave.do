# wave.do - ModelSim waveform configuration for i2c_top

set TB i2c_top_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

add wave -divider {Command and Payloads}
add wave -noupdate /$TB/start
add wave -noupdate /$TB/rw
add wave -noupdate -radix hex /$TB/target_addr
add wave -noupdate -radix hex /$TB/master_tx_data
add wave -noupdate -radix hex /$TB/slave_tx_data
add wave -noupdate -radix hex /$TB/master_rx_data
add wave -noupdate -radix hex /$TB/slave_rx_data

add wave -divider {I2C Bus}
add wave -noupdate /$TB/scl
add wave -noupdate /$TB/sda
add wave -noupdate /$TB/dut/master_scl_drive_low
add wave -noupdate /$TB/dut/master_sda_drive_low
add wave -noupdate /$TB/dut/slave_sda_drive_low

add wave -divider {Status}
add wave -noupdate /$TB/master_busy
add wave -noupdate /$TB/master_done
add wave -noupdate /$TB/slave_busy
add wave -noupdate /$TB/slave_done
add wave -noupdate /$TB/slave_rx_valid
add wave -noupdate /$TB/ack_error

add wave -divider {Internal State}
add wave -noupdate -color yellow -label {master_state}     -radix unsigned /$TB/dut/u_master/state
add wave -noupdate -color yellow -label {master_bit_index} -radix unsigned /$TB/dut/u_master/bit_index
add wave -noupdate -color yellow -label {master_rx_shift}  -radix hex     /$TB/dut/u_master/rx_shift

add wave -noupdate -color cyan   -label {slave_state}      -radix unsigned /$TB/dut/u_slave/state
add wave -noupdate -color cyan   -label {slave_bit_index}  -radix unsigned /$TB/dut/u_slave/bit_index
add wave -noupdate -color cyan   -label {slave_rx_shift}   -radix hex     /$TB/dut/u_slave/rx_shift

add wave -divider {Verification}
add wave -noupdate -radix decimal /$TB/pass_count
add wave -noupdate -radix decimal /$TB/fail_count
add wave -noupdate -radix decimal /$TB/scl_rise_count
add wave -noupdate -radix decimal /$TB/start_count
add wave -noupdate -radix decimal /$TB/stop_count

WaveRestoreZoom {0 ns} {2500 ns}
configure wave -namecolwidth 190
configure wave -valuecolwidth 70
update
