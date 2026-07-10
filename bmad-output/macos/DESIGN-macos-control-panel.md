# DESIGN.md — Bảng điều khiển macOS (mindful-key) — Hệ thống thị giác

**Epic:** Hiện đại hóa Bảng điều khiển macOS · **Platform:** macOS (AppKit) · **Track:** bmad-method
**Nguồn:** `brainstorming-report-macos-control-panel.md`, NOW BRAND OS, HIẾN CHƯƠNG §2.2/2.3
**Trạng thái:** LOCKED planning artifact — dev tool đọc, không sửa. Đổi thiết kế → ghi `decision-log.md`.

> ⚖️ **Luật tối cao ở tài liệu này là HIẾN CHƯƠNG, không phải "đẹp/hiện đại".** Mọi token,
> component, state bên dưới đã lọc qua §2.2/2.3. Xem §5 "Ràng buộc HIẾN CHƯƠNG nhúng vào design".

---

## 1. Design Tokens (lấy từ NOW BRAND OS — KHÔNG tự chế màu)

### 1.1 Color tokens

| Token | Hex | Vai trò | Cấm dùng cho |
|-------|-----|---------|--------------|
| `color.brand.teal` | `#1D7C91` | Chrome, tiêu đề, tint NSSwitch, glyph sóng `~` | — |
| `color.brand.tealLight` | `#E8F2F4` | Nền card gác cổng nhấn nhẹ, hover row | — |
| `color.cta.orange` | `#FF7A1A` | **CHỈ** nút CTA (Vẫn gửi/Lưu), link active | ❌ trạng thái ON/OFF · ❌ gradient cảm xúc · ❌ track slider |
| `color.cta.orangeLight` | `#FFF2E8` | Nền nhấn CTA rất nhẹ | như trên |
| `color.bg.window` | `#F8F8F8` | Nền panel | — |
| `color.bg.card` | `#FFFFFF` | Nền mọi card | — |
| `color.text.primary` | `#2A2A2A` | Chữ chính, **label trên nút cam** | — |
| `color.text.secondary` | `#666666` | Chữ phụ, mô tả, caption | — |
| `color.neutral.stone` | `#8A9BA0` | Sắc độ trung tính-đá cho sóng biên độ thấp | ❌ không dùng như "màu cảnh báo" |
| `color.divider` | `#E5E7E8` | Divider mảnh giữa section (1px) | — |

