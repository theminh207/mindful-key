# ADR-0004 — Lexicon trước, model on-device sau

- **Trạng thái:** Đã chốt
- **Ngày:** không ghi lại ngày cụ thể
- **Liên quan:** [ADR-0003](ADR-0003-send-risk-mot-con-so.md), `../tasks/SEND-RISK-MODEL-SPEC.md`,
  `../tasks/MOOD-WAVE-MECHANISM.md`

## Bối cảnh

Tính send-risk bằng model ngôn ngữ on-device cho kết quả tốt hơn hẳn lexicon, đặc biệt ở mỉa mai và
ngữ cảnh. Nhưng làm model đòi hỏi một thứ dự án **chưa có**: dataset "harmful-if-sent" tiếng Việt.
Và không được dùng câu gõ thật của người dùng để huấn luyện — điều đó vi phạm nguyên tắc riêng tư
tại [tầng Intent §4.2](../01-intent.md).

## Quyết định

Ship với **lexicon có trọng số** cộng công thức bão hòa `risk = 1 − e^(−raw/5)`. Model on-device là
việc làm sau, không phải điều kiện để ra mắt.

Nâng cấp *bên trong* hàm tính risk — luật phủ định, trạng từ cường độ, mở rộng vốn từ — được ưu tiên
trước, vì chúng rẻ và không cản đường thay model.

## Đánh đổi đã chấp nhận

Chấp nhận bốn điểm mù, **công khai chứ không giấu**:

| Điểm mù | Ví dụ |
|---|---|
| Phủ định | "không vui" bị đọc thành "vui", thậm chí *kéo* risk xuống |
| Cường độ | "hơi bực" bằng đúng "bực điên lên" |
| Mỉa mai | "Tôi đang RẤT bình tĩnh đấy nhé" ra 0 |
| Vốn từ mỏng | nhiều khẩu ngữ thông dụng chưa có trong từ điển |

Điểm mù phủ định là nguy hiểm nhất vì nó nói dối **theo chiều sai**: người đang buồn mà mặt hồ báo
êm.

Chấp nhận vì đích của MVP là kiểm chứng *vòng lặp lõi*, không phải kiểm chứng độ chính xác của model.
Vòng lặp sai một số câu vẫn kiểm chứng được; vòng lặp chưa tồn tại thì không.

## Hệ quả

- Hợp đồng `câu → risk [0,1]` phải giữ nguyên khi thay model, để việc thay không lan ra ngoài một
  hàm. Xem [HĐ-3](../04-contracts.md).
- Khi thay model: bắt buộc có **timeout cứng** và **fallback về lexicon**. Không nhánh thứ ba, không
  crash, không chặn luồng gõ.
- Chỉ được **một bản** lexicon dùng chung mọi vỏ. Dự án từng có hai bản trôi lệch nhau khiến cùng
  một câu được cảm nhận khác nhau trên hai hệ điều hành.
- Dữ liệu huấn luyện, khi tới lúc làm, phải đến từ corpus công khai đã ẩn danh — **không bao giờ** từ
  người dùng thật.
