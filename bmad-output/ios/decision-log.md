# Decision Log — mindful-key · iOS

Log riêng của đội iOS (khác `bmad-output/decision-log.md` ở root — chỗ đó dành cho quyết định
xuyên suốt nhiều đội, xem `bmad-output/_shared/README.md`). Threaded, append-only: thêm entry
mới ở TRÊN CÙNG (mới nhất trước), không xoá/sửa entry cũ.

## Entry format

```
### YYYY-MM-DD — <short title>
- **Decision:** <what was decided>
- **Rationale:** <why; alternatives considered>
- **Made by:** <skill/workflow>
- **Supersedes:** <link to prior entry, if any>
```

**⚠️ Supersede một FILE đặc tả cụ thể (không chỉ 1 entry khác trong sổ này) — BẮT BUỘC làm
cùng lúc, không tách lượt sau:** nếu quyết định vừa ghi làm cho nội dung một file đặc tả
(`DESIGN*.md`, `EXPERIENCE*.md`, `tech-spec*.md`, …) không còn đúng nữa, PHẢI dán ngay 1 dòng
banner ở ĐẦU chính file đó, trỏ về entry vừa ghi. Mẫu banner:

```
> ⚠️ **SUPERSEDED (YYYY-MM-DD)** — xem `decision-log.md` entry "<tên entry>". <1 câu: phần
> nào của file này không còn đúng / phần nào vẫn còn dùng được>.
```

Lý do bắt buộc: trường `Supersedes:` ở trên chỉ ghi MỘT CHIỀU — sổ này biết cái mới thay cái
cũ, nhưng bản thân file cũ thì không hề hay biết. Ai mở thẳng file cũ (không qua decision-log)
sẽ hiểu nhầm nó vẫn còn hiệu lực. Đồng bộ cùng quy tắc ở `bmad-output/decision-log.md` (root),
chốt 2026-07-14 sau khi phát hiện lỗ hổng này ở đội macOS.

---

