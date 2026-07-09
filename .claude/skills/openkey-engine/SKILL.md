---
name: openkey-engine
description: Soi/sửa BỘ NÃO C++ thuần của bộ gõ (OpenKey/Sources/OpenKey/engine/) — Telex/VNI/TCVN3, ghép vần tiếng Việt, macro gõ tắt, và callback word-boundary (vOnWordCommitted). PHẢI dùng khi: đụng vào bất kỳ file trong engine/ (Engine.cpp, Vietnamese.cpp, ConvertTool.cpp, Macro.cpp, SmartSwitchKey.cpp, DataType.h); build/chạy test_engine; gặp lỗi compile portability giữa g++/MSVC/clang; hoặc cần thêm một callback mới dùng chung cho nhiều OS. KHÔNG dùng cho lỗi chỉ xảy ra ở 1 OS cụ thể (win32/, macOS/) — đó là việc của skill platform-porting.
---

# OpenKey Engine

## Bản đồ nhanh
```
engine/          ← BỘ NÃO dùng chung (~3.260 dòng C++ thuần, KHÔNG đụng OS)
├── Engine.cpp        (1558 dòng) — vòng đời xử lý phím, buffer từ đang gõ
├── Vietnamese.cpp    (576)  — luật bỏ dấu, ghép vần tiếng Việt
├── Macro.cpp         (293)  — gõ tắt
├── SmartSwitchKey.cpp (73)  — tự đổi Việt/Anh theo app
├── ConvertTool.cpp   (180)  — đổi bảng mã Unicode/VNI/TCVN3
└── DataType.h         (156) — struct trả kết quả (vKeyHookState)
```
Vỏ (win32/, macOS/, linux/) gọi vào engine qua MỘT cửa duy nhất: `vKeyHandleEvent(...)`. Engine cập nhật `TypingWord[]`/`_index`, điền `pData` (backspaceCount, charData[]) — vỏ đọc `pData` rồi tự gõ ra app.

## Word-boundary — mạch quan trọng nhất
Engine biết chính xác lúc "một từ vừa gõ xong" qua `startNewSession()`. Các điểm gọi:
- `Engine.cpp:1360, 1459, 1476`
- `win32/OpenKey.cpp:368, 413, 639, 690`
- `macOS/OpenKey.mm:214, 493, 541, 783`

Callback dùng chung đã cắm: `vOnWordCommitted` (khai báo trong `Engine.h`, mặc định `nullptr` — không đổi hành vi gõ khi không ai đăng ký nghe). Bắn ngay trước/sau `startNewSession()`, dùng `getCharacterCode()` + `wideStringToUtf8()` để đổi keycode → chữ Unicode thật. Đây là chỗ cắm cho lớp cảm xúc (xem skill `mood-sentiment-layer`).

## Quy trình bắt buộc khi sửa engine/
1. Đọc kỹ đoạn code liên quan trước khi sửa — engine đang chạy thật và ổn định, không "cải tiến" khi không được yêu cầu.
2. Sau khi sửa, LUÔN chạy:
   ```bash
   bash prototype/build.sh
   ./prototype/test_engine
   ```
   Kỳ vọng: gõ Telex→Unicode 5/5. Dưới 5/5 = regression, phải sửa lại hoặc revert trước khi coi là xong.
3. Nếu thêm callback/hook mới, đảm bảo mặc định là no-op (không đăng ký = không đổi hành vi).

## Lỗi portability đã gặp (mẫu để nhận diện lỗi tương tự)
`ConvertTool.cpp` từng thiếu `#include <algorithm>` — biên dịch OK trên Windows/Mac (compiler include ké qua header khác) nhưng g++/Linux (WSL) bắt lỗi vì include chuẩn hơn. Khi gặp lỗi kiểu "compiler A build được, compiler B báo thiếu symbol chuẩn", nghi ngờ đầu tiên là thiếu `#include` tường minh — thêm include, đừng tái cấu trúc code.
