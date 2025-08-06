#!/usr/bin/env bash
# Test runner for 'report' command with -ao and a specific mh file.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-5-6" \
    --command "report" \
    --command-options "-ao 1753849479511.mh" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
