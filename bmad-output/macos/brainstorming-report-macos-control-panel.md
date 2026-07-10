# Brainstorming Session Report — Hiện đại hóa Bảng điều khiển macOS (mindful-key)

**Date:** 2026-07-09
**Session Duration:** ~1 phiên (3 kỹ thuật chạy song song qua sub-agent)
**BMAD Track:** bmad-method
**Topic / Problem:** Cải tiến "Bảng điều khiển" (control panel) của app mindful-key trên macOS — hiện đại hơn, chuông cấu hình được, nhận diện cảm xúc rõ ràng hơn.

> **⚠️ Lưu ý scope (đọc trước):** `bmad-output/` hiện đang khoá cho dự án **Windows Port**
> (xem `project-context.md` + `decision-log.md`). Phiên brainstorm này là một CHỦ ĐỀ
> KHÁC — control panel **macOS**. Toàn bộ artifact dùng hậu tố `-macos-panel` /
> `-macos-control-panel` để không lẫn vào luồng Windows Port. **Cần chủ dự án quyết định:**
> mở một workspace BMAD riêng cho sáng kiến macOS-panel này, hay gộp nó thành một epic
> trong workspace hiện tại. (Xem "Bước tiếp theo".)

---

## Session Objective

**Goal:** Sinh ý tưởng cụ thể cho 3 mục tiêu người dùng đặt ra — (a) bố cục control panel
hiện đại (card/section thay 4-tab checkbox cũ), (b) chuông chánh niệm **cấu hình được**
ngay trong panel, (c) hiển thị **rõ ràng** trạng thái/ngưỡng nhận diện cảm xúc (gác cổng).

**Context:** Control panel thật hiện nay (`platforms/apple/macos/ViewController.m` +
`Main.storyboard`) kế thừa gần nguyên trạng OpenKey gốc: 4 tab checkbox/radio, không có
section mood/chuông. Chuông (`BellMac.mm:51`) hardcode `NSUserNotificationDefaultSoundName`
— không có UI chọn âm/volume/ngưỡng. Ngưỡng "số câu căng liên tiếp" nằm cứng trong
`NudgeCoordinatorMac`. Cảm xúc chỉ lộ qua 1 toggle phẳng menu bar + màn "Soi lại hôm nay"
(`ReflectionScreenMac`). Ảnh tham chiếu phong cách: app "Haynoi" (bên thứ 3, chỉ mượn bố
cục, không copy tính năng).

**Constraints (bất khả xâm phạm — HIẾN CHƯƠNG §2.2/2.3):** KHÔNG đèn đỏ/xanh-lá cảm xúc ·
KHÔNG mặt cười/mếu · KHÔNG emoji chấm điểm · KHÔNG gamification (streak/điểm/huy hiệu) ·
trạng thái CHỈ mã hóa bằng biên độ sóng `~` + sắc độ trung tính không bão hòa · cam
`#FF7A1A` CHỈ cho CTA/chrome · copy "quan sát không phán xét" · Feature #1 (gác cổng,
`SendGatekeeperMac`) không được lu mờ · riêng tư mặc định áp cả cho UI hiển thị.

**Success Criteria:** Có đủ ý tưởng đã lọc qua gate "mô tả hay phán xét?" để feed thẳng
vào bước UX/PRD tiếp theo, kèm danh sách nguyên tắc phòng ngừa vi phạm hiến chương.

**Related BMAD Artifacts:**
- Objective chi tiết: `bmad-output/macos/brainstorm-objective-macos-panel.md`
- Chi tiết từng kỹ thuật: `brainstorm-macos-panel-scamper.md`, `-hats.md`, `-reverse.md`
- Constitution: `docs/AGENT-BRIEF.md`; brand: `docs/BRAND-ASSETS.md`

---

## Techniques Used

### Primary Technique: SCAMPER
**Rationale:** Biến đổi có hệ thống chính control panel hiện tại để sinh biến thể bố cục/
tính năng. **Output:** 21 ý tưởng (`brainstorm-macos-panel-scamper.md`).

### Secondary Technique: Six Thinking Hats
**Rationale:** Cân đánh đổi "hiện đại/hấp dẫn hơn" vs. "tôn trọng nghiêm hiến chương chống
gamify/phán xét". **Output:** 6 mũ + khuyến nghị tổng hợp (`brainstorm-macos-panel-hats.md`).

