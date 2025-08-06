#!/usr/bin/env bash
# Test runner for 'script' command with -s option.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-3-2" \
    --command "script" \
    --command-options "-s oracle_source" \
    --comparison-type "log"

