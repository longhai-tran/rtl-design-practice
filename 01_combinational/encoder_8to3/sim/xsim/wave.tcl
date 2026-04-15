log_wave -recursive /

# Get the top-level testbench scope
set tbs [get_scopes -filter {NAME =~ "*tb*"}]
if {[llength $tbs] == 0} { error "Testbench scope not found." }
set TB [lindex $tbs 0]
add_wave /$TB/d
add_wave /$TB/y
add_wave /$TB/valid
add_wave /$TB/expected_y
add_wave /$TB/expected_valid
run all
