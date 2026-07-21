# wave.do - ModelSim Waveform Configuration
# Module: async_fifo

set TB [file tail [file dirname [file dirname [pwd]]]]_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

add wave -divider {System}
add wave -noupdate /$TB/wr_clk
add wave -noupdate /$TB/rd_clk
add wave -noupdate /$TB/rst_n

add wave -divider {Write Side}
add wave -noupdate /$TB/wr_en
add wave -noupdate /$TB/din
add wave -noupdate /$TB/full

add wave -divider {Read Side}
add wave -noupdate /$TB/rd_en
add wave -noupdate /$TB/dout
add wave -noupdate /$TB/empty

add wave -divider {Model}
add wave -noupdate -radix dec /$TB/model_count
add wave -noupdate -radix dec /$TB/pass_count
add wave -noupdate -radix dec /$TB/fail_count

add wave -divider {DUT Internal}
add wave -noupdate -radix hex /$TB/dut/wr_bin
add wave -noupdate -radix hex /$TB/dut/wr_gray
add wave -noupdate -radix hex /$TB/dut/rd_bin
add wave -noupdate -radix hex /$TB/dut/rd_gray
add wave -noupdate -radix hex /$TB/dut/rd_gray_next
add wave -noupdate -radix hex /$TB/dut/rd_gray_sync2
add wave -noupdate -radix hex /$TB/dut/wr_gray_next
add wave -noupdate -radix hex /$TB/dut/wr_gray_sync2

WaveRestoreZoom {0 ns} {2 us}
configure wave -namecolwidth 180
configure wave -valuecolwidth 80
configure wave -justifyvalue left
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

update
