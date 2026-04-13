# =============================================================================
# Makefile — carry_lookahead_adder | Vivado xsim
# =============================================================================
TOP  = carry_lookahead_adder_tb
SRCS = ../../carry_lookahead_adder.v ../../carry_lookahead_adder_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/xsim.mk
