set TOP "decoder_3to8_tb"
set SOURCES [list "../../decoder_3to8.v" "../../decoder_3to8_tb.v"]
set SNAP "sim_snapshot"

if {[catch {exec xvlog {*}$SOURCES >@stdout} err]} {
    puts "[ERROR] Compilation failed:\n$err"
    exit 1
}
if {[catch {exec xelab $TOP -s $SNAP >@stdout} err]} {
    puts "[ERROR] Elaboration failed:\n$err"
    exit 1
}
if {[catch {exec xsim $SNAP -R >@stdout} err]} {
    puts "[ERROR] Simulation failed:\n$err"
    exit 1
}
puts "[TCL] Simulation completed successfully!"
