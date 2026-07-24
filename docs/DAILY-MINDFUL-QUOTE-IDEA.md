# Ý tưởng: Câu dẫn nhắc tâm hằng ngày (tab "Hôm nay")

> 🟡 **Ý TƯỞNG — CHƯA CODE.** Ghi lại từ 2 ảnh chủ dự án gửi 2026-07-24. Chưa vào `epics.md`/
> `sprint-status.yaml` — vào đó mới thành lệnh thi công.

## Nguồn

- **Ảnh 1** — ảnh chụp màn hình **app KHÁC** (không phải mindful-key): 1 câu check-in xong hiện
  dòng "✅ Check-in thành công! 💡 Tự tin vào năng lực và giá trị của bản thân, bạn chính là người
  thuyền trưởng xuất sắc nhất dẫn dắt công việc của mình". Đưa vào làm **tham khảo bố cục** (làm 1
  hành động → hiện 1 câu dẫn ngay sau đó), không phải để chép nguyên giọng văn (xem cảnh báo dưới).
- **Ảnh 2** — mockup tab "Hôm nay" của cửa sổ Cài đặt mindful-key, khoanh đỏ 3 chỗ:
  1. Một khối **"Câu dẫn nhắc tâm"** nằm cạnh dòng quan sát hiện có ("Sáng và tối có gợn").
  2. Cơ chế: **mỗi ngày chạy 1 câu dẫn, chọn ngẫu nhiên** (random) từ một danh sách.
  3. Một mục trong Cài đặt để **thiết lập/quản lý các câu nhắc tâm**.

## Ý tưởng tính năng

Thêm 1 câu dẫn (lead-in sentence) ngắn trên tab "Hôm nay", đổi mới mỗi ngày, chọn ngẫu nhiên từ
một danh sách câu do (ban đầu) sản phẩm soạn sẵn — và chủ dự án/người dùng có thể tự thêm/sửa/xoá
câu trong danh sách đó qua 1 mục Cài đặt riêng.

## ⚠️ Cảnh báo chạm hiến chương — cần chốt trước khi soạn câu

Ảnh 1 dùng **emoji chấm điểm** (✅💡) và **giọng khen ngợi trực tiếp thành tích** ("bạn chính là
người thuyền trưởng xuất sắc nhất"). Cả hai đều rơi đúng vào điều bất khả xâm phạm của
`docs/AGENT-BRIEF.md` §2.2: **không emoji chấm điểm · không copy khen ngợi/khiển trách** — nhận
diện phải là "quan sát không phán xét" (như "Mặt hồ đang gợn sóng").

→ Nếu làm tính năng này, câu dẫn **không được** viết theo giọng ảnh 1. Phải viết theo giọng quan
sát trung tính sẵn có trong app (kiểu "Mặt hồ đang gợn sóng", không khen/không chấm điểm), và
**không kèm emoji**.

## Việc chưa quyết (hỏi chủ dự án trước khi lên story)

| # | Câu hỏi |
|---|---|
| 1 | Câu dẫn thay hẳn dòng quan sát hiện có, hay thêm 1 khối riêng bên cạnh? |
| 2 | Bộ câu dẫn ban đầu: soạn sẵn bao nhiêu câu, ai viết (để không lệch giọng "quan sát không phán xét")? |
| 3 | Đổi câu: đúng 1 câu/ngày cố định (rồi hôm sau mới đổi), hay đổi mỗi lần mở Cài đặt? |
| 4 | Mục "thiết lập câu nhắc tâm" cho tự soạn tự do, hay chỉ bật/tắt từng câu trong bộ có sẵn? |
| 5 | Làm ở macOS trước rồi Windows sau (nếp cũ của dự án), hay song song 2 vỏ? |

## Định tuyến khi thi công (chưa chạy)

Đây là UI hiển thị + nhật ký nhẹ (câu đang hiện hôm nay, danh sách câu) → thuộc `platform-shell-agent`
(vỏ macOS/Windows). Nếu câu dẫn cần đồng bộ qua nhiều vỏ hoặc cần cơ chế chọn ngẫu nhiên "không lặp
liên tiếp" phức tạp hơn, cân nhắc chỗ ở `core/` để 2 vỏ dùng chung thay vì mỗi vỏ tự viết random
riêng — nhưng đây chỉ là gợi ý, chưa khảo sát kỹ.
