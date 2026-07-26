# ADR-0008 — Sàn hệ điều hành macOS 13.0

- **Trạng thái:** Đã chốt
- **Ngày:** 2026-07-18
- **Liên quan:** `../tasks/FRICTION-LOG.md` 2026-07-18

## Bối cảnh

Cấu hình dự án khai `LSMinimumSystemVersion` là **10.15**. Nhưng chưa có máy nào cũ hơn 14.8.3 được
dùng để kiểm thử, nên con số 10.15 là một **lời hứa suông** — không ai biết ứng dụng có chạy trên đó
hay không.

Thêm vào đó, tính năng "Bật cùng hệ thống" dùng `SMAppService`, vốn cần macOS 13 trở lên. Dưới 13
tính năng này **vốn đã chết sẵn** và không có đường thay thế nào được cài.

Quét mã nguồn không thấy API nào gọi vượt trần, nên đây là rủi ro chứ chưa phải lỗi đã xảy ra.

## Quyết định

Nâng `LSMinimumSystemVersion` lên **13.0**, khai đúng thứ đã kiểm được thay vì thứ mong muốn.

## Đánh đổi đã chấp nhận

Mất người dùng trên macOS từ 10.15 tới 12.x. Con số thực tế không rõ vì dự án chưa có người dùng
diện rộng.

Chấp nhận vì lựa chọn kia tệ hơn theo cách khó phát hiện: giữ 10.15 nghĩa là ứng dụng **cài được**
trên máy cũ rồi hỏng ở đâu đó không đoán trước, thay vì từ chối cài một cách rõ ràng.

## Hệ quả

- Con số sàn hệ điều hành là một **cam kết đã kiểm chứng**, không phải một mong muốn. Muốn hạ xuống
  thì phải có một lần chạy thật trên phiên bản đó.
- Vẫn còn nợ: **chưa test trên máy macOS 13.x thật**. Muốn chắc thì cần một lần chạy trên Ventura
  hoặc máy ảo.
- Quyết định này được ghi lại vì nó do agent đề xuất thay chủ dự án trong lúc xử lý một báo cáo lỗi —
  đúng loại quyết định phải để lại vết, không được lẫn vào một commit sửa lỗi.
