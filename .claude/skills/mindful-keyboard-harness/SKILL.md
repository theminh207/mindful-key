---
name: mindful-keyboard-harness
description: "Điều phối viên (orchestrator) của harness dự án mindful-keyboard — quyết định việc mới thuộc về chuyên gia nào trong 4 chuyên gia: engine-agent (bộ não C++/OpenKey, core/engine), mood-layer-agent (lớp cảm xúc/chánh niệm, core/mood), platform-shell-agent (vỏ macOS/Windows/Android/Linux), ios-shell-agent (vỏ iOS — keyboard extension, platforms/apple/ios). PHẢI dùng khi: bắt đầu 1 việc chưa rõ nó thuộc engine hay mood hay platform hay iOS; việc chạm tới từ 2 mảng trở lên (vd sửa engine để mood-layer dùng); kiểm tra/đồng bộ lại harness ('kiểm tra harness', 'harness còn đúng không', 'thêm agent mới'); hoặc build lộ trình đa nền tảng. Với việc RÕ RÀNG chỉ thuộc 1 mảng (ví dụ chỉ sửa 1 dòng trong Vietnamese.cpp), có thể gọi thẳng skill/agent chuyên biệt (openkey-engine, mood-sentiment-layer, platform-porting, ios-keyboard-extension) mà không cần qua đây."
---

# Mindful Keyboard — Harness Orchestrator

## Vì sao harness này tồn tại
Dự án là "1 bộ não (OpenKey fork, GPL v3) + nhiều vỏ OS + 1 lớp cảm xúc trên cùng", lộ trình 5 nền tảng (macOS ① → Windows ② → Android ③ → Linux ④ → iOS ⑤). Các mảng này có ràng buộc kỹ thuật khác hẳn nhau (C++ thuần không đụng OS / on-device ML + privacy / native code từng OS / khuôn sandbox chật của iOS) nên tách thành nhiều chuyên gia thay vì 1 agent ôm hết, tránh lẫn lộn quy tắc (ví dụ: sửa 1 bug riêng iOS nhưng lại đi sửa nhầm vào bộ não `core/` dùng chung).

## Bốn chuyên gia
- **engine-agent** — bộ não C++ thuần (`core/engine`): Telex/VNI, ghép vần, macro, callback dùng chung (`vOnWordCommitted`), giữ xanh `tests/core/test_engine`.
- **mood-layer-agent** — lớp cảm xúc/chánh niệm (`core/mood`): MoodBuffer gom câu, send-risk (0-1), nhật ký, riêng tư dữ liệu cảm xúc.
- **platform-shell-agent** — vỏ **macOS/Windows/Android/Linux** (`platforms/apple/macos`, `platforms/windows`, `platforms/android`, `platforms/linux`): bắt phím native, tray/popup, gác cổng gửi tin (macOS/Windows).
- **ios-shell-agent** — vỏ **iOS** (`platforms/apple/ios`, `tests/ios`): Custom Keyboard Extension, sandbox. Mandate hẹp (chốt 2026-07-10): nhật ký + nhắc thụ động, KHÔNG gác cổng gửi tin (sandbox chặn).

