# 01 — Intent

> Tầng ý định. Luật tối cao của dự án. Mọi quyết định kỹ thuật, thiết kế và câu chữ đều phải quy
> chiếu về đây trước. Bản đầy đủ có bối cảnh lịch sử: `tasks/AGENT-BRIEF.md`, `tasks/PRD.md`.

## 1. Lý do tồn tại

mindful-key là bộ gõ tiếng Việt tồn tại vì **một nhiệm vụ duy nhất**: đứng giữa người dùng và
khoảnh khắc họ sắp gửi đi thứ mà năm phút sau sẽ hối hận.

Đây không phải bộ gõ có thêm tính năng theo dõi tâm trạng cho vui. Định vị ngược lại — khoảng dừng
chánh niệm trước lúc gửi là **tính năng số một**, không phải tính năng thứ n. Thống kê, nhật ký,
chuông tỉnh thức đều phục vụ tính năng đó, không ngang hàng với nó.

Lõi xử lý tiếng Việt kế thừa từ **OpenKey** (Mai Vũ Tuyên). Phần khác biệt là lớp chánh niệm phủ
lên trải nghiệm gõ.

## 2. Người dùng chính

Cộng đồng thực hành chánh niệm — không phải "mọi người gõ tiếng Việt". Nhóm này đã có động lực nội
tại để chấp nhận chậm lại một nhịp, nên ma sát mà sản phẩm tạo ra được đón nhận như một tính năng,
không phải phiền toái.

Hệ quả thiết kế: khi phân vân giữa "ít ma sát hơn cho số đông" và "đúng tinh thần chánh niệm", chọn
vế sau.

## 3. Vòng lặp lõi

```
Sense  →  Pause  →  Remind  →  Reflect
```

- **Sense** — đọc câu vừa gõ xong, quy về **một điểm send-risk trong khoảng [0, 1]**, không phải
  phân loại nhiều cảm xúc. Chạy on-device, bất đồng bộ, chỉ tại điểm kết từ. Không được làm khựng
  luồng gõ.
- **Pause** — khi send-risk vượt ngưỡng và vỏ phát hiện người dùng sắp gửi trong một ứng dụng chat
  đã allow-list, hiện một khung nổi ngắn với hai lựa chọn ngang nhau.
- **Remind** — câu chữ ngắn, mô tả hiện tượng, không phán xét, không cảnh cáo, không chấm điểm.
- **Reflect** — chuông chánh niệm ngân theo chuỗi câu căng thẳng phát hiện được; màn soi lại đọc
  kho dữ liệu local và hiện tóm tắt, không gamify.

Sản phẩm được coi là đạt khi vòng lặp này chạy mượt trong ít nhất hai đến ba ứng dụng chat phổ biến.

## 4. Điều bất khả xâm phạm

Bốn nhóm dưới đây không có ngoại lệ. Đề xuất nào chạm vào chúng mà chưa rõ thì **dừng lại và hỏi
chủ dự án**, không tự quyết.

### 4.1 Nhận diện — "tâm như mặt nước"

Biểu tượng là **con sóng `~` (dấu ngã)**, biến hình theo biên độ: mặt hồ lặng ứng với tâm tĩnh, mặt
hồ dậy sóng ứng với tâm động. Cùng một biểu tượng, chỉ đổi biên độ.

Cấm tuyệt đối:

- Đèn giao thông đỏ/xanh-lá mã hóa cảm xúc (đỏ là xấu, xanh là tốt) — đó là ngôn ngữ phán xét.
- Mặt cười, mặt mếu, emoji cảm xúc chấm điểm người dùng.
- Gamification: streak, điểm, huy hiệu, bảng xếp hạng — mọi thứ tạo áp lực thành tích.
- Câu chữ khiển trách kiểu "Bạn đang tệ", "Hãy cố lên".

Thay vào đó: biểu đạt trạng thái bằng **biên độ sóng** cộng **thang màu trung tính không bão hòa**;
câu chữ nêu hiện tượng để người dùng tự nhận biết. Mỗi mức phải đổi **cả hình lẫn màu** để người mù
màu và thanh menu đơn sắc vẫn đọc được.

Trạng thái tĩnh được tôn vinh, không chỉ đếm lần căng thẳng.

