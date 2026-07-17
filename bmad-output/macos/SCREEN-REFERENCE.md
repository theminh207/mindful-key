> ⚠️ **SUPERSEDED MỘT PHẦN (2026-07-17)** — xem `decision-log.md` entry "Bộ tiếng có Ô THỨ 4 'tiếng
> của bạn'; kho lưu đổi sang id tiếng Anh". Không còn đúng: thẻ **Bộ tiếng nay có 4 ô, không phải 3**
> (§2.2 mục 3 và §5 "3 icon brand GIỮ NGUYÊN") — ô thứ 4 mở hộp chọn tệp âm thanh của người dùng,
> hình lấy từ asset brand có sẵn `bell-idle`. Vẫn còn hiệu lực và KHÔNG được phá: 3 icon
> `bell_temple`/`bell_chime`/`bell_wind` giữ nguyên đúng vị trí + ánh xạ tiếng, chỉ báo chọn vẫn là
> `_bellIndicator`, và luật **cấm icon ngoài brand** (ô thứ 4 tuân thủ: `bell-idle` là asset brand,
> sinh từ `brand/svg/bell-idle.svg` qua `brand/export.sh`).

# Screen Reference & Design Contract — Cửa sổ "Cài đặt Mindful Key" (macOS)

**Ngày:** 2026-07-16 · **Trạng thái:** bản 1 (spec, chưa build tới). Kèm bộ mockup chuẩn 6 màn (session 2026-07-16).

> Tài liệu này phục vụ **3 việc cùng lúc**:
> 1. **Spec build** — agent phải dựng từng màn KHỚP mô tả dưới, không tự sáng tác.
> 2. **Nguồn user guide** — người viết hướng dẫn lấy mục đích/copy/hành vi từ đây, không mò lại app.
> 3. **Hợp đồng tuân thủ** — Phần 0 "Luật linh kiện" là ranh giới; lệch = phải sửa, không thương lượng.

> ⚖️ **Luật tối cao vẫn là HIẾN CHƯƠNG.** Dòng sông / mood / copy nhận diện đã khoá — tài liệu này KHÔNG
> ghi đè, chỉ lo *khung, linh kiện, nhịp, và những màn chưa migrate*. Đụng nhận diện mà mơ hồ → hỏi chủ dự án.

---

## Gốc bệnh (vì sao viết tài liệu này)

App đang là **ngôi nhà cải tạo dở** — hai thế giới dán vào nhau:
- **Đã tân trang (view brand mới):** Hôm nay, Chuông, Riêng tư, Giới thiệu — dựng bằng `BrandColors` + `BrandControls`.
- **Còn đồ cũ (storyboard OpenKey):** **Bộ gõ** + **Hệ thống** = `ViewController` cũ (`tabviewPrimary`/`tabviewSystem`, xem `SettingsWindowController.mm`). Đây là lý do THẬT của mọi "lệch":
  - Toggle Bộ gõ nhợt nhạt/lộn xộn = control OpenKey đời cũ, không phải `PillSwitch`.
  - **"Hệ thống" trắng bốc** = trỏ vào hộp cũ `tabviewSystem` vốn rỗng.
- **Trôi khỏi quyết định:** Chuông hiện 15/30/60 (`BellSettingsView.mm:398`) nhưng decision-log 2026-07-15 chốt **30/60 + ô Tùy chỉnh, sàn 15/trần 240**.

→ Chữa = (a) kéo 2 phòng cũ về cùng bộ linh kiện, (b) vá chỗ trôi, (c) thống nhất nhịp/màu — KHÔNG sơn lẻ từng phòng.

---

## Phần 0 — LUẬT LINH KIỆN (hợp đồng, agent buộc theo)

**PHẢI dùng (đã có sẵn, đừng chế lại — tên THẬT, xem Phần 1b):**
- Màu: nguồn DUY NHẤT = `brand/tokens.json` (đọc qua `BrandColors.h`: `[Brand teal/orange/charcoal/muted/stone/divider/tealLight/orangeLight/softWhite]`). KHÔNG chép hex tay, KHÔNG chế màu.
- Control: `BrandControls.h` — **`PillSwitch`** (toggle, bật = teal), **`StatusDot`** (chấm nhị phân teal), **`CTAButton`** (nút cam chữ tối), **`SecondaryButton`** (nút trắng trung tính), `applyThinCardStyle` (thẻ 1px viền + bo 11px, không bóng), `applyBrandCardStyle`, `mk_eyebrowLabelWithTitle:` (nhãn mục HOA), `MKSegmented` (segmented tự vẽ).
- Icon/hình: dùng asset trong `brand/` (svg nguồn + png xuất). KHÔNG kéo icon ngoài (Tabler/SF Symbol) khi đã có asset brand.

