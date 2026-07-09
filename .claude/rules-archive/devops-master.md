# 🚀 DEVOPS & INFRASTRUCTURE — The Distilled Standard

> This rule governs Docker, CI/CD pipelines, Git workflow, database migrations, deployment strategies, and GitHub operations. Distilled from: ECC docker-patterns skill (365 lines), deployment-patterns skill (428 lines), git-workflow skill (716 lines), database-migrations skill (430 lines), github-ops skill (145 lines), common/git-workflow rule (25 lines).
>
> **NOTE**: Container SECURITY hardening (non-root, secrets, capabilities) is in `security-master.md`. This rule covers build patterns, orchestration, and operational workflows.

---

## 1. DOCKER PATTERNS

### 1.1 Multi-Stage Dockerfile (Node.js Standard)

```dockerfile
# Stage: dependencies
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# Stage: dev (hot reload)
FROM node:22-alpine AS dev
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Stage: build
FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build && npm prune --production

# Stage: production (minimal)
FROM node:22-alpine AS production
WORKDIR /app
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001
USER appuser
COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./
ENV NODE_ENV=production
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

### 1.2 Docker Compose (Local Dev Stack)

```yaml
services:
  app:
    build: { context: ., target: dev }
    ports: ["3000:3000"]
    volumes:
      - .:/app                    # Bind mount → hot reload
      - /app/node_modules         # Anonymous volume → preserve container deps
    depends_on:
      db: { condition: service_healthy }

  db:
    image: postgres:16-alpine
    ports: ["127.0.0.1:5432:5432"]  # Host-only, not network-exposed
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5

volumes:
  pgdata:
```

### 1.3 Docker Best Practices

```
DO:
  ✅ Specific version tags (node:22-alpine, NOT :latest)
  ✅ Multi-stage builds (minimize image size)
  ✅ Run as non-root user
  ✅ Copy dependency files FIRST (layer caching)
  ✅ .dockerignore (exclude node_modules, .git, tests, .env)
  ✅ HEALTHCHECK instruction in production images
  ✅ Resource limits in compose/k8s

DON'T:
  ❌ Use :latest tags
  ❌ Run as root
  ❌ Copy entire repo in one COPY layer
  ❌ Include dev dependencies in production image
  ❌ Store secrets in image layers
  ❌ One giant container with all services
  ❌ Store data in containers without volumes
```

---

## 2. CI/CD PIPELINE

### 2.1 Pipeline Stages

```
PR opened:
  lint → typecheck → unit tests → integration tests → preview deploy

Merged to main:
  lint → typecheck → unit tests → integration tests →
  build image → deploy staging → smoke tests → deploy production
```

### 2.2 GitHub Actions Template

```yaml
name: CI/CD
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test -- --coverage

  build:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    environment: production
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: echo "Platform-specific deploy command"
```

### 2.3 CI Debugging

```bash
# List recent failed runs
gh run list --status failure --limit 10

# View failed run logs
gh run view <run-id> --log-failed

# Re-run only failed jobs
gh run rerun <run-id> --failed
```

**Rule**: Investigate CI failures, don't just re-run. Flaky tests must be flagged.

---

## 3. GIT WORKFLOW

### 3.1 Branching Strategy (Choose One Per Project)

| Strategy | Team Size | Release Cadence | Best For |
|----------|-----------|-----------------|----------|
| **GitHub Flow** | Any | Continuous | SaaS, web apps, startups |
| **Trunk-Based** | 5+ experienced | Multiple/day | High-velocity, feature flags |
| **GitFlow** | 10+ | Scheduled | Enterprise, regulated |

**Default**: GitHub Flow (main always deployable, feature branches → PR → merge).

### 3.2 Commit Messages (Conventional Commits)

```
<type>(<scope>): <subject>

Types: feat, fix, refactor, docs, test, chore, perf, ci, revert
Scope: api, ui, db, auth, etc.
Subject: imperative mood, no period, max 50 chars

# GOOD
feat(auth): add OAuth2 login
fix(api): retry on 503 with exponential backoff

# BAD
"fixed stuff", "updates", "WIP"
```

### 3.3 Branch Naming

```
feature/user-authentication
fix/login-redirect-loop
hotfix/critical-security-patch
release/1.2.0
experiment/new-caching-strategy
```

### 3.4 Merge vs Rebase

```
MERGE: Feature → main (preserves history, use for shared branches)
REBASE: Update local feature branch with latest main (linear history)

NEVER REBASE:
  - Branches pushed to shared repositories
  - Protected branches (main, develop)
  - Branches others have based work on
```

### 3.5 PR Discipline

```markdown
## PR Description Template
- **What**: Brief description
- **Why**: Motivation and context
- **How**: Key implementation details
- **Testing**: What was tested
- **Checklist**: Self-review, tests pass, docs updated
```

**Size**: < 500 lines ideal. Break large PRs into focused pieces.

### 3.6 Release Management (SemVer)

```
MAJOR.MINOR.PATCH
  MAJOR: Breaking changes
  MINOR: New features (backward compatible)
  PATCH: Bug fixes (backward compatible)

# Create release
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
gh release create v1.2.0 --generate-notes
```

---

## 4. DATABASE MIGRATIONS

### 4.1 Core Principles

```
1. Every schema change is a migration — NEVER alter production DB manually
2. Migrations are forward-only in production — rollbacks use NEW forward migrations
3. Schema and data migrations are SEPARATE — never mix DDL and DML
4. Test migrations against production-sized data
5. Migrations are IMMUTABLE once deployed — never edit a deployed migration
```

### 4.2 Safety Checklist

```
□ Migration has both UP and DOWN (or marked irreversible)
□ No full table locks on large tables
□ New columns are nullable OR have defaults
□ Indexes created CONCURRENTLY (for existing tables)
□ Data backfill is a separate migration
□ Tested against production-sized dataset copy
□ Rollback plan documented
```

### 4.3 Zero-Downtime Pattern (Expand-Contract)

```
Phase 1 — EXPAND:
  Add new column (nullable/default)
  Deploy: app writes to BOTH old and new
  Backfill existing data

