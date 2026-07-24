# =============================================================================
# Makefile | ModelSim / Questa
# =============================================================================

TOP  := uart_top_tb
SRCS := ../../../uart_tx/uart_tx.v ../../../uart_rx/uart_rx.v \
        ../../uart_top.v ../../uart_top_tb.v

ROOT := $(shell git -C $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
include $(ROOT)/scripts/modelsim.mk
