---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.py"
  - "**/Dockerfile"
  - "**/docker-compose*"
  - "**/.env*"
  - "**/.mcp.json"
  - "**/.claude/**"
  - "**/nginx*"
  - "**/*.yaml"
  - "**/*.yml"
  - "**/*.tf"
---

# 🔒 SECURITY MASTER RULE — The Distilled Standard

> This rule governs ALL security-sensitive code. Distilled from: ECC security-review skill (496 lines), ECC security guide (456 lines), cloud-infrastructure-security (362 lines), security-scan (166 lines), security-bounty-hunter (100 lines), safety-guard (76 lines), and the security-reviewer agent (109 lines).
>
> **NOTE**: This rule SUPPLEMENTS project-specific security constitutions (e.g., `SECURITY_CONSTITUTION.md`). It does NOT replace them. When both exist, the stricter rule wins.

---

## 1. AGENTIC SECURITY — Protecting Against AI-Specific Threats

> This section addresses a threat class that traditional security guidance does not cover: attacks targeting AI agents, their tools, their memory, and their supply chain.

### 1.1 The Threat Model

An agentic system (Claude Code, MCP servers, autonomous loops) sits at the intersection of three dangerous things:
1. **Private data** — workspace files, secrets, credentials, user data
2. **Untrusted content** — repo code, PR bodies, email attachments, MCP tool output, web content
3. **External communication** — shell execution, network calls, API requests

When all three live in the same runtime, **prompt injection becomes data exfiltration**.

### 1.2 MCP Server Security

```
BEFORE connecting ANY MCP server:
□ Is it from a trusted source? (official vendor, audited repo)
□ Does it have a description? (undescribed = suspicious)
□ Does it use `npx -y` auto-install? (supply chain risk — pin versions)
□ Does it need shell access? (shell-running MCP = high risk)
□ What data can it read? (scope down to minimum)
□ What can it write/execute? (restrict to necessary actions)
```

**Red flags in MCP configs:**
- `npx -y some-unknown-package` → supply chain injection
- Shell-running MCP servers without sandboxing
- MCP servers with hardcoded secrets in config
- Servers that request overly broad permissions

### 1.3 Skill & Rule Supply Chain

Per Snyk's ToxicSkills study: **36% of 3,984 public skills contained prompt injection**. Treat skills/rules like npm packages — they ARE your supply chain.

```bash
# Scan skills, hooks, and rules for injection patterns
rg -n 'curl|wget|nc|scp|ssh|enableAllProjectMcpServers|ANTHROPIC_BASE_URL' .claude/
rg -nP '[\x{200B}\x{200C}\x{200D}\x{2060}\x{FEFF}\x{202A}-\x{202E}]' .claude/
rg -n '<!--.*ignore|system prompt|you are now' .claude/
```

### 1.4 Memory Poisoning Prevention

Persistent memory (CLAUDE.md, .claude/ files) is useful — but also a persistence vector:
- Do NOT store secrets in memory files
- Separate project memory from user-global memory
- Reset or rotate memory after untrusted runs (e.g., reviewing unknown repos)
- Disable long-lived memory for high-risk workflows

### 1.5 Sandboxing for Untrusted Work

When reviewing unknown repos, processing foreign attachments, or running untrusted code:

```yaml
# Docker Compose: sandboxed agent workspace
services:
  agent:
    build: .
    user: "1000:1000"
    working_dir: /workspace
    volumes:
      - ./workspace:/workspace:rw
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    networks: [agent-internal]

networks:
  agent-internal:
    internal: true  # No egress — compromised agent cannot phone home
```

For one-off review: `docker run -it --rm -v "$(pwd)":/workspace -w /workspace --network=none node:20 bash`

---

## 2. DESTRUCTIVE OPERATION PREVENTION

### 2.1 Watched Commands (Always Require Explicit Approval)

```
CRITICAL — Block and warn:
- rm -rf (especially /, ~, or project root)
- git push --force / git push -f
- git reset --hard
- git checkout . (discard all changes)
- DROP TABLE / DROP DATABASE / TRUNCATE
- docker system prune
- kubectl delete
- chmod 777
- sudo rm
- npm publish (accidental publishes)
- Any command with --no-verify
- deleteMany() on production database
```

### 2.2 Production Database Protection

```
ABSOLUTE RULES:
- NEVER run deleteMany(), DELETE FROM, TRUNCATE, DROP TABLE on production
- Unit tests: MUST use mocks (e.g., prismaMock). Never connect to any DB.
- Integration tests: ONLY use dedicated test DB. Clone schema + seed fake data.
- NEVER point test suite at dev/production database.
- No destructive data operations without explicit user instruction.
```

### 2.3 File Scope Restriction

