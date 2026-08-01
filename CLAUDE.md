# CLAUDE.md — mindful-key

Kỷ luật coding cho dự án **mindful-key** — bộ gõ Tiếng Việt chánh niệm (fork OpenKey), stack **C++ (bộ não) + Objective-C/++ (vỏ macOS)**. File này lo *cách viết code cho kỷ luật*.

> ⚖️ **Luật tối cao = HIẾN CHƯƠNG**, không phải file này. Mọi quyết định chạm **NHẬN DIỆN / PHÁP LÝ / RIÊNG TƯ** phải quy chiếu `docs/01-intent.md` TRƯỚC. Bất khả xâm phạm: KHÔNG đèn đỏ/xanh cảm xúc · KHÔNG emoji chấm điểm · KHÔNG gamification (streak/điểm/huy hiệu) · KHÔNG copy khiển trách — nhận diện là con sóng `~` trung tính, "mô tả không phán xét". GPL v3, giữ credit Mai Vũ Tuyên. Mơ hồ → **hỏi chủ dự án**.

## User Profile
- Solo developer. Communicates in Vietnamese (casual). Technical terms in English.
- Vibe coder — designs architecture with systems thinking, AI writes the code.
- Prefers explanations with real-world analogies, not dry textbook style.

---

## Nơi làm việc theo feature — `spec/<feature-name>/`

Feature lớn kéo dài nhiều session có một thư mục riêng ở `spec/`, là **nơi làm việc chung** của cả người lẫn agent: `README.md` giữ kế hoạch + bảng tiến độ + quyết định đã chốt/còn mở, `PROGRESS.md` là nhật ký theo ngày.

- Bắt đầu một việc thuộc feature đang chạy → **đọc `spec/<feature>/README.md` TRƯỚC**, để khỏi hỏi lại thứ đã chốt.
- Đóng một issue → cập nhật bảng tiến độ + ghi một mục vào `PROGRESS.md`, **cùng trong PR đó**, không để dồn.
- Đang chạy: `spec/typing-cadence-bell/` — chuyển từ đọc cảm xúc sang đo nhịp gõ (issue #3 → #18).

---

## Harness (điều phối agent)

**Mô hình "1 bộ não + nhiều vỏ + 1 lớp đo nhịp gõ" chia thành 4 chuyên gia** (chạy chế độ sub-agent, không phải Agent Teams — xem `.claude/skills/mindful-keyboard-harness/SKILL.md`):

| Chuyên gia | Mảng | Sở hữu | Skill chuyên biệt |
|---|---|---|---|
| `engine-agent` | Bộ não C++ dùng chung | `core/engine`, `tests/core` | `openkey-engine` |
| `mood-layer-agent` | Lớp đo nhịp gõ + chuông tỉnh thức | `core/mood` | `typing-cadence-layer` |
| `platform-shell-agent` | Vỏ macOS/Windows/Android/Linux | `platforms/{apple/macos,windows,android,linux}` | `platform-porting` |
| `ios-shell-agent` | Vỏ iOS (keyboard extension) | `platforms/apple/ios`, `tests/ios` | `ios-keyboard-extension` |

Việc chưa rõ thuộc mảng nào, hoặc chạm ≥2 mảng → qua orchestrator `mindful-keyboard-harness`. Việc rõ 1 mảng → gọi thẳng skill/agent tương ứng. Hai sổ đi kèm harness: `docs/tasks/TEST_MATRIX.md` (bằng chứng hành vi) + `docs/tasks/FRICTION-LOG.md` (chỗ AI phải đoán).

### Lịch sử thay đổi harness

Thêm/bớt agent hoặc đổi kiến trúc thì ghi một hàng ở đây (luật: `mindful-keyboard-harness/SKILL.md` bước 6).

| Ngày | Thay đổi | Vì sao |
|---|---|---|
| 2026-08-01 | Skill `mood-sentiment-layer` → **`typing-cadence-layer`**; `mood-layer-agent` đổi mandate từ "lớp cảm xúc" sang "lớp đo nhịp gõ + chuông tỉnh thức" | Sản phẩm bỏ đọc cảm xúc, chuyển sang đo tốc độ gõ ([ADR-0013](docs/03-decisions/ADR-0013-do-nhip-go-thay-doc-cam-xuc.md)). Mandate cũ dạy xây `MoodBuffer` + model sentiment + popup cảnh báo — **đã mất hiệu lực toàn bộ**; không sửa thì agent sẽ tiếp tục sinh code send-risk dù hiến chương đã đổi. Chốt ở issue #5 |
| 2026-07-10 | Tách `ios-shell-agent` khỏi `platform-shell-agent` (kèm skill `ios-keyboard-extension`) | Sandbox keyboard-extension của iOS khác hẳn macOS: không có global hook, không thấy nút gửi của app chủ |