**CẤM (đây là nguồn "lệch"):**
- ❌ `NSColor colorWithRed:/whiteColor/grayColor/controlAccentColor` trong file màn hình → dùng `[Brand ...]`.
- ❌ `NSButton` thô làm toggle → dùng **`PillSwitch`** (teal `#1D7C91` khi bật, `divider` khi tắt).
- ❌ **Thay icon brand bằng icon ngoài** (Tabler/SF) — asset brand đã có thì dùng đúng nó.
- ❌ Giữ pane bằng storyboard `ViewController` cũ (`tabviewPrimary`/`tabviewSystem`) → **migrate** thành view brand độc lập.
- ❌ Tự đặt padding/bo góc/khoảng cách rời rạc → theo "nhịp" ở Phần 1. Đổi cấu trúc đang chạy phải có lý do, không "tiện tay".

**Nhịp bố cục (mọi pane):**
- Lề nội dung: 18px hai bên, 16px trên. Tiêu đề pane `mkh` 19px/semibold, cách nội dung 14px.
- Nhóm = **nhãn eyebrow HOA** (`mk_eyebrowLabel`, màu `stone`) + **1 thẻ** `applyThinCardStyle` bên dưới. Các thẻ cách nhau 14px.
- Hàng trong thẻ: nhãn 14px/medium `charcoal` bên trái, control bên phải (`mkrow` = space-between). Câu phụ 12px `muted`/`stone` xuống dòng dưới.
- **Chống khoảng trắng chết:** nội dung xếp từ trên xuống theo nhóm; cửa sổ cao vừa nội dung (đừng để card cụm trên đỉnh + nửa dưới trống hoác như bản hiện tại).

---

## Phần 1 — Tokens (giá trị thật, để user guide trích đúng)

| Vai | Token | Hex |
|-----|-------|-----|
| Thương hiệu / tiêu đề / nav-active / toggle-on | `teal` | `#1D7C91` |
| Nền phụ / nav-active bg / chọn nhẹ | `tealLight` | `#E8F2F4` |
| CTA / link / khoảnh khắc con người (KHÔNG mã hoá cảm xúc) | `orange` | `#FF7A1A` |
| Nền cam nhạt | `orangeLight` | `#FFF2E8` |
| Chữ chính | `charcoal` | `#2A2A2A` |
| Chữ phụ | `muted` | `#666666` |
| Nhãn eyebrow / sóng biên độ thấp | `stone` | `#8A9BA0` |
| Viền mảnh / nền off toggle | `divider` | `#E5E7E8` |
| Nền trang/card | `softWhite` | `#F8F8F8` |

Font: hệ thống (SF). Bo góc: card 11px, control 7–8px. Không bóng đổ trên thẻ mảnh.

---

## Phần 1b — Kho asset & component THẬT (tham chiếu ĐÚNG TÊN, đừng chế)

**Component (`platforms/apple/macos/BrandControls.h`):** `PillSwitch` (toggle teal) · `StatusDot` (chấm nhị phân) · `CTAButton` (nút cam) · `SecondaryButton` (nút trắng) · `applyThinCardStyle` / `applyBrandCardStyle` (NSView category) · `mk_eyebrowLabelWithTitle:` (NSTextField category) · `MKSegmented` (trong `BellSettingsView.mm`).

**Icon chuông "Bộ tiếng" (đã có, GIỮ):** `bell_temple` · `bell_chime` · `bell_wind` — nạp ở `BellSettingsView.mm` (`createBellButtonWithTag:image:`), chọn tiếng qua `SoundNameForIndex`, chỉ báo chọn = `_bellIndicator`.

