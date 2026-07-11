# DESIGN.md — Visual System (iOS)

> **LOCKED PLANNING ARTIFACT.** Công cụ dev đọc file này nhưng KHÔNG sửa. Mọi thay
> đổi design đi qua skill `bmad-ux` và ghi vào `bmad-output/ios/decision-log.md`.

**Project:** mindful-key — vỏ iOS (Custom Keyboard Extension + container app)
**Track:** Quick Flow
**Date:** 2026-07-10
**Version:** 0.3 (draft — reconcile với `brand/tokens.json`: font hybrid, moodScale 5 bậc, radius 8, bóng teal; thêm §2.12 tab bar; chờ chủ dự án duyệt)

> ⚖️ **Luật tối cao = HIẾN CHƯƠNG** (`docs/AGENT-BRIEF.md` §2.2/§2.3), đè mọi quy tắc UI
> trong file này. Bất khả xâm phạm: KHÔNG đèn đỏ/xanh-lá mã hoá cảm xúc · KHÔNG mặt cười/
> mếu/emoji chấm điểm · KHÔNG gamification (streak/điểm/huy hiệu) · KHÔNG copy khiển trách.
> Nhận diện = con sóng `~` biến hình theo **biên độ**, sắc độ **trung tính**, copy **quan sát
> không phán xét**. Tự kiểm mọi màn: *"mô tả hay phán xét?"* → phán xét thì bỏ.

> 🛠️ **Đây là iOS native (UIKit/SwiftUI), KHÔNG phải web.** "Token" dưới đây là khái niệm
> ánh xạ sang `UIColor`/`UIFont`/`CGFloat` — không phải CSS custom property. "Breakpoint"
> thay bằng **size class + chiều cao khung bàn phím**. Nguồn màu thật đã commit:
> `platforms/apple/shared/BrandPalette.h` — file này KHÔNG được đặt lại giá trị hex, chỉ mô
> tả cách dùng + hằng số text-on-fill phái sinh đã kiểm contrast.

---

## 1. Design Tokens

### 1.1 Color Palette

Mọi giá trị hex gốc lấy từ `BrandPalette.h`. Cặp text/nền đều đã kiểm bằng
`bmad-ux/scripts/contrast-check.py` — tỉ lệ ghi ở §3, **số thật không phải ước lượng**.

**Brand (light mode — nền sáng)**

| Token | Value | Dùng cho |
|-------|-------|----------|
| `brand.teal` | `#1D7C91` | Thương hiệu, tiêu đề lớn, con sóng `~`, link. Chữ thường nhỏ đạt AA sát mức (4.55:1) → ưu tiên cho **chữ lớn/tiêu đề/icon**, không cho đoạn body dài. |
| `brand.tealStrong` | `#155A66` | Chữ teal trên nền `tealLight` hoặc chữ nhỏ cần biên an toàn (6.86:1 trên tealLight). **Phái sinh** — không có trong BrandPalette.h, thêm ở đây vì contrast. |
| `brand.tealLight` | `#E8F2F4` | Nền badge số bước, nền phụ, fill nhẹ. |
| `brand.orange` | `#FF7A1A` | **CTA / lớp nhịp thở / khoảnh khắc con người.** KHÔNG bao giờ dùng để mã hoá trạng thái cảm xúc. |
| `brand.orangeLight` | `#FFF2E8` | Nền nhấn cam rất nhạt. |
| `ink.primary` | `#2A2A2A` | Chữ chính (charcoal). Cũng là **chữ trên nút cam** (xem §3, luật cứng). |
| `ink.secondary` | `#666666` | Chữ phụ, caption, helper. |
| `surface.page` | `#F8F8F8` | Nền trang/màn. |
| `surface.card` | `#FFFFFF` | Nền card, nền phím bàn phím. |
| `line.divider` | `#E5E7E8` | Đường ngăn mảnh, viền, nền-off của toggle. Trang trí — không mang nghĩa. |
| `neutral.stone` | `#8A9BA0` | **Chỉ cho con sóng biên độ thấp (trang trí, Round 2).** Contrast 2.72:1 — KHÔNG đạt cho graphic mang nghĩa hay chữ. |
| `neutral.stoneStrong` | `#5E6E73` | Neutral mang **nghĩa** (đường phẳng "không bao giờ", icon phải đọc được): 5.00:1. **Phái sinh** vì `stone` gốc quá nhạt. |

