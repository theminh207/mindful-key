# EXPERIENCE.md — Bảng điều khiển macOS (mindful-key) — Kế hoạch trải nghiệm

**Epic:** Hiện đại hóa Bảng điều khiển macOS · **Platform:** macOS (AppKit menu-bar popover)
**Song hành:** `DESIGN-macos-control-panel.md` (token/component/WCAG)
**Trạng thái:** LOCKED planning artifact — dev tool đọc, không sửa.

> Nguyên tắc trải nghiệm chủ đạo (từ brainstorm, 3 kỹ thuật hội tụ): **"Quan sát trước, cấu
> hình sau"** — mở panel thấy TRẠNG THÁI trước, các nút chỉnh xếp dưới. Tinh thần chánh niệm
> nằm trong chính kiến trúc thông tin, không chỉ 1 tính năng.

---

## 1. Persona & bối cảnh

- **Persona chính:** người thực hành chánh niệm (cộng đồng GNH), đã có động lực nội tại
  "chậm lại 1 nhịp". Không phải người dùng phổ thông. Không cần bị "kéo tương tác".
- **Thiết bị:** macOS, thao tác bằng chuột + bàn phím, panel là popover từ menu bar.
- **Tần suất:** mở panel thi thoảng (chỉnh cấu hình, liếc trạng thái), KHÔNG phải app mở
  cả ngày. Thiết kế phải chịu được "bị người khác liếc màn hình".

---

## 2. User Journeys

### Journey A — Mở panel lần đầu trong ngày (happy path chủ đạo)

**Goal:** nắm trạng thái + biết mình có thể chỉnh gì, trong <10 giây, không thấy bị chấm điểm.
**Entry:** click icon menu bar.

```
Click menu-bar icon
      │
      ▼
Panel mở (popover 360px)
      │
      ▼
[Trên cùng] CARD GÁC CỔNG  ← thấy đầu tiên (Feature #1)
   • Sóng ~ THU GỌN + "Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi"
   • link "Soi lại hôm nay →"
      │
      ├─(cuộn / liếc xuống)─▶ Card Chuông (độ nhạy 3 mức, âm thanh, giờ yên lặng)
      │
      ├───────────────────▶ Card Bộ gõ (Telex/VNI, macro… — thu gọn)
      │
      ▼
[Cuối] Hàng cam kết riêng tư (on-device, không gửi nội dung đi)
```

**Thời gian ước tính:** 5–10s để nắm bố cục. **Drop-off risk:** nếu card gác cổng không đủ
nổi bật, user hiểu nhầm đây chỉ là "bộ gõ tiếng Việt bình thường" → mất định vị sản phẩm.

### Journey B — Chỉnh chuông cho bớt phiền (quick win, giá trị cao nhất)

**Goal:** giảm phiền mà không phải tắt hẳn tính năng.
**Entry:** Card Chuông trong panel.

```
Card Chuông
   │
   ├─▶ Đổi độ nhạy: [Ít nhạy · Vừa · Nhạy]  → sóng demo animate cho "thấy" mức
   ├─▶ Đổi âm thanh: dropdown  → nghe thử khi chọn
   ├─▶ Kéo âm lượng: slider (track 1 màu teal)
   ├─▶ Đặt giờ yên lặng: từ [22:00] đến [07:00]  (thủ công)
   │       └─(tùy chọn) bật "Đồng bộ Chế độ Tập trung" → hiện giải thích quyền → xác nhận
   └─▶ "Tùy chỉnh nâng cao ▸"  → hiện số câu chính xác cho ai muốn
   │
   ▼
Thay đổi lưu ngay (không cần nút Save riêng cho toggle/slider);
đổi giờ yên lặng có nút "Lưu" (CTAButton cam, chữ tối) nếu cần xác nhận.
```

**Drop-off risk chính:** nếu chỉ có slider số trần trụi + "xem thử ngay" → cảm giác "chọn độ
khó game". Đã né bằng 3 mức định tính.