**Asset brand (`brand/`, nguồn svg → xuất png qua `export*.sh`):**
- Màu/khối: `brand/tokens.json` (10 màu + `moodScale` 1_an…5_cuon + font Montserrat/Inter + radius + shadow). NGUỒN DUY NHẤT.
- Sóng biên độ: `mood-1-an … mood-5-cuon` (svg/png) — 5 bậc trung tính, khớp `moodScale`.
- Chuông trạng thái: `bell-idle` · `bell-ring`. Wordmark: `wordmark(-white)`. Menu-bar: `Status*.svg`.
- Toggle: `ui-toggle-on/off`. Tab: `ui-tab-{bogo,gotat,hethong,thongtin}`. Quyền/nhắc: `ui-perm-*`, `ui-notif`, `ui-snooze`, `ui-resume`.
- ⚠️ Nav hiện dùng **`StatusDot` (chấm)**, KHÔNG dùng `ui-tab-*`. Giữ nguyên cấu trúc — đừng đổi nav sang icon trừ khi chủ dự án yêu cầu.

## Phần 2 — Reference từng màn (6 pane)

### 2.1 · Hôm nay
- **Mục đích:** liếc nhanh trạng thái ngày + lối vào Soi lại. Bản đầy đủ của popover (decision 2026-07-15).
- **Khu:**
  1. **Thẻ trạng thái** — câu tóm tắt ngày (khớp bằng chứng, vd "Sáng và chiều có gợn, phần lớn êm" — KHÔNG cứng "phẳng lặng"), phụ đề "Gác cổng đang canh khi bạn gõ · N nhịp chuông hôm nay", link cam "Soi lại hôm nay →".
  2. **Segmented** Ngày / Tuần / Tháng.
  3. **Thẻ dòng sông** — `EmotionRiverView` (đã có trục nét đứt + chấm teal, 2026-07-16), trục Sáng/Trưa/Chiều/Tối, chú giải "càng gợn càng căng · mỗi chấm = 1 nhịp chuông".
- **Sửa:** bỏ **vạch teal mồ côi** phía trên thẻ (đường phẳng `EmotionWaveView` render lạc) · xưng "**mình**" (đang là "anh") · lấp khoảng trắng chết bên dưới.
- **Khoá (đừng đụng):** logic dòng sông, câu quan sát.

### 2.2 · Chuông
- **Mục đích:** bật/tắt + đặt nhịp chuông tỉnh thức (chuông = nhịp lấy mẫu, mỗi ngân ghi 1 điểm lên sông).
- **Khu:**
  1. Eyebrow **Trạng thái** → thẻ: `PillSwitch` "Bật chuông tỉnh thức" + phụ "Dự kiến reo lúc HH:MM · còn N phút".
  2. Eyebrow **Nhịp** → thẻ: nhãn "Chuông định kỳ mỗi" + **`MKSegmented` 30 / 60** + **ô "Tùy chỉnh" điền phút**; phụ "Sàn 15 · trần 240 phút. …một nhịp, hai vai."
  3. Eyebrow **Âm thanh** → thẻ: "Bộ tiếng" + **3 icon brand GIỮ NGUYÊN** (`bell_temple`/`bell_chime`/`bell_wind`), 1 cái đang chọn (chỉ báo `_bellIndicator`); dưới là "Âm lượng" (slider).
- **Sửa (BẮT BUỘC — khớp decision 2026-07-15):** đổi segmented nhịp `15/30/60` → **`30/60` + ô Tùy chỉnh (sàn 15/trần 240)**.
- **Sửa (thẩm mỹ, KHÔNG đổi asset):** 3 icon chuông + chấm chỉ báo hiện đang **căn lệch** — chỉ chỉnh **khoảng cách đều + chấm nằm ngay dưới icon đang chọn + căn giữa cụm**. GIỮ đúng `bell_temple/chime/wind` + `SoundNameForIndex` + `_bellIndicator`. TUYỆT ĐỐI không thay bằng icon ngoài.

### 2.3 · Bộ gõ  *(ĐANG LEGACY — migrate)*
- **Mục đích:** bật/tắt các luật gõ Telex/VNI + macro + chuyển mã. Nội dung engine, KHÔNG đụng `core/` — chỉ thay VỎ.
- **Khu:** `MKSegmented` **Kiểu gõ / Gõ tắt / Chuyển mã**; tab "Kiểu gõ" = 1 thẻ chứa lưới `PillSwitch` (2 cột) các tuỳ chọn:
  Kiểm tra chính tả · Đặt dấu oà/uý · Sửa lỗi gợi ý (trình duyệt, Excel…) · Tự khôi phục phím với từ sai · Viết hoa đầu câu · Cho phép "z w j f" làm phụ âm · Chuyển chế độ thông minh · Tạm tắt chính tả bằng ^ · Tự ghi nhớ bảng mã theo ứng dụng · Tạm tắt bộ gõ bằng ⌘ · Tắt tiếng Việt khi bộ gõ hệ thống khác tiếng Anh.
