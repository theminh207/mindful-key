---
paths:
  - "platforms/apple/**"
  - "**/*.swift"
  - "**/*.xib"
  - "**/*.storyboard"
  - "brand/**"
---

> 🗺️ **mindful-key (native macOS):** UI là AppKit/Objective-C (NSPanel/popup/tray), KHÔNG web (React/CSS). Đọc phần a11y / state / form / responsive dưới như *nguyên tắc*. **NHẬN DIỆN & THẨM MỸ theo HIẾN CHƯƠNG là tối cao** (con sóng `~` trung tính, "mô tả không phán xét") — rule này KHÔNG được ghi đè: không đèn đỏ/xanh, không emoji chấm điểm, không gamification.

# 🎨 UI/UX MASTER RULE — Distilled

> Governs ALL frontend/UI work.
> Full version (design-token code, mobile-first rationale, 12 style-preset + mood-mapping tables): `~/.claude/rules-archive/ui-ux-master.md`. Read it when you need aesthetic direction / a starting preset.

## 1. Design Philosophy — Non-Negotiables

Every interface MUST have a clear **visual point of view**. "Safe average" is worse than a strong coherent aesthetic.

**BANNED (AI-slop tells):**
- ❌ Default card grids, uniform spacing, no hierarchy
- ❌ Purple→blue gradients as default accent (#1 AI tell)
- ❌ Stock hero: centered headline + gradient blob + generic CTA
- ❌ Glassmorphism cards without structural purpose
- ❌ Uniform rounded corners on everything
- ❌ Motion that exists only because it was easy to add
- ❌ Dashboard-by-numbers: sidebar + card grid + charts = zero personality
- ❌ Inter/Roboto/system stack with no intentional pairing
- ❌ Gratuitous scroll-triggered animations on every section

**Workflow (every time, before any CSS):** 1) **Frame** — what is this, who uses it, what should they *feel*? Pick a direction. 2) **Build the system** — tokens: type scale, palette, spacing rhythm, motion language. 3) **Compose with intention** — asymmetry > symmetry for hierarchy; whitespace is a tool; overlap/depth/layering create interest. 4) **Meaningful motion** — 1 well-directed sequence > 20 random hovers.

**Visual directions (pick one, commit):** Brutally-minimal (dev tools) · Editorial (content) · Industrial (enterprise dashboards) · Luxury (SaaS/fintech) · Playful (social/education) · Geometric-Swiss (data viz) · Retro-futurist (creative/gaming) · Soft-organic (health/wellness) · Dark-atmospheric (AI/creative).

## 2. Quality Gate — 10-Point Audit (score ≥ 4/10 to ship)

| # | Dimension | Check |
|---|-----------|-------|
| 1 | Hierarchy | Clear scale contrast, one thing dominates, eyes have a path |
| 2 | Spacing Rhythm | Consistent 4px/8px grid, no drift |
| 3 | Depth & Layering | Overlap/shadow/surface/motion create depth |
| 4 | Typography | Intentional pairing, type scale has character |
| 5 | Color | Semantic (meaning, not decoration), palette harmony |
| 6 | Interactive States | Hover/focus/active feel designed, not default browser |
| 7 | Composition | Grid-breaking editorial/bento where appropriate |
| 8 | Texture/Atmosphere | Grain/gradient/depth, not flat |
| 9 | Motion | Clarifies flow/state, not just "cool" |
| 10 | Data Viz | Part of the design system, not library defaults |

Scoring: 0-3 reject · 4-6 ship-with-notes · 7-9 strong · 10 exceptional.

## 3. CSS Engineering

**Tokens mandatory** — never hardcode hex/rgb/px inline. Use `oklch()` for colors (perceptual uniformity), `clamp()` for ALL fluid type/spacing (no breakpoint jumps), centralized motion timings (`--duration-*`, ease curves).

**Typography:** max 2 font families (1 display + 1 body) · `font-display: swap` · preload critical weight (Regular 400) · `clamp()` for every responsive size · font pairing needs a rationale.

**Animation — compositor-only:** ✅ animate `transform, opacity, clip-path, filter`. ❌ NEVER animate `width, height, top, left, right, bottom, margin, padding, border-width, font-size` (triggers layout/paint). `will-change` sparingly. Spring/ease > linear. Every animation MUST honor `prefers-reduced-motion` (reduce to ~0.01ms).

