# EXPERIENCE.md — User Experience Plan (iOS)

> **LOCKED PLANNING ARTIFACT.** Công cụ dev đọc, KHÔNG sửa. Mọi thay đổi qua `bmad-ux`,
> ghi vào `bmad-output/ios/decision-log.md`.

**Project:** mindful-key — vỏ iOS
**Track:** Quick Flow
**Date:** 2026-07-10
**Version:** 0.3 (draft — chốt bản đồ 6-module + IA 3-bề-mặt + tab nav + màn Soi lại câu-hỏi-trước; chờ duyệt)

---

## Overview

Vỏ iOS là **bàn phím tiếng Việt chánh niệm** dạng Custom Keyboard Extension + một container
app mỏng lo onboarding và (về sau) nhật ký. Round 1 là **walking skeleton**: chứng minh gõ
được Telex qua `core/engine` trong sandbox extension, và dẫn người dùng vượt "cửa ải khó
nhất của mọi bàn phím bên thứ ba" — bật bàn phím lên và hiểu quyền Full Access.

Tài liệu này đặc tả **journey + screen states của Round 1**. Round 2+ (con sóng cảm xúc,
nhật ký, soi lại cuối ngày) chỉ **phác nhẹ** ở cuối, chưa đặc tả đủ.

**Personas:** người dùng iPhone gõ tiếng Việt hằng ngày (nhắn tin, mạng xã hội), muốn một
bàn phím "nhắc mình chậm lại", không phán xét, không theo dõi. Không rành kỹ thuật — cửa
onboarding phải cực rõ.

**Platform targets:** iPhone (iOS 16+), portrait trước. iPad/landscape = ngoài Round 1.
**Design system reference:** `bmad-output/ios/DESIGN.md`.

> 🧭 **Ranh giới hiến chương cho mọi journey dưới đây:** KHÔNG có luồng "chặn Enter / gác cổng
> gửi tin" trên iOS (sandbox chặn — đã chốt mandate 2026-07-10; nhận diện người-gác-cổng giữ
> ở macOS). iOS chỉ **quan sát + nhắc thụ động**. KHÔNG màn nào chấm điểm cảm xúc bằng màu/
> emoji. Copy mọi màn qua bài kiểm *"mô tả hay phán xét?"*.

---

## Kiến trúc thông tin — bản đồ 6 module + 3 bề mặt (chốt 2026-07-11)

> Chốt sau khi hệ thống hoá mockup (Claude Design) + đối chiếu triage Laban (L1–L5). Chất riêng
> Mindful Key nằm ở **lớp cảm xúc dệt vào bàn phím** (Module 4) — đó là xương sống, không phải
> tính năng phụ. Nguyên tắc: **phủ mọi chức năng bằng số màn TỐI THIỂU**, không dựng lại kiểu
> Laban (7 màn cài đặt rời + cửa hàng theme).

### 3 bề mặt (chi phối điều hướng — đừng gắn nav lung tung)

| Bề mặt | Điều hướng | Màn |
|--------|-----------|-----|
| **Onboarding** | Tuyến tính, 1 lần, KHÔNG tab bar (chỉ tiến/lùi) | Splash · Kích hoạt · Full Access |
| **Container app** | **Tab bar 3 mục** (§DESIGN 2.12): Trang chủ · Mặt hồ · Cài đặt | Trang chủ, Cài đặt (+ màn con), Mặt hồ (nhật ký/soi lại/thang) |
| **Keyboard extension** | KHÔNG tab bar — hiện đè trong app khác (Zalo/Notes) | Bàn phím + 3 trạng thái (sóng gợi ý, thẻ mời thở) |

### 6 module — bản đồ màn + phủ L + round-tier

> ⚠️ **Đừng lẫn 2 thang "1–5":** cột **"Phủ L"** dưới đây = **lô thiết kế Laban** (L1–L5, cách
> chia ảnh tham khảo gửi Claude Design — xem `ref-ux-ui-laban-key/L-MAP.md`), HOÀN TOÀN KHÁC với
> **mức sóng cảm xúc 1–5** (An→Cuộn, `moodScale` trong `DESIGN.md §1.1`). "L5" = nhóm màn nguy
> hiểm cần mổ bỏ; "mức 5 = Cuộn" = sóng cao nhất. Hai hệ trực giao, không liên quan nhau.

