# Mindful Keyboard

> Bộ gõ Tiếng Việt giúp bạn gõ trong tỉnh thức — người gác cổng cảm xúc trước khi bạn gửi đi
> thứ 5 phút sau sẽ hối hận. macOS trước (công dân hạng nhất), rồi Windows → Android → Linux → iOS.

Đây là **repo sạch, đa nền tảng, đã rebrand** của `mindful-keyboard` — dựng lại từ bộ đang phát
triển ở repo gốc theo đúng cấu trúc đích trong `docs/AGENT-BRIEF.md` §3.2. Lõi gõ Tiếng Việt kế
thừa từ **[OpenKey](https://github.com/tuyenvm/OpenKey) của Mai Vũ Tuyên** (GPL v3) — xem
[`LICENSE`](LICENSE) và mục Ghi nhận nguồn bên dưới.

## Cấu trúc

```
mindful-key/
├── core/
│   ├── engine/     ← Bộ não OpenKey nguyên vẹn 100% (Telex/VNI/VIQR, bảng mã, macro...).
│   │                 KHÔNG sửa "mù" — mọi PR chạm vào đây phải kèm test ở tests/engine/.
│   └── mood/       ← MoodBuffer (gom từ→câu) + BreathingPause (hợp đồng "nhịp thở") — C++
│                     thuần, dùng chung mọi nền tảng, không phụ thuộc core/engine.
├── platforms/
│   ├── apple/      ← macOS (đầy đủ tính năng) + iOS/shared (chưa mở). XcodeGen: project.yml.
│   ├── windows/    ← vỏ Win32 gốc, mang sang chưa rebrand/chưa build trong monorepo này.
│   ├── android/    ← chưa có code, chỉ ghi chú lộ trình.
│   └── linux/      ← chỉ có README thượng nguồn, chưa có vỏ thật.
├── models/         ← coreml/onnx/tflite — spec cho bước thay lexicon bằng model sentiment
│                     thật (xem docs/SEND-RISK-MODEL-SPEC.md); chưa có model file nào.
├── brand/          ← Nhận diện NOW BRAND OS: SVG nguồn + export.sh xuất PNG/.icns.
├── docs/           ← Hiến chương, PRD, spec kỹ thuật, ghi chú riêng tư.
├── scripts/        ← build-dmg.sh (đóng gói ad-hoc), sign-and-notarize.sh (placeholder).
├── tests/engine/   ← Regression test core/engine (Telex→Unicode, 5/5).
└── .github/workflows/  ← CI: build macOS + regression engine.
```

## Build & chạy (macOS)

```bash
make generate   # xcodegen generate
make build      # generate + xcodebuild (Debug, ký ad-hoc)
make run        # build rồi mở app
make test       # regression engine (tests/engine)
make brand      # xuất lại icon/asset từ brand/svg/
```

Yêu cầu: Xcode + [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

## Trạng thái rebrand

- **Chuỗi hiển thị** (menu bar, About, NSAlert, tiêu đề cửa sổ): đã đổi "OpenKey" →
  "Mindful Keyboard". Tên class/hàm/biến/file kế thừa (`OpenKeyManager`, `OpenKeyCallback`,
  `vTempOffOpenKey`...) và bundle-id allow-list app chat (`com.vng.zalo`, `com.hnc.Discord`)
  **giữ nguyên** — đổi nhầm vỡ tương thích/logic gác cổng.
- **Bundle ID**: `vn.gnh.mindfulkey` (đề xuất, đổi từ `com.tuyenmai.openkey`). ⚠️ Đổi bundle ID
  nghĩa là macOS coi đây là app MỚI — người dùng cũ (nếu có) sẽ phải **cấp lại quyền
  Accessibility + Input Monitoring** trong System Settings. Nếu chủ dự án muốn giữ ID gốc
  hoặc chọn ID khác, sửa `PRODUCT_BUNDLE_IDENTIFIER` trong `platforms/apple/project.yml`.
- **OpenKeyHelper**: KHÔNG mang sang. Đây là code chết — `OpenKeyHelper/` trong dự án gốc chỉ
  còn là group thư mục + scheme cũ, không phải build target thật (chỉ 1 target `OpenKey` tồn
  tại trong `.xcodeproj` gốc), và lời gọi `SMLoginItemSetEnabled(@"com.tuyenmai.OpenKeyHelper", ...)`
  trong `AppDelegate.m` đang trỏ tới một helper app không hề được nhúng/build — no-op khi chạy.

## Ghi nhận nguồn & giấy phép

Lõi engine gõ tiếng Việt fork từ **[OpenKey](https://github.com/tuyenvm/OpenKey)** của
**Mai Vũ Tuyên** — xin ghi nhận và cảm ơn tác giả. OpenKey là GPL v3, nên `mindful-key`
**cũng là GPL v3** (copyleft kế thừa). Phần kế thừa (`core/engine/`) giữ nguyên; phần viết
thêm (`core/mood/`, `platforms/apple/macos/{Mood,Bell,Nudge,Reflection,SendGatekeeper}*`)
ghi rõ là dựa trên/mở rộng OpenKey. Credit hiển thị trong About (menu bar → Giới thiệu).

## Hiến chương

Mọi quyết định kỹ thuật/nhận diện quy chiếu `docs/AGENT-BRIEF.md`. Tự kiểm mọi UI:
*"Cái này đang mô tả hay đang phán xét?"* — phán xét thì bỏ.
