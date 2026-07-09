# platforms/windows

`win32/` là bản copy **nguyên trạng, chưa rebrand, chưa build trong monorepo này** của vỏ
Windows gốc OpenKey (`OpenKey/Sources/OpenKey/win32/` ở repo `mindful-keyboard`). Mang sang
đây để giữ chỗ trong cấu trúc đa nền tảng — KHÔNG phải bước "port Windows" đã xong.

Còn thiếu trước khi build được:
- Trỏ lại `#include`/project file về `../../core/engine` (đường dẫn cũ trỏ vào
  `Sources/OpenKey/engine` không còn tồn tại ở đây).
- Rebrand chuỗi hiển thị (chưa làm — ngoài phạm vi đợt port macOS-first này).
- Lớp cảm xúc (`MoodWatch.cpp/.h` đã có ở `win32/OpenKey/OpenKey/`) mới là bản **thiết kế
  ban đầu**, chưa đồng bộ với bản macOS đã hoàn thiện hơn (`SendGatekeeperMac`,
  `NudgeCoordinatorMac`, `MoodStoreMac`, `ReflectionScreenMac` — xem `../apple/macos/`).

Theo Hiến chương: chỉ mở lại nhánh Windows sau khi macOS ổn định.