### Journey C — Xem lại cảm xúc trong ngày (từ card gác cổng)

**Goal:** tự soi lại, KHÔNG phải xem thống kê.
**Entry:** link "Soi lại hôm nay →" trên card gác cổng.

```
Card Gác cổng → click "Soi lại hôm nay →"
      │
      ▼
Mở ReflectionScreen (màn có sẵn — KHÔNG dựng dashboard mới trong panel)
   • Câu hỏi phản chiếu là trọng tâm
   • Số liệu (số lần gác cổng, giờ đỉnh điểm) chỉ là bối cảnh phụ, KHÔNG biểu đồ theo thời gian
```

**Ràng buộc:** panel KHÔNG tự vẽ biểu đồ line/bar theo ngày. Mọi "xem lại" đi qua
ReflectionScreen đã đúng tinh thần.

### Journey D — Mở rộng xem trạng thái cảm xúc (opt-in, né nghịch lý riêng tư)

**Goal:** user muốn nhìn kỹ hơn sóng hiện tại.
**Entry:** nút "Xem thêm" trên `EmotionWave` thu gọn.

```
EmotionWave (thu gọn, mặc định)
      │  click "Xem thêm"
      ▼
EmotionWave (mở rộng): sóng lớn hơn + copy mô tả
      │  (chỉ khi user đã BẬT riêng trong nâng cao)
      ▼
Hiện thêm số liệu định lượng  ← mặc định TẮT
```

**Vì sao mặc định thu gọn:** panel dễ bị người đứng cạnh liếc. Rõ hơn với chính user khi họ
chủ động mở, nhưng không phơi bày trạng thái cảm xúc ra ngoài mặc định.

---

## 3. Screen / State Inventory

### 3.1 Panel — trạng thái tổng

| State | Khi nào | Hiển thị |
|-------|---------|----------|
| **Default** | Mở panel, có dữ liệu | Card gác cổng (sóng thu gọn) + Chuông + Bộ gõ + footer |
| **Loading** | Vừa mở, đang đọc UserDefaults/mood store | Skeleton mờ cho từng card; `aria-live=polite` "Đang tải cấu hình" |
| **Empty (chưa có dữ liệu cảm xúc hôm nay)** | Đầu ngày, chưa gõ câu nào | Sóng **phẳng lặng** + copy trung tính "Hôm nay chưa có gì làm mặt hồ gợn sóng" (mô tả, không phán xét). KHÔNG hiện "0 lần", không CTA thúc ép |
| **Error (không lưu được cấu hình)** | Ghi UserDefaults lỗi | Dòng chữ `text.primary` + icon trung tính: "Chưa lưu được thay đổi, thử lại nhé" + nút "Thử lại". KHÔNG màu đỏ |
| **Consent chưa cấp** | Chưa đồng ý lưu nhật ký cảm xúc | Card mood hiện lời mời cấp quyền 1 lần (không hỏi giữa lúc căng); các phần khác vẫn dùng được |
| **Nhắc tâm đang tắt** | User tắt toàn bộ | Card Chuông + EmotionWave mờ 40% + caption "Đang tắt nhắc tâm" + nút bật lại |

### 3.2 `EmotionWave` — các state riêng

| State | Hiển thị |
|-------|----------|
| Phẳng lặng / nghỉ | Đường sóng gần thẳng, **tĩnh**, im lặng, màu ngả `stone` |
| Gợn nhẹ | Biên độ thấp, tần số vừa, màu teal nhạt |
| Gợn sóng (tín hiệu thật) | Biên độ cao, animate chậm 400–600ms, copy "Mặt hồ đang gợn sóng" |
| Reduced-motion | Đổi hình tức thời, không animate biên độ |
| Expanded | Sóng lớn + copy; số liệu chỉ khi opt-in |

### 3.3 Wireframe panel (ASCII)

