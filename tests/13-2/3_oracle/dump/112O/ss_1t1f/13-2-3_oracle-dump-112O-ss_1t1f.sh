#!/usr/bin/env bash
# Test runner for 'start' command with LOCAL migrations.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-2-3-DUMP-112O-SS_1T1F" \
    --command "start" \
    --test-xml "13-2-3_oracle-dump-112O-ss_1t1f.xml" \
    --execution-type "filter_progress" \
    --comparison-type "summary,dump"