| Module | Màn | Bề mặt | Phủ L | Round |
|--------|-----|--------|-------|-------|
| **1 · Vào cửa** | Splash · Kích hoạt bàn phím · Full Access (cặp sóng/đường phẳng) | Onboarding | L1 | 1 |
| **2 · Bàn phím** | 1 màn, **3 trạng thái**: (a) gõ Telex · (b) +sóng thanh gợi ý + câu quan sát · (c) +thẻ mời thở (không chặn) | Extension | — | 1 (a) · 2 (b,c) |
| **3 · Ngôi nhà** | Trang chủ · Cài đặt (GỘP 1 màn hub) | Container | — | 1 |
| **4 · Lớp cảm xúc (linh hồn)** | Thang mặt hồ 5 mức · Lớp nhịp thở (mức 5, full screen) · Soi lại cuối ngày | Container (tab Mặt hồ) + Extension | — | 2–3 |
| **5 · Cài đặt chi tiết** | ~5 màn con drill-down: Bàn phím (kiểu gõ+chiều cao+preview) · Sửa lỗi/gợi ý · Gõ tắt · Âm&rung+Chuông · Giới thiệu (credit GPL) | Container (dưới tab Cài đặt) | **L2 + L3** | 1–2 |
| **6 · Nền cá nhân** (tuỳ chọn) | Chọn nền tĩnh + ảnh của bạn · slider Làm mờ (legibility) · bàn phím trên nền khó | Container (Cài đặt › Giao diện) | **L4** | 3 |

**L5 (nhóm nguy hiểm) — cố ý KHÔNG thành module:** cửa hàng theme → chuyển thành gallery nền
tĩnh (Module 6, không marketplace); ghi chú tô màu → bỏ mã màu, phần "câu hay dùng" nằm ở Gõ
tắt (Module 5); value-prop "kho chủ đề/tiết kiệm %" → bỏ.

**Ghi chú round-tier cho Mốc B:** Round 1 (đang code) chỉ cần Module 1 + 2(a) + 3 (Trang chủ +
Cài đặt tối thiểu). Tab "Mặt hồ" + Module 4/6 là Round 2–3 — đã đặc tả để trọn vision, **không
phải scope code ngay**.

---

## User Journeys

### Journey 1: Lần đầu mở app → bật được bàn phím (Round 1 — critical path)

**Goal:** người dùng bật bàn phím Mindful Key và gõ được tiếng Việt trong một app thật.
**Persona:** người dùng mới, chưa từng cài bàn phím bên thứ ba.
**Estimated time:** 60–90 giây (nếu không vướng).
**Entry points:** mở app lần đầu sau khi cài từ TestFlight/App Store.
**Success criteria:** gõ ra "tiếng Việt" có dấu bằng Telex trong Notes/Zalo.

#### Happy Path

```
[Mở app lần đầu]
      |
      v
[Màn 01 — Kích hoạt bàn phím]  ← 3 bước đánh số + nút "Mở Cài đặt"
      |
      v
[Cài đặt hệ thống]  ← người dùng bật "Mindful Key" trong Bàn phím
      |
      v
[Quay lại app]  ← container đọc App Group heartbeat → biết đã bật (Round 1 chỉ đoán "đã chạy")
      |
      v
[Màn 02 — Về Full Access]  ← minh bạch; "gõ được mà chưa cần bật"; có thể "Để sau"
      |
      v
[Màn Home — sẵn sàng]  ← ô "gõ thử" + nhắc chạm 🌐 để chuyển bàn phím
      |
      v
[Gõ Telex trong app bất kỳ]  ← END: ra chữ có dấu
```

#### Decision Points & Alternative Paths

| Trigger | Hiển thị | Recovery |
|---------|----------|----------|
| Người dùng bấm "Chưa thấy Mindful Key?" ở Màn 01 | Hướng dẫn fallback (kiểu Laban "không kích hoạt được?"): ảnh/bước tĩnh chỉ đúng đường trong Cài đặt | Quay lại thử lại; không đổ lỗi ("có thể iOS cần vài giây để hiện") |
| Quay lại app nhưng **chưa** bật bàn phím (heartbeat trống) | Màn 01 vẫn hiển thị, chỉ báo bước vẫn ở "1/2" | Không quở trách; lặp lại hướng dẫn nhẹ nhàng |
| Người dùng chọn "Để sau" ở Màn 02 (Full Access) | Đi thẳng tới Home; app KHÔNG nài | Có thể bật Full Access sau trong Home/Cài đặt khi muốn con sóng (Round 2) |
| Bàn phím bật rồi nhưng người dùng chưa biết chuyển qua nó | Home có coach-mark nút 🌐 | Câu chỉ dẫn 1 dòng, không popup dồn dập |