## Chế độ thực thi: SUB-AGENT (không phải Agent Teams)
Plugin `harness` (revfactory/harness) mặc định đề xuất "Agent Teams" (`TeamCreate`/`SendMessage`/`TaskCreate`) cho việc phối hợp real-time giữa các agent. Trong môi trường hiện tại, các primitive đó **không có sẵn như tool có thể gọi**, kể cả khi đã bật cờ `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Vì vậy harness này chạy ở **chế độ sub-agent**: dùng tool `Agent` gọi trực tiếp từng chuyên gia (`subagent_type` = tên agent tương ứng nếu môi trường hỗ trợ custom agent type, hoặc `general-purpose` kèm nội dung file `.claude/agents/{name}.md` làm system prompt nếu không), thu kết quả trả về trực tiếp cho người điều phối chính — không có hội thoại real-time giữa các chuyên gia.

**Truyền dữ liệu giữa các chuyên gia:** dùng file trong `_workspace/` (quy ước tên `{buoc}_{agent}_{noi-dung}.md`) khi 1 chuyên gia cần đọc kết quả của chuyên gia khác, hoặc đơn giản là chuyển tiếp qua người điều phối chính khi tác vụ nhỏ.

## Cổng risk-intake (chạy TRƯỚC khi đụng code — phản xạ, không cần ai gọi)
Trước mọi việc, tự phân loại rủi ro rồi mới quyết cách làm:
- **tiny** — sửa 1–2 dòng, không chạm gì nhạy cảm → làm luôn.
- **normal** — tính năng thường, gọn trong 1 mảng → theo skill/chuyên gia tương ứng.
- **high-risk** — chạm bất kỳ điều nào sau đây → **DỪNG, hỏi chủ dự án trước khi tự quyết:**
  - **Nhận diện:** con sóng `~`/dấu ngã, sắc độ, copy, biên độ (bất khả xâm phạm 2.2/2.3).
  - **Pháp lý:** giấy phép GPL v3, credit Mai Vũ Tuyên (OpenKey).
  - **Riêng tư:** dữ liệu gõ, dữ liệu cảm xúc/mood, nơi lưu, gửi ra ngoài (iOS: Full Access + App Group cũng tính).
  - **Bộ não dùng chung:** sửa `core/engine` hay `core/mood` để vá riêng 1 OS (nguy cơ hỏng mọi OS).

Đây là bản phản xạ hoá của điều hiến chương đã dặn ("chạm nhận diện/pháp lý mà mơ hồ → hỏi chủ dự án").

## Quy trình
1. **Xác định việc thuộc mảng nào** (Phase 1 rút gọn):
   - Đụng `core/engine`, Telex/VNI, macro, callback dùng chung, `tests/core/test_engine` → **engine-agent**
   - Đụng cảm xúc/chánh niệm: `core/mood` (MoodBuffer/MoodWatcher), send-risk, mindful bell, mood journal, model sentiment, riêng tư dữ liệu cảm xúc → **mood-layer-agent**
   - Đụng `platforms/apple/macos`, `platforms/windows`, `platforms/android`, `platforms/linux`, build native app, tray/popup/biểu đồ, gác cổng gửi tin → **platform-shell-agent**
   - Đụng `platforms/apple/ios`, keyboard extension, App Group, Full Access, khung bàn phím iOS, `tests/ios` → **ios-shell-agent**
   - Việc chạm ≥2 mảng (vd: thêm callback mới cho mood layer) → gọi cả 2 chuyên gia liên quan, chuyên gia "chủ" (nơi code thực sự thay đổi) làm trước, chuyên gia phụ thuộc làm sau, dựa trên hợp đồng chuyên gia chủ để lại.
2. **Gọi chuyên gia tương ứng** qua tool `Agent`, đọc file `.claude/agents/{name}.md` để lấy đúng vai trò/nguyên tắc nếu `subagent_type` không tự nhận diện tên agent.
3. **Kiểm tra kết quả:** nếu có sửa `core/`, luôn xác nhận `tests/core/test_engine` vẫn 5/5 (`make test-core`) trước khi báo hoàn thành.
4. **Cập nhật sổ bằng chứng:** khi hoàn thành/đổi một hành vi sản phẩm, cập nhật dòng tương ứng trong `docs/TEST_MATRIX.md` (điền Bằng chứng thật, đừng để `implemented` mà Bằng chứng = none). Trigger tự nhiên: *"soi bằng chứng test"*, *"ma trận test còn đúng không"*, *"cập nhật test matrix"*.
5. **Ghi chỗ phải đoán:** bất cứ khi nào phải suy diễn vì thiếu luật/nguồn sự thật, thêm 1 dòng vào `docs/FRICTION-LOG.md` (cụ thể, không chung chung). Đây là danh sách việc nên chốt/viết luật tiếp theo.
6. **Ghi thay đổi hạ tầng harness** (thêm/bớt agent, đổi kiến trúc) vào bảng "Lịch sử thay đổi" trong `CLAUDE.md` ở phần Harness.

## Khi nào tiến hoá harness
Đề xuất thêm agent mới hoặc đổi kiến trúc khi:
- Cùng một loại phản hồi lặp lại ≥2 lần (ví dụ nhiều lần phải nhắc "đừng sửa `core/` cho lỗi riêng OS").
- Dự án bước sang giai đoạn build app thật (Visual Studio/Xcode) — có thể cần thêm 1 QA agent kiểm tra tích hợp giữa engine/mood/platform trước khi coi 1 tính năng là xong.
- Thêm nền tảng mới có ràng buộc khác hẳn → tách chuyên gia riêng. **Đã làm 2026-07-10:** iOS tách khỏi `platform-shell-agent` thành `ios-shell-agent` (skill `ios-keyboard-extension`) vì sandbox keyboard-extension khác hẳn macOS (không global hook → không gác cổng). Android hiện vẫn do `platform-shell-agent` đảm nhiệm; tách riêng nếu IME Android phình đủ lớn.

## Kịch bản kiểm thử
- **Luồng bình thường:** "thêm callback báo từ mới cho mood layer" → orchestrator xác định đụng cả engine (thêm hook trong `core/engine`) + mood (tiêu thụ hook trong `core/mood`) → gọi engine-agent thêm hook trước, chạy `make test-core` 5/5 → gọi mood-layer-agent tiêu thụ hook.
- **Luồng lỗi:** người dùng báo "gõ trên iOS bị lỗi X" nhưng thực ra do bộ não → ios-shell-agent cô lập bằng smoke test tối thiểu, phát hiện lỗi ở `core/`, chuyển sang engine-agent thay vì tự sửa vỏ.
