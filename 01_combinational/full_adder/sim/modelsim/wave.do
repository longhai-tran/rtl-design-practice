# wave.do — ModelSim Waveform Configuration
# Module: full_adder
# Description: Waveform setup for full adder simulation
# ---------------------------------------------------------------------------

quietly WaveActivateNextPane {} 0

add wave -divider Inputs
add wave -noupdate -label "a"   -color Cyan   /full_adder_tb/a
add wave -noupdate -label "b"   -color Yellow /full_adder_tb/b
add wave -noupdate -label "cin" -color Orange /full_adder_tb/cin

add wave -divider Outputs
add wave -noupdate -label "sum"  -color Green /full_adder_tb/sum
add wave -noupdate -label "cout" -color Magenta /full_adder_tb/cout

add wave -divider DUT Ports
add wave -noupdate -label "dut.a"    /full_adder_tb/dut/a
add wave -noupdate -label "dut.b"    /full_adder_tb/dut/b
add wave -noupdate -label "dut.cin"  /full_adder_tb/dut/cin
add wave -noupdate -label "dut.sum"  /full_adder_tb/dut/sum
add wave -noupdate -label "dut.cout" /full_adder_tb/dut/cout

WaveRestoreZoom {0 ns} {100 ns}
configure wave -namecolwidth 150
configure wave -valuecolwidth 60
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

update

