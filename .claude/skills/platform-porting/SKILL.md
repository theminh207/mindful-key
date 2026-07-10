---
name: platform-porting
description: Build/port bộ gõ sang từng hệ điều hành cụ thể — Windows (win32/, Win32 hook + tray), macOS (macOS/, Objective-C + CGEventTap), và sau này Android/iOS. PHẢI dùng khi việc nhắc tới build native app, Visual Studio/Xcode, tray icon, popup/biểu đồ cảm xúc hiện trên UI, hoặc thứ tự lộ trình đa nền tảng. KHÔNG dùng để sửa engine/ (bộ não dùng chung) — lỗi riêng 1 OS phải sửa ở vỏ tương ứng, không sửa engine.
---

# Platform Porting

> **Phạm vi:** vỏ **macOS/Windows/Android/Linux**. Vỏ **iOS đã tách sang skill riêng** `ios-keyboard-extension` + agent `ios-shell-agent` (chốt 2026-07-10) — sandbox keyboard-extension khác hẳn, đừng lo iOS ở đây.

## Cổng an toàn (đọc TRƯỚC khi sửa — kể cả khi được gọi thẳng, không qua orchestrator)
- **Phân loại rủi ro:** việc chạm **nhận diện** (con sóng/màu/copy/biên độ) · **pháp lý** (GPL v3, credit Mai Vũ Tuyên) · **riêng tư** (dữ liệu gõ/mood) · **sửa `core/` để vá riêng 1 OS** → **DỪNG, hỏi chủ dự án trước.** Việc nhỏ, rõ, không nhạy cảm → làm luôn.
- **Phải đoán vì thiếu luật/nguồn sự thật?** → thêm 1 dòng cụ thể vào `docs/FRICTION-LOG.md`.

## Kiến trúc: 1 BỘ NÃO + N CÁI VỎ
```
engine/    ← dùng chung, KHÔNG đụng OS (xem skill openkey-engine)
win32/     ← vỏ Windows  (C++ Win32, low-level keyboard hook)
macOS/     ← vỏ macOS    (Objective-C, CGEventTap + Accessibility)
linux/     ← vỏ Linux
(sắp tới: Android, iOS — 2 vỏ mới, giữ nguyên bộ não)
```
Mỗi OS có "ổ cắm" input method khác nhau — không có chuyện 1 code chạy cả 4 nền. Chỉ engine/ và MoodBuffer (thuần C++) dùng chung.

## Thứ tự lộ trình — ĐÃ ĐỔI sang macOS trước (xem docs/PRD.md, CLAUDE.md changelog 2026-07-08)
1. **macOS** — máy dev hiện tại là macOS, build/thử tại chỗ, không phải chờ máy Windows + Visual Studio. Đang làm.
2. **Windows** — sau khi macOS beta ổn định, tái dùng engine/ + design doc lớp cảm xúc, nhưng cần vỏ Win32 riêng.
3. **Android** — tính năng "chặn tin nhắn nóng giận" hợp ngữ cảnh điện thoại nhất.
4. **iPhone** — khuôn chật nhất của Apple, làm cuối cùng. **Đã tách sang skill `ios-keyboard-extension`** (sandbox keyboard-extension: nhật ký + nhắc thụ động, KHÔNG gác cổng gửi tin).

