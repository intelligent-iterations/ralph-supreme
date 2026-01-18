#!/usr/bin/env bash
#
# Circuit Breaker - Detects stuck loops and repeated errors
# Part of Ralph Supreme
#

set -euo pipefail

# State tracking
declare -a OUTPUT_HASHES=()
declare -a ERROR_COUNTS=()
declare -i NO_PROGRESS_STREAK=0
declare -i ERROR_STREAK=0

# Initialize circuit breaker state
init_circuit_breaker() {
    OUTPUT_HASHES=()
    ERROR_COUNTS=()
    NO_PROGRESS_STREAK=0
    ERROR_STREAK=0
}

# Record an iteration's output hash
record_output() {
    local output="$1"
    local hash=$(echo "$output" | md5sum | cut -d' ' -f1)
    OUTPUT_HASHES+=("$hash")

    # Keep only last 10
    if (( ${#OUTPUT_HASHES[@]} > 10 )); then
        OUTPUT_HASHES=("${OUTPUT_HASHES[@]:1}")
    fi

    echo "$hash"
}

# Check if output is making progress
check_progress() {
    local output="$1"
    local threshold="${2:-3}"

    local current_hash=$(echo "$output" | md5sum | cut -d' ' -f1)

    # Check against recent hashes
    local duplicates=0
    for hash in "${OUTPUT_HASHES[@]}"; do
        if [[ "$hash" == "$current_hash" ]]; then
            ((duplicates++))
        fi
    done

    if (( duplicates > 0 )); then
        ((NO_PROGRESS_STREAK++))
        if (( NO_PROGRESS_STREAK >= threshold )); then
            echo "TRIP:no_progress"
            return 1
        fi
        echo "WARN:no_progress:$NO_PROGRESS_STREAK"
        return 0
    fi

    NO_PROGRESS_STREAK=0
    echo "OK"
    return 0
}

# Check for error patterns
check_errors() {
    local output="$1"
    local threshold="${2:-5}"

    # Multi-line error pattern matching
    local error_patterns=(
        "Error:"
        "Exception:"
        "FAILED"
        "fatal:"
        "Traceback"
        "panic:"
        "cannot find"
        "undefined"
        "null pointer"
    )

    local has_error=false
    for pattern in "${error_patterns[@]}"; do
        if echo "$output" | grep -qi "$pattern"; then
            has_error=true
            break
        fi
    done

    if [[ "$has_error" == "true" ]]; then
        ((ERROR_STREAK++))
        if (( ERROR_STREAK >= threshold )); then
            echo "TRIP:errors"
            return 1
        fi
        echo "WARN:error:$ERROR_STREAK"
        return 0
    fi

    ERROR_STREAK=0
    echo "OK"
    return 0
}

# Full circuit breaker check
check_circuit_breaker() {
    local output="$1"
    local progress_threshold="${2:-3}"
    local error_threshold="${3:-5}"

    local progress_result=$(check_progress "$output" "$progress_threshold")
    if [[ "$progress_result" == TRIP:* ]]; then
        echo "$progress_result"
        return 1
    fi

    local error_result=$(check_errors "$output" "$error_threshold")
    if [[ "$error_result" == TRIP:* ]]; then
        echo "$error_result"
        return 1
    fi

    record_output "$output" > /dev/null
    echo "OK"
    return 0
}

# Main entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        check)
            check_circuit_breaker "$2" "${3:-3}" "${4:-5}"
            ;;
        init)
            init_circuit_breaker
            echo "Circuit breaker initialized"
            ;;
        *)
            echo "Usage: $0 check <output> [progress_threshold] [error_threshold]"
            echo "       $0 init"
            exit 1
            ;;
    esac
fi