**KHÔNG có token semantic success/warning/error dạng đỏ-vàng-xanh-lá.** Đây là quyết định
có chủ đích: app này không mã hóa cảm xúc bằng màu (§5). Thông báo lỗi kỹ thuật (vd "không
lưu được cấu hình") dùng chữ `text.primary` + icon trung tính, KHÔNG dùng đỏ.

### 1.2 Thang sóng cảm xúc (emotion wave scale) — 1 hue duy nhất, chỉ đổi biên độ

Trạng thái cảm xúc KHÔNG dùng thang màu. Nó là **1 glyph sóng `~`, cùng 1 màu**
(`color.brand.teal` → nhạt dần về `color.neutral.stone` khi phẳng lặng), chỉ thay đổi:

| Mức | Biên độ (amplitude) | Tần số (frequency) | Độ dày nét | Copy mẫu (mô tả, không phán xét) |
|-----|--------------------|--------------------|-----------|----------------------------------|
| Phẳng lặng | ~0 (đường gần thẳng) | thấp | mảnh | "Mặt hồ đang phẳng lặng" |
| Gợn nhẹ | thấp | vừa | vừa | "Mặt hồ đang gợn nhẹ" |
| Gợn sóng | cao | vừa | vừa | "Mặt hồ đang gợn sóng" |

> Cần phân biệt các mức thì đổi **biên độ / tần số / độ dày nét** — TUYỆT ĐỐI không đổi hue
> (không teal→cam→đỏ). Không có "mức 4/5 màu đỏ". Không có nhãn số ("mức 3/5").

### 1.3 Typography

| Token | Font | Size | Weight | Line-height | Dùng cho |
|-------|------|------|--------|-------------|----------|
| `type.h1` | Montserrat | 20px | 700 | 1.3 | Tiêu đề card gác cổng |
| `type.h2` | Montserrat | 16px | 600 | 1.35 | Tiêu đề section (Chuông, Bộ gõ) |
| `type.body` | Inter | 14px | 400 | 1.5 | Nội dung, label control |
| `type.bodyStrong` | Inter | 14px | 600 | 1.5 | Nhãn quan trọng |
| `type.caption` | Inter | 12px | 400 | 1.45 | Cam kết riêng tư, tooltip |

> macOS panel dùng point (pt) ~ px logic ở scale 1x. Không có yêu cầu "16px min chống zoom
> iOS" vì đây là app AppKit desktop, không phải web mobile — nhưng giữ body ≥ 13px cho dễ đọc.

### 1.4 Spacing (lưới 8px), radius, elevation

- Spacing scale: `4 · 8 · 12 · 16 · 24 · 32`.
- Radius: `radius.card = 16px`, `radius.control = 8px` (nút/field nhỏ), `radius.pill = 999px` (segmented control 3 mức).
- Padding trong card: 16px. Khoảng cách giữa card: 12px. Lề panel: 16px.
- Elevation card: `0 8px 30px rgba(29,124,145,0.08)` (bóng ánh ngọc bích NOW BRAND OS). Không neon, không viền gắt.

### 1.5 Kích thước panel (menu-bar popover)

- Rộng cố định: **360px** (khớp cỡ popover menu-bar macOS, gần cỡ ảnh Haynoi tham chiếu).
- Cao: co theo nội dung, **cuộn dọc** nếu vượt ~600px. Không có breakpoint mobile/tablet
  (đây là 1 popover desktop cố định bề rộng) — bỏ qua thang breakpoint web của template.

---

## 2. Component Specs

### 2.1 `GatekeeperCard` — Card Gác cổng (Feature #1, ưu tiên tuyệt đối)

Thứ tự: **LUÔN đầu tiên, trên cùng.** Rộng: full-width panel. Nổi bật hơn mọi card khác.

- **Visual default:** nền `card` (#FFFFFF) trên viền `teal` 1.5px (đậm hơn card khác vốn không
  viền) + nền nhấn rất nhẹ `tealLight`. Tiêu đề `type.h1` "Gác cổng gửi tin". Dưới tiêu đề:
  glyph sóng `~` thu gọn (mặc định) + 1 câu mô tả (`type.body`, `text.secondary`):
  "Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi." Góc phải: 1 CTA text-link
  "Soi lại hôm nay →" (mở `ReflectionScreen`).
- **States:**
  - *default (bật):* như trên.
  - *hover:* nền card sáng nhẹ (`tealLight` đậm hơn 4%), con trỏ pointer trên vùng click.
  - *focus (keyboard):* outline 2px `teal` bao card, offset 2px.
  - *tắt gác cổng:* glyph sóng phẳng + copy "Gác cổng đang tắt." + nút bật lại. KHÔNG dùng
    màu đỏ/xám-chết để "cảnh báo đang tắt" — chỉ mô tả trung tính.
  - *đang căng (có tín hiệu thật):* biên độ sóng tăng (chậm, mượt), copy đổi sang "Mặt hồ
    đang gợn sóng". Không nhấp nháy, không đổi màu.
- **A11y:** role = group, `aria-label`="Gác cổng gửi tin — tính năng chính". CTA có label rõ.
  Toàn card reachable bằng Tab; Enter/Space kích hoạt lối tắt Soi lại.
- **Ràng buộc:** KHÔNG bao giờ thu nhỏ ngang cỡ card Chuông/Bộ gõ. KHÔNG gộp vào nhóm "Cài đặt chung".

### 2.2 `EmotionWave` — Widget sóng biên độ (trạng thái cảm xúc)

- **Visual default:** glyph sóng `~` vẽ vector (nguồn `brand/svg/`), màu `teal`↔`stone` theo
  biên độ (§1.2). **Mặc định THU GỌN** (một dải sóng nhỏ ~24px cao trong `GatekeeperCard`).
- **States:**
  - *collapsed (mặc định):* dải sóng nhỏ + copy 1 dòng. Đây là mặc định để né nghịch lý
    riêng tư (người đứng cạnh màn hình không đọc được chi tiết).
  - *expanded (user click "Xem thêm"):* sóng lớn hơn + copy mô tả + (tùy chọn) số liệu định
    lượng CHỈ khi user đã bật riêng (mặc định ẩn).
  - *nghỉ / không có tín hiệu:* sóng **tĩnh, phẳng, im lặng** (biên độ ~0). Không loop
    animation trang trí, không âm nền.
  - *có tín hiệu thật:* animate biên độ chậm (xem §4).
- **A11y:** `aria-label` mô tả bằng lời ("Trạng thái: mặt hồ đang gợn nhẹ"), cập nhật
  `aria-live="polite"` khi đổi — người dùng VoiceOver nghe mô tả, không phụ thuộc thị giác.
- **CẤM:** SF Symbol `face.*` (mặt cười/mếu), `exclamationmark.triangle` (cảnh báo), status
  dot 2 màu, progress bar tích lũy, thang màu đỏ-vàng-xanh.

### 2.3 `BellSettings` — Card cấu hình Chuông

Đặt DƯỚI `GatekeeperCard`. Nhỏ hơn, không viền nhấn.

- **Sub-controls:**
  1. `SensitivitySegmented` — segmented control 3 mức **định tính bằng chữ**: "Ít nhạy · Vừa · Nhạy"
     (radius.pill). Ánh xạ ẩn vào số ngưỡng câu căng phía sau (không hiện số ra mặt chính).
     Kéo/đổi mức → `EmotionWave` demo animate theo để "thấy" mức đó (không số, không thanh màu).
  2. `SoundDropdown` — NSPopUpButton chọn âm thanh chuông (thay hardcode `BellMac.mm:51`).
  3. `VolumeSlider` — NSSlider âm lượng. Track **1 màu trung tính** (`teal` nhạt→đậm cùng hue),
     KHÔNG gradient đa sắc, KHÔNG đầu mút màu cảnh báo.
  4. `QuietHours` — time-range picker (từ giờ → giờ) cho "giờ yên lặng". **Thủ công, độc lập.**
     Toggle "Đồng bộ Chế độ Tập trung của macOS" mặc định **OFF**, kèm caption giải thích
     quyền nếu bật (opt-in, không ngầm bật).
  5. `AdvancedDisclosure` — nút "Tùy chỉnh nâng cao ▸" ẩn/hiện chi tiết (vd số câu chính xác)
     cho ai muốn chỉnh sâu; mặc định thu gọn.
- **States:** mỗi control có default/hover/focus/active/disabled chuẩn AppKit. `disabled` khi
  tắt toàn bộ nhắc tâm → cả card mờ 40% + caption "Đang tắt nhắc tâm".
- **A11y:** segmented control có `aria-label` từng mức; slider có value announce; picker keyboard-reachable.
- **CẤM:** progress bar "3/5 câu", animation ăn mừng khi chạm ngưỡng, nút "xem thử ngay" cạnh
  slider số (né cảm giác "chọn độ khó game").

### 2.4 `InputMethodCard` — Card Bộ gõ (phần OpenKey cũ, gọn lại)

- Gom Telex/VNI/TCVN3, macro, các checkbox hệ thống cũ vào 1 card cuộn được, thu gọn theo
  disclosure. Dùng `PillSwitch` (NSSwitch tint teal) thay checkbox vuông.
- **StatusDot:** dot cạnh header CHỈ báo *bộ gõ đang bật/tắt tiếng Việt* — nhị phân, **1 màu**
  (`teal` khi bật, viền `divider` no-fill khi tắt). TUYỆT ĐỐI không dùng dot này cho cảm xúc.

### 2.5 `PillSwitch` — Toggle (thay checkbox)

- NSSwitch với **tint override = `teal`** (KHÔNG để xanh-lá hệ thống mặc định — né tái tạo
  cặp đèn xanh/đỏ bị cấm). Off = xám `divider`.
- States: on/off/focus (outline 2px teal)/disabled (40% opacity).

### 2.6 `CTAButton` — Nút hành động (Vẫn gửi / Lưu)

- **Nền `cta.orange` #FF7A1A + chữ TỐI `text.primary` #2A2A2A** (KHÔNG chữ trắng — xem §3,
  chữ trắng trên cam chỉ đạt 2.61:1, trượt AA; chữ tối đạt 5.50:1). Radius.control 8px.
