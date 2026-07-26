# ADR-0006 — Ngưỡng gác cổng không ăn theo núm Độ nhạy

- **Trạng thái:** Đã chốt
- **Ngày:** không ghi lại ngày cụ thể
- **Liên quan:** `../tasks/MOOD-WAVE-MECHANISM.md` §5

## Bối cảnh

Người dùng có một núm **Độ nhạy** ba mức, đặt ngưỡng "thế nào là gợn" và độ dài chuỗi câu căng làm
chuông ngân. Vặn xuống mức ít nhạy là cách để đỡ bị làm phiền.

Câu hỏi: gác cổng có nên ăn theo núm này không?

## Quyết định

**Không.** Ngưỡng gác cổng là hằng số cứng trong `core/mood/BreathingPause.cpp`, chung cho mọi hệ
điều hành và không đổi theo bất kỳ cài đặt nào của người dùng.

Núm Độ nhạy chỉ chi phối: câu chữ tóm tắt trong ngày, chuông theo chuỗi câu căng, và màn Soi lại.

## Đánh đổi đã chấp nhận

Người dùng mất quyền vặn nhẹ tính năng gác cổng. Ai thấy nó phiền chỉ có một lựa chọn: **tắt hẳn**
bằng công tắc riêng.

Chấp nhận vì cái giá của phương án kia lớn hơn nhiều. Nếu để chung một núm thì người vặn "ít nhạy"
chỉ vì muốn đỡ ồn chuông sẽ **vô tình hạ luôn tấm lưới an toàn** chặn tin nhắn giận — thứ họ không hề
có ý định đụng vào, và cũng không có cách nào biết là vừa đụng vào.

Ràng buộc kèm theo: dòng chú thích dưới thanh Độ nhạy phải nói thẳng điều này. Một cài đặt có tác
dụng phụ ngầm thì tệ hơn một cài đặt kém linh hoạt.

## Hệ quả

- Ngưỡng gác cổng sống ở tầng `core/`, không phải ở vỏ, để ba vỏ không trôi lệch nhau.
- Popup nhắc thụ động cũng dùng ngưỡng cứng, cùng lý do.
- Công tắc bật tắt gác cổng phải **độc lập** với công tắc nhật ký. Tắt cái này không được kéo theo
  cái kia.
