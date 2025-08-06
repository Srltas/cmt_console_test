#!/usr/bin/env bash
# Test runner for 'start' command with LOCAL migrations.
set -euo pipefail

source "$BASE_PATH/lib/common.sh"

run_test_case \
    --case-id "13-2-3-DUMP-110U-NO" \
    --command "start" \
    --test-xml "13-2-3_oracle-dump-110U-no_option.xml" \
    --execution-type "filter_progress" \
    --comparison-type "summary,dump"
