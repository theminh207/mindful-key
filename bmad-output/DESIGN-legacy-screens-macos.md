# DESIGN.md (bổ sung) — Thay áo 4 màn cũ OpenKey (mindful-key macOS)

**Epic:** Hiện đại hóa Bảng điều khiển macOS · **Platform:** macOS (AppKit) · **Track:** bmad-method
**Song hành:** `DESIGN-macos-control-panel.md` (panel MỚI), tài liệu này lo 4 màn CŨ kế thừa OpenKey.
**Trạng thái:** planning artifact — dev tool đọc, không sửa. Đổi thiết kế → ghi `decision-log.md`.

> ⚖️ Luật tối cao vẫn là HIẾN CHƯƠNG §2.2/2.3. Tài liệu này chỉ thêm phạm vi "màn cũ", KHÔNG
> ghi đè token/component đã khóa ở `DESIGN-macos-control-panel.md`.

---

## 0. Quyết định đã chốt (chủ dự án, phiên 2026-07-09)

| Quyết định | Chốt | Lý do |
|-----------|------|-------|
| **Cách tiếp cận** | **Thay áo (re-skin), KHÔNG xây lại** | Đợt này là *cải tiến*, không đập đi làm lại. Đúng "Surgical Changes" trong CLAUDE.md. |
| Màn Convert (chuyển mã) | **Giữ, chỉ thay áo** | Người dùng cũ OpenKey vẫn cần. Không bỏ, không giấu sâu. |
| 4 tab cửa sổ Main | **Giữ 4 tab, chỉ thay áo** | Nhanh, ít rủi ro. Gộp thành 1 màn cuộn = hướng B, để đợt sau. |

**Hệ quả phạm vi:** KHÔNG đổi cấu trúc điều hướng, KHÔNG bỏ/thêm cửa sổ, KHÔNG dời control giữa
các màn. Chỉ đổi **màu/font/hình dạng control/logo** cho hết lạc tông và hết vi phạm brand.

---

## 1. Sự thật cấu trúc app (đã verify từ code, không đoán)

App macOS gồm **4 cửa sổ tách rời** (mỗi cửa sổ = 1 window + windowController + contentVC nối
bằng relationship segue trong `Main.storyboard`):

| # | Cửa sổ | Code | Dòng | Nội dung |
|---|--------|------|------|----------|
| 1 | **Main — Điều khiển** | `ViewController.m` | 574 | Kiểu gõ/Bảng mã, Phím chuyển, Chế độ gõ, + 4 tab con (Bộ gõ/Gõ tắt/Hệ thống/Thông tin) toàn checkbox |
| 2 | **Macro — Gõ tắt** | `MacroViewController.mm` | 175 | Bảng "Từ gõ tắt / Nội dung đầy đủ", Thêm/Xóa, Nạp/Xuất file |
| 3 | **Convert — Chuyển mã** | `ConvertToolViewController.mm` | 190 | Tùy chọn HOA/thường/bỏ dấu, Bảng mã nguồn→đích, nút Chuyển mã/Đóng |
| 4 | **About — Thông tin** | `AboutViewController.m` | 62 | Logo, tên app, version, credit OpenKey, GNH |

> Panel MỚI (gác cổng/chuông/sóng) đã bắt đầu code: `GatekeeperCardView.mm`, `EmotionWaveView.mm`
> đã tồn tại. Tài liệu này KHÔNG đụng 2 file đó — chỉ lo 4 màn cũ ở bảng trên.

---

## 2. Vi phạm brand đang tồn tại (bằng chứng từ ảnh chụp thật)

Đây là **lỗi thật, không phải gu thẩm mỹ** — soi theo `DESIGN-macos-control-panel.md` §1.1 và §5:

1. **Cam bị dùng làm màu "đang bật" khắp nơi.** Mọi checkbox tô cam đặc `#FF7A1A`; tab đang chọn
   ("Bộ gõ") là viên cam. → Vi phạm §5.6 (cam CHỈ cho CTA + link active) và tinh thần §5.1 (né
   tái tạo cặp đèn xanh/đỏ bằng màu trạng thái).
