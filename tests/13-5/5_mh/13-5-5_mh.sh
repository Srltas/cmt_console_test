#!/usr/bin/env bash
# Test runner for 'report' command with a specific mh file.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-5-5" \
    --command "report" \
    --command-options "1753849479511.mh" \
    --execution-type "expect" \
    --comparison-type "log" \
    --use-mh "true"