When working on a specific feature, ONLY modify files within that feature's scope:
- Read anything, but write only to the task's scope
- If a fix requires changes outside scope → flag it, don't silently modify

---

## 3. OWASP TOP 10 — Complete Checklist

When implementing or reviewing any API endpoint, verify ALL 10:

| # | Category | Key Check |
|---|----------|-----------|
| A01 | **Broken Access Control** | Auth on every route? RBAC enforced server-side? IDOR prevented via token-based user filtering? CORS properly scoped? |
| A02 | **Cryptographic Failures** | Passwords hashed with bcrypt/argon2 (cost ≥ 12)? Data encrypted in transit (TLS) and at rest? No sensitive data in URL params? |
| A03 | **Injection** | All queries parameterized? No string concatenation in SQL? ORM used correctly? No `eval()` with user input? |
| A04 | **Insecure Design** | Rate limiting on auth endpoints? Account lockout after failed attempts? Abuse cases considered in design? |
| A05 | **Security Misconfiguration** | Debug mode off in prod? Default credentials changed? Security headers set? Error messages generic? |
| A06 | **Vulnerable Components** | `npm audit` clean? Dependencies current? Lock files committed? Dependabot/Renovate enabled? |
| A07 | **Auth Failures** | JWT short-lived? Tokens in httpOnly cookies? Session management secure? MFA available for sensitive ops? |
| A08 | **Data Integrity Failures** | CI/CD pipeline uses OIDC (not long-lived tokens)? Signed commits? Dependency integrity verified (SRI)? |
| A09 | **Logging & Monitoring** | Security events logged? Failed auth attempts tracked? Alerts for anomalies? Logs tamper-proof? No secrets in logs? |
| A10 | **SSRF** | User-provided URLs validated against allowlist? Internal network access blocked? Cloud metadata endpoint blocked (169.254.169.254)? |

---

## 4. SECURITY HEADERS — Complete Set

Every production deployment MUST have these headers:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{RANDOM}'; ...
```

**Rules for CSP:**
- NEVER use `unsafe-inline` or `unsafe-eval` for scripts
- Use nonce-based CSP for inline scripts
- Adjust origins per project — do NOT cargo-cult CSP blocks unchanged
- Use `helmet` middleware (Node.js/NestJS) for automatic header management

---

## 5. FILE UPLOAD SECURITY

Every file upload endpoint MUST validate THREE things:

```typescript
function validateUpload(file: File) {
  // 1. SIZE — prevent storage abuse
  const MAX_SIZE = 5 * 1024 * 1024; // 5MB
  if (file.size > MAX_SIZE) throw new Error('File too large');

  // 2. MIME TYPE — prevent type confusion
  const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
  if (!ALLOWED_TYPES.includes(file.type)) throw new Error('Invalid type');

  // 3. EXTENSION — prevent double-extension attacks
  const ALLOWED_EXT = ['.jpg', '.jpeg', '.png', '.webp'];
  const ext = file.name.toLowerCase().match(/\.[^.]+$/)?.[0];
  if (!ext || !ALLOWED_EXT.includes(ext)) throw new Error('Invalid extension');

  // BONUS: Validate file magic bytes for critical uploads
}
```

**Additional rules:**
- Store uploaded files OUTSIDE the web root
- Generate random filenames — never use user-provided filenames
- Scan for malware on server-side if processing user documents/PDFs
- Set Content-Disposition: attachment for downloads

---

## 6. SECURITY TESTING PATTERNS

### 6.1 Automated Security Tests (Include in Test Suite)

```typescript
// Auth boundary tests
test('requires authentication', async () => {
  const res = await fetch('/api/protected');
  expect(res.status).toBe(401);
});

test('requires admin role', async () => {
  const res = await fetch('/api/admin', {
    headers: { Authorization: `Bearer ${regularUserToken}` }
  });
  expect(res.status).toBe(403);
});

// Input validation tests
test('rejects invalid input', async () => {
  const res = await fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify({ email: 'not-an-email' })
  });
  expect(res.status).toBe(400);
});

// IDOR prevention tests
test('user cannot access other user data', async () => {
  const res = await fetch(`/api/users/${otherUserId}`, {
    headers: { Authorization: `Bearer ${userAToken}` }
  });
  expect(res.status).toBe(403);
});

