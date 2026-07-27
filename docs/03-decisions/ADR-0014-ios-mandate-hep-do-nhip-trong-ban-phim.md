# ADR-0014 — Mandate iOS hẹp: nhịp gõ chỉ đo được trong chính bàn phím

- **Trạng thái:** Đã chốt
- **Ngày:** 2026-07-27
- **Liên quan:** [ADR-0013](ADR-0013-do-nhip-go-thay-doc-cam-xuc.md),
  [ADR-0002](ADR-0002-monorepo-mot-bo-nao-nhieu-vo.md), `../tasks/FRICTION-LOG.md` 2026-07-10.
  Thay thế ADR-0009 (đã gỡ — xem ghi chú ở [README](README.md))

## Bối cảnh

ADR-0009 chốt mandate iOS hẹp với lý lẽ: extension bị nhốt trong hộp cát, không thấy được nút Gửi của
ứng dụng chủ, nên **không gác cổng gửi tin được**.

[ADR-0013](ADR-0013-do-nhip-go-thay-doc-cam-xuc.md) đã bỏ hẳn gác cổng trên **mọi** nền tảng. Lý lẽ
cũ vì thế không còn phân biệt được iOS với macOS — nó nói về một tính năng không còn tồn tại. Nhưng
**kết luận thì vẫn đúng**, chỉ là đúng vì một lý do khác. ADR này ghi lại lý do mới.

## Quyết định

Mandate iOS vẫn **cố ý hẹp**, với lý lẽ mới:

> Hộp cát chỉ cho bàn phím thấy phím gõ **trong chính nó**. Không có global hook. Vì vậy nhịp gõ chỉ
> đo được khi người dùng đang gõ bằng bàn phím mindful-key — không phải toàn hệ thống.

Người dùng iOS đổi sang bàn phím khác là phép đo dừng, im lặng, không có cách nào biết. Đây là giới
hạn của nền tảng, không phải việc chưa làm. Dòng "đo nhịp toàn hệ thống trên iOS" ghi là **bất khả
thi** trong sổ bằng chứng.

## Đánh đổi đã chấp nhận

Vỏ iOS phủ được ít thời gian gõ của người dùng hơn hẳn macOS/Windows, và **không tự biết mình đang
phủ được bao nhiêu**. Người dùng iOS nhận một sản phẩm khác về chất, không phải bản rút gọn của cùng
một sản phẩm.

Chấp nhận vì phương án kia là hứa một thứ nền tảng không cho phép làm. Che giấu giới hạn này dẫn
thẳng tới việc người dùng cài rồi thất vọng, và mâu thuẫn với nguyên tắc công khai vùng mù ở
[tầng Intent §4.2](../01-intent.md). Onboarding iOS phải nói thẳng câu này, không để người dùng tự
phát hiện.

## Hệ quả

- Vỏ khác nhau **được phép** có tập tính năng khác nhau. Điều này củng cố
  [ADR-0002](ADR-0002-monorepo-mot-bo-nao-nhieu-vo.md): chung repo là để chia sẻ cái chia sẻ được,
  không phải để ép mọi vỏ giống nhau.
- iOS vẫn dùng chung `core/engine`, `core/mood` và `brand/`. Chỉ tầng vỏ khác.
- Bàn phím iOS **không còn cần đọc câu vừa gõ**. Sau khi lớp đọc cảm xúc bị gỡ, "Full Access" chỉ
  còn phục vụ gõ tắt và ngăn lưu chung — phạm vi quyền hẹp lại thật, và câu chữ onboarding phải sửa
  theo.
- Màn soi lại trên iOS không được trình bày số lần chuông như thể đó là toàn bộ ngày gõ của người
  dùng.
- Android bị giới hạn IME nhẹ hơn iOS nhưng cũng không tự do như desktop. Khi tới lượt, phải xác
  định mandate riêng thay vì mặc định copy bản desktop.
