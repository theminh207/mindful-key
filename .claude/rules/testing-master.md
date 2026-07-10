---
paths:
  - "tests/**"
  - "**/tests/**"
  - "**/test_*.cpp"
  - "**/*_test.cpp"
  - "**/*.test.*"
  - "**/*.spec.*"
---

> 🗺️ **mindful-key (C++/ObjC):** test thật = `make test-core` → `tests/core/test_engine` (harness tự viết, 5 case Telex→Unicode hard-code trong `main()`, KHÔNG vitest/jest). `tests/macos/` và `tests/ios/` hiện chưa có test tự động (no-op). Ví dụ TS dưới đọc như *nguyên tắc*. Đụng logic bộ não trong `core/` = bắt buộc chạy lại regression.

# 🧪 TESTING MASTER RULE — The Distilled Standard

> This rule governs ALL test code. Distilled from: ECC tdd-workflow skill (464 lines), e2e-testing skill (327 lines), ai-regression-testing skill (386 lines), verification-loop skill (127 lines), common/web/typescript testing rules (133 lines), tdd-guide agent (92 lines), e2e-runner agent (108 lines).
>
> **NOTE**: This rule SUPPLEMENTS project-specific testing constitutions (e.g., `TESTING_CONSTITUTION.md`). It does NOT replace them. When both exist, the stricter rule wins.

---

## 1. AI REGRESSION TESTING — The Blind Spot Problem

> When an AI writes code and reviews its own work, it carries the same assumptions into both steps. Automated tests are the ONLY reliable defense.

### 1.1 The Core Problem

```
AI writes fix → AI reviews fix → AI says "looks correct" → Bug still exists
```

This is not hypothetical — it was observed 4 times in production on the same bug. The AI fixed the production path but forgot the sandbox path, then reviewed its own fix and missed the issue AGAIN.

### 1.2 Common AI Regression Patterns

| Pattern | Frequency | What Happens | Test Strategy |
|---------|-----------|--------------|---------------|
| **Sandbox/Production Mismatch** | Very High | AI fixes one code path, forgets the other | Assert same response shape in sandbox mode |
| **SELECT Clause Omission** | High | New column added to response but not to SELECT query | Assert ALL required fields present in response |
| **Error State Leakage** | Medium | Error state set but old data not cleared | Assert state cleanup on error |
| **Missing Rollback** | Medium | Optimistic update without undo on failure | Assert state restored on API failure |
| **Type Cast Masking Null** | Medium | TypeScript cast hides undefined at runtime | Assert field is not undefined |

### 1.3 The Strategy: Test Where Bugs Were Found

```
Bug found in /api/user/profile     → Write test for profile API
Bug found in /api/user/messages    → Write test for messages API
Bug found in /api/user/favorites   → Write test for favorites API
No bug in /api/user/notifications  → Don't write test (yet)
```

Why this works with AI-assisted development:
1. AI tends to make the **same category of mistake** repeatedly
2. Bugs cluster in complex areas (auth, multi-path logic, state management)
3. Once tested, that exact regression **cannot happen again**
4. Test count grows organically with bug fixes — no wasted effort

### 1.4 Required Fields Contract Test

Every API endpoint that has had a bug MUST have a contract test:

```typescript
const REQUIRED_FIELDS = [
  "id", "email", "full_name", "phone", "role",
  "created_at", "avatar_url",
  "notification_settings",  // ← Added after bug found it missing
];

it("returns all required fields", async () => {
  const res = await GET(createTestRequest("/api/user/profile"));
  const { json } = await parseResponse(res);

  for (const field of REQUIRED_FIELDS) {
    expect(json.data).toHaveProperty(field);
  }
});

// Name regression tests after the bug they prevent
it("notification_settings is not undefined (BUG-R1 regression)", async () => {
  const { json } = await parseResponse(await GET(createTestRequest("/api/user/profile")));
  expect("notification_settings" in json.data).toBe(true);
});
```

### 1.5 Bug-Check Workflow

When reviewing AI-written code, follow this order:

```
1. npm run test          ← Automated tests FIRST (no AI judgment)
2. npm run build / tsc   ← Type check (mechanical, catches cast issues)
3. AI code review        ← LAST (supplement, not substitute)
4. For each fix found    ← Write regression test immediately
```

**NEVER trust AI self-review as a substitute for automated tests.**

---

## 2. TDD GIT CHECKPOINT DISCIPLINE

> The Red-Green-Refactor cycle is not just a methodology — it's a commit discipline.

