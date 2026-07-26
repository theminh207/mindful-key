# 03 — Decisions (ADR)

> Mỗi tệp ở đây ghi lại **một lựa chọn đã chốt, kèm lý do và đánh đổi**. ADR là bản ghi lịch sử:
> viết xong thì **không sửa nội dung**. Đổi ý thì viết ADR mới và đánh dấu ADR cũ là *Bị thay thế*,
> để người đọc sau thấy được cả quyết định lẫn đường đi tới nó.
>
> Phân biệt với [tầng Contracts](../04-contracts.md): ADR nói *"đã chọn X vì Y"* — thuộc quá khứ.
> Hợp đồng nói *"mọi vỏ phải giữ Z"* — đang có hiệu lực, vi phạm là bug.

## Danh sách

| # | Quyết định | Ngày | Trạng thái |
|---|---|---|---|
| [0001](ADR-0001-gpl-v3.md) | Giấy phép GPL v3 kế thừa từ OpenKey | 2026-07-08 | Đã chốt |
| [0002](ADR-0002-monorepo-mot-bo-nao-nhieu-vo.md) | Một monorepo cho mọi nền tảng | — | Đã chốt |
| [0003](ADR-0003-send-risk-mot-con-so.md) | Send-risk là một con số, không phải phân loại cảm xúc | — | Đã chốt |
| [0004](ADR-0004-lexicon-truoc-model-sau.md) | Lexicon trước, model on-device sau | — | Đã chốt |
| [0005](ADR-0005-phat-hien-sap-gui.md) | Phát hiện "sắp gửi" bằng phím Enter và allow-list | — | Đã chốt |
| [0006](ADR-0006-nguong-gac-cong-doc-lap.md) | Ngưỡng gác cổng không ăn theo núm Độ nhạy | — | Đã chốt |
| [0007](ADR-0007-phan-phoi-truc-tiep.md) | Phân phối trực tiếp, không qua Mac App Store | — | Đã chốt |
| [0008](ADR-0008-san-macos-13.md) | Sàn hệ điều hành macOS 13.0 | 2026-07-18 | Đã chốt |
| [0009](ADR-0009-ios-mandate-hep.md) | Mandate iOS hẹp: không gác cổng gửi tin | 2026-07-10 | Đã chốt |
| [0010](ADR-0010-ky-windows-signpath.md) | Ký Windows qua SignPath Foundation | 2026-07-18 | Đã chốt |
| [0011](ADR-0011-kho-windows-dpapi.md) | Kho nhật ký Windows dùng tệp phẳng DPAPI | 2026-07-17 | Đã chốt |
| [0012](ADR-0012-mot-nguon-nhan-dien.md) | Một nguồn nhận diện, ba đích | 2026-07-17 | Đã chốt |

Dấu `—` ở cột Ngày nghĩa là quyết định có trong kho tài liệu nhưng **không ghi ngày cụ thể**. Không
suy đoán ngày cho chúng.

## Viết ADR mới

Đặt tên `ADR-00NN-mo-ta-ngan.md`, dùng khuôn dưới đây, rồi thêm một dòng vào bảng trên.

```markdown
# ADR-00NN — Tiêu đề

- **Trạng thái:** Đã chốt | Bị thay thế bởi ADR-00MM
- **Ngày:** YYYY-MM-DD
- **Liên quan:** đường dẫn tới nguồn hoặc ADR khác

## Bối cảnh
Tình huống buộc phải chọn. Nêu ràng buộc thật, không nêu chung chung.

## Quyết định
Chọn cái gì. Viết ở thể khẳng định.

## Đánh đổi đã chấp nhận
Mất gì khi chọn như vậy. Phần này quan trọng nhất — thiếu nó thì ADR chỉ là ghi chép.

## Hệ quả
Ràng buộc mà quyết định này áp lên công việc về sau.
```

Nguồn để chắt thêm ADR khi cần: `../tasks/FRICTION-LOG.md`, `../../bmad-output/decision-log.md`.
