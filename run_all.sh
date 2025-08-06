#!/usr/bin/env bash
###############################################################################
# run_all.sh - Test orchestrator for all CMT commands
#
# USAGE:
#   Run all tests:
#     ./run_all.sh
#   Run a single specific test or directory:
#     ./run_all.sh -t tests/13-2/3_oracle/dump/110U/ss
#   Rerun failed tests from a log file:
#     ./run_all.sh -f results/YYYY.../failed_targets.log
###############################################################################
set -euo pipefail

# ───────────────────────────── Paths & Init ──────────────────────────────────
BASE_PATH="$(cd "$(dirname "$0")" && pwd)"
TEST_ROOT="$BASE_PATH/tests"
NOW="$(date +%Y%m%d_%H%M%S)"
RESULT_ROOT="$BASE_PATH/results/$NOW"
LOG_FILE="$BASE_PATH/log/run_$NOW.log"

mkdir -p "$(dirname "$LOG_FILE")" "$RESULT_ROOT"

export BASE_PATH TEST_ROOT CMT_HOME RESULT_ROOT LOG_FILE
export CMT_HOME="$BASE_PATH/build/"

source "$BASE_PATH/lib/common.sh"
log "======== Overall Test Run Started (Results in: $RESULT_ROOT) ========"

# ────────────────────────── Argument Parsing ─────────────────────────────────
TARGET_PATHS=()
TARGET_FILE=""

while getopts "t:f:" opt; do
  case $opt in
    t) TARGET_PATHS+=("$OPTARG") ;;
    f) TARGET_FILE="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

if [[ ${#TARGET_PATHS[@]} -gt 0 && -n "$TARGET_FILE" ]]; then
    echo "[ERROR] Options -t and -f are mutually exclusive." >&2
    exit 1
fi

if [[ -n "$TARGET_FILE" ]]; then
    if [[ ! -f "$TARGET_FILE" ]]; then
        echo "[ERROR] File not found: $TARGET_FILE" >&2
        exit 1
    fi
    mapfile -t TARGET_PATHS < <(grep . "$TARGET_FILE")
fi

# ────────────────────────── Test Discovery ───────────────────────────────────
declare -a TEST_SCRIPTS
if [[ ${#TARGET_PATHS[@]} -eq 0 ]]; then
    log "No target specified. Discovering all test scripts."
    mapfile -d '' TEST_SCRIPTS < <(find "$TEST_ROOT" -type f -name "*.sh" -print0 | sort -z)
else
    log "Target(s) specified: ${TARGET_PATHS[*]}"
    declare -a find_paths
    for p in "${TARGET_PATHS[@]}"; do
        # If the path doesn't start with TEST_ROOT, prepend it.
        if [[ "$p" != "$TEST_ROOT"* ]]; then
            find_paths+=("$TEST_ROOT/$p")
        else
            find_paths+=("$p")
        fi
    done
    mapfile -d '' TEST_SCRIPTS < <(find "${find_paths[@]}" -type f -name "*.sh" -print0 | sort -z)
fi

# ────────────────────────── Test Execution ───────────────────────────────────
FAIL_COUNT=0
export TOTAL_CASES=${#TEST_SCRIPTS[@]}
export FAILED_TARGETS_LOG="$RESULT_ROOT/failed_targets.log"

log "Discovered $TOTAL_CASES test case(s) to run."
echo "Found $TOTAL_CASES test case(s). Starting execution..."
echo "----------------------------------------------------------------------"

export CURRENT_CASE_INDEX=0
for SCRIPT in "${TEST_SCRIPTS[@]}"; do
    CURRENT_CASE_INDEX=$((CURRENT_CASE_INDEX + 1))
    export CURRENT_CASE_INDEX

    TEST_CASE_DIR=$(dirname "$SCRIPT")
    
    if "$SCRIPT"; then
        : # Case result printed by the test.sh script itself
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "${TEST_CASE_DIR#$TEST_ROOT/}" >> "$FAILED_TARGETS_LOG"
    fi
done

echo "----------------------------------------------------------------------"

# ────────────────────────── Final Summary ───────────────────────────────────
log "======== Overall Test Run Finished ========"
echo
FAIL_COUNT=0
if [[ -f "$FAILED_TARGETS_LOG" ]]; then
    FAIL_COUNT=$(wc -l < "$FAILED_TARGETS_LOG")
fi
PASSED_COUNT=$((TOTAL_CASES - FAIL_COUNT))
echo "=== Final Test Summary ==="
echo " Total Cases: $TOTAL_CASES  Passed: $PASSED_COUNT  Failed: $FAIL_COUNT"
echo " Results in: $RESULT_ROOT"
echo " Debug log : $LOG_FILE"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo " List of failed targets saved to: $FAILED_TARGETS_LOG"
fi

(( FAIL_COUNT == 0 )) && exit 0 || exit 1
