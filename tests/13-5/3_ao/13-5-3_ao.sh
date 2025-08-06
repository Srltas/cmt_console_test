#!/usr/bin/env bash
# Test runner for 'report' command with -ao option.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-5-3" \
    --command "report" \
    --command-options "-ao" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