Màu và hình khối lấy từ nguồn duy nhất `brand/tokens.json`. Không hard-code màu ở bất kỳ vỏ nào.

> **Phép tự kiểm cho mọi đề xuất giao diện và câu chữ:** *"Cái này đang mô tả hay đang phán xét?"*
> Nếu là phán xét thì loại bỏ.

Ràng buộc này được cưỡng chế bằng máy qua `make brand-lint`, CI, git pre-commit và hook chặn agent —
không phụ thuộc vào việc có ai đọc tài liệu hay không.

### 4.2 Riêng tư — 100% on-device

- Câu chữ người dùng gõ **không bao giờ** rời khỏi máy. Không có ngoại lệ "để cải thiện model".
- Kho dữ liệu local được mã hóa và chỉ chứa điểm send-risk, thời điểm, tên ứng dụng, lựa chọn của
  người dùng. **Không cột nào chứa văn bản gốc.**
- Chưa đồng ý rõ ràng thì chưa ghi gì. Tắt được bất cứ lúc nào, xóa sạch được bất cứ lúc nào.
- Không telemetry mạng mặc định, không đồng bộ đám mây.
- Vùng mù phải được nói thẳng ngay từ onboarding, không ngầm định là "bắt được hết".

Lý do đặt riêng tư ngang hàng với lý do tồn tại: bộ gõ *thấy được* mọi phím bấm. Nếu người dùng
không tin câu chữ của mình an toàn thì mọi tính năng chánh niệm khác đều vô nghĩa.

### 4.3 Ma sát mềm, không chặn cứng

Nút gửi **không bao giờ** bị khóa. Lớp gác cổng chỉ được che tạm và lựa chọn "vẫn gửi" phải hoạt
động ngay lập tức. Quyết định cuối cùng luôn thuộc về người dùng.

Sản phẩm không phải công cụ giám sát: không có chế độ báo cáo hay xem từ xa cho người khác. Dữ liệu
chỉ chính người gõ được xem.

### 4.4 Pháp lý

OpenKey là **GPL v3**, đã xác minh 2026-07-08. mindful-key vì vậy cũng phải là GPL v3.

Credit **Mai Vũ Tuyên / OpenKey** phải có mặt trong `LICENSE`, `README.md` và màn About. Không được
gỡ credit gốc. Phần tự viết ghi rõ là "based on OpenKey". Hễ phát hành bản chạy thì phải kèm mã
nguồn tương ứng.

## 5. Non-goals

Những điều dự án **cố ý không làm**, để tránh bị hiểu là thiếu sót:

- Không phủ hết mọi ứng dụng chat. Phạm vi giới hạn ở vài ứng dụng đã kiểm chứng thật.
- Không nhắm độ chính xác tuyệt đối trong đọc cảm xúc. Chấp nhận sai số vừa phải, công khai vùng mù.
- Không qua Mac App Store. Phân phối trực tiếp bằng gói đã ký và notarize.
- Không fork logic gõ theo từng hệ điều hành. Bộ não dùng chung, chỉ vỏ khác nhau.
- Không đặt mục tiêu tăng trưởng ở giai đoạn này. Mục tiêu là kiểm chứng vòng lặp lõi.

## 6. Thứ tự ưu tiên nền tảng

macOS là công dân hạng nhất và không được làm loãng chất lượng để chạy đua đa nền tảng. Thứ tự:
**macOS → Windows → iOS → Android/Linux**.

Mandate iOS cố ý hẹp: chỉ nhật ký và nhắc thụ động, **không gác cổng gửi tin** — sandbox iOS không
cho bàn phím thấy nút gửi của ứng dụng khác. Xem [ADR-0009](03-decisions/ADR-0009-ios-mandate-hep.md).

## 7. Thế nào là đủ tốt

Ở mỗi bước, **đúng tinh thần** được ưu tiên hơn **nhiều tính năng**.

Các điều kiện sống còn, không phải chỉ số tăng trưởng:

- Không có báo cáo giật hay khựng gõ do lớp cảm xúc gây ra.
- Không có người bỏ cuộc ở màn xin quyền vì hoang mang.
- Người dùng tự nguyện mở màn soi lại — dấu hiệu bước Reflect có giá trị thật, không chỉ bước Pause
  hữu ích.
