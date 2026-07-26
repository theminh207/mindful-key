# Nhật ký tiến độ — Typing Cadence Bell

> Mới nhất ở trên cùng. Mỗi issue đóng lại = một mục ở đây, ghi **cùng trong PR đó**, đừng để dồn.
> Kế hoạch và bảng trạng thái ở [README.md](README.md).

**Mẫu một mục:**

```
## YYYY-MM-DD — #<issue> <tiêu đề ngắn>

**Làm gì:** 1-2 câu, nói việc thật đã thay đổi, không chép lại mô tả issue.
**Chốt được:** quyết định nào đã ngã ngũ + lý do (chuyển luôn xuống mục "Đã chốt" ở README §5).
**Phải đoán:** chỗ nào tài liệu không nói rõ mà vẫn phải chọn (ghi thêm vào docs/tasks/FRICTION-LOG.md).
**Kiểm chứng:** make test / make build / brand-lint / thử tay ra sao.
**Còn hở:** thứ cố ý để lại cho issue sau, kèm số issue.
```

---

## 2026-07-26 — Khởi động: hiến chương đổi mô hình lõi

**Làm gì:** Sửa `docs/01-intent.md` — bỏ **Sense** (đọc cảm xúc từ nội dung) và **Pause** (gác cổng
nút gửi), thay bằng vòng lặp `Measure → Bell → Reflect`: đo tốc độ gõ bằng CPM, vượt ngưỡng người
dùng đặt thì ngân chuông, ghi lại số lần chuông cho màn soi lại.

Đụng tới: §1 lý do tồn tại · §3 vòng lặp lõi · §4.2 riêng tư · §4.3 ma sát mềm · §5 non-goals ·
§6 mandate iOS · §7 thế nào là đủ tốt.

**Chốt được:**
- Bỏ **hẳn** lớp sentiment, không giữ lại để ghi nhật ký.
- Đơn vị đo là **CPM (ký tự/phút)**, không phải WPM — Telex/VNI gõ dấu tốn thêm phím nên đếm "từ" bị méo.
- Bỏ cột `appBundleID` khỏi kho local: mô hình mới không còn allow-list app chat nên tên ứng dụng mất
  lý do tồn tại. Kho còn đúng ba thứ: thời điểm chuông · tốc độ lúc đó · ngưỡng đang đặt.

**Phải đoán:** không. Hai điểm mơ hồ (bỏ hẳn sentiment hay giữ; CPM hay WPM) đã hỏi chủ dự án trước
khi sửa.

**Kiểm chứng:** chỉ sửa tài liệu, chưa đụng code. `make` chưa chạy được trên máy Windows của chủ dự
án (không có `make` trong shell) — cổng chất lượng sẽ chạy ở issue đầu tiên có code.

**Còn hở:** gần nửa tủ tài liệu và toàn bộ code vẫn theo mô hình cũ. Đã tách thành 16 issue
(#3 → #18) chia 6 phase, xem README §4.

---

## 2026-07-26 — Dựng kế hoạch + 16 issue

**Làm gì:** Khảo sát code thật để chia phase (không đoán): đường ống hiện tại là
`MoodBuffer → SendRiskAnalyzer → MoodWatch → NudgeCoordinator → Bell → MoodStore → ReflectionScreen`,
cộng nhánh gác cổng `BreathingPause → SendGatekeeper`. Phát hiện quan trọng: **chuông, kho, con sóng,
màn cài đặt đều dùng lại được** — chỉ thay đoạn ống đầu nguồn, nên đây không phải viết lại từ đầu.

Tạo 16 issue (#3 → #18), 6 milestone theo phase, label `area:core/macos/windows/ios/docs` +
`removal`. Mỗi issue có bối cảnh, checklist, file cụ thể, cổng chất lượng, và dòng "chặn bởi #x".

**Chốt được:** thứ tự phase — luật (docs) trước, bộ não sau, macOS chạy thật, rồi mới gỡ đồ cũ và
port sang Windows/iOS. Gỡ `SendRiskAnalyzer` phải đợi cả 3 vỏ chuyển xong, gỡ sớm là vỡ build.

**Phải đoán:** không có. Mọi tham chiếu file trong issue đều đã kiểm tồn tại trước khi viết.

**Kiểm chứng:** `gh issue list` — đủ 16 issue, đúng milestone.

**Còn hở:** 8 câu hỏi mở chưa chốt, xem README §5. Hai cái chặn đường nhất: ngưỡng CPM mặc định (Q1)
và nhịp phím lấy ở đâu (Q3).
