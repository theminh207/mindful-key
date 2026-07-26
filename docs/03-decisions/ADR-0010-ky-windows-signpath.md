# ADR-0010 — Ký Windows qua SignPath Foundation

- **Trạng thái:** Đã chốt
- **Ngày:** 2026-07-18
- **Liên quan:** `../tasks/WINDOWS-CODE-SIGNING.md`, `../tasks/CODE-SIGNING-POLICY.md`

## Bối cảnh

Bộ cài Windows không ký số sẽ bị SmartScreen chặn với cảnh báo nhà phát hành không xác định — đủ để
phần lớn người dùng bỏ cuộc ngay ở bước cài.

Hai đường để có chữ ký:

- **SignPath Foundation** — miễn phí cho dự án mã nguồn mở.
- **Chứng chỉ EV** — khoảng 400 tới 600 đô một năm, kèm yêu cầu HSM cho CI.

## Quyết định

Đi đường **SignPath Foundation**.

## Đánh đổi đã chấp nhận

Dòng nhà phát hành mà SmartScreen hiện lúc cài sẽ là **"SignPath Foundation"**, không phải tên chủ dự
án. Người dùng nhìn thấy tên một tổ chức lạ thay vì tên tác giả.

Chấp nhận vì ở giai đoạn này, việc **có chữ ký hợp lệ** quan trọng hơn việc chữ ký đó mang tên ai.
Đường EV để ngỏ, chưa chọn.

## Hệ quả

- Tệp `CODE-SIGNING-POLICY.md` là tài liệu **công khai** theo yêu cầu của chương trình SignPath.
  Không sửa nội dung nếu chưa đối chiếu lại điều kiện của họ.
- Dự án phải giữ trạng thái mã nguồn mở để tiếp tục đủ điều kiện — trùng hướng với ràng buộc GPL v3
  tại [ADR-0001](ADR-0001-gpl-v3.md).
- Nếu về sau muốn hiện tên chủ dự án trên SmartScreen thì phải mua EV, và khi đó cần giải quyết cả
  bài toán lưu khóa trên HSM cho CI.
