# Thực thi Typing Cadence Bell — issue #4 → #18

- **Slug:** typing-cadence-bell-execution
- **Status:** in-progress
- **Created:** 2026-08-01  ·  **Updated:** 2026-08-01
- **Owner:** @phatnguyen-neurond (chủ dự án) · Claude (thực thi)

## Goal

Làm tuần tự issue #4 → #18 của đợt chuyển `Sense → Pause → Remind → Reflect`
thành `Measure → Bell → Reflect`. Mỗi issue: một nhánh → một PR → một agent
review → pass thì merge + đóng issue. Xong khi cả 15 issue đóng, `main` xanh CI,
và bảng tiến độ ở `spec/typing-cadence-bell/README.md` §4 toàn `✅`.

Kế hoạch gốc và luật cập nhật nằm ở [`spec/typing-cadence-bell/README.md`](../../spec/typing-cadence-bell/README.md).
File này chỉ theo dõi **việc thực thi**, không thay thế nơi làm việc đó.

## Requirements & Constraints

**Functional**
- Mỗi issue đóng lại phải kèm **trong cùng PR**: ô trạng thái README §4 → `✅`,
  một mục vào `spec/typing-cadence-bell/PROGRESS.md`, quyết định mới chuyển
  xuống §5 "Đã chốt", câu hỏi mới thêm vào bảng §5, chỗ phải đoán ghi vào
  `docs/tasks/FRICTION-LOG.md`. (README §7)
- Thứ tự tôn trọng cột "Chặn bởi" ở README §4.

**Constraints**
- **Hiến chương `docs/01-intent.md` là luật tối cao.** Không đèn đỏ/xanh cảm
  xúc · không emoji chấm điểm · không gamification · không copy khiển trách.
  Tên mức ngưỡng mô tả **nhịp tay**, cấm chữ quy về trạng thái tâm.
- GPL v3, giữ credit Mai Vũ Tuyên.
- Surgical changes (`.claude/rules/03-surgical-changes.md`): mỗi dòng sửa phải
  truy được về issue đang làm.
- **Máy dev là Windows, KHÔNG có toolchain** — `g++`/`clang++`/`cl`/`make`/
  `cmake` đều thiếu. Chỉ có `py -3`. Hệ quả: **không kiểm chứng build/test
  local được**, CI là cổng thật. Xem Decision 2026-08-01.

**Non-goals**
- Không refactor code ngoài phạm vi issue đang làm.
- Không tự quyết câu hỏi ở README §5 — hỏi chủ dự án (README §5 ghi rõ).

## Cổng chất lượng thực tế (đã hiệu chỉnh theo máy Windows)

| Cổng | README §7 đòi | Chạy được ở đâu |
|---|---|---|
| `make test` | xanh | ❌ local · ⚠️ CI chỉ chạy `tests/core/build.sh` + `test_engine`, **không** chạy `test-macos`/`test-ios` |
| `make build` | sạch | ❌ local · ✅ CI `macos.yml` (xcodebuild) |
| Windows build | — | ❌ local · ✅ CI `windows.yml` (MSVC v143, Debug + Release) |
| `make brand-lint` | 0 vi phạm | ✅ local qua `PYTHONIOENCODING=utf-8 py -3 scripts/brand_lint.py` · ✅ CI `brand-lint.yml` |

**Luật kiểm chứng:** không bao giờ ghi "đã test" cho thứ chỉ chạy trên CI. PR
nào đụng code phải đợi CI xanh trước khi review agent chạy.

## Milestones

- [x] **M0** — Chốt câu hỏi chặn + dựng doc — *4 câu đã chốt 2026-08-01, doc này tồn tại*
- [ ] **M1** — Phase 0 docs: #4 ✅, #5 — *2 PR merged, docs/ + .claude/ hết dấu vết send-risk*
- [ ] **M2** — Phase 1 core C++: #6, #7, #8 — *TypingCadence + BellPolicy + sóng đổi nguồn, CI xanh*
- [ ] **M3** — Phase 2 macOS: #9, #10, #11 — *macOS reo chuông theo nhịp, chọn ngưỡng, ghi + soi lại*
- [ ] **M4** — Phase 3 gỡ đồ cũ: #12, #13, #14 — *`SendRiskAnalyzer`/`BreathingPause`/`models/` biến mất khỏi repo*
- [ ] **M5** — Phase 4 Windows: #15, #16 — *CI windows.yml xanh cả Debug + Release*
- [ ] **M6** — Phase 5 iOS: #17, #18 — *extension đo nhịp + tín hiệu chuông, ngưỡng qua App Group*

