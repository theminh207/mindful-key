# Sharding Context — Mindful Key iOS, Epic 1 (Round 1)

> Ngữ cảnh dùng chung cho các agent `story-author` compile story `1.x`. Đọc file này TRƯỚC,
> rồi đọc nguồn thật để trích dẫn chính xác. **Track: Quick Flow · Sizing: 1 dev-day (~2-8h)/story, không point.**

## Output
- Story files → `bmad-output/ios/stories/1.{story}.{slug}.story.md`
- Template: `bmad-output/ios/` dùng contract của skill (AC/Dev Notes/Testing LOCKED; Dev Agent Record để TRỐNG).
- Trích dẫn dùng nguồn iOS (KHÔNG có prd.md/architecture.md): `[Source: tech-spec.md#...]`,
  `[Source: EXPERIENCE.md#...]`, `[Source: analysis/07-functional-requirements/_index.md#FR-Ax]`,
  `[Source: decision-log.md#2026-07-11]`. Suy luận riêng đánh `[Inference]`.

## Nguồn sự thật (đọc để trích)
- `bmad-output/ios/tech-spec.md` (v0.2) — §Requirements (FR-001..005), §API Design (hợp đồng engine), §Technical Approach, §Testing Strategy, §Key Components.
- `bmad-output/ios/EXPERIENCE.md` (v0.3) — Journey 1/2, screen states Màn 01/02/Home/Bàn phím/Cài đặt.
- `bmad-output/ios/analysis/07-functional-requirements/_index.md` — FR-A01..A17.
- `bmad-output/ios/analysis/07-non-functional/_index.md` — NFR-01..11 (red-line hiến chương).
- `bmad-output/ios/decision-log.md` — Q7/Q8/Q10a (2026-07-11), tech-spec validate v0.2.
- `.claude/skills/mindful-test-design/references/telex-vni-edge-cases.md` — ma trận ca test.
- Code thật: `platforms/apple/ios/KeyboardExtension/{KeyboardBridge,KeyboardViewController}.{h,mm}`,
  `platforms/apple/shared/{EngineKeyMap,EngineDefaults}.h`, `platforms/apple/project.yml`, `tests/core/test_engine.cpp`.

## RÀNG BUỘC CỨNG (ghi vào Dev Notes MỌI story)
- `core/` ĐÓNG BĂNG — `git diff core/` phải rỗng. Chỉ sửa `platforms/apple/ios/**`, `platforms/apple/shared/**`, `tests/**`.
- CẤM đụng `platforms/apple/macos/*.mm` (việc macOS đang dở). Story chạm `project.yml` chỉ THÊM/ sửa block target iOS, KHÔNG đụng target macOS `MindfulKey`.
- Hiến chương: KHÔNG gamification, KHÔNG đèn đỏ/xanh cảm xúc, copy "mô tả không phán xét" (NFR-04/05/06).
- "Verify đừng đoán": kỳ vọng test lấy từ `make test` thật; on-device 100%, không network (NFR-03).

## Hợp đồng engine (từ tech-spec §API Design — dùng cho 1.2/1.3/1.4)
- Init 1 lần: `vKeyInit()` → `vKeyHookState* pData` (đã bọc trong `KeyboardBridge_Init()` qua `dispatch_once`).
- Mỗi phím: `vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, (unsigned short)KEY_x, modifierByte, false)`.
- Đọc ngay: `pData->code` (`vDoNothing`/`vWillProcess`/`vRestore`/`vRestoreAndStartNewSession`/`vReplaceMaro`), `backspaceCount`, `newCharCount`, `charData[]` (xếp NGƯỢC).
- Vỏ diễn giải: `deleteBackward` × `backspaceCount` rồi `insertText` các `charData` (giải mã như `decodeChar` trong `tests/core/test_engine.cpp`). `EngineKeyMap` (shared) tra char→KEY_x.
- Mốc A hiện chèn THÔ `insertText:letter` (`KeyboardViewController.mm:117`) — 1.2 thay bằng đường qua bridge.

## Quyết định đã chốt (KHÔNG hỏi lại)
- Bundle ID `vn.gnh.mindfulkey.ios` / `.keyboard`; App Group `group.vn.gnh.mindfulkey`; sàn iOS 16.0.
- Container app = Objective-C (Mốc A đã scaffold `ios/App/*.m`). Onboarding dựng theo EXPERIENCE (không cần file mockup).

## Learnings nền (carry vào mọi story)
- Engine build cho iOS 0 thay đổi (thực nghiệm compile, Mach-O 198KB) — rủi ro RAM thật ở UIKit view, không phải engine.
- Macro/SmartSwitch giữ RỖNG mặc định (tránh RAM) — không sync macro macOS sang iOS ở R1.
- `core/mood` build vào target cho parity nhưng KHÔNG set `vOnWordCommitted` ở R1 (mood là R2).

---

## Phân công story (compile mỗi story theo block dưới)

### 1.1 — harness-backspace-edge-cases · FR-A17(hỗ trợ FR-A01)
- **Story:** kỹ sư engine cần harness `test_engine` mô phỏng được phím ⌫ để regression-test backspace giữa âm tiết trước khi Mốc B đụng `backspaceCount`.
- **AC seed:** thêm `KEY_DELETE`(hoặc tương đương) vào `typeChar`/KEYMAP để inject xóa lùi; ≥3 ca Loại 6 từ ma trận Telex (gõ `vieetj` rồi ⌫; sửa dấu giữa từ); `make test-core` xanh exit 0; cổng exit-code giữ nguyên.
- **Owned scope:** `tests/core/test_engine.cpp`, `tests/core/build.sh`(nếu cần). **Blocks:** 1.2.
- **Testing:** chạy `make test-core`, đọc output thật rồi khóa kỳ vọng (verify-đừng-đoán).

