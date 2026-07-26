# 07 — Glossary

> Từ điển thuật ngữ riêng của dự án. Tầng này tồn tại vì phần lớn khái niệm ở đây **nghe như tiếng
> Việt thường ngày nhưng mang nghĩa hẹp và bắt buộc**. Hiểu sai một từ ở đây thường dẫn tới một
> giao diện vi phạm [tầng Intent](01-intent.md) mà không ai kịp nhận ra.

## Khái niệm sản phẩm

**Gác cổng (send gatekeeper)** — khoảnh khắc chặn tạm ngay trước khi một tin nhắn được gửi đi, khi
điểm send-risk vượt ngưỡng và ứng dụng đang gõ nằm trong allow-list. Là tính năng số một của sản
phẩm. Luôn là *ma sát mềm*: nút gửi không bao giờ bị khóa.

**Nhịp thở (breathing pause)** — tên gọi khác của cùng khoảnh khắc trên, nhìn từ phía hợp đồng
`core/mood/BreathingPause.h`. Hợp đồng chỉ trả về "có nên hiện gì không" cùng câu chữ gợi ý; nó
không có, và không được có, cơ chế nào ngăn hành động gửi.

**Ma sát mềm (soft friction)** — làm chậm lại một nhịp mà không cấm. Đối lập với *chặn cứng*, thứ
sẽ khiến người dùng gỡ cài đặt ngay và bị cấm ở [tầng Intent §4.3](01-intent.md).

**Send-risk** — một số thực trong khoảng `[0, 1]` trả lời đúng một câu hỏi: *"nếu gửi câu này đi, nó
có thể làm tổn thương ai đó không?"*. **Không phải** phân loại cảm xúc nhiều nhãn, không phải điểm
đánh giá con người. Đơn vị này là hợp đồng ổn định — đổi cách tính bên trong được, đổi ý nghĩa thì
không.

**Vùng mù (blind spot)** — những tình huống sản phẩm không thấy gì: bộ gõ tắt, đang ở chế độ tiếng
Anh, đang gõ trong ô mật khẩu, hoặc đang ở ứng dụng ngoài allow-list. Vùng mù phải được nói thẳng
với người dùng, không che giấu.

## Khái niệm nhận diện

**Con sóng `~`** — dấu ngã tiếng Việt, đồng thời là làn nước. Dấu ấn thị giác chủ đạo của sản phẩm.
Vừa báo "đây là bộ gõ Việt", vừa mang ẩn dụ mặt hồ.

**Mặt hồ tâm** — ẩn dụ gốc cho trạng thái tâm. Hồ lặng ứng với tâm tĩnh, hồ dậy sóng ứng với tâm
động. Cùng một mặt hồ, chỉ khác biên độ — không có mặt hồ "tốt" và mặt hồ "xấu".

**Biên độ (amplitude)** — tín hiệu **chính** biểu đạt trạng thái. Màu chỉ là tín hiệu phụ. Quy tắc:
mỗi mức phải đổi cả hình lẫn màu, để đọc được cả khi mù màu hoặc ở thanh menu đơn sắc.

**Gợn** — cách gọi trạng thái vượt ngưỡng nhạy cảm trong câu chữ hiển thị. Chọn từ này thay cho
"căng thẳng" hay "tiêu cực" vì nó mô tả mặt nước chứ không xếp loại con người.

**Thang cảm xúc năm mức** — An · Nhẹ · Gợn · Sóng · Cuộn. Dùng thang màu trung tính không bão hòa,
đậm dần. Cam thương hiệu **không xuất hiện** trong thang này; cam chỉ dành cho khoảnh khắc *con
người* như hơi thở hay lời mời, không dùng để mã hóa *trạng thái cảm xúc*.

**Mô tả, không phán xét** — nguyên tắc viết câu chữ. Nói về câu vừa gõ, không chụp mũ người gõ. So
sánh: "câu này nghe có thể làm tổn thương" là mô tả; "bạn đang giận" là phán xét.

## Khái niệm giao diện

**Nhật Ký Tâm** — màn nhật ký cảm xúc, nơi xem lại các mẫu đã ghi và ghi chú tay.

**Soi lại (reflection)** — màn đọc lại kho dữ liệu và hiện tóm tắt cuối ngày. Bước Reflect của vòng
lặp lõi.

**Dòng sông cảm xúc (emotion river)** — đồ thị biểu diễn các mẫu theo thời gian. Chấm **đặc** là
nhịp lấy mẫu tự động; vòng **rỗng** là lần người dùng tự thuật. Trục dọc là biên độ dao động, đọc
theo *khoảng cách tới đường giữa*, không theo lên hay xuống.

**Nhịp lấy mẫu (beat)** — chu kỳ gom mẫu, mặc định trùng nhịp chuông. Mỗi nhịp ghi đúng một mẫu là
trung bình các điểm trong nhịp. Không gõ thì không ghi mẫu — **không bịa dữ liệu**. Hai mẫu cách
nhau quá 1.5 lần nhịp thì đồ thị ngắt nét, vì quãng rời máy là quãng trống thật.

**Độ nhạy (sensitivity)** — một núm duy nhất đặt ngưỡng "thế nào là gợn" và độ dài chuỗi câu căng
làm chuông ngân. Núm này **không** đổi ngưỡng gác cổng — xem
[ADR-0006](03-decisions/ADR-0006-nguong-gac-cong-doc-lap.md).

**Chuông tỉnh thức (mindful bell)** — tiếng chuông ngân theo nhịp và theo chuỗi câu căng. Tắt chuông
là tắt **tiếng**, không tắt nhật ký — nhịp lấy mẫu vẫn chạy.

## Khái niệm kiến trúc

**Bộ não (core)** — phần C++ dùng chung mọi hệ điều hành: `core/engine` xử lý tiếng Việt,
`core/mood` xử lý lớp cảm xúc. Lỗi riêng của một hệ điều hành **không** được sửa ở đây.

**Vỏ (shell / platform)** — lớp tích hợp riêng từng hệ điều hành trong `platforms/`. Vỏ vẽ giao
diện, bắt sự kiện, xin quyền. Vỏ khác nhau có thể có tập tính năng khác nhau.

**Allow-list** — danh sách bundle identifier của các ứng dụng chat mà lớp gác cổng được phép hoạt
động. Chỉ thêm ứng dụng đã cài và xác minh định danh thật, không đoán.

**Hợp đồng (contract)** — một bất biến đang có hiệu lực mà mọi vỏ phải giữ, kiểm được bằng `grep`.
Khác với ADR: ADR ghi lại một lựa chọn trong quá khứ, hợp đồng ràng buộc code hiện tại. Xem
[tầng 04](04-contracts.md).

**Sổ bằng chứng (`TEST_MATRIX.md`)** — bảng hành vi → bằng chứng. Hành vi ghi `implemented` mà cột
bằng chứng để trống là một khoản nợ, không phải một việc đã xong.

**Sổ ma sát (`FRICTION-LOG.md`)** — nơi ghi lại mỗi chỗ phải suy diễn vì thiếu luật hoặc thiếu nguồn
sự thật. Đây là hàng đợi việc "nên viết luật tiếp theo", không phải nhật ký lỗi.

## Quy ước đặt tên

**Định danh tiếng Anh, hiển thị tiếng Việt.** Mọi thứ máy đọc — biến, hàm, tên file, khóa cấu hình,
cột dữ liệu — luôn tiếng Anh. Chỉ chữ hiện ra cho người dùng mới tiếng Việt. Chi tiết ở
[tầng 05](05-conventions.md).
