# SCAMPER — Bảng điều khiển macOS (control panel) mindful-key

> Nguồn bối cảnh: `brainstorm-objective-macos-panel.md`. Chủ đề: hiện đại hóa control panel
> (`platforms/apple/macos/ViewController.m` + `Main.storyboard`), 3 mục tiêu — (a) bố cục
> card/section thay 4-tab checkbox, (b) chuông chánh niệm cấu hình được, (c) hiển thị rõ
> trạng thái/ngưỡng nhận diện cảm xúc (gác cổng). Tham chiếu phong cách: app "Haynoi"
> (bố cục, KHÔNG copy tính năng).
>
> **Ràng buộc bất khả xâm phạm áp dụng cho mọi ý tưởng bên dưới:** không đèn đỏ/xanh-lá,
> không mặt cười/mếu, không emoji chấm điểm, không gamification; trạng thái CHỈ mã hóa
> bằng biên độ sóng `~` + sắc độ trung tính không bão hòa; cam `#FF7A1A` chỉ dùng cho CTA;
> Feature #1 (`SendGatekeeperMac`) không bị lu mờ; mọi ý tưởng liên quan hiển thị cảm xúc
> đã tự kiểm "mô tả hay phán xét?" trước khi đưa vào — ý tưởng nào ngả sang phán xét/giám
> sát đã bị loại khỏi danh sách này.

---

## S — Substitute (Thay thế)

**S1. Card dọc cuộn thay 4-tab ngang**
Thay 4 tab Primary/Macro/System/Info bằng 1 danh sách card dọc có thể cuộn, mỗi card 1 icon + tiêu đề, bấm để mở rộng tại chỗ thay vì chuyển tab.
Giá trị: giảm việc phải nhớ "mình đang ở tab nào", đúng flow xem-lướt của Haynoi.
Mức độ: Incremental.

**S2. Toggle pill-switch thay checkbox vuông**
Thay checkbox/radio kiểu form cũ bằng toggle switch bo tròn (teal khi bật, xám khi tắt) — không dùng cặp màu xanh lá/đỏ.
Giá trị: nhất quán ngôn ngữ hệ điều hành macOS hiện đại, giảm cảm giác "form web cũ".
Mức độ: Incremental.

**S3. Slider ngưỡng bằng lời thay vì con số**
Thay ô nhập số "ngưỡng câu căng liên tiếp" bằng slider có nấc, nhãn mô tả bằng lời ("nhạy hơn" ↔ "để yên lâu hơn") thay vì chỉ hiện số 3/5/7.
Giá trị: dễ hiểu với user không rành kỹ thuật, giảm cảm giác đang "cấu hình tham số".
Mức độ: Incremental.

---

## C — Combine (Kết hợp)

**C1. Gộp trạng thái + ngưỡng + số lần gác cổng vào 1 card đầu trang**
Đưa "gác cổng đang bật", ngưỡng hiện tại, và số lần gác cổng hôm nay vào chung 1 card đặt đầu tiên trong panel — giống vị trí avatar/status ở Haynoi nhưng cho Feature #1.
Giá trị: biến tính năng vương miện thành điểm neo đầu tiên user thấy khi mở panel, đúng yêu cầu "không bị đánh đổi ưu tiên".
Mức độ: Breakthrough (đổi cấu trúc thông tin ưu tiên).

**C2. "Trung tâm nhịp điệu" — gộp cấu hình chuông + gác cổng**
Gộp cấu hình chuông và cấu hình gác cổng vào 1 section chung vì cả hai cùng phản ứng với cùng khái niệm gốc "số câu căng liên tiếp" — chỉ cấu hình ngưỡng 1 lần, dùng chung cho cả hai.
Giá trị: tránh user cấu hình trùng ở 2 nơi khác nhau cho cùng 1 khái niệm.
Mức độ: Incremental.

**C3. Giờ yên lặng đồng bộ với Focus/DND của macOS**
Khi macOS đang ở chế độ Tập trung/Không làm phiền, tự áp giờ yên lặng cho chuông theo, cộng thêm khung giờ tùy chỉnh riêng nếu user muốn.
Giá trị: tận dụng hạ tầng OS có sẵn, không bắt user thiết lập trùng lặp.
Mức độ: Breakthrough (tích hợp hệ thống sâu hơn mức UI đơn thuần).

---

## A — Adapt (Thích ứng)