### Additional Technique: Reverse Brainstorming
**Rationale:** Chủ động tìm cách control panel mới có thể VI PHẠM hiến chương (dù vô tình),
rồi đảo thành nguyên tắc phòng ngừa. **Output:** 16 cặp cách-hỏng→phòng-ngừa
(`brainstorm-macos-panel-reverse.md`).

---

## Ideas Generated

### Category 1 — Bố cục / kiến trúc thông tin (mục tiêu a)

1. **Bỏ 4-tab → 1 trang cuộn dọc theo section (E1)**
   - Description: Xóa khái niệm "tab đang chọn"; toàn panel là 1 trang cuộn, chia section bằng divider mảnh kiểu Haynoi. Nền tảng bố cục cho mọi ý tưởng khác.
   - Source: SCAMPER (Eliminate) · Impact: High · Feasibility: Medium

2. **Đảo thứ tự: "quan sát trước, cấu hình sau" (R1)**
   - Description: Hiển thị TRẠNG THÁI HIỆN TẠI (sóng hôm nay) trên cùng, các nút cấu hình xếp dưới — tinh thần chánh niệm thấm vào chính kiến trúc thông tin, không chỉ 1 tính năng.
   - Source: SCAMPER (Reverse) · Impact: High · Feasibility: Medium