2. **Màn Convert lạc tông hệ thống:** nút "Chuyển mã" xanh dương ▶, "Đóng" xanh lá ✓ — hai màu
   AppKit mặc định, ngoài palette NOW BRAND OS.
3. **Logo About sai nhận diện:** chữ "V" đỏ/coral to. Nhận diện đúng = sóng `~` teal + dấu ngã
   cam (xem `docs/BRAND-ASSETS.md`). Đỏ hoàn toàn ngoài palette.
4. **Bug đè chữ ở About:** "Trang GitHub:" chồng lên "Dựa trên OpenKey…"; dòng "Fanpage:" trống.
5. **Placeholder chưa dọn ở Macro:** cột bảng còn "Table View… / Table View Cell" (tên mặc định
   Interface Builder), chưa đặt nhãn tiếng Việt.
6. Toàn bộ 4 màn dùng form AppKit trần — không card bo góc, không bóng ngọc bích, không
   Montserrat/Inter; lạc hẳn so với panel mới.

---

## 3. Công thức thay áo dùng chung (áp cho cả 4 màn)

Đây là "bộ quy tắc sơn lại" thống nhất — mọi màn theo đúng bộ này để ra cùng 1 tông:

| Thành phần cũ | Đổi thành | Token |
|---------------|-----------|-------|
| Checkbox vuông tô cam | **`PillSwitch`** (NSSwitch tint **teal**), hoặc NSButton checkbox tint teal nếu giữ dạng list | `brand.teal` on; `divider` off |
| Tab cam đang chọn | Segmented/tab **viền + nền teal** khi chọn (không cam) | `brand.teal` |
| Nền cửa sổ trần | Nền `bg.window` + **card bo góc 16px** cho từng nhóm control | `bg.window`, `bg.card`, radius 16px |
| Bóng/viền gắt | Bóng ngọc bích `0 8px 30px rgba(29,124,145,0.08)` | elevation |
| Font hệ thống | Tiêu đề **Montserrat** (h2 16px), nội dung **Inter** (body 14px, caption 12px) | type.* |
| Nút xanh-dương/xanh-lá | Nút CTA **nền cam + chữ tối `#2A2A2A`** (KHÔNG chữ trắng — WCAG) | `cta.orange` + `text.primary` |
| Dropdown/field trần | Bo góc `radius.control` 8px, viền `divider` 1px | radius.control |

**Bất biến khi thay áo:**
- Cam `#FF7A1A` **chỉ** còn ở nút hành động (Thêm, Chuyển mã, Lưu, Kiểm tra bản mới) + link. Bỏ
  cam khỏi mọi checkbox/tab/trạng thái.
- Không thêm màu semantic đỏ-vàng-xanh-lá. Nút "Đóng" = nút phụ trung tính, không xanh-lá.
- Giữ nguyên chức năng + nhãn tiếng Việt hiện có (chỉ sửa placeholder chưa dịch).
- Chuẩn a11y panel mới vẫn áp: focus outline 2px teal, control ≥ 28pt, keyboard-reachable.

---

## 4. Kế hoạch từng màn (map → sửa gì → đụng file → ai làm)

Cả 4 màn là re-skin native AppKit thuần → **owned file rời nhau, đều thuộc `platform-shell-agent`**,
không đụng `core/` (bộ não) và không đụng lớp cảm xúc. Đây là điều kiện lý tưởng để chẻ thành
story chạy song song không conflict.

### 4.1 Màn Main — Điều khiển (`ViewController.m` + `Main.storyboard`)
- Header dropdown Kiểu gõ/Bảng mã: bọc card, font brand.
- Hàng "Phím chuyển" + "Chế độ gõ": checkbox/radio tint teal; bỏ cam.
- **4 tab con:** tab đang chọn dùng teal (không cam). Nội dung mỗi tab (2 lưới checkbox) →
  chuyển sang `PillSwitch` teal, nhóm trong card.
- Nút "Bảng gõ tắt…": nút phụ trung tính (mở cửa sổ Macro).
- **Owned:** `ViewController.m`, scene "Main" trong `Main.storyboard`. **Agent:** platform-shell.

