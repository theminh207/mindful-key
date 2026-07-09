---
paths:
  - "**/.github/workflows/**"
  - "**/Makefile"
  - "**/*.sh"
  - "**/*.xcconfig"
  - "platforms/apple/project.yml"
  - "scripts/**"
  - "**/version.env"
---

> 🗺️ **mindful-key (C++/ObjC):** KHÔNG Docker/K8s/migrations. "Deploy" ở đây = **build + ký + notarize app macOS** (`scripts/build-dmg.sh`, `scripts/sign-and-notarize.sh`), sinh Xcode project bằng XcodeGen (`platforms/apple/project.yml`), CI ở `.github/workflows/macos.yml`. Phần Dockerfile/YAML dưới đọc như *nguyên tắc pipeline*, không áp thẳng.

# 🚀 DEVOPS & INFRASTRUCTURE — Distilled

> Governs Docker, CI/CD, Git workflow, DB migrations, deployment, GitHub ops. Container SECURITY hardening (non-root, secrets, caps) → `security-master.md`.
> Full version with complete Dockerfile / compose / GitHub Actions YAML + health-check code: `~/.claude/rules-archive/devops-master.md`.

## 1. Docker Patterns

**Multi-stage build** (deps → dev → build → production). Production stage: minimal base, non-root user, `--chown` on copies, `HEALTHCHECK`, `ENV NODE_ENV=production`.

**Compose (local dev) gotchas:** bind-mount `.:/app` for hot reload + anonymous volume `/app/node_modules` to preserve container deps · DB port host-only `127.0.0.1:5432:5432` (not network-exposed) · `depends_on` with `condition: service_healthy`.

**DO:** pinned version tags (`node:22-alpine`, NOT `:latest`) · multi-stage · non-root · copy dependency files FIRST (layer caching) · `.dockerignore` (node_modules/.git/tests/.env) · `HEALTHCHECK` in prod · resource limits.
**DON'T:** `:latest` · run as root · copy whole repo in one COPY layer · dev deps in prod image · secrets in image layers · one giant all-services container · data in containers without volumes.

## 2. CI/CD Pipeline

**Stages** — PR: `lint → typecheck → unit → integration → preview deploy`. Main: `... → build image → deploy staging → smoke → deploy prod`.
Actions essentials: `actions/setup-node` with `cache: npm` · `npm ci` (not install) · build+push image tagged by `github.sha` with GHA cache · gate `build`/`deploy` on `github.ref == refs/heads/main` · `environment: production`.

**CI debugging:** `gh run list --status failure --limit 10` · `gh run view <id> --log-failed` · `gh run rerun <id> --failed`. **Rule:** investigate failures, don't just re-run. Flaky tests must be flagged.

## 3. Git Workflow

**Branching (pick one/project):** GitHub Flow (default — main always deployable, feature branch → PR → merge) · Trunk-Based (5+ experienced, feature flags) · GitFlow (10+, regulated).

**Conventional commits:** `<type>(<scope>): <subject>` — types `feat|fix|refactor|docs|test|chore|perf|ci|revert`, imperative mood, no period, ≤ 50 chars. Bad: "fixed stuff", "updates", "WIP".

**Branch naming:** `feature/… fix/… hotfix/… release/… experiment/…`.

**Merge vs rebase:** MERGE feature → main (preserves history). REBASE to update local feature with latest main (linear). **NEVER rebase:** branches pushed to shared repos · protected branches · branches others based work on.

**PR discipline:** describe What / Why / How / Testing / Checklist. Size < 500 lines ideal — break up large PRs.

**Release (SemVer):** MAJOR (breaking) . MINOR (features, compat) . PATCH (fixes, compat). `git tag -a v1.2.0` → `gh release create v1.2.0 --generate-notes`.

## 4. Database Migrations

**Core principles:** every schema change is a migration (NEVER alter prod manually) · forward-only in prod (rollback = new forward migration) · schema and data migrations SEPARATE (never mix DDL/DML) · test against production-sized data · IMMUTABLE once deployed (never edit a deployed migration).

**Safety checklist:** UP + DOWN (or marked irreversible) · no full-table locks on large tables · new columns nullable OR defaulted · indexes `CONCURRENTLY` on existing tables · data backfill is a separate migration · rollback plan documented.

**Zero-downtime (expand-contract):** Phase 1 EXPAND — add nullable column, deploy dual-write, backfill. Phase 2 MIGRATE — read NEW/write BOTH, verify consistency. Phase 3 CONTRACT — use NEW only, drop old column in a separate migration.

**PostgreSQL safe vs unsafe:**
```sql
-- ✅ SAFE: nullable column (no lock)
ALTER TABLE users ADD COLUMN avatar_url TEXT;
-- ✅ SAFE: column with default (PG 11+ instant)
ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
-- ❌ UNSAFE: NOT NULL without default (rewrites whole table)
ALTER TABLE users ADD COLUMN role TEXT NOT NULL;
-- ✅ SAFE: CREATE INDEX CONCURRENTLY ...   ❌ UNSAFE: bare CREATE INDEX (locks writes)
```
**Large backfill:** never a single `UPDATE` (locks table). Batch in a `LOOP` with `LIMIT ... FOR UPDATE SKIP LOCKED` + `COMMIT` per batch, exit when `ROW_COUNT = 0`.

## 5. Deployment Strategies

| Strategy | Mechanism | Rollback | Use When |
|----------|-----------|----------|----------|
| Rolling | Replace instances gradually | Medium | Standard, backward-compatible |
| Blue-Green | Two envs, switch traffic | Instant | Critical, zero-tolerance |
| Canary | Route % traffic to new version | Fast | High-traffic, risky changes |

**Health checks:** simple `/health` (200 ok) for load balancers; detailed `/health/detailed` (DB + Redis + version + uptime, returns 503 if any degraded) for monitoring.
**Env config (12-Factor):** ALL config via env vars, validate at STARTUP with Zod (fail fast), never hardcode secrets, `.env` local (gitignored) + secrets manager in prod.
**Rollback checklist:** previous image tagged & available · migrations backward-compatible · feature flags can disable new features without deploy · alerts on error-rate spikes · rollback tested in staging.

## 6. Production Readiness Checklist

```
APP:   tests pass (unit+integration+E2E) · no hardcoded secrets · edge-case error handling · structured JSON logging no PII · health endpoint works
INFRA: reproducible image build (pinned) · env vars documented + startup-validated · resource limits (CPU/mem) · horizontal scaling · SSL/TLS everywhere
MONITOR: metrics exported (rate/latency/errors) · alerts on error-rate threshold · log aggregation searchable · uptime monitor on health endpoint
OPS:   rollback plan documented + tested · migration tested on prod-sized data · runbook for common failures · on-call + escalation defined
```

## 7. GitHub Operations

**Issue triage:** types `bug/feature-request/question/documentation/duplicate/good-first-issue`; priority critical > high > medium > low. Search duplicates (`gh issue list --search "…" --state all`), apply labels (`gh issue edit <N> --add-label …`), ask for repro.
**Stale policy:** PRs > 5 days no review → flag · issues > 14 days → "stale" · > 30 days stale → auto-close.
**Security monitoring (weekly min):** `gh api repos/{owner}/{repo}/dependabot/alerts` + `.../secret-scanning/alerts` — flag critical/high immediately.