### 1.2 — telex-typing-bridge (Mốc B) · FR-A01 · [MUST, việc lõi]
- **Story:** người dùng gõ Telex trong host app ra tiếng Việt có dấu qua `core/engine`.
- **AC seed:** `KeyboardViewController` chuyển mỗi phím qua `KeyboardBridge` → `vKeyHandleEvent` → `deleteBackward`×N + `insertText`; "vieetj"→"việt" trong Notes VÀ Zalo; bỏ `insertText:letter` thô; `git diff core/` rỗng.
- **Owned scope:** `platforms/apple/ios/KeyboardExtension/KeyboardBridge.{h,mm}`, `platforms/apple/ios/KeyboardExtension/KeyboardViewController.mm`. **Blocked-by:** 1.1. **Blocks:** 1.3/1.4/1.5/1.8.
- **Testing:** bridge-level dùng case `tests/core`; kiểm thủ công Notes+Zalo trên simulator.

### 1.3 — keyboard-shift-number-layer · FR-A02
- **Story:** người dùng dùng Shift/Caps + lớp số & ký hiệu như bàn phím iOS chuẩn.
- **AC seed:** Shift một lần tự về sau 1 ký tự; double-tap = Caps (có chỉ dấu khóa); `123`↔`ABC` đổi lớp; hit area ≥44pt [Source: EXPERIENCE.md#Bàn-phím states].
- **Owned scope:** `platforms/apple/ios/KeyboardExtension/KeyboardViewController.mm` (serialize sau 1.2). **Blocked-by:** 1.2.

### 1.4 — secure-field-privacy-guard · FR-A07 · NFR-03
- **Story:** ở ô mật khẩu, bàn phím gõ chữ thường bình thường nhưng KHÔNG đọc/log/(R2)hiện sóng.
- **AC seed:** phát hiện secure text field (`textDocumentProxy.keyboardType`/trait); không ghi App Group; không network [Source: EXPERIENCE.md#Edge-Case-secure].
- **Owned scope:** `platforms/apple/ios/KeyboardExtension/KeyboardViewController.mm`, `KeyboardBridge.mm` (serialize). **Blocked-by:** 1.2.

### 1.5 — xcodegen-build-verification · FR-A03
- **Story:** dự án build được cả 2 target iOS + macOS từ `project.yml` chung.
- **AC seed:** `xcodegen generate` sạch, đủ scheme 2 target iOS; `xcodebuild -sdk iphonesimulator` build sạch; `make build` macOS vẫn xanh (không giẫm chân macOS) [Source: tech-spec.md#FR-001].
- **Owned scope:** `platforms/apple/project.yml` (CHỈ block iOS). **Blocked-by:** 1.2. **Blocks:** 1.6/1.8.

### 1.6 — app-group-heartbeat · FR-A06 · [SHOULD]
- **Story:** container biết "bàn phím đã từng chạy" qua App Group.
- **AC seed:** tạo `.entitlements` App Group `group.vn.gnh.mindfulkey` cho CẢ 2 target + `CODE_SIGN_ENTITLEMENTS` trong project.yml; `AppGroupBridge` (extension ghi timestamp/bool, container đọc); ghi rõ giới hạn không phát hiện lúc TẮT [Source: tech-spec.md#FR-004 + #Key-Components-3].
- **Owned scope:** `platforms/apple/ios/App/MindfulKeyiOS.entitlements`, `platforms/apple/ios/KeyboardExtension/KeyboardExtension.entitlements`, `platforms/apple/shared/AppGroupBridge.{h,mm}`, `platforms/apple/project.yml` (serialize sau 1.5). **Blocked-by:** 1.5. **Blocks:** 1.7.

### 1.7 — onboarding-two-screens · FR-A04/A05 · NFR-06/09/10
- **Story:** người dùng mới bật được bàn phím + hiểu Full Access.
- **AC seed:** Màn 01 (kích hoạt, bước đánh số + "Mở Cài đặt" + fallback "Chưa thấy?") + Màn 02 (Full Access minh bạch, cặp biên độ, nút "Để sau"); giọng bình thản khi vướng, không tô đỏ [Source: EXPERIENCE.md#Màn-01 #Màn-02]. **Asset nhận diện (glyph sóng/wordmark/copy cuối) CHƯA chốt (Q10b) → dùng placeholder + SF Symbols, đánh dấu chờ chủ dự án, KHÔNG tự chế nhận diện.**
- **Owned scope:** `platforms/apple/ios/App/**` (AppDelegate, ViewController, VC onboarding mới, Info.plist). **Blocked-by:** 1.6.

### 1.8 — ios-test-harness · FR-A17
- **Story:** `make test-ios` chạy test thật chứng minh bridge + build.
- **AC seed:** test bridge-layer tái dùng bộ case Telex→Unicode của `tests/core/test_engine.cpp` (không bịa case mới) + build-smoke `xcodebuild ... MindfulKeyKeyboard -sdk iphonesimulator`; `make test-ios` hết no-op [Source: tech-spec.md#FR-005 #Testing-Strategy].
- **Owned scope:** `tests/ios/**`, `Makefile`(target `test-ios` đã có). **Blocked-by:** 1.2, 1.5.
