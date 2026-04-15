# =============================================================================
# Makefile — shift_register | Vivado xsim
# =============================================================================
TOP  = counter_4bit_tb
SRCS = ../../counter_4bit.v ../../counter_4bit_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/xsim.mk
