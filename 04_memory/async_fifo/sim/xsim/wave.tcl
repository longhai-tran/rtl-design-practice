# wave.tcl - Vivado xsim Waveform Configuration
# Module: async_fifo

log_wave -recursive /
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

add_wave_divider "System"
add_wave /$TB/wr_clk
add_wave /$TB/rd_clk
add_wave /$TB/rst_n

add_wave_divider "Write Side"
add_wave /$TB/wr_en
add_wave -radix unsigned /$TB/din
add_wave /$TB/full

add_wave_divider "Read Side"
add_wave /$TB/rd_en
add_wave -radix unsigned /$TB/dout
add_wave /$TB/empty

add_wave_divider "Model"
add_wave -radix dec /$TB/model_count
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count

add_wave_divider "DUT Internal"
add_wave -radix hex /$TB/dut/wr_bin
add_wave -radix hex /$TB/dut/wr_gray
add_wave -radix hex /$TB/dut/rd_bin
add_wave -radix hex /$TB/dut/rd_gray
add_wave -radix hex /$TB/dut/rd_gray_next
add_wave -radix hex /$TB/dut/rd_gray_sync2
add_wave -radix hex /$TB/dut/wr_gray_next
add_wave -radix hex /$TB/dut/wr_gray_sync2


run all
