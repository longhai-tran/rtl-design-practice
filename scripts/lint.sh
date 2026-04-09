#!/bin/bash
# lint.sh — Run Verilator lint-only on all RTL files (mirrors CI/CD lint.yml).
# Usage:
#   ./scripts/lint.sh                              # Lint all RTL files (any working dir)
#   ./scripts/lint.sh 01_combinational/mux_2to1/  # Lint a specific directory (relative to repo root)

set -euo pipefail

# Resolve repo root from this script's location — works from ANY working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# If arg given: treat as relative to repo root; otherwise lint entire repo
SEARCH_DIR="${REPO_ROOT}/${1:-}"
SEARCH_DIR="${SEARCH_DIR%/}"   # strip trailing slash
[ -n "${1:-}" ] || SEARCH_DIR="$REPO_ROOT"

PASS=0
FAIL=0

echo "=============================================="
echo "  RTL Lint Check (verilator --lint-only -Wall)"
echo "  Repo : $REPO_ROOT"
echo "  Target: ${1:-(all)}"
echo "=============================================="
echo ""

# Check verilator is installed
if ! command -v verilator &> /dev/null; then
    echo "❌ ERROR: verilator is not installed or not in PATH."
    echo "   Install: https://verilator.org/guide/latest/install.html"
    exit 1
fi

# Find RTL files (exclude testbenches, same rule as lint.yml)
RTL_FILES=$(find "$SEARCH_DIR" \
    -name "*.v" \
    -not -name "*_tb.v" \
    -not -path "*/.git/*" \
    -not -path "*/sim/*" \
    | sort)

if [ -z "$RTL_FILES" ]; then
    echo "⚠️  No RTL files found in '$SEARCH_DIR'. Nothing to lint."
    exit 0
fi

for f in $RTL_FILES; do
    echo "→ Linting $f"
    if verilator --lint-only -Wall "$f" 2>&1; then
        echo "   ✅ PASS"
        PASS=$((PASS + 1))
    else
        echo "   ❌ FAIL"
        FAIL=$((FAIL + 1))
    fi
    echo ""
done

echo "=============================================="
echo "  Lint Results: ✅ $PASS passed | ❌ $FAIL failed"
echo "=============================================="

[ $FAIL -eq 0 ] || exit 1
