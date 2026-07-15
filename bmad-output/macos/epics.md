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

> **Trạng thái + bằng chứng thi công (nguồn sự thật DUY NHẤT): `sprint-status.yaml` mục
> `stories:`.** Bảng dưới đây KHÔNG còn cột Status — từng ghi text độc lập ở đây từng lệch
> so với `sprint-status.yaml` nhiều lần (vd 1.4/1.5 từng ghi "in-progress"/"ready-for-dev"
> trong khi đã `done` từ lâu). Xem đồng thời `docs/TEST_MATRIX.md` để biết mức bằng chứng
> (build-verified hay đã có người xem/gõ thật).

| ID | Slug | Intent | Wave |
|----|------|--------|------|
| 1.1 | brand-ui-primitives | Tạo PillSwitch (tint teal) + StatusDot (1 màu) + CTAButton (chữ tối) tái dùng; sở hữu token BrandColors | 1 |
| 1.2 | emotion-wave-view | EmotionWaveView: sóng 1-hue biên độ, thu gọn mặc định, reduced-motion, VoiceOver | 1 |
| 1.3 | panel-scroll-layout | ~~Bỏ 4-tab → 1-trang cuộn dọc~~ + card container + divider + PrivacyFooterRow + InputMethodCard | 2 |
| 1.4 | gatekeeper-card | GatekeeperCardView full-width trên cùng + copy + lối tắt "Soi lại hôm nay →" | 2 |
| 1.5 | bell-settings-card | BellSettingsView + đọc/ghi âm/volume/3-mức/giờ-yên-lặng qua UserDefaults thay hardcode | 2 |
| 1.6 | panel-integration-states | ~~Ráp các card vào panel cuộn dọc~~ + thứ tự ưu tiên + screen states (loading/empty/error/consent/tắt) | 3 |
| 1.7 | legacy-tabs-reskin | Thay áo nội dung 4 tab cũ (checkbox→PillSwitch, tab cam→teal, card hoá) trong `ViewController.m` — **giữ nguyên 4 tab + khối `mountGatekeeperCardIfNeeded`** | 2b |
| 1.8 | macro-window-reskin | Thay áo cửa sổ Gõ tắt (`MacroViewController.mm`): tên cột tiếng Việt, CTA cam cho "Thêm", card hoá | 2b |
| 1.9 | convert-window-reskin | Thay áo cửa sổ Chuyển mã (`ConvertToolViewController.mm`): bỏ ảnh nút xanh-dương/xanh-lá, CTA cam + nút phụ trung tính | 2b |
| 1.10 | about-window-reskin | Thay áo cửa sổ Thông tin (`AboutViewController.m`): logo sóng `~` thay "V" đỏ, vá bug đè chữ, **giữ nguyên credit Mai Vũ Tuyên (GPL v3)** | 2b |

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

## Epic 2: Áo mới v2 — diện mạo macOS

> **Nguồn:** `decision-log.md` entry 2026-07-13 "Diện mạo mới v2" (9 quyết định) +
> `mockups-v2/ao-moi-mindful-key.html` (plan 6 bước + bảng "Nút cũ về chỗ ở mới" + thuật toán
> lấy mẫu/độ nhạy/Soi lại) + `mockups-v2/mockup-v2-tabbed.html` (popover 3 tab) +
> `mockups-v2/soi-lai-mockup.html` (vòng Soi lại).
> **SUPERSEDE** hướng "card nổi trên 4-tab" của Epic 1 (reconciliation 2026-07-10).

**Goal:** Gom các cửa sổ rời rạc về **một căn nhà tĩnh lặng** — popover menu-bar chia 3 tab
(Hôm nay·Chuông·Bộ gõ) + cửa sổ quản lý 6 mục nav trái — nơi cảm xúc là **dòng sông** 1-hue
biên độ (KHÔNG bảng điểm), chuông là **nhịp lấy mẫu**, câu hỏi Soi lại là trung tâm.

