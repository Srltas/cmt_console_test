#!/usr/bin/env bash
# Test runner for 'report' command help.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-5-1" \
    --command "report" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
