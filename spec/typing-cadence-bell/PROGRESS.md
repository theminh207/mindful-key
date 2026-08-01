# Nhật ký tiến độ — Typing Cadence Bell

> Mới nhất ở trên cùng. Mỗi issue đóng lại = một mục ở đây, ghi **cùng trong PR đó**, đừng để dồn.
> Kế hoạch và bảng trạng thái ở [README.md](README.md).

**Mẫu một mục:**

```
## YYYY-MM-DD — #<issue> <tiêu đề ngắn>

**Làm gì:** 1-2 câu, nói việc thật đã thay đổi, không chép lại mô tả issue.
**Chốt được:** quyết định nào đã ngã ngũ + lý do (chuyển luôn xuống mục "Đã chốt" ở README §5).
**Phải đoán:** chỗ nào tài liệu không nói rõ mà vẫn phải chọn (ghi thêm vào docs/tasks/FRICTION-LOG.md).
**Kiểm chứng:** make test / make build / brand-lint / thử tay ra sao.
**Còn hở:** thứ cố ý để lại cho issue sau, kèm số issue.
```

---

## 2026-08-01 — #4 Đồng bộ tầng 02/04/06/07 theo vòng lặp Measure → Bell → Reflect

**Làm gì:** Viết lại `04-contracts.md` từ 6 lên 8 hợp đồng — **gỡ 1** (HĐ nhịp thở, theo gác cổng),
**thêm 3** (**HĐ-1 "lớp nhịp gõ không được nhận nội dung"** — cấm mọi API `core/mood` có tham số
chuỗi, kèm lệnh `grep` soi · **HĐ-2 chuông ngân-thì-được-chặn-thì-không** · **HĐ-4 không đếm trong ô
mật khẩu**), và **giữ HĐ-3 nhưng đổi đơn vị đo** từ `câu → risk [0,1]` sang `nhịp phím → CPM`
(cửa sổ 30s · ngưỡng mặc định 400). Bốn hợp đồng còn lại dịch số, nội dung gần như nguyên. Viết lại
`07-glossary.md`: bỏ `send-risk`/`gác cổng`/`nhịp thở`/`allow-list`, thêm `nhịp gõ`/`CPM`/`cửa sổ
trượt`/`ngưỡng chuông`/`cooldown`, và thêm bảng **"Thuật ngữ đã nghỉ hưu"** để người đọc code cũ tra
ra ngay. Viết lại `02-features.md` theo mô hình mới **kèm nhãn trạng thái thật**. Sửa một dòng ở
`06-operations.md` và một dòng ở `docs/README.md`.

**Chốt được:**
- **Q3 — nhịp phím lấy từng phím ở hook bàn phím**, không tái dùng `vOnWordCommitted`. Lý do đầy đủ
  ở README §5 "Đã chốt". Đã thành hợp đồng HĐ-1.
- **Q5 — không đếm nhịp trong ô mật khẩu**, fail-closed. Đã thành hợp đồng HĐ-4. Kéo theo một việc
  cho #9: **macOS hiện chưa có cổng kiểm này**, Windows và iOS thì có rồi.
