# Changelog

Theo [Keep a Changelog](https://keepachangelog.com/) và [SemVer](https://semver.org/).
Phiên bản lấy từ `version.env`.

## [Unreleased]

### Added
- Monorepo đa nền tảng, rebrand **Mindful Keyboard**: tách `core/engine` (bộ não OpenKey,
  nguyên vẹn 100% — audit `diff -r` rỗng so với bản OpenKey sạch), `core/mood` (MoodBuffer +
  BreathingPause), `platforms/apple` (macOS đầy đủ tính năng, iOS/shared chưa mở),
  `platforms/{windows,linux}` (vỏ gốc mang sang, chưa rebrand), `platforms/android` (chưa có
  code), `models/{coreml,onnx,tflite}` (spec, chưa có model file thật).
- `platforms/apple/project.yml` (XcodeGen) thay cho `.xcodeproj` commit tay.
- Token màu NOW BRAND OS trong `Assets.xcassets` + `BrandColors.h/.m`, áp vào overlay nhịp
  thở (gác cổng gửi tin) và icon các NSAlert chánh niệm.

### Changed
- Rebrand chuỗi hiển thị "OpenKey" → "Mindful Keyboard" trong menu bar, About, NSAlert, tiêu
  đề cửa sổ — giữ nguyên 100% tên class/hàm/biến/file (`OpenKeyManager`, `OpenKeyCallback`,
  `vTempOffOpenKey`...) và bundle-id allow-list app chat.
- `PRODUCT_BUNDLE_IDENTIFIER` đổi từ `com.tuyenmai.openkey` sang `vn.gnh.mindfulkey` (đề xuất
  — xem ghi chú trong `README.md` về việc cấp lại quyền Accessibility/Input Monitoring).

### Kept (không đổi)
- `LICENSE` (GPL v3) + credit **Mai Vũ Tuyên / OpenKey** trong README, About, storyboard.
- Toàn bộ lớp cảm xúc đã hoàn thiện ở bản `mindful-keyboard` gốc (gác cổng gửi tin, chuông
  data-driven, soi lại cuối ngày, kho nhật ký mã hoá) — mang sang nguyên vẹn, chỉ đổi vị trí
  thư mục + chuỗi hiển thị.

### Known gaps
- `platforms/windows`, `platforms/linux` chưa build/test trong monorepo này (vỏ gốc, chưa
  rebrand) — xem README riêng từng thư mục.
- Ký thật/notarize chưa làm (ad-hoc only) — chờ Apple Developer Program.
