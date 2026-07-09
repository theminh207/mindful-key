# 🏗️ ARCHITECTURE & PATTERNS — The Distilled Standard

> This rule governs architectural decisions, design patterns, coding style principles, and planning discipline. Distilled from: ECC hexagonal-architecture skill (277 lines), architecture-decision-records skill (180 lines), backend-patterns skill (599 lines), frontend-patterns skill (643 lines), nestjs-patterns skill (231 lines), coding-standards skill, code-architect agent (72 lines), planner agent (213 lines), common/coding-style (91 lines), common/patterns (32 lines), TypeScript coding-style (200 lines).
>
> **NOTE**: Architecture is a PER-PROJECT decision. This rule provides universal principles. Project-specific architecture goes in `.agent/ARCHITECTURE.md`. CẤM áp kiến trúc project A lên project B.

---

## 1. CORE DESIGN PRINCIPLES

### 1.1 The Trinity

| Principle | Meaning | Violation Signal |
|-----------|---------|-----------------|
| **KISS** | Simplest solution that actually works | Over-engineered abstractions for one use case |
| **DRY** | Extract when repetition is REAL, not speculative | Copy-pasted logic drifting apart in 2+ locations |
| **YAGNI** | Don't build before it's needed | Speculative generality, unused interface methods |

### 1.2 Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```typescript
// BAD: Mutation
function updateUser(user: User, name: string): User {
  user.name = name; // MUTATION!
  return user;
}

// GOOD: Immutable update
function updateUser(user: Readonly<User>, name: string): User {
  return { ...user, name };
}
```

Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

### 1.3 File Organization

```
MANY SMALL FILES > FEW LARGE FILES

Target: 200-400 lines typical, 800 max
Organize: by feature/domain, NOT by type
Cohesion: high cohesion, low coupling
```

---

## 2. HEXAGONAL ARCHITECTURE (Ports & Adapters)

> Use when: long-term maintainability matters, multiple interfaces for same use case, need to swap infrastructure without rewriting business rules.

### 2.1 Core Concepts

```
Domain Model    → Business rules + entities. NO framework imports.
Use Cases       → Orchestrate domain behavior. Input DTO → Output DTO.
Inbound Ports   → What the app CAN do (interfaces)
Outbound Ports  → What the app NEEDS (repositories, gateways)
Adapters        → Infrastructure implementations of ports
Composition Root → Single wiring location (no hidden globals)
```

### 2.2 Dependency Direction

```
Adapters → Application/Domain
Application → Port interfaces (contracts)
Domain → NOTHING external

Dependencies flow INWARD, never outward.
```

### 2.3 Module Layout

```text
src/features/<feature>/
├── domain/           # Pure business rules (no imports from outside)
│   ├── Order.ts
│   └── OrderPolicy.ts
├── application/
│   ├── ports/
│   │   ├── inbound/CreateOrder.ts
│   │   └── outbound/OrderRepositoryPort.ts
│   └── use-cases/CreateOrderUseCase.ts
├── adapters/
│   ├── inbound/http/createOrderRoute.ts
│   └── outbound/postgres/PostgresOrderRepository.ts
└── composition/ordersContainer.ts
```

### 2.4 Anti-Patterns

- Domain entities importing ORM models, web framework types, or SDK clients
- Use cases reading from `req`, `res`, or queue metadata
- Returning database rows directly from use cases
- Adapters calling each other instead of going through ports
- Dependency wiring spread across many files with hidden singletons

### 2.5 Migration Playbook

```
1. Pick ONE vertical slice (single endpoint) with change pain
2. Extract use-case boundary with explicit input/output types
3. Introduce outbound ports around existing infra calls
4. Move orchestration from controllers into use case
5. Add tests around new boundary (unit + adapter integration)
6. Repeat slice-by-slice — NO big-bang rewrites
```

---

## 3. BACKEND PATTERNS

### 3.1 Repository Pattern

```typescript
// Abstract data access behind consistent interface
interface MarketRepository {
  findAll(filters?: MarketFilters): Promise<Market[]>;
  findById(id: string): Promise<Market | null>;
  create(data: CreateMarketDto): Promise<Market>;
  update(id: string, data: UpdateMarketDto): Promise<Market>;
  delete(id: string): Promise<void>;
}
```

### 3.2 Service Layer Pattern

```
Controller → thin, parses HTTP input, calls service, returns response
Service    → business logic, coordinates repositories and external calls
Repository → data access, speaks SQL/ORM, returns domain entities
```

Controllers should NEVER contain business logic directly.

### 3.3 API Response Envelope

Every API response uses a consistent shape:

```typescript
// Success
{ success: true, data: T, pagination?: { total, page, limit } }

// Error
{ success: false, error: string, details?: ValidationError[] }
```

### 3.4 Error Handling Hierarchy

```typescript
// Custom API error for expected errors
class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public isOperational = true
  ) { super(message); }
}

// Centralized error handler
// - ApiError → return status + message
// - ZodError → return 400 + validation details
// - Unknown → log full error, return 500 + generic message
```

### 3.5 Caching Strategy

```
Cache-Aside:
1. Check cache → hit → return cached
2. Cache miss → fetch from DB
3. Store in cache with TTL
4. On write → invalidate cache

