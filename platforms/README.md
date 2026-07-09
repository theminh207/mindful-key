# Lộ trình nền tảng

Thứ tự **macOS ① → Windows ② → Android ③ → Linux ④ → iOS ⑤** (đề xuất — chủ dự án đổi được
tuỳ thực tế; xem AGENT-BRIEF §4 và `docs/OPENKEY-MAP.md` cho lý do đằng sau thứ tự này).

1. **macOS** — công dân hạng nhất, đang làm (`apple/macos/`). Full Access, CGEventTap +
   Accessibility, gác cổng gửi tin hoạt động đầy đủ.
2. **Windows** — vỏ Win32 kế thừa nguyên trạng ở `windows/win32/` (chưa rebrand, chưa build
   trong monorepo này). Cùng năng lực bắt phím toàn cục như macOS (Win32 keyboard hook) →
   gác cổng gửi tin khả thi tương tự.
3. **Android** — chưa có code (`android/README.md`). IME (Input Method Service) có thể đọc
   được luồng gõ toàn cục trong khung IME, tương thích tốt với mô hình gác cổng.
4. **Linux** — vỏ gần như trống ở thượng nguồn (`linux/linux-upstream/README.md`, chỉ có
   README, chưa có code thật). Năng lực bắt phím toàn cục **tuỳ Desktop Environment**
   (X11 dễ hơn, Wayland hạn chế input toàn cục vì lý do bảo mật) — cần khảo sát riêng theo
   DE mục tiêu trước khi cam kết tính năng gác cổng hoạt động y hệt macOS.
5. **iOS** — khuôn chật nhất (`apple/ios/README.md`). App Extension bàn phím SANDBOX
   nghiêm ngặt, không có low-level global keyboard hook → **gác cổng gửi tin bất khả thi**
   ở dạng hiện tại (Feature #1 cần thiết kế lại hoàn toàn cho iOS, có thể chỉ còn nhật ký +
   nhắc chánh niệm thụ động, không có "chặn Enter" xuyên app).

`core/engine` + `core/mood` dùng chung 100% cho mọi nền tảng ở trên — không fork logic gõ
hay logic gom câu cho riêng OS nào (Hiến chương §3).
