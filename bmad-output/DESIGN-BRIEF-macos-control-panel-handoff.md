# Đề bài thiết kế — Bảng điều khiển macOS (mindful-key)

> File này gộp toàn bộ bối cảnh từ `DESIGN-macos-control-panel.md` +
> `EXPERIENCE-macos-control-panel.md` + `brainstorm-macos-panel-hats.md` + NOW BRAND OS +
> HIẾN CHƯƠNG thành **1 đề bài gọn, dán được thẳng vào bất kỳ tool thiết kế AI nào khác**
> (Claude khác, Figma AI, v0...). Không phải tài liệu LOCKED — 3 file nguồn kia mới là spec
> chính thức, file này chỉ đóng gói lại để dễ mang đi.
>
> **Mockup thị giác đã dựng sẵn, xem trước khi đọc tiếp:**
> https://claude.ai/code/artifact/49824db2-3ca9-4e07-8ef4-73a5491d21a9
> (HTML/CSS tương tác — bấm nút đổi trạng thái panel, đổi độ nhạy chuông để thấy sóng đổi biên độ).
> Dùng mockup này làm điểm xuất phát "đã đúng hướng" — nếu đưa cho tool khác, có thể đính kèm
> ảnh chụp màn hình của link trên làm ground truth.

---

## 1. Sản phẩm là gì, cho ai

**mindful-key** — bộ gõ Tiếng Việt chánh niệm (fork OpenKey, GPL v3, giữ credit Mai Vũ Tuyên).
Tính năng lõi ("Feature #1"): **gác cổng gửi tin** — khi người dùng gõ câu có dấu hiệu căng
thẳng và bấm Enter (không Shift) trong app chat, hệ thống dừng lại hỏi trước khi gửi thật.
Toàn bộ xử lý cảm xúc chạy **on-device**, không gửi nội dung gõ đi đâu.

**Người dùng:** cộng đồng thực hành chánh niệm (GNH), đã có động lực nội tại "chậm lại 1
nhịp" — không phải người dùng phổ thông cần bị thuyết phục/kéo tương tác.

**Việc cần thiết kế:** hiện đại hóa control panel macOS (hiện là popover menu-bar kiểu 4-tab
checkbox cũ của OpenKey gốc) thành 1 panel có: (1) bố cục mới, (2) chuông cấu hình được thay vì
hardcode, (3) hiển thị rõ hơn trạng thái cảm xúc/ngưỡng gác cổng — mà không phá vỡ tinh thần
chánh niệm.

---

## 2. Luật bất khả xâm phạm — TRẦN, không thương lượng

Đây là ràng buộc mạnh nhất, mạnh hơn mọi gu thẩm mỹ. Bất kỳ output nào từ tool thiết kế khác
vi phạm mục này đều bị loại, bất kể đẹp đến đâu:

1. ❌ **Không đèn đỏ/vàng/xanh-lá mã hóa cảm xúc.** Thang cảm xúc = 1 hue duy nhất (teal → nhạt
   dần về xám-đá), chỉ đổi **biên độ sóng**, không đổi màu.
2. ❌ **Không mặt cười/mếu, không icon cảnh báo** (`exclamationmark.triangle`, `xmark.octagon`)
   cho trạng thái cảm xúc. Chỉ 1 glyph sóng `~` tự vẽ.
3. ❌ **Không gamification**: không progress bar tích lũy, không streak, không badge, không
   điểm số, không "xem thử ngay" kề slider số (đọc như chọn độ khó game).
4. ❌ **Không copy khiển trách.** Mọi câu mô tả trạng thái phải qua gate "mô tả hay phán xét?" —
   "Mặt hồ đang gợn sóng" ✅ · "Bạn đang căng thẳng, hãy bình tĩnh" ❌.
5. ❌ **Không phơi bày dữ liệu cảm xúc mặc định.** Panel dễ bị người khác liếc màn hình — trạng
   thái cảm xúc mặc định phải THU GỌN, mở rộng chỉ khi user chủ động bấm.
6. ✅ **Feature #1 (gác cổng) luôn nổi bật nhất**, đứng đầu, full-width — không được thu nhỏ
   ngang hàng các card cấu hình khác.