**Dark mode (nền tối iOS)** — không đảo ngược ngây thơ; teal sáng lên để đọc được trên nền đen.

| Token | Value | Ghi chú |
|-------|-------|---------|
| `brand.teal` (dark) | `#4FB6CC` | 8.90:1 trên đen, 7.21:1 trên `#1C1C1E` — dư sức. |
| `brand.orange` (dark) | `#FF7A1A` | Giữ nguyên; **chữ trên cam vẫn là `#2A2A2A`** (luật cứng, cả 2 theme). 8.05:1 như graphic trên đen. |
| `ink.primary` (dark) | `#F2F4F5` | |
| `ink.secondary` (dark) | `#9BA3A6` | 8.18:1 trên đen. |
| `surface.page` (dark) | `#000000` | iOS true-black. |
| `surface.card` (dark) | `#1C1C1E` | Elevated. |
| `neutral.stoneStrong` (dark) | `#9BA3A6` | Đường phẳng mang nghĩa trên nền tối. |

**Thang "mặt hồ tâm" — moodScale 5 bậc (nguồn CHÍNH THỨC: `brand/tokens.json`)**

Đây là thang màu **con sóng cảm xúc** — trung tính, không bão hoà, đậm dần theo biên độ. Dùng
cho NÉT/NỀN con sóng, **KHÔNG dùng làm màu chữ** (tông giữa trượt contrast). Tín hiệu chính là
**biên độ (hình)**, màu chỉ phụ hoạ.

| Mức | Token | Value | Contrast trên nền sáng | Nghĩa (mô tả, không phán xét) |
|-----|-------|-------|:---:|-------|
| 1 | `mood.an`   | `#9FB6BC` | 2.0:1 — **cố ý nhạt** (tôn vinh cái tĩnh) | Mặt hồ đang lặng — trạng thái "nhà" |
| 2 | `mood.nhe`  | `#86A2AA` | — | Mặt hồ gợn êm — bình thường |
| 3 | `mood.gon`  | `#6E8E97` | 3.31:1 | Mặt hồ chớm động |
| 4 | `mood.song` | `#567A84` | — | Mặt hồ đang dậy sóng — chuông có thể ngân mời |
| 5 | `mood.cuon` | `#3F646E` | 6.07:1 | Mặt hồ đang cuộn — kích hoạt lớp nhịp thở |

> **Quan hệ với `stone`/`stoneStrong`:** moodScale là thang **con sóng** (nhận diện). Còn
> `neutral.stone`/`stoneStrong` là neutral cho **đường phẳng "không xảy ra"** (§2.10) — 2 vai
> khác nhau, đừng lẫn. Mức 1 (An) nhạt gần vô hình là ĐÚNG Ý: nghĩa nằm ở HÌNH (biên độ thấp)
> + nhãn chữ, không dựa màu (hiến chương §2.3, "không màu đơn độc").

> **KHÔNG có token semantic success/warning/error/info kiểu web.** Đây là ràng buộc hiến
> chương, không phải thiếu sót: app này **cấm** dùng màu xanh-lá "tốt" / đỏ "xấu" để chấm
> điểm cảm xúc. Lỗi hệ thống (vd "chưa bật được bàn phím") KHÔNG phải trạng thái cảm xúc →
> dùng `ink.primary` + copy rõ ràng, không tô đỏ. Xem §2.10 (Nguyên tắc biên độ).

### 1.2 Typography — **HYBRID** (chốt 2026-07-11)

Brand (`tokens.json`) muốn **Montserrat (heading) + Inter (body)**, nhưng keyboard extension bị
trần RAM ~48–60MB nếu nhồi file font. Chủ dự án chốt **hybrid theo bề mặt** — đúng nhận diện ở
nơi RAM thoải mái, an toàn ở nơi chật:

