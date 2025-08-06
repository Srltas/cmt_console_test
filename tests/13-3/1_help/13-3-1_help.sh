#!/usr/bin/env bash
# Test runner for 'script' command with no options.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-3-1" \
    --command "script" \
    --comparison-type "log"
