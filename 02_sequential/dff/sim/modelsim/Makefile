# =============================================================================
# Makefile — dff | ModelSim / Questa
# =============================================================================
TOP  = dff_tb
SRCS = ../../dff.v ../../dff_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/modelsim.mk
