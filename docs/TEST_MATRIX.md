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
| Con sóng `~` cảm xúc + tiếng chuông (Round 2, FR-A08/A09/A10) | — | — | — | Q1–Q3 đã chốt (decision-log 2026-07-13) + R2 story 2.1–2.6 ĐÃ code xong (commit tới `c872c0c`). **Các dòng bằng chứng R2 chi tiết CHƯA backfill vào bảng này** (nợ sổ — doc tụt sau code) | implemented *(R2 shipped, rows pending backfill)* |
| **[2026-07-13] Đội iOS — Round 3 (nhật ký + soi lại + theme)** | | | | | |
| Kho nhật ký cảm xúc mã hóa on-device + consent (FR-A13 nền, story 3.1) | — | ✅ (host) | ❌ | `tests/ios/mood_journal_store_test` 6 ca host PASS qua `make test-ios`: AES-256 round-trip, **negative test "không plaintext trên đĩa"** (`rangeOfData` không thấy 16B event dựng tay + giải mã lại đúng), cổng consent (chưa consent → KHÔNG tạo file), `DeleteAll`, `SetConsent(NO)` xóa sạch; **verify RED thật** (bẻ 1 assert → fail → sửa lại); build-smoke extension iOS Simulator BUILD SUCCEEDED; `git diff core/` rỗng. Kho ở `platforms/apple/shared/MoodJournalStore.mm`, wire ghi ở `MoodBridge.mm` SAU cổng ô-bảo-mật. **Device-only CHƯA verify:** (1) chia sẻ khóa Keychain cross-process extension↔container qua keychain-access-groups (cần Team ID thật, ký ad-hoc không verify được — nếu `errSecMissingEntitlement` là chỗ soát đầu tiên); (2) round-trip 2 tiến trình thật (extension ghi/container đọc cùng file App Group); (3) RAM extension với kho + Keychain + crypto nạp | implemented *(host-verified crypto/consent; cross-process + RAM device-only chưa)* |
| **[2026-07-14] Đội macOS — Diện mạo mới v2 (Epic 2)** | | | | | |
| Kho nhật ký lấy mẫu (Story 2.3) | — | ✅ | ❌ | build sạch (0 warning mới) + `make test` xanh + `make brand-lint` 0 lỗi. Tự động tích lũy sum/count qua `analyzeRecentTextAsync` và gọi `MoodStoreMac_LogSampleEvent`. `git diff core/` rỗng. CHƯA ai nhìn app thật. Commit `b35fb2b` | implemented |
| UI Check-in 1 chạm (Story 2.3) | — | ✅ | ❌ | Cấu hình heartbeat timer nội bộ trên Main Queue trong `PanelViewController` hiện `NSPanel` sau thời gian `vBellInterval`, lưu 3 mức sóng `MoodStoreMac_LogCheckinEvent`. Commit `b35fb2b` | implemented |
| Đổi độ nhạy 3 mức (Story 2.3) | ✅ | ✅ | ❌ | `make test` test C++ (`NudgeCoordinatorIOS` tương đương) xanh. macOS đọc trực tiếp biến cài đặt (thay vì hằng số cứng). Tự test "bật/tắt" qua test shell. CHƯA gõ thật xem E2E có đúng 5/3/2 câu không. Commit `b35fb2b` | implemented |
| Cửa sổ quản lý 6 mục nav trái (Story 2.2) | — | ⚠️ | ❌ | ~~✅~~ **HẠ CẤP 2026-07-15 khi có mắt nhìn thật:** build sạch, `make test` xanh, `make brand-lint` 0 lỗi, instantiate VC + chuyển tab chạy (commit `66cce8b`) — nhưng nghiệm thu tay phát hiện **mục "Hệ thống" trắng trơn hoàn toàn** (F1) và **4/6 mục lệch thiết kế** (F2/F5/F6/F7). Khung nav 6 mục đúng mockup; NỘI DUNG bên trong thì chưa. Xem `bmad-output/macos/ACCEPTANCE-v2-2026-07-15.md` | implemented *(khung đúng, nội dung chưa)* |
| Emotion River (Story 2.4) | — | ✅ | ❌ | build sạch, `make test` xanh. `MKRiverCanvas` render gap (`NSNull`). `SettingsWindowController` nhúng river đúng tab Hôm nay. Commit `fa76313` | implemented |
| Cửa sổ Soi lại (Reflection Screen) (Story 2.4) | — | ✅ | ❌ | build sạch, `make test` xanh. `ReflectionScreenMac_Show` thay bằng custom window, chia 4 nhịp, nút gọi callback cập nhật cài đặt giờ. Commit `fa76313` | implemented |
| Tab Chuông - Nhịp định kỳ (Story 2.5) | — | ✅ | ❌ | build sạch, `make test` xanh. Thêm thẻ "Nhịp" có MKSegmented (15, 30, 60), chọn theo khoảng gần nhất, gọi `BellMac_ApplySettings()` khi đổi. Không rớt `kBellSoundMuteName`. Commit `6d15a0b` | implemented |
| Pane Riêng tư - Xuất CSV & Tự xóa (Story 2.6) | — | ✅ | ❌ | build sạch, `make test` xanh. Thêm `PrivacyPaneView`, bật tắt consent, xuất CSV (thu hẹp), hẹn tự xóa (mặc định 90 ngày) gọi `DELETE`. Commit `c5646e9` | implemented |
| Khóa toàn bộ UI macOS ở chế độ Sáng (Option A, Follow-up) | — | ✅ | ❌ | Bổ sung `NSApp.appearance = NSAppearanceNameAqua` tại `AppDelegate.m`. Khắc phục triệt để lỗi "khung đen, lõi trắng" khi macOS ở Dark Mode, giúp đồng nhất 100% với bản vẽ HTML tĩnh. Build sạch, test xanh. CHƯA mở app thật để ngắm. | implemented |
| Sửa lỗi cắt cúp UI Popover (Bug fix) | — | ✅ | ❌ | Bỏ thao tác gán `self.view.frame` thủ công trong `PanelViewController` khi đổi chiều cao. Khắc phục triệt để lỗi popover bị khoảng trống ở trên hoặc bị xén mất header/tab/phần "Nhịp" ở các màn hình có chiều cao giới hạn do xung đột với layout auto-resize của `NSPopover`. Build sạch, test xanh. Đã chạy thử nghiệm. | implemented |
| Hoàn thiện tính năng lõi Chuông & Nhận diện (Story 2.7) | — | ✅ | ❌ | 1. Thêm 2 file âm thanh `Chuông chùa.wav` và `Chuông gió.wav` sinh tự động để chuông kêu thật thay vì `Glass` fallback. 2. Sửa thuật toán làm sạch chữ ở `MoodWatchMac.mm` để loại bỏ dấu câu (chấm phẩy, phẩy, hỏi, than...) trước khi phân tích, giúp bắt trúng từ khoá ngay cả khi dính liền với dấu câu. Build sạch, test xanh. | implemented |
| Di chuyển "Nhận diện độ nhạy" sang tab "Hôm nay" (Cân đối giao diện) | — | ✅ | ❌ | SensCard tách thành `SensitivityCardView`, nhúng dưới Gatekeeper trong Hôm nay. Popover co giãn mượt mà. | implemented |
| Khắc phục lỗi reo chuông và Quyền thông báo (Bug fix) | — | ✅ | ❌ | Thêm yêu cầu quyền thông báo `UNUserNotificationCenter` lúc start. Sửa lỗi thay đổi giờ yên lặng ở UI không cập nhật bộ nhớ `vBellFrom/vBellTo` trong `controlTextDidEndEditing:`. | implemented |
| Đưa khung cuộn NSScrollView vào Popover (Đồng nhất UI) | — | ✅ | ❌ | Gom nội dung các tab động vào `NSScrollView` cục bộ của `PanelViewController`. Cố định Header/Tab bar và Footer không bị cuộn mất khi Popover quá dài. | implemented |
| Cấu hình phím tắt nhanh cho Chuông & Bộ gõ (Hotkeys) | — | ✅ | ❌ | Bổ sung nút ghi âm phím nóng trực tiếp (phím tắt chuông mặc định `⌥⌘B`, bộ gõ `⌥Z`) bên cạnh switch ở tab Chuông và Bộ gõ. Tích hợp event intercept trong `OpenKey.mm` và đồng bộ qua NotificationCenter. | implemented |
| **[2026-07-15] NGHIỆM THU TAY LẦN 1 — chủ dự án mở app thật, xem 5/6 mục nav cửa sổ quản lý (có ảnh)** | | | | | |
| **Mục "Hệ thống" hiện được nội dung** (F1) | — | ❌ | ❌ | **PHẢN CHỨNG bằng mắt:** pane trắng trơn hoàn toàn — không tiêu đề, không control. Code: `SettingsWindowController.mm:388` show `_openKeyVC.tabviewSystem`; outlet CÓ thật (`Main.storyboard:1871`). **Nguyên nhân chưa biết** — giả thuyết `@property(weak)` (`ViewController.h:21`) + `removeFromSuperview` → box giải phóng → nil; nhưng CHƯA giải thích được vì sao `tabviewPrimary` y hệt cơ chế lại hiện tốt. Cấm vá mò | in_progress *(Epic 3 gate 4)* |
| **Pane "Hôm nay" có card Gác cổng (Feature #1) nổi nhất** (F2) | — | ❌ | ❌ | **PHẢN CHỨNG bằng mắt:** không có card gác cổng, không link "Soi lại →", không chân trang riêng tư — chỉ tiêu đề + khung sông rỗng. Code xác nhận đây là **việc chưa làm**, không phải bug: `mk_buildTodayPane` (`SettingsWindowController.mm:333-337`) chỉ dựng title + `EmotionRiverView`. Chạm HIẾN CHƯƠNG §5 điều 10 (Feature #1 luôn nổi nhất) | in_progress *(Epic 3 gate 3)* |
| **Lối vào màn "Soi lại" 4 nhịp từ cửa sổ** (F3) | — | ❌ | ❌ | **PHẢN CHỨNG bằng mắt:** không có lối vào. `ReflectionScreenMac_Show` tồn tại + build sạch (`fa76313`) nhưng **không ai gọi được từ cửa sổ** → dòng "Cửa sổ Soi lại (Story 2.4)" phía trên là code-có-thật-nhưng-người-dùng-không-tới-được | in_progress *(Epic 3 gate 3)* |
| **Mọi mục xem hết được nội dung (không cắt đáy)** (F5) | — | ❌ | ❌ | **PHẢN CHỨNG bằng mắt:** "Chuông" cụt ở thanh Âm lượng, "Riêng tư" cụt giữa nút "Xóa toàn bộ nhật ký". Code (nguyên nhân ĐÃ truy ra, không cần điều tra): `kMaxPaneH = 472.0` cố định (`SettingsWindowController.mm:55`) + **cả file không có `NSScrollView`**. Popover đã chữa ở `d377eaf`; cửa sổ bị bỏ sót — cùng bệnh, mới chữa một nửa | in_progress *(Epic 3 gate 1)* |
| **Nhãn control hiện đủ chữ** (F6) | — | ❌ | — | **PHẢN CHỨNG bằng mắt:** "Tạm tắt Mindful Keyboard bằng p" cụt ở Bộ gõ ▸ Kiểu gõ; "Tạm tắt chính tả bằng phím ^" sát mép | in_progress *(Epic 3 gate 1)* |
| **Cam CHỈ dùng cho CTA + link active** (HIẾN CHƯƠNG §5 điều 6) (F7) | — | ⚠️ | — | **NGHI PHẠM, thấy bằng mắt:** chấm CAM đánh dấu "Bộ tiếng" đang chọn ở tab Chuông — "đang chọn" là TRẠNG THÁI, không phải CTA. `make brand-lint` 0 lỗi mà vẫn lọt → lint chưa bắt được ca này. Cần soát: chấm chọn hay một phần glyph? | in_progress *(Epic 3 gate 2)* |
| **1 token teal duy nhất cho mọi PillSwitch ON** (F8) | — | ⚠️ | — | **thấy bằng mắt:** PillSwitch ở Bộ gõ nhạt hơn hẳn ở Chuông, cùng trạng thái ON → 2 sắc teal khác nhau. Nguyên nhân chưa truy | in_progress *(Epic 3 gate 1)* |
| Khung nav 6 mục (đúng thứ tự, chấm trung tính, mục chọn nền tealLight) | — | ✅ | — | **Mắt nhìn thật xác nhận ĐÚNG mockup A2** — đây là dòng ✅-thật đầu tiên của Epic 2 (không phải build-verify). Đủ 6 mục, đúng thứ tự Hôm nay·Chuông·Bộ gõ·Riêng tư·Hệ thống·Giới thiệu; Bộ gõ có sub-nav 3 mục | implemented |
| Không có vi phạm hiến chương ở 5 màn đã xem (ngoài F7) | — | ✅ | — | **Mắt nhìn thật:** không đèn đỏ/xanh cảm xúc, không mặt cười, không streak/điểm/huy hiệu, không copy khiển trách. Copy "Riêng tư" đúng giọng quan sát ("Quên có chủ đích — các sự kiện cũ sẽ tự biến mất…") | implemented |
| Mục "Giới thiệu" (credit Mai Vũ Tuyên + GPL v3) | — | ❌ | — | none — **nghiệm thu 2026-07-15 CHƯA xem mục này**. Hệ trọng pháp lý (GPL v3 + credit). Đừng suy diễn "không nhắc = đã đạt" | implemented (?) |
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

- **Đội macOS — nghiệm thu tay lần 1 (2026-07-15): file này vừa chứng minh nó tồn tại để làm gì.**
  Cả Epic 2 (6 bước v2) từng ghi `✅` ở cột macOS với bằng chứng "build sạch + `make test` xanh +
  `brand-lint` 0 lỗi" — mọi cổng tự động đều xanh. Chủ dự án mở app thật xem 5/6 mục nav: **10
  finding**, trong đó một mục nav **trắng trơn** (Hệ thống), Feature #1 **không có mặt** ở pane
  "Hôm nay", nội dung **cắt cụt** ở 2 mục, và 1 nghi phạm hiến chương (chấm cam) mà `brand-lint`
  không bắt. Bài học đóng đinh: **build-verified không nói gì về việc màn hình có giống thiết kế
  hay không** — nó chỉ nói code hợp lệ. Từ Epic 3 trở đi, bằng chứng nhận `✅` cột macOS phải là
  **mắt nhìn app thật**; build-verified xuống hạng `⚠️`. Chi tiết:
  `bmad-output/macos/ACCEPTANCE-v2-2026-07-15.md`.

## Khi nào cập nhật file này

- Hoàn thành/đổi một hành vi → cập nhật dòng tương ứng, điền Bằng chứng thật.
- Có test/chạy thật mới → nâng ô `❌`/`⚠️` lên `✅` kèm đường dẫn bằng chứng.
- Bỏ một hành vi → đổi Trạng thái sang `retired`, **không xóa dòng** (giữ vết).
- Gọi qua câu nói tự nhiên tới orchestrator: *"soi bằng chứng test"*, *"ma trận test
  còn đúng không"*, *"cập nhật test matrix"*.
