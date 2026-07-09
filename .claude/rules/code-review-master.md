---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.h"
  - "**/*.hpp"
  - "**/*.mm"
  - "**/*.m"
---

> 🗺️ **mindful-key (C++/ObjC):** gate thật = `make test` + `xcodebuild` sạch (KHÔNG tsc/ESLint). "Idiom TS" dưới đọc như *nguyên tắc*, ánh xạ sang C++/Objective-C. Ranh giới cứng: lỗi riêng 1 OS sửa ở `platforms/<os>/`, KHÔNG đụng `core/` (bộ não dùng chung).

# 🔍 CODE REVIEW & QUALITY GATE — Distilled

> Governs review, quality standards, TS idioms, performance, refactoring. SUPPLEMENTS project rules/Golden Rules — stricter wins.
> Full version with before/after code examples: `~/.claude/rules-archive/code-review-master.md`.

## 1. Review Discipline

**Auto-trigger (review MANDATORY):** auth/authz/RBAC, user input & file uploads, DB queries/schema, API endpoints, payment/financial logic, external API integrations, crypto, infra/deploy config.

**Confidence filtering (no noise):** report only if >80% confident it's real; skip stylistic prefs unless they violate project conventions; skip issues in unchanged code (unless CRITICAL security); consolidate similar issues into one finding; prioritize bugs/security/data-loss.

**Severity → action:** CRITICAL (security, data loss) = BLOCK · HIGH (bug, big quality issue) = WARN · MEDIUM (maintainability) = INFO · LOW (style) = NOTE. Approve if no CRITICAL/HIGH.

## 2. Code Quality Checklist

**Structure & size:** functions < 50 lines · files < 800 (warn at 500) · nesting ≤ 4 (early returns) · Single Responsibility · 3+ useState same domain → custom hook.

**Cleanliness:** no `console.log` in prod · no commented-out code (git has history) · no TODO/FIXME without issue number · no magic numbers (named constants) · no dead code (unused imports, unreachable branches) · no duplicate code.

**Error handling:** no empty catch (handle or rethrow) · no swallowed errors (log or propagate) · `JSON.parse` in try/catch · `throw new Error(msg)` not `throw "msg"` · generic user errors / detailed server logs · React ErrorBoundary around async/data subtrees.

**Naming:** descriptive names (no `x`/`tmp`/`data` in non-trivial context) · camelCase vars/fns, PascalCase types/components, SCREAMING_SNAKE constants · booleans `isActive`/`hasPermission`/`canEdit`.

## 3. TypeScript Review (HIGH priority)

**Type safety:** CẤM `any` → use `unknown` + type guard. CẤM `@ts-ignore`/`@ts-expect-error` without a why-comment. CẤM `as`-cast to bypass checks (validate instead — `as User` lies if runtime differs). No non-null `!` without a prior guard. Public functions need explicit return types.

**Async correctness:** no floating promises (`await` or `.catch()`). Independent awaits → `Promise.all`. NEVER `async` inside `forEach` (doesn't await — use `for...of` or `Promise.all(map)`).

**Node backend:** no sync I/O in request handlers (`readFileSync` blocks event loop → `fs.promises`). Validate env at startup (`if (!process.env.X) throw` — never trust undefined).

## 4. React Review

**Anti-patterns to catch:** incomplete `useEffect` deps (missing `userId` etc.) · index-as-key on reorderable lists (use stable `item.id`) · `useEffect` for derived state (compute in render / `useMemo`) · inline objects/functions causing re-renders (`useMemo`/`useCallback` stable refs).

**Checklist:** complete dependency arrays · no state updates during render (infinite loop) · no props drilled 3+ levels (context/composition) · loading + error states on all fetches · cleanup for listeners/timers/subscriptions · virtualize lists > 100 (react-window) · `React.lazy` + route-level code split.

## 5. Performance Review

**Core Web Vitals:** LCP < 2.5s (red > 4s) · FID < 100ms (> 300ms) · CLS < 0.1 (> 0.25) · TTI < 3.8s · bundle gzipped < 200KB (> 500KB).

**Algorithmic:** search-in-loop O(n²) → Map + O(1) lookup · sort once outside loop · string concat in loop → `array.join()` · deep clone → shallow/Immer · recursion → memoize.

**DB & network:** no `SELECT *` on user-facing endpoints · no N+1 (JOIN/include/batch) · LIMIT on paginated queries · index frequently-queried columns · connection pooling · timeouts on external HTTP · parallelize independent requests · cache expensive ops (TTL) · debounce rapid user actions.

**Memory leaks:** every `useEffect` with `addEventListener`/`setInterval`/`setTimeout`/subscription MUST clean up in the return. Closures over large data → `useRef`.

## 6. AI-Generated Code Review (extra scrutiny)

**Check:** behavioral regressions (silently changed existing behavior?) · hidden coupling · architecture drift (follows established patterns?) · over-engineering (abstractions for one use?) · security assumptions (trusted untrusted input?) · cost awareness (escalates to expensive model tiers?).

**AI blind spots (most common):** 1) copy-paste that misses module-specific differences 2) test/prod divergence (fixes one path, forgets the other) 3) over-abstraction for one-time use 4) missing edge cases (happy-path focus) 5) silent import re-org changing resolution.

## 7. Dead Code & Refactoring

Detect: `npx knip` (unused files/exports/deps) · `npx depcheck` · `npx ts-prune`. Safe removal: categorize SAFE (unused exports) / CAREFUL (dynamic imports) / RISKY (public API); remove one category at a time (deps → exports → files → duplicates); test + commit after each batch.

Simplify: nested logic → named functions · complex conditionals → early returns · callback chains → async/await · nested ternaries → if/else · long chains → intermediate vars · over-abstracted single-use helpers → inline.

**Rules:** never refactor during active feature dev · never refactor without test coverage · clarity over cleverness.

## 8. Review Output Format

Per finding: `[SEVERITY] title` + `File: path:line` + Issue (what + why it matters) + Fix (with before/after if useful). End with a severity-count summary table and a Verdict (Approve / Warning / Block).
