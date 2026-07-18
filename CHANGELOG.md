# Changelog

Theo [Keep a Changelog](https://keepachangelog.com/) và [SemVer](https://semver.org/).
Phiên bản lấy từ `version.env`.

## [Unreleased]

## [0.4.0] - 2026-07-18

Đợt "trả nợ báo cáo lỗi 0.2.1" — xử nốt các mục P2/P3 còn treo sau khi 0.3.x đã vá P0/P1.

### Added

- **macOS: bắt thêm EVKey và GoTiengViet** vào lưới bộ gõ xung đột (trước chỉ hardcode OpenKey) —
  cùng luật tự-tắt-rồi-chạy-tiếp; bundle id xác minh từ Homebrew cask, không đoán. UniKey không có
  bản macOS chính thức nên không có gì để bắt.
- **macOS: menu "Báo lỗi / Góp ý…"** trong menu khay — mở thẳng trang GitHub Issues, người dùng gặp
  lỗi có chỗ báo ngay trong app (bài học từ báo cáo 0.2.1).

### Changed

- **`CFBundleVersion` nay tăng theo từng bản build** (đếm số commit git) thay vì đứng yên ở 1 —
  phân biệt được các bản build và dọn đường cho auto-update (Sparkle) sau này.
- **Sàn macOS nâng 10.15 → 13.0 cho đúng sự thật**: chưa từng test máy dưới 14.8.3, và dưới macOS 13
  tính năng "Bật cùng hệ thống" vốn đã chết im lặng (SMAppService cần 13+). Khai 10.15 là hứa suông
  (báo cáo 0.2.1 mục E).

### Fixed

- **macOS: không thể mở 2 bản MindfulKey song song nữa** (`LSMultipleInstancesProhibited`) — guard
  chống-chạy-trùng kế thừa từ OpenKey đã hỏng từ lúc fork đổi bundle id; mở lần 2 giờ kích hoạt bản
  đang chạy và hiện cửa sổ Cài đặt.
- **macOS: tắt "Bật cùng hệ thống" không còn bị app lật lại BẬT** — cửa sổ Cài đặt tắt login item
  nhưng không ghi vào sổ cũ (`RunOnStartup`), lúc mở app lần sau sổ cũ vẫn ghi "bật" nên app tự bật
  lại ngược ý người dùng (lỗi có sẵn từ trước, lộ ra khi review đợt này). Nay hai sổ luôn khớp.

## [0.3.0] - 2026-07-17

**Bản THỬ NGHIỆM cho Windows — chưa ai chạy thật lần nào.** Xem cảnh báo ở release notes.

### Added

- **Vỏ Windows biên dịch và chạy được** — lần đầu trong lịch sử repo. Trước đó chưa từng có một
  lần build thành công nào.
- **Lớp cảm xúc đủ 6 module trên Windows**: MoodWatch (chấm send-risk thay vì dán nhãn cảm xúc) ·
  gác cổng gửi tin (Feature #1) · chuông + nhắc gộp 1 mạch · nhật ký mã hoá (DPAPI, không SQLite) ·
  màn Soi lại · dòng sông cảm xúc (GDI+).
- **Chuông phát ĐÚNG 3 tiếng của dự án** (Chuông chùa/gió/reo) thay vì tiếng "ding" mặc định của
  Windows, có âm lượng riêng không đè lên app khác, và nhận tệp `.wav` cá nhân hoá.
- **Nhận diện thật trên Windows**: icon app + icon khay là con sóng `~` teal (trước là chữ "V" của
  OpenKey 2019), 4 icon tab, và `StatusAlert` — sóng biên độ cao khi tâm đang động (asset brand
  vẽ sẵn từ lâu, cả macOS lẫn Windows đều chưa từng nối).
- **Bộ cài `.exe`** (Inno Setup) + CI Windows build Debug/Release mỗi lần push.

### Changed

- **`core/mood` nay có 6 module dùng chung** cả 3 vỏ. Năm mảnh logic từng kẹt trong vỏ macOS/iOS
  đã gom về: bảng lexicon send-risk, bảng màu brand, câu chữ kể hình dạng ngày, phân loại hình
  dạng ngày + rổ câu hỏi, và đường cong biên độ sóng.
- Tên tệp chạy: `OpenKey64.exe` → `MindfulKey.exe`.
- Nút "Kiểm tra bản mới" nay mở trang Releases, thay vì hỏi repo của OpenKey gốc rồi chạy một
  updater mà bộ cài không kèm.

### Fixed

- **Lexicon send-risk từng trôi lệch giữa macOS và iOS**: `"tôi giận."` chấm 0.33 trên macOS
  nhưng 0.00 trên iOS — lớp cảm xúc iOS mù với mọi câu kết thúc bằng dấu câu. Nay 1 bản dùng chung.
- Bản Windows từng khoe "Phiên bản 2.0.5.0" — số của OpenKey, không phải của dự án này.
- Gỡ code gọi mạng cuối cùng khỏi vỏ Windows: app **không còn khả năng** kết nối mạng.

### Security

- **Lớp cảm xúc TẮT MẶC ĐỊNH trên Windows.** `WH_KEYBOARD_LL` thấy mọi phím kể cả ô mật khẩu, và
  Windows không có cơ chế nào chặn hook như Secure Input Mode của macOS. Bật là hành động có ý
  thức, kèm cảnh báo nói thẳng giới hạn này. Đang vá bằng UI Automation.

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
