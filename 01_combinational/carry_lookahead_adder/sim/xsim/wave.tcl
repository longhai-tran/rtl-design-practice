# wave.tcl — Vivado xsim Waveform Configuration
# Module: carry_lookahead_adder
# ---------------------------------------------------------------------------
# HOW TO USE:
#   Called automatically by: xsim <SNAP> -gui -tclbatch wave.tcl
# ---------------------------------------------------------------------------

log_wave -recursive /
add_wave /
run all
