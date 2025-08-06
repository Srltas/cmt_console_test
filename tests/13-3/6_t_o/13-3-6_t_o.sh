#!/usr/bin/env bash
# Test runner for 'script' command with -t and -o options.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-3-6" \
    --command "script" \
    --command-options "-t file_target -o _RESULT_DIR_" \
    --comparison-type "log"

