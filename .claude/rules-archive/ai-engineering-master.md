# 🤖 AI ENGINEERING — The Distilled Standard

> This rule governs building AI-powered features: prompt design, eval-driven development, cost-aware model routing, agentic workflows, and RAG patterns. Distilled from: ECC eval-harness skill (271 lines), agent-eval skill (146 lines), cost-aware-llm-pipeline skill (184 lines), agentic-engineering skill (64 lines), ai-first-engineering skill (52 lines), prompt-optimizer skill (398 lines), iterative-retrieval skill (212 lines), gan-evaluator agent (210 lines).
>
> **NOTE**: This rule applies when BUILDING AI features (calling LLM APIs, designing prompts, writing evals). For REVIEWING AI-generated code, see `code-review-master.md` section 6.

---

## 1. EVAL-DRIVEN DEVELOPMENT (EDD)

> "Evals are the unit tests of AI development."

### 1.1 The EDD Loop

```
1. DEFINE evals BEFORE implementation (capability + regression)
2. RUN baseline — capture current failure signatures
3. IMPLEMENT the feature
4. RE-RUN evals — compare deltas
5. REPORT pass@k metrics
```

### 1.2 Eval Types

| Type | Purpose | When |
|------|---------|------|
| **Capability Eval** | Can the system do something NEW? | Before each feature |
| **Regression Eval** | Does existing behavior still work? | After each change |
| **Product Eval** | Is the behavior GOOD (not just correct)? | Before release |

### 1.3 Grader Types (Choose wisely)

| Grader | When to Use | Reliability |
|--------|-------------|-------------|
| **Code-based** | Deterministic checks (tests pass, file exists, pattern matches) | ⭐⭐⭐ Highest |
| **Rule-based** | Regex, schema, constraint checks | ⭐⭐⭐ High |
| **Model-based** | LLM-as-judge for open-ended quality | ⭐⭐ Medium (add rubric) |
| **Human** | Security, UX quality, ambiguous outputs | ⭐⭐⭐ Gold standard |

**Rule**: Use code graders when possible. Model graders are supplements, not substitutes. Never fully automate security checks.

### 1.4 pass@k Metrics

```
pass@1: Direct reliability (first attempt success rate)
pass@3: Practical reliability (success within 3 attempts)
pass^3: Stability (ALL 3 runs must pass — use for critical paths)

Targets:
  Capability evals: pass@3 >= 90%
  Regression evals: pass^3 = 100% for release-critical
```

### 1.5 Eval Storage

```
.claude/evals/
├── <feature>.md      ← Eval definition
├── <feature>.log     ← Run history
└── baseline.json     ← Regression baselines

docs/releases/<version>/eval-summary.md  ← Release snapshot
```

### 1.6 Eval Anti-Patterns

- ❌ Overfitting prompts to known eval examples
- ❌ Testing only happy path
- ❌ Ignoring cost/latency while chasing pass rates
- ❌ Allowing flaky graders in release gates
- ❌ Running evals only at the end (run continuously)

---

## 2. COST-AWARE MODEL ROUTING

### 2.1 Tiered Model Strategy

| Tier | Model | Use For | Relative Cost |
|------|-------|---------|---------------|
| **Fast** | Haiku | Classification, boilerplate, narrow edits, formatting | 1x |
| **Standard** | Sonnet | Implementation, refactoring, standard coding | ~4x |
| **Deep** | Opus | Architecture, root-cause analysis, multi-file invariants | ~19x |

**Rule**: Start with cheapest model. Escalate ONLY when lower tier fails with a clear reasoning gap.

### 2.2 Routing Heuristics

```
Text < 10K chars AND items < 30  → Haiku (fast tier)
Text >= 10K chars OR items >= 30 → Sonnet (standard tier)
Multi-file invariants, architecture → Opus (deep tier)
Force override                    → Use specified model

Always allow force_model parameter for manual override.
```

### 2.3 Budget Discipline

```typescript
// MANDATORY for batch processing:
interface CostTracker {
  budgetLimit: number;      // Max USD to spend
  records: CostRecord[];    // Immutable append-only log
  totalCost: number;        // Running total
  overBudget: boolean;      // Halt signal
}

// Track per API call:
// - model used
// - input/output tokens
// - cost in USD
// - wall-clock time
// - success/failure

// Set explicit budget BEFORE processing batches
// Fail early rather than overspend
```

### 2.4 Prompt Caching

```
System prompts > 1024 tokens → USE cache_control: ephemeral
Variable user content → NOT cached (changes each request)

Benefits: Saves both cost (~90% on cached tokens) and latency
```

### 2.5 Retry Logic

```
RETRY: Transient errors only (network, rate limit, server 500)
FAIL FAST: Auth errors, validation errors, bad requests
Backoff: 1s → 2s → 4s (exponential)
Max retries: 3
```

---

## 3. AGENTIC ENGINEERING

### 3.1 Operating Principles

```
1. Define completion criteria BEFORE execution
2. Decompose work into agent-sized units
3. Route model tiers by task complexity
4. Measure with evals and regression checks
```

### 3.2 Task Decomposition (15-Minute Rule)

Each agent task unit should be:
- **Independently verifiable** — has its own pass/fail criteria
- **Single dominant risk** — one thing that can go wrong
- **Clear done condition** — not "make it better" but "function returns correct type"

### 3.3 Scope Assessment

