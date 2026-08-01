# Tài liệu dự án mindful-key

Tập tài liệu này được tổ chức theo lối **intent-driven**: ý định là bản gốc, code là bản dịch.
Khi code và tài liệu mâu thuẫn, tầng 01–04 là nguồn đúng và code phải sửa theo; riêng tầng 02
(Features) mô tả hiện trạng nên khi lệch thì tài liệu phải sửa theo code.

## Bảy tầng

| Tầng | Trả lời câu hỏi | Tính chất |
|---|---|---|
| [01 — Intent](01-intent.md) | Dự án tồn tại để làm gì, và tuyệt đối không được làm gì | Ổn định nhất. Đổi = đổi bản chất sản phẩm |
| [02 — Features](02-features.md) | Sản phẩm hiện làm được gì, trên nền tảng nào | Đổi theo mỗi lần ship |
| [03 — Decisions](03-decisions/) | Đã chọn phương án nào, vì sao, đánh đổi gì | Chỉ thêm, không sửa. Đảo quyết định = viết ADR mới |
| [04 — Contracts](04-contracts.md) | Bất biến mà mọi nền tảng phải giữ | Đang có hiệu lực. Vi phạm = bug |
| [05 — Conventions](05-conventions.md) | Viết code theo lối nào | Đổi khi đội thống nhất lối mới |
| [06 — Operations](06-operations.md) | Build, ký, phát hành, cài đặt, kiểm thử ra sao | Đổi theo hạ tầng |
| [07 — Glossary](07-glossary.md) | Từ ngữ riêng của dự án nghĩa là gì | Thêm khi có khái niệm mới |

## Thứ tự đọc

Người mới vào dự án: **01 → 07 → 02 → 04**. Bốn tầng đó đủ để hiểu sản phẩm là gì và ranh giới ở
đâu. Tầng 03 đọc khi cần biết "vì sao lại làm thế này chứ không thế kia". Tầng 05–06 đọc khi bắt
đầu viết code hoặc phát hành.

Agent hoặc công cụ tự động: đọc **01** trước mọi việc chạm nhận diện, pháp lý, riêng tư. Đọc
**04** trước khi sửa đường khởi động, lớp đo nhịp gõ, hoặc mạch chuông.

## Xếp tài liệu mới vào đâu

- Mô tả *nên như thế nào* và không bao giờ được vi phạm → tầng 01 hoặc 04.
- Mô tả *đang như thế nào* → tầng 02.
- Ghi lại *một lựa chọn đã chốt kèm lý do* → tầng 03, một ADR mới.
- Việc cần làm, lộ trình, feedback nghiệm thu, ý tưởng chưa chốt → **không thuộc `docs/`**. Nơi
  của chúng là `docs/tasks/`.

## Hai thư mục đi kèm

**`tasks/`** — kho lưu trữ toàn bộ tài liệu trước ngày 2026-07-26, cộng với lộ trình, bảng thi
công, feedback nghiệm thu và ý tưởng chưa chốt. Nội dung ở đây là nguồn để chắt ra bảy tầng trên,
và vẫn là chỗ tra chi tiết khi bảy tầng chỉ nêu nguyên tắc. Hai sổ sống cần biết:

- `tasks/TEST_MATRIX.md` — bảng hành vi → bằng chứng. Mỗi hành vi ghi `implemented` phải có bằng
  chứng trỏ tới thứ có thật.
- `tasks/FRICTION-LOG.md` — danh sách chỗ trong dự án còn mơ hồ nên phải suy diễn. Đây là hàng
  đợi việc "nên viết luật tiếp theo".

**`diagrams/`** — sơ đồ nguồn (`.drawio`) và bản xuất (`.svg`).
