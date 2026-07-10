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
- **iOS (platform):** chứng minh ở vỏ iOS thật (`platforms/apple/ios`, keyboard extension). Hiện chưa có code — xem khối "Đội iOS" cuối bảng.
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
| **[2026-07-10] Đội iOS — keyboard extension (mandate: nhật ký + nhắc thụ động, KHÔNG gác cổng)** | | | | | |
| iOS keyboard extension scaffold (`platforms/apple/ios`, XcodeGen target) | — | — | — | none — chưa mở nhánh, `platforms/apple/ios/` mới có README | planned |
| MoodBuffer gom câu trong khung IME (dùng chung `core/mood`, không fork) | ❌ | — | — | none | planned |
| Nhật ký cảm xúc local (trong khung sandbox extension) | — | — | — | none | planned |
| Nhắc chánh niệm thụ động (gợn sóng `~` ambient, không chặn) | — | — | — | none | planned |
| ~~Gác cổng gửi tin xuyên app trên iOS (Feature #1 bản macOS)~~ | — | — | — | **bất khả thi** — keyboard extension sandbox không có global hook/không thấy nút Gửi host app (FRICTION-LOG 2026-07-10, đã chốt) | retired |

> **Vì sao macOS=⚠️ chứ không phải ✅ cho 3/4 cửa sổ trên:** sandbox agent không có quyền
> Accessibility → không tự động click được, và gọi thẳng AppKit qua `lldb` từng gây deadlock 1 lần
> (thử ở story 1.8) nên các story sau tránh dùng — verify bằng build sạch + `make test` + `ibtool`
> + app khởi động không crash, KHÔNG phải bằng mắt thấy UI chạy đúng. Cửa sổ Convert là ngoại lệ vì
> lldb-gọi-hàm áp dụng thành công trước khi phát hiện rủi ro deadlock ở story sau.

**Chú thích `(?)`:** changelog CLAUDE.md ghi các bước này "xong / build sạch", nhưng
Bằng chứng hiện = `none`. Dấu `(?)` là lời nhắc trung thực: cần một lần chạy thật để
nâng từ *"đã code"* lên *"đã chứng minh"*.

## Đọc bảng này thấy gì (tính đến 2026-07-10)

- Bộ não có unit test (5 case), nhưng **gần như toàn bộ lớp mood + gác cổng đang
  `implemented`/`in_progress` mà Bằng chứng = none, E2E = none.**
- Lỗ hổng lớn nhất: **hành vi gác cổng** (Feature #1) — trái tim sản phẩm — chưa có
  một bằng chứng E2E nào.
- Đợt thay áo NOW BRAND OS cho 4 cửa sổ legacy macOS (2026-07-10) đúng lỗ hổng bảng này chuyên
  bắt: **4/5 dòng mới đều `implemented` với macOS=⚠️/E2E=❌** — build sạch, test/ibtool xanh,
  nhưng chưa ai *nhìn thấy* UI chạy đúng ngoài đời (sandbox không có quyền Accessibility). Việc
  còn lại không phải code — là 1 người mở app thật, liếc qua 4 cửa sổ, nâng E2E lên ✅.
- **Đội iOS (mới vạch phạm vi 2026-07-10):** tất cả `planned`, chưa có 1 dòng code —
  `platforms/apple/ios/` mới có README. Mandate cố ý hẹp: **nhật ký + nhắc thụ động**, KHÔNG
  gác cổng gửi tin (sandbox chặn — dòng gác cổng iOS để `retired`). Người điều phối đội này là
  `ios-shell-agent` + skill `ios-keyboard-extension`.

## Khi nào cập nhật file này

- Hoàn thành/đổi một hành vi → cập nhật dòng tương ứng, điền Bằng chứng thật.
- Có test/chạy thật mới → nâng ô `❌`/`⚠️` lên `✅` kèm đường dẫn bằng chứng.
- Bỏ một hành vi → đổi Trạng thái sang `retired`, **không xóa dòng** (giữ vết).
- Gọi qua câu nói tự nhiên tới orchestrator: *"soi bằng chứng test"*, *"ma trận test
  còn đúng không"*, *"cập nhật test matrix"*.