- **Sửa (BẮT BUỘC):** thay control OpenKey cũ (nhợt, thẻ lồng thẻ, xếp lệch) bằng `PillSwitch` một sắc teal, lưới 2 cột đều · nối đúng các biến engine đang có (giữ hành vi, chỉ đổi vỏ).

### 2.4 · Riêng tư
- **Mục đích:** kiểm soát nhật ký cảm xúc (đã coherent nhất — chỉ thống nhất sắc teal toggle cho khớp các pane khác).
- **Khu:** **Nhật ký cảm xúc** (`PillSwitch` "Lưu điểm gợn cục bộ" + cảnh báo tắt = xoá sạch) · **Cầm trịch dữ liệu** (nút "Xuất CSV…" + phụ "không chứa chữ gõ") · **Tự động dọn dẹp** (dropdown 30/60/90/Không bao giờ) · **Xoá bỏ** (nút nguy hiểm "Xoá toàn bộ…").
- **Sửa:** dùng cùng `PillSwitch` sắc teal chuẩn (đang khác shade với Bộ gõ) · sẽ thêm mục **"Ô ghi cảm nhận"** khi làm daily-note (xem `_shared/DECISION-daily-note-v1.md`).

### 2.5 · Hệ thống  *(ĐANG TRẮNG — cần chốt nội dung + migrate)*
- **Vấn đề:** pane trỏ vào `tabviewSystem` cũ, **rỗng**. Phải định nghĩa nội dung rồi dựng bằng view brand.
- **Nội dung (ĐÃ CHỐT 2026-07-16 — cả 4 mục):** `PillSwitch` "Khởi động cùng macOS" · `PillSwitch` "Hiện biểu tượng trên thanh menu" · "Phím tắt bật/tắt bộ gõ" (ô hotkey) · "Cập nhật" (phiên bản + nút "Kiểm tra cập nhật"). Mỗi mục = 1 thẻ `applyThinCardStyle`.

### 2.6 · Giới thiệu
- **Mục đích:** danh tính + credit pháp lý (HIẾN CHƯƠNG buộc giữ credit OpenKey/Mai Vũ Tuyên + GPL v3).
- **Khu (căn giữa):** icon sóng ~ · "Mindful Key" · phiên bản · tagline chánh niệm · **"Dựa trên engine OpenKey của Mai Vũ Tuyên · Giấy phép GPL v3"** · link Trang chủ / Giấy phép / Cam kết riêng tư.
- **Sửa:** đảm bảo dòng credit + GPL hiện rõ (bắt buộc, không được thiếu).

---

## Phần 3 — Quyết định

1. ✅ **Hệ thống** (chốt 2026-07-16): giữ **cả 4 mục** (Khởi động cùng macOS · Hiện icon menu · Phím tắt bật/tắt · Kiểm tra cập nhật).
2. ✅ **Xưng hô toàn app** (chốt 2026-07-16): dùng "**mình**" — app là *tiếng nói bên trong của người dùng* (tấm gương), không phải người ngoài xưng hô. Thay hết "anh" ở Hôm nay + Soi lại; áp cho mọi copy mới.
3. ⬜ **Bộ tiếng chuông** (còn mở): tên 3 bộ tiếng cuối cùng (mockup tạm "Chuông trầm / trong / mõ").

## Phần 4 — Thứ tự thi công (fan-out từng pane, mỗi lệnh 1 pane)

Ưu tiên theo "vỡ nặng trước":
1. **Hệ thống** (đang trắng → dựng nội dung đã chốt) + **Chuông** (vá 30/60+Tùy chỉnh cho khớp decision).
2. **Bộ gõ** (migrate legacy → `PillSwitch`) — nặng nhất, đụng nối biến engine.
3. **Hôm nay** (bỏ vạch mồ côi, xưng "bạn", lấp void) + **Riêng tư** (thống nhất sắc teal) + **Giới thiệu** (chốt credit).
Mỗi pane: chỉ dùng `BrandControls`/`BrandColors`, khớp Phần 2, qua `make brand-lint` + `make build` sạch. KHÔNG đụng `core/`.

*(Bước sau, khi diện mạo đã thống nhất: cân nhắc mở rộng `brand-lint` để fail nếu pane dùng màu thô / control cũ — "cổng chặn" đã hoãn theo yêu cầu chủ dự án 2026-07-16.)*
