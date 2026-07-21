# Changelog

Theo [Keep a Changelog](https://keepachangelog.com/) và [SemVer](https://semver.org/).
Phiên bản lấy từ `version.env`.

## [0.4.3]

### Added

- **Windows: Giao diện Nudge tuỳ chỉnh (GDI+)** — hộp thoại nhắc tâm thay thế `MessageBox` gốc của Windows. Hộp thoại có nền bo góc mềm mại, hiển thị trực tiếp bên trên con trỏ văn bản, không tranh giành tiêu điểm (focus) gây gián đoạn.
- **Windows: Trải nghiệm đồng nhất** — Giao diện Cài đặt (Settings) và Khay hệ thống (Tray Popover) được đại tu hoàn toàn bằng GDI+, với font chữ riêng và ngôn ngữ thiết kế chung với bản macOS.

- **macOS: gác cổng gửi tin (màn Nhịp thở) nay bật/tắt riêng được** — công tắc "Gác cổng gửi tin
  (nhịp thở)" trong menu khay, mặc định BẬT. Tắt thì vẫn giữ nhật ký + con sóng (đó là phần "Nhắc
  tâm" riêng), chỉ ngừng chặn Enter lúc gửi. Thẻ "Ngay bây giờ" đổi chữ thành "Gác cổng đang tạm
  nghỉ" khi tắt — nói thật, không giấu.

### Changed

- **Windows: Đồng bộ cấu hình Core và UI** — Các tham số như Nhịp (vBellInterval), Độ nhạy (vBellSensitivity) và Trạng thái Chuông nay được đồng bộ theo thời gian thực hai chiều, giúp hiển thị Dòng sông chính xác với nhịp độ gõ của người dùng.

- **macOS: biểu đồ cảm xúc "Ngay bây giờ" sống động và thành thật hơn:**
  - Đầu sóng "bây giờ" nay làm mượt vài câu gần nhất và **tự lặng dần về phẳng lặng** sau vài phút
    ngừng gõ — hết cảnh cắm điểm cảm xúc cũ (có thể từ 2 tiếng trước) vào chỗ hiện tại.
  - Con sóng **hiện chấm trong vài phút đầu gõ** thay vì chờ cả nhịp chuông mới có 1 chấm (vệt điểm
    dày giữ trong bộ nhớ, KHÔNG lưu thêm xuống đĩa — nhật ký mã hoá vẫn nhịp thưa như cũ).
  - Trục thời gian: **3 tiếng quá khứ + 1 tiếng "tương lai để trống"**, "bây giờ" dời vào 3/4 bề
    ngang để đầu sóng có chỗ thở (trước đây dính sát mép phải, nửa chấm bị khung cắt). Khoảng tương
    lai chỉ có trục nét đứt, không vẽ nước giả.
  - Biểu đồ **tự vẽ lại mỗi phút khi cửa sổ đang mở** (tận dụng nhịp sẵn có, không thêm đồng hồ mới).

### Fixed

- **macOS: bản build tại máy thôi đề nhầm "0.1.0"** ở tiêu đề cửa sổ/About — nay `make build` đọc số
  thật từ `version.env` (project.yml kẹt "0.1.0" chỉ còn là fallback cho xcodebuild trần).

## [0.4.2] - 2026-07-18

Vá đường **cài lại** trên Windows — kịch bản đúng người dùng thật đã dính ở 0.3.0. Sinh từ một
cuộc rà soát có đối chứng (mỗi phát hiện được đọc lại tận mã nguồn trước khi tính là thật).

### Fixed

- **Windows: gỡ cài / cài đè lên bản đang chạy không còn bế tắc "file đang bị dùng"** — cửa sổ ẩn
  của app trước đây không phản hồi tín hiệu đóng của Windows (Restart Manager, dùng khi cài đè
  hoặc gỡ cài), nên bộ cài xin đóng app vào khoảng không rồi báo lỗi. Nay app đóng sạch đúng lúc
  được yêu cầu — gỡ hook bàn phím, xoá icon khay, thoát hẳn tiến trình.
- **Windows: bộ cài (Setup) và trình gỡ cài giờ NHẬN RA được app đang chạy** và chủ động xin đóng
  trước khi ghi đè/gỡ file, thay vì lặng lẽ đè lên file đang khoá.
- **Windows: mở lại app khi bản cũ đang treo không còn tự treo theo** — trước đây nếu bản đang
  chạy vì lý do gì đó không phản hồi được, việc mở lại sẽ chờ vô thời hạn; nay có giới hạn 3 giây.
- **Windows: chạy nhầm 2 bản cài đặt cùng lúc không còn giẫm chân nhau ghi file.**
- **Windows: bộ cài kèm theo văn bản giấy phép (GPL v3)** cạnh chương trình, đúng nghĩa vụ pháp lý
  kế thừa từ OpenKey — trước đây chỉ hiện lúc cài, không có bản lưu lại trên máy.

### Known limitation

- Máy **đang** kẹt bản 0.3.0 cũ (đã dính đúng sự cố này) sẽ **không** tự thoát khi cài bản 0.4.2
  đè lên — bản cũ không biết cơ chế đóng mới. Cần đóng tiến trình cũ một lần bằng tay (Task
  Manager) trước khi cài, sau đó mọi lần nâng cấp về sau đều tự động.

## [0.4.1] - 2026-07-18

### Added

- **Windows: nhận ra cả UniKey, EVKey, GoTiengViet đang chạy cùng lúc** (0.4.0 mới chỉ nhận ra
  OpenKey gốc) — hai bộ gõ cùng bắt phím sẽ giẫm lên nhau, chữ sai dấu mà không ai hiểu vì sao.
  Giờ có lời nhắc gọi đúng tên bộ gõ kia, để bạn tự chọn tắt bên nào; MindfulKey không tự tắt
  phần mềm của người khác. Tên tiến trình xác minh từ nguồn công khai, không đoán.

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
- **macOS: hết crash khi mở lúc bộ gõ khác đang chạy** (báo cáo 0.2.1, lỗi P0) — trước đây app tự
  nhường chỗ bằng cú tắt gọi quá sớm giữa lúc khởi động, chết không một lời. Nay thấy bộ gõ xung đột
  là tự tắt bên kia rồi chạy tiếp, không crash, không modal.
- **Windows: cài xong mở được thật** — bản 0.3.0 hỏi "cho ghi nhật ký cảm xúc?" NGAY GIỮA lúc khởi
  động, trước khi icon khay tồn tại: hộp thoại nằm sau các cửa sổ khác, app treo vô hình và giữ luôn
  file cài (không xoá được). Câu hỏi nay chỉ hiện khi bạn CHỦ ĐỘNG bật lớp cảm xúc.
- **Windows: mở được trên máy đang chạy OpenKey** — fork thừa hưởng nguyên tên lớp cửa sổ của
  OpenKey gốc nên MindfulKey nhìn thấy OpenKey lại tưởng "mình đang chạy rồi" và lặng lẽ thoát. Nay
  mang tên riêng; nếu OpenKey chạy cùng lúc sẽ có lời nhắc "hai bộ gõ đang giẫm phím nhau" (không tự
  tắt giùm).
- **Windows: lớp cảm xúc không đọc ô mật khẩu** — cờ che fail-closed qua UI Automation
  (`UIA_IsPasswordPropertyId` + `ES_PASSWORD`), hạ ngay khi đổi focus. Lớp cảm xúc vẫn TẮT mặc định.
- **Windows: không còn "chết câm"** — từ chối quyền quản trị (UAC) hoặc không tạo được icon khay giờ
  đều để lại một lời giải thích trước khi thoát, thay vì app biến mất không dấu vết.
- **iOS: bàn phím không còn rò rỉ bộ nhớ mỗi lần mở lại** — đồng hồ poll con sóng và bàn phím giữ
  chặt lẫn nhau nên không bao giờ được dọn; nay nắm hờ (weak) và tự dừng khi bàn phím ẩn.

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