#### Drop-off Risk Notes

Rủi ro rớt lớn nhất = **bước rời-app-sang-Cài-đặt-rồi-quay-lại** (cố hữu của mọi bàn phím
iOS bên thứ ba). Giảm bằng: đánh số bước rõ, nút "Mở Cài đặt" đưa thẳng tới đúng chỗ (deep
link `App-Prefs` nếu còn hiệu lực, nếu không thì hướng dẫn tĩnh), và fallback "chưa thấy?".
**Giới hạn nền tảng thật:** iOS KHÔNG cho app biết chắc bàn phím đã bật — heartbeat App Group
chỉ đoán "đã từng chạy", KHÔNG phát hiện lúc người dùng TẮT lại. Chấp nhận ở Round 1 (ghi rõ,
không giả vờ chắc chắn).

---

### Journey 2: Gõ Telex trong khung bàn phím (Round 1 — Mốc B)

**Goal:** gõ ra tiếng Việt có dấu.
**Entry:** bất kỳ ô nhập nào ở host app, sau khi chuyển sang Mindful Key bằng 🌐.
**Success:** "vieetj" → "việt"; "chaof" → "chào".

#### Happy Path

```
[Chạm ô nhập ở host app]
      |
      v
[Chạm 🌐 → chọn Mindful Key]  ← bàn phím tự vẽ hiện lên
      |
      v
[Gõ phím chữ]  ← mỗi phím: EngineKeyMap tra KEY_x → vKeyHandleEvent → pData
      |
      v
[Bàn phím chèn/xoá qua UITextDocumentProxy]  ← ra chữ có dấu đúng chỗ con trỏ
```

#### Decision Points

| Trigger | Hiển thị | Recovery |
|---------|----------|----------|
| Ô nhập là ô mật khẩu (secure) | Bàn phím vẫn gõ chữ thường; KHÔNG đọc/ghi gì thêm | Tôn trọng: không có sóng, không log (kể cả Round 2) |
| Chưa có Full Access | Gõ vẫn chạy bình thường (không cần quyền để insert/delete) | Không chặn; chỉ tính năng sóng (Round 2) mới cần |

#### Drop-off Risk Notes

Rủi ro kỹ thuật (không phải UX): extension bị iOS kill vì vượt RAM giữa lúc gõ → bàn phím
"chết", người dùng hoang mang. Giảm bằng UI nhẹ (DESIGN §1.4) + macro/smart-switch rỗng
mặc định (tech-spec). Cần đo Instruments thật.

---

## Screen / State Inventory

### Screen: Màn 01 — Kích hoạt bàn phím

**Purpose:** dẫn người dùng bật Mindful Key trong Cài đặt.
**Entry from:** mở app lần đầu.
**Exits to:** Cài đặt hệ thống (qua nút) / Màn 02 (khi quay lại đã bật).

#### Layout Wireframe (mobile-first)

```
┌──────────────────────────────┐
│ ~  Mindful Key       ▭ ▭ (1/2)│  brand-mark + step indicator
│                              │
│ Thêm Mindful Key vào         │  .title2, ink.primary
│ bàn phím của bạn             │
│ Chỉ một lần. Sau đó chạm 🌐   │  .subheadline, ink.secondary
│ để gọi bất cứ khi nào.       │
│                              │
│ ①  Mở Cài đặt › Cài đặt      │  ol bước — số = trình tự thật
│    chung › Bàn phím          │
│ ②  Bàn phím › Thêm bàn       │
│    phím mới…                 │
│ ③  Chọn Mindful Key          │
│                              │
│ ┌──────────────────────────┐ │
│ │      Mở Cài đặt          │ │  CTA cam #FF7A1A / chữ #2A2A2A
│ └──────────────────────────┘ │
│   Chưa thấy Mindful Key?     │  ghost, brand.teal
└──────────────────────────────┘
```

#### Component Hierarchy
1. Brand-mark (sóng `~` + wordmark) + step indicator (§DESIGN 2.9)
2. Tiêu đề `.title2` + phụ đề `.subheadline`
3. Danh sách 3 bước đánh số (badge `tealLight` + chữ `tealStrong`)
4. CTA primary "Mở Cài đặt"
5. Nút ghost "Chưa thấy Mindful Key?"

#### Named States

**Default:** như wireframe, step "1/2".

**Loading:** không có async nặng — bỏ qua (ghi rõ: màn tĩnh).

