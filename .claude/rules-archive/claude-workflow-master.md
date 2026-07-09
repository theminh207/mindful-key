# 🧠 CLAUDE CODE WORKFLOW — The Distilled Standard

> This rule governs how to use Claude Code effectively: context management, hooks, autonomous loops, multi-agent coordination, blueprint planning, and session strategy. Distilled from: ECC shortform-guide (432 lines), strategic-compact skill (132 lines), hookify-rules skill (129 lines), autonomous-loops skill (611 lines), blueprint skill (106 lines), search-first skill (162 lines), ECC CLAUDE.md (73 lines).
>
> **NOTE**: This is a META rule — it governs how to USE Claude Code, not what code to write. Coding standards are in the other 7 master rules.

---

## 1. CONTEXT WINDOW MANAGEMENT

> Your 200K context window can shrink to 70K with too many tools enabled. Context is PRECIOUS.

### 1.1 MCP Discipline

```
DO: Have 20-30 MCPs configured in settings
DO: Keep UNDER 10 MCPs enabled at any time
DO: Keep UNDER 80 tools active total
DO: Disable everything unused — navigate to /mcp

DON'T: Enable all MCPs simultaneously
DON'T: Add MCPs without disabling unused ones first
```

### 1.2 Strategic Compaction

Compact at **logical boundaries**, not arbitrary points:

| Phase Transition | Compact? | Why |
|-----------------|----------|-----|
| Research → Planning | ✅ Yes | Research context is bulky; plan is the distilled output |
| Planning → Implementation | ✅ Yes | Plan is saved to file; free up context for code |
| Implementation → Testing | ⚠️ Maybe | Keep if tests reference recent code |
| Debugging → Next feature | ✅ Yes | Debug traces pollute context for unrelated work |
| Mid-implementation | ❌ No | Losing file paths, variable names is costly |
| After failed approach | ✅ Yes | Clear dead-end reasoning before new approach |

### 1.3 What Survives Compaction

| ✅ Persists | ❌ Lost |
|-------------|---------|
| CLAUDE.md instructions | Intermediate reasoning |
| TodoWrite task list | File contents you previously read |
| Memory files | Multi-step conversation context |
| Git state (commits, branches) | Tool call history |
| Files on disk | Nuanced verbal preferences |

### 1.4 Before Compacting

```
1. Save important context to files or memory
2. Use /compact with a summary:
   /compact Focus on implementing auth middleware next
3. Write decisions to CLAUDE.md or memory if they must survive
```

### 1.5 Token Optimization

```
CLAUDE.md files     → Always loaded. Keep LEAN.
Rules files         → Loaded per paths: matcher. Use frontmatter.
Skills              → Each adds 1-5K tokens. Lazy-load via triggers.
Conversation history → Grows with each exchange
Tool results        → File reads, search results add bulk

Avoid: Same rules in both ~/.claude/rules/ AND project .claude/rules/
       Skills that repeat CLAUDE.md instructions
       Multiple skills covering overlapping domains
```

---

## 2. HOOK SYSTEM

### 2.1 Hook Types

| Hook | When | Common Use |
|------|------|------------|
| **PreToolUse** | Before tool executes | Validation, reminders, blocking dangerous ops |
| **PostToolUse** | After tool finishes | Auto-format, type-check, lint feedback |
| **UserPromptSubmit** | User sends message | Workflow enforcement |
| **Stop** | Claude finishes responding | Completion checks, cleanup reminders |
| **PreCompact** | Before context compaction | Save state to files |
| **Notification** | Permission requests | Custom notification routing |

### 2.2 Essential Hook Patterns

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash && (npm|pnpm|yarn|cargo|pytest)",
      "hooks": ["tmux reminder for long-running commands"]
    },
    {
      "matcher": "Bash && git push",
      "hooks": ["open editor for review before push"]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Edit && (.ts|.tsx|.js|.jsx)",
      "hooks": ["prettier --write (auto-format)"]
    },
    {
      "matcher": "Edit && (.ts|.tsx)",
      "hooks": ["tsc --noEmit (type-check)"]
    },
    {
      "matcher": "Edit",
      "hooks": ["grep console.log warning"]
    }
  ],
  "Stop": [
    {
      "matcher": "*",
      "hooks": ["check modified files for console.log"]
    }
  ]
}
```

### 2.3 Hookify Rules (Declarative)

```markdown
---
name: warn-env-api-keys
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$
  - field: new_text
    operator: contains
    pattern: API_KEY
