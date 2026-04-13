# =============================================================================
# Makefile — full_adder | ModelSim / Questa
# =============================================================================
TOP  = full_adder_tb
SRCS = ../../full_adder.v ../../full_adder_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/modelsim.mk