**In scope (cited):**
- Popover 3 tab thay scroll-list dài [Source: decision-log#2026-07-13-dec1 + mockup-v2-tabbed.html]
- Cửa sổ quản lý 6 mục nav trái (gộp 4 cửa sổ cũ + Hệ thống mục thứ 6) [Source: decision-log#dec2 + ao-moi#một-căn-nhà]
- Dòng sông cảm xúc: 1 trục phẳng↔gợn, 1 hue, đổi biên độ [Source: decision-log#dec3 + ao-moi#dòng-sông]
- Lấy mẫu theo nhịp chuông (1 số trung bình/nhịp, quãng không gõ để TRỐNG) [Source: decision-log#dec4 + ao-moi#cách-lấy-mẫu]
- Chuông ↔ cảm xúc hợp nhất; độ nhạy dùng chung; icon menu-bar chỉ báo VN [Source: decision-log#dec5]
- Ba chân kiềng: sóng chữ + khoảnh khắc gác cổng + check-in 1 chạm [Source: decision-log#dec6 + ao-moi#ba-chân-kiềng]
- Độ nhạy = lớp diễn giải (điểm thô bất biến); gác cổng có SÀN [Source: decision-log#dec7 + ao-moi#độ-nhạy]
- Màn Soi lại: 4 phép tính + 4 nhịp, câu hỏi trung tâm [Source: decision-log#dec8 + soi-lai-mockup.html]
- Thi công 6 bước tuần tự, mỗi bước qua cổng + chủ dự án duyệt [Source: decision-log#dec9]

**Architecture touchpoints:** `PanelViewController` (popover 3 tab), `SettingsWindowController`
(MỚI — cửa sổ 6 mục), tái dùng `ViewController`/`MacroViewController`/`ConvertToolViewController`/
`AboutViewController` làm pane; `MoodStoreMac` (schema lấy mẫu + check-in), `MoodWatchMac` (vòng
lấy mẫu), `NudgeCoordinatorMac` (độ nhạy 3 mức), `BellMac`/`BellSettingsView` (chuông), `EmotionRiverView`
(dòng sông), `ReflectionScreenMac` (Soi lại 4 nhịp), `AppDelegate.m` (tray + wiring). KHÔNG đụng `core/`.

**Out of scope (Epic riêng / lộ trình xa):**
- PhoBERT thay lexicon + tín hiệu "gõ thế nào" (nhịp/xoá/HOA) — lộ trình xa, cần dataset + đo tốc độ.
- Mọi thay đổi trong `core/engine` / `core/mood` (bộ não dùng chung — iOS đóng băng cùng).
- iOS (đội riêng) + hợp nhất lexicon về core — ghi ở `_shared/`, ngoài Epic 2 macOS.

**Stories (6 bước tuần tự — build-xem-thật rồi mới sang bước kế):**

> **Trạng thái + bằng chứng thi công (nguồn sự thật DUY NHẤT): `sprint-status.yaml` mục
> `v2_roadmap.steps`.** Không lặp lại status ở bảng này — xem đồng thời `docs/TEST_MATRIX.md`
> để biết mức bằng chứng (build-verified hay đã có người xem/gõ thật).

| ID | Slug | Intent | Owner |
|----|------|--------|-------|
| 2.1 | popover-3tab-foundation | Popover 3 tab: thẻ trắng, sóng nhỏ 150px, segmented, khung dòng sông TRỐNG thật thà | platform-shell |
| 2.2 | six-nav-settings-window | Cửa sổ 6 mục nav trái, tái dùng ViewController/Macro/Convert/About làm pane; trim menu tray; Hôm nay/Chuông/Riêng tư = phòng trống | platform-shell |
| 2.3 | sampling-journal-sensitivity | Kho nhật ký lấy mẫu theo nhịp chuông + check-in 3 sóng + độ nhạy 3 mức (nối NudgeCoordinator hardcode "3"). **CHẠM RIÊNG TƯ** | mood-layer |
| 2.4 | emotion-river-reflection | Vẽ dòng sông từ dữ liệu lấy mẫu + màn Soi lại 4 nhịp (Nhận ra→Cho phép→Soi→Nuôi dưỡng), câu hỏi trung tâm | mood-layer |
| 2.5 | bell-detail-sounds | Chuông chi tiết + chọn/tải tiếng chuông, nghe thử | platform-shell |
| 2.6 | privacy-export-autopurge | Xuất CSV + tự xoá định kỳ ("quên có chủ đích") | mood-layer |

> **Sizing note:** 2.3 và 2.4 mỗi cái CÓ THỂ vượt 1 dev-day (2.3 = store schema + lấy mẫu +
> check-in UI + độ nhạy; 2.4 = river render + 4 phép tính + màn Soi lại 4 nhịp). Khi compile
> story, nếu vượt → CHẺ đôi (vd 2.3a store+lấy-mẫu / 2.3b check-in+độ-nhạy). Giữ 6 ở epic map
> để khớp 6 bước roadmap; chẻ ở tầng story.

**Scope-conflict / thứ tự:** các story CHỦ Ý **tuần tự** (không song song) vì chồng file nhau:
`BellSettingsView` (2.1→2.3 độ-nhạy→2.5 chuông), `MoodStoreMac` (2.3→2.6), `EmotionRiverView`
(2.1 tạo→2.4 nhồi), cửa sổ 6 mục (2.2→2.4 pane Hôm nay→2.6 pane Riêng tư). Chạy đúng thứ tự
2.2→2.3→2.4→2.5→2.6, mỗi bước 1 commit + chủ dự án duyệt.

**Cross-epic dependencies:**
- Blocked by: Epic 1 (brand primitives 1.1 + EmotionWaveView 1.2 + reskin 1.7–1.10 — đã done).
- Blocks: none.

---

## Delivery Tracking

> **Đã bỏ đếm tay ở đây (2026-07-14)** — từng là nguồn thứ 3 ghi cùng 1 sự thật với
> `sprint-status.yaml`, và đã sai lệch (từng ghi "1.5 remaining" dù story đó done từ lâu).
> Số liệu done/superseded/remaining thật: xem `sprint-status.yaml` mục `sequencing_summary`
> (Epic 1) và `v2_roadmap` (Epic 2).

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
