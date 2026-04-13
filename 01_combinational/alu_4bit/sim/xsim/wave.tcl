log_wave -recursive /

add_wave_divider "Inputs"
add_wave /alu_4bit_tb/a
add_wave /alu_4bit_tb/b
add_wave /alu_4bit_tb/op

add_wave_divider "Outputs"
add_wave /alu_4bit_tb/y
add_wave /alu_4bit_tb/carry
add_wave /alu_4bit_tb/zero

add_wave_divider "Expected Outputs"
add_wave /alu_4bit_tb/expected_y
add_wave /alu_4bit_tb/expected_carry
add_wave /alu_4bit_tb/expected_zero

run all