**A1. Progress bar → dải biên độ (không phải % hoàn thành)**
Mượn hình thức "progress bar ngang" của Haynoi nhưng đổi ngữ nghĩa: không phải thanh tiến độ hướng tới đích, mà là dải hiển thị biên độ sóng dao động qua ngày — không có điểm "100% hoàn thành".
Giá trị: giữ hình thức quen mắt nhưng tránh ngữ nghĩa "đạt chỉ tiêu" dễ trôi dần thành gamification.
Mức độ: Incremental (đã tự kiểm: chỉ hiển thị dao động, không xếp hạng tốt/xấu).

**A2. Status dot chỉ dùng cho trạng thái kỹ thuật, không dùng cho cảm xúc**
Mượn mẫu "dot cạnh avatar" (online/offline) của Haynoi để báo bộ gõ đang bật/tắt tiếng Việt — cố tình KHÔNG dùng dot màu này cho trạng thái cảm xúc, tách bạch 2 loại thông tin.
Giá trị: tận dụng đúng chỗ 1 affordance quen thuộc, ngăn nó bị lạm dụng thành mã màu cảm xúc (điều bị cấm).
Mức độ: Incremental.

**A3. Action group rõ ràng cho khối gác cổng**
Mượn cấu trúc "nhóm action rõ ràng" của Haynoi: gom 3 hành động liên quan gác cổng vào 1 nhóm — "Xem ngưỡng hiện tại / Điều chỉnh độ nhạy / Xem lịch sử hôm nay" — thay vì rải rác trong tab System cũ.
Giá trị: giảm số bước tìm kiếm, gom hành động liên quan về 1 chỗ.
Mức độ: Incremental.

---

## M — Modify/Magnify (Điều chỉnh/Phóng đại)

**M1. Phóng đại card gác cổng thành card lớn nhất, trên cùng**
Card "trạng thái gác cổng" chiếm toàn bộ chiều rộng panel, đặt trên cùng; các card khác (chuông, macro, hệ thống) nhỏ hơn, xếp dưới — tạo phân cấp thị giác rõ ràng.
Giá trị: bảo vệ ưu tiên sản phẩm bằng chính bố cục, không chỉ bằng lời hứa.
Mức độ: Breakthrough.

**M2. Dải sóng động làm "đường chân trời" chủ đạo của panel**
Phóng đại sóng `~` từ 1 icon nhỏ tĩnh thành 1 dải sóng chạy dọc chiều rộng panel, biên độ thay đổi chậm theo dữ liệu thật — trở thành yếu tố nhận diện chủ đạo của toàn control panel.
Giá trị: tăng nhận diện thương hiệu qua chính ẩn dụ chánh niệm, không cần thêm màu.
Mức độ: Breakthrough — **lưu ý rủi ro**: chuyển động phải chậm/mượt; nếu nhanh/giật sẽ đọc như cảnh báo nhấp nháy, ngả sang phán xét — cần tự kiểm lại ở bước thiết kế chi tiết.

**M3. Thu nhỏ cấu hình chuông về 1 slider 3 nấc + nút "tùy chỉnh nâng cao"**
Rút gọn 3 control riêng (số câu, âm lượng, giờ) thành 1 slider "Nhạy — Vừa — Ít nhạy" cho đa số user, ẩn 1 nút "Tùy chỉnh nâng cao" bên dưới cho ai muốn chỉnh sâu.
Giá trị: giảm tải nhận thức cho phần đông, vẫn giữ chi tiết cho người cần.
Mức độ: Incremental.

---

## P — Put to other use (Dùng vào việc khác)

**P1. Card trạng thái gác cổng làm lối tắt mở "Soi lại hôm nay"**
Bấm vào card trạng thái gác cổng (vốn chỉ để xem) sẽ mở luôn ReflectionScreen — biến control panel thành cửa ngõ dẫn tới thực hành chánh niệm sâu hơn, không chỉ là bảng cấu hình khô khan.
Giá trị: nối liền 2 tính năng đang tách rời thành 1 hành trình.
Mức độ: Incremental.

**P2. Tái dùng ngưỡng câu căng để "báo trước" bằng sóng ngay trong panel**
Dùng lại đúng 1 con số ngưỡng (vốn để kích hoạt chuông) cho mục đích thứ hai: khi gần chạm ngưỡng, dải sóng trong panel (nếu đang mở) đổi biên độ nhẹ như một cách báo trước không cần rung chuông.
Giá trị: tái dùng logic có sẵn, không tạo thêm khái niệm cấu hình mới.
Mức độ: Incremental.