### 2026-07-13 — Chốt 3 quyết định Round 3 (Q4/Q5/Q6) + kiến trúc nhật ký iOS
- **Decision:** Chủ dự án chốt (qua AskUserQuestion) 3 câu mở khóa Round 3 (nhật ký + soi lại + theme):
  - **Q4 — nhật ký hiện gì:** **câu phản chiếu là trọng tâm + bối cảnh SỐ nhỏ** (số lần "mặt hồ gợn
    sóng" hôm nay + giờ dễ căng nhất), cỡ nhỏ, đặt dưới câu hỏi — ngang bản macOS `FetchTodaySummary`.
    **KHÔNG biểu đồ, không streak, không điểm.**
  - **Q5 — soi lại là màn hay notification:** **màn trong tab "Mặt hồ" + 1 thông báo đẩy nhẹ cuối
    ngày**, MẶC ĐỊNH TẮT, opt-in, tối đa 1 lần/ngày, giờ chỉnh được, tắt được. Copy quan sát không phán xét.
  - **Q6 — theme cá nhân hóa:** **vài preset trung tính chốt sẵn** (2–4 bảng màu trong palette NOW
    BRAND, đều trung tính), live-preview, **KHÔNG cho tự chọn màu tự do** (chặn user tạo tông đỏ/xanh
    mã hóa cảm xúc).
- **Kiến trúc đã chốt (sau khi grounding code thật R2 + tiền lệ macOS):**
  - Nhật ký iOS **CHỈ ghi "khoảnh khắc căng" (send-risk ≥ ngưỡng chết ~0.3)**, KHÔNG ghi mọi câu —
    mirror mô hình "sự kiện" của macOS (`MoodStoreMac` log event, không log liên tục), tối thiểu hóa
    dữ liệu. Schema: `timestamp + send-risk`, TUYỆT ĐỐI không văn bản gốc (như `MoodStoreMac` schema).
  - Kho sống ở **`platforms/apple/shared/`** (cùng chỗ `BellReminderSettingsBridge`), Foundation +
    CommonCrypto + Security → host-testable. **AES-256-CBC + khóa Keychain** (mirror `MoodStoreMac.mm`),
    **KHÔNG SQLite** (tránh dependency nặng cho extension chật RAM ~48–60MB) — dùng file sự kiện mã hóa gọn.
  - **Extension GHI** (gọi trong callback `MoodBridge.mm`, ngay cạnh `NudgeCoordinatorIOS`, SAU cổng
    ô-bảo-mật), **container ĐỌC** (màn soi lại). Khóa AES chia sẻ qua **keychain-access-groups** — 2
    entitlements hiện CHỈ có App Group, phải THÊM.
  - Consent gate hỏi trong container (tab Mặt hồ / Cài đặt), KHÔNG hỏi giữa lúc gõ; extension không
    ghi gì tới khi có consent (cache cờ consent qua App Group, như macOS check `HasConsent`).
- **Rationale:** Nút thắt chặn "linh hồn" R3. Q4/Q6 bám hiến chương (số liệu = bối cảnh phụ, màu trung
  tính, không gamify). Q5 là **nới lỏng CÓ Ý THỨC** so với mandate iOS "nhắc THỤ ĐỘNG" (2026-07-10):
  notification là "nhắc chủ động", nhưng chủ dự án chọn với rào chắn cứng (mặc định TẮT + opt-in + 1
  lần/ngày + tắt được) → ghi `docs/FRICTION-LOG.md`. Kiến trúc "log tense-event, no SQLite, shared store,
  extension ghi/container đọc" chọn để tối thiểu hóa dữ liệu + nhẹ RAM + đúng "1 kho on-device mã hóa".
- **Hệ quả:** R3 shard thành **4 story** (3.1 kho + consent, 3.2 theme, 3.3 màn soi lại, 3.4 notification).
  R3 khiến câu hỏi **Full Access** (còn `mở`, FRICTION-LOG 2026-07-13) NẶNG KÝ hơn — giờ PERSIST dữ liệu
  phái sinh (không chỉ sóng tức thời) → khuyến nghị chủ dự án chính thức đóng/khẳng định dòng friction đó.
- **Made by:** chủ dự án (qua AskUserQuestion), ghi bởi agent đội iOS (plan phase, Opus).
- **Supersedes:** đóng B2/B3 open questions trong `EXPERIENCE.md` Future (Round 3); mở tech-spec-r3.md.

### 2026-07-13 — Chốt 4 quyết định nhận diện mở khóa Round 2 (Q1/Q2/Q3/Q11)
- **Decision:** Chủ dự án chốt (qua AskUserQuestion) 4 câu nhóm B/C của decision queue — mở khóa
  lớp cảm xúc Round 2:
  - **Q1 — map send-risk→biên độ sóng:** **ngưỡng chết + dâng mượt.** Mặt hồ PHẲNG LẶNG khi
    `send-risk` dưới ~0.3 (vùng chết), rồi biên độ dâng MƯỢT (không bậc thang) theo risk. Không
    gợn vặt khi bình thường — đúng "mặt hồ phẳng lặng ↔ gợn sóng" (hiến chương §2.3).
  - **Q2 — câu quan sát:** **CHỈ con sóng, KHÔNG chữ.** Không hiện câu "Mặt hồ đang gợn sóng".
    Thanh gợi ý chật; để sóng tự nói, ít làm phiền nhất.
  - **Q3 — tiếng chuông:** **chuông nhắc nghỉ sau N câu căng liên tiếp** (mô hình `BellMac`/
    `NudgeCoordinator` macOS: rung/âm nhẹ + cooldown chống dồn dập). KHÔNG phải preset-âm-khi-gõ.
  - **Q11 — model send-risk:** **lexicon on-device trước, PhoBERT ONNX sau** (nhẹ RAM, an toàn
    trần jetsam ~48–60MB; nâng model sau nếu RAM cho phép).
- **Rationale:** Đây là nút thắt duy nhất chặn "linh hồn" R2 (con sóng + chuông). Cả 4 theo phương
  án khuyến nghị, bám hiến chương (biên độ mang nghĩa, không màu valence, không gamify, quan sát
  không phán xét). Chủ dự án uỷ quyền tự hoàn thành R2 theo các chốt này.
- **Hệ quả:** Track B (render sóng FR-A08 + chuông FR-A10) hết vướng quyết định — spec + code được.
  Track A (nền kỹ thuật: MoodBridge tính risk, lõi bàn phím, cài đặt, macro) vốn không chặn, làm song song.
  CÒN mở: **Q10b** (glyph/wordmark/giọng copy chính thức) — placeholder đang chạy, không chặn dev.
- **Made by:** chủ dự án (qua AskUserQuestion), ghi bởi agent phân tích.
- **Supersedes:** đóng Q1/Q2/Q3/Q11 (nhóm B/C) trong `analysis/09-bmad-reconcile.md`.

### 2026-07-11 — Audit đồng bộ 3 nguồn + chốt tiering "gõ tắt" (tách FR-A15)
- **Decision:** Quét chéo khung L (Laban) · gói `analysis/` · specs (`EXPERIENCE.md`/`DESIGN.md`) tìm
  xung đột. Kết luận: KHÔNG có xung đột nền tảng (3 nguồn nhất trí phần hồn). Xử lý:
  1. **Vá drift cơ học** (commit b6953bc): DESIGN radius 12→8pt (§2.1/§2.4), tab Mặt hồ round-tier
     3→2–3, EXPERIENCE thêm cảnh báo "L (lô thiết kế) ≠ mức sóng 1–5", ROADMAP cập nhật Mốc B xong,
     09-reconcile thêm bảng bắc cầu **F1–F8 ↔ Module 1–6** + ghi chú 3 FR mồ côi (nền cá nhân, lớp
     nhịp thở, màn Giới thiệu-GPL — cần chính thức hoá khi tới round).
  2. **Chốt 1 mâu thuẫn thật — tiering "gõ tắt":** TÁCH `FR-A15` cũ → **FR-A15a Gõ tắt (macro chữ) =
     Round 2** (engine đã có `Macro.cpp`, rẻ) + **FR-A15b Vuốt phím = Round 4** (nặng). Cập nhật
     `07-functional-requirements`, `ROADMAP`, `06-software-vision`, `09-reconcile §6`.
- **Rationale:** analysis gộp nhầm 2 thứ khác cân nặng vào FR-A15. Gõ tắt rẻ vì logic macro nằm sẵn
  trong bộ não dùng chung; vuốt phím mới là việc lớn. Hướng đồng bộ: **specs = nguồn chân lý UX**,
  analysis trỏ về specs, khung L = giàn giáo quy trình trực giao (không phải mô hình sản phẩm).
- **Made by:** audit đồng bộ (3 agent soi song song) + chủ dự án chốt qua AskUserQuestion.
- **Supersedes:** FR-A15 (gộp) → FR-A15a + FR-A15b.

### 2026-07-11 — Mốc B XONG: iOS gõ Telex thật qua core/engine (commit 91a8742)
- **Decision:** Nối bàn phím tự vẽ iOS vào `vKeyHandleEvent()` của `core/engine` qua `KeyboardBridge`,
  giải mã HookState (`backspaceCount` + `charData`, chế độ Unicode vCodeTable=0) thành thao tác
  `UITextDocumentProxy` (deleteBackward + insertText). Logic diễn giải HookState bám ĐÚNG bản mẫu
  đã có: `platforms/apple/macos/OpenKey.mm` (SendNewCharString) + `tests/core/test_engine.cpp`
  (typeChar). Bridge thuần Foundation (không UIKit) → test chạy được trên host.
  - **Quyết định thiết kế:** bridge trả struct kết quả `{backspaceCount, textToInsert}` thay vì tự
    đụng `UITextDocumentProxy` — để (a) tách vỏ UI khỏi nội tạng engine, (b) `tests/ios` test được
    trên host bằng `NSMutableString` làm "ô nhập ảo" (không cần Simulator).
  - **Space/Backspace vẫn ĐI QUA engine** (KEY_SPACE/KEY_DELETE) chứ không chèn/xoá "tắt" — để buffer
    từ trong bộ não luôn đồng bộ (nếu không, từ kế tiếp sẽ hỏng).
- **Bằng chứng (verify không đoán):** `make test` xanh cả 3 đội — `tests/ios/bridge_test` chạy 5 ca
  Telex của `tests/core` XUYÊN QUA bridge đều PASS ("vieetj"→"việt"); `git diff core/` rỗng;
  `xcodebuild` scheme `MindfulKeyKeyboard` (iphonesimulator) **BUILD SUCCEEDED**, `.appex` nhúng vào
  app container. Dù config mặc định iOS (`EngineDefaults.h`) khác config inline của test core, output
  vẫn đúng — kiểm bằng chạy thật, không suy diễn.
- **CHƯA làm (thành thật):** chưa kiểm thủ công gõ trên Simulator/thiết bị thật (thêm bàn phím +
  Full Access + gõ trong Notes) và chưa đo RAM jetsam bằng Instruments — 2 việc này tech-spec §Testing
  đã ghi là kiểm thủ công Round 1, chưa tự động hoá được.
- **Made by:** DEV Round 1 (Mốc B), theo walking-skeleton milestone của chủ dự án. Dừng ở đây chờ review.
- **Supersedes:** đóng story #3/#4/#6 trong Story List tech-spec; Round 1 còn lại story #5 (onboarding + App Group).

### 2026-07-11 — Validate + reconcile tech-spec.md với code thật (v0.1 → v0.2)
- **Decision:** Chạy `bmad-tech-spec` (intent Validate) thay vì `bmad-architecture` — vì đội iOS
  là Quick Flow, tech-spec đã thay vai architecture.md; đẻ file `architecture.md` thứ hai chỉ tạo
  drift. Kết quả: tech-spec QUA checklist Quick Flow, vá 3 chỗ lệch giữa doc và code thật:
  1. **Ngôn ngữ container app = Objective-C (chốt).** Doc cũ ghi "Swift hoặc Obj-C, chưa chốt";
     thực tế Mốc A đã scaffold `ios/App/*.m` bằng Obj-C → khoá lại cho khớp.
  2. **Container KHÔNG biên dịch engine.** YAML minh hoạ cũ trong doc liệt kê `core/engine`+
     `core/mood` dưới `MindfulKeyiOS`; `project.yml` thật thì container chỉ có `ios/App`+`shared`
     — chỉ extension mới ôm engine. Sửa YAML doc cho khớp thực tế.
  3. **App Group: tên đã chốt (Q7) nhưng wiring chưa làm.** Doc v0.1 gọi đây là "quyết định mở,
     cần xác nhận" — sai chiều: Q7 (entry ngay dưới) đã chốt tên `group.vn.gnh.mindfulkey`. Việc
     còn lại thuần code: tạo 2 `.entitlements` + `CODE_SIGN_ENTITLEMENTS` (FR-A06), chặn story #5.
- **Rationale:** "Bắt được drift 2 chiều": doc nói thừa (YAML engine dưới container, App Group
  'chưa chốt') và nói thiếu (ngôn ngữ container chưa khoá). Quy chiếu `project.yml` + scaffold thật
  + decision-log Q7 để sửa, không đoán.
- **Made by:** `bmad-tech-spec` (Validate), theo lựa chọn chủ dự án (không tạo architecture.md).
- **Supersedes:** không xoá gì; cập nhật tech-spec.md v0.1 → v0.2.

- **Decision:** Chủ dự án duyệt gói phân tích `analysis/` (00→09 + ROADMAP) và chốt 3 câu nhóm A
  của decision queue (`analysis/09-bmad-reconcile.md` §3):
  - **Q7 — Bundle ID + App Group:** DÙNG bản đề xuất — app `vn.gnh.mindfulkey.ios`, extension
    `vn.gnh.mindfulkey.ios.keyboard`, App Group `group.vn.gnh.mindfulkey`. (Bundle ID đã có sẵn
    trong `platforms/apple/project.yml`; App Group entitlement wiring là việc code FR-A06.)
  - **Q8 — Mockup onboarding:** KHÔNG cần file riêng — dev dựng 2 màn 01/02 theo `EXPERIENCE.md`
    (wireframe chữ + states + a11y đã đủ, nay ở v0.3). Đóng open item của SPEC.
  - **Q10a — Sàn iOS:** GIỮ **16.0** (khớp SDK đã thực nghiệm compile engine).
- **Rationale:** 3 câu này chặn hoàn tất Round 1. Đều theo phương án khuyến nghị, rủi ro thấp, đổi
  sau được (Bundle ID/sàn iOS chỉ là cấu hình). Không cần đổi code ngay để "áp" quyết định.
- **Hệ quả:** Round 1 (FR-A01/A02/A03/A04/A05/A06/A17) hết vướng *quyết định* — còn lại là *code*
  (việc lõi = Mốc B: nối `vKeyHandleEvent` gõ Telex ra dấu). Nhóm B/C (Q1–Q6, chạm nhận diện) vẫn
  mở, chặn R2/R3 — khớp mục "Còn mở" của entry v0.3 ngay dưới.
- **Made by:** chủ dự án (qua AskUserQuestion), ghi bởi agent phân tích.
- **Supersedes:** đóng Q7/Q8/Q10a (nhóm A) trong `analysis/09-bmad-reconcile.md`.

### 2026-07-11 — UX Update v0.3: reconcile brand + chốt bản đồ 6-module/IA + font hybrid
- **Decision:** Sau khi hệ thống hoá mockup (Claude Design) thành sản phẩm hoàn chỉnh, chạy
  `bmad-ux` (Update) kéo `DESIGN.md`/`EXPERIENCE.md` lên **v0.3**, khớp lại với `brand/tokens.json`
  (nguồn brand chính thức) và chốt kiến trúc thông tin:
  1. **Font HYBRID** (chủ dự án chốt qua AskUserQuestion): **Montserrat(heading)+Inter(body) cho
     container app** (RAM thoải mái, đúng nhận diện) · **SF Pro cho keyboard extension** (chật RAM
     ~48–60MB, không bundle font, render dấu Việt chuẩn). Được cả hai.
  2. **moodScale 5 bậc** (`tokens.json`: An #9FB6BC → Cuộn #3F646E) làm thang con sóng chính thức;
     `stone/stoneStrong` lùi về vai "đường phẳng không-xảy-ra". Mức 1 nhạt gần vô hình là cố ý.
  3. **radius.control 12→8pt**, **bóng card → teal `rgba(29,124,145,.08)`** — khớp tokens.json,
     hết drift giữa DESIGN.md và brand.
  4. **Bản đồ 6 module + IA 3 bề mặt** (EXPERIENCE mới): onboarding tuyến-tính-không-tab · container
     có **tab bar 3 mục** (Trang chủ/Mặt hồ/Cài đặt, DESIGN §2.12) · keyboard extension không tab.
     Phủ L1→M1, L2+L3→M5 (cài đặt chi tiết drill-down), L4→M6 (nền tĩnh), L5→cắt/hoà. Cấm nút "+",
     Analytics/Goals/Profile, tài khoản/login.
  5. **Màn "Soi lại cuối ngày" chốt = CÂU HỎI PHẢN CHIẾU là trọng tâm, BỎ biểu đồ/timeline** làm
     nhân vật chính (đó là "thống kê cho vui", phạm hiến chương). Sửa lại đúng tiền lệ macOS.
- **Rationale:** Mockup đã vượt spec → docs bị lệch với cả brand tokens lẫn hình hài thực. Update 1
  pass để 3 thứ (bản vẽ / phối cảnh / luật brand) khớp nhau, có spec chuẩn git-tracked trước khi
  code Mốc B. "Đầy đủ L1–L5" = phủ mọi chức năng bằng số màn tối thiểu, KHÔNG dựng lại 46 màn Laban.
- **Còn mở (Round 2–3, không chặn Mốc B):** map send-risk→biên độ (B1), nội dung nhật ký + App Group
  ownership (B2), soi-lại có notification đẩy không (B3).
- **Made by:** bmad-ux (Update v0.3), gọi bởi agent đội iOS; font do chủ dự án chốt trực tiếp.
- **Supersedes:** none (mở rộng v0.2; reconcile các con số radius/shadow/font trong DESIGN.md).

### 2026-07-10 — iOS thành workspace BMAD tự-đủ (đóng lại câu hỏi treo về log riêng)
- **Decision:** `bmad-output/ios/` nay là một workspace BMAD tự-đủ — có `config.yaml` riêng
  (name "Mindful Keyboard — iOS", track **quick-flow**, `languages: Vietnamese`) trỏ mọi path về
  chính nó: `decision_log: bmad-output/ios/decision-log.md`, `project_context:
  bmad-output/ios/project-context.md`, `stories_folder: bmad-output/ios/stories`. Thêm mới
  `project-context.md` (điền từ SPEC.md). `decision-log.md` cũ giữ nguyên (script không đè).
- **Rationale:** Chủ dự án chốt cho iOS một "tủ hồ sơ" riêng thay vì dùng chung config root
  (root vẫn là track bmad-method cho macOS/Windows, `name` cũ "Windows Port"). iOS mandate hẹp +
  chỉ cần tech-spec → **quick-flow** đúng hơn hẳn bmad-method. Đây chính là câu trả lời cho open
  item ở entry "Ghi chú vận hành: log riêng đội iOS" bên dưới: `config.yaml` iOS giờ trỏ thẳng
  log riêng, không còn mượn `decision_log` của root.
- **Ranh giới cố ý:** Đây là workspace SIBLING với root, KHÔNG thay thế nó. Quyết định xuyên đội
  vẫn ghi ở `../decision-log.md` root theo quy ước `_shared/`. HIẾN CHƯƠNG vẫn là luật tối cao.
- **Made by:** bmad-init (Create, --output bmad-output/ios), gọi bởi chủ dự án.
- **Supersedes:** none (bổ sung, không phá). Đóng open item của entry log-riêng phía dưới.

### 2026-07-10 — UX Update: thêm màn Bàn phím + Cài đặt (đầy đủ) + mục Future Round 2/3 (v0.2)
- **Decision:** Mở rộng DESIGN.md (§2.11 Segmented control + Slider — màu chọn = teal, KHÔNG
  xanh-lá hệ thống) + EXPERIENCE.md 2 màn đặc tả đầy đủ (Bàn phím Mindful Key với states
  Shift/Caps/lớp số/secure field; Cài đặt bàn phím với preview sống + slider + segmented) và
  1 mục "Future Screens (Round 2/3)".
- **Ranh giới cố ý:** chia làm 2 nhóm. Nhóm A (bàn phím, cài đặt) = thuần công cụ/Round 1,
  đặc tả ĐẦY ĐỦ. Nhóm B (sóng cảm xúc B1, nhật ký B2, soi lại B3) = chạm nhận diện + dữ liệu
  cảm xúc → CHỈ chốt phần bám hiến chương + tiền lệ macOS đã duyệt; mọi quyết định sản phẩm
  còn mở đánh dấu **❓** để chủ dự án chốt, KHÔNG tự bịa hành vi. Đúng hiến chương "chạm nhận
  diện mà mơ hồ → hỏi chủ dự án".
- **Contrast component mới đã verify thật:** segmented đoạn chọn (pill trắng + tealStrong
  #155A66 = 7.82:1), đoạn không chọn (muted #666666/tealLight = 5.04:1), slider track teal/
  divider = 3.90:1 (graphic ≥3). Ghi vào DESIGN §3.
- **Quyết định mở nổi bật cần chủ dự án (tóm trong EXPERIENCE Future):** map send-risk→biên
  độ sóng + có/không câu quan sát (B1); nhật ký iOS hiện gì + nút xoá + App Group ownership
  (B2); soi-lại là màn hay notification (B3).
- **Made by:** bmad-ux (Update), gọi bởi agent đội iOS.
- **Supersedes:** none (mở rộng v0.1, không phá phần cũ).

### 2026-07-10 — UX design: DESIGN.md + EXPERIENCE.md, phát hiện + vá 2 lỗi contrast trong mockup
- **Decision:** Tạo `bmad-output/ios/DESIGN.md` (hệ thống design bền cho cả app iOS) +
  `EXPERIENCE.md` (journey Round 1 + phác Round 2). Chạy `bmad-ux/scripts/contrast-check.py`
  kiểm THẬT mọi cặp màu brand trước khi chốt token — số ghi trong DESIGN §3 là output thật.
- **2 lỗi accessibility phát hiện khi verify (mockup HTML tao dựng trước đó dính cả 2):**
  (1) teal `#1D7C91` trên tealLight `#E8F2F4` = 4.24:1 → TRƯỢT AA normal. Vá: badge số bước
  dùng `tealStrong #155A66` (6.86:1). (2) stone `#8A9BA0` = 2.72:1 → TRƯỢT cả ngưỡng graphic
  3:1 cho đường phẳng "không bao giờ". Vá: thêm `stoneStrong #5E6E73` (5.00:1) cho graphic
  mang nghĩa; giữ `stone` gốc CHỈ cho con sóng trang trí (Round 2). Cả 2 token phái sinh
  KHÔNG đặt vào BrandPalette.h (đó là nguồn màu gốc), chỉ khai trong DESIGN.md.
- **Nguyên tắc design mới nâng thành luật:** "biên độ mang nghĩa" (amplitude-as-meaning,
  DESIGN §2.10) — phân biệt trạng thái đối lập bằng SÓNG `~` vs ĐƯỜNG PHẲNG, không bao giờ
  bằng ✓xanh/✗đỏ. Đúng hiến chương §2.3 tuyệt đối + không phụ thuộc màu (mù màu vẫn đọc) +
  nghĩa luôn kèm nhãn chữ. Đã áp ở màn Full Access.
- **Phạm vi cố ý:** DESIGN = toàn app (bền mọi round); EXPERIENCE = bám Round 1 (2 màn
  onboarding + gõ Telex + home tối thiểu), Round 2+ chỉ phác. Quick Flow → giữ gọn, không phình.
- **Ranh giới hiến chương ghi rõ trong EXPERIENCE:** KHÔNG journey "chặn Enter/gác cổng" trên
  iOS (mandate 2026-07-10). KHÔNG semantic đỏ-xanh. Lỗi hệ thống ≠ cảm xúc → không tô đỏ.
- **4 câu hỏi mở để chủ dự án chốt** (cuối EXPERIENCE): giọng copy, giữ/bỏ nút "Để sau",
  glyph sóng chính thức, wordmark/logo.
- **Made by:** bmad-ux (Create), gọi bởi agent đóng vai kỹ sư đội iOS.
- **Supersedes:** none (mockup HTML là bản thử ngoài BMAD; DESIGN.md nay là nguồn chuẩn,
  mockup cần sửa 2 màu theo token đã vá nếu còn dùng làm tham chiếu).

### 2026-07-10 — tech-spec created, đã verify bằng thực nghiệm compile thật
- **Decision:** Tạo `bmad-output/ios/tech-spec.md` trả lời 6 mục kỹ thuật bắt buộc (XcodeGen
  target, cầu nối core, trần RAM, container↔extension detection, Nhịp 0 extract, tests/ios).
  Trước khi viết, đã đọc trực tiếp `platforms/apple/project.yml`, `core/engine/`,
  `core/mood/`, `platforms/apple/macos/*` và CHẠY THỰC NGHIỆM: compile 5 file `core/engine/*.cpp`
  cho target `arm64-apple-ios16.0-simulator` (clang++ trực tiếp, không qua Xcode project) —
  link thành công, binary Mach-O 198KB, KHÔNG sửa dòng nào trong `core/`.
- **Rationale:** Chủ dự án yêu cầu tường minh "không viết chay" — tech-spec phải dựa trên bằng
  chứng đọc được/chạy được trong repo, không suy diễn. Thực nghiệm compile trực tiếp trả lời
  được phần rủi ro kỹ thuật cốt lõi của Problem statement trong SPEC.md (core/engine build được
  trong môi trường iOS hay không) bằng dữ liệu thật thay vì lý thuyết.
- **Phát hiện quan trọng nhất:** Nhịp 0 hoá ra rút được RẤT ÍT nguyên xi từ `platforms/apple/macos/`
  — chỉ 3 thứ (bảng char→keycode, khối default 20 biến config, giá trị hex màu). Toàn bộ
  `.m`/`.mm` khác đều gắn chặt AppKit (`NSColor`) hoặc Carbon/CGEventTap, không tồn tại trên
  iOS. Phần "gửi ký tự" của `OpenKey.mm` (dùng CGEventTap) phải viết lại hoàn toàn cho
  `UITextDocumentProxy` — đây là khác biệt kiến trúc thật, không phải chi tiết vặt.
- **Made by:** bmad-tech-spec (Create), gọi bởi agent đóng vai kỹ sư đội iOS.
- **Supersedes:** none

### 2026-07-10 — SPEC created (Round 1: walking skeleton)
- **Decision:** Tạo `bmad-output/ios/SPEC.md` — kernel 5 field cho Round 1 của đội iOS, track
  Quick Flow. Scope: keyboard extension iOS build + gõ Telex qua `core/engine` nguyên vẹn,
  onboarding kích hoạt + Full Access, thêm target iOS vào `platforms/apple/project.yml`, và
  Nhịp 0 (rút code dùng-chung-được ra `platforms/apple/shared/`).
- **Source:** Kernel do chủ dự án cung cấp trực tiếp (vai trưởng nhóm iOS), đối chiếu
  `docs/AGENT-BRIEF.md` + `/Users/now/Projects/mindful-keyboard/docs/MOBILE-UX-ANALYSIS.md`.
- **Key scope decision:** Non-Goal — KHÔNG làm gác cổng/nhịp thở (kể cả bản "nhắc" theo Phương
  án A) ở Round 1, dời sang Round 2. Lý do: `MOBILE-UX-ANALYSIS.md` §3 kết luận Feature #1
  không port thẳng được lên iOS (sandbox không thấy nút Gửi/host app) — cần thiết kế lại,
  ngoài phạm vi walking skeleton chỉ chứng minh engine chạy được trong extension.
- **Made by:** bmad-spec (Create), gọi bởi agent đóng vai kỹ sư đội iOS.
- **Supersedes:** none

### 2026-07-10 — Ghi chú vận hành: log riêng đội iOS thay vì log chung root
- **Decision:** Đội iOS dùng `bmad-output/ios/decision-log.md` riêng cho quyết định nội bộ
  Round 1, thay vì ghi vào `bmad-output/decision-log.md` ở root như hành vi mặc định của skill
  `bmad-spec`.
- **Rationale:** Quyết định phạm vi kernel Round 1 là việc NỘI BỘ đội iOS, không phải quyết
  định xuyên suốt nhiều đội (đó mới là việc của log root, theo quy ước đã chốt khi tách
  `bmad-output/` thành `_shared/`/`macos/`/`ios/`). `bmad-output/config.yaml` vẫn trỏ
  `decision_log: bmad-output/decision-log.md` ở root — CHƯA sửa field đó, vì đó là quyết định
  ảnh hưởng chung (chủ dự án cần xác nhận trước khi đổi single-source-of-truth path cho tool
  BMAD). **Cần chủ dự án xác nhận** đây có đúng ý hay muốn đội iOS vẫn ghi vào log root.
- **Made by:** agent đóng vai kỹ sư đội iOS (quyết định vận hành, ngoài phạm vi skill bmad-spec).
- **Supersedes:** none
