#!/usr/bin/env bash
# Test runner for 'log' command with -ps option.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-4-3" \
    --command "log" \
    --command-options "-ps 20" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