7. ✅ Cam thương hiệu **chỉ** ở CTA/link active — không dùng cho trạng thái ON/OFF, không track
   slider, không gradient cảm xúc.
8. ✅ Riêng tư: không render nội dung gõ thật (kể cả rút gọn), không lịch sử theo dòng
   (timestamp/tên app), không biểu đồ theo thời gian, không so sánh xã hội.

---

## 3. Token thị giác — NOW BRAND OS (khóa cứng, không tự chế màu)

| Token | Hex | Dùng cho | Cấm dùng cho |
|---|---|---|---|
| `brand.teal` | `#1D7C91` | Chrome, tiêu đề, tint switch, glyph sóng | — |
| `brand.tealLight` | `#E8F2F4` | Nền nhấn nhẹ, hover | — |
| `cta.orange` | `#FF7A1A` | **CHỈ** CTA (Vẫn gửi/Lưu), link active | ON/OFF, gradient cảm xúc, track slider |
| `cta.orangeLight` | `#FFF2E8` | Nền nhấn CTA rất nhẹ | như trên |
| `bg.window` | `#F8F8F8` | Nền panel | — |
| `bg.card` | `#FFFFFF` | Nền card | — |
| `text.primary` | `#2A2A2A` | Chữ chính, **label trên nút cam** | — |
| `text.secondary` | `#666666` | Chữ phụ, caption | — |
| `neutral.stone` | `#8A9BA0` | Sóng biên độ thấp (phẳng lặng) | Không dùng như màu cảnh báo |
| `divider` | `#E5E7E8` | Đường phân cách 1px | — |

**Không có token semantic đỏ-vàng-xanh-lá** — quyết định có chủ đích, xem mục 2.

**Typography:** Montserrat 700/600 (h1 20px, h2 16px) cho tiêu đề · Inter 400/600 (body 14px,
caption 12px) cho nội dung. **Spacing:** lưới 8px (4·8·12·16·24·32). **Radius:** card 16px,
control 8px, pill 999px (segmented control). **Elevation:** `0 8px 30px rgba(29,124,145,0.08)`
— bóng ánh ngọc bích, không neon, không viền gắt. **Panel width:** cố định 360px (popover
menu-bar macOS), cao co theo nội dung, cuộn dọc nếu vượt ~600px.

**WCAG đã verify bằng số thật (DESIGN.md §3):** chữ trắng trên nền cam = 2.61:1 **FAIL** →
luôn dùng chữ tối `#2A2A2A` trên nút cam = 5.50:1 PASS. `text.secondary` chỉ đạt AA (không
AAA) — dùng cho caption, nội dung quan trọng dùng `text.primary`.

---

## 4. Kiến trúc thông tin — "Quan sát trước, cấu hình sau"

Nguyên tắc trải nghiệm chủ đạo (từ brainstorm, hội tụ qua 3 kỹ thuật tư duy): mở panel thấy
**trạng thái** trước, các nút chỉnh xếp dưới.

```
┌─ menu-bar popover · rộng 360px ─────────────────────┐
│  ~ mindful-key            ● gõ VN đang bật           │  Header, chrome teal
│───────────────────────────────────────────────────  │
│ ╔═ Gác cổng gửi tin ═══════════════ [viền teal] ══╗ │  ← LUÔN đứng đầu, full-width,
│ ║  〜 (sóng thu gọn)        Soi lại hôm nay →      ║ │    nổi bật hơn mọi card khác
│ ║  "Khi sóng gợn nhiều, mình sẽ dừng lại hỏi      ║ │    (Feature #1)
│ ║   trước khi gửi."              [Xem thêm ▾]      ║ │
│ ╚═══════════════════════════════════════════════════╝ │
│  Chuông                                              │  ← nhỏ hơn, không viền nhấn
│   Độ nhạy   ( Ít nhạy · [ Vừa ] · Nhạy )            │    3 mức CHỮ, không số/thanh ngang
│   Âm thanh  [ Tiếng chuông ▾ ]                       │
│   Âm lượng  [────────●───────]                       │
│   Giờ yên lặng [22:00]→[07:00]   Nâng cao ▸          │
│  Bộ gõ  [Telex ▾]  macro…                 ▸ (gọn)   │  ← phần OpenKey cũ, thu gọn
│  Xử lý trên máy · không gửi nội dung gõ · Riêng tư  │  ← cố định cuối, không cuộn mất
└──────────────────────────────────────────────────────┘
```

