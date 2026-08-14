# wave.tcl - Vivado xsim waveform configuration for simple_cpu

log_wave -recursive /
set TB simple_cpu_tb

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "Control"
add_wave /$TB/start
add_wave /$TB/busy
add_wave /$TB/halted
add_wave /$TB/done

add_wave_divider "Program Counter"
add_wave -name "pc" -color cyan -radix unsigned /$TB/pc

add_wave_divider "Instruction Pipeline"
add_wave -name "ir"     -color yellow -radix hex      /$TB/dut/ir
add_wave -name "opcode" -color yellow -radix unsigned /$TB/dut/opcode
add_wave -name "rd"     -color yellow -radix unsigned /$TB/dut/rd
add_wave -name "rs"     -color yellow -radix unsigned /$TB/dut/rs
add_wave -name "imm"    -color yellow -radix hex      /$TB/dut/imm

add_wave_divider "FSM State"
add_wave -name "state"   -color orange -radix unsigned /$TB/dut/state
add_wave -name "alu_out" -color orange -radix hex      /$TB/dut/alu_out

add_wave_divider "Register File"
add_wave -name "regs" -radix hex /$TB/dut/regs
add_wave -name "acc"  -radix hex /$TB/acc

add_wave_divider "Data Memory Bus"
add_wave /$TB/data_we
add_wave -radix hex /$TB/data_addr
add_wave -radix hex /$TB/data_wdata
add_wave -radix hex /$TB/data_rdata

add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count

run all
