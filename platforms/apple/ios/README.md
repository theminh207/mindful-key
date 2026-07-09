# apple/ios

Chưa mở. Theo lộ trình nền tảng (AGENT-BRIEF §4 + `docs/OPENKEY-MAP.md`), iOS làm SAU CÙNG —
khuôn chật nhất của Apple: không có low-level keyboard hook toàn cục như macOS (CGEventTap),
nên "gác cổng gửi tin" (Feature #1) không thể làm y hệt bản macOS — cần thiết kế lại qua
Custom Keyboard Extension (App Extension riêng, sandbox nghiêm ngặt hơn, không có Full Access
mặc định, hạn chế truy cập mạng/microphone khi bật Full Access).

Không bắt đầu nhánh này trước khi macOS ổn định (Hiến chương: "macOS là công dân hạng nhất").