### 2.1 The Cycle

```
Step 1: Write failing test       → Commit: "test: add reproducer for <feature>"
Step 2: Verify test FAILS (RED)  → Must compile and execute, must fail for the RIGHT reason
Step 3: Write minimal fix        → Code only enough to make the test pass
Step 4: Verify test PASSES (GREEN) → Commit: "fix: <feature>"
Step 5: Refactor                 → Commit: "refactor: clean up <feature>"
Step 6: Verify coverage          → Run coverage report
```

### 2.2 Rules for RED Gate

Before modifying production code, verify a valid RED state:

- **Runtime RED**: Test compiles, executes, and fails
- **Compile-time RED**: New test references missing implementation, compile failure IS the RED signal
- The failure MUST be caused by the intended bug or missing implementation
- The failure MUST NOT be caused by broken test setup, missing deps, or unrelated issues
- **A test that was written but not compiled/executed does NOT count as RED**

### 2.3 Compact Workflow (Preferred)

```
Commit 1: Failing test + RED validated
Commit 2: Minimal fix + GREEN validated
Commit 3: Refactor (optional, only if needed)
```

---

## 3. EDGE CASE TAXONOMY

Every new feature or bug fix MUST consider these edge cases:

```
ALWAYS TEST (non-negotiable):
□ Null / undefined input
□ Empty string / empty array / empty object
□ Invalid types (string where number expected)
□ Boundary values (0, -1, MAX_INT, min/max)
□ Error paths (network failure, DB error, timeout)
□ Authentication boundary (no token, expired token, wrong role)

TEST WHEN RELEVANT:
□ Race conditions (concurrent operations on same resource)
□ Large data (10k+ items, 100MB+ files)
□ Special characters (Unicode, emojis, SQL injection chars: ' " ; --)
□ Time-dependent logic (timezone, DST, leap year)
□ Encode/decode roundtrip (serialize → deserialize → same result)
```

---

## 4. E2E TESTING PATTERNS (Playwright)

### 4.1 Page Object Model (POM)

```typescript
export class ItemsPage {
  readonly page: Page;
  readonly searchInput: Locator;
  readonly itemCards: Locator;

  constructor(page: Page) {
    this.page = page;
    this.searchInput = page.locator('[data-testid="search-input"]');
    this.itemCards = page.locator('[data-testid="item-card"]');
  }

  async goto() {
    await this.page.goto('/items');
    await this.page.waitForLoadState('networkidle');
  }

  async search(query: string) {
    await this.searchInput.fill(query);
    await this.page.waitForResponse(resp => resp.url().includes('/api/search'));
  }
}
```

### 4.2 Locator Priority

```
BEST:    [data-testid="submit-btn"]     ← Stable, semantic
GOOD:    button:has-text("Submit")      ← Resilient to class changes
OK:      [aria-label="Submit form"]     ← Accessibility-based
AVOID:   .css-class-xyz                 ← Breaks on style changes
NEVER:   div > div:nth-child(3) > span  ← Brittle, impossible to maintain
```

### 4.3 Wait Strategy

```typescript
// NEVER: Arbitrary timeout
await page.waitForTimeout(5000);

// ALWAYS: Wait for specific condition
await page.waitForResponse(resp => resp.url().includes('/api/data'));
await page.locator('[data-testid="result"]').waitFor({ state: 'visible' });
await page.waitForLoadState('networkidle');
```

### 4.4 Flaky Test Protocol

1. Identify: `npx playwright test --repeat-each=10`
2. Quarantine: `test.fixme(true, 'Flaky - Issue #123')`
3. Fix within 48 hours — common causes: missing await, shared state, animation timing
4. Never use `.skip()` to permanently hide a flaky test

### 4.5 Playwright Configuration Reference

```typescript
export default defineConfig({
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
  ],
});
```

---

## 5. VISUAL & ACCESSIBILITY TESTING

### 5.1 Visual Regression

Screenshot key breakpoints to catch unintended UI changes:

```
Required breakpoints: 320, 768, 1024, 1440
```

- Test hero sections and meaningful visual states
- If both themes (dark/light) exist, test BOTH
- Visual regression supplements coverage targets — it does NOT replace them
- For highly visual components, screenshot tests often carry more signal than brittle markup assertions

### 5.2 Accessibility Testing