- States: hover (cam đậm nhẹ), focus (outline 2px), active (nhấn xuống 1px), disabled (40%).
- Cam CHỈ xuất hiện ở đây và link active — không ở đâu khác.

### 2.7 `PrivacyFooterRow` — Hàng cam kết riêng tư (cuối panel)

- Vị trí cố định cuối trang (như "account row" của Haynoi). `type.caption`, `text.secondary`:
  "Mọi xử lý cảm xúc chạy trên máy bạn · không gửi nội dung gõ đi đâu" + link "Chính sách riêng tư".

---

## 3. Hợp đồng WCAG 2.1 AA (đã verify bằng script, số thật)

| Cặp màu | Tỷ lệ | Normal text | Verdict |
|---------|-------|-------------|---------|
| `text.primary #2A2A2A` / card `#FFFFFF` | **14.35:1** | PASS | ✅ (cả AAA) |
| `text.primary #2A2A2A` / window `#F8F8F8` | **13.52:1** | PASS | ✅ (cả AAA) |
| `text.secondary #666666` / card `#FFFFFF` | **5.74:1** | PASS | ✅ AA |
| `text.secondary #666666` / window `#F8F8F8` | **5.41:1** | PASS | ✅ AA |
| `teal #1D7C91` / white (heading/link) | **4.83:1** | PASS | ✅ AA |
| white / `teal #1D7C91` (chrome) | **4.83:1** | PASS | ✅ AA |
| `teal #1D7C91` / window `#F8F8F8` (glyph sóng, UI component) | **4.55:1** | PASS | ✅ AA |
| ⚠️ white / `orange #FF7A1A` | **2.61:1** | **FAIL** | ❌ CẤM — dùng chữ tối thay |
| ✅ `text.primary #2A2A2A` / `orange #FF7A1A` (CTA đã sửa) | **5.50:1** | PASS | ✅ AA |

