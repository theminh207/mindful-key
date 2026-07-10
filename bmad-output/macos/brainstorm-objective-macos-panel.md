# Brainstorm Objective — Bảng điều khiển macOS (control panel) hiện đại hóa

> **Lưu ý scope:** `bmad-output/project-context.md` hiện đang khoá cho dự án **Windows Port**.
> Phiên brainstorm này là một CHỦ ĐỀ KHÁC (macOS control panel), không thuộc luồng quyết
> định Windows Port. Artifact của phiên này dùng hậu tố `-macos-panel` để không lẫn vào
> `decision-log.md` / `brainstorming-report.md` chính của Windows Port. Chủ dự án cần
> quyết định sau: gộp vào 1 bmad-output chung hay tách workspace riêng cho sáng kiến này.

## Chủ đề
Cải tiến "Bảng điều khiển" (control panel) của app **mindful-key** trên macOS —
`platforms/apple/macos/ViewController.m` + `Main.storyboard`.

## Bối cảnh thật (đã khảo sát code)
- Control panel hiện tại kế thừa gần nguyên trạng từ OpenKey gốc: 4 tab
  (Primary/Macro/System/Info) toàn checkbox/radio kiểu form cũ. Không có section
  riêng cho mood (cảm xúc) hay chuông.
- Chuông (`BellMac.mm:51`) hardcode `NSUserNotificationDefaultSoundName` — không có UI
  chọn âm thanh, chỉnh volume, hay chỉnh ngưỡng "số câu căng liên tiếp" trước khi rung
  (ngưỡng hiện cứng trong code, xem `NudgeCoordinatorMac`).
- Nhận diện cảm xúc chỉ lộ qua 1 toggle phẳng trong menu bar ("Bật Nhắc tâm (cảm xúc)")
  + màn "Soi lại hôm nay" cuối ngày. Không có nơi nào trong control panel để xem/cấu
  hình độ nhạy, ngưỡng gác cổng (`SendGatekeeperMac`), hay xem trạng thái hiện tại.
- Ảnh tham chiếu phong cách: app "Haynoi" (bên thứ 3, KHÔNG liên quan sản phẩm) — card
  bo góc hiện đại, avatar + status dot, divider mảnh phân nhóm, progress bar ngang,
  nhóm action rõ ràng, hàng account cuối. Đây là kiểu bố cục menu-bar panel hiện đại
  người dùng muốn tham khảo, KHÔNG phải copy tính năng.

## 3 mục tiêu cụ thể
1. Bố cục hiện đại hơn: card/section thay tab-checkbox cũ.
2. Chuông chánh niệm CẤU HÌNH ĐƯỢC ngay trong control panel (âm thanh, volume, ngưỡng
   số câu căng, giờ yên lặng...).
3. Nhận diện cảm xúc RÕ RÀNG HƠN: có nơi xem trạng thái/ngưỡng gác cổng hiện tại,
   không chỉ ẩn trong menu toggle.

## Ràng buộc bất khả xâm phạm (HIẾN CHƯƠNG §2.2/2.3 — không thương lượng)
- KHÔNG đèn đỏ/xanh-lá mã hóa cảm xúc, KHÔNG mặt cười/mếu, KHÔNG emoji chấm điểm,
  KHÔNG gamification (streak/điểm/huy hiệu).
- Mã hóa trạng thái CHỈ dùng biên độ sóng `~` + sắc độ TRUNG TÍNH KHÔNG BÃO HÒA
  (xanh-nước/xám-đá). Cam bão hòa CHỈ cho CTA/brand chrome, KHÔNG cho gradient cảm xúc.
- Palette NOW BRAND OS: Teal `#1D7C91` (chrome), Orange `#FF7A1A` (CHỈ CTA), nền
  `#F8F8F8`, card trắng, chữ `#2A2A2A`/`#666666`, font Montserrat (heading) + Inter
  (body), bo góc 16px card.
- Copy "quan sát không phán xét" (vd "Mặt hồ đang gợn sóng"), không copy khiển trách.
- Feature #1 (gác cổng gửi tin — `SendGatekeeperMac`) là tính năng vương miện — không
  bị các cấu hình mới (chuông, mood display) làm lu mờ hay đánh đổi độ ưu tiên.
- Riêng tư mặc định: không gửi nội dung gõ đi đâu; mọi cấu hình mới vẫn chạy on-device.

## Kỹ thuật brainstorm áp dụng
1. **SCAMPER** trên control panel hiện tại — biến thể bố cục/tính năng.
2. **Six Thinking Hats** — đánh đổi hiện-đại-hoá vs. tôn trọng hiến chương (rủi ro,
   cảm xúc, logic, sáng tạo, quy trình, lạc quan).
3. **Reverse Brainstorming** — "làm sao để bảng điều khiển mới VI PHẠM hiến chương
   hoặc khiến user thấy bị phán xét/theo dõi?" rồi đảo ngược thành nguyên tắc phòng ngừa.

Mỗi ý tưởng liên quan tới hiển thị cảm xúc PHẢI tự kiểm: "mô tả hay phán xét?" —
phán xét thì loại khỏi báo cáo cuối.