Phase 2 — MIGRATE:
  Deploy: app reads from NEW, writes to BOTH
  Verify data consistency

Phase 3 — CONTRACT:
  Deploy: app uses NEW only
  Drop old column in separate migration

Timeline example:
  Day 1: Add column → Day 1: Deploy dual-write
  Day 2: Backfill → Day 3: Deploy read-new
  Day 7: Drop old column
```

### 4.4 PostgreSQL Safety Patterns

```sql
-- ✅ SAFE: Nullable column (no lock)
ALTER TABLE users ADD COLUMN avatar_url TEXT;

-- ✅ SAFE: Column with default (Postgres 11+ instant)
ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

-- ❌ UNSAFE: NOT NULL without default (rewrites entire table)
ALTER TABLE users ADD COLUMN role TEXT NOT NULL;

-- ✅ SAFE: Non-blocking index
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);

-- ❌ UNSAFE: Blocking index (locks writes)
CREATE INDEX idx_users_email ON users (email);
```

### 4.5 Large Data Backfill

```sql
-- ❌ BAD: Locks table in single transaction
UPDATE users SET normalized_email = LOWER(email);

-- ✅ GOOD: Batch with progress
DO $$
DECLARE batch_size INT := 10000; rows_updated INT;
BEGIN
  LOOP
    UPDATE users SET normalized_email = LOWER(email)
    WHERE id IN (SELECT id FROM users WHERE normalized_email IS NULL
                 LIMIT batch_size FOR UPDATE SKIP LOCKED);
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    EXIT WHEN rows_updated = 0;
    COMMIT;
  END LOOP;
END $$;
```

---

## 5. DEPLOYMENT STRATEGIES

### 5.1 Strategy Selection

| Strategy | Mechanism | Rollback Speed | Use When |
|----------|-----------|----------------|----------|
| **Rolling** | Replace instances gradually | Medium | Standard deploys, backward-compatible |
| **Blue-Green** | Two environments, switch traffic | Instant | Critical services, zero-tolerance |
| **Canary** | Route % of traffic to new version | Fast | High-traffic, risky changes |

### 5.2 Health Checks

```typescript
// Simple (for load balancers)
app.get("/health", (req, res) => res.json({ status: "ok" }));

// Detailed (for monitoring)
app.get("/health/detailed", async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
  };
  const allHealthy = Object.values(checks).every(c => c.status === "ok");
  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? "ok" : "degraded",
    version: process.env.APP_VERSION,
    uptime: process.uptime(),
    checks,
  });
});
```

### 5.3 Environment Configuration

```
ALL config via environment variables (12-Factor App)
Validate at STARTUP with Zod — fail fast if config is wrong
NEVER hardcode secrets in code or config files
Use .env files locally (gitignored), secrets manager in production
```

### 5.4 Rollback Checklist

```
□ Previous image/artifact is available and tagged
□ Database migrations are backward-compatible
□ Feature flags can disable new features without deploy
□ Monitoring alerts configured for error rate spikes
□ Rollback tested in staging before production release
```

---

## 6. PRODUCTION READINESS CHECKLIST

Before ANY production deployment:

### Application
```
□ All tests pass (unit, integration, E2E)
□ No hardcoded secrets
□ Error handling covers edge cases
□ Structured logging (JSON), no PII
□ Health check endpoint works
```

### Infrastructure
```
□ Docker image builds reproducibly (pinned versions)
□ Env vars documented and validated at startup
□ Resource limits set (CPU, memory)
□ Horizontal scaling configured
□ SSL/TLS on all endpoints
```

### Monitoring
```
□ Application metrics exported (rate, latency, errors)
□ Alerts configured for error rate > threshold
□ Log aggregation set up (structured, searchable)
□ Uptime monitoring on health endpoint
```

### Operations
```
□ Rollback plan documented and tested
□ DB migration tested against production-sized data
□ Runbook for common failure scenarios
□ On-call rotation and escalation defined
```

---

## 7. GITHUB OPERATIONS

### 7.1 Issue Triage

```
Types: bug, feature-request, question, documentation, duplicate, good-first-issue
Priority: critical (breaking/security) > high > medium > low

Workflow:
  1. Read issue + comments
  2. Search duplicates: gh issue list --search "keyword" --state all
  3. Apply labels: gh issue edit <N> --add-label "bug,high-priority"
  4. Respond or ask for reproduction steps
```

### 7.2 PR & Stale Policy

```
PRs > 5 days with no review → flag
Issues > 14 days no activity → add "stale" label
Issues > 30 days stale → auto-close with "closed-stale"
```

### 7.3 Security Monitoring

```bash
gh api repos/{owner}/{repo}/dependabot/alerts   # Check CVEs
gh api repos/{owner}/{repo}/secret-scanning/alerts  # Check leaked secrets
```

**Weekly minimum**: Review Dependabot alerts, flag critical/high immediately.

---

*Distilled from: ECC docker-patterns (365 lines), deployment-patterns (428 lines), git-workflow skill (716 lines) + rule (25 lines), database-migrations (430 lines), github-ops (145 lines). Total: ~2109 lines → 420 lines. Last updated: 2026-04-09.*
