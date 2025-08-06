#!/usr/bin/env bash
# Test runner for 'help' command with no specific options.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-1-1" \
    --command "" \
    --comparison-type "summary"
