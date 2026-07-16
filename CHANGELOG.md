# Changelog

Theo [Keep a Changelog](https://keepachangelog.com/) và [SemVer](https://semver.org/).
Phiên bản lấy từ `version.env`.

## [Unreleased]

## [0.2.1] - 2026-07-16

Bản vá — không có tính năng mới.

### Fixed
- **Cửa sổ Cài đặt ▸ Chuông**: vệt chữ chồng lên nhau ở đỉnh tab. Khung cuộn giữ lại pixel cũ của tab vừa rời khi vừa đổi nội dung vừa nhảy vị trí cuộn; nay ép vẽ lại đúng vùng bằng `-setNeedsDisplayInRect:` (cách Apple khuyến nghị thay `copiesOnScroll`, đã bị bỏ tác dụng từ macOS 11).
- **Cửa sổ Cài đặt ▸ Chuông**: nội dung tự đổi chiều cao (bật "Đồng bộ Chế độ Tập trung", gõ giờ yên lặng không hợp lệ) mà khung pane và tiêu đề đứng yên — `onLayoutChanged` đã nối ở popover nhưng chưa từng nối ở cửa sổ Cài đặt.
- Popover bị cắt trên màn hình phụ; tính kích thước trước khi hiện để không rớt khỏi cuống.
- Ô "Nhịp" chuông không còn hiện số sai ở bản Debug.
- Icon "Chuông gió" / "Chuông reo" bị gắn ngược ảnh — tiếng phát ra vốn luôn đúng, chỉ hình nằm sai chỗ.
- Kho nhật ký cảm xúc không còn bị tạo trước khi người dùng đồng ý.
- Mẫu cảm xúc được ghi nốt khi thoát app, không mất mẫu cuối.

### Changed
- Tab Chuông ▸ "Bộ tiếng": 2 icon không được chọn nay mờ đi, icon đang chọn giữ nguyên độ đậm — nhìn là biết ngay đang chọn tiếng nào.

### Added
- Test E2E tầng dữ liệu đầu tiên cho mạch lấy mẫu theo nhịp chuông.
- Tài liệu một-nguồn về cơ chế sóng cảm xúc + danh mục cải tiến trước khi chuyển sang PhoBERT.

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
