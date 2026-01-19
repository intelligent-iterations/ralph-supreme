#!/usr/bin/env bash
#
# Ralph Supreme - Advanced Autonomous AI Development Loop
# Merges: Anthropic's Ralph Wiggum + Frank Bria's Ralph-Claude-Code + Beads
#
# A self-referential bash loop that runs Claude Code iteratively
# until completion criteria are met. Combines:
# - Anthropic's completion promise detection and stop hooks
# - Frank Bria's dual-condition gate, circuit breaker, and monitoring
# - Steve Yegge's Beads for persistent task management
#
# Usage: ./ralph-supreme.sh --prompt "Your task" [options]
#
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="1.0.0"

# Load user config if exists
[[ -f "${SCRIPT_DIR}/.ralphrc" ]] && source "${SCRIPT_DIR}/.ralphrc"
[[ -f ".ralphrc" ]] && source ".ralphrc"

# Defaults (can be overridden by .ralphrc or CLI args)
MAX_ITERATIONS="${MAX_ITERATIONS:-50}"
COMPLETION_PROMISE="${COMPLETION_PROMISE:-COMPLETE}"
RATE_LIMIT="${RATE_LIMIT:-100}"          # Calls per hour
TIMEOUT_MINUTES="${TIMEOUT_MINUTES:-60}"
CIRCUIT_BREAKER_THRESHOLD="${CIRCUIT_BREAKER_THRESHOLD:-3}"
ERROR_THRESHOLD="${ERROR_THRESHOLD:-5}"
LOG_DIR="${LOG_DIR:-./logs}"
STATE_FILE="${STATE_FILE:-.ralph-state.json}"
HOOKS_DIR="${HOOKS_DIR:-${SCRIPT_DIR}/hooks}"
LIB_DIR="${LIB_DIR:-${SCRIPT_DIR}/lib}"
USE_TMUX="${USE_TMUX:-false}"
USE_WORKTREE="${USE_WORKTREE:-false}"
VERBOSE="${VERBOSE:-false}"
DRY_RUN="${DRY_RUN:-false}"
RESUME="${RESUME:-false}"
SKIP_PLANNING="${SKIP_PLANNING:-false}"
USE_BEADS="${USE_BEADS:-true}"
PROMPTS_DIR="${PROMPTS_DIR:-${SCRIPT_DIR}/prompts}"

# Runtime state
PROMPT=""
ITERATION=0
LAST_OUTPUT=""
START_TIME=$(date +%s)
CALLS_THIS_HOUR=0
HOUR_START=$(date +%s)
NO_PROGRESS_COUNT=0
ERROR_COUNT=0
SESSION_ID=$(date +%Y%m%d_%H%M%S)_$$
PLANNING_COMPLETE=false
CURRENT_EPIC_ID=""
CURRENT_TASK_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        INFO)  echo -e "${CYAN}[$timestamp]${NC} ${GREEN}[INFO]${NC} $msg" ;;
        WARN)  echo -e "${CYAN}[$timestamp]${NC} ${YELLOW}[WARN]${NC} $msg" ;;
        ERROR) echo -e "${CYAN}[$timestamp]${NC} ${RED}[ERROR]${NC} $msg" ;;
        DEBUG) [[ "$VERBOSE" == "true" ]] && echo -e "${CYAN}[$timestamp]${NC} ${BLUE}[DEBUG]${NC} $msg" ;;
    esac

    # Also log to JSONL file
    mkdir -p "$LOG_DIR"
    local log_file="${LOG_DIR}/ralph_${SESSION_ID}.jsonl"
    local git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")

    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"iteration\":$ITERATION,\"git_sha\":\"$git_sha\",\"message\":$(echo "$msg" | jq -Rs .)}" >> "$log_file"
}

log_iteration() {
    local iter="$1"
    local output="$2"
    local status="$3"
    local log_file="${LOG_DIR}/ralph_${SESSION_ID}.jsonl"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")

    echo "{\"timestamp\":\"$timestamp\",\"type\":\"iteration\",\"iteration\":$iter,\"git_sha\":\"$git_sha\",\"status\":\"$status\",\"output_length\":${#output},\"output_preview\":$(echo "${output:0:500}" | jq -Rs .)}" >> "$log_file"
}

