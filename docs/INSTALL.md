# Cài đặt / gỡ cài đặt (bản ad-hoc, tự dùng)

> Bản `.dmg` này ký **ad-hoc** (không phải Developer ID thật) — chỉ dùng để tự cài/test trên
> máy của chính bạn. Muốn chia sẻ cho người khác test (beta), cần hoàn tất Apple Developer
> Program + ký thật + notarize trước (xem `docs/PRD.md` §6 và roadmap Bước 9) — nếu không,
> Gatekeeper trên máy người nhận sẽ chặn với cảnh báo "không thể xác minh nhà phát triển".

## Đóng gói lại (khi có bản build mới)

```bash
xcodebuild -project "OpenKey/Sources/OpenKey/macOS/OpenKey.xcodeproj" -scheme OpenKey -configuration Release build
bash package-dmg.sh
```
Ra file `MindfulKeyboard_Beta.dmg` ở gốc repo. Script tự tìm `.app` mới nhất trong DerivedData của Xcode — không cần chỉ đường dẫn thủ công trong trường hợp thông thường.

## Cài đặt

1. Mở file `.dmg` (double-click).
2. Kéo `OpenKey.app` vào biểu tượng `Applications` trong cửa sổ hiện ra.
3. **Vì app ký ad-hoc**, lần đầu mở macOS sẽ cảnh báo "không thể xác minh nhà phát triển":
   - Cách 1: chuột phải (hoặc Control-click) vào `OpenKey.app` trong Applications → chọn **Open** → xác nhận **Open** lần nữa.
   - Cách 2: System Settings → Privacy & Security → cuộn xuống mục cảnh báo → bấm **Open Anyway**.
4. Cấp quyền **Accessibility** + **Input Monitoring** khi được hỏi (xem `docs/PRIVACY-NOTE.md` để hiểu vì sao cần).
5. Đồng ý (hoặc từ chối) bật nhật ký cảm xúc khi được hỏi lần đầu.

## Gỡ cài đặt

1. Thoát app (menu thanh trên cùng, hoặc Activity Monitor nếu cần).
2. Xóa `OpenKey.app` khỏi `/Applications`.
3. Xóa dữ liệu còn sót lại (tùy chọn, không bắt buộc):
   ```bash
   rm -rf ~/Library/Application\ Support/MindfulKeyboard
   defaults delete com.tuyenmai.openkey 2>/dev/null
   ```
   Lệnh `defaults delete` xóa cả trạng thái consent/cài đặt trong `NSUserDefaults`. Khóa mã hóa trong Keychain (nếu còn) có thể xóa qua Keychain Access.app, tìm mục "com.mindfulkeyboard.moodstore".

## Kiểm tra nhanh sau khi cài (đúng vòng lặp sản phẩm)

Xem mục "Hướng dẫn test" đã gửi trong phiên làm việc trước — gõ thử câu tiêu cực, thử gác cổng trong Zalo/Discord, xem màn soi lại.
