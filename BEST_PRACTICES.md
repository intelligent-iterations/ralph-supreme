# Ralph Supreme Best Practices Guide

A comprehensive guide to delivering great software outcomes with autonomous coding loops, compiled from community wisdom and original implementations.

## Core Philosophy

> "The skill shifts from 'directing Claude step by step' to 'writing prompts that converge toward correct solutions.'" — [Paddo.dev](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)

Three foundational principles:

1. **Context scarcity**: With ~176K usable tokens, bloated prompts waste resources. Keep iterations lean.
2. **Disposable plans**: A plan that drifts is cheaper to regenerate than to salvage.
3. **Backpressure over direction**: Engineer environments where incorrect outputs get automatically rejected rather than micromanaging the agent.

---

## The Three-Phase Workflow

From [The Ralph Wiggum Playbook](https://paddo.dev/blog/ralph-wiggum-playbook/):

### Phase 1: Requirements (Human + AI)
- Identify jobs to be done
- Break into topics of concern
- Create specification files in `specs/`
- **No code** — just clearly documented requirements

### Phase 2: Planning (AI)
- Agent examines specs and existing code
- Generates `IMPLEMENTATION_PLAN.md`
- Pure gap analysis, then exits
- Fresh context for planning clarity

### Phase 3: Building (AI Loop)
- Select top task from plan
- Implement it
- Validate (tests, lint, build)
- Update plan, commit, exit
- **One task per iteration** — keeps context lean

---

## Task Selection: When to Use Ralph

### Ideal Tasks ✅

| Task Type | Why It Works |
|-----------|--------------|
| Large refactors | Mechanical, well-defined steps |
| Framework migrations | Clear before/after state |
| Test coverage | Measurable completion (% coverage) |
| Documentation | Verifiable output exists |
| Batch operations | Repetitive, consistent pattern |
| Greenfield with specs | No legacy constraints |
| Dependency upgrades | Clear success (builds pass) |

### Avoid These ❌

| Task Type | Why It Fails |
|-----------|--------------|
| "Make it better" | No objective completion |
| Architectural decisions | Requires human judgment |
| Security-critical code | Needs human review |
| Exploratory/research | Discovery ≠ convergence |
| Vague requirements | Can't define "done" |
| Performance optimization | Often needs profiling insight |

> "Better to fail predictably than succeed unpredictably." — [Paddo.dev](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)

---

## Writing Effective Prompts

### The Prompt Structure

From the Playbook, effective prompts follow phases:

```
Sections 0a-0d: Orientation (read files, absorb context)
Sections 1-4:   Main iteration instructions
Sections 999+:  Guardrails and safety constraints
```

### Bad vs Good Prompts

**❌ Bad: Vague**
```markdown
Build a todo API and make it good
```

**✅ Good: Precise completion criteria**
```markdown
Build a REST API with CRUD operations for todos.

Requirements:
- GET/POST/PUT/DELETE /todos endpoints
- Input validation on all endpoints
- Error responses with proper HTTP status codes
- Unit tests with >80% coverage
- README with API documentation

Success Criteria:
- All tests pass: `npm test`
- Type check passes: `npm run typecheck`
- Linter passes: `npm run lint`
- Build succeeds: `npm run build`

When ALL criteria pass, output:
<promise>COMPLETE</promise>
EXIT_SIGNAL: true
```

### Language That Improves Agent Behavior

From the Playbook:
- "Study the codebase first"
- "Don't assume not implemented"
- "Ultrathink before acting"
- "Capture the why in commits"

---

## Backpressure Mechanisms

The key insight: **autonomous loops converge when wrong outputs face rejection**.

### Three Layers of Backpressure

1. **Downstream Gates** (Most Important)
   - Tests must pass
   - Linting must pass
   - Build must succeed
   - Type checking must pass
   - *Deterministic and effective*

2. **Upstream Steering**
   - Existing code patterns guide approach
   - Agent discovers conventions through exploration
   - Less explicit instruction needed

3. **LLM-as-Judge** (Use Sparingly)
   - For subjective criteria (tone, UX feel)
   - Binary pass/fail evaluations
   - Add only AFTER mechanical backpressure works

### Strategy
```
Start with hard gates (tests, builds)
    ↓
Add linting and type checks
    ↓
Only then consider subjective evaluation
```

---

## File Structure That Works

From the Playbook:

| File | Purpose |
|------|---------|
| `loop.sh` | Bash orchestrator managing modes |
| `PROMPT_plan.md` | Planning-mode instructions |
| `PROMPT_build.md` | Building-mode instructions |
| `AGENTS.md` | Operational guide (keep under 60 lines!) |
| `specs/*.md` | One file per topic |
| `IMPLEMENTATION_PLAN.md` | Persistent state between iterations |

### Topic Scope Test

> Describe the spec in a single sentence without conjunctions. If "and" appears, split the file.

Example:
- JTBD: "Help designers create mood boards"
- Topics: image collection, color extraction, layout, sharing
- Each topic → one spec file → multiple tasks

---

## Context Efficiency

> "The 'dumb zone' begins around 40% token utilization."

### Why One Task Per Iteration

- Fresh context = cognitively sharp agent
- Prevents accumulated cruft
- Makes debugging easier
- Quality degrades as tokens accumulate

### Tactical Approaches

- Spawn subagents for expensive exploration
- Keep `AGENTS.md` concise (~60 lines)
- Trust discovered code patterns over exhaustive instructions
- Don't repeat information available in files

---

## The Progress File Pattern

From [Sid Bharath](https://sidbharath.com/blog/ralph-wiggum-claude-code/):

Maintain a simple log where Claude documents:
- What was accomplished this iteration
- What remains to be done
- Any blockers or decisions made

This helps fresh context windows understand current state without re-reading everything.

With Beads (Ralph Supreme), this is automatic via:
```bash
bd comment [task-id] "Completed X. Decision: used Y because Z."
bd ready  # Shows what's next
```

---

## Failure Modes & How to Avoid Them

### 1. Loops That Don't Converge
**Symptom**: Burning iterations without progress
**Cause**: Vague completion criteria
**Fix**: Make success measurable (tests pass, file exists, etc.)

### 2. Premature Completion Claims
**Symptom**: Claude says "done" but it's not
**Cause**: Self-assessed completion without verification
**Fix**: Add automated gates that MUST pass

### 3. Context Degradation
**Symptom**: Quality drops in later iterations
**Cause**: Too much in one iteration
**Fix**: One task per iteration, fresh context

### 4. Runaway Costs
**Symptom**: $100+ API bill
**Cause**: No iteration limits
**Fix**: Always set `--max-iterations`, start with 10-20

### 5. Stuck in Error Loops
**Symptom**: Same error repeated
**Cause**: No circuit breaker
**Fix**: Use Ralph Supreme's circuit breaker (3 no-progress = stop)

### 6. Stale Plans
**Symptom**: Fighting outdated implementation plan
**Cause**: Requirements shifted
**Fix**: Regenerate the plan — it's cheaper than salvaging

---

## Getting Started: The Safe Path

### Step 1: Start Small
```bash
# First run: small scope, low iterations
./ralph-supreme.sh \
  --prompt "Add type annotations to src/utils.ts" \
  --max-iterations 10 \
  --no-beads
```

### Step 2: Add Verification
Ensure your project has:
```bash
npm test          # Tests
npm run typecheck # Types
npm run lint      # Linting
npm run build     # Build
```

### Step 3: Graduate to Beads
```bash
# Planning enforced, tasks tracked
./ralph-supreme.sh \
  --prompt "Add user authentication with JWT" \
  --max-iterations 30
```

### Step 4: Overnight Runs
```bash
# Full autonomy with monitoring
./ralph-supreme.sh \
  --prompt "Migrate codebase from Express to Fastify" \
  --max-iterations 100 \
  --timeout 480 \
  --rate-limit 50 \
  --monitor
```

---

## Cost Management

> "A 50-iteration loop on a large codebase can easily cost $50-100+ in API credits."

### Budget Guidelines

| Task Size | Max Iterations | Expected Cost |
|-----------|----------------|---------------|
| Small fix | 5-10 | $1-5 |
| Medium feature | 20-30 | $10-30 |
| Large refactor | 50-100 | $30-100 |
| Migration | 100-200 | $50-200 |

### Cost Control Strategies

1. Set `--max-iterations` conservatively
2. Use `--rate-limit` to slow down (e.g., 50/hour)
3. Start with manual iterations to tune prompt
4. Use circuit breaker (built into Ralph Supreme)
5. Monitor with `--monitor` flag

---

## Real-World Success Stories

From community reports:

- **3-month loop**: Built complete programming language with compiler and standard library
- **YC Hackathon**: 6+ repositories shipped overnight for $297 in API costs
- **$50K contract**: Completed for under $300 in API costs
- **14-hour migration**: Framework migration, zero human intervention, all tests passing

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│  BEFORE STARTING                                            │
├─────────────────────────────────────────────────────────────┤
│  □ Can I define "done" precisely?                           │
│  □ Can success be verified automatically (tests/build)?     │
│  □ Is this mechanical execution, not judgment?              │
│  □ Have I set max-iterations?                               │
│  □ Do I have backpressure gates (tests, lint, types)?       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  PROMPT CHECKLIST                                           │
├─────────────────────────────────────────────────────────────┤
│  □ Clear objective (one sentence)                           │
│  □ Specific requirements (checkboxes)                       │
│  □ Measurable success criteria                              │
│  □ Completion signal specified                              │
│  □ Constraints noted (don't touch X, use pattern Y)         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  DURING EXECUTION                                           │
├─────────────────────────────────────────────────────────────┤
│  □ Monitor: tail -f logs/*.jsonl | jq                       │
│  □ Check state: cat .ralph-state.json                       │
│  □ Beads status: bd ready && bd status                      │
│  □ Watch for circuit breaker trips                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  IF STUCK                                                   │
├─────────────────────────────────────────────────────────────┤
│  1. Don't blame the loop — tune the prompt                  │
│  2. Add constraints ("don't touch X")                       │
│  3. Break task smaller                                      │
│  4. Regenerate the plan (cheaper than salvaging)            │
│  5. Add more backpressure gates                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Sources

- [The Ralph Wiggum Playbook](https://paddo.dev/blog/ralph-wiggum-playbook/) — Clayton Farr's comprehensive guide
- [Ralph Wiggum: Autonomous Loops](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/) — Core concepts
- [11 Tips for AI Coding with Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — AI Hero
- [Ralph Wiggum: The Dumbest Smart Way](https://sidbharath.com/blog/ralph-wiggum-claude-code/) — Sid Bharath
- [Geoffrey Huntley's Original Ralph](https://ghuntley.com/ralph/) — The originator
- [Frank Bria's Ralph-Claude-Code](https://github.com/frankbria/ralph-claude-code) — Safety-focused implementation
- [Beads Task Management](https://disruptedai.substack.com/p/persistent-task-management-with-beads) — Steve Yegge
