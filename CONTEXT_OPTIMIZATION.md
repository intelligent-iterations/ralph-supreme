# Context Optimization & Compaction Strategies

Research compiled from Anthropic's official guidance, academic papers, and community implementations for managing context in autonomous coding loops.

## The Core Problem

> "The 'dumb zone' begins around 40% token utilization."

Context windows have a **quality curve**:
- Early in the window: Claude is sharp
- As tokens accumulate: quality degrades
- Failed attempts, error logs, and mixed concerns **pollute** context
- Compaction can lose critical details

---

## Strategy 1: Fresh Context Per Iteration (Ralph Pattern)

**Philosophy**: Treat LLM context like malloc/free, not persistent memory.

From [Ralph Wiggum Cursor](https://github.com/agrimsingh/ralph-wiggum-cursor):

```
Iteration N → Commits to git → Fresh context Iteration N+1
                ↓
         Reads from:
         + git history (memory)
         + progress.txt (accomplishments)
         + guardrails.md (learned constraints)
         + TASK.md (current objective)
```

**Configuration:**
```bash
WARN_THRESHOLD=70000    # 70k tokens: send wrapup warning
ROTATE_THRESHOLD=80000  # 80k tokens: force rotation
MAX_ITERATIONS=20
```

**Benefits:**
- Each iteration starts cognitively sharp
- Git becomes the memory layer
- Failed attempts don't accumulate
- "Sawtooth" pattern vs monotonic growth

---

## Strategy 2: Anthropic's Two-Agent Architecture

From [Anthropic Engineering](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

### Initializer Agent (First Session Only)
- Sets up environment structure
- Creates `init.sh` for dev server
- Generates `claude-progress.txt`
- Establishes baseline git commit
- Develops feature list (JSON)

### Coding Agent (Subsequent Sessions)
- **One feature per session maximum**
- Reads progress artifacts first
- Makes atomic, documented changes
- Leaves "clean state" for next session

### The claude-progress.txt Pattern

Memory bridge between sessions:
```markdown
## Completed
- [x] Feature A: Authentication flow
- [x] Feature B: User profile page

## Current Status
Working on Feature C: Dashboard widgets

## Challenges
- API rate limiting required caching layer
- Chart library incompatible, switched to D3

## Next Session
- Complete dashboard widgets
- Begin Feature D: Export functionality
```

### Startup Protocol (Every Session)
1. `pwd` - confirm working directory
2. Read git logs + progress files
3. Review feature list, select next item
4. Run `init.sh`, verify baseline tests
5. Begin incremental work

---

## Strategy 3: Focus Architecture (Academic)

From [Active Context Compression paper](https://arxiv.org/html/2601.07190):

### The Knowledge Block Pattern

```
┌─────────────────────────────────────┐
│  KNOWLEDGE BLOCK (persistent)       │
│  - Previous learnings               │
│  - Discovered file paths            │
│  - Confirmed bugs                   │
│  - Architecture decisions           │
└─────────────────────────────────────┘
          ↑ append summaries
          │
┌─────────────────────────────────────┐
│  WORKING CONTEXT (prunable)         │
│  - Current exploration              │
│  - Tool call results                │
│  - Raw file contents                │
└─────────────────────────────────────┘
          ↓ delete after compression
```

### Compression Triggers
```
Start Focus  → Mark checkpoint (beginning subtask)
Complete Focus → Compress checkpoint to summary
                 Append to Knowledge block
                 Delete raw messages
```

### Results
- **22.7% token reduction** (14.9M → 11.5M)
- Maintained identical accuracy (60%)
- Exploration-heavy tasks: **50-57% savings**

### Critical Finding
> "When and how often to compress matters more than whether to compress."

- Compress every 10-15 tool calls
- Frequent small compressions > infrequent large ones
- LLMs **don't naturally optimize** for context efficiency
- Requires explicit scaffolding

---

## Strategy 4: Token Threshold Rotation

From [Vercel Ralph Loop Agent](https://github.com/vercel-labs/ralph-loop-agent):

### Stop Conditions
```javascript
// Stop when ANY condition triggers
stopConditions: [
  tokenCountIs(100000),      // Total tokens
  costIs(5.00),              // Dollar limit
  iterationCountIs(50)       // Iteration cap
]
```

### Real-Time Tracking
```
[12:35:10] 🟢 TOKENS: 45,230 / 80,000 (56%)
           [read:30KB write:5KB assist:10KB shell:0KB]

Status indicators:
🟢 Healthy  < 60%
🟡 Warning  60-80%
🔴 Critical > 80% → rotation imminent
```

---

## Strategy 5: Memory Layer (Hybrid RAG)

From [Auto-Claude](https://github.com/kouskousclan/auto-claude):

### Architecture
```
┌─────────────────┐     ┌─────────────────┐
│   Session N     │────▶│   FalkorDB      │
│   (fresh ctx)   │     │   (graph DB)    │
└─────────────────┘     └─────────────────┘
         │                      │
         │    query patterns    │
         │◀─────────────────────│
         │
    ┌────▼────┐
    │ Semantic │
    │ Search   │
    └──────────┘
```

### What Gets Persisted
- Codebase patterns (reusable across sessions)
- Architecture decisions
- Bug discoveries
- File relationships

### Benefits
- Fresh context each session (no pollution)
- Historical context informs decisions
- Pattern recognition across separate tasks
- ~98% prompt reduction for merge conflicts

---

## Strategy 6: Manual Compaction at Breakpoints

From [Claude Code Compaction Guide](https://stevekinney.com/courses/ai-development/claude-code-compaction):

### When to Compact
- After completing a task (before starting new one)
- During long problem-solving sessions
- **Before** hitting 95% auto-compact threshold

### Custom Compaction
```
/compact focus on:
- Current task objectives
- Decisions made and why
- File paths modified
- Test status
```

### The Document & Clear Pattern
```
1. Have Claude dump plan + progress to .md file
2. /clear the context
3. New session: "Read progress.md and continue"
```

---

## Strategy 7: Guardrails (Learning from Failures)

From Ralph Wiggum Cursor:

### The Signs Pattern
After each failure, write to `guardrails.md`:

```markdown
### Sign: Check imports before adding
- **Trigger**: Adding a new import statement
- **Instruction**: First check if import already exists
- **Added after**: Iteration 3 - duplicate import caused build failure

### Sign: Run type check before commit
- **Trigger**: Before any git commit
- **Instruction**: Execute `npm run typecheck` first
- **Added after**: Iteration 7 - type error broke build
```

Future iterations read guardrails **first**, preventing repeated mistakes.

---

## Implementation Comparison

| Strategy | Token Savings | Complexity | Best For |
|----------|:------------:|:----------:|----------|
| Fresh context per iteration | High | Low | Most Ralph loops |
| Two-agent architecture | Medium | Medium | Long projects |
| Focus compression | 22-57% | High | Exploration tasks |
| Token threshold rotation | Medium | Low | Cost control |
| Memory Layer (RAG) | High | High | Multi-session projects |
| Manual compaction | Variable | Low | Single sessions |
| Guardrails | Indirect | Low | Error-prone tasks |

---

## Recommended Approach for Ralph Supreme

### Current Implementation
Ralph Supreme already uses:
- ✅ Fresh context per iteration
- ✅ Git as memory layer
- ✅ Beads for task state
- ✅ Circuit breaker for stuck loops

### Potential Enhancements

**Quick Wins:**
1. Add `claude-progress.txt` pattern to execution prompts
2. Token threshold warnings before rotation
3. Guardrails file for learned constraints

**Medium Effort:**
4. Focus-style Knowledge block in system prompt
5. Compress every 10-15 tool calls instruction
6. Custom compaction instructions

**Future:**
7. Memory Layer integration (requires FalkorDB)
8. Two-agent architecture (initializer + coder)

---

## Anti-Patterns to Avoid

### The Amnesia Loop
```
Compaction triggers → Summary loses detail →
Model re-researches → Fills context → Compacts again →
Forgets again → Infinite loop
```
**Fix**: Preserve key facts in persistent file, not context.

### Context Pollution
```
Failed attempt 1 → Failed attempt 2 → Failed attempt 3 →
Context now 60% garbage → Quality degrades
```
**Fix**: Fresh context per iteration, or manual `/compact` after failures.

### Premature Auto-Compact
```
At 95% capacity → Auto-compact triggers →
Loses implementation details mid-feature →
Agent confused about state
```
**Fix**: Manual compact at natural breakpoints, not capacity limits.

### Over-Trusting Compaction
```
Important decision made → Compacted → Summary omits nuance →
Future session contradicts decision
```
**Fix**: Write critical decisions to files, not just conversation.

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│  CONTEXT HEALTH CHECKLIST                                   │
├─────────────────────────────────────────────────────────────┤
│  □ Using fresh context per iteration?                       │
│  □ Progress persisted to files (not just context)?          │
│  □ Git commits with descriptive messages?                   │
│  □ Token usage monitored?                                   │
│  □ Guardrails capturing learned constraints?                │
│  □ Compacting at breakpoints (not just capacity)?           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  WHEN CONTEXT FEELS POLLUTED                                │
├─────────────────────────────────────────────────────────────┤
│  1. Commit current progress to git                          │
│  2. Write summary to progress.txt                           │
│  3. Note any guardrails learned                             │
│  4. /clear or rotate to fresh context                       │
│  5. Start new session reading artifacts                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Sources

- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Active Context Compression (arxiv)](https://arxiv.org/html/2601.07190)
- [Ralph Wiggum Cursor (GitHub)](https://github.com/agrimsingh/ralph-wiggum-cursor)
- [Vercel Ralph Loop Agent (GitHub)](https://github.com/vercel-labs/ralph-loop-agent)
- [Auto-Claude (GitHub)](https://github.com/kouskousclan/auto-claude)
- [Claude Code Compaction Guide](https://stevekinney.com/courses/ai-development/claude-code-compaction)
- [What to Do When Claude Starts Compacting](https://www.duanlightfoot.com/posts/what-to-do-when-claude-code-starts-compacting/)
