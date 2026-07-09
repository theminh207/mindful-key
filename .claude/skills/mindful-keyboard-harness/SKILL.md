---
name: mindful-keyboard-harness
description: "Điều phối viên (orchestrator) của harness dự án mindful-keyboard — quyết định việc mới thuộc về chuyên gia nào trong 3 chuyên gia: engine-agent (bộ não C++/OpenKey), mood-layer-agent (lớp cảm xúc/chánh niệm), platform-shell-agent (vỏ Windows/macOS/Android/iOS). PHẢI dùng khi: bắt đầu 1 việc chưa rõ nó thuộc engine hay mood hay platform; việc chạm tới từ 2 mảng trở lên (vd sửa engine để mood-layer dùng); kiểm tra/đồng bộ lại harness ('kiểm tra harness', 'harness còn đúng không', 'thêm agent mới'); hoặc build lộ trình MVP Windows. Với việc RÕ RÀNG chỉ thuộc 1 mảng (ví dụ chỉ sửa 1 dòng trong Vietnamese.cpp), có thể gọi thẳng skill/agent chuyên biệt (openkey-engine, mood-sentiment-layer, platform-porting) mà không cần qua đây."
---

# Mindful Keyboard — Harness Orchestrator

## Vì sao harness này tồn tại
Dự án là "1 bộ não (OpenKey fork, GPL v3) + nhiều vỏ OS + 1 lớp cảm xúc trên cùng", lộ trình 4 nền tảng (Windows → macOS → Android → iPhone). Ba mảng này có ràng buộc kỹ thuật khác hẳn nhau (C++ thuần không đụng OS / on-device ML + privacy / native code từng OS) nên tách thành 3 chuyên gia thay vì 1 agent ôm hết, tránh lẫn lộn quy tắc (ví dụ: sửa 1 bug riêng Windows nhưng lại đi sửa nhầm vào engine dùng chung).

## Chế độ thực thi: SUB-AGENT (không phải Agent Teams)
Plugin `harness` (revfactory/harness) mặc định đề xuất "Agent Teams" (`TeamCreate`/`SendMessage`/`TaskCreate`) cho việc phối hợp real-time giữa các agent. Trong môi trường hiện tại, các primitive đó **không có sẵn như tool có thể gọi**, kể cả khi đã bật cờ `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Vì vậy harness này chạy ở **chế độ sub-agent**: dùng tool `Agent` gọi trực tiếp từng chuyên gia (`subagent_type` = tên agent tương ứng nếu môi trường hỗ trợ custom agent type, hoặc `general-purpose` kèm nội dung file `.claude/agents/{name}.md` làm system prompt nếu không), thu kết quả trả về trực tiếp cho người điều phối chính — không có hội thoại real-time giữa các chuyên gia.

**Truyền dữ liệu giữa các chuyên gia:** dùng file trong `_workspace/` (quy ước tên `{buoc}_{agent}_{noi-dung}.md`) khi 1 chuyên gia cần đọc kết quả của chuyên gia khác, hoặc đơn giản là chuyển tiếp qua người điều phối chính khi tác vụ nhỏ.

## Quy trình
1. **Xác định việc thuộc mảng nào** (Phase 1 rút gọn):
   - Đụng `OpenKey/Sources/OpenKey/engine/`, Telex/VNI, macro, callback dùng chung, `test_engine` → **engine-agent**
   - Đụng cảm xúc/chánh niệm: MoodBuffer/MoodWatcher, `mood_log.csv`, mindful bell, mood journal, model sentiment, riêng tư dữ liệu cảm xúc → **mood-layer-agent**
   - Đụng `win32/`, `macOS/`, build native app, tray/popup/biểu đồ, lộ trình OS → **platform-shell-agent**
   - Việc chạm ≥2 mảng (vd: thêm callback mới cho mood layer) → gọi cả 2 chuyên gia liên quan, chuyên gia "chủ" (nơi code thực sự thay đổi) làm trước, chuyên gia phụ thuộc làm sau, dựa trên hợp đồng chuyên gia chủ để lại.
2. **Gọi chuyên gia tương ứng** qua tool `Agent`, đọc file `.claude/agents/{name}.md` để lấy đúng vai trò/nguyên tắc nếu `subagent_type` không tự nhận diện tên agent.
3. **Kiểm tra kết quả:** nếu có sửa engine/, luôn xác nhận `test_engine` vẫn 5/5 trước khi báo hoàn thành.
4. **Ghi thay đổi hạ tầng harness** (thêm/bớt agent, đổi kiến trúc) vào bảng "Lịch sử thay đổi" trong `CLAUDE.md` ở phần Harness.

## Khi nào tiến hoá harness
Đề xuất thêm agent mới hoặc đổi kiến trúc khi:
- Cùng một loại phản hồi lặp lại ≥2 lần (ví dụ nhiều lần phải nhắc "đừng sửa engine cho lỗi riêng OS").
- Dự án bước sang giai đoạn build app thật (Visual Studio/Xcode) — có thể cần thêm 1 QA agent kiểm tra tích hợp giữa engine/mood/platform trước khi coi 1 tính năng là xong.
- Thêm nền tảng mới (Android/iOS) — platform-shell-agent vẫn đảm nhiệm được, nhưng skill `platform-porting` cần bổ sung phần riêng cho nền đó.

## Kịch bản kiểm thử
- **Luồng bình thường:** "thêm callback báo từ mới cho mood layer" → orchestrator xác định đụng cả engine (thêm hook) + mood (tiêu thụ hook) → gọi engine-agent thêm hook trước, chạy test_engine 5/5 → gọi mood-layer-agent tiêu thụ hook.
- **Luồng lỗi:** người dùng báo "gõ trên Mac bị lỗi X" nhưng thực ra do bộ não → platform-shell-agent cô lập bằng demo tối thiểu, phát hiện lỗi ở engine/, chuyển sang engine-agent thay vì tự sửa vỏ.
