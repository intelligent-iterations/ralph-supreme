#!/usr/bin/env bash
#
# JSON Utilities - Helpers for JSON parsing and generation
# Part of Ralph Supreme
#

set -euo pipefail

# Escape a string for JSON
json_escape() {
    local string="$1"
    # Use jq if available, otherwise basic escaping
    if command -v jq &> /dev/null; then
        echo "$string" | jq -Rs .
    else
        # Basic escaping without jq
        string="${string//\\/\\\\}"
        string="${string//\"/\\\"}"
        string="${string//$'\n'/\\n}"
        string="${string//$'\t'/\\t}"
        echo "\"$string\""
    fi
}

# Parse a JSON field (requires jq)
json_get() {
    local json="$1"
    local field="$2"
    local default="${3:-}"

    if command -v jq &> /dev/null; then
        local value=$(echo "$json" | jq -r "$field // empty")
        if [[ -z "$value" ]]; then
            echo "$default"
        else
            echo "$value"
        fi
    else
        echo "$default"
    fi
}

# Create a simple JSON object
json_object() {
    local result="{"
    local first=true

    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        shift 2

        if [[ "$first" == "true" ]]; then
            first=false
        else
            result+=","
        fi

        result+="\"$key\":$(json_escape "$value")"
    done

    result+="}"
    echo "$result"
}

# Append to a JSONL file
jsonl_append() {
    local file="$1"
    shift

    local json=$(json_object "$@")
    echo "$json" >> "$file"
}

# Read latest entry from JSONL
jsonl_latest() {
    local file="$1"

    if [[ -f "$file" ]]; then
        tail -1 "$file"
    else
        echo "{}"
    fi
}

# Main entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        escape)
            json_escape "$2"
            ;;
        get)
            json_get "$2" "$3" "${4:-}"
            ;;
        object)
            shift
            json_object "$@"
            ;;
        *)
            echo "Usage: $0 escape <string>"
            echo "       $0 get <json> <field> [default]"
            echo "       $0 object key1 value1 key2 value2 ..."
            exit 1
            ;;
    esac
fi
