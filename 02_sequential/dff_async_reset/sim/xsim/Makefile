# =============================================================================
# Makefile — dff | Vivado xsim
# =============================================================================
TOP  = dff_async_reset_tb
SRCS = ../../dff_async_reset.v ../../dff_async_reset_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/xsim.mk
