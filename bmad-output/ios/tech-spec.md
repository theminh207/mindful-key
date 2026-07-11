# Technical Specification: mindful-key — iOS Round 1 (Walking Skeleton)

**Date:** 2026-07-11 (validate + reconcile với code thật sau Mốc A; bản gốc 2026-07-10)
**Author:** Đội iOS (agent, vai kỹ sư iOS)
**Version:** 0.2
**Track:** Quick Flow (1-15 stories)
**Status:** validated — qua checklist Quick Flow; mọi quyết định kiến trúc đã chốt, còn lại là code (App Group/entitlements wiring = FR-A06, chặn story #5)

> **Quick Flow track** — tài liệu này thay cho PRD + architecture riêng vì Round 1 là 1
> walking skeleton nhỏ, đã có SPEC + phân tích UX sẵn. Nếu scope phình quá ~15 story, đổi
> sang BMad Method (bmad-prd + bmad-architecture).

> **Ghi chú nguồn:** mọi khẳng định về file/API/dòng số trong tài liệu này đều lấy từ việc
> đọc trực tiếp source thật trong repo (`platforms/apple/project.yml`, `core/engine/`,
> `core/mood/`, `platforms/apple/macos/`) VÀ một thực nghiệm compile thật (xem §Technical
> Approach → "Bằng chứng thực nghiệm"). Chỗ nào là kiến thức nền tảng chung của iOS SDK
> (không lấy từ file cụ thể trong repo — vd cơ chế Full Access, App Group) được đánh dấu
> rõ **[Kiến thức nền tảng iOS]** để phân biệt với phần đã verify trong repo.

---

## Related Documents

- Project context: `bmad-output/project-context.md`
- Decision log (chung): `bmad-output/decision-log.md`
- Decision log (riêng đội iOS): `bmad-output/ios/decision-log.md`
- Kernel: `bmad-output/ios/SPEC.md`
- Phân tích UX gốc: `/Users/now/Projects/mindful-keyboard/docs/MOBILE-UX-ANALYSIS.md`
- Hiến chương: `docs/AGENT-BRIEF.md`

---

## Problem & Solution

### Problem Statement

`core/engine` (bộ não C++ dùng chung — Telex/VNI, gõ tắt, macro) chưa từng chạy trong một
iOS keyboard extension — sandbox riêng, trần RAM ~48-60MB, hệ điều hành kill tiến trình nếu
vượt. Đây là rủi ro kỹ thuật lớn nhất chưa gỡ trước khi đầu tư UI/tính năng cảm xúc cho iOS.

### Proposed Solution

Chứng minh bằng code chạy thật (không chỉ lý thuyết) rằng `core/engine` build được cho iOS
với **0 thay đổi trong `core/`**, bọc nó bằng một lớp cầu nối Objective-C++ mới đặt ở
`platforms/apple/shared/` + `platforms/apple/ios/`, và dựng 1 bàn phím tối thiểu gõ được
Telex có dấu trong 2 app thật (Notes, Zalo).

### Goals

- `core/engine` build sạch trong target iOS mới, `git diff core/` rỗng khi xong.
- Có 1 keyboard extension cài được, gõ Telex ra ký tự tiếng Việt đúng.
- Container app dẫn onboarding kích hoạt bàn phím + xin Full Access minh bạch.

---

## Scope

### In Scope

- Thêm target iOS (container app + keyboard extension) vào `platforms/apple/project.yml` chung.
- Lớp cầu nối core (`.mm` mới) ở `platforms/apple/shared/` + `platforms/apple/ios/`.
- Onboarding 2 màn (kích hoạt bàn phím, xin Full Access) trong container app.
- Nhịp 0: rút phần dùng-chung-được từ `platforms/apple/macos/` sang `platforms/apple/shared/`.
- `tests/ios/`: bộ test tối thiểu chứng minh gõ Telex đúng + build extension sạch.

### Out of Scope

- Sóng `~` nhận diện cảm xúc trên thanh gợi ý (Round 2).
- Gác cổng/nhịp thở trước khi gửi, kể cả bản "chỉ nhắc" (Round 2 — xem Risk R3).
- Nhật ký cảm xúc on-device, portal, thanh toán, kho theme (Round 3+).
- Đăng ký Apple Developer Program thật / ký thật / TestFlight (Round 1 build ad-hoc/simulator, giống cách macOS đang làm — xem `docs/INSTALL.md`).

---

## Requirements

### Functional Requirements

#### FR-001: Target iOS build được từ project.yml chung [MUST]

`platforms/apple/project.yml` có thêm 2 target mới (app container + keyboard extension),
build bằng đúng `make generate` + `xcodebuild` hiện có — không tạo `.xcodeproj` tay, không
project riêng.

**Acceptance Criteria:**
- `xcodegen generate` chạy sạch với project.yml đã sửa, sinh đủ scheme cho cả 2 target mới.
- Target macOS hiện có (`MindfulKey`) không bị ảnh hưởng (build vẫn xanh).

---

#### FR-002: Keyboard extension gõ được Telex có dấu qua core/engine [MUST]

Extension gọi `vKeyHandleEvent()` (core/engine) cho mỗi lần chạm phím trên bàn phím tự vẽ,
và chèn ký tự kết quả vào app đang gõ qua `UITextDocumentProxy`.

**Acceptance Criteria:**
- Gõ chuỗi Telex `"vieetj"` trong Notes → hiển thị `"việt"`.
- Gõ cùng chuỗi trong Zalo (ô chat) → hiển thị đúng y hệt (không lệch giữa 2 app).
- `core/engine/*.{h,cpp}` không có dòng nào bị sửa (`git diff core/` rỗng).

---

#### FR-003: Container app onboarding kích hoạt + Full Access minh bạch [MUST]

App container dẫn người dùng qua 2 màn: (1) hướng dẫn bật bàn phím trong Cài đặt hệ thống,
(2) giải thích rõ vì sao cần "Cho phép truy cập đầy đủ" (Full Access) trước khi người dùng
bật nó lên — không xin quyền mập mờ.

**Acceptance Criteria:**
- Màn 2 nêu rõ lý do cần Full Access (đọc text ô hiện tại để gõ tiếng Việt) — copy cụ thể
  là **open item**, chưa có mockup thật (xem SPEC.md).
- App phát hiện được ít nhất "bàn phím đã từng chạy" (xem FR-004) và đổi trạng thái hiển thị.

---

#### FR-004: Container phát hiện "bàn phím đã kích hoạt" qua App Group heartbeat [SHOULD]

**[Kiến thức nền tảng iOS]** Apple không có API public đáng tin cậy để 1 app tự hỏi "bàn
phím của tôi đã được bật trong Settings chưa" — đây là giới hạn nền tảng thật, không phải
thiếu sót của repo. Giải pháp thực dụng: extension ghi timestamp vào `NSUserDefaults` dùng
chung qua App Group mỗi khi nó chạy; container đọc lại timestamp đó khi vào foreground.

**Acceptance Criteria:**
- Lần đầu cài, chưa gõ gì → container hiển thị hướng dẫn kích hoạt (giống fallback "Không
  kích hoạt được?" của Laban Key, đã phân tích ở `MOBILE-UX-ANALYSIS.md` §1).
- Sau khi gõ 1 lần trong Notes → mở lại container → trạng thái đổi thành "đã kích hoạt".
- Biết rõ giới hạn: không phát hiện được lúc người dùng TẮT lại bàn phím (không có signal
  ngược) — ghi rõ đây là hạn chế chấp nhận được ở Round 1, không phải bug.

---

#### FR-005: `tests/ios` chứng minh Success bằng test tối thiểu [MUST]

Xem §Testing Strategy — 2 test tự động + 1 hạng mục kiểm thủ công.

**Acceptance Criteria:**
- `make test-ios` chạy được test bridge-layer, không còn no-op như hiện tại.
- Test dùng lại nguyên bộ case Telex→Unicode của `tests/core/test_engine.cpp` (không bịa case mới).

---

### Non-Functional Requirements

#### Performance

**[Mục 3 — trần RAM ~48-60MB]** Bằng chứng thực nghiệm: build `core/engine` (5 file .cpp)
cho `arm64-apple-ios16.0-simulator` (`clang++ -target arm64-apple-ios16.0-simulator -Os`)
ra binary Mach-O **198KB** (`__TEXT` 112KB + `__DATA` 16KB). Kết luận: **code của engine
không phải rủi ro RAM chính** — 198KB là muối bỏ biển so với trần 48-60MB.

Rủi ro RAM thật nằm ở runtime, không phải ở kích thước binary:
- **UIKit overhead của chính keyboard extension** (view hierarchy bàn phím tự vẽ) — chiếm
  phần lớn ngân sách RAM trên thực tế, ngoài tầm kiểm soát của `core/engine`.
- **Macro/SmartSwitchKey data nạp từ App Group `NSUserDefaults`** — `OpenKeyManager`/
  `OpenKey.mm` gọi `initMacroMap()`/`initSmartSwitchKey()` với byte buffer từ
  `NSUserDefaults`; nếu người dùng có macro list lớn (macOS không giới hạn), extension iOS
  nạp nguyên xi có thể tốn RAM không cần thiết. **Round 1: giữ danh sách macro/smart-switch
  RỖNG mặc định** (lười-nạp) — không đồng bộ dữ liệu macro thật của macOS sang iOS ở round
  này, tránh rủi ro RAM chưa đo được.
- **`core/mood`** (`MoodBuffer`, `BreathingPause`) — build vào target theo yêu cầu FR-001
  (parity cấu trúc) nhưng **không gọi `vOnWordCommitted`** — đúng theo thực nghiệm mục 10
  (function pointer không set thì không tốn gì thêm lúc runtime ngoài vài trăm byte code).

#### Security

Không sửa `core/`. On-device 100%, không gọi mạng ở Round 1 — dữ liệu duy nhất rời khỏi
tiến trình extension là qua App Group `NSUserDefaults` (heartbeat timestamp + trạng thái
Full Access), cả 2 đều là dữ liệu vận hành, không phải nội dung gõ.

#### Accessibility / Compliance

Full Access là quyền iOS bắt buộc phải xin minh bạch (Apple Review Guidelines 2.5.1 yêu cầu
giải thích rõ mục đích) — khớp tinh thần hiến chương "không xin quyền mập mờ" vốn đã áp dụng
cho Accessibility/Input Monitoring bên macOS (`MJAccessibilityUtils.m`).

#### Other

Không áp dụng thang màu/emoji nhận diện ở Round 1 (Non-Goal) — chỉ cần `BrandColors` cho
onboarding trung tính (teal/charcoal), không có sóng `~`/biên độ nào cần vẽ.

---

## Technical Approach

### Technology Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Engine | C++14 (`core/engine`, `core/mood`) | Dùng nguyên, không sửa — verify bằng thực nghiệm bên dưới |
| Cầu nối | Objective-C++ (`.mm`) mới ở `shared/` + `ios/` | Cùng pattern `OpenKey.mm` bên macOS, khác phần gửi ký tự |
| Container app | UIKit + **Objective-C** (đã chốt) | Mốc A đã scaffold `ios/App/main.m`+`AppDelegate.m`+`ViewController.m` bằng Obj-C — khớp bridge `.mm` của extension, không trộn Swift ở Round 1 |
| Keyboard extension | UIKit, `UIInputViewController` | Bàn phím tự vẽ, `UITextDocumentProxy` để chèn/xoá ký tự |
| Build | XcodeGen (`platforms/apple/project.yml`) | Thêm target, không tạo project riêng |
| Chia sẻ dữ liệu | App Group `NSUserDefaults` | Heartbeat "extension đã chạy" + trạng thái Full Access |

### Bằng chứng thực nghiệm (đã chạy, không phải suy diễn)

```
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
clang++ -target arm64-apple-ios16.0-simulator -isysroot "$SDK" -std=c++14 -Os \
  -I core/engine <probe>.cpp \
  core/engine/Engine.cpp core/engine/Vietnamese.cpp core/engine/Macro.cpp \
  core/engine/SmartSwitchKey.cpp core/engine/ConvertTool.cpp \
  -o probe_ios
# EXIT 0 — Mach-O 64-bit executable arm64, 198312 bytes (TEXT 114688 + DATA 16384)
```

`<probe>.cpp` chỉ định nghĩa lại đúng 20 biến `extern int` mà `core/engine/Engine.h` khai
báo (copy y hệt default của `platforms/apple/macos/AppDelegate.m` dòng 32-62) rồi gọi
`vKeyInit()`. Không sửa 1 dòng nào trong `core/engine/`. `DataType.h` dòng 83-89 rẽ nhánh
`#ifdef LINUX ... #elif _WIN32 ... #else platforms/mac.h` — iOS không định nghĩa `LINUX`
hay `_WIN32` nên rơi đúng nhánh `#else`, và `platforms/mac.h` hoá ra chỉ là bảng
`#define KEY_A 0`/`KEY_W 13`/... (số nguyên thuần) — không có API AppKit nào trong đó dù
tên file gây hiểu lầm là "mac". **Kết luận: `core/` sẵn sàng cho iOS, 0 thay đổi.**

### Architecture Overview

```
Custom keyboard UI (chạm phím "w")
    → shared/EngineKeyMap  (bảng char → KEY_x, rút từ OpenKey.mm keyStringToKeyCodeMap)
    → ios/KeyboardBridge.mm
        - định nghĩa 20 extern config (mặc định Telex, giống AppDelegate.m)
        - gọi vKeyInit() 1 lần lúc extension khởi động → giữ con trỏ pData
        - mỗi lần chạm phím: vKeyHandleEvent(Keyboard, KeyDown, KEY_x, shiftFlag, false)
        - đọc pData->code / backspaceCount / charData[]
    → UITextDocumentProxy (deleteBackward × backspaceCount, insertText: cho charData[])
```

So với macOS (`OpenKey.mm`): **nửa đầu (nhận diện phím → gọi vKeyHandleEvent) dùng chung
được pattern**; **nửa sau (gửi ký tự) viết lại hoàn toàn** vì macOS dùng
`CGEventCreateKeyboardEvent` + `CGEventTapPostEvent` (Carbon/CGEventTap toàn hệ thống) —
API này không tồn tại trong app extension sandbox.

### Key Components

#### 1. XcodeGen targets (`platforms/apple/project.yml`) — trả lời mục 1

**Cập nhật 2026-07-11 (đối chiếu code thật sau Mốc A):** 2 target iOS **đã có thật** trong
`project.yml`. Bản YAML minh hoạ cũ ở đây bị lệch với code thật ở 2 điểm — đã sửa lại cho khớp:

- **Container KHÔNG ôm `core/engine`/`core/mood`.** Thực tế `MindfulKeyiOS` chỉ có `sources:
  ios/App` + `shared` (loại trừ `*.md`). Container Round 1 chỉ làm UI onboarding + đọc App
  Group, không gọi engine trực tiếp — CHỈ keyboard extension mới biên dịch engine. (Bản YAML
  cũ liệt kê engine dưới container là sai; đã đối chiếu `project.yml` dòng `MindfulKeyiOS`.)
- **Chưa có entitlements / App Group nào được wire.** `project.yml` hiện KHÔNG có
  `CODE_SIGN_ENTITLEMENTS` cho 2 target iOS, và không có chuỗi `group.` ở đâu cả. Round 1 build
  ad-hoc cho Simulator (`CODE_SIGNING_ALLOWED: NO`) nên chưa bắt buộc, nhưng **FR-004 (heartbeat
  container↔extension) BỊ CHẶN tới khi App Group được tạo** — xem Quyết định mở dưới đây.

Bản đối chiếu đúng với `project.yml` thật (rút gọn phần khớp macOS):

```yaml
  MindfulKeyiOS:              # container app
    type: application
    platform: iOS
    sources:
      - path: ios/App
      - path: shared          # excludes: ["*.md"]
    dependencies:
      - target: MindfulKeyKeyboard   # embed extension
    # PRODUCT_BUNDLE_IDENTIFIER: vn.gnh.mindfulkey.ios  (đề xuất — xem Quyết định mở)
    # IPHONEOS_DEPLOYMENT_TARGET: "16.0"; ký ad-hoc Simulator; CHƯA có CODE_SIGN_ENTITLEMENTS

  MindfulKeyKeyboard:         # keyboard extension — target DUY NHẤT biên dịch engine
    type: app-extension
    platform: iOS
    sources:
      - path: ../../core/engine
      - path: ../../core/mood
      - path: ios/KeyboardExtension
      - path: shared          # excludes: ["*.md"]
    # HEADER_SEARCH_PATHS: core/engine + core/mood + shared; CHƯA có CODE_SIGN_ENTITLEMENTS
```

> ✅ **Tên đã CHỐT — ⏳ wiring chưa làm (App Group + Bundle ID).**
> Chủ dự án đã chốt (decision-log iOS, 2026-07-11 — Q7): app `vn.gnh.mindfulkey.ios`, extension
> `vn.gnh.mindfulkey.ios.keyboard`, App Group `group.vn.gnh.mindfulkey`. Vậy phần *quyết định*
> đã xong — Bundle ID đã có trong `project.yml`. Việc CÒN LẠI thuần là *code cấu hình* (FR-A06):
> tạo 2 file `.entitlements` khai báo cùng App Group + thêm `CODE_SIGN_ENTITLEMENTS` cho cả 2
> target. Lưu ý kỹ thuật khi wiring: hai target BẮT BUỘC khai báo y hệt cùng chuỗi App Group —
> sai một ký tự là `NSUserDefaults(suiteName:)` trả `nil` âm thầm (heartbeat chết lặng, không
> crash). **Chặn story #5** (container heartbeat), KHÔNG chặn story #1–#4 (gõ Telex không cần
> App Group).

#### 2. Cầu nối core (`shared/` + `ios/`) — trả lời mục 2

| File | Vị trí | Vai trò | Mới hay tái dùng |
|---|---|---|---|
| `EngineKeyMap.h/.mm` | `platforms/apple/shared/` | Bảng char → `KEY_x`, rút từ `OpenKey.mm` dòng 29-43 (`keyStringToKeyCodeMap`) | **Rút ra nguyên xi** — thuần `NSDictionary`/Foundation, không đụng AppKit |
| `EngineDefaults.h` | `platforms/apple/shared/` | Định nghĩa mặc định 20 biến `extern int` của `Engine.h`, rút từ `AppDelegate.m` dòng 32-62 | **Rút ra thành hằng số dùng chung** — macOS đọc để giữ đồng bộ, iOS gọi lúc init |
| `KeyboardBridge.h/.mm` | `platforms/apple/ios/KeyboardExtension/` | Định nghĩa thật 20 biến (dùng default từ `EngineDefaults.h`), gọi `vKeyInit()`/`vKeyHandleEvent()`, đọc `pData`, gọi `UITextDocumentProxy` | **Viết MỚI hoàn toàn** — không có file macOS nào tương đương (phần gửi ký tự của `OpenKey.mm` là CGEventTap, không tái dùng được) |
| `BrandColors+UIKit.h/.m` | `platforms/apple/shared/` hoặc `ios/App/` | Bọc UIColor quanh cùng hex value đang có trong `BrandColors.h` (macOS) | **Giá trị hex rút ra shared/, wrapper UIColor viết mới** — `NSColor`/`UIColor` không dùng chung API được |

#### 3. Container ↔ extension detection — trả lời mục 4

Xem FR-004. Thiết kế: `shared/AppGroupBridge.h/.mm` chứa 2 hàm nhỏ dùng App Group
`NSUserDefaults`:
- `KeyboardBridge_ReportHeartbeat()` — gọi từ extension mỗi lần `viewDidLoad`/gõ phím.
- `ContainerApp_ReadKeyboardStatus()` — gọi từ container lúc `applicationDidBecomeActive`,
  trả về "chưa từng chạy" / "đã chạy, chưa Full Access" / "đã chạy, có Full Access" (đọc
  thêm cờ `self.hasFullAccess` mà extension tự ghi vào cùng App Group, vì `hasFullAccess`
  chỉ đọc được TỪ BÊN TRONG extension).

### Data Model

Không có DB/persistent store thật ở Round 1 (nhật ký cảm xúc là Non-Goal). Duy nhất:
App Group `NSUserDefaults` với 2 key — `lastExtensionHeartbeatAt` (timestamp) và
`lastKnownHasFullAccess` (bool) — cả 2 do extension ghi, container chỉ đọc.

### API Design

Hợp đồng thật của `core/engine` (không đổi, chỉ tiêu thụ):

- **Init 1 lần:** `vKeyInit()` → trả `void*` cast sang `vKeyHookState*`, giữ làm `pData`.
- **Mỗi lần chạm phím:** `vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, (unsigned short)KEY_x, modifierByte, false)`.
- **Đọc kết quả ngay sau đó** qua `pData`: `code` (`vDoNothing`/`vWillProcess`/`vRestore`/
  `vRestoreAndStartNewSession`/`vReplaceMaro`), `backspaceCount`, `newCharCount`,
  `charData[MAX_BUFF]`.
- **Trước khi gọi bất kỳ hàm nào ở trên:** phải định nghĩa (không chỉ khai báo) đủ 20 biến
  `extern int` liệt kê ở `EngineDefaults.h` (mục 2) — thiếu 1 biến là lỗi link, đã xác nhận
  bằng thực nghiệm (probe đầu tiên thiếu định nghĩa → linker báo đủ tên).

### Error Handling Strategy

- `vKeyInit()`/`vKeyHandleEvent()` không throw (C API kiểu C++ cũ, không exception) — bridge
  layer không cần try/catch, chỉ cần đảm bảo `pData` khác `NULL` trước khi đọc (phòng hờ, dù
  thực nghiệm cho thấy nó luôn trả về con trỏ hợp lệ).
- Nếu App Group entitlement thiếu (lỗi cấu hình) → `NSUserDefaults(suiteName:)` trả `nil`,
  container phải fallback về màn hướng dẫn kích hoạt thủ công thay vì crash.
- Nếu Full Access chưa bật → bàn phím vẫn gõ được ký tự thường (không cần Full Access để
  chèn/xoá qua `UITextDocumentProxy`), nhưng không đọc được text-trước-con-trỏ — Round 1
  không cần đọc ngữ cảnh nên không bị chặn bởi thiếu Full Access; Full Access chỉ cần cho
  Round 2 (đọc câu để tính sóng cảm xúc). Ghi rõ trong onboarding để không xin quyền thừa.

---

## Story List

| # | Epic | Story Title | Notes |
|---|------|-------------|-------|
| 1 | iOS Round 1 | Nhịp 0 — rút `EngineKeyMap`, `EngineDefaults`, hex màu ra `shared/` | Làm TRƯỚC mọi story khác |
| 2 | iOS Round 1 | Thêm target iOS + keyboard extension vào `project.yml`, verify `xcodegen generate` | Phụ thuộc #1 |
| 3 | iOS Round 1 | `KeyboardBridge.mm` — gọi `vKeyInit`/`vKeyHandleEvent`, chèn ký tự qua `UITextDocumentProxy` | Phụ thuộc #2 |
| 4 | iOS Round 1 | Bàn phím tự vẽ tối thiểu (QWERTY + phím Telex cần) gọi `EngineKeyMap` | Phụ thuộc #1, có thể song song #3 |
| 5 | iOS Round 1 | Container app: 2 màn onboarding + `AppGroupBridge` heartbeat | Phụ thuộc #2 |
| 6 | iOS Round 1 | `tests/ios`: unit test bridge layer + build-smoke test | Phụ thuộc #3 |

**Total stories:** 6 (Quick Flow ceiling: 15)

> Đây chỉ là outline 1 dòng/story theo yêu cầu template Quick Flow — KHÔNG phải story file
> đầy đủ. Theo chỉ đạo của chủ dự án, KHÔNG chạy `bmad-epics-and-stories`/`bmad-parallel-plan`
> ở bước này; outline này chỉ để dev cầm làm trực tiếp cho Round 1 (1 luồng, không sharding).

---

## Testing Strategy

### Unit Testing Focus — trả lời mục 6 (1/3)

1 file test mới `tests/ios/bridge_test.cpp` (hoặc `.mm` nếu cần link Foundation cho
`NSDictionary` của `EngineKeyMap`) — **tái dùng nguyên bộ case Telex→Unicode đã có trong
`tests/core/test_engine.cpp`** (5 case: "xin chaof cacs banj", "tieengs vieetj", v.v.), nhưng
gọi qua `KeyboardBridge` (bridge layer mới) thay vì gọi thẳng `vKeyHandleEvent` — mục đích là
test WIRING của bridge (định nghĩa 20 extern, map char→KEY_x, đọc `pData`), không phải test
lại engine (đã có `tests/core` lo việc đó).

### Integration / End-to-End Scenarios — trả lời mục 6 (2/3)

1 build-smoke test: `xcodebuild -project platforms/apple/MindfulKey.xcodeproj -scheme
MindfulKeyKeyboard -sdk iphonesimulator build` chạy sạch (0 error) — mirror đúng cách
`make build` hiện làm cho macOS, gate trong `make test-ios`.

### Performance / Load Considerations — trả lời mục 6 (3/3)

**Kiểm THỦ CÔNG ở Round 1, chưa tự động hoá được:** cài lên simulator/device thật, gõ liên
tục trong Notes + Zalo, theo dõi Xcode Debug Memory Graph / Instruments xem RAM extension có
tiệm cận trần jetsam (~48-60MB) không, và extension có bị hệ điều hành kill giữa phiên gõ
không. Ghi kết quả vào `tests/ios/README.md` sau mỗi lần thử — chưa có cách assert tự động
"không bị kill" trong CI vì đó là hành vi của hệ điều hành, không phải unit test được.

### Security Testing Notes

Không áp dụng nhiều — không có network call, không có auth. Chỉ cần review 1 điểm: App Group
`NSUserDefaults` không được vô tình ghi nội dung gõ thật (chỉ ghi timestamp + bool).

---

## Dependencies

### External Dependencies

*Không có dependency bên thứ 3 nào ở Round 1* — chỉ dùng UIKit/Foundation có sẵn trong iOS SDK.

### Internal / Shared Dependencies

- `core/engine` (đóng băng, chỉ tiêu thụ qua API — xem §API Design).
- `core/mood` (build vào target theo FR-001 cho parity cấu trúc, không wire hành vi nào).
- `platforms/apple/shared/` — SỞ HỮU CHUNG với đội macOS (đội macOS đã có `shared/` trong
  sources của target macOS từ trước — bất kỳ file nào rút vào đây cần review chéo để không
  vỡ build macOS hiện có).

---

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| R1: RAM runtime thật (không phải binary size) vượt trần jetsam khi bàn phím tự vẽ + UIKit overhead cộng dồn | Cao — extension bị kill giữa phiên gõ, trải nghiệm vỡ hoàn toàn | Trung bình — 198KB code không phải rủi ro chính, UIKit view mới là ẩn số thật | Giữ macro/smart-switch rỗng mặc định (§NFR Performance), đo bằng Instruments sớm ở story #3-4 thay vì để tới cuối |
| R2: `platforms/apple/shared/` đã dùng chung với target macOS — sửa nhầm phá build macOS | Cao — vi phạm "không giẫm chân đội macOS" | Thấp nếu review chéo | Nhịp 0 chỉ THÊM file mới vào `shared/`, không sửa file macOS hiện có; chạy `make build` (macOS) sau mỗi thay đổi `shared/` |
| R3: Full Access bị Apple Review từ chối nếu copy giải thích không đủ rõ | Trung bình — chặn ship, không chặn Round 1 dev | Thấp ở Round 1 (chưa submit App Store) | Giữ nguyên tắc "giải thích rõ vì sao cần quyền" đã áp dụng bên macOS; chưa cần giải quyết triệt để tới khi thật sự submit |
| R4: Mockup 2 màn onboarding chưa tồn tại (open item từ SPEC.md) | Trung bình — story #5 không có design cụ thể để bám | Chắc chắn xảy ra nếu không xử lý | Chủ dự án cung cấp mockup/mô tả trước khi bắt đầu story #5, hoặc dev tạm dùng wireframe chữ thuần theo mô tả trong FR-003 |
| R5: XcodeGen YAML đề xuất ở §Key Components #1 chưa chạy thử thật | Thấp — chỉ là cấu hình, dễ sửa | Cao (chưa test) | Story #2 verify bằng `xcodegen generate` thật là bước đầu tiên, không giả định YAML đúng 100% |

---

## Assumptions & Constraints

### Assumptions

1. iOS 16.0 làm deployment target tối thiểu (khớp SDK đã dùng để thực nghiệm compile —
   `iphonesimulator16.0`; có thể hạ thấp hơn nếu chủ dự án muốn support máy cũ hơn, chưa xác nhận).
2. Bundle ID `vn.gnh.mindfulkey.ios*` là đề xuất theo pattern `vn.gnh.mindfulkey` đã dùng cho
   macOS (`platforms/apple/project.yml`) — cần chủ dự án xác nhận.
3. Build Round 1 vẫn ký ad-hoc / chạy simulator, giống cách macOS đang làm (`docs/INSTALL.md`)
   — chưa cần Apple Developer Program thật.

### Constraints

1. Không sửa `core/` — đã CHỨNG MINH bằng thực nghiệm là không cần thiết, không phải chỉ là quy tắc.
2. Đội iOS chỉ sở hữu `platforms/apple/ios/**` và `platforms/apple/shared/**`.
3. On-device 100%, không dùng mạng ở Round 1.
4. `platforms/apple/shared/` là tài nguyên DÙNG CHUNG với đội macOS — mọi thay đổi ở đây ảnh
   hưởng cả 2 đội, không đơn phương.

---

## Success Criteria

- [ ] Cài được keyboard extension, gõ đúng "tiếng Việt" có dấu bằng Telex trong Notes và Zalo.
- [ ] Extension không bị hệ điều hành kill vì RAM trong một phiên gõ thông thường (kiểm thủ công).
- [ ] `git diff core/` rỗng tại thời điểm hoàn thành Round 1.
- [ ] `make test-ios` chạy được test thật (không còn no-op).
- [ ] `make build` (macOS) vẫn xanh sau khi thêm file vào `shared/` — không giẫm chân đội macOS.
- [ ] All MUST functional requirements (FR-001, FR-002, FR-003, FR-005) implemented and accepted.

---

## Decisions Log Summary

| Decision | Rationale | Date |
|----------|-----------|------|
| `core/` không cần sửa gì cho iOS | Thực nghiệm compile `arm64-apple-ios16.0-simulator` thành công, `platforms/mac.h` chỉ là hằng số nguyên, không phải API AppKit | 2026-07-10 |
| Nhịp 0 chỉ rút được 3 thứ (key map, config defaults, hex màu) — KHÔNG rút được nguyên file `.m`/`.mm` nào | Toàn bộ `platforms/apple/macos/*.mm` gắn chặt AppKit (`NSColor`) hoặc CGEventTap (Carbon) — không tồn tại trên iOS | 2026-07-10 |
| Container phát hiện "bàn phím đã bật" bằng App Group heartbeat, không phải API trực tiếp | Apple không có API public đáng tin cậy cho việc này — giới hạn nền tảng, không phải thiếu sót thiết kế | 2026-07-10 |
| Container app viết bằng **Objective-C** (không Swift) ở Round 1 | Mốc A đã scaffold container bằng Obj-C, khớp bridge `.mm` của extension — không trộn 2 ngôn ngữ cho 1 walking skeleton | 2026-07-11 |
| Container KHÔNG biên dịch `core/engine`/`core/mood`; chỉ extension mới ôm engine | Đối chiếu `project.yml` thật: container chỉ cần UI + đọc App Group, không gọi engine → giảm bề mặt build & RAM | 2026-07-11 |
| App Group `group.vn.gnh.mindfulkey` + Bundle ID = tên đã CHỐT (Q7), còn wiring entitlements | Chủ dự án đã duyệt tên (decision-log 2026-07-11); entitlements/`CODE_SIGN_ENTITLEMENTS` chưa tồn tại trong `project.yml` = việc code FR-A06, chặn story #5 (heartbeat) | 2026-07-11 |

*(Entry đầy đủ đã ghi vào `bmad-output/ios/decision-log.md` — tiếp tục dùng log riêng đội iOS như đã thống nhất từ bước SPEC.)*

---

## Next Steps

Tech-spec này DỪNG Ở ĐÂY theo chỉ đạo của chủ dự án — KHÔNG tự chạy `bmad-epics-and-stories`
hay `bmad-parallel-plan`. Bước sau là DEV dựng skeleton trực tiếp theo Story List ở trên (1
luồng, không sharding), bắt đầu từ story #1 (Nhịp 0).

---

*Technical Specification — Quick Flow Track — BMAD Method by the BMAD Code Organization*
