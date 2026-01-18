# Ralph Supreme - Planning Phase Prompt

You are in the PLANNING PHASE. Code execution is BLOCKED until planning is complete.

## Your Task

{{TASK_PROMPT}}

---

## Required Output

You must produce a complete Beads project structure. Do NOT write any implementation code.

### Step 1: Analyze the Request

Provide:
- **Scope**: Single-session or multi-session?
- **Complexity**: Simple (1-3 tasks) / Medium (4-10 tasks) / Complex (10+ tasks)
- **Key Risks**: What could go wrong?
- **Unknowns**: What needs investigation first?

### Step 2: Create Epic Structure

```bash
# Initialize beads if not already done
bd init

# Create the main epic
bd create "Epic: [OUTCOME DESCRIPTION]" -t epic
```

### Step 3: Decompose into Tasks

List ALL tasks needed, with clear dependency relationships:

```bash
# Core tasks (in execution order)
bd create "[Task 1 - verb + specific action]" --parent [epic-id]
bd create "[Task 2 - verb + specific action]" --parent [epic-id]
# ... etc

# Set dependencies
bd dep add [task-that-waits] [task-that-must-finish-first]
```

### Step 4: Verify Structure

Run and show output of:
```bash
bd ready      # First task(s) to execute
bd status     # Overview of all tasks
```

### Step 5: Planning Complete Signal

When your beads structure is ready, output:

```
PLANNING_COMPLETE: true
EPIC_ID: [the epic id]
TOTAL_TASKS: [count]
READY_TASKS: [count of unblocked tasks]
```

---

## Constraints

- MAXIMUM 15 tasks per epic (break into sub-epics if larger)
- Each task must be completable in ONE context window
- Every task name starts with a VERB
- Dependencies must form a DAG (no cycles)
- At least ONE task must be ready (unblocked) after planning

---

## Example Output

### Analysis
- **Scope**: Multi-session (estimated 3-5 iterations)
- **Complexity**: Medium (7 tasks)
- **Key Risks**: Database schema changes may break existing queries
- **Unknowns**: Need to verify current auth implementation first

### Beads Structure

```bash
bd init

# Epic
bd create "Epic: Add user password reset functionality" -t epic
# Returns: bd-7x2k

# Tasks
bd create "Investigate current auth implementation" --parent bd-7x2k
# Returns: bd-7x2k.1

bd create "Design password reset flow" --parent bd-7x2k
# Returns: bd-7x2k.2

bd create "Add password_reset_tokens table" --parent bd-7x2k
# Returns: bd-7x2k.3

bd create "Implement reset request endpoint" --parent bd-7x2k
# Returns: bd-7x2k.4

bd create "Implement reset confirmation endpoint" --parent bd-7x2k
# Returns: bd-7x2k.5

bd create "Add email sending for reset links" --parent bd-7x2k
# Returns: bd-7x2k.6

bd create "Write tests for reset flow" --parent bd-7x2k
# Returns: bd-7x2k.7

# Dependencies
bd dep add bd-7x2k.2 bd-7x2k.1   # Design waits for investigation
bd dep add bd-7x2k.3 bd-7x2k.2   # Schema waits for design
bd dep add bd-7x2k.4 bd-7x2k.3   # Endpoint waits for schema
bd dep add bd-7x2k.5 bd-7x2k.4   # Confirm waits for request
bd dep add bd-7x2k.6 bd-7x2k.4   # Email waits for request endpoint
bd dep add bd-7x2k.7 bd-7x2k.5   # Tests wait for both endpoints
bd dep add bd-7x2k.7 bd-7x2k.6   # Tests also wait for email
```

### Verification
```
$ bd ready
bd-7x2k.1  Investigate current auth implementation  [open]

$ bd status
Epic: bd-7x2k "Add user password reset functionality"
  └── bd-7x2k.1 [open]     Investigate current auth implementation
  └── bd-7x2k.2 [blocked]  Design password reset flow
  └── bd-7x2k.3 [blocked]  Add password_reset_tokens table
  └── bd-7x2k.4 [blocked]  Implement reset request endpoint
  └── bd-7x2k.5 [blocked]  Implement reset confirmation endpoint
  └── bd-7x2k.6 [blocked]  Add email sending for reset links
  └── bd-7x2k.7 [blocked]  Write tests for reset flow
```

### Signal
```
PLANNING_COMPLETE: true
EPIC_ID: bd-7x2k
TOTAL_TASKS: 7
READY_TASKS: 1
```

---

## Now analyze and plan for the task above.
