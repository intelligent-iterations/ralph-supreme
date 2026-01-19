# Ralph Supreme

**Advanced Autonomous AI Development Loop for Claude Code**

Ralph Supreme merges the best of three Ralph frameworks:
- **[Anthropic's Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)** - Completion promises, stop hooks, iterative philosophy
- **[Frank Bria's Ralph-Claude-Code](https://github.com/frankbria/ralph-claude-code)** - Dual-gate completion, circuit breakers, monitoring
- **[Steve Yegge's Beads](https://github.com/steveyegge/beads)** - Persistent task management that survives context compaction

## What is Ralph?

Ralph is fundamentally **"a bash loop"** - a `while true` that runs Claude Code iteratively until your task is complete. Named after Ralph Wiggum from The Simpsons, it embodies persistent iteration: keep trying until you succeed.

### Philosophy

- **Iteration > Perfection** - Don't aim for perfect on the first try
- **Failures Are Data** - Use test failures to refine the approach
- **Operator Skill Matters** - Good prompts are critical
- **Persistence Wins** - Keep trying until success

## Quick Start

```bash
# Clone and setup
cd ralph-supreme
cp .ralphrc.example .ralphrc
chmod +x ralph-supreme.sh

# Run with a prompt
./ralph-supreme.sh --prompt "Build a REST API for todos with CRUD operations, input validation, and tests. Output <promise>COMPLETE</promise> when done."

# Or use a PROMPT.md file
echo "Your task description..." > PROMPT.md
./ralph-supreme.sh
```

## Features

### From Anthropic's Ralph Wiggum
- **Completion Promise Detection** - Output `<promise>COMPLETE</promise>` to signal done
- **Iterative Re-prompting** - Fresh context each iteration to avoid rot
- **Auto Git Commits** - Commits changes after each iteration

### From Frank Bria's Implementation
- **Dual-Condition Gate** - Requires both completion indicators AND explicit exit signal
- **Circuit Breaker** - Stops after N iterations with no progress or repeated errors
- **Rate Limiting** - Configurable calls per hour (default: 100)
- **Session Management** - Resume capability with state persistence

### Ralph Supreme Additions
- **6 Lifecycle Hooks** - pre-start, pre-iteration, post-iteration, on-complete, on-error, post-stop
- **JSONL Logging** - Structured logs with timestamps, git SHAs, iteration counts
- **Tmux Monitoring** - Live dashboard with `--monitor` flag
- **Git Worktrees** - Isolated development with `--worktree` flag
- **Configurable Everything** - Via `.ralphrc` file or CLI flags

### Beads Task Management (NEW)
- **Planning Before Execution** - Claude creates structured task breakdown before coding
- **Persistent State** - Tasks survive context compaction in `.beads/` directory
- **Dependency Graph** - Tasks can block other tasks
- **Data-Driven Completion** - Loop until `bd ready` is empty

## Beads Integration

Ralph Supreme enforces **planning before execution** using Steve Yegge's Beads system.

### Two-Phase Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 1: PLANNING                                              │
│  Claude analyzes task → Creates epic → Decomposes into tasks    │
│  → Sets dependencies → Outputs PLANNING_COMPLETE                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 2: EXECUTION                                             │
│  Loop: bd ready → bd start → implement → bd close → repeat      │
│  Until: bd ready returns empty → Output COMPLETE                │
└─────────────────────────────────────────────────────────────────┘
```

### Why Beads?

| Problem | Beads Solution |
|---------|----------------|
| Context compaction loses progress | State persists in `.beads/` files |
| "Where was I?" after interruption | `bd ready` shows next task |
| No dependency awareness | `bd dep add` enforces order |
| Unclear completion criteria | Done when `bd ready` is empty |
| Decisions forgotten | `bd comment` preserves context |

### Quick Setup

```bash
# Install Beads CLI
npm install -g @anthropic/beads

# Check installation
./scripts/beads-setup.sh check

# Initialize in your project
bd init
```

### Beads Commands Reference

```bash
# Task Management
bd create "Task name"              # Create task
bd create "Epic" -t epic           # Create epic (container)
bd create "Sub" --parent bd-XXX    # Create subtask

# Workflow
bd ready                           # Show unblocked tasks
bd start bd-XXX                    # Mark task in progress
bd close bd-XXX                    # Mark task complete
bd status                          # Show all tasks

# Dependencies
bd dep add bd-Y bd-X               # Y waits for X to complete

# Documentation
bd comment bd-XXX "note"           # Add context/decision
bd show bd-XXX                     # Show task details
```

### Skipping Beads

For simple tasks, skip the planning phase:

```bash
# Skip planning, use legacy mode
./ralph-supreme.sh --prompt "Simple fix" --skip-planning

# Disable Beads entirely
./ralph-supreme.sh --prompt "Quick task" --no-beads
```

## Usage

```
./ralph-supreme.sh --prompt "Your task" [OPTIONS]

Required:
  --prompt <text>              Task prompt for Claude (or use PROMPT.md file)

Options:
  --max-iterations <n>         Maximum iterations (default: 50)
  --completion-promise <text>  Completion signal phrase (default: COMPLETE)
  --timeout <minutes>          Max runtime in minutes (default: 60)
  --rate-limit <n>             API calls per hour (default: 100)

  --resume                     Resume from previous state
  --worktree                   Use git worktree for isolation
  --monitor                    Run with tmux monitoring dashboard

Beads Options:
  --skip-planning              Skip planning phase (use existing beads or none)
  --no-beads                   Disable Beads entirely (legacy mode)

  --verbose                    Enable verbose output
  --dry-run                    Show what would be executed
  --help                       Show help message
  --version                    Show version
```

## Configuration

Create a `.ralphrc` file (copy from `.ralphrc.example`):

```bash
# Iteration limits
MAX_ITERATIONS=50
TIMEOUT_MINUTES=60

# Completion detection
COMPLETION_PROMISE="COMPLETE"

# Safety limits
RATE_LIMIT=100
CIRCUIT_BREAKER_THRESHOLD=3
ERROR_THRESHOLD=5

# Features
USE_TMUX=false
USE_WORKTREE=false
VERBOSE=false
```

## Writing Good Prompts

### Good Example

```markdown
Build a REST API for todos.

Requirements:
- CRUD operations (Create, Read, Update, Delete)
- Input validation on all endpoints
- Error handling with proper HTTP status codes
- Unit tests with >80% coverage

When complete:
- All endpoints responding correctly
- All tests passing
- README with API documentation

Output: <promise>COMPLETE</promise>
Also include: EXIT_SIGNAL: true
```

### Bad Example

```markdown
Make a todo app
```

(Too vague, no completion criteria)

## Hooks

Create executable scripts in `hooks/` to run at lifecycle events:

| Hook | When it runs |
|------|-------------|
| `pre-start.sh` | Once before the main loop begins |
| `pre-iteration.sh` | Before each iteration |
| `post-iteration.sh` | After each iteration completes |
| `on-complete.sh` | When completion is detected |
| `on-error.sh` | When circuit breaker trips |
| `post-stop.sh` | When Ralph exits (cleanup) |

Example hook:

```bash
#!/usr/bin/env bash
# hooks/post-iteration.sh

echo "Completed iteration $RALPH_ITERATION"
npm test 2>/dev/null || true
```

Available environment variables in hooks:
- `RALPH_ITERATION` - Current iteration number
- `RALPH_SESSION_ID` - Unique session identifier
- `RALPH_PROMPT` - The task prompt
- `RALPH_LAST_OUTPUT` - Output from previous/current iteration
- `RALPH_LOG_DIR` - Directory for log files

## Completion Detection

Ralph Supreme uses a **dual-condition gate** (from Frank Bria's implementation):

1. **Completion Indicators** - Words like "complete", "done", "finished", "tests passing"
2. **Exit Signal** - Explicit `EXIT_SIGNAL: true` or `RALPH_EXIT`

The loop exits when:
- 2+ completion indicators AND explicit exit signal, OR
- Explicit `<promise>COMPLETE</promise>` tag, OR
- 3+ completion indicators without signal

This prevents premature exits during productive iterations.

## Circuit Breaker

The circuit breaker stops the loop when:

- **No Progress**: Same output for N consecutive iterations (default: 3)
- **Repeated Errors**: Errors detected for N consecutive iterations (default: 5)

This prevents runaway API costs from stuck loops.

## Logs

All runs are logged to `logs/ralph_<session_id>.jsonl`:

```json
{"timestamp":"2024-01-15 10:30:00","level":"INFO","iteration":1,"git_sha":"abc1234","message":"Starting iteration"}
{"timestamp":"2024-01-15 10:30:15","type":"iteration","iteration":1,"git_sha":"abc1234","status":"executed","output_length":1500}
```

Query logs with jq:

```bash
# Get all errors
cat logs/ralph_*.jsonl | jq 'select(.level == "ERROR")'

# Get iteration summaries
cat logs/ralph_*.jsonl | jq 'select(.type == "iteration")'
```

## When to Use Ralph

**Good for:**
- Well-defined tasks with clear success criteria
- Tasks requiring iteration (getting tests to pass)
- Greenfield projects where you can step away
- Tasks with automatic verification (tests, linting)

**Not good for:**
- Tasks requiring human judgment
- One-shot operations
- Unclear success criteria
- Production debugging

## Resume Capability

Ralph saves state to `.ralph-state.json` after each iteration:

```bash
# Start a run
./ralph-supreme.sh --prompt "Build feature X"

# Interrupt with Ctrl+C...

# Resume later
./ralph-supreme.sh --resume
```

## Real-World Results

(From the original Ralph implementations)
- 6 repositories generated overnight at Y Combinator hackathon
- $50k contract completed for $297 in API costs
- Entire programming language created over 3 months

## License

MIT

## Credits

- Original Ralph concept: [Geoffrey Huntley](https://ghuntley.com/ralph/)
- Anthropic's Ralph Wiggum plugin
- Frank Bria's Ralph-Claude-Code
- Steve Yegge's Beads: [Persistent Task Management](https://disruptedai.substack.com/p/persistent-task-management-with-beads)

## Origin

Ralph Supreme was born from work on two parent projects at [Intelligent Iterations](https://github.com/intelligent-iterations):
- **[vibemanager](https://github.com/intelligent-iterations/vibemanager)** - AI-powered project management board for agentic programming workflows
- **vs-meta** - Meta tooling and configuration for AI-assisted development

The need for a robust autonomous development loop emerged while building these tools, leading to the creation of Ralph Supreme.

---

*"Me fail English? That's unpossible!" - Ralph Wiggum*

*"The agent's context window is temporary, but the work graph should be permanent." - Steve Yegge*