| Bề mặt | Heading | Body | Lý do |
|--------|---------|------|-------|
| **Container app** (Trang chủ, Mặt hồ, Cài đặt, onboarding) | **Montserrat** (Semibold/Bold) | **Inter** | RAM thoải mái → dùng đúng font brand cho cá tính nhận diện. Bundle 2 `.ttf` vào app bundle. |
| **Keyboard extension** (khung bàn phím) | **SF Pro** hệ thống | **SF Pro** | Chật RAM → KHÔNG bundle font; SF Pro render dấu tiếng Việt chuẩn + Dynamic Type miễn phí. |
| Số liệu canh cột | font tương ứng + `.monospacedDigit`/`tabular-nums` | | Số thẳng hàng. |

- Cả Montserrat lẫn Inter đều phủ dấu tiếng Việt tốt (subset Vietnamese khi bundle để nhẹ).
- **Giữ đúng VAI** ở cả 2 bề mặt: heading geometric-đậm, body sạch dễ đọc — để container app và
  keyboard cảm giác cùng một họ dù khác font.
- Dark/Light + Dynamic Type áp cho cả 2.

**Type scale** — dùng iOS **Text Styles** (Dynamic Type), KHÔNG hard-code pt cứng. Cột "pt
mặc định" chỉ là giá trị ở kích cỡ Large (mặc định); phải co giãn theo cài đặt người dùng.

| Vai trò | iOS Text Style | pt (Large) | Weight | Dùng cho |
|---------|----------------|-----------|--------|----------|
| Tiêu đề màn | `.title2` | 22 | Semibold | Heading onboarding, tên màn |
| Tiêu đề phụ | `.headline` | 17 | Semibold | Nhóm mục, tên card |
| Body | `.body` | 17 | Regular | Đoạn văn, mô tả (≥17pt tránh khó đọc) |
| Phụ | `.subheadline` | 15 | Regular | Chữ phụ, helper |
| Caption | `.caption1` | 12 | Regular/Semibold | Nhãn nhỏ, chú thích |
| Phím bàn phím | custom | 22–24 | Regular | Ký tự trên phím (đọc rõ ở tay to) |

- **Tối thiểu 17pt cho body** (iOS khuyến nghị; tránh zoom khó chịu).
- **Bắt buộc hỗ trợ Dynamic Type** đến cỡ Accessibility — layout không được vỡ khi chữ to.
- Tiêu đề `.title2` cho onboarding thay vì to đùng — giữ tinh thần "quan sát nhẹ", không hô hào.

### 1.3 Spacing Scale (8pt grid)

| Token | Value | Dùng |
|-------|-------|------|
| `space.1` | 4pt | Khe hở inline (icon–chữ) |
| `space.2` | 8pt | Padding trong chật |
| `space.3` | 12pt | Khe giữa item trong list |
| `space.4` | 16pt | Padding tiêu chuẩn (lề màn) |
| `space.6` | 24pt | Khe giữa nhóm |
| `space.8` | 32pt | Lề trên/dưới khối lớn |
| `space.12` | 48pt | Khoảng thở giữa section |

### 1.4 "Breakpoints" → iOS layout contexts

Không có breakpoint web. Thay bằng ngữ cảnh iOS thật:

| Context | Ràng buộc |
|---------|-----------|
| iPhone compact (SE, 375pt rộng) | Bàn phím + onboarding phải vừa; không tràn ngang. Đây là mẫu số chung — thiết kế cho nó trước. |
| iPhone standard (390–430pt) | Nới khoảng thở, không đổi cấu trúc. |
| **Khung bàn phím (keyboard extension)** | Chiều cao ~216–260pt tuỳ máy/hướng. **UI phải nhẹ RAM (~48–60MB trần)** — không ảnh/blur nặng, không view thừa. |
| Dynamic Type XL/Accessibility | Chữ phóng to → layout cuộn được, không cắt chữ. |
| Dark / Light | Cả 2 theme là hợp đồng (§1.1), không phải tuỳ chọn. |

### 1.5 Elevation

iOS ít đổ bóng nặng. Dùng tiết chế:

| Token | Value | Dùng |
|-------|-------|------|
| `elev.hairline` | 1px `line.divider` | Ngăn phím / list row |
| `elev.card` | `0 8px 30px rgba(29,124,145,0.08)` | **Bóng brand (ngả teal, mềm)** — nguồn `tokens.json`. Card onboarding/sheet nổi nhẹ. Không bóng đen gắt. |
| `elev.keyPressed` | key sáng lên + scale 0.97 | Phản hồi chạm phím |

