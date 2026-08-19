set TB wishbone_top_tb
quietly WaveActivateNextPane {} 0
add wave -divider {Command Interface}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n
add wave -noupdate /$TB/cmd_valid
add wave -noupdate /$TB/cmd_ready
add wave -noupdate /$TB/cmd_write
add wave -noupdate -radix hex /$TB/cmd_addr
add wave -noupdate -radix hex /$TB/cmd_wdata
add wave -noupdate -radix hex /$TB/read_data
add wave -noupdate /$TB/busy
add wave -noupdate /$TB/done
add wave -noupdate /$TB/error
add wave -divider {Wishbone Bus}
add wave -noupdate /$TB/wb_cyc
add wave -noupdate /$TB/wb_stb
add wave -noupdate /$TB/wb_we
add wave -noupdate -radix hex /$TB/wb_addr
add wave -noupdate -radix hex /$TB/wb_sel
add wave -noupdate -radix hex /$TB/wb_wdata
add wave -noupdate -radix hex /$TB/wb_rdata
add wave -noupdate /$TB/wb_ack
add wave -noupdate /$TB/wb_err
add wave -divider {Slave Registers}
add wave -noupdate -radix hex /$TB/slave0_control
add wave -noupdate -radix hex /$TB/slave0_data
add wave -noupdate -radix hex /$TB/slave0_scratch
add wave -noupdate -radix hex /$TB/slave1_control
add wave -noupdate -radix hex /$TB/slave1_data
add wave -noupdate -radix hex /$TB/slave1_scratch
add wave -divider {Scoreboard}
add wave -noupdate -radix decimal /$TB/pass_count
add wave -noupdate -radix decimal /$TB/fail_count
add wave -noupdate -radix decimal /$TB/done_count
WaveRestoreZoom {0 ns} {2000 ns}
configure wave -namecolwidth 190
configure wave -valuecolwidth 90
update