## macOS — sự thật đã xác minh trong repo (không giả định)
- `OpenKey/Sources/OpenKey/macOS/OpenKey.xcodeproj` là project **thật**, chỉ **1 target `OpenKey`** (không phải 3 target như tưởng ban đầu — `OpenKeyHelper`/`OpenKeyUpdate` chỉ là group thư mục + scheme cũ, không phải target build được).
- `ModernKey/AppDelegate.m` đã có sẵn menu-bar UI (NSStatusItem); `OpenKeyManager.m`/`OpenKey.mm` đã bắt phím qua CGEventTap; `MJAccessibilityUtils.m` đã check quyền Accessibility — **không cần viết lại từ đầu**, chỉ nối thêm.
- **Ký code:** target vốn trỏ `DEVELOPMENT_TEAM = 8S7348QV8Q` (tài khoản gốc tác giả OpenKey) — KHÔNG dùng được. Đã đổi sang ký ad-hoc (`CODE_SIGN_IDENTITY = "-"`, `CODE_SIGN_STYLE = Manual`) để build/test local không cần tài khoản trả phí. Khi đóng gói phát hành thật (bước 9), cần Developer ID Application riêng của dev (Apple Developer Program, $99/năm) — xem Phase 0b trong plan.
- **Deployment target:** đã bump từ 10.10 (ngoài phạm vi hỗ trợ của Xcode hiện tại) lên **10.15** (Catalina — cũng là mốc macOS bắt đầu gate Input Monitoring qua TCC).
- `.entitlements` (3 file) hiện **rỗng** (`<dict/>`) — chưa bật Hardened Runtime, chưa có entitlement cụ thể. Việc của bước 9, KHÔNG bật App Sandbox (bắt phím toàn cục không tương thích với sandbox).
- `Info.plist` có `NSAppleEventsUsageDescription` nhưng **chưa có** usage string cho Accessibility/Input Monitoring — cần thêm khi làm luồng xin quyền (bước 4).
- Thêm file mới (.h/.cpp/.mm) vào target: dùng Xcode GUI, hoặc gem `xcodeproj` (`gem install xcodeproj --user-install`, xem lịch sử harness — đã dùng để wire MoodBuffer/MoodWatchMac/BellMac/BreathingPause).

## Nợ kỹ thuật đã biết trước (đừng nhầm với bug mới)
- **Windows gõ chữ ra bằng cách dán qua clipboard + Shift+Insert** — có thể đè clipboard người dùng. Đây là lỗi cố hữu kế thừa từ OpenKey gốc, không phải do lớp cảm xúc gây ra. (Chưa liên quan tới macOS-first hiện tại, ghi lại cho khi quay lại Windows.)
- Win (Win32 C++) và Mac (Objective-C) là 2 codebase tách biệt hoàn toàn — sửa 1 bên không tự động áp dụng bên kia.

## Quy trình khi build/port
1. Chạy smoke test bằng prototype trước khi đụng vào app native thật:
   ```bash
   bash prototype/build-mac.sh   # build CLI prototypes + syntax-check MoodWatchMac.mm/BellMac.mm
   ./prototype/test_engine       # xác nhận bộ não vẫn 5/5
   xcodebuild -project "OpenKey/Sources/OpenKey/macOS/OpenKey.xcodeproj" -scheme OpenKey -configuration Debug build
   ```
2. UI cảm xúc (popup, tray, biểu đồ) được lắp ở tầng vỏ — logic quyết định "có nên cảnh báo không" đến từ MoodWatcher (xem skill `mood-sentiment-layer`), tầng vỏ chỉ chịu trách nhiệm "hiện lên màn hình như thế nào" theo đúng UI convention của OS đó.
3. **Gác cổng gửi tin (bước 5) đã implement** — `SendGatekeeperMac.h/.mm`, wire vào `OpenKeyCallback` (`OpenKey.mm`) ngay sau check "đừng xử lý sự kiện tự tạo". Cơ chế: bắt Enter/Return không Shift + allow-list bundle id (`com.vng.zalo`, `com.hnc.Discord` đã xác minh) thay vì AX semantic "tìm nút Gửi". Khi mở rộng allow-list cho app mới, LUÔN xác minh bundle id thật bằng `defaults read <app>/Contents/Info.plist CFBundleIdentifier`, đừng đoán theo trí nhớ. Chi tiết + hạn chế đã biết: `docs/BREATHING-PAUSE-CONTRACT.md`.
4. Trước khi kết luận lỗi do 1 OS gây ra, cô lập bằng demo tối thiểu trong `prototype/` — nếu lỗi thực ra nằm ở engine dùng chung, chuyển sang skill `openkey-engine`, không tự sửa ở vỏ.

## App chính đã có sẵn khung
Win = `MainControlDialog` + `SystemTrayHelper`; Mac = `ModernKey`. Các tính năng mindfulness (chuông tỉnh thức, hỏi tâm trạng, biểu đồ cuối ngày, gợi ý hồi phục) đắp thêm vào đây — KHÔNG đụng bộ gõ, sống độc lập trong app chính.
