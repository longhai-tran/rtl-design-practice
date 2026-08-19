# wave.do - ModelSim waveform configuration for simple_cpu

set TB simple_cpu_tb

quietly WaveActivateNextPane {} 0
configure wave -signalnamewidth 1

add wave -divider {System}
add wave -noupdate /$TB/clk
add wave -noupdate /$TB/rst_n

add wave -divider {Control}
add wave -noupdate /$TB/start
add wave -noupdate /$TB/busy
add wave -noupdate /$TB/halted
add wave -noupdate /$TB/done

add wave -divider {Program Counter}
add wave -noupdate -color cyan    -label {pc}     -radix unsigned /$TB/pc

add wave -divider {Instruction Pipeline}
add wave -noupdate -color yellow  -label {ir}     -radix hex      /$TB/dut/ir
add wave -noupdate -color yellow  -label {opcode} -radix unsigned /$TB/dut/opcode
add wave -noupdate -color yellow  -label {rd}     -radix unsigned /$TB/dut/rd
add wave -noupdate -color yellow  -label {rs}     -radix unsigned /$TB/dut/rs
add wave -noupdate -color yellow  -label {imm}    -radix hex      /$TB/dut/imm

add wave -divider {FSM State}
add wave -noupdate -color orange  -label {state}   -radix unsigned /$TB/dut/state
add wave -noupdate -color orange  -label {alu_out} -radix hex      /$TB/dut/alu_out

add wave -divider {Register File}
add wave -noupdate                -label {regs}  -radix hex      /$TB/dut/regs
add wave -noupdate                -label {acc}   -radix hex      /$TB/acc

add wave -divider {Data Memory Bus}
add wave -noupdate /$TB/data_we
add wave -noupdate -radix hex /$TB/data_addr
add wave -noupdate -radix hex /$TB/data_wdata
add wave -noupdate -radix hex /$TB/data_rdata

add wave -divider {Verification}
add wave -noupdate -radix decimal /$TB/pass_count
add wave -noupdate -radix decimal /$TB/fail_count

WaveRestoreZoom {0 ns} {400 ns}
configure wave -namecolwidth 190
configure wave -valuecolwidth 70
update
