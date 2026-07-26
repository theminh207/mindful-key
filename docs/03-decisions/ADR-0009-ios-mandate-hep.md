# ADR-0009 — Mandate iOS hẹp: không gác cổng gửi tin

- **Trạng thái:** Đã chốt
- **Ngày:** 2026-07-10
- **Liên quan:** `../tasks/FRICTION-LOG.md` 2026-07-10, `../tasks/REPO-TOPOLOGY.md` §2

## Bối cảnh

Tính năng số một của sản phẩm là gác cổng trước khi gửi. Trên macOS và Windows, nó làm được nhờ hook
bàn phím phạm vi toàn hệ thống.

Trên iOS, bàn phím là một **app extension bị nhốt trong hộp cát**. Extension không có global hook và
không thấy được nút Gửi của ứng dụng chủ. Đây là giới hạn của nền tảng, không phải vấn đề kỹ thuật
chờ giải.

## Quyết định

Mandate iOS **cố ý hẹp**: chỉ **nhật ký cảm xúc và nhắc chánh niệm thụ động**. Không gác cổng gửi
tin.

Dòng hành vi "gác cổng gửi tin trên iOS" được đánh dấu là **bất khả thi** trong sổ bằng chứng, không
phải "chưa làm".

## Đánh đổi đã chấp nhận

Vỏ iOS không có tính năng vương miện của sản phẩm. Người dùng iOS nhận một sản phẩm **khác** về chất,
không phải bản rút gọn của cùng một sản phẩm.

Chấp nhận vì phương án kia là hứa một thứ nền tảng không cho phép làm. Che giấu giới hạn này sẽ dẫn
thẳng tới việc người dùng cài rồi thất vọng, và mâu thuẫn với nguyên tắc công khai vùng mù ở
[tầng Intent §4.2](../01-intent.md).

## Hệ quả

- Vỏ khác nhau **được phép** có tập tính năng khác nhau — đây chính là ca đầu tiên buộc phải công
  nhận điều đó, và nó củng cố [ADR-0002](ADR-0002-monorepo-mot-bo-nao-nhieu-vo.md): chung repo là để
  chia sẻ cái chia sẻ được, không phải để ép mọi vỏ giống nhau.
- iOS vẫn dùng chung `core/engine`, `core/mood` và `brand/`. Chỉ tầng vỏ khác.
- Bàn phím iOS xin quyền "Full Access" cho hai việc: đọc câu vừa gõ để vẽ con sóng, và đọc gõ tắt
  cùng cài đặt qua ngăn lưu chung. **Không** dùng để gửi chữ ra internet — sản phẩm không có máy chủ
  nào để gửi tới. Điều này phải được nói thẳng trong onboarding.
- Android bị giới hạn IME nhẹ hơn iOS nhưng cũng không tự do như desktop. Khi tới lượt, phải xác định
  mandate riêng thay vì mặc định copy bản desktop.