Cache key format: "entity:id" (e.g., "market:abc-123")
Default TTL: 5 minutes (300s)
```

### 3.6 Retry with Backoff

```
Attempt 1: immediate
Attempt 2: wait 1s
Attempt 3: wait 2s
Attempt 4: wait 4s
Give up: throw last error
```

### 3.7 NestJS Specifics

```
Module Structure:
- Feature modules own their controllers, services, DTOs
- Cross-cutting concerns in common/ (guards, filters, interceptors, pipes)
- DTOs validate with class-validator (whitelist: true, forbidNonWhitelisted: true)
- Keep controllers THIN — parse input → call service → return response DTO
- Never return ORM entities directly (leak internal fields)
- Validate env at BOOT, not lazily at first request
```

---

## 4. FRONTEND PATTERNS

### 4.1 Component Composition

```
Composition > Inheritance — always
Compound Components for complex UI (Tabs, Dropdowns, Accordions)
Render Props for flexible data loading
Custom Hooks for reusable logic (3+ useState = custom hook)
```

### 4.2 State Management Hierarchy

Choose by complexity (simplest first):

```
useState           → Single component local state
useReducer         → Complex state with many transitions
Context + Reducer  → Shared state within a feature subtree
Zustand/Jotai      → Cross-feature global state
React Query/SWR    → Server state (caching, revalidation, optimistic)
```

### 4.3 Custom Hook Patterns

```typescript
// Naming: always starts with "use"
// Shape: returns [value, actions] or { data, error, loading }
// Rule: 3+ useState in same domain → extract hook

useToggle()           → [boolean, toggle]
useDebounce(value, delay) → debouncedValue
useQuery(key, fetcher)    → { data, error, loading, refetch }
```

### 4.4 Data Fetching

```typescript
// BAD: Sequential when independent
const user = await fetchUser(id);
const posts = await fetchPosts(id);

// GOOD: Parallel
const [user, posts] = await Promise.all([
  fetchUser(id),
  fetchPosts(id),
]);

// ALWAYS: Debounce rapid user-triggered fetches (search, autocomplete)
const debouncedQuery = useDebounce(searchQuery, 300);
```

---

## 5. ARCHITECTURE DECISION RECORDS (ADR)

### 5.1 When to Record

- Choosing between frameworks, libraries, or patterns
- Database schema design decisions
- Authentication/authorization strategy
- Deployment infrastructure choices
- Any decision where someone might ask "why?" in 6 months

### 5.2 ADR Format

```markdown
# ADR-NNNN: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN

## Context
What situation prompted this decision? (2-5 sentences)

## Decision
What are we doing? (1-3 sentences)

## Alternatives Considered
### Alternative 1: [Name]
- Pros / Cons / Why not

## Consequences
### Positive / Negative / Risks
```

### 5.3 Directory Structure

```
docs/adr/
├── README.md           ← Index table
├── 0001-use-nextjs.md
├── 0002-postgres-over-mongo.md
└── template.md
```

### 5.4 ADR Quality Rules

- **DO**: Be specific ("Use Prisma" not "use an ORM"), record the WHY
- **DON'T**: Record trivial decisions, write essays, omit alternatives
- Lifecycle: `proposed → accepted → deprecated | superseded`

---

## 6. PLANNING DISCIPLINE

### 6.1 Phased Implementation

```
Phase 1: Minimum viable — smallest slice with value
Phase 2: Core experience — complete happy path
Phase 3: Edge cases — error handling, polish
Phase 4: Optimization — performance, monitoring

Each phase MUST be mergeable independently.
```

### 6.2 Build Sequence

When designing features, implement in this order:

```
1. Types & interfaces (contracts first)
2. Core logic (domain/business rules)
3. Integration layer (repositories, services)
4. UI components  
5. Tests
6. Documentation
```

### 6.3 Architecture Blueprint Format

```markdown
## Architecture: [Feature Name]

### Design Decisions
- Decision 1: [Rationale]

### Files to Create
| File | Purpose | Priority |

### Files to Modify
| File | Changes | Priority |

### Data Flow
[Description or diagram]

### Build Sequence
1. Step 1 (deps: none)
2. Step 2 (deps: step 1)
```

---

## 7. INPUT VALIDATION AT BOUNDARIES

```
ALWAYS validate at system boundaries:
- All user input before processing (Zod, class-validator)
- All API responses before using (unknown → validate → typed)
- All file content before processing
- All env vars at startup (fail fast if missing)

NEVER trust external data.
```

### Zod Pattern (Frontend/Next.js)

```typescript
const userSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});
type UserInput = z.infer<typeof userSchema>;
const validated = userSchema.parse(input); // throws on invalid
```

### class-validator Pattern (NestJS)

```typescript
class CreateUserDto {
  @IsEmail() email!: string;
  @IsString() @Length(2, 80) name!: string;
  @IsOptional() @IsEnum(UserRole) role?: UserRole;
}
```

---

## 8. SELF-CHECK BEFORE ARCHITECTURAL CHANGES

```
□ Did I read existing code patterns before designing? (Rule #12: ĐỌC TRƯỚC KHI VIẾT)
□ Does my design fit naturally into current architecture?
□ Am I using the simplest approach that works? (KISS)
□ Am I building only what's needed now? (YAGNI)
□ Did I check for existing utilities before creating new ones?
□ Are dependencies flowing INWARD (domain ← application ← adapters)?
□ Is the implementation plan phased and independently mergeable?
□ Did I consider what happens when this fails? (error paths)
□ Would someone understand WHY I chose this in 6 months? (ADR if significant)
□ Does this change stay within scope? (Rule #11: NINJA)
```

---

*Distilled from: ECC hexagonal-architecture (277 lines), ADR (180 lines), backend-patterns (599 lines), frontend-patterns (643 lines), nestjs-patterns (231 lines), coding-standards, code-architect (72 lines), planner (213 lines), common/TS coding-style (291 lines), common/patterns (32 lines). Last updated: 2026-04-09.*
