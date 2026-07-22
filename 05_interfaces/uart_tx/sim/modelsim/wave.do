# wave.do - ModelSim waveform configuration for uart_tx

set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

add wave -divider {Request}
add wave -noupdate /$TB/tx_start
add wave -noupdate -radix hex /$TB/data_in

add wave -divider {UART Output}
add wave -noupdate -color orange /$TB/tx
add wave -noupdate /$TB/tx_busy
add wave -noupdate /$TB/tx_done

add wave -divider {DUT Internal}
add wave -noupdate -radix unsigned /$TB/dut/state
add wave -noupdate -radix unsigned /$TB/dut/baud_count
add wave -noupdate -radix unsigned /$TB/dut/bit_index
add wave -noupdate -radix hex /$TB/dut/data_latched

add wave -divider {Verification}
add wave -noupdate -radix decimal /$TB/pass_count
add wave -noupdate -radix decimal /$TB/fail_count

WaveRestoreZoom {0 ns} {1200 ns}
configure wave -namecolwidth 170
configure wave -valuecolwidth 70
configure wave -justifyvalue left
update
