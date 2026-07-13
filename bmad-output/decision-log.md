# Decision Log — Mindful Keyboard — Windows Port

A threaded, append-only record of decisions made across BMAD planning workflows.
Every later skill (brief, PRD, architecture, stories) appends here so the reasoning
behind the plan stays visible and consistent.

**How to use:** add a new entry at the top of the log (newest first). Never rewrite
or delete past entries — supersede them with a new entry that references the old one.

## Entry format

```
### YYYY-MM-DD — <short title>
- **Decision:** <what was decided>
- **Rationale:** <why; alternatives considered>
- **Made by:** <skill/workflow, e.g. bmad-init, prd, architecture>
- **Supersedes:** <link to prior entry, if any>
```

---

### 2026-07-13 — Diện mạo mới v2: popover chia tab + hợp nhất chuông↔cảm xúc + thuật toán Soi lại
- **Decision:** Chốt 9 điểm sau một phiên brainstorm nhiều vòng (chủ dự án điều hướng, có 3 file mockup duyệt tận mắt):
  1. **Popover chia 3 tab** (Hôm nay · Chuông · Bộ gõ) kiểu Haynoi (segmented trắng-active + thẻ nhóm eyebrow), **bỏ scroll-list dài**. Refactor `PanelViewController`, **tái dùng nguyên** `GatekeeperCardView` / `BellSettingsView` / `InputMethodCardView` + wiring sẵn có — chỉ đổi cách sắp thành tab.
  2. **Cửa sổ quản lý 6 mục nav trái**: Hôm nay · Chuông · Bộ gõ (Kiểu gõ/Gõ tắt/Chuyển mã) · Riêng tư · **Hệ thống (mục thứ 6 mới)** · Giới thiệu — gộp cửa sổ 4-tab + macro + convert + about; menu tray co gọn (Bảng điều khiển/Gõ tắt/Chuyển mã/Giới thiệu biến khỏi menu).
  3. **Nhận diện cảm xúc theo thời gian = "dòng sông"** (1 trục phẳng↔gợn, 1 hue teal, đổi biên độ). KHÔNG tích cực/tiêu cực, KHÔNG streak/heatmap/số.
  4. **Lấy mẫu**: để ý liên tục trong bộ nhớ, ghi 1 số trung bình mỗi nhịp chuông (30/60'); quãng không gõ để **trống** (không vẽ phẳng lặng giả).
  5. **Chuông ↔ cảm xúc hợp nhất**: chuông = nhịp lấy mẫu (mỗi ngân = 1 điểm lên sông); **độ nhạy dùng chung** gác cổng + chuông; **icon menu-bar chỉ báo VN bật/tắt, KHÔNG báo cảm xúc** (giữ riêng tư ở mặt công khai).
  6. **Ba chân kiềng dữ liệu**: sóng chữ (auto) + khoảnh khắc gác cổng (giờ/app/lựa chọn) + **check-in 1 chạm** khi chuông (3 mức sóng, tự nguyện, tự ẩn, bỏ qua vẫn ghi tự động) — dùng lại 2 cột `checkin` sẵn có trong `MoodStoreMac`.
  7. **Độ nhạy = lớp diễn giải, không phải cái cân**: điểm gợn thô ghi nhật ký KHÔNG đổi khi đổi độ nhạy (đo tách khỏi diễn giải); gác cổng có **sàn**, không bao giờ tắt hẳn. Bảng khởi hành 3 mức: câu "gợn" khi điểm ≥ 0.6/0.5/0.4; chuông ngân sau 5/3/2 câu gợn liên tiếp; gác cổng hỏi khi ≥ 0.6/0.5/0.45.
  8. **Màn Soi lại**: 4 phép tính (dòng sông · đỉnh gợn [cần ≥2 câu/nhịp] · quãng lặng dài nhất · "lặng lại" kể-thành-câu-không-thành-số) + 4 nhịp trình bày (Nhận ra → Cho phép → Soi → Nuôi dưỡng); **câu hỏi là trung tâm** (bộ câu hỏi xoay vòng không lặp 2 ngày liền, tối đa 1 gợi ý hành động); ngày gõ ít → nói thật "hồ chưa đủ nét", không bịa.
  9. **Thi công = 6 bước tuần tự**, mỗi bước qua cổng chất lượng + chủ dự án duyệt kết quả thật; agent chạy "tự động có người gác" — **dừng-hỏi khi chạm nhận diện/pháp lý/riêng tư, xong một bước, hoặc phát sinh quyết định ngoài plan**.
- **⚠️ Hai điểm chạm CỘT TRỤ RIÊNG TƯ (chủ dự án đã đồng thuận có ghi nhận):** (4) ghi nhật ký **nhiều hơn hiện tại** — nhưng CHỈ con số điểm gợn + mốc giờ, **không bao giờ lưu chữ đã gõ**, vẫn mã hoá + có nút xoá + tự xoá định kỳ; (6) check-in phơi thêm một mẩu tự-thuật của người dùng — tự nguyện hoàn toàn.
- **Rationale:** Chủ dự án chạy thật bản popover scroll-list (2 entry 2026-07-11) + đối chiếu app Haynoi → muốn "chia tab từng module cho gọn". Và muốn chuông + cảm xúc thành **một hệ thống logic** để người dùng nhận ra trạng thái hiện tại (không phải 2 tính năng rời). Chốt "chuông là nhịp lấy mẫu" giải bài toán đó bằng một khái niệm chung. Mọi quyết định lọc qua HIẾN CHƯƠNG §2.2/2.3 — **cố ý bác** việc bê nguyên "Insights + BEST STREAK + activity-grid + đếm chữ" của Haynoi (vi phạm 2.2). Cách "dòng sông theo giờ" giữ được ý "theo dõi nhịp cảm xúc" mà KHÔNG thành bảng điểm.
- **Made by:** phiên "brainstorm diện mạo mới v2" (chủ dự án điều hướng qua nhiều vòng AskUserQuestion + mockup). Verify tầng ý tưởng = 3 artifact mockup duyệt tận mắt (plan chốt / popover v2 chia tab / vòng Soi lại) + soát HIẾN CHƯƠNG. Thi công dispatch riêng theo 6 bước.
- **Supersedes:**
  - Phần "popover = **scroll-list**" của 2 entry 2026-07-11 → nay **chia 3 tab** (nội dung + wiring các thẻ GIỮ NGUYÊN, chỉ đổi cách sắp xếp).
  - **Nới ranh** "KHÔNG biểu đồ theo thời gian" của `EXPERIENCE-macos-control-panel.md §3/§6`: **cho phép "dòng sông theo giờ"** như phần mở rộng của con sóng nhận diện (1 hue, biên độ, KHÔNG phải chart cột/đường) — điều kiện cứng: không số, không streak, không valence-color; kèm lấy mẫu tối thiểu + check-in tự nguyện. Đây là amendment CÓ CHỦ ĐÍCH, chủ dự án chốt.

### 2026-07-11 — Compact redesign popover (kiểu danh sách Haynoi, bỏ "hộp card xếp chồng")
- **Decision:** Đổi popover từ "nhiều card viền + nền xám" sang **danh sách nhẹ kiểu Haynoi**: nền panel
  TRẮNG liền mạch; **bỏ vỏ card** (nền/viền) của thẻ Chuông + Bộ gõ → thành hàng danh sách phân tách
  bằng **divider mảnh** (`Brand divider` 1px); **Gác cổng thành DẢI nền `tealLight` full-width** (điểm
  nhấn Feature #1 bằng sắc nền, không phải hộp viền teal) — canh lề thẳng với các mục dưới; header
  mảnh hơn (44→38); siết khoảng cách. File: `PanelViewController.mm` (nền trắng + 3 divider + full-width),
  `GatekeeperCardView.mm` (bỏ viền/bo góc, giữ nền tealLight), `BellSettingsView.mm` + `InputMethodCardView.mm`
  (bỏ nền/viền card).
- **Rationale:** Chủ dự án chạy thật + so với app Haynoi → nhận xét bản card-hộp "to & nặng", yêu cầu
  "nhỏ gọn phù hợp hơn". Bản danh sách nhẹ hơn nhiều, popover collapsed ~319pt (trước ~370+), canh lề
  đẹp. Giữ đúng HIẾN CHƯƠNG: Gác cổng vẫn nổi nhất (dải tealLight trên đỉnh + sóng), teal chrome, sóng ~,
  không gamification, "mô tả không phán xét".
- **Made by:** phiên "cải tiến giao diện" (chủ dự án chỉ đạo, có ảnh Haynoi tham chiếu). Verify build/test/
  brand-lint sạch + chụp popover compact (compact1.png / compact-expanded.png).
- **Supersedes:** phần "component = card viền bo góc" của `DESIGN-macos-control-panel.md §2.1/§2.3` (cho
  Chuông/Bộ gõ). Tinh thần Feature-#1-nổi-bật giữ nguyên (đổi cách thể hiện: dải tint thay hộp viền).

### 2026-07-11 — PHA 2 b1: thẻ "Bộ gõ" bung được trong panel (Kiểu gõ / Bảng mã / Gõ tiếng Việt)
- **Decision:** `InputMethodCardView` từ 1 hàng "mở cửa sổ" → thành thẻ BUNG ĐƯỢC (thu gọn mặc định) chứa 3 control gõ dùng-hằng-ngày: Kiểu gõ (dropdown), Bảng mã (dropdown `[OpenKeyManager getTableCodes]`), Gõ tiếng Việt (PillSwitch). Wiring nối vào **đúng hàm sẵn có** của `AppDelegate` (`onInputTypeSelectedIndex:`, `onCodeTableChanged:`, `onInputMethodSelected`) — chính path menu/ViewController đang dùng, KHÔNG tự chế xử lý engine (tránh gãy gõ). Phần còn lại (toggle chính tả/hoa/thông minh, macro, hệ thống, về) mở qua link "Cài đặt đầy đủ ▸" (cửa sổ 4-tab, chưa gộp).
- **Rationale:** Bước đầu của "gộp hết vào panel" (Q2) làm AN TOÀN theo plan (từng nhóm). Chọn 3 control cốt lõi + reuse hàm proven → rủi ro gãy gõ tiếng Việt ~0. Verify build/test/brand-lint sạch + chụp popover cả 2 trạng thái (thu gọn / bung — panel-inputexpanded.png).
- **Cập nhật (cùng ngày):** đã thêm luôn 5 toggle gõ hằng ngày vào thẻ Bộ gõ (Kiểm tra chính tả → `vCheckSpelling`+`OnSpellCheckingChanged`; Đặt dấu oà·uý → `vUseModernOrthography`; Viết hoa đầu câu → `vUpperCaseFirstChar`; Chuyển chế độ thông minh → `vUseSmartSwitchKey`; Gõ tắt → `vUseMacro`) — data-driven, map key→global đúng chuẩn IBAction. `OnSpellCheckingChanged` khai báo `extern "C"` trong `.mm` (định nghĩa C ở OpenKey.mm).
- **Made by:** phiên "cải tiến giao diện" (chủ dự án chốt "triển pha 2").
- **PHA 2 còn lại (chưa làm):** macro editor / convert / về vào panel; rồi khai tử cửa sổ 4-tab. Mỗi nhóm 1 bước, verify từng bước.

### 2026-07-11 — Re-quyết định: menu-bar POPOVER panel (như Haynoi/mockup), bỏ "thẻ nổi trên cửa sổ 4-tab"
- **Decision:** Bấm TRÁI icon menu-bar → mở **NSPopover panel trạng thái gọn 360px** (header "〜 mindful-key" + chấm trạng thái + gear ⋯ → thẻ Gác cổng → thẻ Chuông thu gọn → thẻ Bộ gõ → chân trang riêng tư). Bấm PHẢI (hoặc gear) → menu cũ (giữ nguyên `theMenu`). Thẻ Gác cổng/Chuông **chuyển từ cửa sổ 4-tab vào popover**; gỡ `mountFloatingCardsIfNeeded`/`layoutFloatingCards` khỏi `ViewController.m`. File mới: `PanelViewController.{h,mm}`, `InputMethodCardView.{h,mm}`; thêm `-preferredHeight` cho `GatekeeperCardView`; sửa `AppDelegate.m` (status item → popover). PHA 1: gear/thẻ Bộ gõ tạm mở cửa sổ 4-tab làm "cài đặt đầy đủ".
- **Rationale:** Hướng "thẻ nổi trên cửa sổ 4-tab" (reconciliation 2026-07-10) chạy thật ra kết quả rối — đọc thành "danh sách tính năng" dài, tràn khi bung. Chủ dự án chỉ rõ trải nghiệm đúng = popover trạng thái (có app Haynoi + mockup `49824db2` làm chuẩn — chính là hướng `DESIGN/EXPERIENCE-macos-control-panel.md` gốc). Chốt phiên này: bấm trái = popover; menu cũ dồn vào gear ⋯ (Q1); mục tiêu cuối = gộp hết vào panel, bỏ cửa sổ 4-tab (Q2) — **chia pha** để an rủi ro (option Q2 tự cảnh báo 2.281 dòng storyboard). Verify: build/test/brand-lint sạch + chụp popover window thật (popover3.png) khớp mockup.
- **Made by:** phiên "cải tiến giao diện" (chủ dự án điều hướng), plan approved (plan mode).
- **Supersedes:** phần layout "thẻ nổi trên cửa sổ 4-tab" của reconciliation 2026-07-10 + entry "Story 1.5 … gắn nổi trên cửa sổ" (bên dưới) — `BellSettingsView`/`GatekeeperCardView` giữ nguyên, chỉ đổi CHỖ gắn (cửa sổ → popover).
- **PHA 2 (chưa làm):** dời dần settings OpenKey từ cửa sổ 4-tab vào panel rồi khai tử cửa sổ; từng nhóm, verify từng bước.

### 2026-07-10 — Story 1.5 (Card Chuông) dựng + gắn "nổi, thu gọn mặc định" trên cửa sổ 4-tab
- **Decision:** Dựng `BellSettingsView.h/.mm` đúng khối "Chuông" trong mockup DESIGN/EXPERIENCE-macos-control-panel (segmented 3 mức chữ tự vẽ teal+chữ trắng, sound dropdown, volume track teal 1 màu, giờ yên lặng 2 chip **map đảo chiều** vào `vBellFrom/vBellTo`, PillSwitch Focus off mặc định + caption quyền, disclosure nâng cao). Thêm getter `NudgeCoordinatorMac_TenseStreakTrigger()` đọc `vBellSensitivity`. **Gắn card lên cửa sổ 4-tab (đụng `ViewController.m`) — nối dài lát cắt dọc 1.4** vì 1.6 đã superseded và chủ dự án chốt "treo giống 1.4" (phiên này). **Card THU GỌN mặc định** ("Chuông ▸", bung khi bấm) + kẹp cửa sổ trong `visibleFrame`.
- **Rationale:** Treo card Chuông bung-sẵn kiểu 1.4 làm cửa sổ cao ~1058pt (lọt ra ngoài màn hình) và che 4-tab — phát hiện khi chạy thật + chụp màn hình. Chủ dự án chọn "thu gọn mặc định" (trong 3 phương án: thu gọn / cửa sổ cuộn / đưa vào tab) để giữ "nổi trên cùng" mà cửa sổ vừa màn hình và không che 4-tab. Segmented ban đầu dựng bằng NSButton viền-off KHÔNG render → thay bằng NSControl tự vẽ (cùng kỹ thuật PillSwitch).
- **Phạm vi còn lại (chưa làm, đã báo):** (1) nối `vBellSoundName`/`vBellVolume` vào lúc chuông phát thật (đổi cơ chế phát âm ở `BellMac.mm:51` sang NSSound/AVAudioPlayer) — rủi ro hơn, không hiện trên ảnh; (2) nối `NudgeCoordinatorMac_TenseStreakTrigger()` vào `MoodWatchMac.mm` (mood-layer, ngoài scope 1.5) để mức nhạy đổi hành vi rung thật; (3) cosmetic: nội dung 4-tab hơi lấn quanh card nổi (bản chất cách "float trên storyboard", giải sạch = việc kiểu 1.6 đã superseded).
- **Made by:** phiên "thợ dựng UI theo bản vẽ" (chủ dự án điều hướng), verify bằng `make build`/`make test` + chụp cửa sổ thật.
- **Supersedes:** phần layout của story `1.6.panel-integration-states` (đã superseded) cho riêng việc gắn card Chuông.
- **Decision:** Trong 1 phiên làm việc khác (chat riêng, không biết epic-1 đã tồn tại), chủ dự
  án được hỏi lại từ đầu và chốt **giữ nguyên 4 tab, chỉ thay áo** cho cả màn Điều khiển lẫn 3
  cửa sổ legacy khác (Gõ tắt/Chuyển mã/Thông tin) — mâu thuẫn trực tiếp với goal gốc của epic-1
  ("Bỏ 4-tab → 1-trang cuộn dọc", story `1.3.panel-scroll-layout` + `1.6.panel-integration-states`).
  Khi đối chiếu lại với chủ dự án qua AskUserQuestion: **chốt kết hợp** — giữ nguyên lát cắt dọc
  đã làm (card `GatekeeperCardView` nổi trên đỉnh cửa sổ 4-tab, xem entry "Thực thi: lát cắt
  dọc" bên dưới), 4 tab bên dưới KHÔNG bị đập mà chỉ thay áo theo NOW BRAND OS. **Story 1.3 và
  1.6 chính thức SUPERSEDED** (không triển khai như đã viết — file story giữ lại làm tài liệu
  tham khảo, không xoá). Thêm 4 story mới **1.7–1.10** cho việc thay áo 4 cửa sổ (xem `epics.md`
  cập nhật), đặc tả trong `IMPLEMENTATION-PLAN-legacy-reskin.md` thay vì viết đủ 4 file
  `.story.md` đầy đủ như 1.1–1.6 (rút gọn quy trình có chủ đích, xem Rationale).
- **Rationale:** (1) `BrandControls.h/.m` (story 1.1) đã code xong + commit — dùng lại được
  100% cho cả 4 story mới, không tạo trùng lặp. (2) Lát cắt dọc (card nổi) đã hoạt động, đập
  bỏ sẽ lãng phí việc đã làm và trì hoãn Feature #1 hiển thị — không có lý do kỹ thuật để đập.
  (3) "Giữ 4 tab" giảm rủi ro thật (không phải sửa mù 2.281 dòng storyboard) và khớp đúng
  "Surgical Changes" trong CLAUDE.md cho 1 đợt cải tiến, không phải viết lại. (4) Viết đủ 4 file
  story.md đầy đủ format cho việc thuần "thay áo" (không có ẩn số kiến trúc, không cần UX
  journey mới) là overhead không cần thiết — `IMPLEMENTATION-PLAN-legacy-reskin.md` (prompt +
  owned_scope + cổng chất lượng) đã đủ để dispatch cho platform-shell-agent.
- **Hệ quả cần biết khi làm 1.7 (legacy-tabs-reskin):** đụng `ViewController.m` — file NÀY đang
  có sửa đổi CHƯA COMMIT từ lát cắt dọc (mount `GatekeeperCardView` trong `viewDidAppear`). 1.7
  phải đọc state hiện tại trước, sửa THÊM vào phần nội dung 4-tab cũ (checkbox → PillSwitch, tab
  cam → teal), TUYỆT ĐỐI không xoá/ghi đè khối `mountGatekeeperCardIfNeeded`. Vì vậy 1.7 **phụ
  thuộc 1.4** (không chạy song song với phần chưa commit của 1.4), dù về mặt file thì 1.4 "xong
  sớm" — ghi nhận đây là 1 dependency thực tế không có trong DAG gốc của 1.3/1.6.
- **1.5 (bell-settings-card) chưa quyết cách gắn:** khi tới lúc làm, cần chốt lại — nổi thành
  card thứ 2 phía trên 4 tab (giống 1.4) hay nhét vào 1 trong 4 tab cũ. CHƯA hỏi chủ dự án — để
  ngỏ, không tự quyết khi tới story đó.
- **Made by:** thực thi (platform-shell), xác nhận trực tiếp với chủ dự án qua AskUserQuestion.
- **Supersedes:** story `1.3.panel-scroll-layout`, story `1.6.panel-integration-states`
  (phần layout "bỏ 4-tab" trong entry "UX design: 2 tài liệu DESIGN + EXPERIENCE" bên dưới —
  KHÔNG phải phần EmotionWave/Gatekeeper/Bell, vẫn giữ nguyên).

### 2026-07-09 — Brainstorm: hiện đại hóa Bảng điều khiển macOS (chủ đề NGOÀI scope Windows Port)
- **Decision:** Chạy 1 phiên `bmad-brainstorm` cho chủ đề control panel **macOS** (bố cục
  hiện đại + chuông cấu hình được + hiển thị cảm xúc rõ hơn), dùng 3 kỹ thuật song song
  (SCAMPER / Six Thinking Hats / Reverse Brainstorming). Kết quả:
  `brainstorming-report-macos-control-panel.md` + 3 file chi tiết `brainstorm-macos-panel-*.md`.
- **Rationale:** Người dùng yêu cầu trực tiếp (kèm 2 ảnh chụp: menu dropdown cũ vs. app
  "Haynoi" làm tham chiếu phong cách). Khảo sát code xác nhận nhu cầu thật: `BellMac.mm:51`
  hardcode âm chuông, ngưỡng cứng trong `NudgeCoordinatorMac`, cảm xúc chỉ lộ qua 1 toggle
  menu bar. 3 kỹ thuật hội tụ vào cùng kết luận (bố cục 1-trang "quan sát trước cấu hình
  sau", bảo vệ Feature #1 bằng bố cục, chuông là quick-win, hiển thị cảm xúc mặc định
  thu gọn để né nghịch lý riêng tư).
- **⚠️ Scope note:** Chủ đề này KHÁC scope đang khoá của workspace (`project-context.md` =
  Windows Port). Artifact dùng hậu tố `-macos-panel` để tách. **CHỜ chủ dự án chốt:** mở
  workspace BMAD riêng cho sáng kiến này HAY gộp thành 1 epic trong workspace hiện tại,
  trước khi chạy bmad-ux/bmad-prd.
- **Made by:** bmad-brainstorm
- **Supersedes:** none

### 2026-07-09 — Chốt scope: macOS control panel = 1 epic trong workspace hiện tại
- **Decision:** Chủ dự án chọn GỘP sáng kiến "hiện đại hóa control panel macOS" thành **1
  epic trong workspace BMAD hiện tại** (không tách workspace riêng). Bước tiếp theo: chạy
  `bmad-ux` để biến 18 ý tưởng từ brainstorm thành DESIGN.md + EXPERIENCE.md.
- **Rationale:** Giữ mọi thứ 1 chỗ, nhẹ nhất để theo dõi. Lưu ý workspace này gốc khoá cho
  Windows Port — coi như workspace nay chứa >1 epic (Windows Port + macOS control panel);
  các artifact macOS-panel giữ hậu tố riêng để không lẫn.
- **Made by:** bmad-brainstorm (ghi nhận lựa chọn của chủ dự án)
- **Supersedes:** phần "CHỜ chủ dự án chốt" trong entry brainstorm phía trên

### 2026-07-09 — Thực thi: lát cắt dọc thay vì đúng thứ tự đợt (giảm rủi ro storyboard)
- **Decision:** Khi vào Đợt 2, thay vì làm story 1.3 (đập `Main.storyboard` 2.281 dòng →
  trang cuộn) trước theo plan, chọn **lát cắt dọc**: hiện thực `GatekeeperCardView` (story 1.4)
  rồi TREO nó lên đầu panel HIỆN TẠI qua `ViewController.viewDidAppear` (nới cửa sổ cao thêm 1
  dải ở đỉnh, nội dung cũ neo đáy giữ nguyên) — KHÔNG đập storyboard.
- **Rationale:** (1) Storyboard 2.281 dòng + ~138 control, sửa "mù" (agent không thấy UI render,
  chỉ chủ dự án thấy) rủi ro vỡ panel / mất setting OpenKey (TC-1.3-6) rất cao. (2) Theo plan,
  card gác cổng chỉ hiện ở story 1.6 (Đợt 3) — chủ dự án (notech, đang học) cần thấy kết quả
  sớm để có phản hồi thị giác. Lát cắt dọc cho "phần thưởng thị giác" (con sóng + Feature #1)
  với rủi ro thấp, panel cũ nguyên vẹn. Chủ dự án chọn hướng này.
- **Lệch plan có kiểm soát:** kéo MỘT phần việc "lắp card" của story 1.6 lên sớm cho riêng card
  gác cổng. Story 1.3 (đập storyboard) vẫn làm sau, cẩn thận, chỗ chủ dự án xem được từng bước.
  Owned-scope 1.4 (chỉ GatekeeperCardView.h/.mm) nay chạm thêm ViewController.m — ghi nhận, sẽ
  hoà vào 1.6 khi làm thật.
- **Made by:** thực thi (platform-shell + mood-layer), ngoài phạm vi BMAD planning.
- **Supersedes:** none

### 2026-07-09 — Parallel plan: 3 đợt sóng (sửa lỗi over-serialize của script)
- **Decision:** Tạo `parallelization-plan.md` (maxParallel=3) với 3 đợt: W1 {1.1,1.2} · W2
  {1.3,1.4,1.5} · W3 {1.6}, kèm tên nhánh `story/{id}-{slug}` + `integration/wave-N` + thứ tự trộn.
- **Sửa lỗi công cụ:** `build-dependency-graph.py` chuỗi hoá ngây thơ theo intra-epic-sequence
  (1.1→1.2→…→1.6) → ra 6 đợt nối tiếp, **bỏ qua "Blocked by" thật** của mỗi story. Orchestrator
  sửa lại theo DAG thật (1.3/1.4/1.5 chỉ blocked-by Wave 1; 1.2 độc lập 1.1) — đúng như skill dặn
  "ordering edges lấy từ explicit Dependency Maps". Đã cập nhật `waves.json` cho khớp; giữ
  `dependency-graph.json` raw để truy vết. Mọi cặp cùng đợt verified file-disjoint.
- **Made by:** bmad-parallel-plan (có can thiệp sửa của orchestrator)
- **Supersedes:** none

### 2026-07-09 — Bổ sung Test Plan (Bảng Nghiệm Thu thủ công) theo đề nghị chủ dự án
- **Decision:** Thêm `bmad-output/TEST-PLAN-macos-control-panel.md` — 41 test-case thủ công map
  1–1 với 41 acceptance criteria của 6 story, + Cổng Hiến Chương 10 dòng kiểm bằng mắt, +
  Definition-of-Done mỗi story, + 2 cổng tự động (`make test` + `make build`), + mục sign-off.
- **Rationale:** Chủ dự án (đang học BMAD) nhận xét đúng rằng Planning thiếu bước kiểm soát output
  trước handoff. Phân định: (a) use-case ĐÃ có gần đủ trong EXPERIENCE (journeys) → không tạo lại;
  (b) test-case/QA checklist là chỗ thiếu thật + giá trị cao nhất cho một người nghiệm thu bằng
  cách bấm (notech) → LÀM; (c) unit test cho UI = over-engineering + BMAD không viết test + epic
  không đụng engine (đã có regression) → KHÔNG làm, chỉ ghi gợi ý unit-test cho phần *logic* thật
  (đọc UserDefaults, bẫy giờ-yên-lặng-ngược, map send-risk→biên độ) để cân nhắc thành story sau.
- **Không sửa mục Testing (LOCKED) trong story:** test plan là tài liệu hợp nhất RIÊNG, tham chiếu
  story, không rewrite phần Testing đã khoá.
- **Made by:** bmad-ux (mở rộng QA planning) theo yêu cầu chủ dự án
- **Supersedes:** none

### 2026-07-09 — Sprint planning: sprint-status.yaml (3 đợt sóng, Đợt 1 dispatch ngay)
- **Decision:** Tạo `bmad-output/sprint-status.yaml` làm system-of-record thứ tự. Gán
  parallel_set: Đợt 1 {1.1, 1.2} · Đợt 2 {1.3, 1.4, 1.5} · Đợt 3 {1.6}. wave_widths [2,3,1].
  Chỉ Đợt 1 để `ready-for-dev` (dispatch ngay, owned_scope disjoint); Đợt 2/3 để `backlog`
  cho tới khi dependency 'done'.
- **Ghi rõ 2 nghĩa "ready-for-dev":** cấp FILE story = "đã biên dịch xong" (cả 6); cấp
  sprint-status = "hết dependency, dispatch được" (chỉ Đợt 1). Không mâu thuẫn — 2 nghĩa khác
  nhau, đã chú thích trong yaml để dev tool không nhầm.
- **Serialize có chủ đích giữ nguyên:** 1.6 blocked-by 1.3 (cùng ViewController.m+storyboard),
  khác đợt.
- **Made by:** bmad-sprint-planning
- **Supersedes:** none

### 2026-07-09 — Epics & Stories: chẻ epic control panel thành 6 story ready-for-dev
- **Decision:** Chẻ Epic 1 (Bảng điều khiển macOS) thành 6 story ready-for-dev
  (`bmad-output/stories/1.1..1.6`), 3 đợt song song (Wave 1: 1.1+1.2 · Wave 2: 1.3+1.4+1.5 ·
  Wave 3: 1.6). Nguồn spec = DESIGN + EXPERIENCE + brainstorm (dự án chưa có prd.md).
- **Resolve scope-conflict:** (a) Token `BrandColors.h/.m` ban đầu bị CẢ 1.1 lẫn 1.3 khai
  báo sở hữu → gán cho **1.1 sở hữu** (story brand nền tảng), 1.3/1.4/1.5 chỉ đọc. (b) Sửa
  lỗi checker báo nhầm "KHÔNG overlaps KHÔNG" ở 1.2/1.4 — do mục Owned Scope liệt kê cả dòng
  loại-trừ dạng bullet; đã chuyển ghi chú read-only/loại-trừ sang văn xuôi để checker chỉ
  parse path thật. (c) Overlap còn lại 1.3↔1.6 trên `ViewController.m`+`Main.storyboard` là
  CÓ CHỦ ĐÍCH (serialize 1.3→1.6, khác đợt) — chấp nhận, không phải lỗi.
- **Phát hiện từ agent (ghi để dev sau lưu ý, KHÔNG tự sửa code — planning-only):**
  1. `MoodWatchMac` chỉ lộ `MoodWatchMac_LastSendRisk()` (0–1), KHÔNG có API "biên độ" — map
     send-risk → biên độ sóng là `[Inference]` trong story 1.2, cần xác nhận khi code.
  2. Ngưỡng "số câu căng liên tiếp" thật là `kTenseStreakTrigger`/`kTenseStreakThreshold` ở
     `MoodWatchMac.mm:47-48` (mood-layer), KHÔNG phải trong `BellMac`/`NudgeCoordinatorMac` như
     giả định ban đầu → story 1.5 dựng hạ tầng UserDefaults + getter, còn việc nối
     `MoodWatchMac.mm` đọc getter là follow-up ngoài 1.5 (đã ghi trong story).
  3. Chưa có cơ chế volume thật (`NSBeep`/`NSUserNotification` không hỗ trợ volume) → cần
     `NSSound`/`AVAudioPlayer` (ghi trong 1.5).
  4. `vBellFrom`/`vBellTo` hiện nghĩa là "giờ HOẠT ĐỘNG" — map UI "giờ yên lặng" ngây thơ sẽ
     rung ngược trong giờ yên lặng (gotcha đã cảnh báo trong 1.5).
  5. Glyph `brand/svg/mood-*.svg` đã đúng đơn sắc teal/stone — KHÔNG dính lệch màu teal→cam.
- **Made by:** bmad-epics-and-stories
- **Supersedes:** none

### 2026-07-09 — UX design: cam CTA phải dùng chữ TỐI (WCAG AA), không chữ trắng
- **Decision:** Trong `DESIGN-macos-control-panel.md`, mọi nút CTA nền cam `#FF7A1A` dùng
  **chữ tối `#2A2A2A`** (đạt 5.50:1), KHÔNG dùng chữ trắng.
- **Rationale:** Kiểm bằng script contrast: chữ trắng trên cam `#FF7A1A` chỉ đạt **2.61:1 —
  TRƯỢT WCAG 2.1 AA**. Đổi cam sang tông đậm hơn để cứu chữ trắng thì lệch brand NOW BRAND OS
  (và tới `#C85400` vẫn chỉ 4.45:1, chưa đạt). Giữ nguyên màu cam thương hiệu + đổi màu chữ
  là cách sạch nhất, không đụng brand token.
- **Made by:** bmad-ux
- **Supersedes:** none

### 2026-07-09 — UX design: 2 tài liệu DESIGN + EXPERIENCE cho epic control panel macOS
- **Decision:** Tạo `DESIGN-macos-control-panel.md` (token/component/WCAG/ràng buộc hiến
  chương) + `EXPERIENCE-macos-control-panel.md` (journey/screen states) từ báo cáo brainstorm.
  Chốt vài hướng thiết kế: panel 1-trang cuộn dọc "quan sát trước cấu hình sau"; card gác
  cổng full-width trên cùng viền teal nhấn; chuông 3 mức định tính; EmotionWave 1-hue-đổi-biên-độ
  mặc định thu gọn; giờ yên lặng thủ công (Focus sync opt-in mặc định OFF).
- **Rationale:** Chủ dự án chọn chạy bmad-ux sau brainstorm; các ý tưởng đã đủ chín + có
  ràng buộc rõ để viết spec thẳng.
- **Made by:** bmad-ux
- **Supersedes:** none

### 2026-07-09 — Language: planning docs in Vietnamese
- **Decision:** Set `languages.communication` and `languages.document_output` to
  Vietnamese in `config.yaml` (script default was English).
- **Rationale:** every existing project doc (`CLAUDE.md`, `docs/PRD.md`,
  `docs/AGENT-BRIEF.md`, `docs/BMAD-SKILLS-GUIDE.md`) is Vietnamese; English output
  would be inconsistent with the rest of the repo. Reversible — edit `config.yaml` if
  this project ever wants English planning docs instead.
- **Made by:** bmad-init
- **Supersedes:** none

### 2026-07-09 — Scope: Windows port
- **Decision:** This bmad-output workspace plans the **Windows port** of
  mindful-keyboard — win32 keyboard hook, tray icon, send-gatekeeper, mindful bell +
  reflection screen, local encrypted mood store, packaging — reusing the shared
  `core/engine` unchanged.
- **Rationale:** `CLAUDE.md` (constitution changelog) says the project is "chuẩn bị
  bước sang giai đoạn build app Windows thật"; `docs/BMAD-SKILLS-GUIDE.md` explicitly
  scripts this as the practice exercise for buổi 1–4, recommending bmad-method track.
  Confirmed with the project owner before scaffolding.
- **Made by:** bmad-init
- **Supersedes:** none

### 2026-07-09 — Track selected: bmad-method
- **Decision:** Initialized this project on the **bmad-method** track.
- **Rationale:** Windows port touches a new OS shell (keyboard hook, tray, gatekeeper
  UI, local store) across an estimated 10-15+ stories spanning several epics — enough
  cross-cutting decisions (e.g. DPAPI vs Keychain equivalent, code-signing story) to
  warrant a written PRD + Architecture rather than a single tech-spec. Confirmed with
  the project owner (helper script `select-track.sh` also suggested bmad-method for
  ~12 stories / one builder / no hard compliance-infra requirement).
- **Made by:** bmad-init
- **Supersedes:** none
