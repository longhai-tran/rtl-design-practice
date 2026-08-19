add_wave /wishbone_top_tb/clk
add_wave /wishbone_top_tb/rst_n
add_wave /wishbone_top_tb/cmd_valid
add_wave /wishbone_top_tb/cmd_ready
add_wave /wishbone_top_tb/cmd_write
add_wave -radix hex /wishbone_top_tb/cmd_addr
add_wave -radix hex /wishbone_top_tb/cmd_wdata
add_wave -radix hex /wishbone_top_tb/read_data
add_wave /wishbone_top_tb/busy
add_wave /wishbone_top_tb/done
add_wave /wishbone_top_tb/error
add_wave /wishbone_top_tb/wb_cyc
add_wave /wishbone_top_tb/wb_stb
add_wave /wishbone_top_tb/wb_we
add_wave -radix hex /wishbone_top_tb/wb_addr
add_wave -radix hex /wishbone_top_tb/wb_sel
add_wave -radix hex /wishbone_top_tb/wb_wdata
add_wave -radix hex /wishbone_top_tb/wb_rdata
add_wave /wishbone_top_tb/wb_ack
add_wave /wishbone_top_tb/wb_err
add_wave -radix hex /wishbone_top_tb/slave0_control
add_wave -radix hex /wishbone_top_tb/slave1_control
add_wave -radix dec /wishbone_top_tb/pass_count
add_wave -radix dec /wishbone_top_tb/fail_count
run all