**Color:** `oklch()` · semantic roles (surface/text/accent/success/warning/danger) · dark mode = adjust lightness, keep chroma/hue · contrast ≥ 4.5:1 normal text, ≥ 3:1 large text (WCAG AA).

## 4. Responsive — Mobile-First (non-negotiable)

Design smallest screen first, then progressively enhance with `min-width` media queries (cleaner/smaller than `max-width` degradation). Start 320px (every element earns its place) → enhance 768px (sidebar, expand grid) → polish 1440px (use space intentionally, not just padding). Tailwind: unprefixed = mobile, `sm/md/lg` = wider.

**Traps:** desktop-then-squeeze · `hidden md:block` with no mobile alternative · fixed px widths (`w-[800px]`) · hover-only interactions with no touch fallback.

**Mobile requirements:** bottom-anchored/hamburger nav (no overflowing horizontal bars) · `inputmode` for correct keyboard · full-screen modals · vertical single-column (horizontal scroll only for carousels/tables with affordance).

**Test widths:** 320 · 375 · 768 · 1024 · 1440 · 1920. **Height** (full-viewport layouts): 500 · 600 · 700. Use `100dvh` (dynamic viewport, mobile address bar).

**Touch targets:** min 44×44px (AAA 48) · real-time actions (calls/video) ≥ 56px · ≥ 8px between adjacent targets.

## 5. Accessibility — Minimum Bar (not optional)

Semantic elements first (`<nav>/<main>/<article>/<section>/<header>/<footer>`). One `<h1>`, never skip heading levels. Every interactive element keyboard-accessible (Tab/Enter/Escape). Images: `alt` always (`alt=""` decorative). Form fields: bound `<label>` or `aria-label`. Dynamic changes: `aria-live` regions.

**Focus:** never `outline: none` without a replacement · focus trap in modals (Tab cycles, Escape closes) · return focus to trigger on close · skip links.

**Contrast:** body ≥ 4.5:1 · large text ≥ 3:1 · UI components ≥ 3:1 · never color alone for meaning (pair with icon/text). Test with VoiceOver/NVDA/TalkBack; `aria-hidden` on decorative.

## 6. Performance Targets

**Core Web Vitals:** LCP < 2.5s · INP < 200ms · CLS < 0.1 · FCP < 1.5s · TBT < 200ms.
**Bundle (gzipped):** landing < 150kb JS / 30kb CSS · app page < 300kb / 50kb · microsite < 80kb / 15kb.
**Assets:** WebP/AVIF with `<picture>` fallback, `loading="lazy"` below fold, explicit `width`/`height` (prevent CLS) · fonts `font-display: swap` + preload + self-host · scripts `defer`, route code-split, tree-shake.

## 7. Component Architecture

Composition over inheritance (children/slots, not deep drilling) · one component one visual purpose · > 300 lines WARN, > 500 MUST split · 3+ related useState → custom hook · URL as state for shareable UI.

**Every interactive component defines:** `default → hover → focus → active → disabled → loading → error → success`. Hover = subtle lift/glow (not just color) · focus = visible ring matching system · active = scale 0.95-0.98 · disabled = opacity 0.5 + `not-allowed` · loading = skeleton/spinner never blank.

**Empty/error states are design opportunities:** illustration/icon + descriptive text + primary CTA. Errors: specific message + recovery action. Skeletons > spinners for content.

## 8. Dark Mode (when in scope)

A design decision, not a CSS filter. Background: tinted dark, not pure `#000` (`#0f0f23`, `oklch(15% 0.02 260)`). Body text: not pure `#fff` (`rgba(255,255,255,0.87)`). Shadows → glow (dark surfaces don't cast shadows). Images: consider `brightness(0.9)`. Test contrast separately for dark mode.

## 9. Testing Priority

1. Visual regression (screenshots at 320/768/1440) · 2. Accessibility (axe-core + keyboard manual) · 3. Performance (Lighthouse ≥ 90) · 4. Cross-browser (Chrome/Firefox/Safari) · 5. Responsive (all 6 widths, portrait + landscape).

## 10. Self-Check Before Shipping

```
□ Has a visual point of view? (not generic template)
□ Typography intentional? (not default browser)
□ Color supports the product, not just decorates?
□ Motion clarifies state, not just "looks cool"?
□ Keyboard navigable? Focus visible? Contrast OK?
□ Tested on mobile AND desktop?
□ No layout-triggering animations? prefers-reduced-motion respected?
□ Empty/error/loading states designed?
□ Does NOT read like AI-generated generic UI?
```
