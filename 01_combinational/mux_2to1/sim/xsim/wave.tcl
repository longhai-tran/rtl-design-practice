# Tcl script to execute when xsim opens in GUI mode
# Log all signals
log_wave -recursive /
# Add all signals in the current scope (typically top level tb) to the wave window
add_wave /
# Run the simulation so the waveform is populated
run all
