---
paths:
  - "models/**"
  - "**/*.onnx"
  - "**/*.mlmodel"
  - "**/*.tflite"
  - "core/mood/**"
  - "**/*sentiment*"
  - "**/*SEND-RISK*"
---

> 🗺️ **mindful-key (AI on-device):** không phải LLM/agent/RAG qua API — mà là **model sentiment tiếng Việt chạy TẠI MÁY** (lexicon → PhoBERT ONNX), cho điểm **send-risk 0–1** để gác cổng gửi tin. Xem `docs/SEND-RISK-MODEL-SPEC.md`. Nguyên tắc eval-driven / đo đạc dưới vẫn dùng được; ràng buộc cứng: chạy on-device, KHÔNG gửi nội dung gõ ra ngoài (riêng tư theo HIẾN CHƯƠNG).

# 🤖 AI ENGINEERING — Distilled

> Governs BUILDING AI features: prompt design, eval-driven dev, cost-aware routing, agentic workflows, RAG. For REVIEWING AI-generated code → `code-review-master.md` §6.
> Full version: `~/.claude/rules-archive/ai-engineering-master.md`.

## 1. Eval-Driven Development (evals = unit tests of AI)

**EDD loop:** define evals BEFORE implementation (capability + regression) → run baseline (capture failure signatures) → implement → re-run + compare deltas → report pass@k.

**Eval types:** Capability (can it do something NEW? — before each feature) · Regression (does existing still work? — after each change) · Product (is it GOOD not just correct? — before release).

**Grader types (reliability):** Code-based ⭐⭐⭐ (deterministic: tests/file/pattern) · Rule-based ⭐⭐⭐ (regex/schema/constraint) · Model-based ⭐⭐ (LLM-judge for open-ended — add rubric) · Human ⭐⭐⭐ (security, UX, ambiguous). **Rule:** prefer code graders; model graders supplement, never substitute; never fully automate security checks.

**pass@k:** pass@1 = first-attempt reliability · pass@3 = success within 3 · pass^3 = ALL 3 must pass (critical paths). Targets: capability pass@3 ≥ 90%, regression pass^3 = 100% for release-critical.

**Storage:** `.claude/evals/<feature>.md` (definition) + `.log` (history) + `baseline.json` (regression); `docs/releases/<version>/eval-summary.md` (snapshot).

**Anti-patterns:** overfitting prompts to known eval examples · happy-path only · ignoring cost/latency while chasing pass rates · flaky graders in release gates · running evals only at the end (run continuously).

## 2. Cost-Aware Model Routing

**Tiered strategy (relative cost):** Fast/Haiku 1x (classification, boilerplate, narrow edits) · Standard/Sonnet ~4x (implementation, refactoring) · Deep/Opus ~19x (architecture, root-cause, multi-file invariants). **Rule:** start cheapest, escalate ONLY when a lower tier fails with a clear reasoning gap; always allow a `force_model` override.

**Routing heuristics:** text < 10K chars AND items < 30 → Fast · text ≥ 10K OR items ≥ 30 → Standard · multi-file invariants/architecture → Deep.

**Budget discipline (mandatory for batch):** set an explicit USD budget BEFORE processing; track per call (model, in/out tokens, USD, wall-time, success/failure) in an immutable append-only log with a running total + over-budget halt signal; fail early rather than overspend.

**Prompt caching:** system prompts > 1024 tokens → `cache_control: ephemeral` (~90% cost + latency savings on cached tokens); variable user content NOT cached.

**Retry:** transient only (network, rate limit, 500) with backoff 1s→2s→4s, max 3. Fail fast on auth/validation/bad-request.

## 3. Agentic Engineering

**Operating principles:** define completion criteria BEFORE execution · decompose into agent-sized units · route model tiers by complexity · measure with evals + regression.

**Task unit (15-min rule):** independently verifiable (own pass/fail) · single dominant risk · clear done condition (not "make it better" but "function returns correct type").

**Scope → approach:** TRIVIAL (1 file, <50 lines) direct · LOW (1 component) single skill · MEDIUM (multi-component, same domain) skill chain + verify · HIGH (cross-domain, 5+ files) plan → phased · EPIC (multi-session, architectural) blueprint → phased PRs.

**Session:** continue for closely-coupled units · new session after major phase transitions · compact after milestones, NOT during active debugging.

## 4. Prompt Engineering

**Anatomy:** 1) CONTEXT (stack, background, what exists) 2) TASK (verb + noun + scope) 3) CONSTRAINTS (what NOT to do) 4) ACCEPTANCE CRITERIA (how to know it's done) 5) VERIFICATION (how to prove it works).

**Missing-context checklist:** stack · target scope (files/modules/endpoints) · measurable acceptance criteria · error-handling expectations · security requirements · testing expectations · existing patterns to follow · scope boundaries. **If 3+ missing → ask before proceeding.**

**Quality signal:** specific + bounded + reference-file + enumerated test cases ("Add PATCH /api/users/:id with Zod, 400 on invalid; use repo pattern from src/users/repo.ts; don't touch other endpoints; test success/validation/401/404") beats vague ("add user update endpoint, follow best practices, add tests").

## 5. RAG & Retrieval

**Iterative retrieval loop:** DISPATCH (broad keyword search) → EVALUATE (score relevance 0-1, identify gaps) → REFINE (update query with discovered terminology) → LOOP (max 3 cycles). Exit: 3+ files with relevance ≥ 0.7 AND no critical gaps.

**Relevance scoring:** 0.8-1.0 HIGH (directly implements → INCLUDE) · 0.5-0.7 MEDIUM (related patterns → MAYBE) · 0.2-0.4 LOW (tangential → EXCLUDE) · 0-0.2 NONE (→ skip + add to exclude list).

**Best practices:** start broad, narrow progressively · learn project terminology in cycle 1 (codebase ≠ your assumptions) · track what's MISSING explicitly (drives refinement) · stop at good-enough (3 high-relevance > 10 mediocre) · exclude confidently.

## 6. GAN-Style Quality Loops

**Generator-Evaluator:** Generator builds/modifies → Evaluator tests the LIVE product, scores vs rubric, gives feedback → loop until weighted score ≥ 7.0/10.

**Scoring:** `(Design ×0.3) + (Originality ×0.2) + (Craft ×0.3) + (Functionality ×0.2)`. Calibration: 1-3 broken · 4-5 "AI-generated" feel · 6 unremarkable · 7 solid junior · 8 professional · 9 senior · 10 ship-as-product.

**Evaluator discipline:** DO test edge cases (empty/long/special-chars/rapid) · compare to what a HUMAN pro would ship · penalize AI-slop · give actionable fixes. DON'T say "solid foundation"/"good effort" (cope) · give points for effort/potential · talk yourself out of issues ("minor, probably fine").

## 7. AI-First Architecture

**Prefer** (for systems agents maintain): explicit boundaries · stable typed contracts · deterministic tests · clear module boundaries · composition-root wiring. **Avoid:** implicit conventions · dynamic duck typing · non-deterministic assertions · cross-cutting magic · hidden service locators.

**Process shift:** planning quality > typing speed · eval coverage > anecdotal confidence · review focus SYNTAX → SYSTEM BEHAVIOR · testing bar HIGHER for AI-generated code.