3. **Toggle pill-switch teal thay checkbox vuông (S2), override tint (Reverse #9)**
   - Description: Thay checkbox form cũ bằng NSSwitch bo tròn, **ép tint về teal trung tính** thay vì xanh-lá hệ thống mặc định (né tái tạo cặp đèn xanh/đỏ bị cấm).
   - Source: SCAMPER (Substitute) + Reverse #9 · Impact: Medium · Feasibility: High

4. **Status dot chỉ cho trạng thái kỹ thuật, KHÔNG cho cảm xúc (A2, Reverse #11)**
   - Description: Mượn "dot cạnh avatar" của Haynoi CHỈ để báo bộ gõ bật/tắt tiếng Việt (nhị phân, 1 màu, no-fill khi off). Cảm xúc chỉ ở sóng `~`, tuyệt đối không ở dot.
   - Source: SCAMPER (Adapt) + Reverse #11 · Impact: Medium · Feasibility: High

5. **"Account row" cuối trang → cam kết riêng tư cố định (P3)**
   - Description: Dùng vị trí hàng-account-cuối của Haynoi để đặt cố định dòng cam kết riêng tư + link chính sách, thay vì giấu trong tab Info cũ.
   - Source: SCAMPER (Put to other use) · Impact: Medium · Feasibility: High

### Category 2 — Bảo vệ Feature #1 (gác cổng — xuyên suốt mục tiêu c)

6. **Gộp trạng thái + ngưỡng + số lần gác cổng vào 1 card đầu trang (C1)**
   - Description: Đưa "gác cổng đang bật", ngưỡng hiện tại, số lần hôm nay vào chung 1 card đặt ĐẦU TIÊN — biến tính năng vương miện thành điểm neo đầu tiên khi mở panel.
   - Source: SCAMPER (Combine) · Impact: High · Feasibility: Medium

7. **Phóng đại card gác cổng: full-width, trên cùng, viền teal nhấn hơn (M1, Hats-lá#2)**
   - Description: Card gác cổng chiếm toàn chiều rộng, đặt trên cùng, độ nhấn khung/khoảng-trắng cao hơn 2 card còn lại — bảo vệ ưu tiên bằng chính bố cục, không cần badge "quan trọng nhất".
   - Source: SCAMPER (Magnify) + Hats(Xanh lá) · Impact: High · Feasibility: Medium

8. **Card gác cổng làm lối tắt mở "Soi lại hôm nay" (P1)**
   - Description: Bấm card gác cổng mở luôn `ReflectionScreen` — nối 2 tính năng đang tách rời thành 1 hành trình, panel thành cửa ngõ thực hành chứ không phải bảng cấu hình khô.
   - Source: SCAMPER (Put to other use) · Impact: Medium · Feasibility: Medium

9. **Bỏ label kỹ thuật "threshold/ngưỡng" khỏi mặt chính (E3)**
   - Description: Mặt trước dùng câu quan sát ("Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi"); thuật ngữ kỹ thuật chỉ giữ trong tooltip/nâng cao.
   - Source: SCAMPER (Eliminate) · Impact: Medium · Feasibility: High

### Category 3 — Cấu hình chuông (mục tiêu b)

10. **Thu gọn về 3 mức định tính "Ít nhạy — Vừa — Nhạy" + nút nâng cao (M3, Hats-lá#5)**
    - Description: Rút 3 control (số câu, volume, giờ) thành 1 lựa chọn 3 mức bằng chữ ánh xạ ẩn vào số ngưỡng; ẩn "Tùy chỉnh nâng cao" cho ai cần. Giữ cảm giác "chọn 1 mức sống" thay vì "vặn thông số game".
    - Source: SCAMPER (Modify) + Hats(Xanh lá) · Impact: High · Feasibility: High

11. **UI chuẩn AppKit cho chuông: dropdown âm thanh + slider volume + time-range picker (Hats-dương#2)**
    - Description: Chọn âm thanh (thay hardcode `BellMac.mm:51`), volume, khung "giờ yên lặng" bằng component hệ thống chuẩn — giải quyết đúng nỗi đau "chuông phiền → tắt cả tính năng".
    - Source: Hats(Xanh dương) · Impact: High · Feasibility: High

12. **Sóng `~` làm preview sống khi kéo mức nhạy (Hats-lá#1)**
    - Description: Khi user kéo mức nhạy, sóng demo animate theo — "thấy" ngưỡng là mức nào mà không cần số hay thanh màu. Thay cho progress bar (bị cảnh báo gamify).
    - Source: Hats(Xanh lá) · Impact: Medium · Feasibility: Medium

13. **Giờ yên lặng = cấu hình thủ công độc lập, KHÔNG tự đồng bộ Focus Mode (Reverse #16)**
    - Description: Khung giờ do user tự đặt; chỉ đọc/ghi Focus Mode hệ thống nếu user chủ động bật 1 toggle riêng có giải thích quyền — mặc định OFF (né rò rỉ ngữ cảnh + entitlement thừa).
    - Source: Reverse #16 (đảo ngược C3 của SCAMPER) · Impact: Medium · Feasibility: High
    - ⚠️ Lưu ý: SCAMPER-C3 đề xuất tự đồng bộ Focus/DND; Reverse #16 cảnh báo rủi ro riêng tư. **Chốt hướng an toàn = thủ công, opt-in.**

### Category 4 — Hiển thị trạng thái cảm xúc (mục tiêu c, phần nhạy cảm nhất)

14. **Trạng thái = 1 hình thức DUY NHẤT: biên độ sóng `~` trung tính (Reverse #1, #10)**
    - Description: Biên độ thấp→cao cùng 1 sắc teal/xám-đá, KHÔNG đổi hue theo mức. Cần phân biệt "yên/gợn" thì dùng độ dày nét hoặc tần số sóng, không hue thứ 2. Cấm SF Symbol mặt người/cảnh báo — vẽ riêng glyph sóng từ `brand/svg/`.
    - Source: Reverse #1+#10 · Impact: High · Feasibility: Medium

15. **Copy trạng thái xoay vòng theo biên độ (Hats-lá#4)**
    - Description: "Mặt hồ đang phẳng lặng" (biên độ thấp) ↔ "Mặt hồ đang gợn sóng" (cao) — sống động bằng đổi ẩn dụ theo dữ liệu thật, không thêm số liệu/điểm.
    - Source: Hats(Xanh lá) · Impact: Medium · Feasibility: High

16. **Mặc định THU GỌN trạng thái cảm xúc, click để mở rộng (Hats-dương#3, Reverse #4)**
    - Description: Giải nghịch lý riêng tư — control panel dễ bị liếc qua khi có người đứng cạnh. Rõ ràng hơn với chính user (mở ra khi muốn), nhưng không phơi bày mặc định. KHÔNG dashboard biểu đồ theo thời gian trong panel.
    - Source: Hats(Xanh dương) + Reverse #4 · Impact: High · Feasibility: Medium

17. **Mặc định ẩn định lượng, chỉ hiện sóng định tính (R3)**
    - Description: Số liệu (số lần gác cổng, biên độ...) là tùy chọn phải BẬT thêm; mặc định chỉ hiện sóng định tính — tôn trọng user nhạy cảm với việc tự đo/so sánh bản thân.
    - Source: SCAMPER (Reverse) · Impact: Medium · Feasibility: Medium

18. **Sóng chỉ động khi có tín hiệu thật, nghỉ thì tĩnh/im lặng (Reverse #15)**
    - Description: Ở trạng thái nghỉ hiển thị phẳng, biên độ ~0, không loop animation vô nghĩa, không âm nền — chuyển động = có dữ liệu thật, không phải trang trí (né cảm giác bị theo dõi 24/7).
    - Source: Reverse #15 · Impact: Medium · Feasibility: High

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total ý tưởng thô sinh ra (3 kỹ thuật) | 21 + 30 (6 mũ×~5) + 16 = ~57 |
| Ý tưởng chắt lọc vào báo cáo | 18 |
| Categories | 4 |
| Ý tưởng Impact cao | 9 |
| Quick wins (Impact cao + Feasibility cao) | 2 (ý #10, #11 — cấu hình chuông) |
| Moon shots (Impact cao + Feasibility trung/thấp) | 5 (bố cục lớn, card gác cổng, hiển thị cảm xúc) |
| Cặp cách-hỏng → phòng-ngừa (governance) | 16 |

---

## Top Insights (xuyên suốt 3 kỹ thuật)

Ba kỹ thuật độc lập nhưng **hội tụ vào cùng vài kết luận** — dấu hiệu các insight này chắc:

1. **Bố cục nền = 1 trang cuộn dọc, "quan sát trước, cấu hình sau".** (SCAMPER E1+R1) Bỏ
   4-tab; trạng thái hiện tại lên đầu, cấu hình xuống dưới. Đây là xương sống cho mọi thứ khác.

2. **Feature #1 phải được bảo vệ bằng chính bố cục, không bằng lời hứa.** (cả 3 kỹ thuật
   đều nêu) Card gác cổng full-width, trên cùng, nhấn hơn — KHÔNG bao giờ xếp ngang hàng
   3 card cùng cỡ (Chuông/Mood/Gác cổng), vì "3 card đẹp cùng cỡ" tự nó làm gác cổng chìm.

3. **Chuông cấu hình được là "quick win" giá trị cao, ít rủi ro nhất.** (Hats-Vàng) Giải
   đúng nỗi đau thật (chuông phiền → user tắt cả tính năng). Dùng 3 mức định tính +
   component AppKit chuẩn. Đây là nơi nên bắt đầu triển khai đầu tiên.

4. **Hiển thị cảm xúc là phần NHẠY CẢM NHẤT — "rõ ràng hơn" ≠ "phơi bày mặc định".**
   (Hats-Đen#1 + Reverse #4) Nghịch lý riêng tư: panel dễ bị liếc qua. Giải pháp = rõ hơn
   với chính user (mở rộng khi muốn) nhưng **mặc định thu gọn**, chỉ sóng `~` định tính,
   ẩn định lượng.

5. **Rủi ro lớn nhất là gamification qua HÌNH DẠNG/THAO TÁC, không phải qua màu.**
   (Hats-Đen#2#3) Progress bar ngang tự nó gợi "thanh máu/XP" dù không đỏ-xanh; slider số +
   "xem thử ngay" biến trải nghiệm thành "chọn độ khó game". → cấm progress bar cho
   ngưỡng/mood; dùng sóng + chữ định tính.

---

## Risks / Cảnh báo mang sang bước sau

- **Nghịch lý riêng tư hiển thị:** làm cảm xúc "rõ hơn" có thể khiến người đứng cạnh màn
  hình đọc được — bản cũ (ẩn trong menu) vô tình riêng tư hơn. Giải: mặc định thu gọn.
- **Copy trôi dần theo thời gian:** card trạng thái cần đổi câu thường xuyên hơn toggle
  tĩnh → dễ trôi từ "mô tả" sang "phán xét nhẹ" qua các đợt cập nhật. Giải: **gate copy bắt
  buộc** — mỗi câu mới phải tự trả lời "mô tả hay phán xét?" ghi thành 1 dòng trong story/PR.
- **Xung đột SCAMPER-C3 vs Reverse #16 (Focus Mode):** tự đồng bộ DND tiện nhưng rò rỉ ngữ
  cảnh + có thể cần entitlement thừa. Chốt hướng an toàn: thủ công, opt-in.
- **Ranh giới triển khai:** việc chạm CẢ layout/AppKit (`platform-shell-agent`) LẪN copy/
  ngưỡng/logic (`mood-layer-agent`). Khi sang code thật nên qua `mindful-keyboard-harness`
  để tránh 1 bên chỉnh nhầm phần bên kia.
- **Scope governance:** chủ đề này chưa nằm trong workspace BMAD hiện tại (Windows Port) —
  cần quyết định gộp/tách trước khi làm PRD/story (xem dưới).

---

## Đề xuất bố cục panel (phác thảo từ các ý tưởng hội tụ)

```
┌─ Control panel (1 trang cuộn dọc, không tab) ────────────┐
│  [Header] logo ~ + tên app + status dot (bật/tắt gõ VN)  │  ← A2/S2
│                                                          │
│  ╔══ CARD GÁC CỔNG (Feature #1) — full-width, trên cùng ╗│  ← C1/M1
│  ║  Sóng ~ định tính (thu gọn) · "…dừng lại hỏi trước   ║│  ← #14/#16
│  ║   khi gửi" · [Mở Soi lại hôm nay]                    ║│  ← P1
│  ╚══════════════════════════════════════════════════════╝│
│  ── divider mảnh ──                                       │
│  ┌ Card Chuông ─────────────────────────────────────────┐│
│  │ Độ nhạy: ( Ít nhạy · [Vừa] · Nhạy )  ▸ Nâng cao      ││  ← M3
│  │ Âm thanh: [dropdown]  Volume: [────●──]              ││  ← Hats-dương#2
│  │ Giờ yên lặng: [time-range]  (Focus sync: OFF)        ││  ← #13
│  └──────────────────────────────────────────────────────┘│
│  ┌ Card Bộ gõ (Telex/VNI, macro…) — gọn ────────────────┐│  ← phần OpenKey cũ
│  └──────────────────────────────────────────────────────┘│
│  [hàng cuối] Cam kết riêng tư · on-device · link chính sách│  ← P3
└──────────────────────────────────────────────────────────┘
```

---

## Recommended Next Steps (BMAD)

1. **Chốt scope governance trước tiên** (chủ dự án quyết): mở workspace BMAD riêng cho
   sáng kiến "macOS control panel redesign", HAY thêm nó làm 1 epic trong workspace hiện
   tại (đang là Windows Port). Ghi quyết định vào `decision-log.md`.
2. **Chạy `bmad-ux`** (skill có sẵn) để biến 18 ý tưởng này thành DESIGN.md (design tokens
   đã có sẵn từ NOW BRAND OS + component spec cho card/sóng/slider) và EXPERIENCE.md
   (flow mở panel → thu gọn/mở rộng trạng thái → chỉnh chuông). Đây là bước tự nhiên vì
   dự án có UI và các ý tưởng đã đủ chín.
3. **Hoặc `bmad-prd` / `bmad-tech-spec`** nếu muốn ghi FR/NFR trước (vd FR: "chuông đọc
   ngưỡng từ UserDefaults thay hardcode"; NFR: "trạng thái cảm xúc mặc định thu gọn").
   Nếu scope nhỏ (~1 epic) → `bmad-tech-spec` gọn hơn PRD.
4. **Khi sang code thật:** qua `mindful-keyboard-harness` để điều phối `platform-shell-agent`
   (layout AppKit) + `mood-layer-agent` (copy/ngưỡng), tránh lẫn ranh giới engine/mood/shell.
5. **Thêm 1 governance gate lâu dài:** đưa checklist "mô tả hay phán xét?" + "Feature #1 còn
   nổi bật nhất không?" vào `code-review-master.md` để mọi thay đổi UI cảm xúc về sau đều bị
   soi lại — không dựa trí nhớ.
