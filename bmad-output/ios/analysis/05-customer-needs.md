# 05 — Customer Needs (Step 3 · WHAT)

> **Pha 2/4 · problem-based-srs Step 3.** Kết quả (outcome) phần mềm phải mang lại.
> Cú pháp: `[Subject] needs [system] to [Verb] [Object] [Condition]`. Lớp outcome:
> **Information** (cho biết) · **Control** (điều khiển) · **Construction** (tạo/lưu) ·
> **Entertainment** (trải nghiệm). Mỗi CP có ≥1 CN. **2026-07-11.**

---

## CN theo Customer Problem

### CN-01 ← CP-01 — Gõ Telex/VNI ra dấu
Người dùng needs hệ thống **hiển thị** đúng ký tự tiếng Việt có dấu khi gõ Telex/VNI trong mọi ô
nhập của app host, chạy qua `core/engine` nguyên vẹn.
> Lớp: Information · Điều kiện: mọi app; "vieetj"→"việt"; không lệch giữa Notes và Zalo.

### CN-02 ← CP-01 — Điều khiển bàn phím (Shift/số/xoá/đổi bàn phím)
Người dùng needs hệ thống **cho phép điều khiển** Shift/Caps, lớp số & ký hiệu, xóa lùi, và chuyển
bàn phím (🌐), như một bàn phím iOS chuẩn.
> Lớp: Control · Điều kiện: hit area ≥ 44pt, phản hồi < ~80ms.

### CN-03 ← CP-02 — Dẫn kích hoạt bàn phím
Người dùng mới needs hệ thống **hướng dẫn** bật bàn phím trong Cài đặt hệ thống theo bước đánh số +
coach-mark 🌐 + fallback khi không thấy.
> Lớp: Information · Điều kiện: giọng bình thản khi vướng, không quở trách.

### CN-04 ← CP-02, CP-03 — Minh bạch & kiểm soát Full Access
Người dùng needs hệ thống **giải thích rõ** Full Access dùng làm gì (đọc câu vừa gõ, on-device, cho
con sóng) **trước khi** iOS hỏi, và **cho phép "Để sau"**.
> Lớp: Information + Control · Điều kiện: dùng cặp biên độ (sóng "bật lên để" / đường phẳng "không bao giờ"), nghĩa nằm ở nhãn chữ.

### CN-05 ← CP-02 — Biết bàn phím đã kích hoạt (đoán)
Người dùng needs hệ thống **cho biết** trạng thái "bàn phím đã từng chạy" khi quay lại container.
> Lớp: Information · Điều kiện: qua App Group heartbeat; thành thật không phát hiện được lúc TẮT.

### CN-06 ← CP-03 — Giữ nội dung gõ trên máy
Người dùng needs hệ thống **đảm bảo** nội dung gõ không rời máy: không gửi mạng, ô mật khẩu không
đọc/log/hiện sóng, dữ liệu vận hành (heartbeat) không chứa nội dung gõ.
> Lớp: Construction (bảo toàn) · Điều kiện: on-device 100%; secure field bị loại tuyệt đối.

### CN-07 ← CP-04, CP-05 — Quan sát cảm xúc bằng con sóng, không phán xét
Người dùng needs hệ thống **phản chiếu** trạng thái cảm xúc câu đang gõ bằng con sóng `~` biến hình
theo biên độ trên thanh gợi ý — trung tính, ambient, KHÔNG chặn, KHÔNG màu cảnh báo.
> Lớp: Information · Điều kiện: cần Full Access; qua bài kiểm "mô tả không phán xét"; Reduce Motion → sóng đứng yên ở biên độ tương ứng.

### CN-08 ← CP-08 — Một nhịp chuông chậm lại
Người dùng needs hệ thống **phát** một tín hiệu nhẹ (tiếng chuông chánh niệm) như một điểm dừng —
qua preset âm khi gõ và/hoặc chuông nhắc nghỉ (nghĩa cụ thể chờ Q3).
> Lớp: Entertainment/Information · Điều kiện: tùy chọn bật/tắt; không dồn dập.

### CN-09 ← CP-06 — Cá nhân hóa bàn phím với preview sống
Người dùng needs hệ thống **cho phép chỉnh** chiều cao, kiểu gõ (Telex/VNI), và tông theme trung
tính, **thấy kết quả ngay** trên preview sống.
> Lớp: Control + Construction · Điều kiện: kế thừa preview/slider Laban; theme chỉ tông trung tính, KHÔNG game hóa.

### CN-10 ← CP-07 — Nhật ký cảm xúc riêng tư
Người dùng needs hệ thống **lưu và trình bày** các khoảnh khắc cảm xúc khi gõ dưới dạng nhật ký
on-device mã hóa, **câu phản chiếu là trọng tâm**, số liệu chỉ là bối cảnh phụ.
> Lớp: Construction + Information · Điều kiện: consent 1 lần; có nút xóa tất cả; KHÔNG biểu đồ/streak/điểm.

### CN-11 ← CP-07 — Soi lại cuối ngày
Người dùng needs hệ thống **gợi mở** một câu hỏi phản chiếu cuối ngày (màn hoặc thông báo nhẹ),
giọng quan sát, không tổng kết thành tích.
> Lớp: Information · Điều kiện: cân với "không hối thúc" nếu là notification (Q6).

### CN-12 ← CP-09 — Tiện ích gõ nâng cao (round sau)
Người dùng needs hệ thống **hỗ trợ** vuốt phím + gõ tắt (macro) như bàn phím thương mại.
> Lớp: Control · Điều kiện: NGOÀI phạm vi đợt này — ghi để không rơi.

### CN-13 ← CP-10 — Đồng bộ giao diện (round xa, opt-in)
Người dùng nhiều máy needs hệ thống **đồng bộ** theme/cài đặt (opt-in), **tuyệt đối không** đồng bộ nhật ký cảm xúc.
> Lớp: Control · Điều kiện: opt-in mặc định OFF; nhật ký không rời máy (M3).

---

## Zigzag Validation — CP → CN (BẮT BUỘC sau Step 3)

| CP | Có CN phục vụ? | CN |
|---|---|---|
| CP-01 Gõ Việt quen tay | ✅ | CN-01, CN-02 |
| CP-02 Vượt cửa kích hoạt | ✅ | CN-03, CN-04, CN-05 |
| CP-03 Không lộ nội dung | ✅ | CN-04, CN-06 |
| CP-04 Không bị phán xét | ✅ | CN-07 |
| CP-05 Khoảng lặng trước khi gửi | ✅ | CN-07 |
| CP-06 Cá nhân hóa | ✅ | CN-09 |
| CP-07 Tự nhìn lại | ✅ | CN-10, CN-11 |
| CP-08 Nhịp chuông | ✅ | CN-08 |
| CP-09 Tiện ích nâng cao | ✅ | CN-12 |
| CP-10 Đồng bộ | ✅ | CN-13 |

**Kết quả zigzag:** ✅ **0 CP mồ côi** — mọi CP có ≥1 CN. ✅ mọi CN truy ngược về ≥1 CP. Không có CN "trên trời" không gắn vấn đề nào.

---
*Step 3/5. Zigzag PASS. Kế tiếp: `06-software-vision.md` (SV — có Mermaid).*