```
Required checks:
□ Automated a11y audit (axe-core) on all pages
□ Keyboard navigation works for all interactive elements
□ Color contrast meets WCAG AA (4.5:1 text, 3:1 large text)
□ prefers-reduced-motion respected — animations disabled
□ All images have alt text, all form inputs have labels
□ Focus indicators visible and meaningful
```

### 5.3 Responsive Testing

```
Required viewport widths: 320, 375, 768, 1024, 1440, 1920

For each breakpoint verify:
□ No horizontal overflow
□ All content readable
□ Touch targets ≥ 44×44px on mobile
□ Navigation accessible
```

---

## 6. VERIFICATION LOOP — Quality Gate Protocol

After completing any feature or significant change, run ALL phases:

```
VERIFICATION REPORT
==================

Phase 1: BUILD      → npm run build          [PASS/FAIL]
Phase 2: TYPES      → npx tsc --noEmit       [PASS/FAIL] (X errors)
Phase 3: LINT       → npm run lint            [PASS/FAIL] (X warnings)
Phase 4: TESTS      → npm test -- --coverage  [PASS/FAIL] (X/Y passed, Z% coverage)
Phase 5: SECURITY   → grep secrets/console.log [PASS/FAIL] (X issues)
Phase 6: DIFF       → git diff --stat        [X files changed]

Overall: [READY / NOT READY] for merge
```

### Rules:
- Phase 1-2 fails → STOP. Fix before continuing.
- Phase 3 fails → Fix lint before running tests.
- Phase 4 coverage below threshold → Write more tests.
- Phase 5 finds secrets/console.log → Remove immediately.
- Run this loop after EVERY significant change, not just before PR.

---

## 7. TEST ANTI-PATTERNS

### 7.1 Testing Implementation vs Behavior

```typescript
// BAD: Testing internal state
expect(component.state.count).toBe(5);

// GOOD: Testing user-visible behavior
expect(screen.getByText('Count: 5')).toBeInTheDocument();
```

### 7.2 Asserting Too Little

```typescript
// BAD: Test passes but verifies nothing meaningful
it('works', async () => {
  const result = await fetchData();
  expect(result).toBeDefined();  // Everything is "defined"
});

// GOOD: Specific, meaningful assertion
it('returns paginated users with correct shape', async () => {
  const result = await fetchData();
  expect(result.data).toHaveLength(10);
  expect(result.data[0]).toHaveProperty('email');
  expect(result.pagination.totalPages).toBeGreaterThan(0);
});
```

### 7.3 Shared State Between Tests

```typescript
// BAD: Tests depend on each other
let createdUserId: string;
test('creates user', () => { createdUserId = '123'; });
test('updates user', () => { updateUser(createdUserId); }); // Fails if run alone

// GOOD: Each test is independent
test('creates user', () => {
  const user = createTestUser();
  expect(user.id).toBeDefined();
});
test('updates user', () => {
  const user = createTestUser();  // Own setup
  const updated = updateUser(user.id, { name: 'New' });
  expect(updated.name).toBe('New');
});
```

---

## 8. CI/CD TEST INTEGRATION

### 8.1 GitHub Actions for Tests

```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage
      - run: npx playwright install --with-deps
      - run: npx playwright test
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-reports
          path: |
            coverage/
            playwright-report/
          retention-days: 30
```

### 8.2 Artifact Management

On failure, E2E tests should produce:
- **Screenshots**: Captured at failure point
- **Videos**: Full test session recording
- **Traces**: Playwright trace for debugging

Configure: `trace: 'on-first-retry'`, `screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`

---

## 9. SELF-CHECK BEFORE MARKING TESTS COMPLETE

```
□ Did I follow the project's testing constitution?
□ Did I read 2-3 existing test files in the same module for patterns?
□ Did I test BOTH happy path AND sad paths?
□ Did I mock ALL external dependencies (DB, API, Redis)?
□ Are my tests independent? (shuffle order → still pass)
□ Did I use the centralized mock setup (not inline mocks)?
□ Are test names descriptive? (should + specific behavior)
□ Did I check coverage report for gaps?
□ Did I write a regression test if I fixed a bug?
□ Would an AI making the same mistake again be caught by my tests?
```

---

*Distilled from: ECC tdd-workflow (464 lines), e2e-testing (327 lines), ai-regression-testing (386 lines), verification-loop (127 lines), common/web/typescript testing rules (133 lines), tdd-guide agent (92 lines), e2e-runner agent (108 lines). Cross-referenced with 360Connect TESTING_CONSTITUTION.md (116 lines) and project testing.md (18 lines). Last updated: 2026-04-09.*
