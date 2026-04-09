# wave.do — ModelSim Waveform Configuration
# Module: ripple_carry_adder
# Description: Waveform setup for ripple_carry_adder simulation
# ---------------------------------------------------------------------------

quietly WaveActivateNextPane {} 0

add wave -divider Inputs
add wave -noupdate -label "a"   -color Cyan   /ripple_carry_adder_tb/a
add wave -noupdate -label "b"   -color Yellow /ripple_carry_adder_tb/b
add wave -noupdate -label "cin" -color Orange /ripple_carry_adder_tb/cin

add wave -divider Outputs
add wave -noupdate -label "sum"  -color Green   /ripple_carry_adder_tb/sum
add wave -noupdate -label "cout" -color Magenta /ripple_carry_adder_tb/cout

add wave -divider "DUT Ports"
add wave -noupdate -label "dut.a"    /ripple_carry_adder_tb/dut/a
add wave -noupdate -label "dut.b"    /ripple_carry_adder_tb/dut/b
add wave -noupdate -label "dut.cin"  /ripple_carry_adder_tb/dut/cin
add wave -noupdate -label "dut.sum"  /ripple_carry_adder_tb/dut/sum
add wave -noupdate -label "dut.cout" /ripple_carry_adder_tb/dut/cout

WaveRestoreZoom {0 ns} {5200 ns}
configure wave -namecolwidth 150
configure wave -valuecolwidth 60
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

update

