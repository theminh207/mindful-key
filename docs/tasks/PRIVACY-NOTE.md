# Mindful Key xử lý dữ liệu của bạn như thế nào

*(Bản dễ đọc — dùng trong màn hình xin phép và onboarding. Xem `docs/01-intent.md` §4.2 cho bản quy phạm.)*

> 🔄 **Ghi chú cho người trong dự án, không hiện cho người dùng:** bản đang phát hành ngoài đời vẫn
> chạy mô hình cũ (đọc nội dung để chấm điểm). Trang này mô tả mô hình mới đã chốt và đang được thi
> công ở [`spec/typing-cadence-bell/`](../../spec/typing-cadence-bell/README.md). **Chừng nào
> `SendRiskAnalyzer` còn được nạp vào app thì câu "chúng tôi không đọc" chưa được phép hiện cho
> người dùng** — issue #13 gỡ code, issue #14 bật câu chữ mới.

## Điều quan trọng nhất

**Chúng tôi không đọc những gì bạn gõ.**

Không phải "có đọc nhưng không lưu". Không phải "có đọc nhưng đã mã hóa". **Không đọc.** App đếm
*nhịp tay bạn bấm phím* — như đếm nhịp trống mà không nghe lời bài hát.

Và bạn không cần tin lời hứa suông: điều này **kiểm chứng được bằng cách đọc mã nguồn**. Dự án đặt
một luật cứng (`docs/04-contracts.md` HĐ-1) cấm mọi hàm trong lớp đo nhịp nhận tham số kiểu chuỗi.
Không có đường nào cho chữ đi vào, kể cả vô tình. Mã nguồn mở, GPL v3 — ai cũng soi được.

## Vậy app "biết" gì?

Đúng một thứ: **bạn đang gõ nhanh cỡ nào**, tính bằng số ký tự mỗi phút trong 30 giây vừa rồi.

Khi con số đó vượt mức **bạn tự đặt**, app ngân một tiếng chuông. Chỉ vậy. Không khung hiện lên,
không chặn phím, không hỏi han, không đòi bạn bấm gì.

Nếu bạn **đồng ý** (và chỉ khi đó), app ghi lại một dòng nhỏ mỗi lần chuông ngân:

| Được lưu | KHÔNG BAO GIỜ được lưu |
|---|---|
| Thời điểm chuông ngân | Bất kỳ chữ nào bạn gõ |
| Tốc độ gõ lúc đó (một con số) | Phím nào bạn bấm |
| Ngưỡng bạn đang đặt | Nội dung cuộc trò chuyện |
| | Tên người nhận |

Nhật ký này được **mã hóa** và **chỉ nằm trên máy bạn** — không đồng bộ đám mây, không có máy chủ
nào của chúng tôi nhận được nó. Chúng tôi không có máy chủ.

## Ngưỡng là của bạn, không phải của chúng tôi

Bốn mức để chọn: **Nhanh (300)** · **Rất nhanh (400)** · **Cực nhanh (500)** · **Tắt chuông**.
Đổi bất cứ lúc nào.

Mỗi người một nhịp tay — chúng tôi không quyết hộ bạn thế nào là "nhanh". Đó cũng là lý do tên các
mức chỉ mô tả **nhịp tay**, kèm luôn con số, chứ không nói gì về bạn.

## Nói thẳng về giới hạn

**Gõ nhanh không có nghĩa là bạn đang giận.** Có thể bạn đang chép chính tả, đang gõ lại một đoạn
đã nghĩ xong, hoặc tay bạn vốn nhanh. Tốc độ gõ là một **dấu hiệu thô**, không phải thước đo tâm
trạng. Tiếng chuông là **lời mời để ý một cái**, không phải một kết luận về bạn.

Chúng tôi nói điều này ngay từ đầu vì một sản phẩm chánh niệm mà nói quá về khả năng của mình thì
đã tự mâu thuẫn.

## Vùng mù — chỗ app không thấy gì

- **Ô mật khẩu:** app **không đếm nhịp** khi bạn đang nhập mật khẩu. Không xác định được ô đó là gì
  thì app cũng coi như ô mật khẩu và không đếm — thà mất vài nhịp còn hơn đếm nhầm.
- **Khi bộ gõ tắt:** không thấy gì.
- **Trên iPhone:** chỉ đếm được khi bạn đang dùng chính bàn phím Mindful Key. Bạn chuyển sang bàn
  phím khác thì app không thấy — sandbox của iOS không cho phép, và chúng tôi không tìm cách lách.

## Bạn luôn có quyền kiểm soát

- **Chưa từng đồng ý = chưa có gì được ghi.** App hỏi bạn một lần, vào lúc bình thường — không phải
  giữa lúc bạn đang bực.
- **Đổi ý bất cứ lúc nào:** tắt chuông, đổi ngưỡng, hoặc tắt hẳn tính năng.
- **Xóa sạch bất cứ lúc nào:** xóa vĩnh viễn, không khôi phục được.
- **Xuất ra file CSV:** bản xuất **hẹp hơn** nhật ký trong máy. Lý do: file CSV không còn được mã
  hóa (để bạn mở bằng Excel), nên một khi đã rời khỏi app, chúng tôi giữ nó càng gọn càng tốt.

## Trên iPhone: vì sao bàn phím xin "Full Access"

iOS sẽ hỏi bạn bật **"Allow Full Access"**. Nghe như "mở toang", nên nói thẳng nó dùng để làm gì:

- **Gõ tắt (macro) và cài đặt** bạn đặt trong app — app chính và bàn phím chia nhau một ngăn lưu
  chung trên chính máy bạn. iOS bắt buộc phải có quyền này thì hai bên mới đọc chung được.
- **Phát tiếng chuông** — iOS không cho bàn phím phát bất kỳ âm thanh nào nếu chưa bật quyền này.

**Nó KHÔNG dùng để gửi chữ của bạn ra internet** — Mindful Key không có máy chủ nào để gửi tới.

> Một thay đổi đáng nói: trước đây quyền này còn dùng để **đọc câu bạn vừa gõ** cho con sóng `~`.
> Lý do đó **không còn nữa** — con sóng giờ chạy bằng nhịp gõ, không cần đọc chữ.

## Vì sao chúng tôi làm vậy

Mindful Key là bộ gõ — nghĩa là nó *thấy được* mọi phím bạn bấm. Đó chính là lý do chúng tôi coi
quyền riêng tư là điều kiện sống còn chứ không phải một tính năng phụ: nếu bạn không tin được rằng
câu chữ của mình an toàn, thì mọi tính năng chánh niệm khác đều vô nghĩa.

Và đó cũng là lý do chúng tôi chọn đo nhịp gõ thay vì đọc nội dung, dù đo nhịp **kém chính xác hơn**
hẳn. Chúng tôi đánh đổi độ chính xác để lấy một lời hứa bạn kiểm chứng được.
