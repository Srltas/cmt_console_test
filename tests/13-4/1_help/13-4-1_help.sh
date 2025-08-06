#!/usr/bin/env bash
# Test runner for 'log' command help.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-4-1" \
    --command "log" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