```
┌─ menu-bar popover · rộng 360px ─────────────────────┐
│  ~ mindful-key            ● (dot: gõ VN đang bật)   │  Header, teal chrome
│─────────────────────────────────────────────────────│
│ ╔═ Gác cổng gửi tin ════════════════ [viền teal] ══╗ │  GatekeeperCard (H1)
│ ║   〜  (sóng thu gọn)          Soi lại hôm nay →  ║ │  Feature #1, trên cùng
│ ║   "Khi sóng gợn nhiều, mình sẽ dừng lại hỏi     ║ │
│ ║    trước khi gửi."              [Xem thêm ▾]     ║ │
│ ╚═══════════════════════════════════════════════════╝ │
│ ── divider ──                                        │
│  Chuông                                              │  H2
│   Độ nhạy   ( Ít nhạy · [ Vừa ] · Nhạy )            │  segmented 3 mức
│   Âm thanh  [ Tiếng chuông ▾ ]                       │
│   Âm lượng  [────────●───────]  (track teal)         │
│   Giờ yên lặng [22:00]→[07:00]   Nâng cao ▸          │
│ ── divider ──                                        │
│  Bộ gõ  [Telex ▾]  macro…                 ▸ (gọn)   │  InputMethodCard
│ ── divider ──                                        │
│  Xử lý trên máy · không gửi nội dung gõ · Riêng tư  │  PrivacyFooterRow (caption)
└──────────────────────────────────────────────────────┘
```

---

## 4. Decision Points & Alternative Paths

| Branch | Trigger | Hiển thị | Recovery |
|--------|---------|----------|----------|
| Bật "Đồng bộ Focus Mode" | User gạt toggle | Popover giải thích app sẽ đọc trạng thái Focus + quyền cần | User xác nhận hoặc huỷ; mặc định vẫn OFF |
| Đổi giờ yên lặng chồng chéo | User đặt giờ vô lý (bắt đầu = kết thúc) | Caption trung tính "Khoảng giờ chưa hợp lệ" | Giữ giá trị cũ tới khi hợp lệ |
| Chưa cấp consent mood | Mở card mood lần đầu | Lời mời cấp quyền 1 lần | Cấp → dùng; từ chối → card mood ẩn, phần còn lại vẫn chạy |
| Mood store lỗi đọc | Đọc DB lỗi | Sóng phẳng + "Chưa đọc được nhật ký, thử lại sau" (trung tính) | Nút thử lại; không chặn cấu hình chuông/bộ gõ |

---

## 5. Interaction & Animation Notes (tóm — chi tiết ở DESIGN §4)

- Sóng animate **chỉ khi có tín hiệu thật**, chậm/mượt 400–600ms; nghỉ = tĩnh.
- Disclosure 200ms ease-out.
- Tôn trọng "Giảm chuyển động" của macOS (`prefers-reduced-motion`).
- KHÔNG animation loop trang trí (né cảm giác bị theo dõi liên tục).

---

## 6. Kiểm HIẾN CHƯƠNG cho trải nghiệm (song song DESIGN §5)

- [ ] Mở panel: card gác cổng là thứ nổi bật nhất, thấy đầu tiên?
- [ ] Trạng thái cảm xúc mặc định thu gọn, không phơi bày?
- [ ] Empty state không hiện "0 lần" / không thúc ép / không phán xét?
- [ ] Không có biểu đồ theo thời gian / so sánh xã hội trong panel?
- [ ] Mọi copy trạng thái qua gate "mô tả hay phán xét?"?
- [ ] Không nội dung gõ thật xuất hiện ở bất kỳ state nào?
- [ ] Giờ yên lặng thủ công, Focus sync opt-in?

---

## 7. Bàn giao

Hai tài liệu (`DESIGN-…` + `EXPERIENCE-…`) là input cho bước tạo story. Khi được duyệt,
chạy `bmad-epics-and-stories` (hoặc `bmad-tech-spec` nếu muốn ghi FR/NFR trước) để chẻ epic
"Hiện đại hóa Bảng điều khiển macOS" thành story ready-for-dev, rồi giao qua
`mindful-keyboard-harness` cho `platform-shell-agent` + `mood-layer-agent`.