- **Số phận skill `mood-sentiment-layer`** (câu hỏi #5 tự đặt): đổi tên thành `typing-cadence-layer`.
  Chốt ở đây để #5 khỏi phải hỏi lại.

**Phải đoán:** hai chỗ, đã ghi `docs/tasks/FRICTION-LOG.md`.
1. **Issue #4 giao "vẽ lại sơ đồ vòng lặp lõi 4 bước thành 3 bước" — sơ đồ đó không tồn tại.** Cả
   hai file trong `docs/diagrams/` là sơ đồ *quy trình làm việc*, không phải *vòng lặp sản phẩm*;
   grep `Sense|Pause|Remind|Reflect` ra 0 kết quả. **Không bịa ra sơ đồ chưa từng có.** Thành **Q9**
   ở README §5 chờ chủ dự án chốt. Ràng buộc kèm theo: máy dev Windows không có drawio CLI, sửa
   `.drawio` mà không regenerate được `.svg`/`.png` sẽ tạo trôi lệch nguồn ↔ bản xuất.
2. **Tầng 02 mô tả hiện trạng, mà hiện trạng đang giữa đợt chuyển.** Issue bảo viết theo mô hình
   mới; luật của tầng 02 lại là "code là đúng". Viết mục B theo mô hình mới **kèm nhãn "chưa khởi
   công trên mọi vỏ"** + banner đầu file, bảng nền tảng ghi cả thứ đang chạy lẫn thứ sắp có. Giữ
   được cả hai luật.

**Kiểm chứng:** `brand_lint.py` — 0 vi phạm cứng (chi tiết ở phần cuối PR). PR thuần tài liệu, không
đụng code, nên `macos.yml`/`windows.yml` không có gì để build khác đi. **Lưu ý máy dev là Windows và
KHÔNG có toolchain** (`g++`/`clang++`/`cl`/`make` đều thiếu) — `make test`/`make build` không chạy
local được, CI là cổng thật. Điều này áp cho toàn bộ đợt #4→#18, ghi ở
`docs/tasks/typing-cadence-bell-execution.md`.

**Vòng review bắt được 4 lỗi chặn — đã sửa hết:**
1. **Đánh số lại HĐ làm mồ côi 7 tham chiếu.** Đây là orphan do chính PR tạo ra, thuộc luật
   `.claude/rules/03-surgical-changes.md`. Nặng nhất: `ADR-0005:5` trỏ `HĐ-1` vốn là *"Nhịp thở"* —
   nay HĐ-1 là hợp đồng **cấm** đúng thứ ADR đó mô tả. Xử: thêm **bảng đánh số lại** ở đầu
   `04-contracts.md` (số cũ → số mới) để link cũ tra ra được, **không sửa thân ADR** vì tầng 03 là
   *"chỉ thêm, không sửa"*. Riêng `05-conventions.md:39` là tầng 05 (sửa được) → `HĐ-5` → `HĐ-6`.
2. **5 anchor link chết trong `07-glossary.md`.** Tui viết `[CPM](#cpm)` v.v. nhưng các thuật ngữ là
   **chữ đậm trong đoạn văn, không phải heading**, nên GitHub không sinh anchor. Xử: bỏ link, giữ
   chữ đậm.
3. **Bảng nền tảng `02-features.md` khai thiếu**: bỏ mất dòng chuông đang tồn tại thật hôm nay, đọc
   ra thành "sản phẩm chưa có chuông nào" trong khi mục C/D vẫn mô tả nhịp chuông. Xử: thêm lại dòng
   `~~Chuông theo nhịp lấy mẫu / chuỗi câu căng~~ | có (đổi nguồn ở #9)` + đoạn giải thích rằng
   #9/#15/#17 là **đổi nguồn nuôi chuông**, không phải dựng tiếng chuông từ đầu.
4. **Doc theo dõi nhân đôi nguồn sự thật.** File `docs/tasks/typing-cadence-bell-execution.md` chép
   lại Q4/Q6/Q7/Q8/Q9, decision log và bảng milestone vốn đã sống ở README §4/§5 — đúng cái bẫy §6
   cảnh báo và trái `05-conventions.md` §3. Xử: cắt còn **hai thứ không có chỗ nào khác chứa** (thứ
   tự thi công đã hiệu chỉnh + kho research), thêm banner "file này KHÔNG phải nguồn sự thật". Phần
   cổng chất lượng Windows-không-toolchain chuyển về đúng chỗ: **README §7**.

Sửa thêm 3 chỗ nhỏ reviewer chỉ ra: `07-glossary.md` đếm nhầm "Ba khái niệm" (thật ra 5, sau khi bổ
sung **Độ nhạy** vào bảng đã-nghỉ-hưu); `06-operations.md` viết "hai bộ sau" trong ô chỉ liệt kê 2
thứ (thật ra `make test-core` chạy **3** bộ) → liệt kê rõ từng bộ; dòng Q9 ở FRICTION-LOG viết "dấu
vết duy nhất" nhưng `workflow-macos-team.drawio` có **hai** node — node dòng 115 khai hẳn *"Gác cổng
… Trái tim sản phẩm"*, nặng hơn ghi chú dòng 134.

**Còn hở:**
- **Q9** (sơ đồ) treo, chờ chủ dự án — checkbox `docs/diagrams/` của #4 **cố ý để trống**.
- Năm chỗ trong `docs/03-decisions/` còn trỏ số HĐ cũ (`ADR-0003` · `ADR-0004` · `ADR-0005` ·
  `ADR-0011` ×2 = **bốn ADR**, tất cả đều đã *Bị thay thế*), **cố ý không sửa** vì tầng 03 chỉ thêm
  không sửa — bảng đánh số lại ở `04-contracts.md` gánh việc tra cứu. Riêng `ADR-0002` là ADR duy
  nhất còn *Đã chốt* nên **đã sửa số trực tiếp**: đó là dòng metadata "Liên quan", không phải thân
  quyết định, và #3 đã tạo tiền lệ sửa metadata tầng 03.
- HĐ-7 (copy chuỗi trước khi rời luồng) giữ nguyên dù phạm vi đang thu hẹp — chưa gỡ luật khi code
  chưa gỡ, đợi #13.

---

## 2026-07-27 — #3 ADR: đo nhịp gõ thay cho đọc cảm xúc

**Làm gì:** Viết `ADR-0013` (đo nhịp gõ thay đọc cảm xúc) và `ADR-0014` (mandate iOS hẹp, lý lẽ
mới). Đánh dấu **năm** ADR là *Bị thay thế bởi 0013*: 0003, 0004, 0005, 0006 và **0011**. Gỡ hẳn
`ADR-0009`. Cập nhật bảng mục lục `docs/03-decisions/README.md`, gỡ dòng ghi chú tạm ở
`docs/01-intent.md` §6, trỏ lại hai liên kết ADR-0009 đã chết ở `01-intent.md` và `02-features.md`.

**Chốt được:**
- **Q1 — ngưỡng.** Bốn mức, mặc định **Rất nhanh = 400 CPM**: `Nhanh 300` · `Rất nhanh 400` ·
  `Cực nhanh 500` · `Tắt chuông`. Tên mức mô tả nhịp tay, không mô tả tâm người gõ; hiển thị luôn
  kèm con số CPM.
- **Q2 — cửa sổ trượt 30 giây.** Ngắn hơn thì một tràng gõ dồn rồi nghỉ cũng vượt ngưỡng; dài hơn
  thì chuông tới sau khi nhịp đã lắng.
- **ADR-0009 gỡ hẳn, không đánh dấu bị thay thế.** Thân nó lập luận cho gác cổng gửi tin — tính năng
  đã bị xoá khỏi sản phẩm, để lại thì người đọc sau phải đọc hết mới biết nó đã chết. Kết luận
  (mandate iOS hẹp) viết lại ở `ADR-0014`. Ngoại lệ này có mục giải thích + lệnh `git show` để đọc
  lại bản gốc ngay trong index; **không phải tiền lệ**.
- **ADR-0011 vào danh sách bị thay thế**, dù issue #3 không liệt kê. Nó chốt schema "bất biến" có
  cột `send_risk` — cột chết theo mô hình mới. Để nguyên thì #16 sẽ trích một ADR đã sai làm căn cứ.

**Phải đoán:** không. Bốn điểm mơ hồ (Q1, Q2, cách xử lý ADR-0009, phạm vi ADR-0011) đã hỏi chủ dự
án và được chốt trước khi viết.

**Kiểm chứng:** brand-lint — `✅ 223 file, 0 vi phạm cứng, 9 cảnh báo` (cả 9 là hardcode màu có sẵn
trong `BrandColors.h`, PR này không đụng tới). Hai vướng trên máy Windows, **không phải lỗi do PR
này**: `make` không có trong shell, và `scripts/brand-lint.sh` gọi `python3` (không tồn tại trên
Windows). Chạy được bằng `PYTHONIOENCODING=utf-8 py -3 scripts/brand_lint.py` — thiếu biến môi
trường thì script chết vì console cp1252 không in nổi ký tự `⚠️`.

Lưu ý cho lần sau: `scripts/brand_lint.py` chỉ quét
`platforms/`, `site/`, `brand/` với đuôi file UI, **không quét `.md`** — nên với PR thuần tài liệu,
cổng này xanh không có nghĩa là câu chữ đã được máy kiểm. Tên bốn mức ở trên là **đọc tay** theo
HIẾN CHƯƠNG §2.2/2.3.

**Còn hở:**
- `docs/02-features.md` còn câu "iOS không có gác cổng là quyết định" — viết theo mô hình cũ. PR này
  chỉ trỏ lại liên kết cho khỏi chết, phần câu chữ thuộc **#4**.
- Schema kho nhật ký sau khi mất `send_risk` chốt ở **#11**.
- Công thức quy CPM → biên độ sóng vẫn mở (Q4, ở #8).

---

## 2026-07-26 — Khởi động: hiến chương đổi mô hình lõi

**Làm gì:** Sửa `docs/01-intent.md` — bỏ **Sense** (đọc cảm xúc từ nội dung) và **Pause** (gác cổng
nút gửi), thay bằng vòng lặp `Measure → Bell → Reflect`: đo tốc độ gõ bằng CPM, vượt ngưỡng người
dùng đặt thì ngân chuông, ghi lại số lần chuông cho màn soi lại.

Đụng tới: §1 lý do tồn tại · §3 vòng lặp lõi · §4.2 riêng tư · §4.3 ma sát mềm · §5 non-goals ·
§6 mandate iOS · §7 thế nào là đủ tốt.

**Chốt được:**
- Bỏ **hẳn** lớp sentiment, không giữ lại để ghi nhật ký.
- Đơn vị đo là **CPM (ký tự/phút)**, không phải WPM — Telex/VNI gõ dấu tốn thêm phím nên đếm "từ" bị méo.
- Bỏ cột `appBundleID` khỏi kho local: mô hình mới không còn allow-list app chat nên tên ứng dụng mất
  lý do tồn tại. Kho còn đúng ba thứ: thời điểm chuông · tốc độ lúc đó · ngưỡng đang đặt.

**Phải đoán:** không. Hai điểm mơ hồ (bỏ hẳn sentiment hay giữ; CPM hay WPM) đã hỏi chủ dự án trước
khi sửa.

**Kiểm chứng:** chỉ sửa tài liệu, chưa đụng code. `make` chưa chạy được trên máy Windows của chủ dự
án (không có `make` trong shell) — cổng chất lượng sẽ chạy ở issue đầu tiên có code.

**Còn hở:** gần nửa tủ tài liệu và toàn bộ code vẫn theo mô hình cũ. Đã tách thành 16 issue
(#3 → #18) chia 6 phase, xem README §4.

---

## 2026-07-26 — Dựng kế hoạch + 16 issue

**Làm gì:** Khảo sát code thật để chia phase (không đoán): đường ống hiện tại là
`MoodBuffer → SendRiskAnalyzer → MoodWatch → NudgeCoordinator → Bell → MoodStore → ReflectionScreen`,
cộng nhánh gác cổng `BreathingPause → SendGatekeeper`. Phát hiện quan trọng: **chuông, kho, con sóng,
màn cài đặt đều dùng lại được** — chỉ thay đoạn ống đầu nguồn, nên đây không phải viết lại từ đầu.

Tạo 16 issue (#3 → #18), 6 milestone theo phase, label `area:core/macos/windows/ios/docs` +
`removal`. Mỗi issue có bối cảnh, checklist, file cụ thể, cổng chất lượng, và dòng "chặn bởi #x".

**Chốt được:** thứ tự phase — luật (docs) trước, bộ não sau, macOS chạy thật, rồi mới gỡ đồ cũ và
port sang Windows/iOS. Gỡ `SendRiskAnalyzer` phải đợi cả 3 vỏ chuyển xong, gỡ sớm là vỡ build.

**Phải đoán:** không có. Mọi tham chiếu file trong issue đều đã kiểm tồn tại trước khi viết.

**Kiểm chứng:** `gh issue list` — đủ 16 issue, đúng milestone.

**Còn hở:** 8 câu hỏi mở chưa chốt, xem README §5. Hai cái chặn đường nhất: ngưỡng CPM mặc định (Q1)
và nhịp phím lấy ở đâu (Q3).
