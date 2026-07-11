# TEST_MATRIX — bảng hành vi → bằng chứng

> Đây là **sổ cái bằng chứng**, không phải danh sách tính năng. Mỗi dòng là một
> hành vi sản phẩm; các cột kiểm thử cho biết hành vi đó **đã được chứng minh tới
> đâu**. Cột **Bằng chứng** phải trỏ tới thứ có thật (file test, lệnh chạy, output) —
> không ghi suông. Nếu một hành vi ghi `implemented` mà Bằng chứng = `none`, đó là
> tín hiệu *"code có thể build sạch nhưng chưa ai chứng minh nó chạy thật"* (đúng
> kiểu bug bước 4: `MoodWatchMac_Init()` chưa từng được gọi). Không tô màu, không
> chấm điểm — chỉ mô tả trạng thái.

## Cách đọc các cột

- **Engine (unit):** chứng minh ở tầng bộ não C++ thuần (`tests/core/test_engine` qua `make test-core`). Dùng chung mọi OS.
- **macOS (platform):** chứng minh ở vỏ macOS thật (`platforms/apple/macos`, build/chạy/quan sát hành vi).
- **iOS (platform):** chứng minh ở vỏ iOS thật (`platforms/apple/ios`, keyboard extension) — xem khối "Đội iOS" cuối bảng. **Build-verify** (`xcodebuild -sdk iphonesimulator` BUILD SUCCEEDED, tự động) ≠ **đã có người gõ/nhìn** trên simulator/máy thật — 2 mức bằng chứng khác nhau, ghi rõ trong ô Bằng chứng, không gộp lại thành ✅ chung chung.
- **E2E:** chứng minh luồng người dùng đầu-cuối (vd macOS: gõ trong Zalo → gác cổng hiện → nuốt Enter → gửi lại).
- **Bằng chứng:** trỏ cụ thể. `none` = chưa có gì.
- **Trạng thái:** `planned` · `in_progress` · `implemented` · `changed` · `retired`.

Ký hiệu ô: `✅` có bằng chứng · `⚠️` một phần/gián tiếp · `❌` cần mà chưa có · `—` không áp dụng.

## Bảng