| Scope | Heuristic | Approach |
|-------|-----------|----------|
| **TRIVIAL** | Single file, < 50 lines | Direct execution |
| **LOW** | Single component/module | Single skill |
| **MEDIUM** | Multiple components, same domain | Skill chain + verify |
| **HIGH** | Cross-domain, 5+ files | Plan first → phased execution |
| **EPIC** | Multi-session, architectural shift | Blueprint → phased PRs |

### 3.4 Session Strategy

```
CONTINUE session: Closely-coupled work units
NEW session: After major phase transitions
COMPACT: After milestone completion, NOT during active debugging
```

---

## 4. PROMPT ENGINEERING PRINCIPLES

### 4.1 Structured Prompt Anatomy

Every well-formed prompt includes:

```
1. CONTEXT — Tech stack, project background, what exists
2. TASK — Specific action to take (verb + noun + scope)
3. CONSTRAINTS — What NOT to do, boundaries
4. ACCEPTANCE CRITERIA — How to know it's done
5. VERIFICATION — How to prove it works
```

### 4.2 Missing Context Checklist

Before sending ANY prompt to an LLM, verify:

```
□ Tech stack specified (or auto-detected)
□ Target scope (files, modules, endpoints)
□ Acceptance criteria (measurable outcomes)
□ Error handling expectations
□ Security requirements (if auth/data involved)
□ Testing expectations (unit, integration, E2E)
□ Existing patterns to follow (reference files)
□ Scope boundaries (what NOT to change)
```

**If 3+ items missing**: Ask clarifying questions before proceeding.

### 4.3 Prompt Quality Signals

| Good Prompt | Bad Prompt |
|-------------|-----------|
| "Add PATCH /api/users/:id with Zod validation, returning 400 on invalid input" | "Add user update endpoint" |
| "Use existing repository pattern from src/users/repo.ts" | "Follow best practices" |
| "Do not modify existing endpoints or schema" | (no boundaries stated) |
| "Tests should cover: success, validation error, 401, 404" | "Add tests" |

---

## 5. RAG & RETRIEVAL PATTERNS

### 5.1 Iterative Retrieval Loop

Solves "context problem" in multi-agent/RAG systems:

```
Phase 1: DISPATCH — Broad keyword search for candidate files
Phase 2: EVALUATE — Score relevance (0-1), identify gaps
Phase 3: REFINE — Update query with discovered terminology
Phase 4: LOOP — Repeat (max 3 cycles), then proceed

Exit condition: 3+ files with relevance >= 0.7 AND no critical gaps
```

### 5.2 Relevance Scoring

```
0.8-1.0: HIGH — Directly implements target functionality → INCLUDE
0.5-0.7: MEDIUM — Contains related patterns/types → MAYBE
0.2-0.4: LOW — Tangentially related → EXCLUDE
0.0-0.2: NONE — Not relevant → SKIP and add to exclude list
```

### 5.3 RAG Best Practices

```
□ Start broad, narrow progressively (don't over-specify initial queries)
□ Learn project terminology in first cycle (codebase != your assumptions)
□ Track what's MISSING explicitly — gap identification drives refinement
□ Stop at "good enough" — 3 high-relevance files > 10 mediocre ones
□ Exclude confidently — low-relevance files won't magically become relevant
```

---

## 6. GAN-STYLE QUALITY LOOPS

### 6.1 Generator-Evaluator Pattern

```
Generator → builds/modifies the feature
Evaluator → tests the LIVE product, scores against rubric, gives feedback
Loop → Generator fixes issues → Evaluator re-scores

Exit: Weighted score >= 7.0/10
```

### 6.2 Evaluation Scoring

```
Weighted Score = (Design × 0.3) + (Originality × 0.2) + (Craft × 0.3) + (Functionality × 0.2)

Scale calibration:
  1-3: Broken, embarrassing
  4-5: Functional but "AI-generated" feel
  6:   Decent but unremarkable
  7:   Good — junior developer solid work
  8:   Very good — professional quality
  9:   Excellent — senior developer quality
  10:  Exceptional — ship as real product
```

### 6.3 Evaluator Discipline

```
DO: Test edge cases (empty, long, special chars, rapid actions)
DO: Compare against what a HUMAN professional would ship
DO: Penalize AI-slop (generic gradients, stock layouts)
DO: Provide actionable "how to fix" for every issue found

DON'T: Say "overall good effort" or "solid foundation" (cope)
DON'T: Give points for effort or potential
DON'T: Talk yourself out of issues ("it's minor, probably fine")
```

---

## 7. AI-FIRST ARCHITECTURE

When building systems that AI agents will maintain:

### 7.1 Agent-Friendly Architecture

```
PREFER:                              AVOID:
  Explicit boundaries                  Implicit conventions
  Stable typed contracts               Dynamic duck typing
  Deterministic tests                  Non-deterministic assertions
  Clear module boundaries              Cross-cutting magic
  Composition root wiring              Hidden service locators
```

### 7.2 AI-First Team Process

```
Planning quality matters MORE than typing speed
Eval coverage matters MORE than anecdotal confidence
Review focus shifts from SYNTAX to SYSTEM BEHAVIOR
Testing bar is HIGHER for AI-generated code

Strong AI-first engineers:
  - Decompose ambiguous work cleanly
  - Define measurable acceptance criteria
  - Produce high-signal prompts and evals
  - Enforce risk controls under delivery pressure
```

---

*Distilled from: ECC eval-harness (271 lines), agent-eval (146 lines), cost-aware-llm-pipeline (184 lines), agentic-engineering (64 lines), ai-first-engineering (52 lines), prompt-optimizer (398 lines), iterative-retrieval (212 lines), gan-evaluator (210 lines). Total: ~1537 lines → 340 lines. Last updated: 2026-04-09.*
