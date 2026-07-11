# Epics — Mindful Key iOS

> Bản đồ epic (thin index cho **Quick Flow**), không phải context object. Chi tiết từng story
> nằm ở `stories/{epic}.{story}.{slug}.story.md`.
>
> **Track:** Quick Flow · **Nguồn:** `tech-spec.md` (v0.2), `EXPERIENCE.md` (v0.3),
> `analysis/07-functional-requirements/_index.md` (FR-Ax), `decision-log.md`.
> **Phạm vi cố ý:** CHỈ shard **Round 1**. R2/R3 (sóng cảm xúc, chuông, nhật ký) KHÔNG shard —
> chặn ở quyết định nhận diện Q1–Q6 (hiến chương: hỏi chủ dự án), shard bây giờ = xây trên cát.

---

## ✅ Đã xong trước khi shard (context, KHÔNG phải story backlog)
- **Nhịp 0** — rút `EngineKeyMap`/`EngineDefaults`/`BrandPalette` ra `platforms/apple/shared/` — ✅ committed (Mốc A).
- **Mốc A** — target iOS trong `project.yml` + skeleton container app + keyboard extension vẽ QWERTY; `KeyboardBridge_Init()` chứng minh engine sống trong sandbox (chèn ký tự THÔ, chưa qua engine) — ✅ committed.
- **Lưới test engine** — 13 ca Telex + cổng exit-code thật trong `tests/core/test_engine.cpp` — ✅ committed (`de10bfc`).

---

## Epic 1: iOS Round 1 — Walking skeleton (gõ Telex thật + onboarding + test)

**Goal:** Một bàn phím iOS cài được, gõ tiếng Việt Telex ra dấu thật qua `core/engine` trong Notes + Zalo, có onboarding kích hoạt + Full Access minh bạch, và test tự động chứng minh.

