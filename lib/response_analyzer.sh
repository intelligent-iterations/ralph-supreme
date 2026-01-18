#!/usr/bin/env bash
#
# Response Analyzer - Evaluates Claude's output for progress and completion signals
# Part of Ralph Supreme
#

set -euo pipefail

# Analyze a response and return JSON with metrics
analyze_response() {
    local response="$1"
    local previous_response="${2:-}"

    local has_error=false
    local has_completion=false
    local has_progress=false
    local completion_indicators=0
    local error_indicators=0

    # Check for error patterns
    if echo "$response" | grep -qiE "(error|exception|failed|fatal|traceback|panic)"; then
        has_error=true
        error_indicators=$(echo "$response" | grep -ciE "(error|exception|failed)" || echo 0)
    fi

    # Check for completion patterns
    if echo "$response" | grep -qiE "(complete|done|finished|success|passed)"; then
        completion_indicators=$(echo "$response" | grep -ciE "(complete|done|finished|success|passed)" || echo 0)
        if (( completion_indicators >= 2 )); then
            has_completion=true
        fi
    fi

    # Check for progress (different from previous)
    if [[ -n "$previous_response" ]]; then
        local current_hash=$(echo "$response" | md5sum | cut -d' ' -f1)
        local prev_hash=$(echo "$previous_response" | md5sum | cut -d' ' -f1)
        if [[ "$current_hash" != "$prev_hash" ]]; then
            has_progress=true
        fi
    else
        has_progress=true
    fi

    # Check for specific signals
    local has_exit_signal=false
    if echo "$response" | grep -qiE "(EXIT_SIGNAL|RALPH_EXIT)"; then
        has_exit_signal=true
    fi

    # Output JSON
    cat << EOF
{
  "has_error": $has_error,
  "has_completion": $has_completion,
  "has_progress": $has_progress,
  "has_exit_signal": $has_exit_signal,
  "completion_indicators": $completion_indicators,
  "error_indicators": $error_indicators,
  "response_length": ${#response}
}
EOF
}

# Extract key information from response
extract_summary() {
    local response="$1"
    local max_length="${2:-500}"

    # Try to find meaningful summary sections
    local summary=""

    # Look for explicit summaries
    if echo "$response" | grep -q "Summary:"; then
        summary=$(echo "$response" | sed -n '/Summary:/,/^$/p' | head -5)
    # Look for status updates
    elif echo "$response" | grep -q "Status:"; then
        summary=$(echo "$response" | sed -n '/Status:/,/^$/p' | head -5)
    # Fall back to last N characters
    else
        summary="${response: -$max_length}"
    fi

    echo "$summary"
}

# Main entry point if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        analyze)
            analyze_response "$2" "${3:-}"
            ;;
        summary)
            extract_summary "$2" "${3:-500}"
            ;;
        *)
            echo "Usage: $0 analyze <response> [previous_response]"
            echo "       $0 summary <response> [max_length]"
            exit 1
            ;;
    esac
fi
