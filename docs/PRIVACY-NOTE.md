# Mindful Keyboard xử lý dữ liệu của bạn như thế nào

*(Bản dễ đọc — dùng trong màn hình xin phép và onboarding. Xem `docs/PRD.md` §5 cho phiên bản kỹ thuật đầy đủ.)*

## Điều quan trọng nhất

**Câu chữ bạn gõ không bao giờ rời khỏi máy của bạn.** Không gửi lên internet, không gửi cho chúng tôi, không gửi cho ai cả — kể cả khi bạn gõ những câu riêng tư nhất.

## Vậy app "biết" gì?

Khi bạn gõ, app tính ra **một con số duy nhất** — gọi là "điểm rủi ro khi gửi" (0 đến 1) — để trả lời câu hỏi: *"nếu gửi câu này đi, nó có thể làm tổn thương ai đó không?"*. Việc tính toán này diễn ra hoàn toàn ngay trên máy bạn, không cần internet.

Nếu bạn **đồng ý** (và chỉ khi bạn đồng ý), app lưu lại một nhật ký nhỏ mỗi khi tính năng "gác cổng" được kích hoạt, gồm:

| Được lưu | KHÔNG BAO GIỜ được lưu |
|---|---|
| Điểm rủi ro (một con số 0–1) | Câu bạn vừa gõ |
| Thời điểm (giờ, ngày) | Tên người nhận |
| Tên ứng dụng bạn đang gõ (vd "Zalo") | Nội dung cuộc trò chuyện |
| Bạn đã chọn "Vẫn gửi" hay "Đợi chút" | Bất kỳ chữ nào bạn gõ |

Nhật ký này được **mã hóa** và **chỉ lưu trên máy bạn** — không đồng bộ lên đám mây, không có server nào của chúng tôi nhận được nó.

## Bạn luôn có quyền kiểm soát

- **Chưa từng đồng ý = chưa có gì được ghi lại.** App sẽ hỏi bạn một lần, vào lúc bình thường (không phải giữa lúc bạn đang bực mình) — bạn có thể từ chối.
- **Đổi ý bất cứ lúc nào:** tắt "Nhắc tâm" trong menu app trên thanh menu.
- **Xóa sạch bất cứ lúc nào:** chọn "Xóa nhật ký cảm xúc..." trong menu — xóa vĩnh viễn, không thể khôi phục.

## Vùng mù — nói thẳng để bạn không hiểu lầm

App chỉ "nghe" được khi bộ gõ đang bật **và** bạn đang gõ tiếng Việt. Nếu bạn đang ở chế độ gõ tiếng Anh, đang gõ trong ô mật khẩu, hoặc tắt bộ gõ đi — app không thấy gì cả. Tính năng "gác cổng trước khi gửi" hiện chỉ hoạt động trong một số ứng dụng nhắn tin cụ thể (không phải mọi nơi bạn gõ chữ).

## Trên iPhone: vì sao bàn phím xin "Full Access"

Khi bạn thêm Mindful Key trên iPhone, iOS sẽ hỏi bạn bật **"Allow Full Access"**. Nghe thì "mở toang", nên chúng tôi nói thẳng nó dùng để làm gì:

- **Đọc câu bạn vừa gõ** để con sóng `~` phản chiếu nhịp gõ — tính ngay trên máy, không gửi đi đâu.
- **Đọc gõ tắt (macro) và cài đặt** bạn đặt trong app — hai bên (app và bàn phím) chia nhau một ngăn lưu chung trên chính máy bạn.

iOS bắt buộc phải có "Full Access" thì bàn phím mới đọc được hai thứ trên. **Nó KHÔNG dùng để gửi chữ của bạn ra internet** — Mindful Key không có máy chủ nào để gửi tới. Bạn vẫn gõ bình thường mà chưa cần bật; bật khi nào bạn muốn có con sóng và gõ tắt.

## Vì sao chúng tôi làm vậy

Mindful Keyboard là bộ gõ — nghĩa là nó *thấy được* mọi phím bạn bấm. Đó là lý do chúng tôi coi quyền riêng tư là điều kiện sống còn, không phải một tính năng phụ: nếu bạn không tin tưởng được rằng câu chữ của mình an toàn, mọi tính năng chánh niệm khác đều vô nghĩa.
