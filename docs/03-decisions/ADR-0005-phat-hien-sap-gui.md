# ADR-0005 — Phát hiện "sắp gửi" bằng phím Enter và allow-list

- **Trạng thái:** Đã chốt
- **Ngày:** không ghi lại ngày cụ thể
- **Liên quan:** [HĐ-1](../04-contracts.md), `../tasks/BREATHING-PAUSE-CONTRACT.md` §5

## Bối cảnh

Gác cổng cần biết đúng khoảnh khắc người dùng sắp gửi. Có hai đường làm điều đó.

Đường thứ nhất là **hỏi cây accessibility** của ứng dụng đang chạy để tìm nút Gửi. Đúng về mặt ngữ
nghĩa, nhưng mỗi ứng dụng chat dựng giao diện một kiểu và đổi theo mỗi bản cập nhật — dễ vỡ, và đã
được lường trước là một rủi ro lớn từ đầu dự án.

Đường thứ hai là bắt **phím Enter không kèm Shift** trong hook bàn phím vốn đã có sẵn, rồi đối chiếu
định danh ứng dụng đang focus với một danh sách cho phép.

## Quyết định

Dùng đường thứ hai: **Enter không Shift, cộng allow-list định danh ứng dụng**.

Cơ chế nuốt và phát lại: khi đủ điều kiện, hook trả về rỗng để nuốt đúng phím Enter đó và hiện khung
gác cổng. Chọn "vẫn gửi" thì phát lại một sự kiện Enter thật **có gắn dấu nguồn riêng**, nhờ vậy
hook tự bỏ qua nó ở bước kiểm tra đầu tiên và không rơi vào vòng lặp tự chặn chính mình.

Allow-list chỉ chứa ứng dụng đã cài và **xác minh định danh thật**. Windows để **rỗng mặc định** vì
máy dev là macOS nên không xác minh được tên tiến trình; người dùng tự thêm qua menu khay.

## Đánh đổi đã chấp nhận

- Chỉ phủ được vài ứng dụng chat, không phải mọi nơi có ô nhập chữ. Điều này được nêu thẳng là
  non-goal, không phải thiếu sót.
- Không bắt được trường hợp người dùng bấm chuột vào nút Gửi thay vì bấm Enter.
- Điểm chèn kiểm tra nằm **trước** khi engine xử lý ký tự Enter, nên nếu từ cuối câu chưa được chốt
  thì send-risk có thể chưa tính từ đó. Đánh đổi có chủ đích để không phải đụng vào hơn 900 dòng
  logic xử lý tiếng Việt — rủi ro hồi quy ở đó cao hơn nhiều so với lợi ích xử lý hoàn hảo ca biên
  này.

## Hệ quả

- Thêm ứng dụng vào allow-list là việc **xác minh**, không phải việc đoán. Không thêm định danh chưa
  kiểm chứng trên máy thật.
- Cơ chế chống vòng lặp phải dùng đúng thứ hệ điều hành đã có sẵn: dấu nguồn sự kiện trên macOS,
  trường thông tin phụ của sự kiện trên Windows. Không tự chế cờ mới.
