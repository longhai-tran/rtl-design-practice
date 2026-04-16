# XSIM waveform config for dff_async_reset
log_wave -recursive /

# Get the top-level testbench scope
set tbs [get_scopes -filter {NAME =~ "*tb*"}]
if {[llength $tbs] == 0} { error "Testbench scope not found." }
set TB [lindex $tbs 0]

add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

add_wave_divider "Inputs"
add_wave /$TB/d

add_wave_divider "Outputs"
add_wave /$TB/q

add_wave_divider "Expected Outputs"
add_wave /$TB/expected_q

add_wave -radix dec /$TB/error_count

run all
# quit
