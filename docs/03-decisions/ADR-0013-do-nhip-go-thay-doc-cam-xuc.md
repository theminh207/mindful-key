# ADR-0013 — Đo nhịp gõ thay cho đọc cảm xúc

- **Trạng thái:** Đã chốt
- **Ngày:** 2026-07-27
- **Liên quan:** [tầng Intent](../01-intent.md), `../../spec/typing-cadence-bell/README.md`,
  thay thế [ADR-0003](ADR-0003-send-risk-mot-con-so.md),
  [ADR-0004](ADR-0004-lexicon-truoc-model-sau.md),
  [ADR-0005](ADR-0005-phat-hien-sap-gui.md),
  [ADR-0006](ADR-0006-nguong-gac-cong-doc-lap.md),
  [ADR-0011](ADR-0011-kho-windows-dpapi.md)

## Bối cảnh

Vòng lặp lõi cũ là `Sense → Pause → Remind → Reflect`. **Sense** đọc nội dung câu đang gõ để chấm một
điểm send-risk; **Pause** chặn lại lúc người dùng sắp gửi.

Mô hình đó buộc sản phẩm phải **đọc chữ người dùng gõ**. Lời hứa riêng tư mạnh nhất mà nó có thể nói
là *"chúng tôi có đọc nhưng không lưu, không gửi đi"* — một lời hứa người dùng chỉ có thể **tin**,
không kiểm chứng được, vì mắt thường nhìn vào app không phân biệt được "đọc rồi quên" với "đọc rồi
gửi".

Có một tín hiệu khác nằm sẵn trên bàn: **nhịp phím**. Nó đo được mà không cần biết phím đó là chữ gì.

## Quyết định

Vòng lặp lõi đổi thành:

```
Measure (đo nhịp gõ, CPM)  →  Bell (một tiếng chuông)  →  Reflect (đếm số lần chuông)
```

**Đơn vị đo là CPM — ký tự mỗi phút**, không phải WPM. Telex và VNI gõ dấu tốn thêm phím, nên cùng
một câu tiếng Việt tiêu tốn số phím rất khác nhau tuỳ kiểu gõ; đếm "từ" làm con số méo theo kiểu gõ,
đếm phím thì không.

**Cửa sổ trượt: 30 giây.** Ngắn hơn thì một tràng gõ dồn rồi nghỉ cũng đủ vượt ngưỡng; dài hơn thì
chuông tới sau khi nhịp đã lắng, mất tác dụng.

**Ngưỡng thuộc về người dùng.** Bốn mức, mặc định **Rất nhanh (400 CPM)**:

| Mức | Ngưỡng |
|---|---|
| Nhanh | 300 CPM |
| **Rất nhanh** | **400 CPM** — mặc định |
| Cực nhanh | 500 CPM |
| Tắt chuông | — |

Tên mức **mô tả nhịp tay, không mô tả tâm người gõ**. Được nói "nhanh"; không được nói "bình tĩnh",
"mất kiểm soát", "vội vàng" hay bất kỳ chữ nào quy về trạng thái tâm. Chỗ nào hiển thị tên mức thì
hiển thị kèm con số CPM, để người đọc thấy đây là phép đo chứ không phải một lời nhận xét.

Chuông chỉ là **âm thanh**. Không khung nổi, không chặn phím, không đếm ngược.

## Đánh đổi đã chấp nhận

**Gõ nhanh không luôn có nghĩa tâm đang động.** Người ta gõ nhanh khi chép lại một đoạn, khi hào
hứng, khi quen bàn phím. Chuông vì vậy là **lời mời để ý**, không phải kết luận — và đây là lý do
ngưỡng phải do người dùng đặt, phải tắt được, và câu chữ quanh nó không bao giờ được viết ở thể
khẳng định về trạng thái người gõ.

**Mất hẳn khả năng nhận ra một câu tiêu cực sắp gửi đi.** Đây là mất mát thật, không phải đánh đổi
danh nghĩa: tính năng từng được coi là vương miện của sản phẩm biến mất. Chấp nhận vì thứ đổi lại là
một lời hứa khác hẳn về chất — *"chúng tôi không đọc"* — kiểm chứng được bằng cách nhìn vào code, và
không phụ thuộc vào việc người dùng có tin đội ngũ hay không.

**Mất luôn con đường model on-device.** ADR-0004 vạch lộ trình lexicon trước, model sau. Lộ trình đó
đóng lại: không còn bài toán nào cần model, vì không còn chữ nào được đọc.

## Hệ quả

- `core/mood` đổi đầu vào: từ *chuỗi ký tự* sang *dấu thời gian của phím*. Không hàm nào trong tầng
  này còn nhận `std::string` nội dung.
- Lexicon, `SendRiskAnalyzer` và `models/` phải bị **gỡ khỏi repo**, không phải chỉ ngừng gọi. Chừng
  nào code đọc chữ còn được nạp vào app, câu "không đọc nội dung" vẫn là quảng cáo.
- Biên độ con sóng `~` đổi nguồn: tính từ CPM thay vì từ send-risk. Công thức quy đổi phải nằm ở
  `core/` một bản duy nhất, để ba vỏ không trôi lệch.
- Chính sách reo chuông về `core/mood`, dùng chung cho macOS/Windows/iOS. Hiện đang có hai bản chép
  tay (`NudgeCoordinatorIOS.h` tự khai là sao y từ macOS) — không để sinh ra bản thứ ba.
- Kho nhật ký mất cột `send_risk`. Cái được ghi lại là **số lần chuông ngân**, không phải một điểm
  chấm cho câu nào. Schema cụ thể chốt ở issue #11.
- Nhật ký cũ trên máy người dùng đo bằng thước khác. Không trộn hai loại vào chung một biểu đồ —
  vẽ chung là nói dối người dùng.
- Trên iOS, phép đo chỉ chạy khi người dùng đang gõ bằng chính bàn phím mindful-key. Xem
  [ADR-0014](ADR-0014-ios-mandate-hep-do-nhip-trong-ban-phim.md).
