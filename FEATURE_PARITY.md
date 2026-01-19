# Ralph Implementation Feature Parity Chart

Comparison of Ralph Supreme against original implementations.

## Implementations Compared

| Implementation | Author | Language | Repository |
|----------------|--------|----------|------------|
| **Original Ralph** | Geoffrey Huntley | Bash | [ghuntley.com/ralph](https://ghuntley.com/ralph/) |
| **Anthropic Ralph Wiggum** | Anthropic | Bash | [claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code) |
| **Frank Bria's Ralph** | Frank Bria | Bash | [frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code) |
| **Ralph Orchestrator** | Mikey O'Brien | Rust | [mikeyobrien/ralph-orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) |
| **Ralph TUI** | Community | TypeScript | [ralph-tui.com](https://ralph-tui.com) |
| **Snarktank Ralph** | Snarktank | Bash | [snarktank/ralph](https://github.com/snarktank/ralph) |
| **Ralph Supreme** | This Project | Bash | (merged implementation) |

---

## Core Loop Features

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| While-true loop | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fresh context per iteration | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Max iteration limit | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Timeout limit | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ |
| Configurable via CLI | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Config file support | ❌ | ❌ | 🚧 | ✅ | ✅ | ❌ | ✅ |

**Legend:** ✅ = Implemented | ❌ = Not implemented | 🚧 = Planned/Partial

---

## Completion Detection

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| Completion promise (`<promise>`) | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| EXIT_SIGNAL detection | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Dual-condition gate | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Multiple indicator detection | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| PRD/JSON status tracking | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Beads integration (`bd ready`) | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |

---

## Safety & Rate Limiting

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| Rate limiting (calls/hour) | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Circuit breaker | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| No-progress detection | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Error streak detection | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| API limit handling (5hr) | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Backpressure/quality gates | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |

---

## Hooks & Lifecycle Events

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| Stop hook (intercept exit) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Pre-start hook | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Pre-iteration hook | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Post-iteration hook | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| On-complete hook | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| On-error hook | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Post-stop hook | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Event-driven coordination | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |

---

## State Management & Resume

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| State file persistence | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Resume from interruption | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Session continuity flag | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Scratchpad (shared memory) | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Session recording/replay | ❌ | ❌ | ❌ | 🚧 | ❌ | ❌ | ❌ |

---

## Task Management

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| PROMPT.md file | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PRD import/conversion | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| prd.json tracking | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Beads task management | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Planning phase (enforced) | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| Dependency graph | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Decision documentation | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Git Integration

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| Auto-commit per iteration | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| Git worktree support | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Git-backed state (Beads) | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| Branch per session | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Logging & Monitoring

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| Console output | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| JSONL structured logging | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Tmux monitoring dashboard | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Interactive TUI | ❌ | ❌ | ❌ | 🚧 | ✅ | ❌ | ❌ |
| Log rotation | ❌ | ❌ | 🚧 | ❌ | ❌ | ❌ | ❌ |
| Metrics/analytics | ❌ | ❌ | 🚧 | ❌ | ❌ | ❌ | ❌ |

---

## Multi-Agent & Extensibility

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| Multi-agent support | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Hat system (personas) | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Multiple LLM backends | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| Preset workflows | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Template system | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Skills/plugins | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ |

---

## Testing & CI/CD

| Feature | Original | Anthropic | Bria | Orchestrator | TUI | Snarktank | **Supreme** |
|---------|:--------:|:---------:|:----:|:------------:|:---:|:---------:|:-----------:|
| Test suite | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |
| CI/CD pipeline | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |
| E2E tests | ❌ | ❌ | 🚧 | ❌ | ❌ | ❌ | ❌ |

---

## Feature Count Summary

| Implementation | ✅ Features | 🚧 Partial | Total Possible |
|----------------|:-----------:|:----------:|:--------------:|
| Original Ralph | 4 | 0 | 58 |
| Anthropic Ralph Wiggum | 10 | 0 | 58 |
| Frank Bria's Ralph | 24 | 5 | 58 |
| Ralph Orchestrator | 21 | 2 | 58 |
| Ralph TUI | 18 | 0 | 58 |
| Snarktank Ralph | 12 | 0 | 58 |
| **Ralph Supreme** | **32** | 0 | 58 |

---

## Unique Features by Implementation

### Original Ralph (Geoffrey Huntley)
- Foundational philosophy: "Ralph is a bash loop"
- Emphasis on operator skill and prompt tuning
- Minimal by design

### Anthropic Ralph Wiggum
- Official Anthropic implementation
- Stop hook mechanism (intercepts Claude's exit)
- Plugin architecture integration

### Frank Bria's Ralph
- Most comprehensive safety features
- Circuit breaker with three-state pattern
- 276+ tests with CI/CD
- 5-hour API limit handling
- Session continuity

### Ralph Orchestrator
- Multi-agent with Hat system
- Event-driven coordination
- 20+ preset workflows
- Rust implementation (performance)
- Scratchpad shared memory

### Ralph TUI
- Interactive terminal UI
- Multiple AI backend support
- Handlebars template system
- Bundled skills for PRD creation

### Snarktank Ralph
- PRD-focused workflow
- Learnings file (AGENTS.md)
- Quality gates (tests must pass)

### Ralph Supreme (This Project)
- **Merged features** from Anthropic + Bria
- **Beads integration** with planning enforcement
- **6 lifecycle hooks** (most comprehensive)
- **Git worktree** isolation
- **Decision documentation** via Beads comments
- **Dual-gate completion** + Beads completion

---

## What Ralph Supreme Lacks

Features not yet implemented that exist elsewhere:

| Feature | Found In | Priority |
|---------|----------|----------|
| Multi-agent/Hat system | Orchestrator | Medium |
| PRD import conversion | Bria, TUI | Low |
| Interactive TUI | TUI, Orchestrator | Low |
| Multiple LLM backends | Orchestrator, TUI | Medium |
| Stop hook (intercept exit) | Anthropic | Low |
| Test suite | Bria, Orchestrator | High |
| 5-hour API limit handling | Bria | Medium |
| Template system | Bria, Orchestrator, TUI | Low |
| Preset workflows | Orchestrator | Low |
| Session continuity flag | Bria | Medium |

---

## Sources

- [ghuntley.com/ralph](https://ghuntley.com/ralph/) - Original Ralph concept
- [Anthropic Claude Code Plugins](https://github.com/anthropics/claude-code) - Ralph Wiggum
- [frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code) - Frank Bria's implementation
- [mikeyobrien/ralph-orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) - Ralph Orchestrator
- [ralph-tui.com](https://ralph-tui.com/docs/getting-started/introduction) - Ralph TUI
- [snarktank/ralph](https://github.com/snarktank/ralph) - Snarktank Ralph
- [Beads Task Management](https://disruptedai.substack.com/p/persistent-task-management-with-beads) - Steve Yegge