show_banner() {
    cat << 'EOF'
 ____       _       _       ____
|  _ \ __ _| |_ __ | |__   / ___| _   _ _ __  _ __ ___ _ __ ___   ___
| |_) / _` | | '_ \| '_ \  \___ \| | | | '_ \| '__/ _ \ '_ ` _ \ / _ \
|  _ < (_| | | |_) | | | |  ___) | |_| | |_) | | |  __/ | | | | |  __/
|_| \_\__,_|_| .__/|_| |_| |____/ \__,_| .__/|_|  \___|_| |_| |_|\___|
             |_|                       |_|
EOF
    echo -e "${CYAN}Version ${VERSION} - Autonomous AI Development Loop${NC}"
    echo -e "${BLUE}Merging: Anthropic Ralph Wiggum + Frank Bria Ralph-Claude-Code${NC}"
    echo ""
}

usage() {
    cat << EOF
Usage: $(basename "$0") --prompt "Your task description" [OPTIONS]

Required:
  --prompt <text>              Task prompt for Claude (or use PROMPT.md file)

Options:
  --max-iterations <n>         Maximum iterations (default: $MAX_ITERATIONS)
  --completion-promise <text>  Completion signal phrase (default: $COMPLETION_PROMISE)
  --timeout <minutes>          Max runtime in minutes (default: $TIMEOUT_MINUTES)
  --rate-limit <n>             API calls per hour (default: $RATE_LIMIT)

  --resume                     Resume from previous state
  --worktree                   Use git worktree for isolation
  --monitor                    Run with tmux monitoring dashboard

Beads Task Management:
  --skip-planning              Skip the planning phase (jump to execution)
  --no-beads                   Disable Beads integration entirely

  --verbose                    Enable verbose output
  --dry-run                    Show what would be executed without running
  --help                       Show this help message
  --version                    Show version

Workflow:
  1. PLANNING PHASE: Claude creates Beads task structure (epic + tasks + deps)
  2. EXECUTION PHASE: Loop through tasks until bd ready is empty

Environment:
  Place a .ralphrc file in this directory or home to set defaults.
  Create PROMPT.md for persistent task instructions.
  Beads CLI (bd) required for task management: npm install -g @anthropic/beads

Examples:
  $(basename "$0") --prompt "Build a REST API with tests" --max-iterations 30
  $(basename "$0") --prompt "Fix all type errors" --skip-planning
  $(basename "$0") --resume --monitor
  $(basename "$0") --prompt "Simple task" --no-beads

EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT (Resume Capability)
# ═══════════════════════════════════════════════════════════════════════════════

save_state() {
    local status="${1:-running}"
    local git_branch=$(git branch --show-current 2>/dev/null || echo "none")

    cat > "$STATE_FILE" << EOF
{
  "session_id": "$SESSION_ID",
  "status": "$status",
  "iteration": $ITERATION,
  "max_iterations": $MAX_ITERATIONS,
  "prompt": $(echo "$PROMPT" | jq -Rs .),
  "completion_promise": "$COMPLETION_PROMISE",
  "last_output_preview": $(echo "${LAST_OUTPUT:0:1000}" | jq -Rs .),
  "git_branch": "$git_branch",
  "start_time": $START_TIME,
  "last_update": $(date +%s),
  "no_progress_count": $NO_PROGRESS_COUNT,
  "error_count": $ERROR_COUNT
}
EOF
    log DEBUG "State saved: iteration=$ITERATION, status=$status"
}

load_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        log ERROR "No state file found at $STATE_FILE"
        return 1
    fi

    log INFO "Loading state from $STATE_FILE"

    SESSION_ID=$(jq -r '.session_id // empty' "$STATE_FILE")
    ITERATION=$(jq -r '.iteration // 0' "$STATE_FILE")
    PROMPT=$(jq -r '.prompt // empty' "$STATE_FILE")
    COMPLETION_PROMISE=$(jq -r '.completion_promise // "COMPLETE"' "$STATE_FILE")
    LAST_OUTPUT=$(jq -r '.last_output_preview // empty' "$STATE_FILE")
    NO_PROGRESS_COUNT=$(jq -r '.no_progress_count // 0' "$STATE_FILE")
    ERROR_COUNT=$(jq -r '.error_count // 0' "$STATE_FILE")

    log INFO "Resumed: session=$SESSION_ID, iteration=$ITERATION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# HOOKS SYSTEM (Lifecycle Events)
# ═══════════════════════════════════════════════════════════════════════════════

run_hook() {
    local hook_name="$1"
    local hook_file="${HOOKS_DIR}/${hook_name}.sh"

    if [[ -x "$hook_file" ]]; then
        log DEBUG "Running hook: $hook_name"

        # Export context for hooks
        export RALPH_ITERATION=$ITERATION
        export RALPH_SESSION_ID=$SESSION_ID
        export RALPH_PROMPT="$PROMPT"
        export RALPH_LAST_OUTPUT="$LAST_OUTPUT"
        export RALPH_LOG_DIR="$LOG_DIR"

        if ! "$hook_file"; then
            log WARN "Hook $hook_name returned non-zero"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# BEADS INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════════

check_beads_installed() {
    if ! command -v bd &> /dev/null; then
        return 1
    fi
    return 0
}

init_beads() {
    if [[ "$USE_BEADS" != "true" ]]; then
        return 0
    fi

    if ! check_beads_installed; then
        log WARN "Beads (bd) not installed. Install with: npm install -g @anthropic/beads"
        log WARN "Continuing without Beads task management"
        USE_BEADS="false"
        return 0
    fi

    # Initialize beads if not already done
    if [[ ! -d ".beads" ]]; then
        log INFO "Initializing Beads task database..."
        bd init 2>/dev/null || true
    fi

    log INFO "Beads task management enabled"
}

get_beads_ready_count() {
    if [[ "$USE_BEADS" != "true" ]]; then
        echo "-1"
        return
    fi

    local count=$(bd ready 2>/dev/null | wc -l | tr -d ' ')
    echo "$count"
}

get_next_beads_task() {
    if [[ "$USE_BEADS" != "true" ]]; then
        echo ""
        return
    fi

    # Get first ready task
    bd ready 2>/dev/null | head -1 | awk '{print $1}'
}

check_beads_complete() {
    if [[ "$USE_BEADS" != "true" ]]; then
        return 1
    fi

    local ready_count=$(get_beads_ready_count)
    if [[ "$ready_count" == "0" ]]; then
        log INFO "All Beads tasks complete (bd ready is empty)"
        return 0
    fi
    return 1
}

load_beads_system_prompt() {
    local system_prompt_file="${PROMPTS_DIR}/BEADS_SYSTEM.md"
    if [[ -f "$system_prompt_file" ]]; then
        cat "$system_prompt_file"
    else
        log WARN "Beads system prompt not found at $system_prompt_file"
        echo ""
    fi
}

load_planning_prompt() {
    local planning_file="${PROMPTS_DIR}/PLANNING_PHASE.md"
    if [[ -f "$planning_file" ]]; then
        # Replace placeholder with actual task using bash parameter expansion
        # This safely handles multi-line PROMPT with any special characters
        local template
        template=$(<"$planning_file")
        printf '%s\n' "${template//\{\{TASK_PROMPT\}\}/$PROMPT}"
    else
        log WARN "Planning prompt not found at $planning_file"
        echo ""
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# PLANNING PHASE
# ═══════════════════════════════════════════════════════════════════════════════

run_planning_phase() {
    if [[ "$SKIP_PLANNING" == "true" ]]; then
        log INFO "Skipping planning phase (--skip-planning)"
        PLANNING_COMPLETE=true
        return 0
    fi

    if [[ "$USE_BEADS" != "true" ]]; then
        log INFO "Beads disabled, skipping planning phase"
        PLANNING_COMPLETE=true
        return 0
    fi

    log INFO "═══════════════════════════════════════════════════════════════════"
    log INFO "PLANNING PHASE - Establishing Beads task structure"
    log INFO "═══════════════════════════════════════════════════════════════════"

    local planning_prompt=$(load_planning_prompt)
    local system_prompt=$(load_beads_system_prompt)

    if [[ -z "$planning_prompt" ]]; then
        log ERROR "Could not load planning prompt"
        return 1
    fi

    local full_prompt="$system_prompt

---

$planning_prompt"

    log INFO "Running planning iteration..."

    local max_planning_attempts=3
    local attempt=0

    while (( attempt < max_planning_attempts )); do
        ((attempt++))
        log INFO "Planning attempt $attempt/$max_planning_attempts"

        check_rate_limit

        local output=$(run_claude "$full_prompt")

        # Check if planning is complete
        if echo "$output" | grep -q "PLANNING_COMPLETE: true"; then
            log INFO "Planning phase completed successfully"

            # Extract epic ID if present
            CURRENT_EPIC_ID=$(echo "$output" | grep -oP 'EPIC_ID: \K[^\s]+' || echo "")

            if [[ -n "$CURRENT_EPIC_ID" ]]; then
                log INFO "Epic created: $CURRENT_EPIC_ID"
            fi

            # Verify beads were created
            local ready_count=$(get_beads_ready_count)
            if [[ "$ready_count" -gt 0 ]]; then
                log INFO "Beads structure verified: $ready_count tasks ready"
                PLANNING_COMPLETE=true
                return 0
            else
                log WARN "No ready tasks found after planning"
            fi
        fi

        log WARN "Planning not complete, retrying..."

        # Update prompt for retry
        full_prompt="$system_prompt

---

$planning_prompt

PREVIOUS ATTEMPT DID NOT COMPLETE PLANNING. Please ensure you:
1. Create an epic with bd create
2. Create tasks with proper dependencies
3. Output PLANNING_COMPLETE: true when done
4. Verify bd ready shows at least one task"

    done

    log ERROR "Planning phase failed after $max_planning_attempts attempts"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# RATE LIMITING
# ═══════════════════════════════════════════════════════════════════════════════

check_rate_limit() {
    local now=$(date +%s)
    local hour_elapsed=$((now - HOUR_START))

    # Reset counter every hour
    if (( hour_elapsed >= 3600 )); then
        HOUR_START=$now
        CALLS_THIS_HOUR=0
        log DEBUG "Rate limit counter reset"
    fi

    if (( CALLS_THIS_HOUR >= RATE_LIMIT )); then
        local wait_time=$((3600 - hour_elapsed))
        log WARN "Rate limit reached ($RATE_LIMIT/hour). Waiting ${wait_time}s..."
        sleep "$wait_time"
        HOUR_START=$(date +%s)
        CALLS_THIS_HOUR=0
    fi

    ((CALLS_THIS_HOUR++))
}

# ═══════════════════════════════════════════════════════════════════════════════
# CIRCUIT BREAKER (Error Detection)
# ═══════════════════════════════════════════════════════════════════════════════

check_circuit_breaker() {
    local output="$1"
    local previous_output="$2"

    # Check for repeated errors
    if echo "$output" | grep -qiE "(error|exception|failed|fatal)"; then
        ((ERROR_COUNT++))
        log WARN "Error detected in output (count: $ERROR_COUNT)"
    else
        ERROR_COUNT=0
    fi

    # Check for no progress (output too similar to previous)
    if [[ -n "$previous_output" ]]; then
        # Simple similarity check - if outputs are nearly identical
        local output_hash=$(echo "$output" | md5sum | cut -d' ' -f1)
        local prev_hash=$(echo "$previous_output" | md5sum | cut -d' ' -f1)

        if [[ "$output_hash" == "$prev_hash" ]]; then
            ((NO_PROGRESS_COUNT++))
            log WARN "No progress detected (count: $NO_PROGRESS_COUNT)"
        else
            NO_PROGRESS_COUNT=0
        fi
    fi

    # Trip circuit breaker
    if (( NO_PROGRESS_COUNT >= CIRCUIT_BREAKER_THRESHOLD )); then
        log ERROR "Circuit breaker tripped: $NO_PROGRESS_COUNT iterations with no progress"
        return 1
    fi

    if (( ERROR_COUNT >= ERROR_THRESHOLD )); then
        log ERROR "Circuit breaker tripped: $ERROR_COUNT consecutive errors"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# COMPLETION DETECTION (Dual-Condition Gate)
# ═══════════════════════════════════════════════════════════════════════════════

check_completion() {
    local output="$1"
    local indicators=0

    # BEADS COMPLETION: Check if all beads tasks are done
    if [[ "$USE_BEADS" == "true" ]] && check_beads_installed; then
        if check_beads_complete; then
            log INFO "Beads completion: all tasks done (bd ready is empty)"
            ((indicators+=2))  # Strong indicator
        fi
    fi

    # Check for explicit completion promise (from Anthropic's approach)
    if echo "$output" | grep -qF "$COMPLETION_PROMISE"; then
        log INFO "Completion promise detected: $COMPLETION_PROMISE"
        ((indicators++))
    fi

    # Check for common completion signals
    if echo "$output" | grep -qiE "(task complete|all done|finished|implementation complete)"; then
        ((indicators++))
    fi

    # Check for test success indicators
    if echo "$output" | grep -qiE "(all tests pass|tests: [0-9]+ pass|✓.*pass)"; then
        ((indicators++))
    fi

    # Check for explicit EXIT_SIGNAL (from Frank Bria's dual-gate)
    local has_exit_signal=false
    if echo "$output" | grep -qiE "(EXIT_SIGNAL|RALPH_EXIT|ready.to.exit)"; then
        has_exit_signal=true
        log DEBUG "Exit signal detected"
    fi

    # Dual-condition gate: need indicators AND signal (or strong indicators alone)
    if (( indicators >= 2 )) && [[ "$has_exit_signal" == "true" ]]; then
        log INFO "Dual-gate completion: $indicators indicators + exit signal"
        return 0
    fi

    # Strong completion: explicit promise is enough
    if echo "$output" | grep -qF "<promise>$COMPLETION_PROMISE</promise>"; then
        log INFO "Strong completion promise detected"
        return 0
    fi

    # Multiple strong indicators without explicit signal
    if (( indicators >= 3 )); then
        log INFO "Multiple completion indicators ($indicators) detected"
        return 0
    fi

    # BEADS-ONLY completion: if beads shows done and we have the promise
    if [[ "$USE_BEADS" == "true" ]] && check_beads_complete; then
        if echo "$output" | grep -qF "$COMPLETION_PROMISE"; then
            log INFO "Beads complete + completion promise"
            return 0
        fi
    fi

    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# GIT WORKTREE SUPPORT
# ═══════════════════════════════════════════════════════════════════════════════

setup_worktree() {
    if [[ "$USE_WORKTREE" != "true" ]]; then
        return 0
    fi

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log WARN "Not a git repository, skipping worktree setup"
        return 0
    fi

    local worktree_name="ralph-${SESSION_ID}"
    local worktree_path="../${worktree_name}"

    log INFO "Creating git worktree: $worktree_name"

    # Create a new branch for this run
    git branch "$worktree_name" HEAD 2>/dev/null || true
    git worktree add "$worktree_path" "$worktree_name"

    cd "$worktree_path"
    log INFO "Working in isolated worktree: $(pwd)"
}

cleanup_worktree() {
    if [[ "$USE_WORKTREE" != "true" ]]; then
        return 0
    fi

    local worktree_name="ralph-${SESSION_ID}"

    if git worktree list | grep -q "$worktree_name"; then
        log INFO "Cleaning up worktree: $worktree_name"
        cd ..
        git worktree remove "$worktree_name" --force 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TMUX MONITORING
# ═══════════════════════════════════════════════════════════════════════════════

setup_tmux_monitor() {
    if [[ "$USE_TMUX" != "true" ]]; then
        return 0
    fi

    if ! command -v tmux &> /dev/null; then
        log WARN "tmux not found, disabling monitoring"
        USE_TMUX="false"
        return 0
    fi

    local session_name="ralph-monitor-${SESSION_ID}"

    # Create monitoring session
    tmux new-session -d -s "$session_name" -n "main"

    # Split for log tailing
    tmux split-window -h -t "$session_name"
    tmux send-keys -t "$session_name:0.1" "tail -f ${LOG_DIR}/ralph_${SESSION_ID}.jsonl | jq ." Enter

    # Split for status
    tmux split-window -v -t "$session_name:0.0"
    tmux send-keys -t "$session_name:0.2" "watch -n 5 'cat $STATE_FILE | jq .'" Enter

    log INFO "Tmux monitor started: tmux attach -t $session_name"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION LOOP
# ═══════════════════════════════════════════════════════════════════════════════

run_claude() {
    local iteration_prompt="$1"
    local output_file=$(mktemp)

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would execute: claude --print \"${iteration_prompt:0:100}...\""
        echo "DRY_RUN_OUTPUT_ITERATION_$ITERATION"
        return 0
    fi

    # Run Claude Code and capture output
    # Using --print for non-interactive mode with full output
    if claude --print "$iteration_prompt" > "$output_file" 2>&1; then
        cat "$output_file"
    else
        local exit_code=$?
        log WARN "Claude exited with code $exit_code"
        cat "$output_file"
    fi

    rm -f "$output_file"
}

build_iteration_prompt() {
    local base_prompt="$1"
    local last_output="$2"
    local iteration="$3"

    # Load Beads system prompt if available
    local system_context=""
    if [[ "$USE_BEADS" == "true" ]]; then
        system_context=$(load_beads_system_prompt)
    fi

    # Get current beads status
    local beads_status=""
    local current_task=""
    if [[ "$USE_BEADS" == "true" ]] && check_beads_installed; then
        current_task=$(get_next_beads_task)
        local ready_count=$(get_beads_ready_count)

        if [[ -n "$current_task" ]]; then
            beads_status="BEADS STATUS:
Current task: $current_task
Ready tasks: $ready_count
$(bd show "$current_task" 2>/dev/null || echo "")

INSTRUCTIONS:
1. Run: bd start $current_task
2. Complete the task described above
3. Document decisions: bd comment $current_task \"DECISION: ...\"
4. When done: bd close $current_task
5. Check: bd ready for next task"
        else
            beads_status="BEADS STATUS:
No tasks ready. Check if all tasks are complete with: bd status

If epic is complete, output:
<promise>$COMPLETION_PROMISE</promise>
EXIT_SIGNAL: true"
        fi
    fi

    cat << EOF
[RALPH SUPREME - Iteration $iteration/$MAX_ITERATIONS]

${system_context:+$system_context

---

}ORIGINAL TASK:
$base_prompt

${beads_status:+$beads_status

---

}COMPLETION CRITERIA:
When ALL beads tasks are complete (bd ready returns empty), output:
<promise>$COMPLETION_PROMISE</promise>
EXIT_SIGNAL: true

$(if [[ -n "$last_output" ]]; then
echo "PREVIOUS ITERATION SUMMARY:"
echo "${last_output:0:2000}"
echo ""
echo "Continue from where you left off. Build on previous progress."
fi)

EXECUTION RULES:
1. Work on ONE task at a time (the current task from bd ready)
2. Document ALL decisions with bd comment
3. Close tasks ONLY when fully complete
4. Check bd ready after closing each task
5. Signal completion ONLY when bd ready is empty

Remember: Iteration > Perfection. Make progress, commit often, document decisions.
EOF
}

main_loop() {
    local previous_output=""

    # Check timeout
    check_timeout() {
        local now=$(date +%s)
        local elapsed=$(( (now - START_TIME) / 60 ))
        if (( elapsed >= TIMEOUT_MINUTES )); then
            log ERROR "Timeout reached: ${elapsed}m >= ${TIMEOUT_MINUTES}m"
            return 1
        fi
        return 0
    }

    log INFO "Starting main loop: max_iterations=$MAX_ITERATIONS, timeout=${TIMEOUT_MINUTES}m"
    run_hook pre-start

    while (( ITERATION < MAX_ITERATIONS )); do
        ((ITERATION++))

        log INFO "═══ Iteration $ITERATION/$MAX_ITERATIONS ═══"
        save_state "running"
        run_hook pre-iteration

        # Check rate limit
        check_rate_limit

        # Check timeout
        if ! check_timeout; then
            run_hook on-timeout
            break
        fi

        # Build and execute prompt
        local iteration_prompt=$(build_iteration_prompt "$PROMPT" "$LAST_OUTPUT" "$ITERATION")

        log DEBUG "Executing Claude..."
        local output=$(run_claude "$iteration_prompt")

        log_iteration "$ITERATION" "$output" "executed"

        # Check circuit breaker
        if ! check_circuit_breaker "$output" "$previous_output"; then
            log ERROR "Circuit breaker tripped, stopping loop"
            run_hook on-error
            save_state "circuit_breaker"
            return 1
        fi

        # Check completion
        if check_completion "$output"; then
            log INFO "Completion detected at iteration $ITERATION"
            LAST_OUTPUT="$output"
            run_hook on-complete
            save_state "completed"
            return 0
        fi

        # Update state for next iteration
        previous_output="$LAST_OUTPUT"
        LAST_OUTPUT="$output"

        run_hook post-iteration

        # Auto-commit if in git repo
        if git rev-parse --git-dir > /dev/null 2>&1; then
            if [[ -n "$(git status --porcelain)" ]]; then
                git add -A
                git commit -m "Ralph iteration $ITERATION" --no-verify 2>/dev/null || true
                log DEBUG "Auto-committed changes"
            fi
        fi
    done

    log WARN "Max iterations reached ($MAX_ITERATIONS)"
    save_state "max_iterations"
    run_hook on-max-iterations
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLEANUP & SIGNAL HANDLING
# ═══════════════════════════════════════════════════════════════════════════════

cleanup() {
    log INFO "Cleaning up..."
    save_state "interrupted"
    run_hook post-stop
    cleanup_worktree

    if [[ "$USE_TMUX" == "true" ]]; then
        local session_name="ralph-monitor-${SESSION_ID}"
        tmux kill-session -t "$session_name" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

# ═══════════════════════════════════════════════════════════════════════════════
# ARGUMENT PARSING
# ═══════════════════════════════════════════════════════════════════════════════

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prompt)
                PROMPT="$2"
                shift 2
                ;;
            --max-iterations)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            --completion-promise)
                COMPLETION_PROMISE="$2"
                shift 2
                ;;
            --timeout)
                TIMEOUT_MINUTES="$2"
                shift 2
                ;;
            --rate-limit)
                RATE_LIMIT="$2"
                shift 2
                ;;
            --resume)
                RESUME="true"
                shift
                ;;
            --worktree)
                USE_WORKTREE="true"
                shift
                ;;
            --monitor)
                USE_TMUX="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --skip-planning)
                SKIP_PLANNING="true"
                shift
                ;;
            --no-beads)
                USE_BEADS="false"
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            --version)
                echo "Ralph Supreme v${VERSION}"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    parse_args "$@"

    show_banner

    # Resume mode
    if [[ "$RESUME" == "true" ]]; then
        load_state || exit 1
        # When resuming, skip planning (already done)
        SKIP_PLANNING="true"
    fi

    # Load prompt from file if not provided
    if [[ -z "$PROMPT" ]] && [[ -f "PROMPT.md" ]]; then
        PROMPT=$(cat PROMPT.md)
        log INFO "Loaded prompt from PROMPT.md"
    fi

    # Validate prompt
    if [[ -z "$PROMPT" ]]; then
        echo -e "${RED}Error: No prompt provided. Use --prompt or create PROMPT.md${NC}"
        usage
        exit 1
    fi

    log INFO "Session ID: $SESSION_ID"
    log INFO "Prompt: ${PROMPT:0:100}..."
    log INFO "Max iterations: $MAX_ITERATIONS"
    log INFO "Completion promise: $COMPLETION_PROMISE"
    log INFO "Timeout: ${TIMEOUT_MINUTES} minutes"
    log INFO "Rate limit: ${RATE_LIMIT}/hour"
    log INFO "Beads enabled: $USE_BEADS"
    log INFO "Skip planning: $SKIP_PLANNING"

    # Setup
    mkdir -p "$LOG_DIR"
    setup_worktree
    setup_tmux_monitor

    # Initialize Beads if enabled
    if [[ "$USE_BEADS" == "true" ]]; then
        init_beads
    fi

    # ═══════════════════════════════════════════════════════════════════
    # PHASE 1: PLANNING (Beads task structure)
    # ═══════════════════════════════════════════════════════════════════
    if [[ "$USE_BEADS" == "true" ]] && [[ "$SKIP_PLANNING" != "true" ]]; then
        if ! run_planning_phase; then
            echo ""
            log ERROR "Planning phase failed"
            echo -e "${RED}Could not establish Beads task structure. Use --skip-planning to bypass.${NC}"
            exit 1
        fi
        echo ""
        log INFO "Planning complete. Starting execution phase..."
        echo ""
    fi

    # ═══════════════════════════════════════════════════════════════════
    # PHASE 2: EXECUTION (Main loop)
    # ═══════════════════════════════════════════════════════════════════
    if main_loop; then
        echo ""
        log INFO "Ralph Supreme completed successfully!"
        echo -e "${GREEN}Task completed in $ITERATION iterations${NC}"

        # Show final beads status
        if [[ "$USE_BEADS" == "true" ]] && check_beads_installed; then
            echo ""
            echo -e "${CYAN}Final Beads Status:${NC}"
            bd status 2>/dev/null || true
        fi

        exit 0
    else
        echo ""
        log WARN "Ralph Supreme stopped before completion"
        echo -e "${YELLOW}Stopped at iteration $ITERATION. Use --resume to continue.${NC}"

        # Show current beads status
        if [[ "$USE_BEADS" == "true" ]] && check_beads_installed; then
            echo ""
            echo -e "${CYAN}Current Beads Status:${NC}"
            bd status 2>/dev/null || true
            echo ""
            echo -e "${CYAN}Ready tasks:${NC}"
            bd ready 2>/dev/null || true
        fi

        exit 1
    fi
}

main "$@"
