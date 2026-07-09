---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# 🔍 CODE REVIEW & QUALITY GATE — The Distilled Standard

> This rule governs code review, quality standards, TypeScript idioms, performance patterns, and refactoring discipline. Distilled from: ECC code-reviewer agent (238 lines), typescript-reviewer agent (113 lines), performance-optimizer agent (447 lines), refactor-cleaner agent (86 lines), code-simplifier agent (48 lines), common/code-review rules (125 lines), coding-standards skill, plankton-code-quality skill.
>
> **NOTE**: This rule SUPPLEMENTS project-specific rules and Golden Rules. It does NOT replace them. When both exist, the stricter rule wins.

---

## 1. REVIEW DISCIPLINE

### 1.1 When to Review (Auto-Trigger)

Review is MANDATORY when modifying:
- Authentication, authorization, or RBAC code
- User input handling, file uploads
- Database queries or schema changes
- API endpoints (new or modified)
- Payment or financial logic
- External API integrations
- Cryptographic operations
- Infrastructure or deployment config

### 1.2 Confidence-Based Filtering

Do NOT flood reviews with noise:
- **Report** if >80% confident it is a real issue
- **Skip** stylistic preferences unless they violate project conventions
- **Skip** issues in unchanged code (unless CRITICAL security)
- **Consolidate** similar issues ("5 functions missing error handling" → 1 finding)
- **Prioritize** issues that cause bugs, security holes, or data loss

### 1.3 Review Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| **CRITICAL** | Security vulnerability, data loss risk | **BLOCK** — Must fix before merge |
| **HIGH** | Bug, significant quality issue | **WARN** — Should fix before merge |
| **MEDIUM** | Maintainability concern | **INFO** — Consider fixing |
| **LOW** | Style, minor suggestion | **NOTE** — Optional |

**Approval Criteria:**
- **Approve**: No CRITICAL or HIGH issues
- **Warning**: HIGH issues only (merge with caution)
- **Block**: Any CRITICAL issue → must fix

---

## 2. CODE QUALITY CHECKLIST

Before marking ANY code change complete:

### Structure & Size
```
□ Functions < 50 lines (extract helpers if larger)
□ Files < 800 lines (extract modules if larger — WARNING at 500)
□ No deep nesting > 4 levels (use early returns)
□ Single Responsibility — each file/function does ONE thing
□ 3+ useState in same domain → extract custom hook
```

### Cleanliness
```
□ No console.log / console.debug in production code
□ No commented-out code (delete it, git has history)
□ No TODO/FIXME without issue numbers
□ No magic numbers — use named constants
□ No dead code — unused imports, unreachable branches
□ No duplicate code — extract to shared utility
```

### Error Handling
```
□ No empty catch blocks — handle or rethrow
□ No swallowed errors — always log or propagate
□ JSON.parse wrapped in try/catch
□ throw new Error("message") — not throw "message"
□ Error messages generic for users, detailed in server logs
□ React: ErrorBoundary around async/data-fetching subtrees
```

### Naming
```
□ Descriptive variable names (no x, tmp, data in non-trivial context)
□ camelCase for variables/functions, PascalCase for types/components
□ Constants in SCREAMING_SNAKE_CASE
□ Boolean: isActive, hasPermission, canEdit (not active, permission, edit)
```

---

## 3. TYPESCRIPT-SPECIFIC REVIEW

### 3.1 Type Safety (HIGH Priority)

```typescript
// BAD: Disables type checking entirely
const data: any = fetchData();

// GOOD: Use unknown + narrowing
const data: unknown = fetchData();
if (isUserData(data)) { /* now typed */ }

// BAD: Non-null assertion without guard
const name = user!.name;

// GOOD: Runtime check first
if (!user) throw new Error('User not found');
const name = user.name;

// BAD: as-cast that lies
const user = response as User; // might not be User at runtime

// GOOD: Validate first
const user = validateUser(response); // throws if invalid
```

**Rules:**
- CẤM `any` (use `unknown` + type guard)
- CẤM `@ts-ignore` / `@ts-expect-error` without comment explaining why
- CẤM `as` cast to bypass checks — fix the actual type
- Public functions MUST have explicit return types

### 3.2 Async Correctness (HIGH Priority)

```typescript
// BAD: Unhandled promise rejection
async function riskyCall() { /* ... */ }
riskyCall(); // floating promise!

// GOOD: Handle errors
riskyCall().catch(handleError);
// or
await riskyCall();

// BAD: Sequential when independent
const user = await fetchUser(id);
const posts = await fetchPosts(id);

// GOOD: Parallel when independent
const [user, posts] = await Promise.all([
  fetchUser(id),
  fetchPosts(id),
]);

// BAD: forEach with async
items.forEach(async (item) => { await process(item); }); // Does NOT await!

// GOOD: for...of or Promise.all
for (const item of items) { await process(item); }
// or
await Promise.all(items.map(item => process(item)));
```

### 3.3 Node.js Backend Patterns (HIGH Priority)

```typescript
// BAD: Synchronous I/O in request handler
const data = fs.readFileSync('file.json'); // Blocks event loop!

// GOOD: Async I/O
const data = await fs.promises.readFile('file.json');

// BAD: Unvalidated env access
const apiKey = process.env.API_KEY; // might be undefined

// GOOD: Validate at startup
const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error('API_KEY not configured');
```

---

## 4. REACT REVIEW PATTERNS

### 4.1 Common Anti-Patterns to Catch

