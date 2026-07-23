# WINDOWS-PARITY-PLAN — đối chiếu macOS ↔ Windows + lộ trình đồng bộ

> Sinh từ **nghiệm thu tay Windows LẦN 1** (2026-07-23, bản v0.4.12, 3 ảnh + 5 lời than của chủ
> dự án) cộng 2 cuộc quét code song song: kiểm kê ~150 tính năng vỏ macOS (chuẩn gốc) và khám
> "dây điện" vỏ Windows từng control. Mục tiêu chủ dự án chốt: **hành vi Windows ↔ macOS đồng bộ
> 100%** (trong phạm vi OS cho phép — xem §5).
>
> Bám tên giai đoạn của `docs/ROADMAP-WINDOWS.md` (GĐ0–GĐ7 đã xong phần dựng); đây là các giai
> đoạn **sau nghiệm thu**, đánh số GĐ-A → GĐ-D. Ca nghiệm thu lấy từ `docs/QA-WINDOWS.md`.

## 1. Nghiệm thu v0.4.12 — cái gì ĐÃ ăn

| Kết quả | Bằng chứng |
|---|---|
| ✅ Chữ Việt hết vỡ (mojibake) — fix `/utf-8` ăn thật | 3 ảnh chủ dự án: "Hôm nay/Chuông/Bộ gõ", "Bật chuông tỉnh thức"… đọc sạch |
| ✅ Cửa sổ Cài đặt + popover VẼ ra nội dung (hết trắng trơn) | ảnh popover đủ 3 tab; lời than chuyển từ "trắng" sang "to quá/không bấm được" |
| ✅ Hết hộp thoại "tự nhận mình là đối thủ" | không còn trong phản hồi lần này |

## 2. Chẩn đoán gốc 5 lời than (đọc từ code, có neo)

Hình dung tổng: **mặt tiền đã dựng giống bản vẽ, nhưng công tắc chưa nối dây — hoặc nối nhầm dây.**

