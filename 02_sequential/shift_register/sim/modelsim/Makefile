# =============================================================================
# Makefile — shift_register | ModelSim / Questa
# =============================================================================
TOP  = shift_register_tb
SRCS = ../../shift_register.v ../../shift_register_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/modelsim.mk
