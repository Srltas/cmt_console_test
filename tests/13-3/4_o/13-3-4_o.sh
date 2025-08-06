#!/usr/bin/env bash
# Test runner for 'script' command with -o option.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-3-4" \
    --command "script" \
    --command-options "-o _RESULT_DIR_" \
    --comparison-type "log"

