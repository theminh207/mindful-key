# Epics — mindful-key (bổ sung: epic Bảng điều khiển macOS)

> Bản đồ epic (index mỏng, không phải context object). Chi tiết story nằm ở từng file
> `bmad-output/stories/{epic}.{story}.{slug}.story.md`.
>
> Track: BMad Method
> **Lưu ý workspace:** workspace này gốc khoá cho **Windows Port** (Epic chưa chẻ). File
> `epics.md` này bổ sung **Epic 1 — Bảng điều khiển macOS** như một epic độc lập, dùng
> nguồn spec là 2 tài liệu UX + báo cáo brainstorm (thay vai trò PRD/architecture cho
> riêng epic này — dự án chưa có prd.md/architecture.md).
> Sources: `DESIGN-macos-control-panel.md`, `EXPERIENCE-macos-control-panel.md`,
> `brainstorming-report-macos-control-panel.md`, `docs/AGENT-BRIEF.md` (HIẾN CHƯƠNG).

---

## Epic 1: Hiện đại hóa Bảng điều khiển macOS

**Goal:** Thay control panel 4-tab-checkbox cũ (kế thừa OpenKey) bằng 1 panel cuộn dọc
hiện đại theo NOW BRAND OS — nơi Feature #1 (gác cổng) nổi bật nhất trên cùng, chuông cấu
hình được, và trạng thái cảm xúc hiển thị rõ nhưng tôn trọng riêng tư + hiến chương.

**In scope (cited):**
- Bố cục 1-trang "quan sát trước, cấu hình sau" [Source: EXPERIENCE#nguyên-tắc + brainstorm#top-insights-1]
- Card gác cổng full-width trên cùng [Source: DESIGN#2.1-GatekeeperCard]
- EmotionWave sóng 1-hue biên độ, mặc định thu gọn [Source: DESIGN#2.2-EmotionWave]
- Cấu hình chuông (âm/volume/3-mức/giờ-yên-lặng) đọc UserDefaults thay hardcode [Source: DESIGN#2.3-BellSettings]
- Brand primitives: PillSwitch tint teal, StatusDot 1-màu, CTAButton chữ tối [Source: DESIGN#2.5/2.4/2.6]
- Hợp đồng WCAG AA (contrast đã verify, focus, keyboard) [Source: DESIGN#3]
- Ràng buộc HIẾN CHƯƠNG nhúng vào design [Source: DESIGN#5]

**Architecture touchpoints:** `platforms/apple/macos/ViewController.m` + `Main.storyboard`
(xương sống — dùng chung), component mới (`GatekeeperCardView`, `EmotionWaveView`,
`BellSettingsView`, `BrandControls`), `BellMac.mm`/`NudgeCoordinatorMac.mm` (ngưỡng/âm),
`MoodWatchMac.mm` (đọc biên độ sóng), `ReflectionScreenMac` (lối tắt), `brand/svg/` (glyph).
[Source: DESIGN#6-bản-đồ-component↔code]

**Out of scope (deferdefer sang epic/việc khác):**
- Thay lexicon bằng model PhoBERT (send-risk) — thuộc mood-layer roadmap riêng.
- Bất kỳ thay đổi logic gõ trong `core/engine`.
- Port Windows (epic riêng của workspace).
- Dashboard/biểu đồ cảm xúc theo thời gian — CỐ Ý không làm (hiến chương).

**Stories (ordered theo wave phụ thuộc):**

| ID | Slug | Intent | Wave | Status |
|----|------|--------|------|--------|
| 1.1 | brand-ui-primitives | Tạo PillSwitch (tint teal) + StatusDot (1 màu) + CTAButton (chữ tối) tái dùng; sở hữu token BrandColors | 1 | ready-for-dev |
| 1.2 | emotion-wave-view | EmotionWaveView: sóng 1-hue biên độ, thu gọn mặc định, reduced-motion, VoiceOver | 1 | ready-for-dev |
| 1.3 | panel-scroll-layout | Bỏ 4-tab → 1-trang cuộn dọc + card container + divider + PrivacyFooterRow + InputMethodCard | 2 | ready-for-dev |
| 1.4 | gatekeeper-card | GatekeeperCardView full-width trên cùng + copy + lối tắt "Soi lại hôm nay →" | 2 | ready-for-dev |
| 1.5 | bell-settings-card | BellSettingsView + đọc/ghi âm/volume/3-mức/giờ-yên-lặng qua UserDefaults thay hardcode | 2 | ready-for-dev |
| 1.6 | panel-integration-states | Ráp các card vào panel + thứ tự ưu tiên + screen states (loading/empty/error/consent/tắt) | 3 | ready-for-dev |

> **Scope-conflict-check (2026-07-09):** sau khi giải quyết, chỉ còn 1 overlap CÓ CHỦ ĐÍCH:
> 1.3 ↔ 1.6 trên `ViewController.m` + `Main.storyboard` → 2 story này PHẢI serialize (1.3
> Wave 2 trước, 1.6 Wave 3 sau), KHÔNG chạy cùng đợt. Mọi cặp còn lại: OK (disjoint).
> Token `BrandColors.h/.m` đã gán cho 1.1 sở hữu; 1.3/1.4/1.5 chỉ đọc.

**Cross-epic dependencies:**
- Blocked by: none (Epic 1 độc lập, không chờ Windows Port).
- Blocks: none.

**Dependency DAG nội bộ (waves cho chạy song song an toàn):**
- **Wave 1 (song song):** 1.1, 1.2 — đều tạo file MỚI, scope rời hẳn nhau.
- **Wave 2 (song song, sau wave 1):** 1.3, 1.4, 1.5 — 1.4 dùng EmotionWaveView (1.2) + CTA (1.1); 1.3/1.5 dùng brand primitives (1.1).
- **Wave 3:** 1.6 — ráp tất cả; đụng `ViewController.m`+`Main.storyboard` (chung với 1.3) nên **nối tiếp sau 1.3**.
- File tranh chấp duy nhất: `ViewController.m` + `Main.storyboard` (do 1.3 rồi 1.6 sở hữu — phải serialize). Mọi story khác dùng file mới → disjoint.

---

## Delivery Tracking (count-based)

- Total stories: 6
- Ready-for-dev: 6
- Done: 0
- Remaining: 6
- Completion rate: 0/6

## Notes

- Đây là epic UI-nặng trên AppKit: `Main.storyboard` là XML lớn dùng chung → không thể song
  song hoá tuyệt đối. Giải pháp: đẩy phần lớn UI vào **NSView subclass file mới** (mỗi story
  1 component), chỉ để phần "nối dây vào panel" ở story tích hợp (1.6) chạy sau cùng.
- Mọi story chạm copy trạng thái phải mang acceptance criterion "gate: mô tả hay phán xét?".
- Testing: dự án C++/ObjC không có unit-test UI — verify bằng `make build` sạch (0 warning
  mới) + checklist thủ công theo screen states trong EXPERIENCE. Engine không đụng → `make
  test` giữ xanh là đủ chứng minh không phá bộ não dùng chung.
