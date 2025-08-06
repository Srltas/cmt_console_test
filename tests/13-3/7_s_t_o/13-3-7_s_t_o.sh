#!/usr/bin/env bash
# Test runner for 'script' command with -s, -t, and -o options.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-3-7" \
    --command "script" \
    --command-options "-s oracle_source -t cubrid_dump -o _RESULT_DIR_" \
    --comparison-type "log"
