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

## 2026-08-02 — #8 Con sóng đổi nguồn: biên độ theo nhịp gõ (CPM) thay vì send-risk

**Làm gì:** Đổi tên `core/mood/EmotionWaveAmplitude.{h,cpp}` → `CadenceWaveAmplitude.{h,cpp}`
(`git mv`, giữ lịch sử) và đổi chữ ký từ `EmotionWaveAmplitude(double risk)` một tham số sang
`CadenceWaveAmplitude(double cpm, double thresholdCpm)` hai tham số, theo đúng công thức đã research
ở Q4 (`docs/tasks/typing-cadence-bell-execution.md` §2). Quét toàn repo (`git grep`) và sửa **mọi**
nơi gọi/tham chiếu tên cũ: iOS (`KeyboardViewController.mm`, `SuggestionBarView.h`,
`NudgeCoordinatorIOS.h` — comment), Windows (`MoodWatch.cpp` + `MindfulKey.vcxproj` +
`.vcxproj.filters`), `.claude/agents/mood-layer-agent.md`. Dời `tests/ios/emotion_wave_test.mm` →
`tests/core/test_cadence_wave.cpp` (viết lại HOÀN TOÀN cho chữ ký mới, không chỉ đổi tên biến) +
`tests/core/cadence_wave_build.sh`, nối vào `make test-core` + `.github/workflows/macos.yml`, gỡ
`tests/ios/emotion_wave_build.sh` và 2 dòng tương ứng khỏi `make test-ios`. Thêm neo hợp đồng
"Tắt chuông không ảnh hưởng biên độ sóng" vào `docs/04-contracts.md` HĐ-3 (caveat #2 của Q4, chưa
có chỗ neo trước #8).

**Chốt được:**

- **Công thức Q4 chuyển từ "chưa chốt" sang `🟡 chốt tạm`** (README §5): bão hoà tiệm cận Hill n=2,
  `amplitude = s²/(s²+k)` với `s = cpm/thresholdCpm - 0.3`, `k = kCadenceWaveSaturationK = 0.1225`.
  Nhận **hai tham số thô** (không để vỏ tự chia `cpm/threshold`) vì HĐ-6 cấm chia nhỏ logic ra
  nhiều vỏ — đúng bẫy lexicon send-risk từng trôi lệch macOS/iOS. Vùng chết là **tỉ lệ**
  (`kCadenceWaveDeadZoneRatio = 0.3`) so với ngưỡng, không phải giá trị CPM tuyệt đối, để tự co
  giãn theo 3 mức ngưỡng người dùng chọn (300/400/500). Bão hoà tiệm cận thay vì kẹp cứng tại
  ngưỡng: giữ phân biệt được CPM 400/500/800/2000 (biên độ ~0.8/0.881/0.959/0.994) thay vì cả bốn
  cùng vẽ ra 1.0. **Vì sao chỉ là chốt tạm:** `k=0.1225` suy ngược từ mốc "0.80 đúng tại ngưỡng"
  (`MOOD-WAVE-MECHANISM.md:192`), nhưng chính tài liệu đó ghi rõ ba mốc 0.12/0.45/0.80 là mục tiêu
  hiệu chỉnh, chưa ai gõ thật để kiểm.
- **"Tắt chuông" không có nhánh trong core.** Hàm luôn đòi `thresholdCpm` cụ thể; vỏ giữ hai giá
  trị tách biệt `bellEnabled` và `waveReferenceThresholdCpm` — nay đã ghi thành hợp đồng ở HĐ-3.

**Phải đoán:** hai chỗ, đã ghi `docs/tasks/FRICTION-LOG.md` 2026-08-02.

1. **macOS đang có bản logic biên độ sóng THỨ HAI, không đi qua core.** `EmotionWaveView.mm` tự có
   `EaseInOut()` (smoothstep riêng) + hai ngưỡng trạng thái cứng (0.05/0.50) khác hẳn core (0.3);
   `EmotionRiverView.mm` còn vẽ thẳng từ `risk` cũ, chưa đổi sang CPM. Đây đúng bẫy README §6
   ("một mảnh logic hai bản"), nhưng là do macOS **chưa nối dây** (#9), không phải đã trôi lệch từ
   một bản dùng chung. Không tự ý viết lại view macOS trong #8 (ngoài phạm vi, thuộc #9) — chỉ ghi
   phát hiện lại để #9 xử khi nối `TypingCadence`/`BellPolicy` vào macOS.
2. **Nơi gọi iOS/Windows chưa có CPM thật để truyền** (TypingCadence/BellPolicy chưa nối dây, việc
   của #9/#15/#17). iOS: thay bằng `CadenceWaveAmplitude(0.0, 0.0)` (hằng số, không phải biến
   `risk` cũ) kèm `TODO(#17)` — sóng giữ phẳng. Windows (`MoodWatch.cpp`): bỏ hẳn điều kiện
   `EmotionWaveAmplitude(risk) > 0.0` (không còn cách gọi có nghĩa — risk không phải cpm, HĐ-8 cấm
   trộn thước đo), giữ nguyên điều kiện còn lại vì `NudgeCoordinator_RippleThreshold()` luôn ∈
   {0.4, 0.5, 0.6} > 0.3 nên hành vi thật của khối code legacy (sẽ gỡ ở #13) không đổi.

**Kiểm chứng — máy dev KHÔNG có trình biên dịch nào (`g++`/`clang++`/`cl`/`make` đều thiếu), nên
KHÔNG build/chạy được `test_cadence_wave` ở local. CI là cổng thật, CHƯA CHẠY tại thời điểm viết
mục này** (PR chưa mở):**

| Cổng | Kết quả |
|---|---|
| `py -3 scripts/check_hd1.py` | ✅ xanh tại chỗ — bản ghim `scripts/hd1_pinned_api.txt` đã cập nhật (2 dòng đổi: tên file + chữ ký), đọc kỹ diff trước khi cập nhật |
| `PYTHONIOENCODING=utf-8 py -3 scripts/brand_lint.py` | ✅ xanh tại chỗ — 223 file, 9 cảnh báo (đều pre-existing ở `BrandColors.h`, không liên quan thay đổi này) |
| `tests/core/test_cadence_wave` (build + chạy) | ⏳ CHƯA chạy — chờ CI `macos.yml` |
| `xcodebuild` (macOS + iOS build với tên file mới) | ⏳ CHƯA chạy — chờ CI |
| MSVC build Windows (`MoodWatch.cpp` + `.vcxproj` đổi tên) | ⏳ CHƯA chạy — chờ CI `windows.yml` |

**Còn hở:**

- Nối `EmotionWaveView`/`EmotionRiverView` (macOS) vào `CadenceWaveAmplitude` thật — #9.
- Nối placeholder iOS (`CadenceWaveAmplitude(0.0, 0.0)`) thành CPM thật — #17.
- Gỡ khối GĐ6 trong `MoodWatch.cpp` (Windows, đọc cảm xúc cũ) — #13.
- Bản ghim vùng chết `k=0.1225` chờ chủ dự án nhìn sóng thật ở vài mốc CPM trước khi khoá cứng.

---

## 2026-08-02 — #7 `core/mood/BellPolicy` — chính sách reo chuông dùng chung 3 vỏ

**Làm gì:** Viết `core/mood/BellPolicy.{h,cpp}` — C++ thuần, một bản dùng chung 3 vỏ. Cộng
`tests/core/test_bell_policy.cpp` (7 loại ca) + `bell_policy_build.sh`, nối vào `make test-core` và
vào `.github/workflows/macos.yml`. Cập nhật `docs/04-contracts.md` HĐ-2 cho khớp code thật (khối
code cũ là hai hàm tự do, phác thảo — chưa từng có code).

**Chốt được:**

- **Chữ ký: dạng LỚP, một hàm `evaluate()` trả `bool`.** HĐ-2 cũ và issue #7 đều phác thảo hai hàm
  tự do (`BellPolicy_ShouldRing` + `BellPolicy_NoteRung`), issue còn đề xuất trả `struct
  BellDecision`. Đổi cả ba: (1) **lớp thay hàm tự do** — cùng lý do `TypingCadence` đã chốt ở #6
  (cooldown + trạng thái chống rung là *state*, hàm tự do buộc giữ trong biến toàn cục, ba vỏ dùng
  chung một biến thì test dính nhau); (2) **một hàm thay hai hàm** — gộp "hỏi" và "báo đã reo" để
  loại hẳn kiểu lỗi "vỏ hỏi rồi quên báo lại" (cooldown/chống rung không bao giờ nạp) hoặc ngược lại
  (core nghĩ đã reo, vỏ thì im); (3) **bỏ `struct BellDecision`** — `cpmAtDecision` là thông tin nơi
  gọi đã có sẵn (chính là tham số `cpm` nó vừa truyền vào), trả lại là thừa. Đã cập nhật khối code +
  giải trình ở `docs/04-contracts.md` HĐ-2, đúng tiền lệ HĐ-1 đã ghi lại việc `TypingCadence` thành
  lớp.
- **Thời điểm: `int64_t nowMs`, không phải `double nowSeconds` như issue phác thảo.** Cùng đơn vị
  với `TypingCadence::registerKeystroke(int64_t nowMs)` — vỏ có sẵn một mốc mili-giây từ hook bàn
  phím, dùng lại nguyên con số đó cho cả hai lớp thay vì đổi đơn vị + chịu sai số dấu phẩy động ở
  một hợp đồng lõi.
- **Cơ chế chống rung: hysteresis 10% dưới ngưỡng** (`kBellPolicyHysteresisFactor = 0.9`, hằng
  `extern` để test khoá được bằng số thật, không phải hằng chết chôn trong `.cpp`). Sau khi đã reo,
  CPM phải tụt xuống dưới `thresholdCpm * 0.9` mới được coi là một đợt vượt ngưỡng mới. Chọn có biên
  thay vì margin 0 ("chỉ cần tụt dưới ngưỡng"): CPM dao động sát ngưỡng là chuyện thường, và với
  margin 0 một cú tụt 1-2 CPM (đúng mức nhiễu một phím trên cửa sổ 30 giây) đã đủ "tái vũ trang" —
  hai gợn nhịp sát nhau vẫn tách thành hai đợt và reo hai lần cách nhau vài giây, đúng thứ chống
  rung phải ngăn. 10% cho ngưỡng mặc định 400 nghĩa là phải tụt xuống dưới 360 (~20 phím/30 giây).
- **Cơ chế "đã vũ trang" (armed) TÁCH BIỆT hoàn toàn khỏi cooldown** — đây là điểm dễ vấp nhất. Nếu
  chỉ dựa vào cooldown (không có cổng vũ trang riêng), một tràng gõ nhanh dài liên tục sẽ reo lặp
  lại mỗi khi cooldown hết hạn — sai với checklist issue #7 ("reo đúng 1 lần cho một tràng gõ nhanh
  dài liên tục", kể cả khi tràng đó dài hơn cooldown). Cổng "đã vũ trang" (cổng 3) chặn TRƯỚC khi
  cổng cooldown (cổng 6) kịp được xét, nên hai cơ chế không thể thay thế cho nhau — `test_bell_policy.cpp`
  Loại 1 khoá đúng ca hồi quy này (streak trải dài qua mốc t=45000, tức đúng lúc cooldown hết, vẫn im).
- **Ca biên CPM == ngưỡng: CÓ reo** (so sánh `>=`, không phải `>`). Ngưỡng do chính người dùng đặt —
  "đạt đúng mức mình đặt" phải tính là đã tới, không phải còn thiếu một chút.
- **Tắt chuông / tạm hoãn KHÔNG tiêu lượt vũ trang.** Nếu CPM vượt ngưỡng trong lúc tắt/hoãn, cơ hội
  reo vẫn còn nguyên khi bật lại/hết hoãn — không phải chờ CPM tụt xuống rồi vượt lại từ đầu. Việc
  bật/tắt là quyết định người dùng, tách biệt khỏi tín hiệu nhịp gõ.
- **Không bake một giá trị cooldown mặc định vào core.** Constructor nhận `cooldownMs` từ vỏ; core
  không tự chọn con số. 45 giây đang chạy ở `NudgeCoordinatorMac`/`IOS` là cho MÔ HÌNH CŨ (đếm chuỗi
  câu căng liên tiếp) — chưa có quyết định nào chốt lại số cho mô hình CPM mới, ghi ở
  `FRICTION-LOG.md` để #9 xin chốt trước khi ba vỏ tự đoán ba con số khác nhau.

**Phải đoán:** ba chỗ, đã ghi `docs/tasks/FRICTION-LOG.md`.
1. Biên trễ chống rung (10%) và hướng chọn ca biên CPM==ngưỡng (`>=`) — issue chỉ nói "cân nhắc",
   không cho con số hay hướng, nên đã tự chọn + ghi lý do đầy đủ (đã chốt).
2. Con số cooldown mặc định cho mô hình CPM mới — chưa ai chốt, cố ý KHÔNG bake vào core, để #9 xin
   chốt trước khi nối dây thật (còn mở).
3. Chỉ nối `macos.yml`, không nối `windows.yml` — issue #7 chỉ ghi rõ `macos.yml`, dù tiền lệ #6 đã
   nối cả hai runner. Bám sát chữ issue thay vì tự mở rộng phạm vi; `BellPolicy` dùng subset C++14
   đơn giản như `TypingCadence` nên rủi ro khác biệt clang↔MSVC thấp nhưng **chưa được chứng minh**
   (còn mở).

**Kiểm chứng — máy dev KHÔNG có trình biên dịch nào (`g++`/`clang++`/`cl`/`make` đều thiếu), nên
KHÔNG build/chạy được `test_bell_policy` ở local. CI là cổng thật, và **đã chạy**:**

| Cổng | Kết quả |
|---|---|
| `macos.yml` — `test_bell_policy` | ✅ [run 30726639383](https://github.com/theminh207/mindful-key/actions/runs/30726639383) — `g++ -std=c++14 -Wall -Wextra` **không warning nào**, mọi ca PASS. Xcode cũng compile `BellPolicy.cpp` vào target app macOS, sạch |
| `windows.yml` (MSVC v143) | ✅ Debug + Release — nhưng chỉ build vỏ, **không** chạy `test_bell_policy` (xem "Phải đoán" #3 / Q11) |
| Cổng HĐ-1 (`py -3 scripts/check_hd1.py`) | ✅ chạy tại chỗ — xanh, 23 dòng khai báo khớp bản ghim (7 dòng mới của `BellPolicy.h`) |
| Cổng HĐ-1 — kiểm chiều-ngược | ✅ tiêm 1 vi phạm giả (`const wchar_t* debugLabel` thêm vào `evaluate`) → cổng đỏ đúng cả 3 lưới (ghim/allowlist/denylist), sau đó revert → xanh lại |
| `brand_lint.py` | ✅ 223 file, 9 cảnh báo (9 cảnh báo là hardcode màu có sẵn ở `BrandColors.h`, không do PR này) |

**Còn hở:**
- `BellPolicy` **chưa vỏ nào nối dây** — thuần là bộ não, giống `TypingCadence` sau #6. Nối ở #9
  (macOS) · #15 (Windows) · #17 (iOS).
- Chưa nối `windows.yml` (xem "Phải đoán" #3) — `BellPolicy` chưa từng biên dịch bằng MSVC.
- Cooldown mặc định cho mô hình CPM mới chưa chốt (xem "Phải đoán" #2) — nay là **Q10** ở README §5,
  cần chốt trước #9.
- Hai con số **`🟡 chốt tạm`** (biên trễ 10%; ca biên `>=`) là do agent tự chọn trong phiên chạy tự
  động, **chưa được chủ dự án duyệt** — lập luận đầy đủ ở
  `docs/tasks/typing-cadence-bell-execution.md` §2.
- Chưa ai **nghe thử** chuông reo theo nhịp thật: `BellPolicy` mới chỉ được chứng minh bằng ca kiểm
  tất định. Mốc 360 CPM có đúng là "đã chậm tay lại" hay không thì chỉ tay người gõ mới trả lời được.

---

## 2026-08-01 — #6 `core/mood/TypingCadence` — đo nhịp gõ (CPM) trên cửa sổ trượt

**Làm gì:** Viết `core/mood/TypingCadence.{h,cpp}` — C++ thuần, một bản dùng chung 3 vỏ. Cộng
`tests/core/test_cadence.cpp` (12 loại ca) + `cadence_build.sh`, nối vào `make test-core` **và vào
cả hai runner CI**.

**Chốt được:**

- **Chữ ký: dạng LỚP, thời gian tính bằng int64 mili-giây.** Issue #6 đề xuất class với
  `double nowSeconds`; hợp đồng HĐ-1 (merge ở #4) lại ghi `TypingCadence_OnKeystroke(int64_t tsMs)`.
  Hoà giải: lấy **dạng lớp** từ issue (test dựng được nhiều thể hiện độc lập, không rò rỉ trạng thái
  giữa các ca) và lấy **int64 mili-giây** từ hợp đồng (không sai số dấu phẩy động; đồng hồ đơn điệu
  cả hai OS đều cho tick nguyên). Đã đồng bộ lại chữ ký ở `04-contracts.md`, skill và README §5 —
  tầng 04 là quy phạm, không được nói sai so với code.
- **Cách chống thổi phồng CPM** (issue hỏi *"cần tối thiểu bao nhiêu phím mới báo số"*): **chia cho
  độ dài cửa sổ**, không phải cho khoảng giữa nhịp đầu và nhịp cuối. Chia theo khoảng giữa hai nhịp
  thì gõ 2 phím cách nhau 100ms ra **1200 CPM** → chuông reo oan ngay phím thứ hai. Chia cho cửa sổ
  thì 2 phím trong 30 giây ra đúng 4 CPM, và muốn chạm ngưỡng 400 phải gõ **thật 200 phím trong 30
  giây**. Không có cách nào thổi phồng → **không cần** thêm luật "tối thiểu N phím". Một khái niệm
  ít hơn thay vì một khái niệm nhiều hơn.
- **Đánh đổi cố ý:** 30 giây đầu sau khởi động bị báo **thấp** hơn thực tế (cửa sổ chưa đầy). Đây là
  chiều an toàn — nghiêng về **im lặng**, đúng tinh thần "chuông là lời mời, không phải kết luận".
- **Đồng hồ nhảy lùi → xoá sạch** thay vì cố vá. Nhịp trước cú nhảy không còn so được với nhịp sau
  nó; giữ lại là bịa dữ liệu (HĐ-8). Mất tối đa một cửa sổ.
- **Sức chứa cố định 1024, không cấp phát động** (HĐ-3 đòi O(1), không cấp phát, chạy được trong
  hook). Trần này cho CPM bão hoà quanh 2048 — xa trên mọi ngưỡng (cao nhất 500), nên không bao giờ
  làm chuông câm.

**Phải đoán:** không. Hai chỗ mơ hồ (chữ ký, cách chống thổi phồng) đều có căn cứ trong issue hoặc
hợp đồng, và đã ghi rõ lý lẽ ở trên.

**Kiểm chứng — lần đầu của đợt này có bằng chứng CHẠY THẬT, không phải chỉ đọc code:**

| Cổng | Kết quả |
|---|---|
| `macos.yml` (clang) | ✅ `test_cadence` — **12/12 loại ca PASS** |
| `windows.yml` (MSVC, Debug + Release) | ✅ biên dịch + chạy `test_cadence` |
| Cổng HĐ-1 | ✅ xanh |
| `brand-lint` | ✅ 0 vi phạm cứng |

Đây là **lần đầu `core/mood` được biên dịch bằng MSVC** — trước nay chỉ `core/engine` đi qua đường
đó. Bắt khác biệt clang↔MSVC ngay bây giờ thay vì để #15 (vỏ Windows) vấp phải rồi mới biết.

**CI bắt được đúng thứ nó sinh ra để bắt.** Vòng đầu đỏ 3 ca ngưỡng: `typeKeys(150, 0, 100)` đặt
nhịp tại `t = 0..14900`, rồi hỏi `currentCPM(30000)` → mép dưới cửa sổ **đúng bằng 0**, mà cửa sổ là
nửa mở `(now-W, now]` nên nhịp tại `t=0` bị loại → 298 thay vì 300. **Lỗi test, không phải lỗi
code** (hành vi mép đã có Loại 6 khoá riêng). Đã sửa cho nhịp trải đều gần hết cửa sổ rồi xét tại
phím cuối — vừa đúng số vừa sát cách gõ thật.

**Biến HĐ-1 từ lời hứa thành cổng máy.** Hiến chương §4.1 tự đòi luật nhận diện phải cưỡng chế bằng
máy *"không phụ thuộc vào việc có ai đọc tài liệu hay không"*; PR này áp đúng lối nghĩ đó cho §4.2:
thêm bước **"Cổng HĐ-1"** vào `macos.yml`. (Bản đầu là grep denylist; sau ba lần thủng nó thành
`scripts/check_hd1.py` — allowlist — xem khối "Vòng review 2" ở trên.)

Dựng cổng đó lòi ra **hai lỗi trong chính hợp đồng tui viết ở #4**:

1. **Mẫu grep tự khớp chính nó.** Dòng ví dụ grep nằm trong comment của `TypingCadence.h` chứa cả
   `wstring` lẫn `Cadence` → cổng bắt luôn cái comment. Xử: pattern giữ **đúng một bản**, ở
   workflow; header chỉ trỏ tới, không chép.
2. **Mẫu grep HỎNG — đây là lỗi nặng hơn.** Nó đòi kiểu chuỗi đứng *trước* tên lớp trên cùng một
   dòng, nên `void TypingCadence_OnWord(const std::wstring&)` **lọt qua** — đúng cái hình dạng vi
   phạm dễ xảy ra nhất. Phát hiện bằng cách **thử chiều ngược**: tiêm vi phạm giả rồi xem cổng có
   đỏ không. Cổng mới đã thử cả hai kiểu vi phạm (tên trước / kiểu chuỗi trước), cả hai đều đỏ
   đúng, code thật thì xanh.

   **Bài học:** một hợp đồng kèm lệnh soi hỏng còn **tệ hơn** không kèm lệnh nào — nó cho cảm giác
   an toàn giả. Và cách duy nhất biết một cổng có chạy không là **tiêm vi phạm giả vào rồi xem nó
   có đỏ**; thấy nó xanh trên code sạch không chứng minh được gì.

**Vòng review 4 — giới hạn KHÁI NIỆM, không phải lỗi vặt:**

```cpp
void noteChar(int codePoint);   // cổng XANH
```

`int` nằm trong allowlist, mà `int` thừa sức chở một codepoint Unicode. Tức allowlist **kiểu vô
hướng** chỉ chứng minh *"không có kiểu hình dạng chuỗi"*, **không** chứng minh *"không nội dung nào
vào"* — đúng điều HĐ-1 tuyên. Comment trong chính script tự khẳng định sai: *"không kiểu nào chở
nổi một ký tự"*. Và đường gọi đó chính là đường thiết kế đã chốt (*"vỏ gọi từ hook, từng phím
một"*) — chỉ cần thêm một tham số vào lời gọi có sẵn.

Cộng ba lỗ cùng họ: `.hpp`/`.hh`/`.inl`/`.mm` vô hình (chỉ nhận `.h`/`.cpp`); **thư mục con** vô
hình (`os.listdir` không đệ quy); biến thành viên trong `.h` (`int _typed[4096]`) không ai canh.

**Xử — thêm lưới thứ ba: ghim bề mặt khai báo** (`scripts/hd1_pinned_api.txt`). Cách này khớp sẵn
với một thứ **đã có**: HĐ-3 tuyên chữ ký lớp nhịp gõ là **hợp đồng đóng băng**. File ghim biến lời
tuyên đó thành thứ kiểm được bằng máy — thêm *bất kỳ* tham số nào, kiểu gì, hay thêm một biến thành
viên, đều đỏ cho tới khi có người chạy `--update-pin` và giải trình trong PR. Đổi `os.listdir` →
`os.walk`, nới bộ đuôi.

Kiểm lại: `noteChar(int)` · `noteChar2(int64_t)` · `int* typedChars()` · `int _typed[4096]` ·
`std::array<int,1024>` · `ContentTap.hpp` · `core/mood/tap/ContentTap.h` — **tất cả nay đỏ**. Ba lỗ
vòng 3 vẫn đỏ. Sáu API hợp lệ vẫn xanh.

**Và ghi rõ giới hạn thật thay vì giả vờ kín.** `static int gTyped[4096]` trong `.cpp` vẫn qua được
cả ba lưới. Nhưng nó là **kho chứa trơ**: muốn đổ dữ liệu vào phải có đường nhận từ ngoài, mà mọi
đường như thế đều ở header và đã bị ghim. Cổng này bảo đảm **bề mặt NHẬN**, không bảo đảm từng byte
bộ nhớ bên trong. Đã viết thẳng vào docstring — đúng bài học của chính PR này: **một hợp đồng nói
quá thứ nó làm được còn tệ hơn không nói gì.**

**Vòng review 3 — allowlist vẫn còn ba đường vào, tất cả cùng một gốc:**

1. **`operator<<(const uint32_t*)` lọt.** Regex tìm tên hàm là `[A-Za-z_]\w*`, mà ngay trước `(`
   của `operator<<` là `<<` — không khớp gì cả, nên **cả danh sách tham số đi lọt**. Áp cho mọi
   toán tử ký hiệu: `<<` `()` `+=` `[]`. Và `uint32_t` **thiếu** ở lưới denylist phụ, nên không có
   gì đỡ. Đúng con bug "quên một kiểu" đã giết bản denylist — vẫn còn nguyên trong cái lưới đáng
   lẽ để đỡ lưng allowlist.
2. **File mới trong `core/mood/` hoàn toàn vô hình.** Danh sách file được soi là 4 đường dẫn
   **cứng**, nên `core/mood/ContentTap.h` chứa `const uint32_t*` đi qua **xanh**. Chốt chặn "không
   tìm thấy file nào → đỏ" chỉ chống *đổi tên*, không chống *thêm file*. Mà lộ trình sắp tới có
   "kho ghi lần chuông" là file mới.
3. **Hàm tự do trong `.cpp`** nhận `const uint32_t*` — cùng gốc với (1).

**Xử — đảo luôn cả cách chọn file:** thay danh sách *file-được-soi* (phải nhớ mà thêm) bằng danh
sách **miễn trừ** (co lại dần, cạn khi #13 xong). Cổng nay quét **mọi `.h`/`.cpp` trong
`core/mood/`** trừ 7 file của mô hình cũ — nên file mới **bị soi ngay**, không cần ai nhớ đăng ký.
Thêm `operator\s*[^\s(]+` vào regex tên hàm; thêm `uint32_t` + `unsigned short` vào lưới phụ. Và
để danh sách miễn trừ không mục ruỗng: trỏ tới file đã biến mất cũng **đỏ**, nhắc dọn.

Sửa luôn ba chỗ **bắt oan** reviewer chỉ ra: `charsPerMinute()` và `charCount()` bị đỏ vì `char`
không có ranh giới từ — mà đơn vị của chính lớp này *là* characters-per-minute, tức cổng đang cấm
gọi đúng tên miền; và tham số có **giá trị mặc định là định danh** (`bool on = true`,
`int64_t ms = kTypingCadenceDefaultWindowMs`) bị đẩy tên vào ô "kiểu" → đỏ oan, đúng thứ #7
`BellPolicy` rất dễ vấp. Cộng một lỗi vận hành: script **crash trên chính máy dev** vì console
cp1252 không in nổi tiếng Việt — mà "chạy được tại máy dev" là lý do tồn tại của nó.

Kiểm lại toàn bộ: 3 lỗ vòng 3 **đóng**, 8 ca vòng 2 **vẫn đỏ**, 6 API hợp lệ (gồm cả chữ ký dự kiến
của `BellPolicy`) **không còn bị bắt oan**.

**Vòng review 2 — cổng vẫn thủng, và lần này là lỗ đáng sợ hơn:**

Reviewer làm đúng cái phương pháp tui vừa tự viết ra (*"đi tìm hình dạng vi phạm có thật trong
repo"*) nhưng grep **rộng hơn `core/mood/`** — và tìm ra `core/engine/DataType.h` có
`typedef unsigned short Uint16` / `Uint32` / `Byte`, còn `Engine.h:198` dùng đúng chúng để trao ký
tự ra ngoài: `Uint32 getCharacterCode(const Uint32& data)`. Nghĩa là
`void registerKeystroke(int64_t nowMs, const Uint16* text)` là **vi phạm thật, portable, dịch được
trên cả hai runner — và cổng cho qua XANH**. Cộng thêm `TCHAR`/`LPCWSTR` (47 chỗ dùng trong
`platforms/windows/`), `uint16_t`, `id`.

Đây là **lần thứ ba** cổng này thủng. Kết luận không thể tránh: **denylist không bao giờ đủ** — nó
chỉ chặn được những kiểu người viết đã *nghĩ tới*, mà vi phạm thật đến từ kiểu người ta *không*
nghĩ tới. Vá thêm tên kiểu là đuổi theo cái đuôi của chính mình.

**Đảo sang allowlist.** Viết `scripts/check_hd1.py`: mọi tham số trong header của lớp nhịp
gõ/chuông phải là `int64_t` · `int` · `double` · `bool` · `void`, và **không được là con trỏ / tham
chiếu / mảng**. Kiểu nào khác — *kể cả kiểu chưa ai nghĩ tới* — là đỏ.

Viết bằng **Python chứ không phải grep**, vì hai lý do: allowlist cần phân tích tham số (grep không
nổi), và **máy dev chạy được python** — nên lần đầu trong cả đợt này tui **kiểm được cổng tại chỗ
trước khi push** thay vì đẩy lên rồi chờ CI.

Kiểm bằng **22 hình dạng vi phạm**: 8 ca reviewer chỉ ra lọt (`Uint16`/`Uint32`/`Byte`/`uint16_t`/
`TCHAR`/`LPCWSTR`/`id`/`filesystem`), 7 ca vòng trước, cộng `unichar`/`string_view`/`u8string`/
`vector<wchar_t>`/`NSMutableAttributedString`/`QString`/`jstring`/`BSTR`, và — quan trọng nhất —
một kiểu **tự bịa** `SomeUnknownType` cùng `const int64_t&` (tham chiếu tới kiểu *được phép*).
**Cả 22 đều đỏ**, code thật vẫn xanh. Ca `SomeUnknownType` là bằng chứng allowlist làm được thứ
denylist không đời nào làm được.

Xây cổng cũng lòi ra hai chỗ nữa: regex bắt nhầm **danh sách khởi tạo constructor** và **nơi gọi
hàm** trong `.cpp` (`_hasLast(false)`, `keystrokesInWindow(nowMs)` — đỏ oan 3 chỗ), nên allowlist
giới hạn vào `.h`, nơi duy nhất có mặt API; `.cpp` vẫn có lưới denylist. Và comment trong chính
`macos.yml` vẫn còn chữ *"mọi kiểu chuỗi"* — đúng chữ tui vừa gỡ khỏi hai file khác vì nói quá.

**Vòng review 1 bắt được 1 lỗi chặn — cùng một chỗ đau:**

Cổng HĐ-1 tui vừa dựng **bỏ sót `const wchar_t*`** — đúng kiểu chuỗi phổ biến **nhất** trong
`core/mood` hiện nay (`MoodPhrasing.cpp`, `SendRiskAnalyzer.cpp` dùng đầy), và đúng thứ #7
`BellPolicy` dễ viết ra: `const wchar_t* levelName` sẽ đi qua cổng **xanh**. Mẫu cũ có
`char[[:space:]]*\*` — sau `char` là `_t*` chứ không phải `*`, nên trượt. Reviewer còn tìm thêm 3
kiểu lọt nữa: `char[]`, `u16string`, `CFStringRef`.

Cay ở chỗ: **đây đúng cái bài học tui vừa tự viết ra trong cùng PR** — *"lệnh soi hỏng còn tệ hơn
không có, vì cho cảm giác an toàn giả"*. Tui viết bài học đó sau khi sửa mẫu lần một, rồi lập tức
mắc lại lần hai ở dạng khác. Kiểm chiều-ngược lần đầu tui chỉ thử **2 hình dạng vi phạm**, và cả
hai đều thuộc loại tui đã nghĩ tới; không thử kiểu nào mình chưa nghĩ tới.

Xử: nới mẫu thành `string|String|char` — cố ý **rộng**, fail-closed. Kiểm bằng **7 hình dạng vi
phạm**, cả 7 đều đỏ, code thật vẫn xanh. Không dùng `\b` vì đó là mở rộng GNU, còn runner là BSD
grep. Và sửa `04-contracts.md` + `TEST_MATRIX.md` bỏ chữ *"mọi kiểu chuỗi"* — nói quá so với thứ
mẫu thật sự phủ.

> Nhưng đó **vẫn là denylist**, và vòng 2 chứng minh nó vẫn thủng. Bản cuối cùng là allowlist.

**Bài học chồng lên bài học:** kiểm một cổng bằng cách tiêm vi phạm là đúng, nhưng **tiêm những
hình dạng mình đã nghĩ tới thì chỉ chứng minh được điều mình đã tin**. Muốn biết cổng có thủng
không thì phải đi tìm hình dạng vi phạm **có thật trong repo** — `grep` chính `core/mood/` xem code
hiện có đang dùng những kiểu chuỗi nào, rồi thử đúng chúng.

Sửa thêm theo góp ý không-chặn: comment biện minh cho "không dừng sớm" trong `keystrokesInWindow`
**nói sai sự thật** (dãy *có* đơn điệu vì nhánh reset đã bảo đảm) — viết lại thành lý do thật, là
cố ý không phụ thuộc bất biến ở hàm khác; khai `O()` ở header sai (`O(_count)` chứ không phải "số
nhịp trong cửa sổ"); ca test tràn vòng tròn **chép lại chính công thức đang test** → viết cứng
`2048.0`; hai ca `windowMs` hỏng chỉ khẳng định "không NaN" → khoá cứng giá trị kẹp là 1ms; ví dụ
C++ "SAI" ở `04-contracts.md` không phải cú pháp khai báo hợp lệ.

**Thêm 3 ca test lấp lỗ phủ** reviewer chỉ ra: vòng tròn **đầy** *và* có nhịp rơi khỏi cửa sổ cùng
lúc (tổ hợp duy nhất bắt được lỗi chỉ số vòng khi gặp phép lọc mép — Loại 10 không phủ vì ở đó cả
1024 ô đều trong cửa sổ); nhiều phím trong **cùng một mili-giây** (đồng hồ thô/auto-repeat, không
được nuốt nhịp và không được coi là đồng hồ nhảy lùi); và `windowMs()` accessor.

**Còn hở:**
- `TypingCadence` **chưa vỏ nào nối dây** — đây thuần là bộ não. Nối ở #9 (macOS) · #15 (Windows) ·
  #17 (iOS), và cổng kiểm ô mật khẩu (HĐ-4) nằm ở phía vỏ, macOS hiện chưa có.
- **Danh sách kiểu chuỗi của cổng HĐ-1 là chỗ phải đoán** — không nguồn nào định nghĩa "kiểu chuỗi"
  gồm những gì. Đã ghi `FRICTION-LOG.md`, chờ chủ dự án chốt có cần liệt danh sách chính thức trong
  `04-contracts.md` không, và có nên áp cổng cho **cả** `core/mood/` sau khi #13 gỡ xong.
- Tràn `int64` ở `nowMs - _windowMs` khi `nowMs` gần `INT64_MIN` — UB về lý thuyết, không tới được
  từ đồng hồ đơn điệu thật. Ghi để biết, không xử.
- `keystrokesInWindow()` là API thêm ngoài đề xuất của issue. Giữ vì test khẳng định được bằng **số
  nguyên chính xác** thay vì so sánh số thực, và vỏ Windows sẽ cần nó cho icon khay (#15).
- Cổng HĐ-1 hiện chỉ liệt `TypingCadence.*` và `BellPolicy.*`. Thêm lớp mới vào `core/mood` thì phải
  thêm tên vào danh sách — cổng cố ý **đỏ khi không tìm thấy file nào**, nhưng không tự phát hiện
  file mới.

---

## 2026-08-01 — #5 Đồng bộ docs/tasks + harness .claude

**Làm gì:**

*Harness `.claude/`* — skill `mood-sentiment-layer` → **`typing-cadence-layer`**, viết lại toàn bộ
mandate (luồng dữ liệu mới, 4 luật không được phá, bảng "thứ đã chết đừng sinh lại"). `mood-layer-agent`
đổi mandate từ "lớp cảm xúc" sang "lớp đo nhịp gõ + chuông tỉnh thức". `mindful-keyboard-harness/SKILL.md`
cập nhật bảng 4 chuyên gia + luật định tuyến. `CLAUDE.md` cập nhật bảng harness và **tạo mới bảng
"Lịch sử thay đổi harness"** — bảng này được `SKILL.md` bước 6 viện dẫn nhưng trước giờ **chưa từng
tồn tại**.

*`docs/tasks/`* — `PRD.md` viết lại theo `Measure → Bell → Reflect` (định vị, vòng lặp, non-goals,
metrics, riêng tư, phạm vi kỹ thuật). `PRIVACY-NOTE.md` viết lại mạnh hơn hẳn: lời hứa từ *"có đọc
nhưng không lưu"* thành ***"không đọc"***, kèm câu chốt *"không cần tin lời hứa suông — kiểm chứng
được bằng cách đọc mã nguồn"* trỏ vào HĐ-1. `SEND-RISK-MODEL-SPEC.md` + `BREATHING-PAUSE-CONTRACT.md`
gắn banner **⛔ LỖI THỜI** ở đầu (giữ file, không xoá lịch sử). `MOOD-WAVE-MECHANISM.md` gắn banner
bảng-phân-loại nói rõ phần nào chết / phần nào giữ, và **viết lại đoạn §8 hướng dẫn đọc đồ thị** —
đoạn cũ mô tả biên độ theo *"dùng từ ngữ ôn hòa / tiêu cực"* (giả định đọc nội dung) và *"tâm trí bắt
đầu xáo động"* (suy trạng thái tâm ra từ **nội dung** — hiến chương **§4.2** cấm: *"không suy đoán
gì từ chữ nghĩa"*; §4.1 thì **không** cấm ẩn dụ mặt hồ ↔ tâm, nó còn dùng chính ẩn dụ đó). `AGENT-BRIEF.md` sửa dòng định vị.
`TEST_MATRIX.md` thêm khối mở đầu + **10 hàng mô hình mới**.

**Chốt được:**
- **Khôi phục 4 agent** thay vì để xoá. `.claude/agents/` bị xoá sạch trong tree bàn giao, nhưng
  `SKILL.md` dòng 41 **bắt buộc** đọc `.claude/agents/{name}.md`, và 3 chỗ khác cũng trỏ tới. Hỏi
  chủ dự án → khôi phục, giữ tên `mood-layer-agent`, viết lại mandate.
- **`.claude/rules-archive/` giữ nguyên việc xoá** — grep toàn repo: **không ai trỏ tới**.
- **`.claude/settings.json`** (bỏ `Bash(git push:*)` khỏi ask-list) giữ, đi kèm PR này — chủ dự án
  chốt, ghi rõ là ngoài phạm vi có chủ đích.

**Phải đoán:** hai chỗ, đã ghi `FRICTION-LOG.md`.
1. **`TEST_MATRIX.md`: issue bảo "gỡ hàng", luật của chính file bảo "giữ vết".** Mục "Khi nào cập
   nhật file này" viết: *"Bỏ một hành vi → đổi Trạng thái sang `retired`, **không xóa dòng**"*.
   **Luật của file thắng.** Và còn một tầng nữa: cũng **chưa** đổi sang `retired` bây giờ, vì
   `test_send_risk` hôm nay **vẫn chạy và vẫn xanh** — đổi trạng thái trước khi gỡ code là nói dối
   theo hướng ngược lại. Chuyển `retired` ở #12/#13 khi code biến mất thật.
2. **FRICTION-LOG không phải changelog.** Issue bảo *"ghi 1 mục ngày đổi mô hình + lý do, để người
   sau hiểu vì sao code cũ biến mất"*. Nhưng file này tự khai là danh sách *"chỗ phải đoán"*, không
   phải nhật ký thay đổi. Xử: lý do "vì sao code cũ biến mất" đặt vào **banner ⛔ LỖI THỜI** ngay đầu
   hai file chết (đúng chỗ người đọc sẽ gặp nó) + `ADR-0013`; ba mục thêm vào FRICTION-LOG đều đúng
   thể loại "chỗ phải đoán" thật.

**Vòng review bắt được 4 lỗi chặn — đã sửa hết:**
1. **`CONTRIBUTING.md:28` còn trỏ tới skill đã xoá.** Tui grep `mood-sentiment-layer` **chỉ trong
   `.claude/`** rồi tuyên bố "sạch" — grep hẹp hơn phạm vi thật. Grep toàn repo ra 6 kết quả, 5 hợp
   lệ (bảng lịch sử, PROGRESS, README, file đã gắn banner lỗi thời) và **1 sai**: dòng đang chỉ
   người đóng góp mới tới một skill không còn tồn tại. **Bài học: grep phạm vi hẹp rồi kết luận
   "sạch" là tự lừa.**
2. **Banner `MOOD-WAVE-MECHANISM.md` tự mâu thuẫn.** Xếp §3 và §4 vào nhóm "✅ giữ nguyên — không
   phụ thuộc nguồn", nhưng §3 viết *"ghi 1 mẫu = trung bình **risk**"* (đúng là phần nguồn, đúng thứ
   issue giao viết lại) và §4 định nghĩa "buổi có gợn" bằng ngưỡng đến từ §5 — mà chính bảng xếp §5
   vào nhóm chết. Xếp cả §8 vào "giữ nguyên" trong khi **chính PR này viết lại §8**. Tách lại thành
   ❌ / ⚠️ nửa-sống / 🔄 đã-viết-lại / ✅.
3. **`CLAUDE.md:5` sửa ngoài phạm vi mà không khai.** Tree bàn giao gỡ mệnh đề trỏ về
   `docs/tasks/AGENT-BRIEF.md` khỏi dòng hiến chương; tui để nguyên và chỉ khai `settings.json` là
   ngoài phạm vi. Hệ quả: `AGENT-BRIEF.md` vẫn **tự xưng là hiến chương** trong khi CLAUDE.md đã trỏ
   luật tối cao sang `docs/01-intent.md` → hai file cùng nhận vai luật tối cao. Xử: **hạ cấp
   AGENT-BRIEF** thành "bản brief đầy đủ có bối cảnh lịch sử, không phải nguồn luật", kèm câu phân
   xử "hai bên mâu thuẫn → `docs/01-intent.md` đúng".
4. **`AGENT-BRIEF.md:41` copy mẫu là *"Hơi thở đang ngắn"*.** Sản phẩm không đo hơi thở và sẽ không —
   tàn dư mô hình nhịp thở. Đổi thành *"Nhịp gõ vượt mức bạn đặt"*.

Sửa thêm 3 chỗ nhỏ: phạm vi hợp đồng ghi "HĐ-1 → HĐ-4" trong skill và agent nhưng chính hai file đó
viện dẫn HĐ-6 và HĐ-8 → ghi rõ; thêm mục "khôi phục 4 agent" vào §5 "Đã chốt" (session sau cần biết);
`settings.json` thừa khoảng trắng sau `[`.

**Vòng review 2 — thêm 2 lỗi chặn:**
1. **`AGENT-BRIEF.md:1` H1 vẫn là "(HIẾN CHƯƠNG)"**, mâu thuẫn thẳng với banner ngay dưới nó. Sửa
   banner mà quên tiêu đề — mà tiêu đề mới là dòng người ta nhìn đầu tiên.
2. **`MOOD-WAVE-MECHANISM.md` §8 đoạn "Lưu ý quan trọng" vẫn nói *"mặt hồ càng xáo động"***, mâu
   thuẫn với câu mới cách đó 6 dòng (*"không nói gì về tâm bạn"*). Vòng trước tui viết lại **danh
   sách gạch đầu dòng** nhưng bỏ sót **đoạn văn ngay dưới nó**.

**Vòng review 3 — bài học đáng ghi nhất của cả issue này:**

Vòng 2 tui tự phát hiện mình **trích sai hiến chương**: viết *"'tâm trí xáo động' — phán xét trạng
thái tâm, hiến chương §4.1 cấm"*. §4.1 **không** cấm điều đó — nó còn dùng chính ẩn dụ *"mặt hồ dậy
sóng ứng với tâm động"*, và phần cấm tuyệt đối của nó liệt 4 thứ (đèn đỏ/xanh · emoji chấm điểm ·
gamification · copy khiển trách). §4.1 **có** một phép tự kiểm phạm vi rộng (*"đang mô tả hay đang
phán xét?"*) nên lời trích cũ **quá rộng chứ không hoàn toàn vô căn cứ**. Nhưng căn cứ chuẩn xác là
**§4.2** (*"không suy đoán gì từ chữ nghĩa"*) — cái sai của bản cũ là **căn cứ để nói**, không phải
chữ "tâm".

Nhưng vòng 3 bắt được: tui sửa lời trích đó ở `MOOD-WAVE-MECHANISM.md` mà **để nguyên chính lời
trích sai ấy ở `PROGRESS.md:38`** — cùng một PR, một chỗ đính chính, một chỗ vẫn sai. Và tìm ra
**bản sao thứ ba ở `docs/04-contracts.md`** — tầng hợp đồng, trọng lượng quy phạm cao hơn `docs/tasks/`
— cũng viện dẫn §4.1 quá rộng (do chính PR #4 của tui viết). Đã sửa cả ba, cộng `AGENTS.md:146` còn
gọi `AGENT-BRIEF.md` là *"Hiến chương bản gốc"*, và hai câu ở §8 (*"gương soi tâm trí"*, *"những gì
cơ thể đang thể hiện"*) vẫn suy trạng thái người từ phép đo.

**Bài học:** trong một repo lấy hiến chương làm luật tối cao, **trích sai hiến chương là lỗi nặng
hơn lỗi câu chữ** — nó tạo ra luật giả. Và khi phát hiện một lời trích sai, phải `grep` **mọi bản
sao của nó** rồi sửa cùng lượt, chứ không sửa đúng chỗ vừa nhìn thấy. Đây là lần thứ hai trong cùng
issue tui mắc lỗi "sửa chỗ nhìn thấy, sót chỗ còn lại" (lần đầu: grep `mood-sentiment-layer` chỉ
trong `.claude/`).

**Kiểm chứng:** `brand_lint.py` 0 vi phạm cứng. PR thuần tài liệu + harness, không đụng `core/` hay
`platforms/`.

**Còn hở:**
- `docs/tasks/` còn nhiều file khác nhắc mô hình cũ (`OPENKEY-MAP.md`, `QA-WINDOWS.md`,
  `WINDOWS-PARITY-TASKS.md`, `BRAND-ASSETS.md`…) — **issue #5 không liệt kê**, không đụng phần nội
  dung. Để #14 nhặt khi rà câu chữ toàn cục. **Ngoại lệ đã xử ngay:** 3 file
  (`ROADMAP-WINDOWS.md`, `QA-WINDOWS.md`, `WINDOWS-PARITY-TASKS.md`) trỏ `AGENT-BRIEF.md` là *"luật
  tối cao"* — đó là orphan **do chính PR này tạo ra** khi hạ cấp AGENT-BRIEF, nên dọn luôn theo luật
  surgical, trỏ sang `docs/01-intent.md`.
- `bmad-output/` (tài liệu BMAD cũ) chưa rà — ngoài phạm vi, và bản thân nó tự khai là archival.

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