> ⚠️ **Thứ tự thật khác thứ tự số.** #13 chặn bởi #8 #9 **#15 #17** — tức phải
> đợi cả Windows (#15) và iOS (#17) chuyển xong mới gỡ được lớp sentiment.
> Nên M4 phải chạy **sau** M5 và M6 ở phần #13. Thứ tự thực thi đúng:
> `#4 #5 → #6 #7 #8 → #9 #10 #11 → #12 → #15 #16 → #17 #18 → #13 #14`.

## Decision Log

<!-- newest first; mỗi mục: quyết định + vì sao + phương án bị loại -->

- **2026-08-01 — Thứ tự thực thi đảo so với thứ tự số issue:**
  `#4 #5 → #6 #7 #8 → #9 #10 #11 → #12 → #15 #16 → #17 #18 → #13 #14`.
  Vì #13 (gỡ lớp đọc cảm xúc) chặn bởi **#15 và #17** theo README §4 — gỡ trước
  khi Windows/iOS chuyển xong là vỡ build cả hai vỏ, đúng cái bẫy README §6 đã
  cảnh báo ("gỡ sớm là vỡ build"). Rejected: chạy đúng 4→18 tuần tự.

- **2026-08-01 — Working tree bẩn sẵn gộp vào PR của #5** *(chốt bởi chủ dự án)*:
  4 file `.claude/agents/*.md` + 7 file `.claude/rules-archive/*` bị xoá và
  `CLAUDE.md` + `.claude/settings.json` sửa — tất cả chưa commit và **đúng phạm
  vi #5** (đồng bộ harness `.claude/`). Rejected: revert hết làm lại; commit
  riêng lên main trước.

- **2026-08-01 — Q5: KHÔNG đếm nhịp trong ô mật khẩu** *(chốt bởi chủ dự án)*:
  giữ nguyên hành vi Windows đang có (`MoodWatch.cpp:47` đã loại ô mật khẩu khỏi
  `MoodBuffer`) và áp cho cả 3 vỏ. Tránh chuông reo giữa lúc gõ mật khẩu và
  không sinh dấu vết thời gian gõ mật khẩu. Rejected: có đếm (lý lẽ "nhịp không
  phải nội dung nên không lộ gì").

- **2026-08-01 — Skill `mood-sentiment-layer` đổi tên thành `typing-cadence-layer`**
  *(chốt bởi chủ dự án, đóng yêu cầu "chốt trong issue này" của #5)*: giữ chỗ
  đứng của lớp này trong bảng 4 chuyên gia, viết lại toàn bộ mandate theo đo
  nhịp. Rejected: gỡ hẳn skill (khiến `mood-layer-agent` mất skill chuyên biệt,
  phải sửa thêm `mindful-keyboard-harness/SKILL.md`).

- **2026-08-01 — Q3: nhịp phím lấy từ HOOK BÀN PHÍM, từng phím một**
  *(chốt bởi chủ dự án)*. API là `TypingCadence_OnKeystroke(int64_t tsMs)` —
  **không tham số chuỗi ở bất kỳ đâu**. Vì sao: README §1 viết "Chỉ đếm nhịp
  phím, không đọc ký tự", và README §2 nói lời hứa riêng tư phải "kiểm chứng
  được bằng cách nhìn vào code". Nếu nuôi từ `vOnWordCommitted(const wstring&
  word)` thì lớp nhịp vẫn **nhận** chuỗi từ dù chỉ dùng `.length()` — người
  review đọc code vẫn thấy lớp mood cầm text, lời hứa yếu đi. Phụ: hook cho tín
  hiệu mượt (gõ giữa từ dài vẫn có nhịp), và Telex `aa`→`â` tính 2 nhịp đúng
  nghĩa "nhịp tay". Rejected: (B) tái dùng `vOnWordCommitted` — ít sửa hơn vì
  3 vỏ đã nối sẵn, nhưng đánh đổi lời hứa riêng tư.

- **2026-08-01 — CI là cổng kiểm chứng, không phải máy local:** máy dev Windows
  thiếu toàn bộ trình biên dịch (`g++`/`clang++`/`cl`/`make`/`cmake`). PR đụng
  code phải đợi `macos.yml` + `windows.yml` xanh trước khi review. Không ghi "đã
  test" cho thứ chỉ CI chạy. Rejected: cài toolchain (ngoài phạm vi, và không
  giải được phần Xcode/iOS).

## Open Questions

- [ ] **Q4** (chặn #8) — Quy CPM về biên độ sóng `[0,1]` theo công thức nào, đặt
  ở đâu để 3 vỏ không trôi lệch? → sẽ đề xuất phương án khi tới #8, hỏi chốt
  trước khi code.
- [ ] **Q6** (chặn #11) — Nhật ký cũ trên máy người dùng: xoá sạch hay giữ đọc
  song song? README §6 đã **khuyến nghị xoá** ("điểm cũ đo bằng thước khác, vẽ
  chung một biểu đồ là nói dối người dùng") — sẽ xác nhận với chủ dự án ở #11.
- [ ] **Q7** (chặn #11) — Giữ hay bỏ check-in tự thuật "Mặt hồ đang thế nào?"
  → hỏi chốt ở #11.
- [x] ~~**Q8** (chặn #17) — Bàn phím iOS có phát được tiếng chuông trong app
  extension không?~~ → **ĐÃ TRẢ LỜI 2026-08-01**: có, qua
  `AudioServicesPlaySystemSound`, cần Full Access (đã bật sẵn). Xem Research
  Findings. Còn lại là việc **nghe-verify tay trên iPhone thật ở #17**, không
  chặn thiết kế nữa.
- [ ] **Q9** (phát sinh ở #4) — `docs/diagrams/` **không có** sơ đồ vòng lặp lõi
  như issue #4 giả định. Có vẽ mới `Measure → Bell → Reflect` không? Ghi chú
  "gác cổng" cũ trong `workflow-macos-team.drawio` để nguyên hay sửa? → hỏi chủ
  dự án. Ràng buộc: máy dev không có drawio CLI nên sửa `.drawio` sẽ làm
  `.svg`/`.png` trôi lệch.

## Research Findings

### 2026-08-01 — Q8: iOS keyboard extension có phát được tiếng chuông không?

> Nguồn: `task-researcher`, 2026-08-01. Confidence: **high** (đường audio) / **medium** (đường haptic).

**Đáp án ngắn:** **Có** — `AudioServicesPlaySystemSound` phát được trong extension
`com.apple.keyboard-service`, nhưng **bắt buộc Full Access**. Full Access trong repo này **đã bật
sẵn** vì lý do khác (macro + App Group), nên chuông âm thanh **không tạo thêm chi phí riêng tư mới**.

**Repo đã tự trả lời bằng code sản xuất:** `platforms/apple/ios/KeyboardExtension/NudgeCoordinatorIOS.mm:29-42`
đã gọi cả `UIImpactFeedbackGenerator` lẫn `AudioServicesPlaySystemSound(1104)` trong đúng loại
extension này; `Info.plist:36` có `RequestsOpenAccess = true`.

**Khuyến nghị:** tái dùng cặp **haptic (`UIImpactFeedbackGenerator` Medium) + `AudioServicesPlaySystemSound`**
theo đúng pattern `mk_triggerRingEffect()` đã có — chỉ **đổi nơi gọi** từ
`NudgeCoordinatorIOS_RegisterSentenceRisk` sang `BellPolicy`/`TypingCadence` mới, không viết lại.

**Tránh `AVAudioSession`/`AVAudioPlayer`:** có báo cáo `setActive` ném lỗi `561015905` trong
extension **kể cả khi đã bật Full Access** — [Apple Developer Forums 709107](https://developer.apple.com/forums/thread/709107).
`AudioServicesPlaySystemSound` không đụng `AVAudioSession` nên an toàn hơn.

**Nguồn Apple:** [App Extension Programming Guide — Custom Keyboard](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)
ghi rõ: `RequestsOpenAccess = NO` (mặc định) thì keyboard **không** được phát âm thanh gì, kể cả
`playInputClick`; chỉ `YES` mới có *"Ability to play audio"*.

**Caveat phải xử ở #17:**
- `SystemSoundID` **không** phải API công khai có catalog chính thức. Giá trị `1104` hiện trong code
  đang gắn nhãn `[Inference]`, **chưa nghe-verify trên máy thật**. Phải nghe tay trên iPhone thật ở
  #17 (Simulator không dựng được custom keyboard — `FRICTION-LOG.md` dòng 2026-07-13) và chọn tiếng
  **trung tính, ngắn**, không giống âm báo lỗi hệ thống.
- Giả định "haptic cũng cần Full Access" **chưa có trích dẫn Apple chính thức** (chỉ bằng chứng cộng
  đồng + code repo đang chạy song song với Full Access bật). Ở #17 thử tắt Full Access xem haptic
  còn kêu không, ghi kết quả vào `FRICTION-LOG.md`.
- Dòng "Full Access" ở `FRICTION-LOG.md` (2026-07-13) vẫn **mở**, chưa được chủ dự án đóng chính
  thức. #17 đi trên giả định Full Access tiếp tục tồn tại vì #18/macro. Nếu chủ dự án veto Full
  Access thì **cả audio lẫn haptic sập theo**, chỉ còn phương án tín hiệu thị giác trên thanh bàn
  phím (không cần quyền gì).

**Đường lui không cần quyền:** một xung ngắn trung tính trên chính view `~` sẵn có. Chạy 100% trong
sandbox mặc định. Nhưng đây là **quyết định sản phẩm** (đánh đổi UX, dễ bị bỏ lỡ), không phải giới
hạn kỹ thuật — để chủ dự án chốt ở #17, không tự chọn. Cẩn thận không biến nó thành "đèn đỏ/xanh"
(hiến chương cấm): chỉ một nhịp trung tính, không đổi màu theo mức.

## Completed Work

- 2026-08-01 — Khảo sát repo: xác nhận thiếu toolchain, xác nhận CI là cổng
  thật, đọc issue #4/#5, định vị `vOnWordCommitted` + các điểm nuôi `MoodBuffer`
  trên 3 vỏ — `platforms/apple/macos/MoodWatchMac.mm:269`,
  `platforms/apple/ios/KeyboardExtension/MoodBridge.mm:71`,
  `platforms/windows/win32/MindfulKey/MindfulKey/MoodWatch.cpp:489`.
- 2026-08-01 — Chốt 4 câu chặn với chủ dự án (Q3, Q5, số phận skill, tree bẩn) —
  xem Decision Log.
- 2026-08-01 — Dựng doc này — `docs/tasks/typing-cadence-bell-execution.md`.
- 2026-08-01 — **#4 xong** (nhánh `docs/sync-layers-measure-bell-reflect`):
  `04-contracts.md` viết lại thành 8 hợp đồng (HĐ-1 cấm lớp nhịp nhận chuỗi ·
  HĐ-2 chuông không chặn · HĐ-3 hợp đồng nhịp gõ · HĐ-4 ô mật khẩu);
  `07-glossary.md` thay 4 thuật ngữ chết bằng 5 thuật ngữ mới + bảng "đã nghỉ
  hưu"; `02-features.md` viết theo mô hình mới kèm nhãn trạng thái thật;
  `06-operations.md` + `docs/README.md` mỗi file một dòng. brand-lint 0 vi phạm
  cứng. Phát sinh **Q9** (sơ đồ không tồn tại) — treo, chờ chủ dự án.
- 2026-08-01 — Q8 có đáp án qua `task-researcher` — xem Research Findings.

## Remaining Action Items

- [x] #4 — Đồng bộ `docs/02,04,06,07` + `docs/README.md` — *xong; phần
  `docs/diagrams/` cố ý để trống, chờ Q9*
- [ ] **Chờ chủ dự án chốt Q9** (sơ đồ vòng lặp lõi) — không chặn #5 trở đi
- [ ] #5 — Đồng bộ `docs/tasks/` + harness `.claude/` (gộp cả tree bẩn đang ở
  `git stash@{0}`, 13 file)
- [ ] #6 → #18 theo thứ tự đã chốt ở Decision Log
