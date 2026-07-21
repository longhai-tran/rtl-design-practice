# =============================================================================
# Makefile — rtl-design-practice (Root)
# =============================================================================
# Run from the project root to manage all modules.
#
# TARGETS:
#   make clean         — Remove all sim artifacts in every module
#   make clean-dry     — Preview: list what will be deleted, without deleting
#   make clean-<mod>   — Remove artifacts of a specific module
# =============================================================================

SHELL := bash

MOD ?=

# Automatically find all sim/modelsim and sim/xsim directories
MODELSIM_DIRS := $(shell find 01_combinational 02_sequential 03_fsm 04_memory 05_interfaces \
                          -type d -name "modelsim" 2>/dev/null)
XSIM_DIRS     := $(shell find 01_combinational 02_sequential 03_fsm 04_memory 05_interfaces \
                          -type d -name "xsim" 2>/dev/null)

.PHONY: clean clean-dry clean-modelsim clean-xsim lint help

clean: ## Remove all sim artifacts in the entire project (ModelSim + xsim)
	@bash scripts/clean.sh

clean-dry: ## Preview what will be deleted, without actually deleting
	@bash scripts/clean.sh --dry-run

clean-modelsim: ## Only remove ModelSim / Questa artifacts
	@echo "Cleaning ModelSim artifacts..."
	@for d in $(MODELSIM_DIRS); do \
	    echo "  -> $$d"; \
	    $(MAKE) -C $$d clean --no-print-directory 2>/dev/null || true; \
	done
	@echo "Done."

clean-xsim: ## Only remove Vivado xsim artifacts
	@echo "Cleaning Vivado xsim artifacts..."
	@for d in $(XSIM_DIRS); do \
	    echo "  -> $$d"; \
	    $(MAKE) -C $$d clean --no-print-directory 2>/dev/null || true; \
	done
	@echo "Done."

lint: ## Run Verilator lint on all RTL  (use MOD=<path> to lint one module)
	@bash scripts/lint.sh $(MOD)

# -----------------------------------------------------------------------------
# help — List all available targets (self-documenting via ## annotations)
# -----------------------------------------------------------------------------
help: ## Show this help message
	@printf "\n\033[1;36m  rtl-design-practice — Root Makefile\033[0m\n"
	@printf "  %s\n" "$(shell printf '%.0s─' {1..44})"
	@awk 'BEGIN {FS = ":.*##"} \
	     /^[a-zA-Z_-]+:.*?##/ { \
	         printf "  \033[1;32m%-18s\033[0m %s\n", $$1, $$2 \
	     }' $(MAKEFILE_LIST)
	@printf "\n  \033[1;36mVariables\033[0m  \033[90m(override on the command line if needed)\033[0m\n"
	@printf "  \033[33mMOD\033[0m = \033[90m<path>   Restrict lint to a specific module directory\033[0m\n"
	@printf "\n"
