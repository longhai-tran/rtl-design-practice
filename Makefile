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

# Automatically find all sim/modelsim and sim/xsim directories
MODELSIM_DIRS := $(shell find 01_combinational 02_sequential 03_fsm 04_memory 05_interfaces \
                          -type d -name "modelsim" 2>/dev/null)
XSIM_DIRS     := $(shell find 01_combinational 02_sequential 03_fsm 04_memory 05_interfaces \
                          -type d -name "xsim" 2>/dev/null)

.PHONY: clean clean-dry clean-modelsim clean-xsim help

# -----------------------------------------------------------------------------
# clean — Remove all artifacts in the entire project (fastest way)
# -----------------------------------------------------------------------------
clean:
	@bash scripts/clean.sh

# -----------------------------------------------------------------------------
# clean-dry — Preview what will be deleted, not actually deleted.
# -----------------------------------------------------------------------------
clean-dry:
	@bash scripts/clean.sh --dry-run

# -----------------------------------------------------------------------------
# clean-modelsim — Only remove ModelSim/Questa artifacts
# -----------------------------------------------------------------------------
clean-modelsim:
	@echo "Cleaning ModelSim artifacts..."
	@for d in $(MODELSIM_DIRS); do \
	    echo "  -> $$d"; \
	    $(MAKE) -C $$d clean --no-print-directory 2>/dev/null || true; \
	done
	@echo "Done."

# -----------------------------------------------------------------------------
# clean-xsim — Only remove Vivado xsim artifacts
# -----------------------------------------------------------------------------
clean-xsim:
	@echo "Cleaning Vivado xsim artifacts..."
	@for d in $(XSIM_DIRS); do \
	    echo "  -> $$d"; \
	    $(MAKE) -C $$d clean --no-print-directory 2>/dev/null || true; \
	done
	@echo "Done."

# -----------------------------------------------------------------------------
# help — Display list of targets
# -----------------------------------------------------------------------------
help:
	@echo ""
	@echo "  rtl-design-practice — Root Makefile"
	@echo "  ====================================="
	@echo "  make clean           Remove all sim artifacts (ModelSim + xsim)"
	@echo "  make clean-dry       Preview: list what will be deleted"
	@echo "  make clean-modelsim  Only remove ModelSim/Questa artifacts"
	@echo "  make clean-xsim      Only remove Vivado xsim artifacts"
	@echo ""
