# wave.do — ModelSim Waveform Configuration
# Module: carry_lookahead_adder
# Description: Waveform setup for carry_lookahead_adder simulation
# ---------------------------------------------------------------------------

quietly WaveActivateNextPane {} 0

add wave -divider Inputs
add wave -noupdate -label "a"   -color Cyan   /carry_lookahead_adder_tb/a
add wave -noupdate -label "b"   -color Yellow /carry_lookahead_adder_tb/b
add wave -noupdate -label "cin" -color Orange /carry_lookahead_adder_tb/cin

add wave -divider Outputs
add wave -noupdate -label "sum"  -color Green   /carry_lookahead_adder_tb/sum
add wave -noupdate -label "cout" -color Magenta /carry_lookahead_adder_tb/cout

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
