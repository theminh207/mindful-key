# 03 — Customer Problems (Step 1 · WHY)

> **Pha 2/4 · problem-based-srs Step 1.** Vì sao cần giải pháp (business justification).
> Cú pháp: `[Subject] [must/expects/hopes] [Object] [Penalty]`. Phân loại: **Obligation** (bắt
> buộc, không có thì hỏng) · **Expectation** (kỳ vọng mạnh) · **Hope** (mong đợi). **2026-07-11.**
>
> ⚠️ CP mô tả **vấn đề**, không nhúng giải pháp. "Clone Laban" là giải pháp → không xuất hiện ở đây.

---

## Obligations (bắt buộc — thiếu là sản phẩm không tồn tại đúng nghĩa)

### CP-01 — Gõ tiếng Việt quen tay trên iOS
**Người dùng Việt** *must* có bàn phím gõ Telex/VNI ra dấu chuẩn, mượt, quen tay trong mọi app
iOS — *nếu không* họ không thể dùng nó làm bàn phím mặc định và sẽ quay về Laban/GBoard.
> Loại: Obligation · Chạm: `core/engine` qua bridge.

### CP-02 — Vượt được "cửa ải" bật bàn phím bên thứ ba
**Người dùng mới (không rành kỹ thuật)** *must* bật được bàn phím trong Cài đặt hệ thống và hiểu
quyền Full Access — *nếu không* họ bỏ cuộc ngay ở onboarding (điểm rớt lớn nhất của mọi bàn phím
iOS bên thứ ba).
> Loại: Obligation · Chạm: container onboarding + App Group heartbeat.

### CP-03 — Không bị theo dõi / không lộ nội dung gõ
**Người dùng** *must* tin rằng nội dung họ gõ (kể cả câu nhạy cảm) **không rời khỏi máy**, không
bị gửi đi, không ai đọc — *nếu không* toàn bộ đề xuất "chánh niệm khi gõ" mất niềm tin và phản
tác dụng (một bàn phím đọc cảm xúc mà không riêng tư là mối đe dọa).
> Loại: Obligation · Chạm: on-device 100%, mã hóa nhật ký, minh bạch Full Access.

### CP-04 — Không bị phán xét khi đang yếu lòng
**Người dùng đang căng thẳng/tiêu cực** *must* không bị bàn phím chấm điểm, gắn nhãn đỏ, hay
khiển trách — *nếu không* sản phẩm gây tổn thương đúng lúc người ta dễ tổn thương nhất, phản bội
chính lý do nó tồn tại.
> Loại: Obligation · Chạm: hiến chương M1/M2 (không màu cảm xúc, copy quan sát).

## Expectations (kỳ vọng mạnh — có thì sản phẩm mới "bài bản")

### CP-05 — Một khoảng lặng trước khi gửi lời nóng giận
**Người dùng** *expects* bàn phím nhắc họ *tự nhận ra* khi đang gõ trong trạng thái cảm xúc mạnh —
để có một nhịp dừng tự nguyện — *nếu không* sản phẩm chỉ là bàn phím gõ chữ như bao cái khác, mất
bản sắc chánh niệm.
> Loại: Expectation · Chạm: con sóng `~` ambient trên thanh gợi ý (Phương án A).

### CP-06 — Cá nhân hóa giao diện cho thấy "của mình"
**Người dùng** *expects* chỉnh được giao diện bàn phím (chiều cao, kiểu gõ, tông màu) và thấy
"của mình" — *nếu không* cảm giác xa lạ, khó gắn bó lâu dài.
> Loại: Expectation · Chạm: cài đặt + preview sống + theme trung tính (kế thừa Laban, bỏ game hóa).

### CP-07 — Tự nhìn lại nhịp cảm xúc của mình theo thời gian
**Người dùng** *expects* có nơi riêng tư để tự nhìn lại các khoảnh khắc cảm xúc khi gõ (không phải
thống kê thành tích) — *nếu không* trải nghiệm chánh niệm dừng ở tức thời, không đọng lại thành
sự tự nhận biết.
> Loại: Expectation · Chạm: nhật ký on-device mã hóa + soi lại cuối ngày.

### CP-08 — Một nhịp chuông nhắc chậm lại
**Người dùng** *expects* một tín hiệu nhẹ (âm/cảm giác) như tiếng chuông chánh niệm để chậm lại
giữa lúc gõ dồn dập — *nếu không* mất một kênh nhắc-tỉnh-thức mà macOS đã có (`BellMac`).
> Loại: Expectation · Chạm: tiếng chuông (preset âm và/hoặc nhắc nghỉ định kỳ — Q3 còn mở).

## Hopes (mong đợi — làm được thì tuyệt, không thì vẫn ổn)

### CP-09 — Không thua kém bàn phím thương mại về tiện ích gõ
**Người dùng** *hopes* có vuốt phím + gõ tắt (macro) như Laban — *nếu không* vẫn dùng được nhưng
thấy thiếu so với đối thủ.
> Loại: Hope · Chạm: vuốt phím + macro (ngoài phạm vi đợt này → round sau).

### CP-10 — Đồng bộ giao diện giữa các thiết bị
**Người dùng nhiều thiết bị** *hopes* theme/cài đặt đồng bộ — *nếu không* phải chỉnh lại tay ở mỗi máy.
> Loại: Hope · Chạm: sync theme opt-in (Q9 còn mở; nhật ký cảm xúc tuyệt đối không sync).

---

## Bảng phân loại nhanh
| Loại | CP |
|---|---|
| Obligation | CP-01, CP-02, CP-03, CP-04 |
| Expectation | CP-05, CP-06, CP-07, CP-08 |
| Hope | CP-09, CP-10 |

> Gate check Step 1: ✅ mọi CP dùng cú pháp có Penalty · ✅ đã phân loại · ✅ không nhúng giải pháp.

---
*Step 1/5. Kế tiếp: `04-software-glance.md` (SG — bức phác giải pháp, có Mermaid).*
