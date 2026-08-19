# wave.do - ModelSim waveform configuration for spi_top

set TB spi_top_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n
add wave -noupdate -radix unsigned /$TB/active_mode

add wave -divider {Payloads}
add wave -noupdate /$TB/start_cmd
add wave -noupdate -radix hex /$TB/master_tx_data
add wave -noupdate -radix hex /$TB/slave_tx_data
add wave -noupdate -radix hex /$TB/active_master_rx
add wave -noupdate -radix hex /$TB/active_slave_rx

add wave -divider {Active SPI Bus}
add wave -noupdate /$TB/active_cs_n
add wave -noupdate /$TB/active_sclk
add wave -noupdate /$TB/active_mosi
add wave -noupdate /$TB/active_miso

add wave -divider {Endpoint Status}
add wave -noupdate /$TB/active_master_busy
add wave -noupdate /$TB/active_master_done
add wave -noupdate /$TB/active_slave_busy
add wave -noupdate /$TB/active_slave_done

add wave -divider {Mode 0 Internals}
add wave -noupdate -radix unsigned /$TB/dut0/u_master/state
add wave -noupdate -radix unsigned /$TB/dut0/u_master/bit_index
add wave -noupdate -radix unsigned /$TB/dut0/u_master/div_count
add wave -noupdate -radix hex /$TB/dut0/u_slave/rx_shift
add wave -noupdate -radix unsigned /$TB/dut0/u_slave/bit_index

add wave -divider {Verification}
add wave -noupdate -radix decimal /$TB/pass_count
add wave -noupdate -radix decimal /$TB/fail_count
add wave -noupdate -radix decimal /$TB/master_done_count
add wave -noupdate -radix decimal /$TB/slave_done_count
add wave -noupdate -radix decimal /$TB/edge_count

WaveRestoreZoom {0 ns} {1500 ns}
configure wave -namecolwidth 190
configure wave -valuecolwidth 70
configure wave -justifyvalue left
update
