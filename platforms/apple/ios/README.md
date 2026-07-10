# apple/ios

Vỏ **iOS** — bàn phím tiếng Việt chánh niệm dạng **Custom Keyboard Extension** (App Extension).
Chưa mở code. Theo lộ trình nền tảng (`../../README.md`), iOS làm SAU CÙNG — không bắt đầu
trước khi macOS ổn định (Hiến chương: "macOS là công dân hạng nhất").

## Mandate đã chốt (2026-07-10)

iOS bị **sandbox** chặn: keyboard extension không có low-level global hook như macOS
(`CGEventTap`), không thấy nút "Gửi" của host app → **gác cổng gửi tin (Feature #1 bản macOS)
bất khả thi.** Vì vậy chủ dự án đã chốt mandate hẹp lại:

- ✅ **Nhật ký cảm xúc** — MoodBuffer (dùng chung `core/mood`) gom câu trong khung IME, đọc
  send-risk, ghi nhật ký local (chia qua **App Group** nếu cần dùng chung với app chính).
- ✅ **Nhắc chánh niệm thụ động** — con sóng `~` gợn theo biên độ (ambient), "quan sát không
  phán xét". Nhắc, không chặn.
- ❌ **KHÔNG gác cổng gửi tin xuyên app.** Nhận diện "người gác cổng" giữ ở macOS/Windows;
  iOS thể hiện cùng tinh thần ở mức "nhắc".

Xem lý do đầy đủ: `docs/FRICTION-LOG.md` (dòng 2026-07-10, đã chốt) và khối "Đội iOS" trong
`docs/TEST_MATRIX.md`.

## Ai lo nhánh này

- **Agent:** `ios-shell-agent` (`.claude/agents/ios-shell-agent.md`) — chuyên gia vỏ iOS.
- **Skill:** `ios-keyboard-extension` (`.claude/skills/ios-keyboard-extension/`) — cẩm nang
  build extension, ràng buộc sandbox, App Group, Full Access, giới hạn bộ nhớ.
- **Test:** `tests/ios/` (`make test-ios` — hiện no-op tới khi có code).
- **Dùng chung 2 vỏ Apple:** `../shared/` (BrandColors, wrapper `core/mood`, model schema).

`core/engine` + `core/mood` (C++ thuần) dùng chung 100% — vỏ iOS KHÔNG fork logic gõ hay gom câu.
