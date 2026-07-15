# Changelog

Theo [Keep a Changelog](https://keepachangelog.com/) và [SemVer](https://semver.org/).
Phiên bản lấy từ `version.env`.

## [Unreleased]

## [0.2.0] - 2026-07-15

### Added
- Giao diện **Popover 3 tab** (Hôm nay · Chuông · Bộ gõ) hiện đại, gom gọn các card tùy chọn.
- Khung cuộn **NSScrollView** cho phần nội dung chính của Popover, cố định Header và Footer.
- **Cấu hình phím tắt (Hotkeys)** nhanh trực tiếp từ giao diện cho tính năng bật/tắt tiếng chuông (mặc định `⌥⌘B`) và bật/tắt tiếng Việt (mặc định `⌥Z`).
- Hộp thoại xin quyền **Notification** trên macOS lúc khởi động để bảo đảm chuông hoạt động đúng.
- Custom brand assets: các file âm thanh và biểu tượng chuông mới (`Chuông chùa`, `Chuông gió`, `Chuông reo`).
- Monorepo đa nền tảng, rebrand **Mindful Keyboard**: tách `core/engine` (bộ não OpenKey, nguyên vẹn 100%), `core/mood` (MoodBuffer + BreathingPause), `platforms/apple` (macOS đầy đủ tính năng, iOS/shared chưa mở), `platforms/{windows,linux}` (vỏ gốc mang sang, chưa rebrand).
- `platforms/apple/project.yml` (XcodeGen) thay cho `.xcodeproj` commit tay.
- Token màu NOW BRAND OS trong `Assets.xcassets` + `BrandColors.h/.m`.

### Changed
- Dời Sensitivity Card (Độ nhạy nhận diện) sang tab Hôm nay để giao diện cân đối hơn.
- Rebrand chuỗi hiển thị "OpenKey" → "Mindful Keyboard" trong menu bar, About, NSAlert, tiêu đề cửa sổ.
- `PRODUCT_BUNDLE_IDENTIFIER` đổi từ `com.tuyenmai.openkey` sang `vn.gnh.mindfulkey`.

### Fixed
- Lỗi đồng bộ Giờ yên lặng: người dùng chỉnh giờ trên giao diện sẽ lưu ngay lập tức vào bộ nhớ mà không cần khởi động lại.

### Kept (không đổi)
- `LICENSE` (GPL v3) + credit **Mai Vũ Tuyên / OpenKey** trong README, About, storyboard.

### Known gaps
- `platforms/windows`, `platforms/linux` chưa build/test trong monorepo này (vỏ gốc, chưa rebrand) — xem README riêng từng thư mục.
- Ký thật/notarize chưa làm (ad-hoc only) — chờ Apple Developer Program.
