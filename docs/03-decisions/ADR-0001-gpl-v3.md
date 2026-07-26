# ADR-0001 — Giấy phép GPL v3 kế thừa từ OpenKey

- **Trạng thái:** Đã chốt
- **Ngày:** 2026-07-08
- **Liên quan:** [tầng Intent §4.4](../01-intent.md), `../tasks/AGENT-BRIEF.md` §6

## Bối cảnh

Dự án fork lõi xử lý tiếng Việt từ OpenKey của Mai Vũ Tuyên. Giấy phép của dự án gốc phải được xác
định **trước dòng kế thừa đầu tiên**, vì nó quyết định luôn giấy phép của sản phẩm phái sinh.

Kết quả xác minh: OpenKey là **GPL v3**, một giấy phép copyleft.

## Quyết định

mindful-key là **GPL v3**.

Credit Mai Vũ Tuyên và OpenKey phải có mặt trong `LICENSE`, `README.md` và màn About. Không được gỡ
credit gốc. Phần tự viết ghi rõ là "based on OpenKey".

## Đánh đổi đã chấp nhận

Copyleft nghĩa là **hễ phát hành bản chạy thì phải kèm mã nguồn tương ứng**. Không có đường mở sản
phẩm nguồn đóng dựa trên lõi này. Repo công khai không được là "chỉ binary, giấu code".

Đây không thực sự là một lựa chọn — nó là hệ quả bắt buộc của việc kế thừa. Điều được chọn là *có
kế thừa hay không*, và dự án chọn kế thừa để không viết lại một engine tiếng Việt đã chín.

## Hệ quả

- Mọi Release phải kèm hoặc trỏ được tới mã nguồn của đúng bản đó.
- Credit là **điều bất khả xâm phạm**, ngang hàng với luật nhận diện. Một lần đổi tên hàng loạt trên
  vỏ Windows từng làm sai credit thành "Dựa trên MindfulKey — Mai Vũ Tuyên", biến nó thành lời ghi
  công vòng tròn. Đây là lỗi pháp lý, không phải lỗi chính tả.
- Mọi thay đổi chạm giấy phép hoặc credit đều phải hỏi chủ dự án trước.