| Hành vi | Engine | macOS | E2E | Bằng chứng | Trạng thái |
|---|---|---|---|---|---|
| Gõ Telex → Unicode, bỏ dấu cơ bản | ✅ | — | — | `tests/core/test_engine` 5 case (`make test-core`) | implemented *(chỉ unit)* |
| Ghép vần / luật bỏ dấu nâng cao (`Vietnamese.cpp`) | ⚠️ | — | — | gián tiếp qua 5 case, chưa có case riêng | planned |
| Tự đổi Việt/Anh theo app (`SmartSwitchKey`) | ❌ | ❌ | — | none | planned |
| MoodBuffer gom từ → câu | ❌ | — | — | none | planned |
| MoodWatch đọc cảm xúc chạy thật trên máy | — | ⚠️ | — | bước 4 vá `Init` chưa gọi; chưa có test chứng minh chạy | in_progress |
| **Gác cổng Enter-không-Shift (Zalo/Discord)** | — | ❌ | ❌ | none — luồng chính chưa có bằng chứng E2E | in_progress |
| MoodStore mã hóa (AES-256 + Keychain, at-rest) | — | ❌ | — | none — chưa chứng minh file thật sự mã hóa | implemented (?) |
| Consent gate hỏi 1 lần lúc khởi động | — | ❌ | — | none | implemented (?) |
| Chuông/Nudge — cooldown 45s, snooze 1 giờ | — | ❌ | — | none | implemented (?) |
| Reflection cuối ngày (`FetchTodaySummary`) | — | ❌ | — | none | implemented (?) |
| Xuất brand asset (SVG → PNG/.icns) | — | ✅ | — | `make brand` / `brand/export.sh` chạy được | implemented |
| Đóng gói DMG ad-hoc | — | ✅ | — | verify mount + `codesign -dv` sạch (`docs/INSTALL.md`) | implemented |
| **[2026-07-10] Thay áo 4 cửa sổ legacy macOS (mindful-key) theo NOW BRAND OS** | | | | | |
| Cửa sổ Điều khiển (4 tab): checkbox cam → PillSwitch teal, tab chọn hết phụ thuộc Accent Color hệ thống | — | ⚠️ | ❌ | build sạch (0 warning mới, đối chiếu baseline qua git stash) + `ibtool` (4→2 notice, không phát sinh mới) + khối card Gác cổng (story 1.4, đang dở) verify nguyên vẹn **2 lần độc lập**; CHƯA ai nhìn app thật. `mindful-key` commit `3b41b3d` | implemented |
| Cửa sổ Gõ tắt (Macro): checkbox/nút → PillSwitch/CTAButton/SecondaryButton | — | ⚠️ | ❌ | build sạch (11 warning = baseline) + `make test` xanh + `ibtool` cải thiện (43→42); CHƯA ai nhìn app thật. `mindful-key` commit `d370161` | implemented |
| Cửa sổ Chuyển mã (Convert): checkbox/nút → PillSwitch/CTAButton/SecondaryButton | — | ✅ | ❌ | **Duy nhất trong đợt có test hành vi thật** — lldb gọi trực tiếp IBAction xác nhận: toggle↔UserDefaults, 4 tùy chọn HOA/thường loại trừ lẫn nhau, 1 lần chuyển mã thật ("Xin chào các bạn"→"xin chào các bạn"), nút Đóng, giữ trạng thái qua relaunch app. Vẫn KHÔNG phải người nhìn — là lldb gọi hàm hộ. `mindful-key` commit `7c759a7` (+ vá notice `6b652af`) | implemented |
| Cửa sổ Thông tin (About): logo sóng `~` thay "V" đỏ, vá bug đè chữ "Trang GitHub"/credit, checkbox/nút → PillSwitch/CTAButton | — | ⚠️ | ❌ | build sạch (warning diff rỗng so baseline) + credit "Mai Vũ Tuyên (GPL v3)" verify byte-identical qua `grep` + logo verify qua `iconutil` export ngược; CHƯA ai nhìn app thật xem layout đè chữ đã hết hẳn chưa. `mindful-key` commit `2a4a090` | implemented |
| Radio "Chế độ gõ" (Việt/English) tô teal đầy đủ (không chỉ chữ label) | — | ❌ | — | AppKit không có API tint công khai cho glyph radio (cùng lý do PillSwitch phải tự vẽ) — cố ý CHƯA làm, vì thay control rủi ro gãy cơ chế loại-trừ Việt/Anh mà sandbox không click-test được | planned |
| **[2026-07-11] Đội iOS — Round 1 walking skeleton (8 story, `bmad-output/ios/stories/`)** | | | | | |
| Target iOS build từ `project.yml` chung (FR-A03, story 1.5) | — | ✅¹ | ⚠️ | `xcodegen generate` exit 0 (3 scheme) + `xcodebuild -sdk iphonesimulator` BUILD SUCCEEDED cho `MindfulKeyiOS`+`MindfulKeyKeyboard`, `make build` macOS vẫn xanh — build-verify thật, đóng Risk R5 tech-spec. Commit `dfb083d`. Chưa ai chạy app trên simulator | implemented |
| Gõ Telex ra dấu qua `core/engine` — Mốc B (FR-A01, story 1.2) | ✅¹ | ✅¹ | ❌ | `KeyboardBridge_HandleKeyTap` route qua `vKeyHandleEvent`; `tests/ios/bridge_test.mm` 5 ca Telex→Unicode PASS qua bridge (`make test-ios`, commit `91a8742`); build-verify BUILD SUCCEEDED. **CHƯA có ai gõ "vieetj"→"việt" trong Notes/Zalo thật** — đây là hành vi lõi, E2E vẫn ❌ | implemented *(bridge-verified, chưa device)* |
| Shift/Caps + lớp số & ký hiệu (FR-A02, story 1.3) | — | ✅¹ | ❌ | 3-state Shift (off/one-shot/lock), double-tap, 123↔ABC, hit ≥44pt — code + build-verify (commit `c6c042d`). Hành vi chạm/double-tap CHƯA ai thử trên simulator | implemented *(build-verified only)* |
| Loại ô mật khẩu — không đọc/log/mạng (FR-A07, story 1.4) | — | ✅ | ❌ | audit tĩnh (grep) xác nhận 0 `NSLog`/App-Group-nội-dung/network trong 2 file phạm vi + build sạch (commit `7760f38`) — đây là NEGATIVE test (chứng minh KHÔNG có hành vi xấu), mạnh hơn build-verify thường. Chưa ai gõ thật vào field `secureTextEntry=YES` | implemented |
| App Group heartbeat — container phát hiện "đã kích hoạt" (FR-A06, story 1.6) | — | ✅¹ | ❌ | entitlements 2 target + `AppGroupBridge` (chỉ timestamp/bool) — code + build-verify cả 3 scheme (iOS×2 + macOS), 1 bug link C++ name-mangling sửa tận gốc (commit `6e83b8d`). Round-trip heartbeat thật (viết ở extension, đọc ở container trên máy) CHƯA thử | implemented *(build-verified only)* |
| Onboarding 2 màn (kích hoạt + Full Access) + Home (FR-A04/A05, story 1.7) | — | ⚠️² | ❌ | dựng theo `EXPERIENCE.md`, build-verify BUILD SUCCEEDED + 1 lần cài+mở trên Simulator không crash (Màn 01 render đúng wireframe) — gần nhất với "có người nhìn" trong đợt này, nhưng chưa đi hết luồng (chưa bấm thật qua Cài đặt hệ thống, chưa VoiceOver/Reduce-Motion). Asset nhận diện (glyph/wordmark/copy) là **placeholder**, đánh dấu `TODO(Q10b)` — chưa chốt | implemented *(1 lần smoke, chưa full walkthrough)* |
| `tests/ios` test thật — bridge + build-smoke (FR-A17, story 1.8) | ✅ | ✅ | — | `make test-ios` chạy CẢ HAI: bridge test (5 ca) + `build_smoke.sh` (`xcodebuild` simulator); verify RED thật (bẻ scheme → exit 2, trả lại → 0) — không còn no-op. Commit `0c1ade7` | implemented |
| ⌫ backspace / sửa giữa từ ở engine (Loại 6, story 1.1) | ✅ | — | — | `tests/core/test_engine.cpp` +3 ca, kỳ vọng lấy từ `make test-core` thật (không đoán); phát hiện 1 quirk engine (`as⌫⌫nawm`→"nawm" không "năm" — biến hình không tái kích hoạt sau ⌫-về-rỗng qua âm tiết có dấu), đã khóa làm mốc regression, chưa báo đội core. Commit `6ff72f0` | implemented |
| Đo RAM extension trong giới hạn jetsam ~48–60MB | — | ❌ | ❌ | none — cần Instruments trên simulator/thiết bị thật, không tự động hóa được | planned |
| ~~Gác cổng gửi tin xuyên app trên iOS (Feature #1 bản macOS)~~ | — | — | — | **bất khả thi** — keyboard extension sandbox không có global hook/không thấy nút Gửi host app (FRICTION-LOG 2026-07-10, đã chốt) | retired |
| Con sóng `~` cảm xúc + tiếng chuông (Round 2, FR-A08/A09/A10) | — | — | — | none — chặn ở quyết định nhận diện Q1–Q3 (`bmad-output/ios/analysis/09-bmad-reconcile.md`), chưa khởi công | planned |

> **Vì sao macOS=⚠️ chứ không phải ✅ cho 3/4 cửa sổ trên:** sandbox agent không có quyền
> Accessibility → không tự động click được, và gọi thẳng AppKit qua `lldb` từng gây deadlock 1 lần
> (thử ở story 1.8) nên các story sau tránh dùng — verify bằng build sạch + `make test` + `ibtool`
> + app khởi động không crash, KHÔNG phải bằng mắt thấy UI chạy đúng. Cửa sổ Convert là ngoại lệ vì
> lldb-gọi-hàm áp dụng thành công trước khi phát hiện rủi ro deadlock ở story sau.

**Chú thích `(?)`:** changelog CLAUDE.md ghi các bước này "xong / build sạch", nhưng
Bằng chứng hiện = `none`. Dấu `(?)` là lời nhắc trung thực: cần một lần chạy thật để
nâng từ *"đã code"* lên *"đã chứng minh"*.

**Chú thích ¹/² (khối Đội iOS 2026-07-11):** `✅¹` = build-verify thật (`xcodebuild` compile+link
thành công cho iOS Simulator, không phải suy đoán) nhưng **CHƯA có người chạy app quan sát hành
vi** — build sạch không đồng nghĩa hành vi đúng (đúng bài học "MoodWatchMac_Init() chưa từng được
gọi" ở đầu file này). `⚠️²` = có 1 lần cài+mở trên Simulator (không crash, UI render đúng), gần
nhất với "có người nhìn" trong đợt nhưng chưa đi hết luồng.

## Đọc bảng này thấy gì (tính đến 2026-07-10)

- Bộ não có unit test (5 case), nhưng **gần như toàn bộ lớp mood + gác cổng đang
  `implemented`/`in_progress` mà Bằng chứng = none, E2E = none.**
- Lỗ hổng lớn nhất: **hành vi gác cổng** (Feature #1) — trái tim sản phẩm — chưa có
  một bằng chứng E2E nào.
- Đợt thay áo NOW BRAND OS cho 4 cửa sổ legacy macOS (2026-07-10) đúng lỗ hổng bảng này chuyên
  bắt: **4/5 dòng mới đều `implemented` với macOS=⚠️/E2E=❌** — build sạch, test/ibtool xanh,
  nhưng chưa ai *nhìn thấy* UI chạy đúng ngoài đời (sandbox không có quyền Accessibility). Việc
  còn lại không phải code — là 1 người mở app thật, liếc qua 4 cửa sổ, nâng E2E lên ✅.
- **Đội iOS — Round 1 (2026-07-11):** đảo ngược hoàn toàn so với 2026-07-10 — 8/8 story code
  xong, mọi cổng tự động xanh (`make test-core`/`make test-ios`/`make build` macOS/build app iOS
  đều exit 0), `git diff core/` rỗng. NHƯNG bảng trên cố ý dùng `✅¹`/`⚠️²` thay vì `✅` trần cho
  hầu hết dòng: **build-verify KHÔNG phải device-verify**. Chưa một ai gõ "vieetj" trong Notes/Zalo
  thật, chưa đo RAM, chưa đi hết luồng onboarding bằng tay — đây chính là lỗ hổng mà file này tồn
  tại để bắt (đừng lặp lại kiểu `implemented (?)` ở khối mood macOS phía trên). Việc còn lại KHÔNG
  phải code — là chủ dự án mở Simulator, gõ thử, đo RAM, nâng các dòng ✅¹/⚠️² lên ✅ thật.
  Mandate vẫn hẹp: **nhật ký + nhắc thụ động**, KHÔNG gác cổng gửi tin (sandbox chặn, `retired`).
  Con sóng/chuông (Round 2) chặn ở quyết định nhận diện Q1–Q3, chưa khởi công.

## Khi nào cập nhật file này

- Hoàn thành/đổi một hành vi → cập nhật dòng tương ứng, điền Bằng chứng thật.
- Có test/chạy thật mới → nâng ô `❌`/`⚠️` lên `✅` kèm đường dẫn bằng chứng.
- Bỏ một hành vi → đổi Trạng thái sang `retired`, **không xóa dòng** (giữ vết).
- Gọi qua câu nói tự nhiên tới orchestrator: *"soi bằng chứng test"*, *"ma trận test
  còn đúng không"*, *"cập nhật test matrix"*.