**Empty:** không áp dụng.

**Error:** nút "Mở Cài đặt" không mở được deep link (iOS đổi scheme) → thay bằng hướng dẫn
tĩnh "Mở app Cài đặt › Cài đặt chung › Bàn phím". **Không tô đỏ**, không "Lỗi!" — chỉ đổi
sang chỉ dẫn thủ công, giọng bình thản.

**Success (ngầm):** khi quay lại app và heartbeat báo đã chạy → tự chuyển Màn 02. Không
cần toast ăn mừng (né gamification) — chuyển màn êm là đủ.

**Disabled:** không áp dụng.

#### Interactions & Animations

| Interaction | Behavior | Timing | Reduced-motion |
|-------------|----------|--------|----------------|
| Sóng brand-mark | Gợn biên độ thấp, chậm | ~2.6s/chu kỳ | Đứng yên |
| Vào màn | Fade nhẹ | 200ms ease-out | Instant |
| Nhấn CTA | Scale 0.98 + cam tối nhẹ | 100ms | Chỉ đổi màu |

#### Accessibility

- Tiêu đề màn = heading. Bước = `UIStackView` đọc theo thứ tự "bước 1…2…3".
- Sóng brand-mark trang trí → `isAccessibilityElement=false`.
- Step indicator `accessibilityLabel="Bước 1 trên 2"`.
- CTA target ≥ 50pt.

---

### Screen: Màn 02 — Về Full Access

**Purpose:** minh bạch quyền Full Access TRƯỚC khi iOS hỏi; thành thật rằng chưa bắt buộc.
**Entry from:** quay lại app sau khi bật bàn phím.
**Exits to:** Home (bật hoặc "Để sau" đều tới Home).

#### Layout Wireframe

```
┌──────────────────────────────┐
│ ~  Mindful Key       ▭ ▭ (2/2)│
│                              │
│ Về quyền Truy cập Đầy đủ     │  .title2
│ iOS sẽ hỏi bạn bật "Cho phép │  .subheadline
│ Truy cập Đầy đủ". Đây là     │
│ điều nó thật sự làm.         │
│                              │
│ ~   BẬT LÊN ĐỂ               │  sóng teal + nhãn caption
│     Mindful Key đọc câu bạn  │  (biên độ = "có xảy ra")
│     vừa gõ — ngay trên máy — │
│     để con sóng ~ phản chiếu │
│     nhịp gõ của bạn.         │
│                              │
│ ──  KHÔNG BAO GIỜ            │  đường phẳng stoneStrong + nhãn
│     Chữ bạn gõ không rời     │  (mặt phẳng = "không xảy ra")
│     khỏi máy. Không gửi,     │
│     không lưu, không ai đọc. │
│                              │
│ ┌ Bạn vẫn gõ bình thường mà ┐│  reassure card, nền elev
│ └ chưa cần bật. Bật khi muốn┘│
│ ┌──────────────────────────┐ │
│ │   Bật Truy cập Đầy đủ     │ │  CTA cam / chữ tối
│ └──────────────────────────┘ │
│          Để sau              │  ghost
└──────────────────────────────┘
```

#### Component Hierarchy
1. Brand-mark + step "2/2"
2. Tiêu đề + phụ đề
3. **Cặp biên độ** (§DESIGN 2.10): dòng "Bật lên để" (sóng `~` teal) + dòng "Không bao giờ"
   (đường phẳng `stoneStrong`) — mỗi dòng có nhãn caption + body
4. Card trấn an ("chưa cần bật")
5. CTA "Bật Truy cập Đầy đủ" + ghost "Để sau"

#### Named States

**Default:** như wireframe.

**Decision — Bật:** chạm CTA → iOS hiện popup hệ thống thật (app không kiểm soát nội dung
popup đó) → dù kết quả gì, về Home. Nếu người dùng bật thật → App Group đọc được, Round 2
mở khoá sóng.

**Decision — Để sau:** về Home ngay, không nài, không nhắc lại dồn dập. Home có lối bật lại.

**Error:** không áp dụng (không async).

**Success:** về Home. Không toast ăn mừng.

#### Interactions & Animations

| Interaction | Behavior | Timing | Reduced-motion |
|-------------|----------|--------|----------------|
| Sóng dòng "Bật lên để" | Gợn biên độ thấp | ~2.6s | Đứng yên (vẫn là hình sóng) |
| Đường phẳng "Không bao giờ" | Tĩnh (đó là điểm nhấn — mặt phẳng) | — | — |

