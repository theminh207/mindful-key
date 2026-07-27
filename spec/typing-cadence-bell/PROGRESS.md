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

## 2026-07-27 — #3 ADR: đo nhịp gõ thay cho đọc cảm xúc

**Làm gì:** Viết `ADR-0013` (đo nhịp gõ thay đọc cảm xúc) và `ADR-0014` (mandate iOS hẹp, lý lẽ
mới). Đánh dấu **năm** ADR là *Bị thay thế bởi 0013*: 0003, 0004, 0005, 0006 và **0011**. Gỡ hẳn
`ADR-0009`. Cập nhật bảng mục lục `docs/03-decisions/README.md`, gỡ dòng ghi chú tạm ở
`docs/01-intent.md` §6, trỏ lại hai liên kết ADR-0009 đã chết ở `01-intent.md` và `02-features.md`.

**Chốt được:**
- **Q1 — ngưỡng.** Bốn mức, mặc định **Rất nhanh = 400 CPM**: `Nhanh 300` · `Rất nhanh 400` ·
  `Cực nhanh 500` · `Tắt chuông`. Tên mức mô tả nhịp tay, không mô tả tâm người gõ; hiển thị luôn
  kèm con số CPM.
- **Q2 — cửa sổ trượt 30 giây.** Ngắn hơn thì một tràng gõ dồn rồi nghỉ cũng vượt ngưỡng; dài hơn
  thì chuông tới sau khi nhịp đã lắng.
- **ADR-0009 gỡ hẳn, không đánh dấu bị thay thế.** Thân nó lập luận cho gác cổng gửi tin — tính năng
  đã bị xoá khỏi sản phẩm, để lại thì người đọc sau phải đọc hết mới biết nó đã chết. Kết luận
  (mandate iOS hẹp) viết lại ở `ADR-0014`. Ngoại lệ này có mục giải thích + lệnh `git show` để đọc
  lại bản gốc ngay trong index; **không phải tiền lệ**.
- **ADR-0011 vào danh sách bị thay thế**, dù issue #3 không liệt kê. Nó chốt schema "bất biến" có
  cột `send_risk` — cột chết theo mô hình mới. Để nguyên thì #16 sẽ trích một ADR đã sai làm căn cứ.

**Phải đoán:** không. Bốn điểm mơ hồ (Q1, Q2, cách xử lý ADR-0009, phạm vi ADR-0011) đã hỏi chủ dự
án và được chốt trước khi viết.

**Kiểm chứng:** brand-lint — `✅ 223 file, 0 vi phạm cứng, 9 cảnh báo` (cả 9 là hardcode màu có sẵn
trong `BrandColors.h`, PR này không đụng tới). Hai vướng trên máy Windows, **không phải lỗi do PR
này**: `make` không có trong shell, và `scripts/brand-lint.sh` gọi `python3` (không tồn tại trên
Windows). Chạy được bằng `PYTHONIOENCODING=utf-8 py -3 scripts/brand_lint.py` — thiếu biến môi
trường thì script chết vì console cp1252 không in nổi ký tự `⚠️`.

Lưu ý cho lần sau: `scripts/brand_lint.py` chỉ quét
`platforms/`, `site/`, `brand/` với đuôi file UI, **không quét `.md`** — nên với PR thuần tài liệu,
cổng này xanh không có nghĩa là câu chữ đã được máy kiểm. Tên bốn mức ở trên là **đọc tay** theo
HIẾN CHƯƠNG §2.2/2.3.

**Còn hở:**
- `docs/02-features.md` còn câu "iOS không có gác cổng là quyết định" — viết theo mô hình cũ. PR này
  chỉ trỏ lại liên kết cho khỏi chết, phần câu chữ thuộc **#4**.
- Schema kho nhật ký sau khi mất `send_risk` chốt ở **#11**.
- Công thức quy CPM → biên độ sóng vẫn mở (Q4, ở #8).

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