---
You're adding an API key to a .env file. Ensure this file is in .gitignore!
```

**Naming**: `warn-*`, `block-*`, `require-*` (verb-first, kebab-case)
**Location**: `.claude/hookify.{name}.local.md`
**Gitignore**: `.claude/*.local.md`

---

## 3. AUTONOMOUS LOOPS

### 3.1 Loop Pattern Spectrum

| Pattern | Complexity | Best For |
|---------|-----------|----------|
| **Sequential Pipeline** | Low | Daily dev steps, scripted workflows |
| **De-Sloppify** | Add-on | Quality cleanup after any implement step |
| **Continuous PR Loop** | Medium | Multi-day iterative projects with CI gates |
| **DAG Orchestration** | High | Large features, parallel work with merge queue |

### 3.2 Sequential Pipeline (`claude -p`)

```bash
#!/bin/bash
set -e

# Step 1: Implement
claude -p "Read spec. Implement with TDD."

# Step 2: De-sloppify (cleanup pass)
claude -p "Review changes. Remove test/code slop. Run tests."

# Step 3: Verify
claude -p "Run build + lint + tests. Fix failures. No new features."

# Step 4: Commit
claude -p "Conventional commit for staged changes."
```

**Key principles**:
- Each `claude -p` = fresh context (no bleed)
- Order matters (each builds on filesystem state)
- Use `set -e` to stop pipeline on failure
- Route models: `--model opus` for research/review, default for implementation

### 3.3 De-Sloppify Pattern (CRITICAL)

```
PROBLEM: Telling AI "don't test type systems" makes it skip
         legitimate tests. Negative instructions have side effects.

SOLUTION: Let the Implementer be thorough. Then add a separate
          cleanup agent with focused instructions:

Step 1: claude -p "Implement with full TDD. Be thorough."
Step 2: claude -p "Cleanup: remove tests for language features,
                   redundant type checks, console.log, commented code.
                   Keep all business logic tests. Run tests after."

Two focused agents > one constrained agent.
```

### 3.4 Cross-Iteration Context

```markdown
# SHARED_TASK_NOTES.md — bridges context between claude -p calls

## Progress
- [x] Added tests for auth module (iteration 1)
- [x] Fixed edge case in token refresh (iteration 2)
- [ ] Still need: rate limiting tests

## Next Steps
- Focus on rate limiting module
- Reuse mock setup in tests/helpers.ts
```

Claude reads at iteration start, updates at iteration end.

### 3.5 Loop Safety

```
ALWAYS have exit conditions:
  --max-runs N         | Stop after N iterations
  --max-cost $X        | Stop after spending $X
  --max-duration 2h    | Stop after time elapsed
  --completion-signal   | Agent signals "done" (3 consecutive = stop)

NEVER: Run infinite loops without exit conditions
NEVER: Retry same failure blindly — capture error context first
```

---

## 4. BLUEPRINT PLANNING

### 4.1 When to Use

```
BLUEPRINT: Multi-session, multi-PR tasks where context loss causes rework
SIMPLE PLAN: Single-session tasks completable in one PR
JUST DO IT: Tasks under 3 tool calls
```

### 4.2 Blueprint Pipeline

```
1. RESEARCH — Pre-flight checks, read project structure
2. DESIGN — Break into one-PR-sized steps (3-12 typical)
   - Assign dependency edges
   - Detect parallel/serial ordering
   - Assign model tier per step
3. DRAFT — Self-contained Markdown plan
   - Every step has context brief (cold-start execution)
   - Task list, verification commands, exit criteria
4. REVIEW — Adversarial review by strongest model
5. REGISTER — Save plan, update memory
```

### 4.3 Cold-Start Execution

```
Every step includes a SELF-CONTAINED context brief:
  - What this step does
  - What files to read/modify
  - What the previous step produced
  - Acceptance criteria
  - Verification commands

A FRESH AGENT can execute ANY step without reading prior steps.
```

---

## 5. SUBAGENT COORDINATION

### 5.1 Agent Delegation Model

```
~/.claude/agents/
  planner.md           # Break down features → implementation plan
  architect.md         # System design decisions
  tdd-guide.md         # Test-driven development
  code-reviewer.md     # Quality/security review
  security-reviewer.md # Vulnerability analysis
  build-error-resolver.md
  e2e-runner.md        # Playwright tests
  refactor-cleaner.md  # Dead code removal
```

### 5.2 Agent Scoping Rules

```
DO: Limit agent tools with --allowedTools
DO: Give each agent a focused, single-responsibility prompt
DO: Use separate context windows for author/reviewer (no author-bias)
DO: Pass skill conventions into agent prompts

DON'T: Give all tools to all agents
DON'T: Let one agent do everything
DON'T: Let the code author review their own code
```

### 5.3 Model Routing Per Stage

| Stage | Model | Why |
|-------|-------|-----|
| Research, Context gathering | Sonnet | Fast, broad search |
| Architecture, Planning | Opus | Deep reasoning |
| Implementation | Sonnet/Default | Fast, capable coding |
| Code Review, Security | Opus | Thorough analysis |
| Simple fixes, formatting | Haiku | Cost-efficient |

---

## 6. SEARCH-FIRST DISCIPLINE

### 6.1 Before Writing ANY Utility

```
0. Does this already exist in the repo? → rg through modules
1. Is this a common problem? → Search npm/PyPI
2. Is there an MCP for this? → Check settings.json
3. Is there a skill for this? → Check ~/.claude/skills/
4. Is there a GitHub implementation? → Code search
```

### 6.2 Decision Matrix

| Signal | Action |
|--------|--------|
| Exact match, well-maintained, MIT/Apache | **Adopt** — install and use directly |
| Partial match, good foundation | **Extend** — install + thin wrapper |
| Multiple weak matches | **Compose** — combine 2-3 packages |
| Nothing suitable | **Build** — custom, but informed by research |

---

## 7. SESSION STRATEGY

### 7.1 Session Management

```
CONTINUE session: Closely-coupled work units
NEW session:      After major phase transitions
FORK (/fork):     Non-overlapping parallel tasks
GIT WORKTREES:    Overlapping parallel Claudes without conflicts

COMPACT after:    Milestones, NOT during active debugging
```

### 7.2 Parallel Execution

```bash
# Git worktrees for parallel Claude instances
git worktree add ../feature-branch feature-branch
cd ../feature-branch
claude  # Independent instance, no conflicts

# Or use /fork for non-overlapping tasks in same repo
```

### 7.3 Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+U` | Delete entire line |
| `!` | Quick bash command |
| `@` | Search for files |
| `/` | Slash commands |
| `Shift+Enter` | Multi-line input |
| `Tab` | Toggle thinking display |
| `Esc Esc` | Interrupt Claude / restore code |

---

## 8. ECC ECOSYSTEM STRUCTURE

```
~/.claude/
├── CLAUDE.md           ← Global instructions (always loaded, keep lean)
├── rules/              ← Always-follow guidelines (path-filtered .md files)
├── skills/             ← Workflow definitions (trigger on demand)
├── agents/             ← Subagent definitions (.md with frontmatter)
├── commands/           ← Slash command shims (legacy, migrate to skills)
├── settings.json       ← Hooks, MCPs, permissions, model preferences
└── memory/             ← Persistent state across sessions

.claude/                ← Project-level overrides
├── rules/              ← Project-specific guidelines
├── hookify.*.local.md  ← Project hookify rules (gitignored)
└── evals/              ← Eval definitions and run history
```

### 8.1 Format Reference

```
Agents:  Markdown + YAML frontmatter (name, description, tools, model)
Skills:  Markdown + sections (When to Use, How It Works, Examples)
Rules:   Markdown + paths: frontmatter (conditional loading)
Hooks:   JSON in settings.json (matcher + hooks array)
```

---

*Distilled from: ECC shortform-guide (432 lines), strategic-compact (132 lines), hookify-rules (129 lines), autonomous-loops (611 lines), blueprint (106 lines), search-first (162 lines), ECC CLAUDE.md (73 lines). Total: ~1645 lines → 390 lines. Last updated: 2026-04-09.*
