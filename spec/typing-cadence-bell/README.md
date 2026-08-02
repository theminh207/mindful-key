# Typing Cadence Bell — đo nhịp gõ, ngân chuông tỉnh thức

> **Đây là nơi làm việc của cả đợt chuyển đổi này.** Kế hoạch nằm ở file này, tiến độ ghi ở
> [PROGRESS.md](PROGRESS.md). Ai làm issue nào cũng đọc file này trước và cập nhật lại sau khi xong.

| | |
|---|---|
| **Bắt đầu** | 2026-07-26 |
| **Hiến chương** | [`docs/01-intent.md`](../../docs/01-intent.md) — luật tối cao, đã sửa |
| **Issue** | [#3 → #18](https://github.com/theminh207/mindful-key/issues) trên GitHub |
| **Trạng thái** | Phase 1 xong — #6 `TypingCadence`, #7 `BellPolicy`, #8 (con sóng) đều xong. #9 (macOS mạch chuông) code xong, **CHƯA ai build/gõ thật** (máy dev không có trình biên dịch — xem PROGRESS.md). Phase 2 tiếp theo: #10 |

---

## 1. Đổi cái gì

Bỏ **Sense** (đọc nội dung câu để đoán cảm xúc) và bỏ **Pause** (gác cổng nút gửi). Thay bằng phép đo
duy nhất: **tốc độ gõ**.

```
CŨ:   Sense  →  Pause  →  Remind  →  Reflect
MỚI:  Measure  →  Bell  →  Reflect
```

- **Measure** — đo **ký tự/phút (CPM)** trên cửa sổ trượt. Chỉ đếm nhịp phím, không đọc ký tự.
- **Bell** — vượt ngưỡng thì ngân **một tiếng chuông**. Chỉ âm thanh. Không khung nổi, không chặn phím.
- **Reflect** — ghi lại mỗi lần chuông, màn soi lại đếm số lần theo thời gian.

**Ngưỡng thuộc về người dùng** — mỗi người một nhịp tay, sản phẩm không tự quyết hộ.

## 2. Vì sao đổi

Nhịp gõ đo được mà **không cần đọc chữ**. Lời hứa riêng tư từ chỗ "chúng tôi có đọc nhưng không lưu"
chuyển thành "chúng tôi không đọc" — mạnh hơn hẳn, và kiểm chứng được bằng cách nhìn vào code.

Đánh đổi phải nói thẳng: gõ nhanh **không luôn** có nghĩa tâm đang động, và sản phẩm mất khả năng
nhận ra một câu tiêu cực sắp gửi đi. Chuông là **lời mời để ý**, không phải kết luận.

## 3. Hình dung đường ống

App hiện tại như một cái máy nước: đầu nguồn là **máy đọc chữ** (chấm điểm cảm xúc), giữa đường có
**van chặn** (gác cổng lúc gửi), cuối đường là **chuông + cuốn sổ**.

Việc của đợt này: thay máy đọc chữ bằng **đồng hồ đo nhịp tay**, tháo hẳn cái van. Chuông, sổ, con
sóng, màn cài đặt **giữ nguyên** — đó là lý do đây không phải viết lại từ đầu.

## 4. Bảng tiến độ

Trạng thái: `⬜ chưa bắt đầu` · `🔄 đang làm` · `✅ xong` · `⏸ chặn`

### Phase 0 — Chốt luật (docs/ADR)

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ✅ | [#3](https://github.com/theminh207/mindful-key/issues/3) | ADR "đo nhịp gõ thay đọc cảm xúc" + 5 ADR cũ bị thay thế, ADR-0009 gỡ → ADR-0014 | — | @phatnguyen-neurond |
| ✅ | [#4](https://github.com/theminh207/mindful-key/issues/4) | Đồng bộ tầng 02/04/06/07 theo vòng lặp mới | #3 | @phatnguyen-neurond |
| ✅ | [#5](https://github.com/theminh207/mindful-key/issues/5) | Đồng bộ `docs/tasks/` + harness `.claude/` | #3 | @phatnguyen-neurond |

### Phase 1 — Bộ não C++ (`core/`)

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ✅ | [#6](https://github.com/theminh207/mindful-key/issues/6) | `core/mood/TypingCadence` — đo CPM trên cửa sổ trượt | #3 | @phatnguyen-neurond |
| ✅ | [#7](https://github.com/theminh207/mindful-key/issues/7) | `core/mood/BellPolicy` — chính sách reo chuông dùng chung 3 vỏ | #6 | @phatnguyen-neurond |
| ✅ | [#8](https://github.com/theminh207/mindful-key/issues/8) | Con sóng đổi nguồn: biên độ theo nhịp gõ | #6 | @phatnguyen-neurond |

### Phase 2 — macOS (công dân hạng nhất, chạy thật trước)

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ✅ | [#9](https://github.com/theminh207/mindful-key/issues/9) | Nối nhịp gõ vào mạch chuông | #6 #7 #8 | @phatnguyen-neurond |
| ⬜ | [#10](https://github.com/theminh207/mindful-key/issues/10) | Người dùng chọn ngưỡng tốc độ trong màn Chuông | #9 | |
| ⬜ | [#11](https://github.com/theminh207/mindful-key/issues/11) | Kho ghi số lần chuông + màn soi lại | #9 | |

### Phase 3 — Gỡ đồ cũ

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#12](https://github.com/theminh207/mindful-key/issues/12) | Gỡ nhánh gác cổng gửi tin | #9 | |
| ⬜ | [#13](https://github.com/theminh207/mindful-key/issues/13) | Gỡ nhánh đọc cảm xúc + `models/` | #8 #9 #15 #17 | |
| ⬜ | [#14](https://github.com/theminh207/mindful-key/issues/14) | Câu chữ onboarding/riêng tư + xử lý nhật ký cũ | #11 #12 | |

### Phase 4 — Windows

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#15](https://github.com/theminh207/mindful-key/issues/15) | Nối nhịp gõ vào `Bell.cpp` + icon khay | #6 #7 #8 | |
| ⬜ | [#16](https://github.com/theminh207/mindful-key/issues/16) | Chọn ngưỡng + kho DPAPI + màn soi lại | #15 | |

### Phase 5 — iOS

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#17](https://github.com/theminh207/mindful-key/issues/17) | Đo nhịp trong keyboard extension + tín hiệu chuông | #6 #7 #8 | |
| ⬜ | [#18](https://github.com/theminh207/mindful-key/issues/18) | Chọn ngưỡng qua App Group + nhật ký mặt hồ | #17 | |

## 5. Quyết định đang mở

Chưa chốt thì **đừng tự quyết trong im lặng** — hỏi chủ dự án, rồi ghi câu trả lời vào đây kèm ngày.

| # | Câu hỏi | Chốt ở | Trạng thái |
|---|---|---|---|
| Q3 | Nhịp phím lấy từ đâu — (A) từng phím ở hook bàn phím, hay (B) tại điểm kết từ qua `vOnWordCommitted`? | #6 | ✅ chốt 2026-08-01 → (A) |
| Q5 | Có đếm nhịp trong ô mật khẩu không? | #9 | ✅ chốt 2026-08-01 → không đếm |
| Q6 | Nhật ký cũ trên máy người dùng: xoá sạch hay giữ đọc song song? | #11 | ❓ chưa chốt |
| Q7 | Giữ hay bỏ check-in tự thuật "Mặt hồ đang thế nào?" (người dùng tự nói, không phải máy đoán) | #11 | ❓ chưa chốt |
| Q8 | Bàn phím iOS có phát được tiếng chuông trong app extension không? Không được thì thay bằng gì? | #17 | 🔬 đã có đáp án kỹ thuật, chờ nghe-verify tay |
| Q9 | `docs/diagrams/` **không có** sơ đồ vòng lặp lõi (issue #4 giả định là có). Có vẽ mới `Measure → Bell → Reflect` không? Và **hai node** mô hình cũ trong `workflow-macos-team.drawio` để nguyên hay sửa — dòng 115 khai *"Gác cổng… Trái tim sản phẩm"* (nặng, khai sai tính năng số một) và dòng 134 là ghi chú trạng thái đề ngày? | #4 → treo | ❓ chưa chốt |
| Q10 | **Cooldown mặc định cho chuông theo mô hình CPM là bao nhiêu?** 45 giây đang chạy ở `NudgeCoordinatorMac`/`IOS` là của **mô hình cũ** (đếm chuỗi câu căng liên tiếp) — không có lý do gì để tự động đúng cho phép đo nhịp gõ. `BellPolicy` cố ý **không** bake số nào vào core; vỏ truyền vào constructor. Chốt một lần ở #9 trước khi ba vỏ tự đoán ba con số. | #9 | 🟡 chốt tạm 2026-08-02 → **giữ 45s, dùng chung 3 vỏ** |
| Q12 | macOS `EmotionWaveView`/`EmotionRiverView` **không** gọi hàm sóng dùng chung — tự có `EaseInOut()` riêng + hai ngưỡng cứng `0.05`/`0.50`. Đổi sang gọi thẳng `CadenceWaveAmplitude`, hay giữ ngưỡng UI riêng làm tầng tách biệt? | #9 | 🟡 chốt tạm 2026-08-02 → **một nửa**: `EmotionWaveView` giữ nguyên (easing animation, không phải bản sao công thức). Nửa còn lại (`EmotionRiverView` còn vẽ từ `risk`) tách thành **Q14** |
| Q15 | **Chuông nhịp gõ KHÔNG tôn trọng giờ chuông.** `BellMac_RingForFastTyping` không gọi `isInBellRange()`, trong khi `bellTick()` và `BellMac_PlayCheckinChime` đều gọi (comment ở đó nói rõ: *"thiếu chỗ này thì sẽ kêu lúc 3h sáng giữa giờ yên lặng"*). Đây là **lỗ có sẵn**, thừa kế nguyên từ `RingForTenseStreak` — nhưng tần suất kích hoạt vừa đổi từ "3 câu căng liên tiếp" sang "mỗi phím", nên hậu quả thực tế khác hẳn. Chuông nhịp gõ có phải tôn trọng giờ chuông không? | #10 | ❓ chưa chốt — **cố ý không sửa lén ở #9** |
| Q16 | Cổng ô mật khẩu macOS dùng `IsSecureEventInputEnabled()`, trả lời *"có tiến trình nào trong hệ thống đang bật secure input"* chứ không phải *"ô đang focus có phải ô mật khẩu"*. Báo thừa thì vô hại (đúng chiều fail-closed), nhưng **báo thiếu** thì ô mật khẩu kiểu Electron/webview tự vẽ che ký tự **vẫn bị đếm nhịp**. Chấp nhận khoảng hở này, hay bịt thêm bằng Accessibility (IPC, vi phạm HĐ-3 "rẻ tới mức chạy trong hook")? | #10 | ❓ chưa chốt |
| Q14 | `EmotionRiverView` (thẻ "Ngay bây giờ", `GatekeeperCardView`) vẫn vẽ thẳng từ `risk`/`MoodStoreMac` (send-risk) — mạch CPM thật đã chạy ở #9 nhưng CHƯA cắm vào view này (#9 cố ý **không** để lại hàm đọc CPM đầu cơ — sẽ thêm khi có nơi gọi thật). Cắt sang nguồn mới bây giờ đòi schema kho mới (thuộc #11) + câu ngày-hình-dạng CPM (`MoodPhrasingMac` nay vẫn theo risk); cắt nửa vời sẽ trộn 2 thước đo trên 1 đồ thị (HĐ-8 cấm). Có nên #11 làm TRỌN việc này (đổi cả kho lẫn view), hay tách thêm 1 issue riêng? | #11 | ❓ chưa chốt |
| Q13 | **Không CI nào build target bàn phím iOS (`MindfulKeyKeyboard`)** — `macos.yml` chỉ build `-scheme MindfulKey` (app macOS). Mọi thay đổi trong `KeyboardExtension/` hiện chỉ được kiểm bằng mắt. Có thêm một job CI build extension cho iphonesimulator (`tests/ios/build_smoke.sh` đã có sẵn) không? | #17 | ❓ chưa chốt |
| Q11 | `BellPolicy` có nối vào `windows.yml` (MSVC) không? `macos.yml` đã chạy `test_bell_policy`; `windows.yml` chỉ build vỏ, không chạy test core. Nối thì bắt được lỗi portability MSVC sớm; không nối thì CI nhanh hơn. | #15 | ❓ chưa chốt |

**Đã chốt:**

> 🟡 **`chốt tạm`** = agent tự quyết trong phiên chạy tự động 2026-08-02 vì chủ dự án vắng mặt, có
> lập luận đầy đủ nhưng **chưa được chủ dự án duyệt**. Khác hẳn mục không nhãn — mục không nhãn là
> chủ dự án đã gật đầu. Xem `docs/tasks/typing-cadence-bell-execution.md` §2 cho lập luận đầy đủ.

- 🟡 2026-08-02 *(ở #9, Q10, **chốt tạm** — agent tự quyết, chờ chủ dự án gõ thật)* — **Cooldown giữ
  45 giây, dùng chung cả ba vỏ.** Không tìm thấy lý do nào cho con số 45 cũ (`git log --all -S
  "kCooldownSeconds"` chỉ ra một commit *"Initial commit"*) — nhưng giữ lại có lập luận, không phải
  quán tính: với cổng vũ trang (tụt dưới `0.9 × ngưỡng` mới được reo lại) cộng cửa sổ trượt 30 giây,
  một chu kỳ *"gõ nhanh → nghỉ tay ngắn → gõ nhanh lại"* **tự nó** đã mất ~15–30 giây mới vượt ngưỡng
  lần nữa. Nên cooldown **dưới ~20–30 giây gần như vô nghĩa** (cơ chế khác đã chặn trước), còn 45
  giây cắt thêm ~15–30 giây thật — có tác dụng, mà vẫn xa mức "ép nghỉ" hàng phút kiểu công cụ chống
  RSI, đúng tinh thần *"chuông là lời mời, không phải kết luận"*. Hằng đặt ở **core**
  (`kBellPolicyDefaultCooldownMs`) chứ không để mỗi vỏ tự viết `45000` — cùng lý do đã áp cho
  `kCadenceWaveDefaultThresholdCPM` ở #8; vỏ vẫn là nơi **truyền** giá trị vào constructor. Còn `🟡`
  vì **chưa ai gõ thật** để nghe 45 giây có đúng nhịp không. Lập luận đầy đủ + nguồn ở
  `docs/tasks/typing-cadence-bell-execution.md` §2.
- 🟡 2026-08-02 *(ở #9, Q12, **chốt tạm** — agent tự quyết, chờ chủ dự án duyệt)* — **Q12 tách làm
  hai nửa, chỉ nửa đầu chốt được ở #9:**
  1. **`EmotionWaveView.mm` giữ nguyên `EaseInOut()` + hai ngưỡng `0.05`/`0.50`.** Đọc kỹ code:
     `EaseInOut()` là easing ANIMATION (nội suy `_displayedAmplitude` theo thời gian, 500ms), khác
     hẳn việc "quy cpm/risk ra biên độ" mà `CadenceWaveAmplitude` làm — không phải bản sao của cùng
     một phép tính. `kRestThreshold`/`kLowThreshold` chỉ chọn NHÃN hiển thị
     ("phẳng lặng"/"gợn nhẹ"/"gợn sóng") cho một biên độ ĐÃ CÓ SẴN do nơi gọi truyền vào qua
     `setAmplitude:` — đây đúng là "tầng khác" mà issue #9 cho phép giữ lại (phương án b). Thêm
     nữa: `git grep setAmplitude` cho thấy `EmotionWaveView` HIỆN KHÔNG có nơi gọi sống nào nuôi nó
     bằng risk/cpm thật — nơi duy nhất là `BellSettingsView.mm` (bản demo, biên độ HARDCODE
     0.2/0.5/0.85 theo mức Độ nhạy), nên không có rủi ro trôi lệch NGAY BÂY GIỜ.
  2. **`EmotionRiverView` (thẻ "Ngay bây giờ") VẪN vẽ từ `risk`/`MoodStoreMac` — CHƯA cắt sang
     CPM trong #9.** Đây là nơi Q12 mô tả đúng: nguồn sống thật là send-risk. Nhưng cắt sang CPM
     ĐÚNG CÁCH đòi đổi luôn schema kho (`MoodStoreMac`, việc của #11) + hàm ngày-hình-dạng CPM
     (`MoodPhrasingMac_DayShapeSentence` nay nhận `risk`, chưa có bản CPM) — cắt NỬA VỜI (chỉ đổi
     phần "vệt sống" trong RAM, giữ nguyên phần "nền quá khứ" đọc từ kho risk) sẽ VẼ CHUNG một đồ
     thị 2 thước đo khác nhau, đúng điều HĐ-8 cấm ("Không trộn thước đo"). Quyết định: **để nguyên
     cho tới #11**, ghi lại thành Q14 (bảng trên) để không mất dấu — #11 vốn đã bị #9 chặn và là
     nơi đúng để làm TRỌN cả kho lẫn view cùng lúc. **Vì sao `chốt tạm`:** đây là agent tự cân nhắc
     đánh đổi (rủi ro trộn thước đo so với đòi hỏi "phải đổi nguồn"), không phải chủ dự án tự chọn.

- 🟡 2026-08-02 *(ở #8, Q4, **chốt tạm** — agent tự chọn công thức + hằng số, chờ chủ dự án nhìn
  sóng thật duyệt)* — **Quy CPM về biên độ sóng bằng bão hoà tiệm cận Hill n=2, đặt trong
  `core/mood/CadenceWaveAmplitude(cpm, thresholdCpm)`** — nhận **hai tham số thô** (không để vỏ tự
  chia `cpm/threshold`): vùng chết là **tỉ lệ** `kCadenceWaveDeadZoneRatio = 0.3` so với ngưỡng
  (không phải một giá trị CPM tuyệt đối, để tự co giãn theo 3 mức ngưỡng người dùng chọn); trên
  vùng chết, biên độ = `s² / (s² + k)` với `s = cpm/threshold - 0.3`, `k = kCadenceWaveSaturationK
  = 0.1225`. Ba phương án khác đã cân nhắc (tuyến tính kẹp, smoothstep đỉnh-tại-ngưỡng) đều **kẹp
  cứng biên độ = 1.0 ngay tại CPM == ngưỡng** — nghĩa là 400/500/800/2000 CPM (ngưỡng 400) trông y
  hệt nhau trên sóng, mất đúng thứ thông tin "gợn nhẹ khác dậy sóng" mà tính năng này tồn tại vì
  nó. Bão hoà tiệm cận giữ đơn điệu liên tục xuyên suốt, không bao giờ "phẳng lì" ở 1.0: 800 CPM
  (~0.959) và 2000 CPM (~0.995) vẫn phân biệt được, chỉ khác biệt nhỏ dần — mất thông tin có chủ
  đích ở vùng xa, không phải lỗi. **Vì sao chỉ là `chốt tạm`:** hằng `k = 0.1225` suy ngược từ mốc
  "biên độ 0.80 đúng tại ngưỡng" ở `docs/tasks/MOOD-WAVE-MECHANISM.md:192` — nhưng chính tài liệu
  đó ghi rõ ba mốc 0.12/0.45/0.80 là "mốc hình học đang dùng, KHÔNG PHẢI kết quả của công thức đã
  chốt", tức là mục tiêu hiệu chỉnh chứ chưa có ai gõ thật để kiểm. Lập luận đầy đủ + bảng 3
  phương án + nguồn: `docs/tasks/typing-cadence-bell-execution.md` §2 "2026-08-02 — Q4".
- 2026-08-02 *(ở #7)* — **`BellPolicy` là LỚP, không phải hai hàm tự do.** Hợp đồng HĐ-2 cũ và
  issue #7 đều phác thảo `BellPolicy_ShouldRing(...)` + `BellPolicy_NoteRung(...)` (hàm tự do).
  Cooldown + trạng thái chống rung là **state**; hàm tự do buộc giữ state đó trong biến toàn cục,
  khiến ba vỏ dùng chung một biến (test dính nhau, không dựng được nhiều thể hiện độc lập) — đúng
  tiền lệ đã chốt cho `TypingCadence` ở #6 (Q3). Gộp thêm "hỏi" và "báo đã reo" thành **một** hàm
  `evaluate()` trả thẳng `bool` (bỏ luôn `struct BellDecision` issue đề xuất, vì `cpmAtDecision` là
  thông tin nơi gọi đã có sẵn) — loại hẳn kiểu lỗi "vỏ hỏi rồi quên báo lại". `docs/04-contracts.md`
  HĐ-2 đã cập nhật khối code + giải trình.
- 🟡 2026-08-02 *(ở #7, **chốt tạm** — agent tự chọn con số, chờ chủ dự án duyệt)* — **Chống rung
  dùng biên trễ (hysteresis) 10% dưới ngưỡng**, không phải
  "tụt xuống dưới ngưỡng" đơn thuần (margin 0). Sau khi đã reo, CPM phải tụt xuống dưới
  `thresholdCpm * 0.9` mới được coi là một đợt vượt ngưỡng mới. Lý do chọn có biên thay vì margin
  0: CPM dao động sát ngưỡng là chuyện thường (nhịp gõ người không phẳng lì); với margin 0, một cú
  tụt rất nhỏ (1-2 CPM, đúng mức nhiễu một phím trên cửa sổ 30 giây) đã đủ "tái vũ trang", khiến
  hai gợn nhịp sát nhau vẫn tách thành hai đợt và reo hai lần cách nhau vài giây — đúng thứ chống
  rung phải ngăn. 10% cho ngưỡng mặc định 400 nghĩa là phải tụt xuống dưới 360 (~20 phím/30 giây)
  mới tính là đã chậm tay lại. Hằng số phơi ra làm `extern const double kBellPolicyHysteresisFactor`
  để test khoá được bằng số thật, không phải hằng chết chôn trong `.cpp`. **Vì sao là `chốt tạm`:**
  con số 10% suy từ lập luận về mức nhiễu, **chưa có ai gõ thật để kiểm** — chỉ người dùng thật mới
  biết 360 CPM có phải mốc "đã chậm tay lại" đúng hay không.
- 2026-08-02 *(ở #7)* — **Cơ chế "đã vũ trang" (armed) tách biệt hoàn toàn khỏi cooldown.** Một
  tràng gõ nhanh dài liên tục (CPM không bao giờ tụt) chỉ reo **đúng một lần** dù cooldown hết hạn
  giữa chừng — vì cổng "đã vũ trang" (cổng 3) chặn trước khi cổng cooldown (cổng 6) kịp được xét.
  Nếu chỉ dựa vào cooldown (không có cổng vũ trang riêng), streak dài hơn thời lượng cooldown sẽ
  reo lặp lại nhiều lần — sai với checklist issue #7 ("reo đúng 1 lần cho một tràng gõ nhanh dài
  liên tục").
- 🟡 2026-08-02 *(ở #7, **chốt tạm** — agent tự chọn hướng, chờ chủ dự án duyệt)* — **Ca biên
  CPM == ngưỡng: CÓ reo** (so sánh là `>=`, không phải `>`). Ngưỡng do chính người dùng đặt; "đạt
  đúng mức mình đặt" phải tính là đã tới, không phải còn thiếu một chút. Hướng ngược lại (`>`,
  nghiêng về im lặng) cũng bảo vệ được bằng tinh thần "chuông là lời mời, không phải kết luận" —
  nên đây là chỗ chủ dự án nên tự chọn.
- 2026-08-02 *(ở #7)* — **Tắt chuông (`enabled=false`) và tạm hoãn (`snoozed=true`) KHÔNG tiêu lượt
  vũ trang.** Nếu CPM vượt ngưỡng trong lúc tắt/hoãn, cơ hội reo vẫn còn nguyên khi bật/hết hoãn —
  không phải chờ CPM tụt xuống rồi vượt lại từ đầu. Việc bật/tắt là quyết định của người dùng, tách
  biệt khỏi tín hiệu nhịp gõ.
- 2026-08-01 *(ở #6)* — **CPM = (số nhịp trong cửa sổ) / (độ dài cửa sổ tính bằng phút)** — chia
  cho **độ dài cửa sổ**, KHÔNG phải cho khoảng giữa nhịp đầu và nhịp cuối. Chia theo khoảng giữa
  hai nhịp thì gõ 2 phím cách nhau 100ms ra **1200 CPM** → chuông reo oan ngay phím thứ hai. Chia
  cho cửa sổ thì 2 phím trong 30 giây ra đúng 4 CPM, và muốn chạm ngưỡng 400 phải gõ **thật 200
  phím trong 30 giây** — nên **không cần** thêm luật "tối thiểu N phím" như issue #6 gợi ý. Đánh đổi
  cố ý: 30 giây đầu sau khởi động báo **thấp** hơn thực tế (cửa sổ chưa đầy), tức nghiêng về **im
  lặng**. Đây là bất biến **xuyên issue** — cả #7 (`BellPolicy`) lẫn #8 (biên độ sóng) đều tiêu thụ
  con số CPM này, nên đổi cách chia là đổi nghĩa của mọi thứ phía sau.
- 2026-08-01 *(Q3, ở #4)* — **Nhịp phím lấy từng phím một ở hook bàn phím**, không tái dùng
  `vOnWordCommitted`. API là `TypingCadence::registerKeystroke(int64_t nowMs)` — **không tham số chuỗi ở
  bất kỳ đâu** (chữ ký chốt lại ở #6: dạng lớp thay vì hàm tự do, để test dựng được nhiều
  thể hiện độc lập; phần bất biến — chỉ nhận dấu thời gian — không đổi). Lý do: README §1 viết "chỉ đếm nhịp phím, không đọc ký tự" và §2 nói lời hứa riêng tư
  phải *kiểm chứng được bằng cách nhìn vào code*. Nuôi từ `vOnWordCommitted(const wstring& word)`
  thì lớp nhịp vẫn **nhận** chuỗi dù chỉ dùng `.length()` — người review đọc code vẫn thấy lớp mood
  cầm text, lời hứa tụt xuống "có nhận nhưng hứa không dùng". Phụ: hook cho tín hiệu mượt (gõ giữa
  từ dài vẫn có nhịp) và Telex `aa`→`â` tính 2 nhịp, đúng nghĩa "nhịp tay". Đánh đổi bị bỏ: phương
  án (B) ít sửa hơn vì 3 vỏ đã nối sẵn callback đó. Thành hợp đồng **HĐ-1** ở `docs/04-contracts.md`.
- 2026-08-01 *(Q5, ở #4)* — **Không đếm nhịp trong ô mật khẩu**, mặc định **fail-closed** (không
  xác định được thì coi là ô mật khẩu). Giữ nguyên hành vi Windows đang có (`MoodWatch.cpp:47` đã
  loại ô mật khẩu khỏi `MoodBuffer`) và áp cho cả 3 vỏ — macOS hiện **chưa có**, phải bổ sung ở #9.
  Hai lý do độc lập: chuông reo giữa lúc gõ mật khẩu là quấy rầy thuần tuý; và chuỗi thời điểm bấm
  phím lúc nhập mật khẩu là dữ liệu nhạy cảm, không thu thập là cách duy nhất chắc chắn không rò.
  Thành hợp đồng **HĐ-4** ở `docs/04-contracts.md`.
- 2026-08-01 *(ở #5)* — **Khôi phục 4 file `.claude/agents/`** thay vì để chúng bị xoá. Tree bàn
  giao có cả 4 bị xoá (chưa commit), nhưng `mindful-keyboard-harness/SKILL.md` bước 2 **bắt buộc**
  đọc `.claude/agents/{name}.md` để lấy vai trò khi `subagent_type` không tự nhận diện, và 3 chỗ
  khác cũng trỏ tới — xoá là gãy harness. Giữ tên `mood-layer-agent`, chỉ viết lại mandate theo đo
  nhịp. Ngược lại, `.claude/rules-archive/` (7 file) **giữ nguyên việc xoá**: grep toàn repo không
  ai trỏ tới.
- 2026-08-01 *(ở #5)* — Skill `.claude/skills/mood-sentiment-layer/` **đổi tên thành
  `typing-cadence-layer`**, viết lại toàn bộ mandate theo đo nhịp, thay vì gỡ hẳn. Giữ chỗ đứng của
  lớp này trong bảng 4 chuyên gia để `mood-layer-agent` còn skill chuyên biệt để trỏ tới. Thi công
  ở #5.
- 2026-07-26 — Bỏ **hẳn** lớp sentiment, không giữ lại để ghi nhật ký.
- 2026-07-26 — Đơn vị đo là **CPM (ký tự/phút)**, không phải WPM. Telex/VNI gõ dấu tốn thêm phím nên đếm "từ" bị méo.
- 2026-07-27 *(Q1, ở #3)* — Bốn mức ngưỡng, mặc định **Rất nhanh = 400 CPM**: `Nhanh 300` ·
  `Rất nhanh 400` · `Cực nhanh 500` · `Tắt chuông`. Tên mức mô tả **nhịp tay**, không mô tả tâm
  người gõ — cấm mọi chữ quy về trạng thái tâm ("bình tĩnh", "mất kiểm soát"…). Chỗ nào hiện tên
  mức thì hiện kèm con số CPM, để đọc ra đây là phép đo chứ không phải lời nhận xét.
- 2026-07-27 *(Q2, ở #3)* — **Cửa sổ trượt 30 giây.** Ngắn hơn thì một tràng gõ dồn rồi nghỉ cũng
  đủ vượt ngưỡng; dài hơn thì chuông tới sau khi nhịp đã lắng.
- 2026-07-27 *(ở #3)* — `ADR-0009` **gỡ hẳn** khỏi `docs/` thay vì đánh dấu bị thay thế, vì toàn bộ
  thân nó lập luận cho gác cổng gửi tin — thứ đã bị xoá khỏi sản phẩm. Kết luận (mandate iOS hẹp)
  viết lại với lý lẽ mới ở `ADR-0014`. Là **ngoại lệ có ghi chú ở index**, không phải tiền lệ;
  mặc định vẫn giữ file và đánh dấu *Bị thay thế*.
- 2026-07-27 *(ở #3)* — `ADR-0011` (kho Windows DPAPI) cũng bị thay thế: schema "bất biến" của nó
  chốt cột `send_risk`, cột này chết theo mô hình mới. Schema thật chốt lại ở #11.

## 6. Ba cái bẫy đã biết trước

**Đừng để một mảnh logic tồn tại hai bản.** Lexicon send-risk từng có 2 bản ở macOS và iOS rồi trôi
lệch thật (macOS coi dấu câu là dấu tách từ, iOS thì không). Chính sách chuông hiện cũng đang có 2
bản chép tay — `NudgeCoordinatorIOS.h` tự thú là "sao y bản chính từ macOS". Vì vậy #7 gom về `core/`
ngay từ đầu, trước khi Windows kịp thành bản thứ ba.

**Lời hứa riêng tư chỉ thật khi code biến mất.** Hiến chương ghi "không đọc nội dung" — chừng nào
`SendRiskAnalyzer` còn trong repo và còn được nạp vào app, câu đó là quảng cáo. #13 quan trọng nhất
Phase 3, nhưng phải đợi cả 3 vỏ chuyển xong, gỡ sớm là vỡ build.

**Người dùng cũ sẽ mất tính năng.** Bản đang phát hành ngoài đời có gác cổng gửi tin và nhật ký theo
thước đo cũ. #14 lo chuyện nói thật. Khuyến nghị: xoá nhật ký cũ chứ đừng trộn — điểm cũ đo bằng
thước khác, vẽ chung một biểu đồ là nói dối người dùng.

## 7. Luật cập nhật — làm xong issue thì phải làm gì

Mỗi lần một issue đóng lại, **cùng trong PR đó** (không để dồn):

1. Đổi ô trạng thái ở [§4](#4-bảng-tiến-độ) sang `✅` và điền tên người làm.
2. Thêm một mục vào [PROGRESS.md](PROGRESS.md): ngày · issue · làm gì · **quyết định đã chốt** ·
   chỗ nào phải đoán.
3. Có quyết định nào ở [§5](#5-quyết-định-đang-mở) được chốt → chuyển xuống mục "Đã chốt" kèm ngày
   và lý do. Đây là thứ session sau và đồng đội sau đọc để khỏi hỏi lại.
4. Phát sinh câu hỏi mới → thêm vào bảng §5, đừng giấu trong đầu.
5. Chỗ nào phải **đoán** vì tài liệu không nói rõ → ghi thêm vào
   [`docs/tasks/FRICTION-LOG.md`](../../docs/tasks/FRICTION-LOG.md), đúng chỗ nó sinh ra để ghi.

Cổng chất lượng trước khi coi là xong (theo `CLAUDE.md`): `make test` xanh · `make build` sạch, không
thêm warning · `make brand-lint` 0 vi phạm · CI xanh.

### Chạy cổng đó ở đâu — khi máy dev là Windows

Máy dev hiện tại **không có toolchain**: `g++`, `clang++`, `cl`, `make`, `cmake` đều thiếu (chỉ có
`py -3`). Nên **CI là cổng kiểm chứng thật**, không phải máy local:

| Cổng | Local | CI |
|---|---|---|
| `make test` | ❌ | ⚠️ `macos.yml` chỉ chạy `tests/core/build.sh` + `test_engine` — **không** chạy `test-macos`/`test-ios` |
| `make build` (macOS) | ❌ | ✅ `macos.yml` — xcodebuild, ad-hoc sign |
| Build Windows | ❌ | ✅ `windows.yml` — MSVC v143, cả Debug lẫn Release |
| `make brand-lint` | ✅ `PYTHONIOENCODING=utf-8 py -3 scripts/brand_lint.py` | ✅ `brand-lint.yml` |

**Luật:** không ghi "đã test" cho thứ chỉ CI chạy. PR nào đụng code phải **đợi CI xanh** trước khi
review. Phần `test-macos`/`test-ios` không có ai chạy tự động — muốn chắc thì phải có người mở máy
macOS chạy tay, và nói rõ trong PR là chưa chạy.