**P3. "Account row" cuối trang → cam kết riêng tư**
Dùng vị trí "hàng account cuối trang" của Haynoi (vốn cho thông tin tài khoản/đăng xuất) để đặt cố định dòng cam kết riêng tư ngắn + link chính sách, thay vì để trôi nổi trong tab Info cũ.
Giá trị: tăng minh bạch, "riêng tư mặc định" luôn hiện diện thay vì giấu trong submenu.
Mức độ: Incremental.

---

## E — Eliminate (Loại bỏ)

**E1. Bỏ hẳn 4-tab, chuyển thành 1 trang cuộn dọc duy nhất**
Xóa khái niệm "tab đang chọn"; toàn bộ control panel là 1 trang cuộn, chia section bằng divider mảnh.
Giá trị: bớt 1 tầng điều hướng không cần thiết cho 1 bảng cấu hình vốn không quá nhiều mục.
Mức độ: Breakthrough.

**E2. Bỏ mọi con số "đếm dồn" kiểu streak-ẩn**
Dù dữ liệu có sẵn, không hiển thị bất kỳ con số đếm liên tiếp nào (vd "căng thẳng X ngày liên tiếp") — vì loại số này rất dễ trôi thành streak trá hình dưới vỏ bọc "thống kê".
Giá trị: phòng ngừa vi phạm hiến chương ẩn trước khi nó lọt vào UI.
Mức độ: Incremental về mặt UI, nhưng quan trọng về governance.

**E3. Bỏ label kỹ thuật "threshold/ngưỡng gác cổng" khỏi mặt UI chính**
Chỉ giữ thuật ngữ kỹ thuật trong tooltip/phần nâng cao; mặt trước chỉ dùng câu quan sát ("Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi").
Giá trị: giảm cảm giác bị 1 hệ thống chấm điểm giám sát, đúng tinh thần "mô tả không phán xét".
Mức độ: Incremental.

---

## R — Reverse (Đảo ngược)

**R1. Đảo thứ tự: trạng thái hiện tại trước, cấu hình sau**
Thay vì mô hình form truyền thống (điền cấu hình xong mới thấy kết quả), hiển thị TRẠNG THÁI HIỆN TẠI (sóng hôm nay ra sao) trước tiên, các nút cấu hình xếp bên dưới.
Giá trị: "quan sát trước, hành động sau" — tinh thần chánh niệm thấm vào chính cấu trúc thông tin, không chỉ vào 1 tính năng riêng lẻ.
Mức độ: Breakthrough.

**R2. Đảo vai trò chuông: thêm chế độ "bị động"**
Bên cạnh chuông chủ động rung để nhắc, thêm lựa chọn chuông "bị động" — chỉ hiện thông tin khi user tự mở control panel, không tự rung nếu user không mở app trong ngày.
Giá trị: trao quyền chủ động hoàn toàn cho user muốn giảm thiểu gián đoạn.
Mức độ: Incremental (thêm 1 mode tùy chọn, không thay thế cơ chế hiện có).

**R3. Đảo quyền hiển thị số liệu: mặc định ẩn định lượng**
Thay vì luôn hiện số liệu (số lần gác cổng, biên độ...) mỗi lần mở panel, mặc định chỉ hiện sóng định tính; số liệu định lượng trở thành tùy chọn phải BẬT thêm.
Giá trị: tôn trọng user nhạy cảm với việc tự đo lường/theo dõi bản thân, đúng tinh thần "không đo để so sánh".
Mức độ: Breakthrough.

---

## Top 3 ý tưởng nổi bật nhất

1. **E1 — Bỏ 4-tab, chuyển thành 1 trang cuộn dọc theo section.** Đây là nền tảng bố cục cho mọi ý tưởng khác trong danh sách; giải quyết trực tiếp mục tiêu (a) và mở đường cho card/section hiện đại kiểu Haynoi.
2. **C1 — Gộp trạng thái/ngưỡng/số lần gác cổng vào 1 card đầu trang.** Trực tiếp bảo vệ Feature #1 (gác cổng gửi tin) khỏi bị lu mờ — đúng ràng buộc bất khả xâm phạm quan trọng nhất trong 3 mục tiêu, đồng thời giải quyết mục tiêu (c).
3. **R1 — Đảo thứ tự "quan sát trước, cấu hình sau".** Ý tưởng breakthrough duy nhất đưa tinh thần chánh niệm vào chính kiến trúc thông tin của panel (không chỉ vào 1 tính năng), là nguyên tắc tổ chức có thể áp dụng xuyên suốt cả 3 mục tiêu.
