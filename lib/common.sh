#!/usr/bin/env bash
# This is a library of common functions, not meant to be executed directly.

# ───────────────────────────── Logging & Utilities ──────────────────────────
log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"; }

json_escape() {
    local s="$1"
    s="${s//\/\\}"       # 1. Backslash
    s="${s//\"/}"        # 2. Double quote
    s="${s//$\n/\\n}"    # 3. Newline
    s="${s//$''/\\r}"    # 4. Carriage return
    s="${s//$\t/\\t}"    # 5. Tab
    printf '%s' "$s"
}

# ───────────────────────────── Core Test Execution Engine ───────────────────

run_test_case() {
    # --- 1. Argument Parsing ---
    local case_id="" command="" command_options="" test_xml="" comparison_type="" execution_type="" use_mh="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --case-id) case_id="$2"; shift 2 ;;
            --command) command="$2"; shift 2 ;;
            --command-options) command_options="$2"; shift 2 ;;
            --test-xml) test_xml="$2"; shift 2 ;;
            --comparison-type) comparison_type="$2"; shift 2 ;;
            --execution-type) execution_type="$2"; shift 2 ;;
            --use-mh) use_mh="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    # --- 2. Setup & Path Definition ---
    local test_script_path="${BASH_SOURCE[1]}" # Caller script's path
    local test_dir; test_dir="$(cd "$(dirname "$test_script_path")" && pwd)"
    local rel_path="${test_dir#$TEST_ROOT/}"
    local result_dir="$RESULT_ROOT/$rel_path"
    local result_log="$result_dir/result.log"
    local cli_status=0
    local all_comparisons_passed=true

    mkdir -p "$result_dir"
    printf "  [%d/%d] Case: %s (%s)\n" "$CURRENT_CASE_INDEX" "$TOTAL_CASES" "$case_id" "$rel_path"
    log "  --- Running Case [$CURRENT_CASE_INDEX/$TOTAL_CASES]: $case_id ($rel_path)"

    # --- 3. Pre-execution Hooks ---
    [[ "$use_mh" == "true" ]] && prepare_mh_file
    if [[ -n "$test_xml" ]]; then
        if [[ "$test_xml" != /* ]]; then
            test_xml="$test_dir/$test_xml"
        fi
        command_options="$(_prepare_xml "$test_xml" "$result_dir")"
    fi

    # --- 4. Command Execution ---
    log " Command: ./migration.sh $command $command_options"
    (
        cd "$CMT_HOME" || exit 1
        case "$execution_type" in
            "expect")
                _execute_with_expect "$command" "$command_options" > "$result_log" 2>&1
                ;;
            "filter_progress")
                _execute_and_filter_progress "$command" "$command_options" > "$result_log"
                ;;
            "pipe_newline")
                _execute_with_pipe_newline "$command" "$command_options" > "$result_log"
                ;;
            *) # default
                eval "./migration.sh $command $command_options" > "$result_log" 2>&1
                ;;
        esac
    )
    cli_status=${PIPESTATUS[0]}
    if [ "$cli_status" -eq 0 ]; then
	    log "CMT ran successfully."
    else
	    log "CMT ran failed. (code: $cli_status)"
    fi

    # --- 5. Result Comparison ---
    local comparison_failed=false
    for type in $(echo "$comparison_type" | tr ',' ' '); do
        if ! _handle_comparison "$type" "$test_dir" "$result_dir" "$result_log" "$test_script_path"; then
            comparison_failed=true
        fi
    done

    # --- 6. Final Verdict & Cleanup ---
    if [[ $cli_status -eq 0 ]] && [[ "$comparison_failed" == "false" ]]; then
        printf "    ➜ ✅ Case Passed\n"
        log "  Case Result: Success"
    else
        printf "    ➜ ❌ Case Failed (see %s)\n" "$result_dir"
        log "  Case Result: Failure"
        echo "${rel_path}" >> "$FAILED_TARGETS_LOG"
    fi

    [[ "$use_mh" == "true" ]] && cleanup_mh_file
    cleanup_workspace
}

# ───────────────────────────── Execution Helpers ────────────────────────────

_execute_with_expect() {
    local cmd="$1" opts="$2"
    export cmd opts
    expect << 'EXPECT'
set timeout -1
set cmd_name $env(cmd)
set cmd_opts $env(opts)
eval spawn ./migration.sh $cmd_name $cmd_opts
expect {
    -re {Press.*to continue.*} { send "\r"; exp_continue }
    eof
}
wait
EXPECT
}

_execute_and_filter_progress() {
    local cmd="$1" opts="$2"
    eval "./migration.sh $command $command_options" 2>&1 | tr '\r' '\n' | grep -v -E '^Progress:[0-9]+%' 
}

_execute_with_pipe_newline() {
    local cmd="$1" opts="$2"
    printf '\n' | eval "./migration.sh $cmd $opts" 2>&1 | tr '\r' '\n'
}

_prepare_xml() {
    local src_xml="$1" out_dir="$2"
    local dst_xml="$out_dir/$(basename "$src_xml")"
    cp -- "$src_xml" "$dst_xml"
    local esc_dir
    esc_dir=$(printf '%s' "$out_dir" | sed 's/[&/\\]/\\&/g')
    sed -E -i "0,/<fileRepository[^>]*dir=\"[^\"]*\"/s#dir=\"[^\"]*\"#dir=\"$esc_dir\"#" "$dst_xml"
    log "prepare_xml      : src=$src_xml patchedDir=$out_dir"
    echo "$dst_xml"
}

# ───────────────────────────── Comparison Helpers ───────────────────────────

_handle_comparison() {
    local type="$1" test_dir="$2" result_dir="$3" result_log="$4" test_script_path="$5"
    local comp_json answer_file

    local script_basename; script_basename=$(basename "$test_script_path" .sh)
    answer_file="$test_dir/$script_basename.answer"
    if [[ ! -f "$answer_file" ]]; then
        local rel_path_stem; rel_path_stem="${test_dir#$TEST_ROOT/}"; rel_path_stem="${rel_path_stem//\//-}"
        answer_file="$test_dir/$rel_path_stem.answer"
    fi

    if [[ ! -f "$answer_file" ]]; then
        log "  Answer file missing for $test_script_path"
        comp_json="$result_dir/comparison_error.json"
        printf '{"status": "Failure", "message": "Answer file not found."}\n' > "$comp_json"
        return 1
    fi

    case "$type" in
        "summary")
            comp_json="$result_dir/summary_vs_answer.json"
            log "Comparing summary: $answer_file"
            _compare_summaries "$answer_file" "$result_log" "$comp_json"
            ;;
        "log")
            comp_json="$result_dir/log_vs_answer.json"
            log "Comparing log: $answer_file"
            _compare_log_outputs "$answer_file" "$result_log" "$comp_json"
            ;;
        "dump")
            comp_json="$result_dir/dump_vs_answer.json"
            local answer_dump="$test_dir/dump"
            local result_dump_name; result_dump_name=$(basename "$(find "$result_dir" -maxdepth 1 -type f -name '*.xml' | head -n 1)" .xml)
            local result_dump="$result_dir/$result_dump_name"
            log "Comparing dump: $answer_dump vs $result_dump"
            _compare_dumps "$answer_dump" "$result_dump" "$comp_json"
            ;;
        *)
            log "Unknown comparison type: $type"
            comp_json="$result_dir/comparison_error.json"
            printf '{"status": "Failure", "message": "Unknown comparison type: %s"}\n' "$type" > "$comp_json"
            return 1
            ;;
    esac
}

_compare_summaries() {
    local answer="$1" result_log="$2" out_json="$3"
    mapfile -t exp < <(awk '/Migration Report summary:/{f=1;next} f&&/^[[:space:]]*$/{exit} f&&!/Time used:/{sub(/^    /,"");print}' "$answer")
    mapfile -t act < <(awk '/Migration Report summary:/{f=1;next} f&&/^[[:space:]]*$/{exit} f&&!/Time used:/{sub(/^    /,"");print}' "$result_log")
    local max=${#exp[@]}; (( ${#act[@]} > max )) && max=${#act[@]}
    local diff_cnt=0 diff_json=""
    for ((i=0;i<max;i++)); do
        local e="${exp[i]:-}" a="${act[i]:-}"
        [[ "$e" == "$a" ]] && continue
        diff_cnt=$((diff_cnt+1))
        [[ -n "$diff_json" ]] && diff_json+=,
        diff_json+="\n    {\n      \"lineNumber\": $((i+1)),\n      \"expected\": \"$(json_escape "$e")\",\n      \"actual\": \"$(json_escape "$a")\"\n    }"
    done

    if (( diff_cnt==0 )); then
        printf '{\n  "status": "Success",\n  "message": "The summaries are identical."\n}\n' > "$out_json"
        return 0
    else
        printf '{\n  "status": "Failure",\n  "message": "The summaries have differences.",\n  "differences": [%b\n  ]\n}\n' "$diff_json" > "$out_json"
        return 1
    fi
}

_compare_dumps() {
    local ans_dump="$1" res_dump="$2" out_json="$3"
    local ans_files=() res_files=()
    if [[ -d "$ans_dump" ]]; then mapfile -t ans_files < <(find "$ans_dump" -type f -printf "%P\n" | sort); fi
    if [[ -d "$res_dump" ]]; then mapfile -t res_files < <(find "$res_dump" -type f -printf "%P\n" | sort); fi

    declare -A a_set r_set; for f in "${ans_files[@]}"; do a_set["$f"]=1; done; for f in "${res_files[@]}"; do r_set["$f"]=1; done
    mapfile -t all < <(printf '%s\n' "${ans_files[@]}" "${res_files[@]}" | sort -u)
    local total_files=${#all[@]} diff_cnt=0 file_json=""
    local SKIP_REGEX='(^|/)objects/|_object'

    for f in "${all[@]}"; do
        local reason="" note="" status="Success"
        if [[ -z "${a_set[$f]+x}" ]]; then
            diff_cnt=$((diff_cnt+1)); status="Failure"; reason="MissingInAnswer"
        elif [[ -z "${r_set[$f]+x}" ]]; then
            diff_cnt=$((diff_cnt+1)); status="Failure"; reason="MissingInResult"
        elif [[ "$f" =~ $SKIP_REGEX ]]; then
            note="ContentSkipped"
        elif ! cmp -s "$ans_dump/$f" "$res_dump/$f"; then
            diff_cnt=$((diff_cnt+1)); status="Failure"; reason="ContentMismatch"
        fi
        [[ -n "$file_json" ]] && file_json+=,
        file_json+="\n    {\n      \"path\": \"$(json_escape "$f")\",\n      \"status\": \"$status\""
        [[ -n "$reason" ]] && file_json+=",\n      \"reason\": \"$(json_escape "$reason")\""
        [[ -n "$note" ]] && file_json+=",\n      \"note\": \"$(json_escape "$note")\""
        file_json+="\n    }"
    done

    if (( diff_cnt > 0 )); then
        printf '{\n  "status": "Failure",\n  "message": "The dumps have differences.",\n  "filesChecked": {\n    "count": %d,\n    "files": [%b\n    ]\n  }\n}\n' "$total_files" "$file_json" > "$out_json"
        return 1
    else
        printf '{\n  "status": "Success",\n  "message": "The dumps are identical."\n}\n' > "$out_json"
        return 0
    fi
}

_compare_log_outputs() {
    local answer_file="$1" result_file="$2" output_json="$3"
    local filtered_result_file; filtered_result_file=$(mktemp)
    local filtered_answer_file; filtered_answer_file=$(mktemp)

    awk '
        !/^spawn / && !/^<Press \[enter\] to continue...>/ {
            sub(/^[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}(\.[0-9]{3})? /, "");
            gsub(/^[[:space:]]+|[[:space:]]+$/, "");
            print;
        }
    ' "$result_file" > "$filtered_result_file"

    awk '
        !/^spawn / && !/^<Press \[enter\] to continue...>/ {
            sub(/^[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}(\.[0-9]{3})? /, "");
            gsub(/^[[:space:]]+|[[:space:]]+$/, "");
            print;
        }
    ' "$answer_file" > "$filtered_answer_file"

    if diff -q "$filtered_answer_file" "$filtered_result_file" > /dev/null; then
        printf '{\n  "status": "Success",\n  "message": "The log outputs are identical."\n}\n' > "$output_json"
        rm -f "$filtered_result_file" "$filtered_answer_file"
        return 0
    else
        printf '{\n  "status": "Failure",\n  "message": "The log outputs have differences."\n}\n' > "$output_json"
        rm -f "$filtered_result_file" "$filtered_answer_file"
        return 1
    fi
}

# ───────────────────────────── Workspace & History Helpers ──────────────────

cleanup_workspace() {
    local target_dir="$CMT_HOME/workspace/cmt/report"
    if [[ -d "$target_dir" ]]; then
        find "$target_dir" -mindepth 1 -delete
        log "cleanup_workspace: Successfully cleaned."
    fi
}

prepare_mh_file() {
    local mh_source="$BASE_PATH/mh/1753849479511.mh"
    local mh_dest_dir="$CMT_HOME/workspace/cmt/report"
    mkdir -p "$mh_dest_dir"
    cp "$mh_source" "$mh_dest_dir/1753849479511.mh"
    log "Prepared migration history file."
}

cleanup_mh_file() {
    rm -f "$CMT_HOME/workspace/cmt/report/1753849479511.mh"
    log "Cleaned up migration history file."
}
