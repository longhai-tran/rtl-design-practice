log_wave -recursive /

add_wave /decoder_3to8_tb/in
add_wave /decoder_3to8_tb/en
add_wave /decoder_3to8_tb/y
add_wave /decoder_3to8_tb/expected_y
add_wave /decoder_3to8_tb/error_count

run all