### 4.2 Màn Macro — Gõ tắt (`MacroViewController.mm` + scene Macro)
- Đặt tên cột bảng tiếng Việt: "Từ gõ tắt" / "Nội dung đầy đủ" (bỏ placeholder "Table View Cell").
- Nút **"＋ Thêm"** = CTA cam (chữ tối); **"－ Xóa"** = nút phụ trung tính. "Nạp/Xuất file" = nút phụ.
- Checkbox "Tự động viết hoa theo phím tắt" → switch teal.
- Bảng + card bo góc, font brand.
- **Owned:** `MacroViewController.mm`, scene "Macro". **Agent:** platform-shell.

### 4.3 Màn Convert — Chuyển mã (`ConvertToolViewController.mm` + scene Convert)
- Nhóm "Tùy chọn chung" + "Lựa chọn" → 2 card; checkbox → switch teal.
- **Nút "Chuyển mã"** (đang xanh-dương ▶): CTA cam + chữ tối, bỏ icon xanh.
- **Nút "Đóng"** (đang xanh-lá ✓): nút phụ trung tính, bỏ icon xanh-lá.
- Dropdown Bảng mã nguồn→đích + nút swap: bo góc control, viền divider.
- **Owned:** `ConvertToolViewController.mm`, scene "Convert". **Agent:** platform-shell.

### 4.4 Màn About — Thông tin (`AboutViewController.m` + scene About + asset logo)
- **Thay logo "V" đỏ** bằng glyph sóng `~` teal + dấu ngã cam (nguồn `brand/svg/`, xuất qua
  `brand/export.sh`, xem `docs/BRAND-ASSETS.md`).
- **Vá bug đè chữ:** layout lại 2 dòng "Dựa trên OpenKey — Mai Vũ Tuyên (GPL v3)" và "Trang
  GitHub:" cho không chồng nhau; điền hoặc bỏ hẳn dòng "Fanpage:" trống.
- Link GitHub = link teal; checkbox "Kiểm tra bản mới khi khởi động" → switch teal; nút "Kiểm
  tra bản mới…" = CTA cam.
- **Giữ nguyên credit** "Dựa trên OpenKey — Mai Vũ Tuyên (GPL v3)" (bắt buộc pháp lý, HIẾN CHƯƠNG).
- **Owned:** `AboutViewController.m`, scene "About", asset logo trong `Resources/Assets` + `brand/`.
  **Agent:** platform-shell (asset logo lấy từ pipeline brand có sẵn).

---

## 5. Kiểm HIẾN CHƯƠNG cho đợt thay áo

- [ ] Sau khi sửa: cam `#FF7A1A` KHÔNG còn ở bất kỳ checkbox/tab/trạng thái nào — chỉ ở CTA + link?
- [ ] KHÔNG còn màu xanh-dương/xanh-lá hệ thống trên nút Convert?
- [ ] Logo About là sóng `~` teal + dấu ngã cam, KHÔNG còn chữ V đỏ?
- [ ] Nút CTA cam luôn chữ tối `#2A2A2A` (không chữ trắng — WCAG 2.61:1 FAIL)?
- [ ] Credit "Mai Vũ Tuyên (GPL v3)" còn nguyên ở About?
- [ ] Chức năng + nhãn tiếng Việt giữ nguyên, chỉ dọn placeholder chưa dịch?
- [ ] KHÔNG đụng `core/` (bộ não) và KHÔNG đụng `GatekeeperCardView.mm`/`EmotionWaveView.mm`?

---

## 6. Bàn giao

4 màn = 4 story owned-file rời nhau, **cùng thuộc `platform-shell-agent`**, chạy song song an toàn
(không màn nào đụng file của màn khác, không đụng bộ não chung). `mood-layer-agent` KHÔNG cần
tham gia đợt này (các màn cũ không có copy/ngưỡng cảm xúc).

Khi chuyển sang code: qua `mindful-key:mindful-keyboard-harness` để xác nhận ranh giới, rồi giao
4 story cho `platform-shell-agent`. Có thể chạy `bmad-epics-and-stories` để chẻ chính thức thành
story ready-for-dev trước khi code.