Dark mode: bóng đổ gần như vô hình → dùng **đổi nền elevated** (`#1C1C1E`) thay bóng.

### 1.6 Border Radius

| Token | Value | Dùng |
|-------|-------|------|
| `radius.key` | 5pt | Phím bàn phím |
| `radius.control` | **8pt** | Nút, ô nhập, chip, khối nhỏ — **khớp `tokens.json`** (trước ghi 12pt, đã reconcile). |
| `radius.card` | 16pt | Card onboarding, sheet — khớp `tokens.json`. |
| `radius.pill` | 999pt | Badge bước, chip tròn |

---

## 2. Component Specifications

> Mỗi component: mặc định + đủ trạng thái + a11y. Touch target **≥ 44×44pt** là sàn cứng iOS.

### 2.1 Button — Primary (CTA)

**Visual**

| Thuộc tính | Giá trị |
|-----------|---------|
| Nền | `brand.orange` #FF7A1A |
| Chữ | `ink.primary` **#2A2A2A** (chữ TỐI — luật cứng §3, KHÔNG chữ trắng) |
| Cao | ≥ 50pt (thoải mái ngón tay) |
| Padding | 14pt dọc, 16pt ngang |
| Radius | `radius.control` 8pt |
| Font | `.body` Semibold |

**States**

| State | Đổi |
|-------|-----|
| Default | Nền cam đặc |
| Pressed | Cam tối đi ~8% + scale 0.98 |
| Disabled | Opacity 40%, không nhận chạm (`isEnabled=false`) |
| Loading | `UIActivityIndicator` + chữ mờ, `isEnabled=false` |

**A11y:** target ≥ 44pt (đây 50pt, dư). `accessibilityLabel` = nhãn nút. `<button>`
tương đương = `UIButton`, không phải `UITapGestureRecognizer` trên `UILabel`.

### 2.2 Button — Secondary / Ghost

Nút phụ ("Để sau", "Chưa thấy Mindful Key?"): nền trong suốt, chữ `brand.teal`
(dark: `#4FB6CC`), không viền hoặc viền `line.divider` 1px. Pressed: nền `tealLight`.
Dùng cho hành động không phá huỷ / lối thoát nhẹ.

### 2.3 Button — Destructive

Chỉ dùng cho "Xoá nhật ký cảm xúc" (Round 3+). **KHÔNG tô nền đỏ mặc định** — đỏ đặc là
mã màu cảm xúc, phạm hiến chương. Dùng chữ `ink.primary` + xác nhận 2 bước (sheet "Xoá
tất cả?" với nút xác nhận rõ chữ), thay vì dựa vào màu đỏ để cảnh báo. (Chi tiết khi tới
Round 3.)

### 2.4 Text field (ô nhập thử / cấu hình)

| Thuộc tính | Giá trị |
|-----------|---------|
| Cao | ≥ 44pt |
| Viền | 1px `line.divider`, focus → `brand.teal` |
| Radius | `radius.control` 8pt |
| Font | `.body` 17pt (đủ lớn, không lo zoom) |

Trạng thái lỗi (vd "không mở được Cài đặt"): viền **KHÔNG đỏ** — dùng chữ helper
`ink.secondary` + icon trung tính + copy chỉ dẫn. Lỗi hệ thống ≠ cảm xúc.

### 2.5 Keyboard key (phím bàn phím tự vẽ) — **component lõi**

