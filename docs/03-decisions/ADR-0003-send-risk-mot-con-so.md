# ADR-0003 — Send-risk là một con số, không phải phân loại cảm xúc

- **Trạng thái:** Bị thay thế bởi [ADR-0013](ADR-0013-do-nhip-go-thay-doc-cam-xuc.md)
- **Ngày:** không ghi lại ngày cụ thể
- **Liên quan:** [HĐ-3](../04-contracts.md), `../tasks/PRD.md` §2

## Bối cảnh

Lớp đọc cảm xúc có thể được thiết kế theo hai hướng. Một là **phân loại nhiều nhãn** — giận, buồn,
lo, vui — như phần lớn bài toán sentiment analysis. Hai là **quy về một điểm duy nhất** trả lời đúng
câu hỏi sản phẩm cần.

Câu hỏi sản phẩm cần trả lời rất hẹp: *"nếu gửi câu này đi, nó có thể làm tổn thương ai đó không?"*

## Quyết định

Lớp cảm xúc trả về **một số thực trong khoảng [0, 1]**, gọi là send-risk.

```
câu (chuỗi) → risk (số thực [0, 1])
```

Không phân loại nhiều nhãn. Không trả về tên cảm xúc.

## Đánh đổi đã chấp nhận

Mất khả năng nói với người dùng "bạn đang buồn" hay "bạn đang lo". Nhưng đó chính là thứ [tầng
Intent](../01-intent.md) cấm — chụp mũ trạng thái tâm của người khác là phán xét, không phải mô tả.

Cũng mất khả năng làm thống kê kiểu "tuần này bạn giận N lần". Đó cũng là thứ không muốn có, vì nó
dẫn thẳng tới gamification.

## Hệ quả

- Mọi tầng phía sau — nhịp thở, gác cổng, kho dữ liệu, câu chữ — chỉ tiêu thụ **một con số** và
  không quan tâm nó được tính bằng gì. Nhờ vậy thay cách tính không phá vỡ gì cả.
- Cột dữ liệu trong kho là `send_risk`, một số. Không có cột tên cảm xúc.
- Đây là điều kiện làm cho [ADR-0004](ADR-0004-lexicon-truoc-model-sau.md) khả thi.
- Bài toán huấn luyện model sau này là **regression trên nhãn "harmful-if-sent"**, không phải
  multi-class cảm xúc.