```tsx
// BAD: Missing dependency in useEffect
useEffect(() => {
  fetchData(userId);
}, []); // userId missing!

// GOOD: Complete deps
useEffect(() => {
  fetchData(userId);
}, [userId]);

// BAD: Index as key with reorderable list
{items.map((item, i) => <Item key={i} />)}

// GOOD: Stable unique key
{items.map(item => <Item key={item.id} />)}

// BAD: useEffect for derived state
useEffect(() => {
  setFilteredItems(items.filter(i => i.active));
}, [items]);

// GOOD: Compute during render
const filteredItems = useMemo(
  () => items.filter(i => i.active),
  [items]
);

// BAD: Inline objects/functions causing re-renders
<Child style={{ color: 'red' }} onClick={() => handle(id)} />

// GOOD: Stable references
const style = useMemo(() => ({ color: 'red' }), []);
const handleClick = useCallback(() => handle(id), [id]);
<Child style={style} onClick={handleClick} />
```

### 4.2 React Quality Checklist

```
□ useEffect/useMemo/useCallback have complete dependency arrays
□ No state updates during render (infinite loop)
□ No props drilled through 3+ levels (use context or composition)
□ Loading and error states for all data fetching
□ useEffect cleanup for event listeners, timers, subscriptions
□ Virtualization for lists > 100 items (react-window)
□ React.lazy for heavy components, code splitting at route level
```

---

## 5. PERFORMANCE REVIEW

### 5.1 Core Web Vitals Targets

| Metric | Target | Red Flag |
|--------|--------|----------|
| LCP (Largest Contentful Paint) | < 2.5s | > 4s |
| FID (First Input Delay) | < 100ms | > 300ms |
| CLS (Cumulative Layout Shift) | < 0.1 | > 0.25 |
| TTI (Time to Interactive) | < 3.8s | > 7.3s |
| Bundle Size (gzipped) | < 200KB | > 500KB |

### 5.2 Algorithmic Complexity

| Pattern | Bad | Good |
|---------|-----|------|
| Search in loop | O(n²) — `.filter()` inside `.map()` | O(n) — Convert to Map, then O(1) lookup |
| Sort in loop | O(n² log n) | Sort once outside loop |
| String concat in loop | O(n²) | Use `array.join()` |
| Deep clone large objects | O(n) each time | Shallow copy or Immer |
| Recursion without memo | O(2^n) | Add memoization |

### 5.3 Database & Network

```
□ No SELECT * on user-facing endpoints — select only needed columns
□ No N+1 queries — use JOINs, includes, or batch fetch
□ All queries have LIMIT for paginated results
□ Indexes on frequently queried columns
□ Connection pooling configured
□ External HTTP calls have timeout configured
□ Independent requests parallelized with Promise.all
□ Expensive operations cached (TTL-based)
□ Rapid user actions debounced (search, autocomplete)
```

### 5.4 Memory Leak Prevention

```
Every useEffect with addEventListener → MUST have removeEventListener in cleanup
Every useEffect with setInterval/setTimeout → MUST have clear in cleanup
Every useEffect with subscription → MUST have unsubscribe in cleanup
Every closure over large data → Use useRef instead
```

---

## 6. AI-GENERATED CODE REVIEW

When reviewing code that was written by an AI agent:

### 6.1 Extra Scrutiny Points

```
□ Behavioral regressions — did the AI silently change existing behavior?
□ Hidden coupling — did the AI introduce tight coupling between modules?
□ Architecture drift — does the change follow established patterns?
□ Over-engineering — did the AI add unnecessary abstractions?
□ Security assumptions — did the AI trust untrusted input?
□ Cost awareness — does the change escalate to expensive model tiers unnecessarily?
```

### 6.2 AI Blind Spots (Most Common Mistakes)

1. **Copy-paste patterns** — AI copies from one module but misses module-specific differences
2. **Test/production divergence** — AI fixes one path but forgets the other
3. **Over-abstraction** — AI creates abstractions for one-time use cases
4. **Missing edge cases** — AI focuses on happy path
5. **Silent import changes** — AI re-organizes imports and accidentally changes resolution

---

## 7. DEAD CODE & REFACTORING

### 7.1 Detection Tools

```bash
npx knip                    # Unused files, exports, dependencies
npx depcheck                # Unused npm dependencies
npx ts-prune                # Unused TypeScript exports
```

### 7.2 Safe Removal Workflow

```
1. Run detection tools
2. Categorize: SAFE (unused exports) / CAREFUL (dynamic imports) / RISKY (public API)
3. Start with SAFE items only
4. Remove one category at a time: deps → exports → files → duplicates
5. Run tests after each batch
6. Commit after each batch with descriptive message
```

### 7.3 Simplification Targets

```
□ Deeply nested logic → extract named functions
□ Complex conditionals → early returns
□ Callback chains → async/await
□ Nested ternaries → if/else or switch
□ Long chains → intermediate variables
□ Over-abstracted single-use helpers → inline them
```

**Rules:**
- Never refactor during active feature development
- Never refactor without test coverage
- Clarity over cleverness — always

---

## 8. REVIEW OUTPUT FORMAT

When conducting a code review, use this structure:

```
[SEVERITY] Issue title
File: path/to/file.ts:42
Issue: Description of what's wrong and why it matters
Fix: How to fix it

  // Before (problematic)
  const bad = ...;

  // After (fixed)
  const good = ...;
```

### Summary Format

```
## Review Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0     | ✅     |
| HIGH     | 2     | ⚠️     |
| MEDIUM   | 3     | ℹ️     |
| LOW      | 1     | 📝     |

Verdict: WARNING — 2 HIGH issues should be resolved before merge.
```

---

*Distilled from: ECC code-reviewer (238 lines), typescript-reviewer (113 lines), performance-optimizer (447 lines), refactor-cleaner (86 lines), code-simplifier (48 lines), code-review rules (125 lines), coding-standards skill, plankton-code-quality skill. Cross-referenced with 360Connect Golden Rules #9, #11, #12, #16, #17, #18. Last updated: 2026-04-09.*
