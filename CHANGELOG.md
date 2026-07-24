# Changelog

Theo [Keep a Changelog](https://keepachangelog.com/) và [SemVer](https://semver.org/).
Phiên bản lấy từ `version.env`.

## [0.4.24]

Đợt "Nhật Ký Tâm" phần 3 — macOS (`docs/JOURNAL-NAV-FEEDBACK.md`). Hoàn tất H4 trên cả 2 nền.

### Added

- **macOS: mục nav "Nhật Ký Tâm"** (ngay dưới "Hôm nay") trong cửa Cài đặt — hiện danh sách **đầy đủ**
  các dòng đã viết (ngày + câu hỏi hôm đó + chữ), cuộn được. Enum thêm section mới ở cuối + nav dựng
  theo thứ-tự-hiển-thị (không đánh số lại 5 section cũ, tránh vỡ nav). Link "Những dòng đã viết →"
  trong màn Soi lại vẫn giữ song song.

## [0.4.23]

Đợt "Nhật Ký Tâm" phần 2 — Windows (`docs/JOURNAL-NAV-FEEDBACK.md`).

### Added

- **Windows: mục nav "Nhật Ký Tâm"** (ngay dưới "Hôm nay") trong cửa Cài đặt — hiện các dòng đã viết:
  xem trước 5 dòng gần nhất (ngày + chữ), "Xem tất cả (N) →" mở cửa sổ cuộn đầy đủ. Link "Những dòng
  đã viết →" trong màn Soi lại vẫn giữ (H4). Dùng bảng thứ-tự-hiển-thị để mục mới đứng thứ 2 mà không
  đánh số lại các pane cũ.

> macOS "Nhật Ký Tâm" sẽ ở bản kế (v0.4.24) — nav macOS khớp cứng storyboard, làm riêng cho chắc.

## [0.4.22]

Đợt "Nhật Ký Tâm" phần 1 (`docs/JOURNAL-NAV-FEEDBACK.md`) — nghiệm thu tay v0.4.21. (Phần 2 = mục
nav "Nhật Ký Tâm" sẽ ở bản sau.)

### Added

- **Dữ liệu mẫu "1 tuần"** trong công cụ Thử nghiệm — bộ seed nay có 3 mốc **12 giờ / 1 tuần / 30
  ngày** trên **CẢ Windows lẫn macOS** (để test biểu đồ Ngày/Tuần/Tháng) (H2).
- **macOS: công cụ Thử nghiệm hiện ở bản Release** (trước chỉ Debug) — bơm dữ liệu mẫu để xem biểu đồ
  trên bản đã cài, giống Windows. Nằm trong submenu "Thử nghiệm". (⚠️ ẩn/bỏ trước 1.0.)
- **Màn Soi lại (Windows): thêm dòng chân trang** "Xử lý trên máy · Câu hỏi mỗi ngày một khác · Không
  điểm số, không chuỗi ngày" (đồng bộ macOS) (H3).

## [0.4.21]

### Fixed

- **Nút "Kiểm tra bản mới" báo nhầm "đang dùng bản mới nhất"** dù đã có bản mới. Updater hỏi endpoint
  GitHub `/releases/latest` — endpoint này **cố ý bỏ qua prerelease**, mà mọi bản beta của mình đều là
  prerelease → nó trả về bản full-release cũ (v0.4.13) nên luôn tưởng đã mới nhất. Nay đọc `/releases`
  (gồm prerelease, phần tử đầu = mới nhất) + `ExtractTagName` chịu được khoảng trắng trong JSON GitHub.
  ⚠️ **Bản đã cài (≤ v0.4.20) mang updater hỏng** nên phải cài tay MỘT LẦN lên v0.4.21; từ đó nút tự
  cập nhật mới chạy đúng cho các bản sau.

## [0.4.20]

Đợt "đồng bộ Cài đặt↔Popover + phím tắt" (`docs/SYNC-HOTKEY-FEEDBACK.md`) — nghiệm thu tay v0.4.19.

### Fixed

- **Phím tắt bật/tắt tiếng Việt đã hoạt động** — mặc định cũ nhét mã phím Mac (0x06) nên bấm không
  ăn trên Windows; nay **Ctrl + Alt + Z** (VK_Z=0x5A), tự sửa cho cả máy đã cài bản cũ (G1).
- **Màn Soi lại:** khung sóng không còn rỗng khi chưa có dữ liệu (vẫn hiện trục Sáng·Trưa·Chiều·Tối);
  câu quan sát + câu hỏi + thẻ Nuôi dưỡng đo chiều cao thật nên hết cắt chữ / lệch dòng (G3).

### Added / Changed

- **Phím tắt hiện cạnh "Gõ tiếng Việt"** (popover + Cài đặt), đọc từ cấu hình thật (G1).
- **Đồng bộ Cài đặt ↔ Popover:** tab Chuông dùng "30 / 60 / Tùy chỉnh + stepper" như popover (thay
  "Nhanh/Vừa/Chậm") (G2a); tab Hôm nay thêm toggle "Ngay bây giờ / Hôm nay" + link "Soi lại hôm nay →" (G2b).

## [0.4.19]

Đợt "màn Soi lại + nhật ký viết tay" (`docs/REFLECTION-FEEDBACK.md`) — nghiệm thu tay v0.4.18.

### Added

- **Màn Soi lại (đại tu theo macOS):** 3 nhịp **Nhận ra / Soi / Nuôi dưỡng** — sóng cả ngày trong
  thẻ (Sáng·Trưa·Chiều·Tối), câu quan sát + dòng gác cổng, câu hỏi phản chiếu, **ô ghi một dòng cho
  hôm nay**, thẻ gợi ý nhẹ + link "Chỉnh chuông quanh Nh →" (F4/F5).
- **Nhật ký "Những dòng đã viết":** lưu chữ bạn viết trong ô Soi lại — **mã hoá tại chỗ** (`notes.enc`,
  DPAPI), hỏi đồng ý riêng đúng lúc bạn gõ dòng đầu, không bao giờ chạy máy đọc cảm xúc lên chữ đó.
  Cửa sổ đọc lại (ngày · câu hỏi hôm đó · chữ bạn viết), cuộn được (F5).
- **Tab Chuông:** dòng **"Dự kiến reo lúc HH:MM (còn N phút)"** ngay dưới "Bật chuông tỉnh thức" (F3).
- **Menu khay "Thử nghiệm":** bơm dữ liệu mẫu **12 giờ** (xem sóng hôm nay) / **30 ngày** (xem nhật ký),
  và "Xoá dữ liệu mẫu" — công cụ thử, dữ liệu đánh dấu riêng, gỡ sạch được (F6).

### Changed

- **Tab Chuông:** gỡ nút "Chọn tiếng .wav của bạn…" thừa (icon nốt nhạc đã mở chọn .wav) (F1); giãn
  vùng khung giờ yên lặng cho rõ khỏi tiêu đề (F2).

## [0.4.18]

Đợt "cửa Cài đặt bắt kịp macOS" (`docs/CONTROL-PANEL-FEEDBACK.md`).

### Added

- **Tab Chuông:** bấm icon nốt nhạc cũng mở chọn file .wav (CP2); nới rộng ô nhập khung giờ yên lặng
  để không bị cắt chữ (CP3).
- **Tab Bộ gõ:** thêm thẻ "CÔNG CỤ" mở **Bảng gõ tắt** (macro) + **Công cụ chuyển mã** (CP4).
- **Tab Riêng tư (trước để trống):** đủ 4 nhóm — bật/tắt nhật ký cảm xúc (tắt là xóa sạch), **Xuất
  CSV** (bản sao gọn, không chứa chữ gõ), **tự động dọn dẹp** nhật ký cũ hơn 30/60/90 ngày, và **Xóa
  toàn bộ nhật ký** (CP5).
- **Tab Giới thiệu:** đồng bộ với macOS — icon, tagline "Một sản phẩm GNH", ngày cập nhật, credit
  OpenKey, trang chủ key.bketech.xyz, nút cam "Kiểm tra bản mới..." nối bộ tự-cập-nhật, copyright GNH (CP6).

### Changed

- **Đổi tên "Phát tiếng gõ" → "Bật chuông tỉnh thức"** cho đúng nghĩa + đồng bộ với macOS/popover (CP1).

## [0.4.17]

Đợt hoàn thiện Popover theo nghiệm thu tay (`docs/POPOVER-FEEDBACK.md`) + tự-cập-nhật một chạm.

### Added

- **Popover: nhịp chuông tùy chỉnh đặt được** — thêm bộ tăng/giảm "− NN phút +" + nút "Đặt" (thay ô
  cứng chỉ đọc). Nhịp trong khoảng 15–240 phút (P1).
- **Popover: bấm icon nốt nhạc để chọn file .wav** làm tiếng chuông của riêng bạn (P2).
- **Popover: khung cảm xúc "Hôm nay" hết trống** — luôn hiện khung thời gian 3 giờ/2 giờ/1 giờ/bây
  giờ kể cả khi chưa có dữ liệu; thêm nút chuyển **"Ngay bây giờ / Hôm nay"** (xem 24 giờ theo
  sáng/trưa/chiều/tối) + link **"Soi lại hôm nay →"** (P4, P5, P6).
- **Popover: tab Bộ gõ có thẻ "Gõ tắt"** — bật/tắt Macro + Chuyển chế độ thông minh + link mở bảng
  gõ tắt (P7).
- **Nút "Kiểm tra bản mới..." giờ tự cập nhật** — tự hỏi bản mới nhất, tải và mở bộ cài (chỉ khi bạn
  bấm; vẫn qua kiểm tra an toàn của Windows). Chưa ký số nên có thể còn cảnh báo SmartScreen — bấm
  "More info → Run anyway".

### Changed

- **Trang chủ đổi thành `https://key.bketech.xyz`** (link mã nguồn vẫn trỏ GitHub theo giấy phép GPL).

### Fixed

- **Bug thật: nhịp tùy chỉnh 15–60 phút bị xếp nhầm về "30/60 phút"** ở lần vẽ kế (hiện sai số so với
  nhịp đang chạy thật). Nay so đúng bằng giá trị chính xác (P1 review).

## [0.4.16]

Đợt "thu cửa sổ + đồng bộ thiết kế" (GĐ-C) + khép sổ (GĐ-D một phần), `docs/WINDOWS-PARITY-TASKS.md`.

### Added

- **Windows: cửa Cài đặt kéo giãn được** — bỏ khung cứng, thêm mép kéo + nút thu nhỏ; thu cỡ mặc
  định từ 450×450 xuống 380×360 (trước to quá so với nội dung). Có chặn thu-nhỏ-quá để nội dung
  không bị cắt (C1).
- **Windows: khung "Mặt hồ đang thế nào?" sau nhịp chuông** — thay hộp nhắc chữ cũ bằng 3 lựa chọn
  tự ghi nhận (Phẳng lặng / Gợn nhẹ / Gợn sóng) + "Bỏ qua", ghi vào nhật ký và hiện lên cơn sóng. Ba
  mức cùng một sắc trung tính — không đèn xanh/đỏ chấm điểm (C5).
- **Windows: chọn Kiểu gõ / Bảng mã ngay trên popover** — trước đây chỉ hiện chữ "Telex"/"Unicode"
  cứng (sai cả trạng thái thật lẫn không bấm được); nay đọc đúng thiết lập hiện tại và bấm để đổi (C3).
- **Windows: file .exe khai đúng phiên bản** — thêm bước tự ghi số phiên bản từ `version.env` vào
  file build, vá lỗi .exe kẹt version cũ (D1).

### Notes

- **DPI màn nét-cao (C2) tạm HOÃN có chủ đích**: hiện app vẫn hiển thị đúng cỡ + bấm trúng trên màn
  150% (Windows tự phóng, hơi mờ). Bản "sắc nét per-monitor" cần sửa 260+ toạ độ vẽ+bấm và **chỉ màn
  nét-cao thật mới kiểm được** — làm mù rủi ro lệch vùng bấm, để lại chờ máy thật. Xem `docs/FRICTION-LOG.md`.

## [0.4.15]

Đợt "trọn vẹn tính năng chuông + cơn sóng sống" (GĐ-B, `docs/WINDOWS-PARITY-TASKS.md`) — sau nghiệm
thu tay v0.4.14, hoàn thiện 9 việc B1–B9 để vỏ Windows bắt kịp macOS về chuông, nhật ký, cơn sóng
và bỏ nốt giao diện cũ. Mỗi việc 1 commit riêng.

### Added

- **Windows: cơn sóng + nhật ký "chạy" theo thời gian thực** — lớp cảm xúc giờ giữ trạng thái sóng
  sống (EMA làm mượt + phai dần 5 phút) cập nhật mỗi câu, y như macOS: popover và cửa Cài đặt vẽ
  đầu sóng "bây giờ" cùng vệt điểm dày theo lịch sử gõ, thay vì đường phẳng chết (B1–B3).
- **Windows: nút "Nghe thử" tiếng chuông** ngay trên popover lẫn cửa Cài đặt — bấm là nghe liền,
  bỏ qua mọi cổng chặn (B4).
- **Windows: dòng "Dự kiến reo lúc HH:mm (còn N phút)"** trên popover, tự ẩn khi tắt chuông hoặc
  đang tạm hoãn (B5).
- **Windows: giờ yên lặng + chọn tiếng .wav của riêng bạn + tạm hoãn 1 giờ** trong tab Chuông của
  cửa Cài đặt — đưa nốt những gì trước đây chỉ hộp thoại chuông cũ mới có (B6).
- **Windows: icon 4 bộ tiếng chuông thật** (chuông chùa / chuông báo / chuông gió / nhạc) thay 4
  chữ tạm A/B/C/D, xuất từ SVG thương hiệu (B7).
- **Windows: header popover có "VN" + nút "⋯"** như macOS — "VN" báo bộ gõ Việt bật/tắt (chỉ báo
  ngôn ngữ, không bao giờ báo cảm xúc), "⋯" mở đúng menu khay (B9).

### Changed

- **Windows: bỏ hẳn hộp thoại chuông native cũ (xám xịt)** — mọi cài đặt chuông nay nằm gọn trong
  tab "Chuông" của cửa Cài đặt; menu khay "Chuông tỉnh thức…" mở thẳng đúng tab đó (B8).

## [0.4.14]

Đợt "nối lại dây điện" (GĐ-A, `docs/WINDOWS-PARITY-TASKS.md`) — sau nghiệm thu tay v0.4.12 lộ ra
UI Windows đã vẽ đúng nhưng nhiều control chưa nối dây thật hoặc nối nhầm dây. 9 việc A0–A8, mỗi
việc 1 commit riêng.

### Fixed

- **Windows: chuông giờ reo được từ cả popover lẫn cửa sổ Cài đặt** — nút "Phát tiếng gõ"/"Bật
  chuông tỉnh thức" trước đây lật nhầm `FLAG_BEEP` (tiếng bíp đổi Việt/Anh của OpenKey) thay vì
  `vBell` (biến thật `Bell.cpp` đọc lúc reo); tiếng chuông ghi khoá `vBellSoundIndex` (không ai
  đọc) thay vì `vBellSoundName`; âm lượng ghi `vVolume`/`vVolume` (khoá chết) thay vì `vBellVolume`.
  Vá kèm 1 lỗi kiểu dữ liệu: `BrandControls_DrawSlider` nhận/trả thang 0..1 (float) nhưng bị gán
  thẳng vào biến `int` — cắt cụt khiến bấm vào đâu trên thanh trượt cũng gần như luôn đặt âm lượng
  về 0. Cả popover lẫn cửa sổ Cài đặt đều vá.
- **Windows: 3 tab cửa sổ Cài đặt hết tê liệt** ("Hôm nay"/"Chuông"/"Riêng tư") — vùng dò-click nằm
  trong nhánh `WM_PAINT` (toạ độ chuột giả `{-1,-1}` lúc vẽ) nên không bao giờ khớp. Nay có khối
  `WM_LBUTTONUP` riêng, dựng lại đúng toạ độ vùng vẽ.
- **Windows: popover hết "bấm như không ăn"** — công tắc gạt (pill) trước đây xử lý cả lúc nhấn
  xuống LẪN lúc thả chuột, nên mỗi cú bấm đảo trạng thái 2 lần (về đúng chỗ cũ). Nay chỉ xử lúc thả
  chuột. Đánh đổi: thanh trượt âm lượng thành "bấm để đặt" thay vì kéo-mượt theo chuột.
- **Windows: nút "Bật nhật ký" ngay tại chỗ** — trước đây thấy chữ "Nhật ký cảm xúc đang tắt." mà
  không có cách bật tại chỗ, phải tự tìm menu khay chuột phải. Thêm ở cả popover và cửa sổ Cài đặt.
- **Windows: Độ nhạy chọn "Nhạy" giờ mới thật sự nhạy** — UI ghi thang 0/1/2 nhưng bộ điều phối
  nhắc tâm (`NudgeCoordinator`) đọc thang 1/2/3, nên chọn "Nhạy" (ghi 2) bị hiểu thành "Vừa", và
  mức "Nhạy" thật (3) không bao giờ đạt tới được. Đồng bộ cả 2 chiều đọc/ghi ở 3 nơi (popover +
  paint + click của cửa sổ Cài đặt).
- **Windows: credit GPL hết ghi sai** — cú đổi tên hàng loạt OpenKey→MindfulKey từng nuốt luôn tên
  gốc trong dòng ghi công, hộp Giới thiệu từng ghi "Dựa trên MindfulKey — Mai Vũ Tuyên" (ghi công
  vòng tròn, sai). Trả lại "Dựa trên OpenKey", link Fanpage/GitHub OpenKeyVN/tuyenvm-OpenKey đúng
  dự án gốc, ở cả header 23 file lẫn hộp Giới thiệu.

### Known limitation

- **Windows: tab "Riêng tư" tạm trống** — 2 control cũ (chọn thời gian lưu trữ, xuất CSV) chưa
  từng có hàm hậu trường nào cả (không phải chỉ sai tên khoá) nên đã gỡ khỏi UI thay vì để nút giả.
  macOS đã có đủ 2 tính năng này thật; port sang Windows là việc riêng, chờ chủ dự án chốt — xem
  `docs/FRICTION-LOG.md` 2026-07-23 "A4".

## [0.4.13]

### Added

- **macOS: cửa sổ Cài đặt kéo giãn được** — trước đây cửa sổ đóng cứng một cỡ (thiếu
  `NSWindowStyleMaskResizable`), mọi card dán frame cố định 600pt. Nay bật kéo giãn: cột nav ghim
  trái, cột nội dung nới theo, và màn "Hôm nay" tự giãn — card sóng (Gác cổng) + dòng sông cảm xúc
  kéo rộng theo bề ngang, link "Soi lại hôm nay →" vẫn ghim mép phải, pill "Ngày/Tuần/Tháng" giữ cỡ.
  Sàn kích thước = cỡ thiết kế gốc (chỉ kéo to, không bóp nhỏ) để pane tái dùng từ OpenKey (NSBox,
  bóng đổ chụp sẵn theo bounds) canh giữa giữ nguyên, không lệch bóng.

## [0.4.12]

### Fixed

- **Windows: chữ Tiếng Việt hết bị vỡ (mojibake)** — thêm cờ `/utf-8` vào cả 4 cấu hình build. File
  nguồn UTF-8 không có BOM trước đây bị MSVC đọc như CP1252 → mọi chữ Việt trong menu khay, popover,
  hộp thoại vỡ thành "HÃ´m nay". Nay đọc đúng UTF-8.
- **Windows: cửa sổ Cài đặt hết trắng trơn** — phần vẽ toàn bộ 6-nav + nội dung nằm trong
  `tabPageEventProc` nhưng hàm này chưa bao giờ được gắn làm window proc; `eventProc` (proc thật của
  cửa sổ) không có WM_PAINT → chỉ vẽ nền trống. Nay `eventProc` chuyển tiếp WM_PAINT/ERASEBKGND/
  LBUTTONUP sang `tabPageEventProc` + bỏ điều kiện `IsThemeActive()` (Classic/high-contrast không vẽ).
- **Windows: hết cảnh báo "tự nhận mình là đối thủ"** — `RIVAL_MINDFULKEY_CLASS` bị đè trùng
  `APP_CLASS` lúc đổi tên OpenKey→MindfulKey, khiến app tìm thấy chính cửa sổ mình rồi cảnh báo. Trả
  về `"OpenKeyVietnameseInputMethod"` (lớp cửa sổ OpenKey gốc) để chỉ cảnh báo khi OpenKey thật chạy.
- **Windows: tiêu đề hết kẹt "0.4.2"** — `.rc` cập nhật version 0.4.12 (đồng bộ `version.env`).

### Known follow-ups

- Windows tab "Hôm nay"/"Chuông"/"Riêng tư" (0/1/3): hiển thị đúng nhưng hit-test click còn kẹt trong
  nhánh WM_PAINT — sẽ chuyển sang WM_LBUTTONUP như tab Bộ gõ/Hệ thống.
- Windows version nên tự đọc `version.env` lúc build thay vì hardcode trong `.rc`.

## [0.4.11]

### Fixed

- **Sóng cảm xúc vẽ ổn định, hết "nhảy" mỗi lần cập nhật (macOS + Windows)** — trước đây mỗi điểm
  nhô lên hay chìm xuống theo THỨ TỰ trong mảng (điểm chẵn nhô, điểm lẻ chìm), nên chỉ cần thêm/bớt
  một điểm là đảo nhô-chìm của mọi điểm sau nó → dòng sông đổi hình mỗi lần refresh. Nay độ cao mỗi
  điểm = đúng biên độ của chính nó, luôn nhô lên từ đường trục; chấm khớp đúng đường. Sửa đồng bộ ở
  `EmotionRiverView.mm` (macOS) và `ReflectionScreen.cpp` (Windows).

## [0.4.10]

### Fixed

- **Windows: gỡ hết lỗi biên dịch chặn phát hành** — bản build Windows trước đó chưa từng compile
  sạch (viết trên máy Mac, không có compiler Windows để kiểm), nên CI hỏng từng đợt và trang Release
  thiếu file `.exe`/`.dmg`. Lần này dựng compiler Windows (mingw-w64) ngay trên máy dev để bắt HẾT lỗi
  trước khi push, thay vì đoán từng vòng CI:
  - `BrandControls.cpp`: thêm `<gdiplus.h>` (+ `<objidl.h>` trước nó cho PROPID) — file đã chuyển sang
    vẽ GDI+ nhưng quên include.
  - `TrayPopover.cpp`: thêm `<windowsx.h>` (dùng `GET_X_LPARAM`).
  - `MainControlDialog.cpp`: gọi hàm thành viên `onTabIndexChanged`/`requestRestartAsAdmin` từ window-proc
    static phải qua con trỏ `pThis->`; thêm `<cstdint>` cho `uint32_t`.
  - `ReflectionScreen.cpp`: thêm `BrandControls.h`; `MindfulKey.cpp`: thêm `<algorithm>` cho `std::find`
    — 2 lỗi CI chưa kịp báo tới (sẽ nổ ở các vòng sau nếu không vá trước).

## [0.4.9]

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
