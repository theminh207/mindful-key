# 07 — Glossary

> Từ điển thuật ngữ riêng của dự án. Tầng này tồn tại vì phần lớn khái niệm ở đây **nghe như tiếng
> Việt thường ngày nhưng mang nghĩa hẹp và bắt buộc**. Hiểu sai một từ ở đây thường dẫn tới một
> giao diện vi phạm [tầng Intent](01-intent.md) mà không ai kịp nhận ra.

## Khái niệm sản phẩm

**Nhịp gõ (typing cadence)** — tốc độ tay người dùng đang gõ, tính bằng [CPM](#cpm) trên một
[cửa sổ trượt](#cửa-sổ-trượt). Là **tín hiệu duy nhất** sản phẩm dùng. Đo bằng cách đếm thời điểm
các lần bấm phím; **không** đọc phím nào ra ký tự gì. Nhịp gõ nói về *tay*, không nói về *tâm* —
xem [Chuông là lời mời](#chuông-là-lời-mời-không-phải-kết-luận).

**CPM (characters per minute)** — ký tự mỗi phút, đơn vị đo nhịp gõ. Chọn CPM chứ **không** WPM vì
Telex/VNI gõ dấu tốn thêm phím, nên gom thành "từ" rồi đếm sẽ méo: cùng một tốc độ tay, câu nhiều
dấu ra số từ thấp hơn hẳn câu ít dấu. Đơn vị này là hợp đồng ổn định — đổi cách tính bên trong được,
đổi ý nghĩa thì không.

**Cửa sổ trượt (sliding window)** — quãng thời gian gần nhất được dùng để tính CPM, **mặc định 30
giây**. Ngắn hơn thì một tràng gõ dồn rồi nghỉ cũng đủ vượt ngưỡng; dài hơn thì chuông tới sau khi
nhịp đã lắng. Cửa sổ trượt liên tục theo thời gian thực, không phải chia ô cố định.

**Ngưỡng chuông (bell threshold)** — mức CPM mà vượt qua thì chuông ngân. **Thuộc về người dùng**,
đổi được bất cứ lúc nào; sản phẩm không tự quyết thế nào là "nhanh" cho người khác. Bốn mức:
`Nhanh 300` · `Rất nhanh 400` (mặc định) · `Cực nhanh 500` · `Tắt chuông`. Tên mức mô tả **nhịp
tay**, cấm mọi chữ quy về trạng thái tâm ("bình tĩnh", "mất kiểm soát"…). Chỗ nào hiện tên mức thì
**hiện kèm con số CPM**, để đọc ra ngay đây là phép đo chứ không phải lời nhận xét.

**Khoảng lặng giữa hai lần chuông (cooldown)** — thời gian tối thiểu bắt buộc phải trôi qua giữa
hai tiếng chuông, để chuông không thành tiếng ồn khi nhịp gõ dao động quanh ngưỡng. Vượt ngưỡng
trong lúc còn cooldown thì **không** ngân và **không** dồn lại ngân bù sau.

**Ma sát mềm (soft friction)** — làm chậm lại một nhịp mà không cấm. Đối lập với *chặn cứng*, thứ
sẽ khiến người dùng gỡ cài đặt ngay và bị cấm ở [tầng Intent §4.3](01-intent.md). Chuông là ma sát
mềm ở dạng thuần khiết nhất: nó ngân lên rồi thôi, phớt lờ được bằng cách gõ tiếp.

**Chuông là lời mời, không phải kết luận** — nguyên tắc diễn giải. Gõ nhanh **không luôn** có nghĩa
tâm đang động: có thể người dùng đang chép chính tả, đang gõ lại một đoạn đã nghĩ xong, hoặc đơn
giản là tay nhanh. Chuông mời để ý một cái, không tuyên bố điều gì về người gõ. Mọi câu chữ quanh
chuông phải giữ đúng khoảng cách này.

**Vùng mù (blind spot)** — những tình huống sản phẩm không đo được gì: bộ gõ tắt, đang gõ trong ô
mật khẩu, hoặc (trên iOS) người dùng đang dùng bàn phím khác. Vùng mù phải được nói thẳng với người
dùng, không che giấu.

## Khái niệm nhận diện

**Con sóng `~`** — dấu ngã tiếng Việt, đồng thời là làn nước. Dấu ấn thị giác chủ đạo của sản phẩm.
Vừa báo "đây là bộ gõ Việt", vừa mang ẩn dụ mặt hồ.

**Mặt hồ tâm** — ẩn dụ gốc cho trạng thái tâm. Hồ lặng ứng với tâm tĩnh, hồ dậy sóng ứng với tâm
động. Cùng một mặt hồ, chỉ khác biên độ — không có mặt hồ "tốt" và mặt hồ "xấu".

**Biên độ (amplitude)** — tín hiệu **chính** biểu đạt trạng thái, nay lấy nguồn từ nhịp gõ. Màu chỉ
là tín hiệu phụ. Quy tắc: mỗi mức phải đổi cả hình lẫn màu, để đọc được cả khi mù màu hoặc ở thanh
menu đơn sắc.

**Thang biên độ năm mức** — An · Nhẹ · Gợn · Sóng · Cuộn. Dùng thang màu trung tính không bão hòa,
đậm dần. Cam thương hiệu **không xuất hiện** trong thang này; cam chỉ dành cho khoảnh khắc *con
người* như hơi thở hay lời mời, không dùng để mã hóa mức đo.

**Gợn** — tên một mức trên thang biên độ, không phải một lời nhận xét. Chọn từ này thay cho "căng
thẳng" hay "tiêu cực" vì nó mô tả mặt nước chứ không xếp loại con người.

**Mô tả, không phán xét** — nguyên tắc viết câu chữ. Nói về **phép đo**, không chụp mũ người gõ. So
sánh: "nhịp gõ vượt mức bạn đặt" là mô tả; "bạn đang gõ quá nhanh" hay "bạn đang giận" là phán xét.
Chữ **"quá"** là dấu hiệu cảnh báo — nó hàm ý có một mức đúng do sản phẩm định đoạt, trong khi
ngưỡng là do chính người dùng đặt.

## Khái niệm giao diện

**Nhật Ký Tâm** — màn nhật ký, nơi xem lại các mẫu đã ghi và ghi chú tay.

**Soi lại (reflection)** — màn đọc lại kho dữ liệu và hiện tóm tắt cuối ngày. Bước Reflect của vòng
lặp lõi.

**Dòng sông nhịp gõ** — đồ thị biểu diễn các mẫu theo thời gian. Chấm **đặc** là nhịp lấy mẫu tự
động; vòng **rỗng** là lần người dùng tự thuật. Trục dọc là biên độ dao động, đọc theo *khoảng cách
tới đường giữa*, không theo lên hay xuống.

**Nhịp lấy mẫu (beat)** — chu kỳ gom mẫu. Mỗi nhịp ghi đúng một mẫu là trung bình các điểm trong
nhịp. Không gõ thì không ghi mẫu — **không bịa dữ liệu**. Hai mẫu cách nhau quá 1.5 lần nhịp thì đồ
thị ngắt nét, vì quãng rời máy là quãng trống thật.

**Chuông tỉnh thức (mindful bell)** — tiếng chuông ngân khi nhịp gõ vượt [ngưỡng](#ngưỡng-chuông-bell-threshold)
người dùng đặt. **Chỉ có âm thanh**: không khung nổi, không chặn phím, không hỏi han, không đòi bấm
gì. Tắt chuông là tắt **tiếng**, không tắt việc ghi nhận.

## Khái niệm kiến trúc

**Bộ não (core)** — phần C++ dùng chung mọi hệ điều hành: `core/engine` xử lý tiếng Việt,
`core/mood` xử lý lớp nhịp gõ và chính sách chuông. Lỗi riêng của một hệ điều hành **không** được
sửa ở đây.

**Vỏ (shell / platform)** — lớp tích hợp riêng từng hệ điều hành trong `platforms/`. Vỏ vẽ giao
diện, bắt sự kiện, xin quyền. Vỏ khác nhau có thể có tập tính năng khác nhau.

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

---

## Thuật ngữ đã nghỉ hưu

Ba khái niệm dưới đây từng là trung tâm sản phẩm và nay **không còn tồn tại**. Giữ lại tên ở đây để
người đọc code cũ hoặc ADR cũ tra ra ngay, khỏi tưởng mình đọc thiếu.

| Từ cũ | Nghĩa cũ | Thay bằng |
|---|---|---|
| **Send-risk** | Số thực `[0,1]` trả lời "gửi câu này đi có làm tổn thương ai không" — chấm điểm bằng cách **đọc nội dung** | [CPM](#cpm). Sản phẩm không đọc nội dung nữa. |
| **Gác cổng (send gatekeeper)** | Chặn tạm đúng lúc người dùng bấm gửi một câu điểm cao | Không có thay thế — [tầng Intent §5](01-intent.md) liệt kê đây là **non-goal** |
| **Nhịp thở (breathing pause)** | Hợp đồng `core/mood/BreathingPause.h` quyết định có hiện khung gác cổng không | Không có thay thế, gỡ theo gác cổng |
| **Allow-list** | Danh sách ứng dụng chat mà gác cổng được phép hoạt động | Không có thay thế — chuông ngân ở mọi nơi, không phân biệt ứng dụng |

Lý do đổi và đánh đổi đã chấp nhận:
[ADR-0013](03-decisions/ADR-0013-do-nhip-go-thay-doc-cam-xuc.md).