**4 user journey chính** (chi tiết ở EXPERIENCE.md §2):
- **A — Mở panel lần đầu trong ngày:** nắm trạng thái + biết chỉnh được gì trong <10 giây.
- **B — Chỉnh chuông cho bớt phiền:** đổi độ nhạy → sóng demo animate theo mức (không số/thanh màu).
- **C — Soi lại cảm xúc trong ngày:** đi qua màn `ReflectionScreen` có sẵn, panel KHÔNG tự vẽ
  biểu đồ theo thời gian.
- **D — Mở rộng xem trạng thái (opt-in):** click "Xem thêm" mới lộ sóng lớn + copy; số liệu định
  lượng mặc định ẩn.

**State quan trọng cần thiết kế đủ** (không chỉ trạng thái "đẹp mặc định"): Loading, Empty
(chưa có dữ liệu hôm nay — copy trung tính, KHÔNG hiện "0 lần"), Error (chữ trung tính + nút
thử lại, KHÔNG đỏ), Consent chưa cấp, Đã tắt nhắc tâm (card mờ 40% + nút bật lại).

---

## 5. Đề bài cụ thể — dán đoạn này cho tool thiết kế khác

```
Thiết kế lại 1 popover control panel cho ứng dụng macOS "mindful-key" (bộ gõ Tiếng Việt
chánh niệm), rộng cố định 360px, dạng menu-bar popover AppKit.

Token bắt buộc (không đổi): teal #1D7C91 (chrome/accent), cam #FF7A1A (CHỈ cho CTA/link,
cấm dùng cho trạng thái ON/OFF hay bất kỳ thang đo nào), nền #F8F8F8, card #FFFFFF, chữ
chính #2A2A2A, chữ phụ #666666, xám-đá #8A9BA0 cho trạng thái "phẳng lặng". Font Montserrat
(heading) + Inter (body). Radius 16px card / 8px control / pill cho segmented control.

Cấu trúc bắt buộc: 1 card "Gác cổng gửi tin" LUÔN đứng đầu, full-width, nổi bật nhất (đây là
tính năng chính, không phải cài đặt phụ) — bên trong có 1 glyph sóng "~" (KHÔNG phải progress
bar, KHÔNG phải mặt cười/mếu, KHÔNG đèn đỏ-xanh) chỉ đổi BIÊN ĐỘ để biểu thị mức độ căng
thẳng, mặc định thu gọn/ẩn chi tiết. Dưới đó là card "Chuông" (độ nhạy = 3 mức bằng CHỮ: Ít
nhạy/Vừa/Nhạy — không phải slider số, không phải progress bar), card "Bộ gõ" thu gọn, và 1
dòng cam kết riêng tư cố định ở cuối.

Cấm tuyệt đối: gamification (streak/điểm/badge), mã hóa cảm xúc bằng màu đỏ-vàng-xanh-lá,
copy phán xét/khiển trách ("bạn đang..."), hiển thị số liệu cảm xúc định lượng mặc định.

Đây là ứng dụng chánh niệm, không phải app năng suất — thiết kế nên tĩnh lặng, "quan sát
không phán xét", không thúc ép tương tác.
```

---

## 6. Nếu cần đào sâu hơn

- Component spec đầy đủ (states hover/focus/disabled từng control, a11y `aria-label`,
  animation timing 400–600ms ease-in-out, `prefers-reduced-motion`): `DESIGN-macos-control-panel.md`.
- Journey/wireframe/decision-branch đầy đủ: `EXPERIENCE-macos-control-panel.md`.
- Lý do từng lựa chọn (Six Thinking Hats — rủi ro đã cân nhắc, ý tưởng đã loại): `brainstorm-macos-panel-hats.md`.
- Khi đã chốt thiết kế và muốn code AppKit thật: gọi skill `mindful-key:mindful-keyboard-harness`
  để chia đúng việc cho `platform-shell-agent` (bố cục/component) và `mood-layer-agent`
  (ngưỡng/copy cảm xúc) — đừng tự code thẳng tay không qua điều phối.