**Quy tắc rút ra (bắt buộc trong dev):**
- Nút CTA cam → **luôn dùng chữ tối #2A2A2A**, không bao giờ chữ trắng.
- `text.secondary #666666` chỉ đạt AA (không AAA) — ổn cho caption/mô tả, nhưng nội dung
  quan trọng dùng `text.primary`.

**Cam kết a11y khác:**
- Focus indicator: outline 2px `teal` solid, offset 2px, trên MỌI control reachable.
- Mọi chức năng thao tác được bằng bàn phím (Tab/Shift-Tab/Enter/Space/mũi tên cho segmented+slider).
- Target size: nút/control ≥ 28×28pt (chuẩn macOS pointer; app desktop không cần 44px như touch,
  nhưng giữ ≥ 28pt + spacing ≥ 8px).
- VoiceOver: `EmotionWave` bắt buộc có mô tả bằng lời + `aria-live=polite` (người khiếm thị
  không được phụ thuộc hình sóng).

---

## 4. Interaction & Animation

- `EmotionWave` biên độ: transition 400–600ms ease-in-out, **chỉ chạy khi có tín hiệu thật**
  (đang gõ / vừa có câu căng). Nghỉ = tĩnh hoàn toàn.
- Disclosure (thu gọn/mở rộng): 200ms ease-out.
- `prefers-reduced-motion` / "Giảm chuyển động" của macOS: khi bật, `EmotionWave` chuyển
  trạng thái tức thời (cross-fade 0ms), không animate biên độ — chỉ đổi hình + copy.