| # | Lời than | Nguyên nhân gốc | Neo |
|---|---|---|---|
| 1 | Sóng cảm xúc khi gõ không chạy | (a) `vMoodWatch` mặc định **0** — cả lớp cảm xúc ngủ; (b) **không có sóng sống**: `liveHead` đóng cứng `-1.0` ở cả 3 chỗ vẽ, Windows chưa có `LiveAmplitude()`/`FetchLiveTrace()` như macOS (EMA α=0.4, phai 5', vệt RAM ≤1điểm/30s). Ống core (MoodBuffer + SendRiskAnalyzer) thì **đã nối đúng** | MoodWatch.cpp:51,390,225-226 · TrayPopover.cpp:82 · MainControlDialog.cpp:273 · ReflectionScreen.cpp:319 |
| 2 | Chuông không bao giờ reo | Nút "Bật chuông tỉnh thức" (popover + tab Chuông) lật nhầm **`FLAG_BEEP` trong `vSwitchKeyStatus`** — tiếng "bíp" đổi Việt/Anh của OpenKey — thay vì `vBell` (mặc định 0). Chỗ DUY NHẤT ghi `vBell=1` là hộp thoại Bell cũ trong menu khay. Thêm: chọn tiếng ghi khoá `vBellSoundIndex`, âm lượng ghi `vVolume` — Bell đọc `vBellSoundName`/`vBellVolume` → **khoá chết**, chỉnh không ăn | TrayPopover.cpp:99-101 · MainControlDialog.cpp:306-308 · Bell.cpp:36,50,421 |
| 3 | "Nhật ký cảm xúc đang tắt" | Cờ là `vMoodWatch=0`; chỗ bật DUY NHẤT là menu khay chuột phải "Bật nhắc tâm". Popover hiện chữ "đang tắt" nhưng **không có nút bật tại chỗ**; đường checkbox cũ trong cửa Cài đặt là code chết | SystemTrayHelper.cpp:89,242-243 · TrayPopover.cpp:86 · MainControlDialog.cpp:778-787 |
| 4 | Cửa Cài đặt quá bự, không kéo giãn, lệch thiết kế | Khung kẻ cứng **450×450 DLU** (~1012×1080 px ở scale 150%) + `DS_MODALFRAME`, **không** `WS_THICKFRAME` → không resize. Manifest chỉ system-DPI (không PerMonitorV2). Toạ độ vẽ tay + vùng bấm đều **pixel cứng** không theo DPI → DPI cao là lệch cả layout lẫn chỗ bấm. macOS thì vừa lên resizable (v0.4.13) | MindfulKey.rc:148-149 · DeclareDPIAware.manifest:4 · MainControlDialog.cpp:204 |
| 5 | Nút không bấm được (cả cửa Cài đặt lẫn popover) | Cửa Cài đặt: tab **0 Hôm nay / 1 Chuông / 3 Riêng tư** hit-test nằm TRONG nhánh WM_PAINT với `pt={-1,-1}` → không bao giờ khớp; tab 2/4/5 + nav thì có khối WM_LBUTTONUP thật nên bấm được. Popover: pill toggle xử lý **cả** WM_LBUTTONDOWN **lẫn** WM_LBUTTONUP → đảo 2 lần = về chỗ cũ (net-zero, "bấm như không"); 2 combo Kiểu gõ/Bảng mã chỉ là **nhãn vẽ**, không phải control; 4 icon Bộ tiếng là **chữ giả A/B/C/D** | MainControlDialog.cpp:206,260,305-350,375,522-617 · TrayPopover.cpp:261-296,168-176 · BrandControls.cpp:301-309 |

**Vì sao trước giờ không ai thấy:** toàn bộ vỏ này build-verified trên CI nhưng chưa từng có mắt
người — đúng bài học đã ghi ở TEST_MATRIX ("build sạch ≠ chạy đúng"). Nghiệm thu tay lần 1 chính
là bài test thật đầu tiên.

## 3. Ma trận đối chiếu theo phân hệ (chuẩn = macOS, ~150 tính năng)

Trạng thái: ✅ ngang macOS · 🎨 chỉ-vỏ (vẽ được, chưa bấm/chưa áp) · 🧱 sườn (máy có, cổng sai)
· ❌ vắng.

| Phân hệ (số tính năng macOS) | Windows | Khoảng cách chính |
|---|---|---|
| A. Gõ tiếng Việt & engine (~26) | 🧱 gần đủ | Engine chung nên gõ = ngang; tab Kiểu gõ 10 pill bấm được; **thiếu**: combo Kiểu gõ/Bảng mã thật ở popover, hotkey tuỳ chỉnh UI, convert tool ngang macOS |
| B. Popover khay (~18) | 🎨 | Vẽ đủ 3 tab; pill double-toggle; khoá chết (tiếng/âm lượng); không công tắc nhật ký; không check-in overlay; không dòng "chuông kế tiếp lúc HH:mm" |
| C. Cửa Cài đặt (~12, 6-nav) | 🎨 | 3/6 tab tê liệt; không resize (macOS đã resizable); không segmented Ngày/Tuần/Tháng; pane Riêng tư chưa bấm được (Xuất CSV không handler) |
| D. Ống cảm xúc (~11) | 🧱 | Core nối ĐÚNG (MoodBuffer+SendRiskAnalyzer); **thiếu sóng sống** (LiveAmplitude/FetchLiveTrace/liveHead); mặc định tắt |
| E. Gác cổng (~8) | ✅ ngủ | Đủ dây (chặn Enter, allowlist, màn nhịp thở, 2 nút, log) nhưng ngủ vì cần mood bật + allowlist rỗng mặc định — GIỐNG macOS về cơ chế, khác về đường bật |
| F. Chuông & Nudge (~19) | 🧱 | Engine chuông + 3 tiếng nhúng + timer đủ; UI nối nhầm biến (mục 2); thiếu: giờ yên lặng UI, snooze menu, tiếng tuỳ chỉnh (có code, thiếu đường vào), độ nhạy lệch index (UI ghi 0/1/2, coordinator đợi 1/2/3 → "Nhạy" không bao giờ đạt) |
| G. Kho nhật ký (~13) | ✅ | DPAPI + consent-lúc-bật + purge — đủ dây qua menu khay; thiếu UI pane Riêng tư bấm được |
| H. Soi lại (~9) | ✅ | Đủ dây, đọc store thật; chỉ mở được từ menu khay (macOS có thêm 2 link trong UI) |
| I. Hệ thống (~24) | 🧱 | Khay + menu đủ; **credit GPL bị clobber** (xem §6); version .rc phải sửa tay mỗi bản (chưa auto từ version.env) |

## 4. Lộ trình khắc phục — 4 giai đoạn

Nguyên tắc: giai đoạn trước là móng của giai đoạn sau; mỗi giai đoạn có cổng nghiệm thu riêng
(máy + mắt người, bám `QA-WINDOWS.md` §7 Definition of Done). KHÔNG gộp — mỗi GĐ 1 đợt
commit + 1 bản release để chủ dự án test tay.

### GĐ-A — "Nối lại dây điện" (làm những gì ĐÃ VẼ chạy thật) — ưu tiên cao nhất
1. **Chuông**: toggle popover + tab Chuông lật đúng `vBell` (+ `Bell_ApplySettings()`); map tiếng
   `vBellSoundIndex`→`vBellSoundName`; âm lượng ghi `vBellVolume`. Ô "Tùy chỉnh" phút thành edit
   thật (hoặc tạm ẩn nếu chưa kịp — không để nút giả).
2. **Click cửa Cài đặt**: chuyển hit-test tab 0/1/3 từ WM_PAINT (pt={-1,-1}) sang khối
   WM_LBUTTONUP như tab 2/4/5 + `InvalidateRect` sau đổi.
3. **Click popover**: pill chỉ xử lý WM_LBUTTONUP (bỏ down) — hết đảo kép.
4. **Nhật ký bật tại chỗ**: dòng "Nhật ký cảm xúc đang tắt." thành nút "Bật nhật ký" (gọi đúng
   `MoodWatch_Toggle` — đã có consent gate sẵn).
5. **Độ nhạy**: khớp index UI (0/1/2) với NudgeCoordinator (1/2/3).
6. **Credit GPL** (§6) — sửa cùng đợt vì 1 dòng.
- **Cổng nghiệm thu GĐ-A**: đặt nhịp 15' + bật chuông từ popover → chuông reo đúng tiếng đã chọn
  (QA §4c); bật nhật ký từ popover → gõ 15' → sông có chấm (QA §4d); mọi control đã vẽ đều bấm
  được hoặc bị GỠ (không nút giả).

### GĐ-B — "Sóng sống" (đúng cảm giác "gõ là thấy mặt hồ gợn")
1. Port `MoodWatch_LiveAmplitude()` + `MoodWatch_FetchLiveTrace()` theo chuẩn macOS
   (EMA α=0.4 · phai smoothstep 5 phút về 0 · vệt RAM ≤1 điểm/30s giữ 4h · trộn nền persisted
   · idle = KHÔNG vẽ đầu sóng — hợp đồng dec.4, không bịa nước).
2. Nối `liveHead` thật vào 3 chỗ vẽ (TrayPopover, MainControlDialog, ReflectionScreen).
3. Popover thêm dòng "Chuông kế tiếp: lúc HH:mm" (đọc timer thật như macOS).
- **Cổng nghiệm thu**: gõ câu căng → đầu sóng nhích trong vài giây; ngừng gõ 5' → tự lặng về
  phẳng; so ảnh cạnh macOS cùng kịch bản.

### GĐ-C — "Khung cửa sổ đúng cỡ" (đồng bộ giao diện với macOS)
1. Cửa Cài đặt: bỏ `DS_MODALFRAME`, thêm `WS_THICKFRAME` (resizable như macOS v0.4.13), thu cỡ
   mặc định về khớp thiết kế; layout theo tỷ lệ thay pixel cứng.
2. DPI: nâng manifest lên **PerMonitorV2** + scale mọi toạ độ vẽ tay/hit-rect theo DPI (font đã
   theo sẵn).
3. Popover: combo Kiểu gõ/Bảng mã thành dropdown thật; icon Bộ tiếng thật (từ brand, bỏ chữ giả
   A/B/C/D); check-in overlay 3 mức sóng (macOS PanelVC).
4. Pane Riêng tư bấm được trọn: Xuất CSV (cột hẹp như macOS) · tự xoá 30/60/90/Không · Xoá toàn
   bộ; pane Chuông: giờ yên lặng + snooze + tiếng tuỳ chỉnh (code Bell có sẵn, thiếu đường vào).
- **Cổng nghiệm thu**: đặt cạnh 2 máy chụp từng màn — lệch nào phải có lý do ghi thành văn.

### GĐ-D — "Khép 100% + sổ sách"
1. Quét ma trận §3 lần cuối: mục nào còn ❌/🎨 → làm hoặc ghi "khác biệt cố ý" vào §5.
2. Version Windows tự đọc `version.env` lúc build (hết sửa tay `.rc`).
3. Chạy TRỌN `QA-WINDOWS.md` trên máy thật, điền bằng chứng vào `TEST_MATRIX.md` (cột mắt người).
4. Khi SignPath duyệt → nối ký số (bug `github-artifact-name` đã ghi ở WINDOWS-CODE-SIGNING.md).

## 5. Khác biệt CỐ Ý giữ (OS khác nhau, hành vi tương đương)

| macOS | Windows | Lý do |
|---|---|---|
| Login item `SMAppService` | Registry Run key | API mỗi OS; hành vi người dùng thấy như nhau |
| Quyền Accessibility + Input Monitoring (onboarding) | Hook trực tiếp, không cần quyền | Windows không có lớp quyền tương đương |
| Đồng bộ Chế độ Tập trung (Focus) | — không có | API macOS-only; KHÔNG bịa bản nhái |
| Single-instance `LSMultipleInstancesProhibited` | Mutex `MindfulKeyboardAppMutex` | Cơ chế mỗi OS |
| Tiếng tuỳ chỉnh nhận .wav/.aiff/.mp3/.m4a | Chỉ .wav | PlaySound không mở nổi mp3 — đã chốt 2026-07-17 |

## 6. Việc pháp lý ưu tiên 0 — credit bị máy đổi tên nuốt mất

Cú đổi tên hàng loạt OpenKey→MindfulKey đã **nuốt luôn tên trong dòng ghi công**, thành ghi công
vòng tròn/sai địa chỉ — chạm hiến chương ("GPL v3, giữ credit Mai Vũ Tuyên"):

| Chỗ | Đang ghi (SAI) | Phải là |
|---|---|---|
| MindfulKey.rc:144 | "Dựa trên **MindfulKey** — Mai Vũ Tuyên (GPL v3)" | "Dựa trên **OpenKey** — Mai Vũ Tuyên (GPL v3)" |
| MindfulKey.rc:142,344 | fanpage `facebook.com/MindfulKeyVN` (không tồn tại) | `facebook.com/OpenKeyVN` (kênh dự án gốc) |
| stdafx.h:6-7 (+ boilerplate đầu mọi .cpp) | `github.com/tuyenvm/MindfulKey` (repo bịa) | `github.com/tuyenvm/OpenKey` |

Sửa trong GĐ-A (đổi chuỗi, 0 rủi ro build). Ghi chú: quét thêm toàn vỏ Windows tìm chuỗi
"MindfulKey" nào khác vốn là tên OpenKey gốc bị nuốt.
