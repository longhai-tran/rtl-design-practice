# =============================================================================
# Makefile — alu_4bit | Vivado xsim
# =============================================================================
TOP  = alu_4bit_tb
SRCS = ../../alu_4bit.v ../../alu_4bit_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/xsim.mk
