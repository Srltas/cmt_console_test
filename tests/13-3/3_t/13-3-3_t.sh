#!/usr/bin/env bash
# Test runner for 'script' command with -t option.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-3-3" \
    --command "script" \
    --command-options "-t file_target" \
    --comparison-type "log"