#### Accessibility

- Cặp biên độ: **nghĩa nằm ở NHÃN CHỮ** ("Bật lên để" / "Không bao giờ"), sóng/đường phẳng
  chỉ minh hoạ → graphic `isAccessibilityElement=false`, nhãn + body đọc được. Không phụ
  thuộc màu/hình để hiểu (đạt WCAG 1.4.1 use-of-color).
- CTA + ghost đều ≥ 44pt, đọc rõ nhãn.

---

### Screen: Màn Home (container, tối thiểu Round 1)

**Purpose:** xác nhận "sẵn sàng", cho ô gõ thử, coach-mark 🌐. (Round 2+: lối vào nhật ký.)
**Entry from:** Màn 02.
**Exits to:** — (điểm dừng Round 1); về sau: Cài đặt bàn phím, Nhật ký.

#### Layout Wireframe

```
┌──────────────────────────────┐
│ ~  Mindful Key               │
│                              │
│ Bàn phím đã sẵn sàng          │  .title2 (mô tả trạng thái, không khen)
│ Chạm 🌐 trên bàn phím để      │  .body
│ chuyển sang Mindful Key.     │
│                              │
│ ┌ Gõ thử ở đây… ───────────┐ │  text field 17pt
│ └──────────────────────────┘ │
│                              │
│ (Round 2+: con sóng, nhật ký)│  ← phác, chưa làm
└──────────────────────────────┘
```

#### Named States

**Default:** như trên.
**Empty:** ô gõ thử trống → placeholder "Gõ thử ở đây…". Không phải lỗi.
**"Bàn phím chưa bật" (đoán từ heartbeat):** hiện nhắc nhẹ + nút quay lại Màn 01. Giọng
bình thản ("Có vẻ bàn phím chưa bật — thử lại nhé"), KHÔNG quở.

#### Accessibility
- Tiêu đề trạng thái = heading. Ô gõ thử có `accessibilityLabel`. Coach-mark 🌐 đọc được.

---

### Screen: Bàn phím Mindful Key (khung extension) — bề mặt lõi Round 1

**Purpose:** gõ tiếng Việt Telex/VNI qua `core/engine`; hiện trong ô nhập của host app.
**Entry from:** người dùng chạm 🌐 chọn Mindful Key ở bất kỳ app nào.
**Exits to:** — (bàn phím ẩn khi rời ô nhập hoặc đổi bàn phím khác).

#### Layout Wireframe (khung ~216–260pt cao)

```
┌──────────────────────────────┐
│ (thanh gợi ý)                │  ~40pt — Round 1: trống/gợi ý từ · Round 2: con sóng ~
├──────────────────────────────┤
│  q w e r t y u i o p         │  hàng 1
│   a s d f g h j k l          │  hàng 2
│  ⇧   z x c v b n m   ⌫       │  hàng 3 (⇧ trái, ⌫ phải)
│ 123  🌐   [ space ]   ↵      │  hàng dưới
└──────────────────────────────┘
```

#### Component Hierarchy
1. Thanh gợi ý (§DESIGN 2.6)
2. 3 hàng phím chữ (§DESIGN 2.5)
3. Hàng chức năng: ⇧ (Shift), 123 (đổi lớp), 🌐 (đổi bàn phím), space, ↵/⌫

#### Named States

**Default:** chữ thường, thanh gợi ý theo Round.

**Shift (một lần) / Caps (khoá):** ⇧ sáng `tealLight`; một lần = chữ hoa 1 ký tự rồi tự về;
double-tap ⇧ = khoá Caps (⇧ có chỉ dấu khoá). Đổi visual phím sang chữ hoa.

**Lớp số & ký hiệu:** chạm `123` → hàng phím thành số + ký hiệu; nút đổi thành `ABC` để quay
lại. (Lớp 2 ký hiệu phụ nếu cần — giữ tối giản Round 1.)

**Lần đầu hiện (first-appearance):** khung dựng < ~150ms; KHÔNG spinner (bàn phím phải tức
thì). `KeyboardBridge_Init()` chạy 1 lần nền, không chặn UI.

**Ô bảo mật (secure text field):** vẫn gõ chữ bình thường; **tuyệt đối không đọc/log/hiện
sóng** — kể cả Round 2. (Riêng tư mặc định; là điểm khác biệt so với "bàn phím thường".)

**Không có Full Access:** gõ chạy bình thường (insert/delete không cần quyền). Chỉ tính năng
sóng (Round 2) mới cần → thanh gợi ý ở trạng thái Round 1.

