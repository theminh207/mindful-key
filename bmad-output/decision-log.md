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

### 2026-07-10 — Reconciliation: huỷ 1.3/1.6 (bỏ 4-tab), chốt "card nổi + thay áo tab" là kiến trúc cuối
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
