# =============================================================================
# Makefile — dff | Vivado xsim
# =============================================================================
TOP  = register_8bit_tb
SRCS = ../../register_8bit.v ../../register_8bit_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/xsim.mk