**In scope (cited):**
- FR-A01 — Gõ Telex/VNI ra dấu qua engine [Source: analysis/07-functional-requirements/_index.md#FR-A01] [Source: tech-spec.md#FR-002]
- FR-A02 — Điều khiển Shift/Caps/lớp số/xóa/đổi bàn phím [Source: analysis/.../_index.md#FR-A02]
- FR-A03 — Target iOS build được từ project.yml chung [Source: tech-spec.md#FR-001]
- FR-A04/A05 — Onboarding kích hoạt + Full Access minh bạch [Source: tech-spec.md#FR-003] [Source: EXPERIENCE.md#Journey-1]
- FR-A06 — App Group heartbeat detection [Source: tech-spec.md#FR-004]
- FR-A07 — Loại ô mật khẩu + không log nội dung [Source: analysis/.../_index.md#FR-A07]
- FR-A17 — tests/ios test thật [Source: tech-spec.md#FR-005]

**NFR canh (cited):** NFR-01 RAM ~48-60MB · NFR-03 on-device/riêng tư · NFR-07 core đóng băng · NFR-08 không vỡ macOS · NFR-09 WCAG AA · NFR-10 Full Access minh bạch [Source: analysis/07-non-functional/_index.md].

**Kiến trúc touchpoints:** `platforms/apple/ios/KeyboardExtension/` (KeyboardBridge, KeyboardViewController) · `platforms/apple/ios/App/` (container + onboarding) · `platforms/apple/shared/` (AppGroupBridge, EngineKeyMap) · `platforms/apple/project.yml` · `tests/core` + `tests/ios` [Source: tech-spec.md#Architecture-Overview].

**Out of scope:** Con sóng cảm xúc, chuông, nhật ký, gác cổng (R2/R3) · vuốt phím + macro · ký thật/notarize/TestFlight (R4) · iPad/landscape.

**Stories (ordered):**

| ID | Slug | Intent | Status |
|----|------|--------|--------|
| 1.1 | harness-backspace-edge-cases | Mở rộng `test_engine` inject phím ⌫ + ca biên Loại 6 (backspace giữa âm tiết) — lưới test cho Mốc B | ready-for-dev |
| 1.2 | telex-typing-bridge | **Mốc B:** nối `vKeyHandleEvent` → `UITextDocumentProxy`, gõ Telex ra dấu thật (bỏ chèn thô) | **review** (code landed `91a8742`, bridge test PASS; còn verify Notes/Zalo+RAM) |
| 1.3 | keyboard-shift-number-layer | Shift/Caps (một lần + khóa) + lớp số & ký hiệu (123↔ABC) | ready-for-dev |
| 1.4 | secure-field-privacy-guard | Loại ô mật khẩu: không đọc/log, gõ chữ thường bình thường | ready-for-dev |
| 1.5 | xcodegen-build-verification | Chạy `xcodegen generate` + `xcodebuild` iOS simulator sạch; macOS build vẫn xanh | ready-for-dev |
| 1.6 | app-group-heartbeat | Entitlements App Group 2 target + `AppGroupBridge` heartbeat (extension ghi, container đọc) | ready-for-dev |
| 1.7 | onboarding-two-screens | 2 màn onboarding (kích hoạt + Full Access minh bạch, có "Để sau") theo EXPERIENCE v0.3 | ready-for-dev |
| 1.8 | ios-test-harness | build-smoke `xcodebuild` + vá README (bridge test 5 ca ĐÃ có + wired vào `make test-ios`) | ready-for-dev |

**Chuỗi phụ thuộc (tuyến tính — 1 luồng, KHÔNG parallel):**
```
1.1 ──▶ 1.2 ──┬──▶ 1.3
              ├──▶ 1.4
              ├──▶ 1.5 ──▶ 1.6 ──▶ 1.7
              └──▶ 1.8 (cần 1.2 + 1.5)
```
- **File dùng chung phải serialize** (từ `scope-conflict-check`, 11 overlap — ĐÚNG dự kiến vì R1 chạy 1 luồng, KHÔNG song song): `KeyboardViewController.mm` (1.2/1.3/1.4/1.6) · `KeyboardBridge.mm` (1.2/1.4) · `project.yml` (1.5/1.6/1.7) · `tests/ios/bridge_test.mm` (1.2/1.8) · `tests/ios/README.md` (1.5/1.8) · `AppGroupBridge.*` (1.6/1.7). Chạy tuần tự theo chuỗi trên → không xung đột merge.

**Cross-epic dependencies:** Blocked by: none (R1 là epic đầu). Blocks: Epic 2 (R2 sóng/chuông) — cần bàn phím gõ thật + Full Access + App Group trước.

---

## Delivery Tracking (count-based)
- Total stories (Epic 1 / Round 1): **8**
- **done: 7 · review: 1 (1.2)** · ready-for-dev: 0. Toàn bộ CODE Round 1 đã xong + build-verify (2026-07-11).
  Còn lại CHỈ kiểm thủ công trên máy thật (không tự động hóa được): gõ Notes/Zalo, đo RAM, VoiceOver/Reduce-Motion, Settings round-trip.
- (Nhịp 0 + Mốc A + lưới test engine đã xong nhưng KHÔNG tính là story — là context nền.)

### Reconcile 2026-07-11 (sau khi compile 8 story + đối chiếu code thật)
- **1.2 (Mốc B)** đã code thật (commit `91a8742`) — bridge route đủ, `git diff core/` rỗng, bridge test 5 ca PASS → set **review** (chỉ còn verify Notes/Zalo trên máy + đo RAM).
- **1.8** hẹp lại: bridge test 5 ca ĐÃ có + wired vào `make test-ios`; việc còn = thêm build-smoke `xcodebuild -sdk iphonesimulator` + vá `tests/ios/README.md` (đang ghi "no-op" sai).
- **1.5** xác nhận Risk R5 CÒN MỞ: `tests/ios/build.sh` compile bằng `clang++` host, chưa từng chạy `xcodegen generate`/`xcodebuild` simulator thật.
- **1.1** lỗ `test_engine` chưa inject được ⌫ là thật (dù bridge production đã xử `KEY_DELETE`) → vẫn cần để regression-test.
- **1.7** deep-link `App-Prefs` bị Apple từ chối → story chuyển sang `UIApplication.openSettingsURLString` (public API) + 3 bước luôn hiện. Asset nhận diện (glyph/copy) chờ Q10b → placeholder + TODO marker.

## Notes
- **Ranh giới cứng mọi story:** `core/` đóng băng (`git diff core/` rỗng) · CẤM đụng `platforms/apple/macos/*.mm` (việc macOS đang dở) · story chạm `project.yml` chỉ THÊM block iOS, KHÔNG sửa target macOS.
- Story 1.7 có **lỗ asset nhận diện** (glyph con sóng, wordmark, copy cuối — Q10b chưa chốt): dùng placeholder + SF Symbols, đánh dấu chờ chủ dự án, KHÔNG tự chế nhận diện.
- Round 1 xong = "v1.0 skeleton": gõ "việt" trong Notes+Zalo · `make test-core`+`make test-ios` xanh · `xcodebuild` iOS sạch · macOS build xanh · `git diff core/` rỗng.
