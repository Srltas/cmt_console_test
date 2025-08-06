#!/usr/bin/env bash
# Test runner for 'start' command's help display when no script is provided.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-2-1-1" \
    --command "start" \
    --execution-type "pipe_newline" \
    --comparison-type "summary"