#### Interactions & Animations

| Interaction | Behavior | Timing | Reduced-motion |
|-------------|----------|--------|----------------|
| Nhấn phím chữ | Sáng nền `tealLight` + scale 0.97 + "pop" preview ký tự phía trên (như iOS gốc) | ~80ms | **Tắt pop**, giữ đổi nền |
| Giữ phím (long-press) | Hiện ký tự/dấu phụ nếu có (vd giữ để lấy số/ký tự thay thế) | 400ms giữ | Không đổi |
| Nhấn ⌫ giữ | Xoá lặp tăng tốc | chuẩn iOS | Không đổi |

#### Accessibility
- Mỗi phím `accessibilityLabel` rõ ("chữ a", "phím hoa", "xoá lùi", "đổi bàn phím", "phím
  cách"). Hit area ≥ 44pt kể cả khi visual phím hẹp hơn (mở rộng vùng chạm).
- VoiceOver đọc theo thứ tự hàng trái→phải, trên→dưới.
- Sóng ở thanh gợi ý = trang trí → `isAccessibilityElement=false` (xem §DESIGN 2.6).
- **RAM nhẹ:** không blur/ảnh nền/bóng nặng trong khung — né trần ~48–60MB (đo bằng Instruments).

---

### Screen: Cài đặt bàn phím (container app)

**Purpose:** chỉnh bàn phím tại chỗ, thấy kết quả ngay (kế thừa "slider trực tiếp + preview
sống" của Laban; BỎ mọi gamification/ví xu/đếm tải).
**Entry from:** Home → mục Cài đặt.
**Exits to:** Home; hoặc màn con Gõ tắt/macro.

#### Layout Wireframe

```
┌──────────────────────────────┐
│ Cài đặt bàn phím              │  .title2
│                              │
│ ┌ Preview sống ────────────┐ │  khung bàn phím thu nhỏ, cập nhật realtime
│ │  q w e r t y … (mô phỏng) │ │
│ └──────────────────────────┘ │
│                              │
│ Kiểu gõ      [ Telex | VNI ] │  segmented (§DESIGN 2.11), chọn = teal
│ Chiều cao    ●───────  ──   │  slider (§DESIGN 2.11)
│ Gõ tắt / macro            > │  list row → màn con
└──────────────────────────────┘
```

#### Component Hierarchy
1. Tiêu đề `.title2`
2. Khu **Preview sống** (khung bàn phím thu nhỏ)
3. List rows: Kiểu gõ (segmented Telex/VNI), Chiều cao (slider), Gõ tắt/macro (row → màn con)

#### Named States

**Default:** giá trị hiện tại (đọc từ App Group/UserDefaults).

**Preview cập nhật realtime:** chỉnh slider/segmented → khung preview đổi NGAY (không cần
lưu/thoát). Đây là điểm UX cốt lõi kế thừa Laban.

**Empty (chưa có macro):** màn con Gõ tắt trống → dòng gợi ý "Chưa có gõ tắt nào. Thêm một
mục để gõ nhanh cụm bạn hay dùng." + nút thêm. Không phải lỗi, giọng bình thản.

**Loading/Error:** không async nặng (đọc UserDefaults local) → bỏ qua.

#### Interactions & Animations

| Interaction | Behavior | Timing | Reduced-motion |
|-------------|----------|--------|----------------|
| Kéo slider chiều cao | Preview đổi realtime | tức thì | Tức thì (không animate) |
| Đổi Telex/VNI | Preview đổi cách hiển thị gõ | tức thì | — |

#### Accessibility
- Slider `accessibilityValue` đọc được; segmented đúng role selected. Mỗi row ≥ 44pt.
- Preview là minh hoạ → không bắt buộc là accessibility element, nhưng thay đổi giá trị
  báo qua VoiceOver ("chiều cao: mức 3").

---

## Error & Edge Case Catalogue

### Error: Không mở được Cài đặt (deep link fail)
**Trigger:** iOS bỏ/đổi URL scheme `App-Prefs`.
**Scope:** Màn 01, nút "Mở Cài đặt".
**Display:** thay nút bằng hướng dẫn tĩnh; **không** icon đỏ, **không** chữ "Lỗi".
**Copy:** "Mở app **Cài đặt** › **Cài đặt chung** › **Bàn phím** để thêm Mindful Key."
**Recovery:** người dùng tự vào Cài đặt; hướng dẫn vẫn đủ để hoàn tất.

### Edge Case: Bật bàn phím rồi lại tắt
**Scenario:** heartbeat từng ghi, nhưng người dùng gỡ bàn phím.
**Behavior:** app **không** phát hiện được (giới hạn nền tảng). Chấp nhận Round 1; không
khẳng định sai "đã bật". Nếu gõ thử không ra bàn phím Mindful Key → nhắc nhẹ ở Home.

### Edge Case: Ô nhập bảo mật (mật khẩu)
**Scenario:** con trỏ ở secure field.
**Behavior:** gõ chữ thường bình thường; tuyệt đối không đọc/log/hiện sóng (kể cả Round 2).
Riêng tư mặc định.

---

## Future Screens (Round 2/3) — ngôn ngữ thị giác + quyết định còn mở

> ⚠️ Các màn dưới đây **chưa đặc tả đủ để thi công**. Chúng chạm trực tiếp **nhận diện +
> dữ liệu cảm xúc** — vùng hiến chương dặn "mơ hồ thì hỏi chủ dự án". Ở đây chỉ chốt phần
> bám chắc hiến chương + tiền lệ macOS (đã được chủ dự án duyệt); phần là **quyết định sản
> phẩm** thì đánh dấu **❓** và để chủ dự án chốt, KHÔNG tự quyết trong im lặng.

### Future B1 — Con sóng cảm xúc trên thanh gợi ý (Round 2)

**Chốt được (bám hiến chương §2.3):** thanh gợi ý (§DESIGN 2.6) hiện con sóng `~` màu
`brand.teal` biến hình theo **biên độ** — mặt hồ phẳng lặng ↔ gợn sóng. Trung tính, "quan
sát không chặn". Cần Full Access (đọc text-trước-con-trỏ, on-device). Reduce Motion: sóng
đứng yên ở biên độ tương ứng. **KHÔNG** đổi thanh sang đỏ/cam để cảnh báo; **KHÔNG** chặn
Enter (mandate iOS 2026-07-10).

**❓ Quyết định mở (cần chủ dự án):**
1. Map `MoodWatch send-risk 0..1` → biên độ sóng cụ thể ra sao? (tuyến tính? có ngưỡng chết
   ở dưới X để "mặt hồ phẳng" khi bình thường?)
2. Có kèm **1 câu quan sát** ("Mặt hồ đang gợn sóng") không, hay chỉ sóng im lặng? Nếu có,
   hiện khi nào, biến mất khi nào (tránh làm phiền)?
3. Ngưỡng đổi biên độ — bao nhiêu bậc? (macOS dùng "N câu căng liên tiếp" cho chuông — iOS
   có mượn khái niệm này không?)

### Future B2 — Nhật ký cảm xúc on-device (Round 3)

**Chốt được (tiền lệ macOS `MoodStoreMac` đã duyệt):** nhật ký lưu **on-device, mã hoá**,
**không rời máy**. Trình bày theo tinh thần macOS: **câu phản chiếu là trọng tâm**, số liệu
(số lần, giờ đỉnh điểm, app chủ yếu) chỉ là **bối cảnh phụ, cỡ nhỏ**. **CỐ Ý không biểu đồ,
không streak, không điểm** — "thiết kế để tự nhận ra, không phải thống kê cho vui". Có consent
gate hỏi 1 lần (không hỏi giữa lúc căng thẳng).

**❓ Quyết định mở:**
1. Nhật ký iOS hiện **chính xác** những gì? (danh sách câu phản chiếu theo ngày? 1 con số
   bối cảnh?) — cần chủ dự án vẽ ranh giới "đủ để tự nhận ra" vs "thành dashboard".
2. Nút **"Xoá tất cả"** (macOS có) đặt ở đâu trên iOS? Xác nhận 2 bước thế nào (KHÔNG nút đỏ
   mặc định — xem DESIGN §2.3)?
3. Đồng bộ App Group extension↔container: extension ghi, container đọc — hay ngược lại? Ai sở
   hữu file mã hoá?

### Future B3 — Soi lại cuối ngày (Round 3)

**Chốt được (2026-07-11, sau mockup + review):** trọng tâm là **CÂU HỎI PHẢN CHIẾU**, không
phải biểu đồ/con số (như macOS `ReflectionScreen`). Giọng quan sát, không tổng kết thành tích.
- **Bố cục đã chốt:** dẫn bằng 1 câu hỏi mở ("Hôm nay có lúc nào mặt hồ dậy sóng không?") + vài
  chip trả lời nhẹ ("Có, vài lần" / "Một chút" / "Khá lặng") + câu quan sát ("...điều đó rất
  người") + ghi chú "mọi ghi nhận ở lại trên máy này".
- **BỎ biểu đồ đường + timeline làm nhân vật chính** — đó là "thống kê cho vui", phạm tinh thần
  hiến chương (§2 macOS decision "cố ý không biểu đồ/gamify"). Nếu vẽ con sóng, chỉ là **nền
  ambient nhẹ**, không phải chart dữ liệu.
- Sống ở **tab "Mặt hồ"** trong container app.

**❓ Quyết định còn mở:**
1. Có kèm **1 thông báo đẩy** cuối ngày mời soi lại không? (notification chạm "nhắc chủ động",
   cần cân với tinh thần "không hối thúc" — hoặc chỉ để trong app, người dùng tự vào.)
2. Có cho **ghi chú riêng tư** (1 dòng) không, hay chỉ chọn chip?
3. Cuối ngày là mấy giờ, ai chỉnh được?

> Khi chủ dự án chốt B1/B2/B3, chạy lại `bmad-ux` (Update) để nâng phần này thành screen
> inventory đầy đủ (states/wireframe/a11y) như nhóm A.

---

## Interaction & Animation Spec

| Element | Animation | Duration | Easing | Reduced-motion |
|---------|-----------|----------|--------|----------------|
| Sóng `~` ambient (brand-mark, và Round 2 suggestion bar) | Gợn biên độ thấp | ~2.6s/chu kỳ | sine | **Đứng yên** ở biên độ tương ứng |
| Chuyển màn onboarding | Fade | 200ms | ease-out | Instant |
| Nhấn phím bàn phím | Sáng nền + scale 0.97 + pop preview | ~80ms | ease-out | Tắt pop, giữ đổi nền |
| Nhấn CTA | Scale 0.98 + cam tối nhẹ | 100ms | ease-out | Chỉ đổi màu |

> Mọi animation là **quan sát/phản hồi**, không phần thưởng. Sóng biên độ thấp = "mặt hồ
> phẳng lặng" — cố ý KHÔNG hoạt náo.

---

## Dev Handoff Notes

**Ưu tiên thi công (Round 1):**
1. Journey 2 (gõ Telex — Mốc B) — **critical path kỹ thuật**, chứng minh lõi.
2. Journey 1 màn 01+02 (onboarding — Mốc C).
3. Màn Home tối thiểu.

**Asset cần trước khi code:**
- [ ] Glyph con sóng `~` (SVG/vector) cho brand-mark — hiện mockup vẽ bằng path, cần bản chính thức.
- [ ] Icon set tối thiểu (⌫, ⇧, 🌐, space) — ưu tiên SF Symbols (miễn phí, đúng chất iOS).
- [ ] Copy cuối cho 3 màn (đã có bản nháp trong mockup + tài liệu này — cần chủ dự án chốt giọng).
- [ ] **Mockup 2 màn onboarding** (artifact HTML đã dựng) — dùng làm tham chiếu thị giác.

**Yêu cầu thi công chốt:**
- Bàn phím = `UIInputViewController`, gõ qua `UITextDocumentProxy`; KHÔNG global hook.
- Dynamic Type + VoiceOver + Reduce Motion respected mọi màn.
- WCAG 2.1 AA — xem `DESIGN.md §3` (cặp màu đã verify).
- UI bàn phím nhẹ (trần RAM ~48–60MB) — không blur/ảnh nặng.
- Full Access: **không** đòi ở Round 1 để gõ; chỉ hỏi ở Màn 02 với lối "Để sau".

**Câu hỏi mở cho chủ dự án:**
1. Giọng copy 3 màn: bản nháp hiện tại ("Mặt hồ…", "Bật khi nào bạn muốn con sóng") đã đúng
   chất chưa, hay cần chỉnh?
2. Nút "Để sau" ở Full Access: giữ (khuyến nghị — đúng riêng-tư-mặc-định) hay bỏ?
3. Glyph sóng chính thức: dùng path hiện tại hay đặt vẽ lại?
4. Wordmark "Mindful Key" — có logo riêng chưa, hay để chữ cạnh sóng?

---

*Part of the BMAD Planning & Orchestrator plugin. Produced by the `bmad-ux` skill.*
*Design system: `bmad-output/ios/DESIGN.md`. Hiến chương: `docs/AGENT-BRIEF.md`.*
