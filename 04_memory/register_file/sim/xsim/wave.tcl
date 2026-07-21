# wave.tcl - Vivado xsim Waveform Configuration
# Module: register_file
# ---------------------------------------------------------------------------
# HOW TO USE:
#   Called automatically by: xsim <SNAP> -gui -tclbatch wave.tcl
# ---------------------------------------------------------------------------

log_wave -recursive /

# Auto-detect testbench name from directory structure
set TB [file tail [file dirname [file dirname [pwd]]]]_tb

# ---------------------------------------------------------------------------
# --- System signals ---
# ---------------------------------------------------------------------------
add_wave_divider "System"
add_wave /$TB/clk
add_wave /$TB/rst_n

# ---------------------------------------------------------------------------
# --- Inputs ---
# ---------------------------------------------------------------------------
add_wave_divider "Inputs"
add_wave /$TB/we
add_wave -radix unsigned /$TB/waddr
add_wave -radix hex /$TB/wdata
add_wave -radix unsigned /$TB/raddr1
add_wave -radix unsigned /$TB/raddr2

# ---------------------------------------------------------------------------
# --- DUT signals ---
# ---------------------------------------------------------------------------
add_wave_divider "DUT"
add_wave -radix hex /$TB/dut/regs

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add_wave_divider "Outputs"
add_wave -radix hex /$TB/rdata1
add_wave -radix hex /$TB/rdata2

# ---------------------------------------------------------------------------
# --- Verification ---
# ---------------------------------------------------------------------------
add_wave_divider "Verification"
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count

run all