// Rate limiting tests
test('enforces rate limits', async () => {
  const requests = Array(101).fill(null).map(() => fetch('/api/endpoint'));
  const responses = await Promise.all(requests);
  const rateLimited = responses.filter(r => r.status === 429);
  expect(rateLimited.length).toBeGreaterThan(0);
});
```

### 6.2 Pentest Methodology (For Bi-Monthly Audits)

Priority scan order for exploitable (bounty-worthy) issues:

| Priority | Pattern | CWE | Impact |
|----------|---------|-----|--------|
| 1 | SSRF through user-controlled URLs | CWE-918 | Internal network access, cloud metadata theft |
| 2 | Auth bypass in middleware/guards | CWE-287 | Unauthorized access |
| 3 | SQL injection in reachable endpoints | CWE-89 | Data exfiltration |
| 4 | Command injection in request handlers | CWE-78 | Code execution |
| 5 | Path traversal in file-serving paths | CWE-22 | Arbitrary file read/write |
| 6 | Auto-triggered XSS | CWE-79 | Session theft |
| 7 | Insecure deserialization | CWE-502 | Code execution |

**Skip in pentest:**
- Local-only eval/exec in CLI tooling
- Shell=True on fully hardcoded commands
- Missing headers by themselves (no exploit)
- Self-XSS requiring victim to paste code
- Demo/example/test-only code

---

## 7. CI/CD PIPELINE SECURITY

```yaml
# Secure GitHub Actions workflow pattern
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read  # Minimal permissions

    steps:
      - uses: actions/checkout@v4

      # Secret scanning
      - name: Scan for secrets
        uses: trufflesecurity/trufflehog@main

      # Dependency audit
      - name: Audit dependencies
        run: npm audit --audit-level=high

      # Use OIDC, not long-lived tokens
      - name: Configure credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
```

**Pipeline rules:**
- Use OIDC auth (not long-lived credentials)
- Secret scanning in every pipeline run
- Dependency vulnerability scanning before deploy
- Branch protection rules enforced (reviews required)
- `npm ci` (not `npm install`) for reproducible builds
- Container image scanning if using Docker

---

## 8. SECURITY RESPONSE PROTOCOL

When a security issue is discovered:

```
1. STOP — Do not continue development
2. ASSESS — Determine severity (Critical/High/Medium/Low)
3. CONTAIN — Isolate affected systems if production
4. FIX — Patch the vulnerability
5. ROTATE — Change any possibly exposed secrets immediately
6. VERIFY — Confirm the fix works, write regression test
7. REVIEW — Search entire codebase for similar patterns
8. DOCUMENT — Log the incident in LESSONS_LEARNED.md
```

**Severity-based response time:**
| Severity | Response | Fix Deadline |
|----------|----------|-------------|
| CRITICAL | Immediate stop, alert owner | Same day |
| HIGH | Prioritize over current work | 48 hours |
| MEDIUM | Schedule in current sprint | 1 week |
| LOW | Add to backlog | Next sprint |

---

## 9. PRE-DEPLOYMENT SECURITY CHECKLIST (Extended)

Before ANY production deployment, verify ALL items:

```
SECRETS & CREDENTIALS
□ No hardcoded secrets in source code
□ .env in .gitignore, never committed
□ No secrets in git history (trufflehog scan)
□ Production secrets in hosting platform or secrets manager

INPUT & VALIDATION
□ All user inputs validated with schemas (Zod/class-validator)
□ File uploads validated (size + type + extension)
□ No direct user input in SQL queries, commands, or file paths

AUTHENTICATION & AUTHORIZATION
□ Tokens in httpOnly+Secure+SameSite cookies
□ JWT short-lived (access ≤ 60 min)
□ Auth middleware on every protected route
□ RBAC verified server-side (not just frontend)
□ IDOR prevention: filter by userId from token

TRANSPORT & HEADERS
□ HTTPS enforced (redirect HTTP → HTTPS)
□ Security headers set (HSTS, CSP, X-Frame-Options, etc.)
□ CORS properly scoped (not wildcard *)

APPLICATION SECURITY
□ XSS: user content sanitized (DOMPurify)
□ CSRF: protection on state-changing endpoints
□ Rate limiting on auth + expensive endpoints
□ Error messages generic for users, detailed in server logs
□ No console.log with tokens/passwords/secrets

INFRASTRUCTURE
□ Dependencies up to date (npm audit clean)
□ Lock files committed
□ Database not publicly accessible
□ Backups automated with tested recovery
□ Logging enabled for security events

POST-DEPLOY
□ Smoke test critical auth flows
□ Verify security headers in browser DevTools
□ Confirm rate limiting works
```

---

## 10. AI APPLICATION SECURITY — Protecting AI-Powered Features

> Section 1 protects the AI agent (Claude Code). This section protects AI features YOU BUILD — RAG pipelines, chat interfaces, AI-generated content rendering.

### 10.1 Prompt Injection in RAG/Chat

When user input flows into LLM prompts (chat, search, editing), it becomes an injection vector:

```
RULES:
- NEVER concatenate raw user input into system prompts
- Separate user content from instructions with clear delimiters:
    SYSTEM: "You are a helpful assistant. Answer based on CONTEXT below."
    CONTEXT: <retrieved_chunks>
    USER: <user_question>
