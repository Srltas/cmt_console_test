#!/usr/bin/env bash
# Test runner for 'log' command with -ps and a specific mh file.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-4-6" \
    --command "log" \
    --command-options "-ps 20 1753849479511.mh" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
