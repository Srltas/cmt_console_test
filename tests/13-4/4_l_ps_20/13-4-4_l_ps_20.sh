#!/usr/bin/env bash
# Test runner for 'log' command with -l and -ps options.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-4-4" \
    --command "log" \
    --command-options "-l -ps 20" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
