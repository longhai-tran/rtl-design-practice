# =============================================================================
# Makefile — alu_4bit | ModelSim / Questa
# =============================================================================
TOP  = alu_4bit_tb
SRCS = ../../alu_4bit.v ../../alu_4bit_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/modelsim.mk
