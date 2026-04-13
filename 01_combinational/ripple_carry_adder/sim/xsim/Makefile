# =============================================================================
# Makefile — ripple_carry_adder | Vivado xsim
# =============================================================================
TOP  = ripple_carry_adder_tb
SRCS = ../../ripple_carry_adder.v ../../ripple_carry_adder_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/xsim.mk
