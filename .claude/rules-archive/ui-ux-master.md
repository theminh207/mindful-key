---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.html"
  - "**/*.vue"
  - "**/*.svelte"
---

# 🎨 UI/UX MASTER RULE — The Distilled Standard

> This rule governs ALL frontend/UI work. It is the result of distilling 11+ specialized agents, skills, and rules from the Claude ecosystem into a single authoritative reference.

---

## 1. DESIGN PHILOSOPHY — The Non-Negotiables

### 1.1 The Anti-Template Manifesto
Every interface MUST have a clear **visual point of view**. "Safe average" is worse than a strong, coherent aesthetic with bold choices.

**BANNED Patterns (AI Slop Detection):**
- ❌ Default card grids with uniform spacing and no hierarchy
- ❌ Purple-to-blue gradients as default accent (the #1 AI-generated tell)
- ❌ Stock hero sections: centered headline + gradient blob + generic CTA
- ❌ Glassmorphism cards without structural purpose
- ❌ Rounded corners on everything uniformly
- ❌ Motion that exists only because animation was easy to add
- ❌ Dashboard-by-numbers: sidebar + card grid + charts = zero personality
- ❌ Sans-serif font stack (Inter/Roboto/system) with no intentional pairing
- ❌ Gratuitous scroll-triggered animations on every section

### 1.2 The Design Workflow (4 Steps, Every Time)
Before writing a single line of CSS:

1. **Frame the Interface** — What is this? Who uses it? What should they *feel*? Pick a visual direction.
2. **Build the Visual System** — Define tokens: type scale, color palette, spacing rhythm, motion language.
3. **Compose with Intention** — Asymmetry > symmetry when hierarchy matters. Whitespace is a tool, not waste. Overlap, depth, and layering create interest.
4. **Make Motion Meaningful** — 1 well-directed animation sequence > 20 random hover effects.

### 1.3 Visual Directions (Pick One, Commit)
Choose the direction that serves the product's purpose and audience:

| Direction | When to Use |
|-----------|------------|
| Brutally minimal | Data-heavy tools, developer UX |
| Editorial/magazine | Content platforms, blogs, portfolios |
| Industrial | Enterprise tools, dashboards |
| Luxury/premium | SaaS landing, fintech, lifestyle |
| Playful/friendly | Social apps, education, onboarding |
| Geometric/Swiss | Data visualization, analytics |
| Retro-futurist | Creative tools, gaming |
| Soft/organic | Health, wellness, mindfulness |
| Dark atmospheric | AI products, creative studios |

---

## 2. QUALITY GATE — The 10-Point Audit

Every UI surface MUST score **≥ 4 out of 10** on these dimensions before shipping:

| # | Dimension | What to Check |
|---|-----------|---------------|
| 1 | **Hierarchy** | Clear scale contrast. One thing dominates. Eyes have a path. |
| 2 | **Spacing Rhythm** | Consistent spacing system (4px/8px grid). No "rhythm drift." |
| 3 | **Depth & Layering** | Overlap, shadows, surfaces, or motion create visual depth. |
| 4 | **Typography** | Intentional font pairing. Type scale has character, not just size. |
| 5 | **Color** | Semantic color usage: meaning, not decoration. Palette has harmony. |
| 6 | **Interactive States** | Hover/focus/active feel *designed*, not default browser states. |
| 7 | **Composition** | Grid-breaking editorial/bento layouts where appropriate. |
| 8 | **Texture/Atmosphere** | Grain, gradients, or atmospheric depth — not flat surfaces. |
| 9 | **Motion** | Animations clarify flow and state changes, not just "look cool." |
| 10 | **Data Viz** | Charts/graphs are part of the design system, not library defaults. |

**Scoring:** 0-3 = Reject. 4-6 = Ship with notes. 7-9 = Strong. 10 = Exceptional.

---

## 3. CSS ENGINEERING — The Technical Standards

### 3.1 Design Tokens (Mandatory)
All design values MUST be tokenized. Never hardcode hex/rgb/pixel values inline.

```css
/* REQUIRED: Define tokens in your design system */
:root {
  /* Colors — use oklch() for perceptual uniformity */
  --color-surface: oklch(98% 0 0);
  --color-text: oklch(18% 0 0);
  --color-accent: oklch(68% 0.21 250);

  /* Typography — use clamp() for fluid scaling */
  --text-base: clamp(1rem, 0.92rem + 0.4vw, 1.125rem);
  --text-lg: clamp(1.25rem, 1rem + 0.5vw, 1.5rem);
  --text-hero: clamp(3rem, 1rem + 7vw, 8rem);

  /* Spacing — use clamp() for responsive rhythm */
  --space-section: clamp(4rem, 3rem + 5vw, 10rem);
  --space-card: clamp(1rem, 0.5rem + 1vw, 2rem);

  /* Motion — centralize timing */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-spring: cubic-bezier(0.4, 0, 0.2, 1);
}
```

### 3.2 Typography Rules
- **Max 2 font families** per project (1 display + 1 body, or 1 versatile family)
- **`font-display: swap`** on all custom fonts
- **Preload** the critical weight (usually Regular 400)
- **`clamp()`** for ALL responsive font sizes — NO breakpoint-based jumps
- Font pairing MUST have a clear rationale (contrast of personality, not random)

### 3.3 Animation Performance — Compositor-Only
```
✅ ANIMATE (compositor-friendly, GPU-accelerated):
   transform, opacity, clip-path, filter

❌ NEVER ANIMATE (triggers layout/paint):
   width, height, top, left, right, bottom, margin, padding, border-width, font-size
```

- Use `will-change` sparingly and only on elements that actually animate
- Spring/ease curves > linear transitions (linear feels mechanical)
- Every animation MUST handle `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### 3.4 Color System
- Prefer **`oklch()`** for perceptual uniformity (colors look equally bright/vivid)
- Define semantic roles: `surface`, `text`, `accent`, `success`, `warning`, `danger`
- Dark mode: adjust lightness channel, keep chroma/hue stable
- Contrast ratio: **≥ 4.5:1** for normal text, **≥ 3:1** for large text (WCAG AA)

---

## 4. RESPONSIVE DESIGN — The Protocol

### 4.1 Mobile-First Design (Non-Negotiable)
**Design for the smallest screen first, then progressively enhance.** This is not a suggestion — it is the foundational workflow.

**Why Mobile-First?**
- Forces content priority decisions (what MUST be visible on 320px?)
- Prevents "desktop-then-squeeze" syndrome (cramming desktop layouts into mobile)
- CSS `min-width` media queries (mobile → up) produce cleaner, smaller stylesheets than `max-width` (desktop → down)
- 60%+ of global web traffic is mobile (2025). If it doesn't work on mobile, it doesn't work.

**The Workflow:**
1. **Start at 320px** — design the core experience. Every element earns its place.
2. **Enhance at 768px** — add sidebar, expand grid, show secondary info.
3. **Polish at 1440px** — use extra space intentionally (DO NOT just add padding).

**CSS Pattern:**
```css
/* ✅ CORRECT: Mobile-First (min-width, progressive enhancement) */
.container { padding: 1rem; }              /* Mobile default */
@media (min-width: 768px) { .container { padding: 2rem; } }   /* Tablet+ */
@media (min-width: 1440px) { .container { padding: 3rem; } }  /* Desktop+ */

/* ❌ WRONG: Desktop-First (max-width, degradation) */
.container { padding: 3rem; }
@media (max-width: 768px) { .container { padding: 1rem; } }
```

**Tailwind Convention:**
```
/* Mobile-first: unprefixed = mobile, sm/md/lg = progressively wider */
className="text-sm md:text-base lg:text-lg"     ✅ Mobile-first
className="lg:text-lg md:text-base text-sm"     ❌ Just reordered, same result but harder to read
```

**Common Traps:**
- ❌ Designing a beautiful desktop layout then "making it responsive" → results in cramped, afterthought mobile UX
- ❌ Hiding content on mobile with `hidden md:block` without considering mobile alternatives
- ❌ Using fixed pixel widths (`w-[800px]`) that break on small screens
- ❌ Hover-dependent interactions with no touch/tap alternative

**Mobile-Specific Requirements:**
- Navigation: bottom-anchored or hamburger menu (NO horizontal nav bars that overflow)
- Forms: `inputmode` attribute for correct keyboard (`numeric`, `email`, `tel`)
- Modals: full-screen on mobile (`w-full h-full` or `w-[calc(100%-2rem)]`)
- Scrolling: vertical single-column flow. Horizontal scroll ONLY for carousels/tables with clear affordance

### 4.2 Breakpoint Testing Matrix
All UI MUST be verified at these widths:
```
320px  — Small mobile (iPhone SE)
375px  — Standard mobile (iPhone 14)
768px  — Tablet (iPad)
1024px — Small desktop / landscape tablet
1440px — Standard desktop
1920px — Large desktop
```

### 4.3 Height Breakpoints (Often Forgotten)
For full-viewport layouts, also test:
```
500px  — Landscape phone / small laptop
600px  — Short desktop window
700px  — Standard laptop
```

### 4.4 Viewport Setup
```css
/* Full-viewport layouts */
html, body {
  height: 100vh;        /* Fallback */
  height: 100dvh;       /* Dynamic viewport (mobile address bar) */
  overflow: hidden;     /* If app shell with internal scroll */
}
```

### 4.5 Touch Targets
- Minimum touch target: **44×44px** (WCAG 2.1, Level AAA: 48×48px)
- Interactive elements with real-time actions (calls, video): **≥ 56px**
- Spacing between adjacent touch targets: **≥ 8px**

---

## 5. ACCESSIBILITY — The Minimum Bar

> Accessibility is NOT optional. It is a quality indicator as important as visual design.

### 5.1 ARIA & Semantic HTML
- Use semantic elements first: `<nav>`, `<main>`, `<article>`, `<section>`, `<aside>`, `<header>`, `<footer>`
- One `<h1>` per page. Heading hierarchy must never skip levels.
- Every interactive element MUST be keyboard accessible (`Tab`, `Enter`, `Escape`)
- Images: `alt` text always. Decorative images: `alt=""`
- Form fields: `<label>` bound to input, or `aria-label`
- Dynamic content changes: `aria-live` regions for notifications, chat, loading states

### 5.2 Focus Management
- Visible focus indicators: never `outline: none` without a replacement
- Focus trap in modals: `Tab` cycles within modal, `Escape` closes
- After modal close: return focus to the trigger element
- Skip links for navigation-heavy pages

### 5.3 Color Contrast
- Body text: **≥ 4.5:1** contrast ratio
- Large text (≥ 24px / bold ≥ 18.5px): **≥ 3:1**
- UI components and graphical objects: **≥ 3:1**
- Never rely on color alone for meaning — pair with icons, text, or patterns

### 5.4 Screen Reader Testing
- Test with VoiceOver (macOS/iOS), NVDA (Windows), or TalkBack (Android)
- `aria-hidden="true"` on decorative elements
- Live regions (`aria-live="polite"`) for async content updates

---

## 6. PERFORMANCE — The Targets

### 6.1 Core Web Vitals
| Metric | Target | What It Measures |
|--------|--------|-----------------|
| LCP | < 2.5s | Largest Contentful Paint (main content visible) |
| INP | < 200ms | Interaction to Next Paint (responsiveness) |
| CLS | < 0.1 | Cumulative Layout Shift (visual stability) |
| FCP | < 1.5s | First Contentful Paint (initial render) |
| TBT | < 200ms | Total Blocking Time (main thread) |

### 6.2 Bundle Budget
| Page Type | JS (gzipped) | CSS (gzipped) |
|-----------|-------------|---------------|
| Landing page | < 150kb | < 30kb |
| App page | < 300kb | < 50kb |
| Microsite | < 80kb | < 15kb |

### 6.3 Asset Loading
- **Images**: WebP/AVIF with `<picture>` fallback. `loading="lazy"` below the fold. Explicit `width`/`height` to prevent CLS.
- **Fonts**: `font-display: swap`. Preload critical weight. Self-host for First-Party control when possible.
- **Scripts**: `defer` for non-critical JS. Code-split routes. Tree-shake unused imports.

---

## 7. COMPONENT ARCHITECTURE — The Patterns

### 7.1 Composition Rules
- **Composition over inheritance** — use children/slots, not deep props drilling
- **Single Responsibility** — one component, one visual purpose
- **Size limits**: > 300 lines = WARNING, > 500 lines = MUST split
- 3+ related `useState` → extract to custom hook
- URL as state for shareable/bookmarkable UI states

### 7.2 Interactive States (Every Component)
Every interactive component MUST define:
```
default → hover → focus → active → disabled → loading → error → success
```
- Hover: subtle lift, glow, or color shift (NOT just color change)
- Focus: visible ring/outline that matches design system
- Active: scale-down (0.95-0.98) for tactile feedback
- Disabled: reduced opacity (0.5) with `cursor: not-allowed`
- Loading: skeleton or spinner, NEVER blank

### 7.3 Empty & Error States
- Empty states are DESIGN opportunities, not afterthoughts
- Include: illustration/icon + descriptive text + primary action CTA
- Error states: specific, helpful message + recovery action
- Loading: skeleton screens > spinners for content areas

---

## 8. DARK MODE — The Standard

When dark mode is part of the design:
- Dark mode is a **design decision**, not a CSS filter
- Background: deep, not pure black (#000). Use tinted darks (e.g., `#0f0f23`, `oklch(15% 0.02 260)`)
- Text: not pure white (#fff) for body. Use `rgba(255,255,255,0.87)` or `oklch(95% 0 0)`
- Shadows: use glow effects instead of drop shadows (dark surfaces don't cast shadows)
- Images: consider `brightness(0.9)` or `filter` to reduce glare
- Test contrast ratios specifically for dark mode — they differ from light mode

---

## 9. TESTING PRIORITY

```
1. Visual Regression — Screenshot comparison at key breakpoints (320, 768, 1440)
2. Accessibility    — axe-core automated scan + keyboard navigation manual test
3. Performance      — Lighthouse score ≥ 90 for Performance category
4. Cross-Browser    — Chrome, Firefox, Safari (at minimum)
5. Responsive       — All 6 breakpoints, portrait + landscape on mobile
```

---

## 10. STYLE PRESET REFERENCE

When a project needs aesthetic direction, reference these curated presets:

| Preset | Vibe | Suggested Fonts |
|--------|------|-----------------|
| Bold Signal | Keynote-ready, confident | Archivo Black + Space Grotesk |
| Electric Studio | Agency-polished, sleek | Manrope |
| Creative Voltage | Retro-modern, bold | Syne + Space Mono |
| Dark Botanical | Premium, atmospheric | Cormorant + IBM Plex Sans |
| Notebook Tabs | Editorial, tactile | Bodoni Moda + DM Sans |
| Pastel Geometry | Friendly, modern | Plus Jakarta Sans |
| Split Pastel | Playful, creative | Outfit |
| Vintage Editorial | Magazine-inspired | Fraunces + Work Sans |
| Neon Cyber | Futuristic, techy | Clash Display + Satoshi |
| Terminal Green | Developer-focused | JetBrains Mono |
| Swiss Modern | Minimal, data-forward | Archivo + Nunito |
| Paper & Ink | Literary, story-driven | Cormorant Garamond + Source Serif 4 |

**Mood → Preset Mapping:**
| Target Feeling | Best Presets |
|----------------|-------------|
| Impressed / Confident | Bold Signal, Electric Studio, Dark Botanical |
| Excited / Energized | Creative Voltage, Neon Cyber, Split Pastel |
| Calm / Focused | Notebook Tabs, Paper & Ink, Swiss Modern |
| Inspired / Moved | Dark Botanical, Vintage Editorial, Pastel Geometry |

---

## 11. SELF-CHECK BEFORE SHIPPING

Before marking any UI task complete, verify:

```
□ Does this have a visual point of view? (Not generic template)
□ Typography feels intentional? (Not default browser)
□ Color supports the product, not just decorates?
□ Motion clarifies state changes, not just "looks cool"?
□ Accessibility: keyboard navigable? Focus visible? Contrast OK?
□ Responsive: tested on mobile AND desktop?
□ Performance: no layout-triggering animations?
□ prefers-reduced-motion respected?
□ Empty/error/loading states designed?
□ Does NOT read like AI-generated generic UI?
```

---

*Distilled from: everything-claude-code (11 skills/rules), awesome-claude-code-subagents (3 agents), 360Connect design system (1185 lines of battle-tested patterns). Last updated: 2026-04-09.*
