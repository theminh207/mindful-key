# ADR-0011 — Kho nhật ký Windows dùng tệp phẳng DPAPI

- **Trạng thái:** Bị thay thế bởi [ADR-0013](ADR-0013-do-nhip-go-thay-doc-cam-xuc.md)
- **Ngày:** 2026-07-17
- **Liên quan:** [tầng Features §C](../02-features.md), [HĐ-5](../04-contracts.md)

## Bối cảnh

macOS và iOS lưu nhật ký cảm xúc trong SQLite mã hóa AES-256 với khóa giữ ở Keychain. Cách hiển
nhiên là làm y hệt trên Windows.

Nhưng kéo SQLite kèm lớp mã hóa vào vỏ Windows nghĩa là thêm một phụ thuộc lớn cho một nhu cầu rất
nhỏ: kho này chỉ ghi thêm dòng và đọc theo khoảng thời gian, không có truy vấn phức tạp nào.

## Quyết định

Vỏ Windows dùng **tệp phẳng TSV, mã hóa toàn tệp bằng DPAPI** (`CryptProtectData`).

Ghi **nguyên tử**: viết ra tệp tạm, đẩy xuống đĩa, rồi đổi tên đè lên. Ghi đè thẳng là mất cả sổ khi
mất điện giữa chừng.

**Schema giữ bất biến** khớp macOS: `ts`, `event_type`, `send_risk`, `app_bundle_id`, `choice`.

## Đánh đổi đã chấp nhận

- Mất khả năng truy vấn bằng SQL. Mọi phép lọc và gộp phải viết tay bằng C++.
- Toàn bộ tệp được giải mã một lần để đọc, nên không mở rộng tốt nếu kho lớn dần. Chấp nhận được với
  nhịp ghi hiện tại là một mẫu mỗi nhịp chuông.
- Ba vỏ có **ba cơ chế lưu trữ khác nhau**, phải tự giữ cho chúng đồng nghĩa.

Chấp nhận vì tiêu chí thật của kho này là *mã hóa at-rest, ghi an toàn, không lộ văn bản gốc* — cả
ba đều đạt được mà không cần cơ sở dữ liệu.

## Hệ quả

- **Schema là hợp đồng liên vỏ.** Thêm hay đổi cột thì phải làm ở cả ba vỏ cùng lượt, nếu không dữ
  liệu hai bên hết đồng nghĩa.
- Vẫn phải giữ đủ các cam kết chung: chưa đồng ý thì không tạo tệp; từ chối hoặc rút lại đồng ý thì
  xóa tệp; nhịp ghi đặt **trước** mọi cổng chặn tiếng, vì tắt chuông không phải tắt ghi nhận; nhịp
  không gõ thì không ghi, khác hẳn ghi giá trị 0.
- Đây là ca mẫu cho nguyên tắc ở [HĐ-5](../04-contracts.md): khác biệt hạ tầng giữa các vỏ được giải
  quyết **trong vỏ**, không kéo `core/` chạy theo.
