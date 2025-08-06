#!/usr/bin/env bash
# Test runner for 'report' command with -l option.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-5-2" \
    --command "report" \
    --command-options "-l" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
