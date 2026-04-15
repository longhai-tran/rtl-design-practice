log_wave -recursive /

# Get the top-level testbench scope
set tbs [get_scopes -filter {NAME =~ "*tb*"}]
if {[llength $tbs] == 0} { error "Testbench scope not found." }
set TB [lindex $tbs 0]

add_wave /$TB/in
add_wave /$TB/en
add_wave /$TB/y
add_wave /$TB/expected_y
add_wave /$TB/error_count

run all
