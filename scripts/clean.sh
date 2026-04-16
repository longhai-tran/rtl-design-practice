#!/bin/bash
# =============================================================================
# scripts/clean.sh — Global simulation artifact cleaner
# =============================================================================
# Delete all ModelSim and Vivado xsim artifacts in all modules.
#
# USAGE (run from root project):
#   bash scripts/clean.sh             # Delete all artifacts
#   bash scripts/clean.sh --dry-run   # Preview: list only, no deletion
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

DRY_RUN=false
if [[ "$1" == "--dry-run" || "$1" == "-n" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}[DRY-RUN] Preview mode — nothing will be deleted.${NC}"
fi

echo -e "${CYAN}Scanning for simulation artifacts...${NC}"

# Hàm tiện ích: xóa hoặc preview
do_rm() {
    local target="$1"
    if $DRY_RUN; then
        echo "  [would delete] $target"
    else
        rm -rf "$target"
    fi
}

count=0

# --- Vivado xsim artifacts ---
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "xsim.dir"      -type d  -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name ".Xil"          -type d  -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "webtalk"       -type d  -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "*.pb"                   -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "*.jou"                  -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "*.wdb"                  -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "dfx_runtime.txt"        -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "vivado*.str"            -print0 2>/dev/null)

# --- ModelSim / QuestaSim artifacts ---
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "work"          -type d  -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "transcript"             -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "*.wlf"                  -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "modelsim.ini"           -print0 2>/dev/null)

# --- Shared (cả hai simulator) ---
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "*.log"  ! -name "README*" -print0 2>/dev/null)
while IFS= read -r -d '' f; do do_rm "$f"; ((count++)); done < <(find . -name "*.vcd"                  -print0 2>/dev/null)

if $DRY_RUN; then
    echo -e "${YELLOW}[DRY-RUN] Would remove $count items. Run without --dry-run to delete.${NC}"
else
    echo -e "${GREEN}Done! Removed $count items. Working tree is clean.${NC}"
fi
