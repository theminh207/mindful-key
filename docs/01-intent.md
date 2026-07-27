# 01 — Intent

> Tầng ý định. Luật tối cao của dự án. Mọi quyết định kỹ thuật, thiết kế và câu chữ đều phải quy
> chiếu về đây trước. Bản đầy đủ có bối cảnh lịch sử: `tasks/AGENT-BRIEF.md`, `tasks/PRD.md`.

## 1. Lý do tồn tại

mindful-key là bộ gõ tiếng Việt tồn tại vì **một nhiệm vụ duy nhất**: nhận ra lúc nhịp gõ đang cuốn
người dùng đi, và ngân một tiếng chuông kéo họ về lại hiện tại.

Nhịp gõ là thứ đo được mà không cần đọc chữ. Khi tay chạy nhanh hơn bình thường, thường là tâm đang
gấp — đang tranh cãi, đang lo, đang cuốn theo. Bộ gõ không cần biết người dùng viết gì mới nhận ra
điều đó.

Đây không phải bộ gõ có thêm tính năng nhắc nhở cho vui. Định vị ngược lại — **tiếng chuông tỉnh
thức là tính năng số một**, không phải tính năng thứ n. Thống kê và nhật ký phục vụ tính năng đó,
không ngang hàng với nó.

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
Measure  →  Bell  →  Reflect
```

- **Measure** — đo **tốc độ gõ tính bằng ký tự mỗi phút (CPM)** trên một cửa sổ trượt ngắn. Chỉ đếm
  nhịp phím, **không đọc ký tự nào là ký tự nào**. Chạy on-device, nhẹ, không được làm khựng luồng
  gõ.
- **Bell** — tốc độ vượt ngưỡng thì ngân **một tiếng chuông tỉnh thức**. Chỉ có âm thanh: không
  khung nổi, không chặn phím, không hỏi han, không đòi người dùng bấm gì. Có khoảng lặng tối thiểu
  giữa hai lần chuông để nó không thành tiếng ồn.
- **Reflect** — mỗi lần chuông được ghi lại vào kho local; màn soi lại hiện tóm tắt số lần chuông
  theo thời gian, mô tả trần trụi, không gamify.

**Ngưỡng thuộc về người dùng.** Người dùng chọn mức tốc độ sẽ gọi chuông, đổi được bất cứ lúc nào.
Sản phẩm không tự quyết thế nào là "quá nhanh" cho người khác — mỗi người một nhịp tay.

Sản phẩm được coi là đạt khi vòng lặp này chạy mượt trong lúc gõ hàng ngày, ở mọi ứng dụng, không
làm người dùng để ý tới nó ngoài đúng lúc chuông ngân.

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

Trạng thái tĩnh được tôn vinh, không chỉ đếm lần chuông ngân.

Màu và hình khối lấy từ nguồn duy nhất `brand/tokens.json`. Không hard-code màu ở bất kỳ vỏ nào.

> **Phép tự kiểm cho mọi đề xuất giao diện và câu chữ:** *"Cái này đang mô tả hay đang phán xét?"*
> Nếu là phán xét thì loại bỏ.

Ràng buộc này được cưỡng chế bằng máy qua `make brand-lint`, CI, git pre-commit và hook chặn agent —
không phụ thuộc vào việc có ai đọc tài liệu hay không.

### 4.2 Riêng tư — 100% on-device

- Sản phẩm **không đọc nội dung** người dùng gõ. Nó chỉ đếm nhịp phím để tính tốc độ — không lưu,
  không phân tích, không suy đoán gì từ chữ nghĩa.
- Câu chữ người dùng gõ **không bao giờ** rời khỏi máy. Không có ngoại lệ.
- Kho dữ liệu local được mã hóa và chỉ chứa thời điểm chuông ngân, tốc độ đo được lúc đó, và ngưỡng
  đang đặt. **Không cột nào chứa văn bản gốc.**
- Chưa đồng ý rõ ràng thì chưa ghi gì. Tắt được bất cứ lúc nào, xóa sạch được bất cứ lúc nào.
- Không telemetry mạng mặc định, không đồng bộ đám mây.
- Giới hạn của phép đo phải được nói thẳng ngay từ onboarding: tốc độ gõ là một dấu hiệu thô, không
  phải thước đo tâm trạng.

Lý do đặt riêng tư ngang hàng với lý do tồn tại: bộ gõ *thấy được* mọi phím bấm. Nếu người dùng
không tin câu chữ của mình an toàn thì mọi tính năng chánh niệm khác đều vô nghĩa.

### 4.3 Ma sát mềm, không chặn cứng

Chuông **không bao giờ** được chặn luồng gõ: không khóa phím, không nuốt phím, không hiện khung nổi
đòi bấm, không làm chậm ký tự nào. Nó ngân lên rồi thôi — người dùng muốn phớt lờ thì gõ tiếp là
xong. Quyết định cuối cùng luôn thuộc về người dùng: tắt chuông, đổi ngưỡng, tắt cả tính năng đều
phải làm được ngay.

Sản phẩm không phải công cụ giám sát: không có chế độ báo cáo hay xem từ xa cho người khác. Dữ liệu
chỉ chính người gõ được xem.

### 4.4 Pháp lý

OpenKey là **GPL v3**, đã xác minh 2026-07-08. mindful-key vì vậy cũng phải là GPL v3.

Credit **Mai Vũ Tuyên / OpenKey** phải có mặt trong `LICENSE`, `README.md` và màn About. Không được
gỡ credit gốc. Phần tự viết ghi rõ là "based on OpenKey". Hễ phát hành bản chạy thì phải kèm mã
nguồn tương ứng.

## 5. Non-goals

Những điều dự án **cố ý không làm**, để tránh bị hiểu là thiếu sót:

- Không đọc cảm xúc từ nội dung. Không phân tích ngữ nghĩa, không chấm điểm câu chữ, không model
  sentiment. Tín hiệu duy nhất là tốc độ gõ.
- Không gác cổng nút gửi. Sản phẩm không phát hiện "sắp gửi tin", không chen vào giữa người dùng và
  ứng dụng chat.
- Không nhắm chính xác tuyệt đối. Gõ nhanh không luôn có nghĩa là tâm động — chuông là lời mời để ý,
  không phải kết luận.
- Không đo năng suất. Tốc độ gõ không bao giờ được trình bày như thành tích hay điểm số.
- Không qua Mac App Store. Phân phối trực tiếp bằng gói đã ký và notarize.
- Không fork logic gõ theo từng hệ điều hành. Bộ não dùng chung, chỉ vỏ khác nhau.
- Không đặt mục tiêu tăng trưởng ở giai đoạn này. Mục tiêu là kiểm chứng vòng lặp lõi.

## 6. Thứ tự ưu tiên nền tảng

macOS là công dân hạng nhất và không được làm loãng chất lượng để chạy đua đa nền tảng. Thứ tự:
**macOS → Windows → iOS → Android/Linux**.

Mandate iOS cố ý hẹp: sandbox chỉ cho bàn phím thấy phím gõ trong chính nó, nên **tốc độ chỉ đo
được khi người dùng đang dùng bàn phím mindful-key**, không phải toàn hệ thống. Xem
[ADR-0014](03-decisions/ADR-0014-ios-mandate-hep-do-nhip-trong-ban-phim.md).

## 7. Thế nào là đủ tốt

Ở mỗi bước, **đúng tinh thần** được ưu tiên hơn **nhiều tính năng**.

Các điều kiện sống còn, không phải chỉ số tăng trưởng:

- Không có báo cáo giật hay khựng gõ do lớp đo tốc độ gây ra.
- Không có người bỏ cuộc ở màn xin quyền vì hoang mang.
- Chuông ngân đúng lúc đủ để người dùng để yên, không tắt đi vì phiền — dấu hiệu ngưỡng và khoảng
  lặng đã hợp lý.
- Người dùng tự nguyện mở màn soi lại — dấu hiệu bước Reflect có giá trị thật, không chỉ tiếng
  chuông hữu ích.
