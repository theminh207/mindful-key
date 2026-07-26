# ADR-0007 — Phân phối trực tiếp, không qua Mac App Store

- **Trạng thái:** Đã chốt
- **Ngày:** không ghi lại ngày cụ thể
- **Liên quan:** `../tasks/PRD.md` §1, §3; [tầng Operations](../06-operations.md)

## Bối cảnh

Ứng dụng cần bắt phím ở phạm vi toàn hệ thống để làm được cả bộ gõ lẫn gác cổng. Mac App Store yêu
cầu sandbox, và sandbox không tương thích với việc bắt phím toàn cục.

Ngoài ra, quy trình duyệt của App Store không cần thiết cho một bản beta đóng nhắm nhóm nhỏ.

## Quyết định

Phân phối **trực tiếp** bằng gói `.dmg` đã ký Developer ID và notarize. Không qua Mac App Store.

## Đánh đổi đã chấp nhận

- Mất kênh phân phối có sẵn người dùng và có sẵn cơ chế thanh toán, cập nhật.
- Phải tự lo ký số, notarize, và tự lo cả cơ chế tự cập nhật — thứ hiện **chưa có**.
- Người dùng tải qua trình duyệt sẽ bị dán cờ quarantine, và đã có người dùng thật gặp thông báo
  *"MindfulKey is damaged"* vì lý do này. Phải bù bằng script cài đặt dùng `curl` và bằng tài liệu
  hướng dẫn.

Chấp nhận vì phương án kia không phải là đánh đổi mà là **bất khả thi**: sandbox chặn đúng thứ làm
nên sản phẩm.

## Hệ quả

- Ký số và notarize trở thành hạ tầng bắt buộc, không phải việc làm sau. Xem
  [tầng Operations §6](../06-operations.md).
- Cùng logic đó áp cho Windows: phân phối `.exe` tự ký qua SignPath, xem
  [ADR-0010](ADR-0010-ky-windows-signpath.md).
- Tự cập nhật là khoảng trống đã biết. Sparkle đã có trong kế hoạch nhưng chưa gắn SDK.