- Validate user queries BEFORE sending to LLM (length, encoding, patterns)
- Strip control characters and Unicode direction overrides from user input
- Log suspicious patterns: "ignore previous", "system:", "you are now"
```

### 10.2 AI Output Sanitization (CRITICAL for Frontend)

AI-generated content (markdown, HTML) rendered in the browser is an XSS vector — the LLM can be tricked into generating malicious output:

```
RULES:
- NEVER render AI output with dangerouslySetInnerHTML without sanitization
- Use sanitized markdown renderer (react-markdown + rehype-sanitize, NOT raw innerHTML)
- Strip <script>, <iframe>, <object>, <embed>, on* event handlers from AI output
- Validate URLs in AI-generated links (https:// or / only, NO javascript:)
- AI-generated code blocks: render as TEXT, never execute
- If using DOMPurify: configure ALLOWED_TAGS whitelist, don't rely on defaults
```

### 10.3 RAG Data Poisoning

Indexed content (transcripts, documents) can contain injection payloads that activate during retrieval:

```
RULES:
- Sanitize content BEFORE indexing into vector DB (strip control chars, HTML tags)
- Treat retrieved chunks as UNTRUSTED even though they came from "your" database
- Limit chunk size to prevent context window stuffing attacks
- Monitor embedding similarity scores — anomalous scores may indicate adversarial input
```

### 10.4 LLM API Security

```
RULES:
- API keys for DeepSeek/Voyage/OpenAI: ONLY in backend env vars, NEVER in frontend
- Validate LLM API responses before using (malformed JSON, unexpected fields)
- Set timeouts on all LLM calls (prevent hung connections draining resources)
- Rate limit user-facing AI endpoints MORE aggressively (LLM calls are expensive)
- Track token usage per user — alert on anomalous consumption (abuse detection)
- NEVER expose raw LLM errors to frontend (may leak system prompt or API details)
```

---

## 11. SSE & WEBSOCKET SECURITY

### 11.1 SSE Authentication

`EventSource` API does NOT support custom headers — this creates auth bypass risk:

```
APPROACHES (choose one per project, be consistent):
1. Token via query param: /api/stream?token=<jwt>
   - Backend validates token from query param
   - Use short-lived tokens (≤ 5 min) to reduce window of exposure
   - Log token usage, reject reuse after stream closes

2. Cookie-based auth: httpOnly cookie sent automatically
   - Requires SameSite=Lax (not Strict) for SSE to work cross-origin
   - Preferred when cookies are already the auth mechanism

3. fetch-event-source library: supports custom headers
   - Adds ~3KB to bundle, but proper Authorization header support
   - Preferred for new projects using Bearer token auth

NEVER: Allow unauthenticated SSE endpoints that stream user-specific data
```

### 11.2 SSE/WebSocket Abuse Prevention

```
- Rate limit SSE connections per user (max 3-5 concurrent streams)
- Set maximum connection duration (auto-close after 30 min, client reconnects)
- Validate :id params in SSE URLs (user can only stream THEIR resources)
- Send heartbeat pings every 30s — close stale connections
- Do NOT stream sensitive data (tokens, passwords) over SSE
```

---

## 12. SELF-CHECK BEFORE SHIPPING

Every code change touching security-sensitive areas:

```
□ Did I validate ALL inputs from external sources?
□ Did I check authorization, not just authentication?
□ Are secrets in env vars, not in code?
□ Will error messages help attackers? (they shouldn't)
□ Did I use parameterized queries / ORM correctly?
□ Is the file upload properly restricted?
□ Did I write a security test for this change?
□ Would a pentest find this endpoint vulnerable?
□ Does this change expose any new attack surface?
□ Did I follow the principle of least privilege?

AI-SPECIFIC (when building AI features):
□ Is user input separated from system prompt instructions?
□ Is AI-generated output sanitized before rendering in browser?
□ Are LLM API keys backend-only (not in frontend bundle)?
□ Are AI endpoints rate-limited per user?
□ Is indexed content sanitized before embedding?
□ Are SSE/WebSocket endpoints authenticated?
```

---

*Distilled from: ECC Security Guide (456 lines), ECC security-review skill (496 lines), cloud-infrastructure-security (362 lines), security-scan (166 lines), security-bounty-hunter (100 lines), safety-guard (76 lines), security-reviewer agent (109 lines). Cross-referenced with 360Connect SECURITY_CONSTITUTION.md (79 lines) and LESSONS_LEARNED.md (#11 pentest incident). Sections 10-11 added for AI application security and SSE/WebSocket. Last updated: 2026-04-13.*
