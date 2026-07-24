# wave.do - ModelSim waveform configuration for uart_top

set TB uart_top_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

add wave -divider {TX Request and Status}
add wave -noupdate /$TB/tx_start
add wave -noupdate -radix hex /$TB/tx_data
add wave -noupdate /$TB/tx
add wave -noupdate /$TB/tx_busy
add wave -noupdate /$TB/tx_done

add wave -divider {RX Input and Status}
add wave -noupdate /$TB/loopback_enable
add wave -noupdate /$TB/rx
add wave -noupdate -radix hex /$TB/rx_data
add wave -noupdate /$TB/rx_busy
add wave -noupdate /$TB/rx_done_valid
add wave -noupdate /$TB/framing_error

add wave -divider {TX Internal}
add wave -noupdate -radix unsigned /$TB/dut/u_tx/state
add wave -noupdate -radix unsigned /$TB/dut/u_tx/baud_count
add wave -noupdate -radix unsigned /$TB/dut/u_tx/bit_index
add wave -noupdate -radix hex /$TB/dut/u_tx/data_latched

add wave -divider {RX Internal}
add wave -noupdate /$TB/dut/u_rx/rx_meta
add wave -noupdate /$TB/dut/u_rx/rx_sync
add wave -noupdate -radix unsigned /$TB/dut/u_rx/state
add wave -noupdate -radix unsigned /$TB/dut/u_rx/baud_count
add wave -noupdate -radix unsigned /$TB/dut/u_rx/bit_index
add wave -noupdate -radix hex /$TB/dut/u_rx/data_shift

add wave -divider {Verification}
add wave -noupdate -radix decimal /$TB/pass_count
add wave -noupdate -radix decimal /$TB/fail_count
add wave -noupdate -radix decimal /$TB/tx_done_count
add wave -noupdate -radix decimal /$TB/rx_valid_count
add wave -noupdate -radix decimal /$TB/error_count

WaveRestoreZoom {0 ns} {1500 ns}
configure wave -namecolwidth 180
configure wave -valuecolwidth 70
configure wave -justifyvalue left
update