| Thuộc tính | Giá trị |
|-----------|---------|
| Nền | `surface.card` (#FFFFFF / dark #1C1C1E) |
| Chữ | `ink.primary` |
| Cao tối thiểu | 42pt (hàng phím); tổng khung nhẹ để né trần RAM |
| Radius | `radius.key` 5pt |
| Khe giữa phím | 4–6pt |

**States**

| State | Đổi |
|-------|-----|
| Default | Nền card, chữ ink |
| Pressed (touch-down) | Sáng lên `tealLight` + scale 0.97 (`elev.keyPressed`); phím chữ có thể "pop" preview phía trên như iOS gốc |
| Phím chức năng (⌫, ⇧, 🌐, space) | Nền `surface.page` (tối hơn phím chữ 1 bậc) để phân biệt |

**A11y:** mỗi phím có `accessibilityLabel` đọc được (vd "chữ a", "xoá lùi", "chuyển bàn
phím"). Target thực ≥ 44pt kể cả khi visual nhỏ hơn (mở rộng hit area). Hỗ trợ
**Reduce Motion**: tắt "pop" preview, giữ đổi nền.

### 2.6 Suggestion bar + con sóng `~` (Round 1 khung, Round 2 sóng)

Thanh trên cùng bàn phím, cao ~40pt.

- **Round 1:** để trống hoặc gợi ý từ đơn giản (nếu bật). Chưa có sóng.
- **Round 2 (phác):** khi có Full Access, thanh này hiện **con sóng `~` ambient** phản chiếu
  biên độ nhịp gõ. **Biên độ = ý nghĩa** (§2.10): mặt hồ phẳng ↔ gợn sóng. **Tuyệt đối
  không** đổi thanh này sang đỏ/cam để "cảnh báo" — chỉ đổi **biên độ sóng** + (nếu cần) 1
  câu quan sát ngắn ("Mặt hồ đang gợn sóng"). Màu sóng: `brand.teal`; biên độ thấp có thể
  ngả `neutral.stone` (trang trí).

**A11y:** con sóng là trang trí → `isAccessibilityElement=false`; nếu có câu quan sát thì
câu đó mới là accessibility element (đọc được). Reduce Motion: sóng đứng yên ở biên độ
tương ứng, không dao động.

### 2.7 List row (cấu hình / nhật ký)

Row chuẩn iOS: nhãn trái, control/giá trị phải (toggle, chevron, slider). Cao ≥ 44pt.
Ngăn bằng `line.divider`. Toggle bật = `brand.teal` (KHÔNG xanh-lá hệ thống). Slider
(chiều cao bàn phím, cỡ chữ) — kế thừa ý "slider trực tiếp" của Laban.

### 2.8 Card onboarding

Nền `surface.card`, radius `radius.card` 16pt, padding `space.4`. Nổi nhẹ `elev.card`.
Cấu trúc: brand-mark (sóng + "Mindful Key") → chỉ báo bước → tiêu đề `.title2` → body →
nội dung → CTA cam → nút ghost.

### 2.9 Step indicator (chỉ báo bước)

2 đoạn gạch ngang; đoạn hiện tại `brand.teal`, còn lại `line.divider`. Đây là **page
indicator trình tự thật** (2 màn onboarding) — KHÔNG phải thanh tiến trình phần thưởng, KHÔNG
điểm/streak. `accessibilityLabel` = "Bước 1 trên 2".

### 2.10 Nguyên tắc "biên độ mang nghĩa" (amplitude-as-meaning) — **luật design riêng**

> Đây là component-nguyên-tắc quan trọng nhất, phái sinh từ hiến chương §2.3. Khi cần phân
> biệt hai trạng thái đối lập (bật/không, xảy ra/không xảy ra, căng/lặng), **KHÔNG dùng cặp
> màu valence (xanh-lá ✓ / đỏ ✗)**. Thay bằng **ngôn ngữ biên độ của chính brand**:

| Nghĩa | Ký hiệu | Token |
|-------|---------|-------|
| "Cái này xảy ra / bật lên / có nhịp" | con sóng `~` | `brand.teal` |
| "Cái này KHÔNG xảy ra / mặt phẳng lặng" | đường thẳng phẳng | `neutral.stoneStrong` #5E6E73 (đạt 5.00:1) |

Đã dùng ở màn Full Access (§ EXPERIENCE). Lợi ích: (1) đúng hiến chương tuyệt đối — không
mã màu cảm xúc; (2) nhất quán nhận diện — sóng vs mặt hồ là chính ẩn dụ lõi của sản phẩm;
(3) không phụ thuộc màu để truyền nghĩa (người mù màu vẫn phân biệt sóng vs đường thẳng).
**Nghĩa luôn có kèm nhãn chữ** — graphic không bao giờ là kênh truyền nghĩa duy nhất.

### 2.11 Segmented control + Slider (màn Cài đặt)

Hai control cấu hình bàn phím. **Màu "đang chọn/đã tô" = `brand.teal`, KHÔNG dùng xanh-lá
hệ thống iOS** (xanh-lá = mã màu valence, phạm hiến chương).

**Segmented control** (vd chọn Kiểu gõ: Telex / VNI)

| Phần | Visual | Ratio |
|------|--------|-------|
| Track (nền) | `tealLight` #E8F2F4 (light) / `#1C1C1E` (dark) | — |
| Đoạn ĐANG chọn | pill nền `surface.card` #FFFFFF, chữ `tealStrong` #155A66 | **7.82:1** ✅ |
| Đoạn KHÔNG chọn | chữ `ink.secondary` #666666 trên track | **5.04:1** ✅ |

- States: default / pressed (pill mờ nhẹ) / disabled (opacity 40%).
- A11y: `UISegmentedControl` chuẩn; mỗi đoạn có label đọc được ("Telex", "VNI"); đoạn đang
  chọn báo trạng thái selected cho VoiceOver.
- Target: control cao ≥ 44pt.

**Slider** (vd Chiều cao bàn phím)

| Phần | Visual | Ratio |
|------|--------|-------|
| Track đã tô | `brand.teal` #1D7C91 | **3.90:1** trên track trống #E5E7E8 (graphic ≥3 ✅) |
| Track trống | `line.divider` #E5E7E8 | — |
| Thumb | `surface.card` #FFFFFF + `elev.card` | — |

- States: default / dragging (thumb hơi to + preview cập nhật realtime) / disabled.
- A11y: `UISlider` với `accessibilityValue` đọc được (vd "mức 3/5"); chỉnh được bằng
  VoiceOver. Reduce Motion: preview đổi tức thì, không animate.

### 2.12 Tab bar (điều hướng container app)

Thanh tab đáy của **container app** — 3 mục top-level (xem EXPERIENCE §Kiến trúc thông tin).
**Chỉ container app có tab bar**; onboarding (tuyến tính) và keyboard extension KHÔNG có.

| Mục | Icon | Label |
|-----|------|-------|
| Trang chủ | nhà (hoặc dấu ngã `~`) | "Trang chủ" |
| Mặt hồ | con sóng `~` | "Mặt hồ" (nhật ký + soi lại + thang mặt hồ) |
| Cài đặt | sliders | "Cài đặt" |

**Visual & states**

| Trạng thái | Màu | Ratio |
|-----------|-----|-------|
| Tab đang chọn | `brand.teal` #1D7C91 (icon + label) trên `surface.card` | 4.83:1 (✅ ≥3 graphic/large) |
| Tab tắt | `ink.secondary` #666666 | 5.74:1 (✅) |
| Nền tab bar | `surface.card` (light) / `#1C1C1E` (dark) + hairline trên | — |

- **CẤM:** nút "+" giữa, "Analytics/Goals/Profile", tab tài khoản/đăng nhập (on-device, không login).
- Tối đa 3 mục (xa dưới trần 5 của HIG). Icon + label bắt buộc (không icon-only).
- A11y: `UITabBar` chuẩn; mục đang chọn báo trait `.selected` cho VoiceOver; target ≥ 44pt;
  tôn trọng safe-area đáy (home indicator).
- Round-tiering: Round 1 thực tế chỉ cần **Trang chủ + Cài đặt** (2 tab); tab **Mặt hồ** là
  **Round 2–3** (khớp `EXPERIENCE.md` §Kiến trúc thông tin) — xuất hiện ở **R2** khi có con sóng
  (thang mặt hồ) và đầy đủ ở **R3** khi có nhật ký/soi lại. Vẽ trong spec cho trọn vision, không
  phải scope code Mốc B.

---

## 3. WCAG 2.1 AA Contract

> Kiểm bằng `bmad-ux/scripts/contrast-check.py`. Bảng dưới là **số thật đã chạy**, không placeholder.

**Cặp màu đã verify (light mode)**

| Cặp | Ratio | AA normal (≥4.5) | AA large/graphic (≥3) | Ghi chú |
|-----|-------|:---:|:---:|---------|
| `ink.primary` #2A2A2A / `surface.page` #F8F8F8 | **13.52:1** | ✅ | ✅ | Chữ chính |
| `ink.primary` #2A2A2A / `surface.card` #FFFFFF | **14.35:1** | ✅ | ✅ | |
| `ink.secondary` #666666 / #F8F8F8 | **5.41:1** | ✅ | ✅ | Chữ phụ đạt cả body |
| **Chữ #2A2A2A / nút cam #FF7A1A** | **5.50:1** | ✅ | ✅ | **Luật cứng: nút cam = chữ tối** |
| ~~Chữ trắng #FFFFFF / cam #FF7A1A~~ | **2.61:1** | ❌ | ❌ | **CẤM** — đây là lý do dùng chữ tối |
| `brand.teal` #1D7C91 / #F8F8F8 | **4.55:1** | ✅ (sát) | ✅ | Ưu tiên tiêu đề/chữ lớn/icon, không body dài |
| `brand.teal` #1D7C91 / #FFFFFF | **4.83:1** | ✅ | ✅ | |
| `brand.tealStrong` #155A66 / `tealLight` #E8F2F4 | **6.86:1** | ✅ | ✅ | Chữ badge số bước (KHÔNG dùng #1D7C91 ở đây — chỉ 4.24:1, TRƯỢT) |
| `neutral.stoneStrong` #5E6E73 / #F8F8F8 | **5.00:1** | ✅ | ✅ | Đường phẳng "không bao giờ" (mang nghĩa) |
| ~~`neutral.stone` #8A9BA0 / #F8F8F8~~ | **2.72:1** | ❌ | ❌ | **Chỉ cho sóng trang trí**, KHÔNG cho graphic mang nghĩa |
| `tealStrong` #155A66 / `surface.card` #FFFFFF | **7.82:1** | ✅ | ✅ | Chữ đoạn đang chọn của segmented control |
| `ink.secondary` #666666 / `tealLight` #E8F2F4 | **5.04:1** | ✅ | ✅ | Chữ đoạn không chọn segmented |
| `brand.teal` #1D7C91 / `line.divider` #E5E7E8 | **3.90:1** | — | ✅ | Slider track đã tô (graphic) |
| Chữ trắng #FFFFFF / `brand.teal` #1D7C91 | **4.83:1** | ✅ | ✅ | Chỉ dùng nếu cần pill teal-đặc (mặc định ưu tiên pill trắng) |

**Cặp màu đã verify (dark mode)**

| Cặp | Ratio | Ghi chú |
|-----|-------|---------|
| `brand.teal` #4FB6CC / #000000 | 8.90:1 | Sóng/link trên nền đen |
| `brand.teal` #4FB6CC / #1C1C1E | 7.21:1 | Trên card tối |
| Chữ #2A2A2A / cam #FF7A1A (trên nền tối) | 5.50:1 | Nút cam giữ chữ tối, không đổi |
| `ink.secondary` #9BA3A6 / #000000 | 8.18:1 | Chữ phụ dark |

**Bàn phím & focus (iOS)**

- Mọi phím/nút **≥ 44×44pt** hit area (mở rộng nếu visual nhỏ hơn). Khe ≥ 8pt giữa target
  rời nhau (phím sát nhau chấp nhận theo chuẩn bàn phím iOS gốc).
- Hỗ trợ **VoiceOver**: mỗi phím có label; thứ tự đọc = thứ tự đọc trực quan.
- Hỗ trợ **Full Keyboard Access / Switch Control** ở container app.
- Không tràn ngang ở iPhone SE (375pt).

**Dynamic Type & motion**

- Toàn app hỗ trợ Dynamic Type; layout cuộn/giãn khi chữ to, không cắt.
- **Reduce Motion**: sóng đứng yên, tắt "pop" phím, chuyển màn không animation.
- **Reduce Transparency / Increase Contrast**: né blur; nếu bật Increase Contrast, dùng
  `brand.tealStrong`/`stoneStrong` thay bản nhạt.

**Cấu trúc ngữ nghĩa (spec cho dev)**

- Container app: mỗi màn 1 tiêu đề rõ (`.title2`), phân cấp không nhảy bậc.
- `UIButton` cho hành động, không gắn tap lên `UILabel`.
- Ảnh trang trí (con sóng): `isAccessibilityElement=false`. Nội dung đọc được: có label.
- Thay đổi động (câu quan sát xuất hiện): thông báo qua `UIAccessibility.post(.announcement)`.

---

## 4. Design Decisions

| Quyết định | Lý do | Đã cân nhắc gì khác |
|-----------|-------|---------------------|
| Nút cam #FF7A1A dùng chữ tối #2A2A2A, cấm chữ trắng | Chữ trắng/cam chỉ 2.61:1 (trượt AA); chữ tối 5.50:1 (đạt). Đồng bộ luật đã chốt bên macOS | Đổi cam đậm hơn để cứu chữ trắng → lệch brand + tới #C85400 vẫn chỉ 4.45:1, chưa đạt |
| Chữ teal trên tealLight dùng `#155A66` không `#1D7C91` | #1D7C91/tealLight chỉ 4.24:1 (trượt normal). #155A66 → 6.86:1 | Làm badge nền đậm hơn → lệch tông nhạt mong muốn |
| Đường phẳng "không bao giờ" dùng `#5E6E73` không `stone #8A9BA0` | stone gốc 2.72:1 (trượt cả graphic 3:1). #5E6E73 → 5.00:1. Giữ stone gốc cho sóng trang trí | Giữ stone cho cả 2 → graphic mang nghĩa không đọc được |
| Phân biệt trạng thái bằng **sóng vs đường phẳng**, không ✓xanh/✗đỏ | Hiến chương cấm mã màu valence; biên độ là ẩn dụ lõi; không phụ thuộc màu (mù màu vẫn đọc) | Tick xanh/gạch đỏ kiểu Laban → phạm §2.2 trực diện |
| KHÔNG có token semantic success/error đỏ-xanh | Cấm chấm điểm cảm xúc bằng màu. Lỗi hệ thống dùng ink + copy | Bộ semantic web mặc định → kéo theo đèn đỏ-xanh |
| Full Access onboarding nói THẬT "gõ được mà chưa cần bật" | Round 1 gõ không cần Full Access; xin quyền thừa là phản riêng-tư-mặc-định | Ép bật Full Access ngay → mất niềm tin, khác biệt vs Laban mất |
| Bỏ toàn bộ theme store/ví xu/đếm tải của Laban | Gamification + tiền tệ hoá phạm §2.2 | Giữ marketplace tông trung tính → vẫn là gamification lõi |
| **Font HYBRID** (2026-07-11): Montserrat/Inter cho container app, SF Pro cho keyboard extension | Brand muốn Montserrat/Inter; nhưng nhồi font vào extension tốn RAM (trần 48–60MB). Hybrid: đúng nhận diện ở app, an toàn+native ở bàn phím | (a) tất cả Montserrat/Inter → rủi ro RAM bàn phím; (b) tất cả SF Pro → mất bản sắc typography brand |
| **moodScale 5 bậc** (`tokens.json`) làm thang con sóng chính thức, thay token stone tự chế cho biên độ | tokens.json đã có thang An→Cuộn desaturated; đây là nguồn brand chính thức. stone/stoneStrong lùi về vai "đường phẳng không xảy ra" | Giữ stone tự chế cho biên độ → lệch nguồn brand + thiếu bậc |
| **radius.control 12→8pt, bóng card → teal `rgba(29,124,145,.08)`** | Reconcile khớp `tokens.json` (nguồn hình khối chính thức); tránh drift giữa DESIGN.md và brand | Giữ 12pt/bóng đen → 3 bản token lệch nhau |
| **Container app dùng tab bar 3 mục** (Trang chủ/Mặt hồ/Cài đặt), keyboard KHÔNG tab | 3 bề mặt khác nhau (onboarding tuyến tính / container có tab / extension không tab). Bỏ tab "Cửa hàng/Tài khoản" của Laban (mình on-device, không store/login) | Bê thanh tab 5 mục của Laban → kéo theo store + account đã cắt |

---

*Part of the BMAD Planning & Orchestrator plugin. Produced by the `bmad-ux` skill.*
*Nguồn màu: `brand/tokens.json` (chính thức) + `platforms/apple/shared/BrandPalette.h`. Hiến chương: `docs/AGENT-BRIEF.md`.*
