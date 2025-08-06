#!/usr/bin/env bash
# Test runner for 'report' command with -l and -ao options.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-5-4" \
    --command "report" \
    --command-options "-l -ao" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
