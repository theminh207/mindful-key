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

> **Trạng thái + bằng chứng thi công (nguồn sự thật DUY NHẤT): `sprint-status.yaml` mục
> `stories:`.** Bảng dưới đây KHÔNG còn cột Status (bỏ 2026-07-14) — từng ghi "ready-for-dev"
> cho gần hết Round 1 dù đã code xong từ lâu. Xem đồng thời `docs/TEST_MATRIX.md` để biết mức
> bằng chứng (build-verified hay đã có người xem/gõ thật).

| ID | Slug | Intent |
|----|------|--------|
| 1.1 | harness-backspace-edge-cases | Mở rộng `test_engine` inject phím ⌫ + ca biên Loại 6 (backspace giữa âm tiết) — lưới test cho Mốc B |
| 1.2 | telex-typing-bridge | **Mốc B:** nối `vKeyHandleEvent` → `UITextDocumentProxy`, gõ Telex ra dấu thật (bỏ chèn thô) |
| 1.3 | keyboard-shift-number-layer | Shift/Caps (một lần + khóa) + lớp số & ký hiệu (123↔ABC) |
| 1.4 | secure-field-privacy-guard | Loại ô mật khẩu: không đọc/log, gõ chữ thường bình thường |
| 1.5 | xcodegen-build-verification | Chạy `xcodegen generate` + `xcodebuild` iOS simulator sạch; macOS build vẫn xanh |
| 1.6 | app-group-heartbeat | Entitlements App Group 2 target + `AppGroupBridge` heartbeat (extension ghi, container đọc) |
| 1.7 | onboarding-two-screens | 2 màn onboarding (kích hoạt + Full Access minh bạch, có "Để sau") theo EXPERIENCE v0.3 |
| 1.8 | ios-test-harness | build-smoke `xcodebuild` + vá README (bridge test 5 ca ĐÃ có + wired vào `make test-ios`) |

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

## Delivery Tracking

> **Đã bỏ đếm tay ở đây (2026-07-14)** — từng là nguồn thứ 2 ghi cùng 1 sự thật với
> `sprint-status.yaml` (và ngay cả bảng Status ở Epic 2 phía trên cũng đã lệch, xem note).
> Số liệu done/review/in-progress thật: xem `sprint-status.yaml` mục `sequencing_summary`.
> Còn lại CHỈ kiểm thủ công trên máy thật (không tự động hóa được): gõ Notes/Zalo, đo RAM,
> VoiceOver/Reduce-Motion, Settings round-trip — xem `docs/TEST_MATRIX.md` để biết đúng dòng
> nào còn thiếu bước này.
> (Nhịp 0 + Mốc A + lưới test engine đã xong nhưng KHÔNG tính là story — là context nền.)

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

---

## Epic 2: iOS Round 2 — lõi Laban đầy đủ + lớp cảm xúc (sóng + chuông)

**Goal:** Bàn phím đủ tiện (VNI, macro, cài đặt) + **linh hồn chánh niệm**: con sóng `~` biến hình theo cảm xúc + chuông nhắc nghỉ. Spec: `tech-spec-r2.md`. Quyết định nhận diện Q1/Q2/Q3/Q11 chốt 2026-07-13.

**Stories (ordered — 1 luồng tuần tự, 13 conflict trên `KeyboardViewController.mm`/App, KHÔNG parallel):**

> **Trạng thái + bằng chứng thi công (nguồn sự thật DUY NHẤT): `sprint-status.yaml` mục
> `stories:`.** Bảng dưới đây KHÔNG còn cột Trạng thái (bỏ 2026-07-14) — từng ghi "ready-for-dev"
> cho cả 6 dòng dù cả 6 story đã code xong từ commit `c872c0c` "Round 2 complete".

| ID | Slug | Track | Model |
|----|------|-------|-------|
| 2.1 | full-keyboard-suggestion-bar | A | Sonnet |
| 2.2 | moodbridge-send-risk | A | Sonnet + **Opus review** (riêng tư/async) |
| 2.4 | macro-text-expansion | A | Sonnet |
| 2.3 | keyboard-settings-live-preview | A | Sonnet |
| 2.5 | emotion-wave-ambient | B | Sonnet + **Opus review nhận diện** |
| 2.6 | rest-reminder-bell | B | Sonnet + **Opus review nhận diện** |

**Thứ tự dev:** `2.1 → 2.2 → 2.4 → 2.3 → 2.5 → 2.6` (2.5 blocked-by 2.1+2.2; 2.6 blocked-by 2.2+2.3).

**Phát hiện từ sharding (đã bake vào story, tránh dev vấp):**
- Engine **KHÔNG** có API gợi ý từ/sửa lỗi (chỉ `checkCorrectVowel` nội bộ) → thanh gợi ý 2.1 là hook rỗng, không bịa (2.1).
- send-risk thực tế = **cửa sổ trượt 15 từ mỗi từ**, không "cuối câu"; callback engine chạy đồng bộ trong mạch gõ → serial queue + cache secure-field (2.2, rủi ro cao nhất).
- Extension **không import chéo** `ios/App` → con sóng tự-chứa trong `KeyboardExtension/`, chỉ dùng `shared/BrandPalette.h` (2.5).
- `Macro.cpp` đủ dùng; bug thật = `KeyboardBridge.mm` no-op `vReplaceMaro` (2.4). Container không link engine → macro qua `MacroBridge` NSDictionary.
- Chuỗi App Group literal lặp nhiều lần → **gom hằng số dùng chung** khi dev.

**Đích R2 (SC2):** câu căng → sóng gợn (đường cong Q1); câu thường → mặt hồ phẳng; chuông sau N câu căng liên tiếp, tắt/hoãn được; `git diff core/` rỗng; qua bài kiểm "mô tả không phán xét".

---

## Epic 3: iOS Round 3 — nhật ký + soi lại + theme

> **Thêm 2026-07-14** — Round 3 đã có code thật (commit `34b9026`, `cf1857e`) từ trước, nhưng
> CHƯA từng shard thành epic/story chuẩn ở đây. Spec đầy đủ sống ở `tech-spec-r3.md` (4 story:
> 3.1 kho nhật ký, 3.2 theme, 3.3 màn soi lại, 3.4 thông báo nhắc). **Trạng thái + bằng chứng:
> xem `sprint-status.yaml` mục `stories:` (epic-3)** — 2/4 story (3.1, 3.3) done, 2/4 (3.2, 3.4)
> `in-progress` vì chính commit message thừa nhận chưa đạt định nghĩa hoàn thành SC3 (theme chưa
> áp vào bàn phím thật; chuông chưa có scheduler thật ngân theo lịch).
>
> Chưa có file `.story.md` riêng cho Round 3 — nếu đội muốn mở rộng thêm (vd hoàn tất 3.2/3.4,
> hoặc thêm story mới), nên shard chuẩn theo đúng cách Round 1/2 đã làm thay vì tiếp tục code
> thẳng từ tech-spec.
