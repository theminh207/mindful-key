# Epics — mindful-key (bổ sung: epic Bảng điều khiển macOS)

> Bản đồ epic (index mỏng, không phải context object). Chi tiết story nằm ở từng file
> `bmad-output/macos/stories/{epic}.{story}.{slug}.story.md`.
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

> **⚠️ REVISE 2026-07-10** (xem `decision-log.md` entry "Reconciliation: huỷ 1.3/1.6"). Hướng
> "bỏ 4-tab" bên dưới KHÔNG còn là hướng thi công. Hướng THẬT đang làm: card mới
> (Gatekeeper/Bell) **nổi trên đỉnh** cửa sổ 4-tab hiện có; 4 tab bên dưới **chỉ thay áo**
> NOW BRAND OS (checkbox→PillSwitch, tab cam→teal), KHÔNG bị đập. Chi tiết: story 1.7–1.10
> (mục Stories bên dưới) + `IMPLEMENTATION-PLAN-legacy-reskin.md`.

**Goal (gốc — phần "bỏ 4-tab" đã lỗi thời, xem note trên):** Thay control panel 4-tab-checkbox
cũ (kế thừa OpenKey) bằng ~~1 panel cuộn dọc~~ **card nổi + tab thay áo** hiện đại theo NOW
BRAND OS — nơi Feature #1 (gác cổng) nổi bật nhất trên cùng, chuông cấu hình được, và trạng
thái cảm xúc hiển thị rõ nhưng tôn trọng riêng tư + hiến chương.

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
| 1.1 | brand-ui-primitives | Tạo PillSwitch (tint teal) + StatusDot (1 màu) + CTAButton (chữ tối) tái dùng; sở hữu token BrandColors | 1 | **done** |
| 1.2 | emotion-wave-view | EmotionWaveView: sóng 1-hue biên độ, thu gọn mặc định, reduced-motion, VoiceOver | 1 | **done** |
| 1.3 | panel-scroll-layout | ~~Bỏ 4-tab → 1-trang cuộn dọc~~ + card container + divider + PrivacyFooterRow + InputMethodCard | 2 | **superseded** (xem 2026-07-10 trong decision-log) |
| 1.4 | gatekeeper-card | GatekeeperCardView full-width trên cùng + copy + lối tắt "Soi lại hôm nay →" | 2 | **in-progress** (lát cắt dọc, chưa commit — treo trên đỉnh 4-tab cũ) |
| 1.5 | bell-settings-card | BellSettingsView + đọc/ghi âm/volume/3-mức/giờ-yên-lặng qua UserDefaults thay hardcode | 2 | ready-for-dev (cách gắn UI: CHƯA chốt — xem decision-log) |
| 1.6 | panel-integration-states | ~~Ráp các card vào panel cuộn dọc~~ + thứ tự ưu tiên + screen states (loading/empty/error/consent/tắt) | 3 | **superseded** (xem 2026-07-10 trong decision-log) |
| 1.7 | legacy-tabs-reskin | Thay áo nội dung 4 tab cũ (checkbox→PillSwitch, tab cam→teal, card hoá) trong `ViewController.m` — **giữ nguyên 4 tab + khối `mountGatekeeperCardIfNeeded`** | 2b | **done** (commit 3b41b3d) — gap: radio Chế độ gõ chưa tint được (AppKit hạn chế) |
| 1.8 | macro-window-reskin | Thay áo cửa sổ Gõ tắt (`MacroViewController.mm`): tên cột tiếng Việt, CTA cam cho "Thêm", card hoá | 2b | **done** (commit d370161) |
| 1.9 | convert-window-reskin | Thay áo cửa sổ Chuyển mã (`ConvertToolViewController.mm`): bỏ ảnh nút xanh-dương/xanh-lá, CTA cam + nút phụ trung tính | 2b | **done** (commit 7c759a7) |
| 1.10 | about-window-reskin | Thay áo cửa sổ Thông tin (`AboutViewController.m`): logo sóng `~` thay "V" đỏ, vá bug đè chữ, **giữ nguyên credit Mai Vũ Tuyên (GPL v3)** | 2b | **done** (commit 2a4a090) |

> **Scope-conflict-check (2026-07-09, revise 2026-07-10):** 1.3/1.6 superseded nên overlap gốc
> của chúng với `ViewController.m`/`Main.storyboard` không còn áp dụng. Overlap MỚI cần biết:
> **1.7 ↔ 1.4** cùng đụng `ViewController.m` — 1.4 đang có sửa đổi CHƯA COMMIT (mount card gác
> cổng), nên 1.7 **phải chạy sau khi hiểu rõ state của 1.4**, sửa THÊM chứ không ghi đè (xem
> decision-log). 1.8/1.9/1.10 dùng file hoàn toàn riêng (`MacroViewController.mm`,
> `ConvertToolViewController.mm`, `AboutViewController.m`) → disjoint với mọi story khác, chạy
> song song an toàn với nhau và với 1.5. Token `BrandColors.h/.m` (1.1) đã done — 1.7-1.10 chỉ
> đọc, dùng lại `PillSwitch`/`StatusDot`/`CTAButton` có sẵn trong `BrandControls.h/.m`, KHÔNG
> tạo helper mới trùng lặp.

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

- Total stories: 10 (6 gốc + 4 thêm 2026-07-10; 2 trong 6 gốc đã superseded)
- Done: 6 (1.1, 1.2, 1.7, 1.8, 1.9, 1.10)
- Superseded: 2 (1.3, 1.6 — không tính vào "còn phải làm")
- In-progress: 1 (1.4 — lát cắt dọc, chưa commit)
- Remaining: 1 (1.5 — bell-settings-card, cách gắn UI chưa chốt)
- Completion rate: 6/8 hiệu lực (loại 2 superseded khỏi mẫu số)

## Notes

- Đây là epic UI-nặng trên AppKit: `Main.storyboard` là XML lớn dùng chung → không thể song
  song hoá tuyệt đối. Giải pháp gốc (đẩy UI vào NSView subclass file mới, story tích hợp ráp
  sau cùng) đã **đổi hướng 2026-07-10**: thay vì 1 story tích hợp đập storyboard, các card mới
  tự treo nổi lên trên (lát cắt dọc), 4 tab cũ giữ nguyên cấu trúc — ít điểm chạm storyboard
  chung hơn hẳn so với plan gốc.
- Mọi story chạm copy trạng thái phải mang acceptance criterion "gate: mô tả hay phán xét?".
- Testing: dự án C++/ObjC không có unit-test UI — verify bằng `make build` sạch (0 warning
  mới) + checklist thủ công theo screen states trong EXPERIENCE. Engine không đụng → `make
  test` giữ xanh là đủ chứng minh không phá bộ não dùng chung.
- Story 1.7–1.10 KHÔNG có file `.story.md` đầy đủ format (khác 1.1–1.6) — quyết định có chủ
  đích (xem decision-log 2026-07-10): việc thuần "thay áo", không có ẩn số kiến trúc/UX mới,
  nên dùng `IMPLEMENTATION-PLAN-legacy-reskin.md` (prompt + owned_scope + cổng chất lượng) làm
  spec thay thế, đỡ overhead viết đủ format nặng cho việc rủi ro thấp.
