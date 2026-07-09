---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.h"
  - "**/*.hpp"
  - "**/*.mm"
  - "**/*.m"
  - "core/**"
  - "platforms/**"
---

> 🗺️ **mindful-key (C++/ObjC):** kiến trúc dự án đã chốt = **"1 bộ não + nhiều vỏ"**: `core/` (C++ thuần dùng chung, không đụng API riêng OS) + `platforms/<os>/` (vỏ native). Xem `docs/OPENKEY-MAP.md`, `docs/AGENT-BRIEF.md`. Nguyên tắc "CẤM áp kiến trúc project A lên project B" ở dưới vẫn đúng — kiến trúc dự án này là bất biến, đừng tự đề xuất lại.

# 🏗️ ARCHITECTURE & PATTERNS — Principles Only

> Universal principles. Architecture is a PER-PROJECT decision — project-specific architecture goes in `.agent/ARCHITECTURE.md`. CẤM áp kiến trúc project A lên project B.
> Full version with code examples: `~/.claude/rules-archive/architecture-master.md` — Read it when doing large greenfield design or big refactors.

## 1. Core Principles

| Principle | Meaning | Violation Signal |
|-----------|---------|-----------------|
| **KISS** | Simplest solution that actually works | Over-engineered abstractions for one use case |
| **DRY** | Extract when repetition is REAL, not speculative | Copy-pasted logic drifting apart in 2+ locations |
| **YAGNI** | Don't build before it's needed | Speculative generality, unused interface methods |

**Immutability (CRITICAL):** ALWAYS create new objects (`{ ...user, name }`), NEVER mutate inputs.

**File organization:** many small files > few large files. 200-400 lines typical, 800 max. Organize by feature/domain, NOT by type.

## 2. Layering & Dependency Direction

```
Controller/Adapter → thin: parse input, call service/use-case, return response
Service/Use-case   → business logic; input DTO → output DTO
Repository         → data access only
Domain             → imports NOTHING external (no ORM, no framework, no SDK)
```

Dependencies flow INWARD (adapters → application → domain). Never outward.

Anti-patterns: business logic in controllers; use cases reading `req`/`res`; returning ORM entities/DB rows directly from use cases; hidden singletons instead of a composition root.

## 3. API & Error Conventions

- Consistent response envelope: `{ success: true, data, pagination? }` / `{ success: false, error, details? }`
- Expected errors → `ApiError(statusCode, message)`; ZodError → 400 + details; unknown → log full error, return generic 500.
- Cache-aside with TTL (default 5m), key format `entity:id`, invalidate on write.
- Retry with exponential backoff (1s→2s→4s, max 3) for transient errors only; fail fast on auth/validation errors.

## 4. Frontend State Hierarchy (simplest first)

```
useState → useReducer → Context+Reducer → Zustand/Jotai → React Query/SWR (server state)
```

3+ useState in same domain → extract custom hook. Independent fetches → `Promise.all`. Rapid user-triggered fetches (search) → debounce.

## 5. Input Validation at Boundaries

ALWAYS validate at system boundaries: user input, API responses, file content, env vars (at startup — fail fast). Zod (FE/Next) / class-validator with `whitelist: true` (NestJS). NEVER trust external data.

## 6. ADR — When & Format

Record an ADR when choosing frameworks/libraries/patterns, schema design, auth strategy, infra — anything someone might ask "why?" about in 6 months. Format: `docs/adr/NNNN-title.md` with Context / Decision / Alternatives Considered / Consequences. Status lifecycle: proposed → accepted → deprecated | superseded.

## 7. Planning Discipline

Phased implementation — each phase mergeable independently: MVP → complete happy path → edge cases → optimization. Build sequence: types/contracts → core logic → integration → UI → tests → docs.

## 8. Self-Check Before Architectural Changes

```
□ Did I read existing code patterns before designing? (ĐỌC TRƯỚC KHI VIẾT)
□ Does my design fit naturally into current architecture?
□ Simplest approach that works? (KISS) Only what's needed now? (YAGNI)
□ Did I check for existing utilities before creating new ones?
□ Are dependencies flowing INWARD (domain ← application ← adapters)?
□ Is the plan phased and independently mergeable?
□ Did I consider error paths?
□ Would someone understand WHY in 6 months? (ADR if significant)
□ Does this change stay within scope? (Surgical Changes — CLAUDE.md)
```