- **Phân loại:** animation sóng là *meaningful* (phản ánh dữ liệu thật). KHÔNG có animation
  *decorative* loop vô nghĩa (né cảm giác bị theo dõi 24/7).
- ⚠️ Sóng phải chậm/mượt: nếu nhanh/giật sẽ đọc như cảnh báo nhấp nháy → ngả sang phán xét.

---

## 5. Ràng buộc HIẾN CHƯƠNG nhúng vào design (§2.2/2.3 — bất khả xâm phạm)

Checklist này là 1 phần của DESIGN.md, dev + reviewer phải soi mỗi thay đổi UI:

1. ❌ KHÔNG đèn đỏ/vàng/xanh-lá mã hóa cảm xúc. Thang cảm xúc = **1 hue, chỉ đổi biên độ**.
2. ❌ KHÔNG SF Symbol `face.*` (mặt cười/mếu) hay `exclamationmark.triangle`/`xmark.octagon`
   màu cảnh báo cho trạng thái. Chỉ glyph sóng tự vẽ.
3. ❌ KHÔNG progress bar tích lũy / streak / badge / điểm số / huy hiệu cho ngưỡng hay mood.
4. ❌ KHÔNG badge Dock/menu-bar đếm số lần gác cổng (né phơi số nhạy cảm ra công khai).
5. ✅ NSSwitch/toggle liên quan mood override tint về **teal**, không xanh-lá hệ thống.
6. ✅ Cam `#FF7A1A` CHỈ ở CTA + link active. Không ở trạng thái ON/OFF, không track slider,
   không gradient cảm xúc.
7. ✅ **Riêng tư trong UI:** không render nội dung gõ thật (kể cả rút gọn), không lịch sử
   chi tiết theo dòng (timestamp/tên app), không biểu đồ theo thời gian trong panel, không
   so sánh xã hội/thời gian. Mood mặc định **thu gọn**.
8. ✅ **Gate copy bắt buộc — "mô tả hay phán xét?":** mọi câu hiển thị trạng thái, trước khi
   merge, phải tự trả lời câu này. "Mặt hồ đang gợn sóng" = mô tả ✅. "Bạn đang căng thẳng,
   hãy bình tĩnh" = phán xét ❌. Ghi 1 dòng xác nhận trong story/PR, không dựa trí nhớ.
9. ✅ Giờ yên lặng = thủ công; đồng bộ Focus Mode mặc định OFF, opt-in có giải thích quyền.
10. ✅ Feature #1 (gác cổng) luôn trên cùng, nổi bật nhất — redesign không được giảm độ nổi
    bật so với bản cũ.

---

## 6. Component ↔ code hiện tại (bản đồ cho dev sau này)

| Component (mới) | Chạm code thật | Chuyên gia phụ trách |
|-----------------|----------------|----------------------|
| Bố cục panel, card, PillSwitch, StatusDot, CTAButton | `ViewController.m` + `Main.storyboard` | platform-shell-agent |
| `BellSettings` (âm/volume/ngưỡng) | `BellMac.mm`, `NudgeCoordinatorMac.mm` (đọc UserDefaults thay hardcode) | mood-layer-agent + platform-shell |
| `EmotionWave`, copy trạng thái | glyph `brand/svg/`, logic biên độ từ `MoodWatchMac` | mood-layer-agent |
| Lối tắt "Soi lại hôm nay" | `ReflectionScreenMac` | mood-layer-agent |

> Khi sang code thật: qua `mindful-keyboard-harness` để không lẫn ranh giới engine/mood/shell.
