# wave.tcl - Vivado xsim Waveform Configuration
# Module: sync_fifo
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
add_wave /$TB/wr_en
add_wave /$TB/rd_en
add_wave -radix hex /$TB/din

# ---------------------------------------------------------------------------
# --- DUT signals ---
# ---------------------------------------------------------------------------
add_wave_divider "DUT"
add_wave -radix unsigned /$TB/dut/wr_ptr
add_wave -radix unsigned /$TB/dut/rd_ptr
add_wave -radix unsigned /$TB/level
add_wave /$TB/full
add_wave /$TB/empty
add_wave -radix hex /$TB/dut/mem

# ---------------------------------------------------------------------------
# --- Outputs ---
# ---------------------------------------------------------------------------
add_wave_divider "Outputs"
add_wave -radix hex /$TB/dout

# ---------------------------------------------------------------------------
# --- Verification ---
# ---------------------------------------------------------------------------
add_wave_divider "Verification"
add_wave -radix dec /$TB/model_count
add_wave -radix dec /$TB/pass_count
add_wave -radix dec /$TB/fail_count

run all
