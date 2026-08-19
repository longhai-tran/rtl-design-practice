# wave.do - ModelSim waveform configuration for uart_rx

set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

add wave -divider {UART Input}
add wave -noupdate -color orange /$TB/rx
add wave -noupdate /$TB/dut/rx_meta
add wave -noupdate /$TB/dut/rx_sync

add wave -divider {Receive Output}
add wave -noupdate -radix hex /$TB/data_out
add wave -noupdate /$TB/rx_busy
add wave -noupdate /$TB/rx_done_valid
add wave -noupdate /$TB/framing_error

add wave -divider {DUT Internal}
add wave -noupdate -radix unsigned /$TB/dut/state
add wave -noupdate -radix unsigned /$TB/dut/baud_count
add wave -noupdate -radix unsigned /$TB/dut/bit_index
add wave -noupdate -radix hex /$TB/dut/data_shift

add wave -divider {Verification}
add wave -noupdate -radix decimal /$TB/pass_count
add wave -noupdate -radix decimal /$TB/fail_count
add wave -noupdate -radix decimal /$TB/done_count
add wave -noupdate -radix decimal /$TB/error_count

WaveRestoreZoom {0 ns} {1200 ns}
configure wave -namecolwidth 170
configure wave -valuecolwidth 70
configure wave -justifyvalue left
update
