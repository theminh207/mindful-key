# Nhật ký thi công đợt Typing Cadence Bell (#4 → #18)

- **Status:** in-progress · **Created:** 2026-08-01 · **Updated:** 2026-08-01

> ⚠️ **File này KHÔNG phải nguồn sự thật.** Kế hoạch, bảng tiến độ, quyết định đã chốt và câu hỏi
> còn mở đều sống ở **[`spec/typing-cadence-bell/README.md`](../../spec/typing-cadence-bell/README.md)**;
> nhật ký theo ngày ở [`PROGRESS.md`](../../spec/typing-cadence-bell/PROGRESS.md). Đọc hai file đó
> trước. File này chỉ giữ **hai thứ không có chỗ nào khác chứa**: thứ tự thi công đã hiệu chỉnh, và
> kho kết quả research. Thấy chỗ nào ở đây mâu thuẫn với `spec/` → **`spec/` đúng**, sửa file này.

## 1. Một hiệu chỉnh so với thứ tự Phase ở README §4

Phase 3 **không chạy liền sau Phase 2** như số thứ tự gợi ý. Phải tách đôi:

- **#12** (gỡ gác cổng) chỉ chặn bởi `#9` → làm được ngay sau Phase 2.
- **#13** (gỡ lớp đọc cảm xúc) chặn bởi `#8 #9 #15 #17` → phải đợi **cả Windows và iOS** chuyển
  xong. Gỡ sớm là vỡ build hai vỏ, đúng cái bẫy README §6 cảnh báo (*"gỡ sớm là vỡ build"*).
- **#14** (câu chữ onboarding/riêng tư) chặn bởi `#11 #12`, nhưng đoạn hứa *"không đọc nội dung"*
  chỉ nói được sau khi #13 xong — nên xếp cùng #13.

Tức Phase 3 kẹp Phase 4 và Phase 5 ở giữa: `… → #12 → Phase 4 → Phase 5 → #13 #14`.
Mọi thứ còn lại theo đúng README §4.

## 1b. Vòng chạy 2026-08-02 — thi công #7 → #18 bằng agent

Chủ dự án giao chạy tự động cả 12 issue còn lại trong một phiên, mỗi issue **một agent thi công
riêng → PR → một agent review riêng → CI xanh → merge → đóng issue**, và cập nhật
`spec/typing-cadence-bell/README.md` §4 + `PROGRESS.md` **trong cùng PR** (luật README §7).

**Thứ tự thi công** theo §1 ở trên (không theo số thứ tự issue):

`#7 → #8 → #9 → #10 → #11 → #12 → #15 → #16 → #17 → #18 → #13 → #14`

| # | Issue | Agent thi công | Nhánh | PR | CI | Review | Xong |
|---|---|---|---|---|---|---|---|
| 1 | #7 BellPolicy | `mood-layer-agent` | `feat/core-bell-policy` | [#24](https://github.com/theminh207/mindful-key/pull/24) | ✅ 4/4 | FAIL → sửa 3 lỗi chặn → PASS | |
| 2 | #8 Biên độ sóng | `mood-layer-agent` | | | | | |
| 3 | #9 macOS mạch chuông | `platform-shell-agent` | | | | | |
| 4 | #10 macOS ngưỡng | `platform-shell-agent` | | | | | |
| 5 | #11 macOS kho + soi lại | `platform-shell-agent` | | | | | |
| 6 | #12 Gỡ gác cổng | `platform-shell-agent` | | | | | |
| 7 | #15 Windows mạch chuông | `platform-shell-agent` | | | | | |
| 8 | #16 Windows ngưỡng + kho | `platform-shell-agent` | | | | | |
| 9 | #17 iOS đo nhịp + chuông | vỏ iOS | | | | | |
| 10 | #18 iOS App Group | vỏ iOS | | | | | |
| 11 | #13 Gỡ đọc cảm xúc | `mood-layer-agent` | | | | | |
| 12 | #14 Câu chữ + nhật ký cũ | docs | | | | | |

**Luật của phiên này (chủ dự án vắng mặt tới 9h):**

1. **Cổng thật là CI.** Máy dev không có `g++`/`clang++`/`cl`/`make`/`cmake` (chỉ `py -3`). PR nào
   đụng code phải **đợi CI xanh** rồi mới review/merge. Không ghi "đã test" cho thứ chỉ CI chạy.
2. **Câu hỏi mở không được tự chốt trong im lặng** (README §5). Nhưng chủ dự án đã giao *"bạn tự
   research và làm đi"* và đang vắng, nên cách hoà giải: mỗi câu trả lời phải có **research + lập
   luận + nguồn**, ghi vào §2 file này và vào README §5 với nhãn **`🟡 chốt tạm`** — để buổi review
   9h lật lại được. Không có nhãn nào bị chốt cứng sau lưng chủ dự án.
3. Agent review là **agent sạch**, không thấy quá trình thi công — để nó đọc diff bằng mắt người
   lạ, không bị mồi bởi lý lẽ của người viết.

**Câu hỏi mở còn chặn đường:** Q4 (chặn #8) · Q6, Q7 (chặn #11). Q8 đã có đáp án ở §2.

## 2. Research Findings

Kho kết quả research. Giữ nguyên văn — đây là thứ session sau đọc để khỏi tra lại.

### 2026-08-02 — Hai con số `🟡 chốt tạm` ở #7 (BellPolicy)

> Không phải research ngoài, mà là **lập luận nội bộ của agent thi công**. Ghi ở đây vì luật §1b:
> agent tự quyết thì phải để lại vết đọc được, không được lẫn vào danh sách chủ dự án đã duyệt.

**1. Biên trễ chống rung = 10% dưới ngưỡng (`kBellPolicyHysteresisFactor = 0.9`).**

Vấn đề thật: chỉ đòi "tụt xuống dưới ngưỡng" (biên trễ 0) thì một cú tụt **1–2 CPM** đã đủ tái vũ
trang. Trên cửa sổ 30 giây, 1 CPM = 0.5 phím — tức **đúng mức nhiễu của một phím lẻ**. Hệ quả: hai
gợn nhịp sát nhau tách thành hai đợt, chuông reo hai lần cách nhau vài giây.

10% ở ngưỡng mặc định 400 → phải tụt dưới 360, tức mất thật ~20 phím/30 giây. Đủ xa nhiễu một phím,
vẫn đủ gần để phản ứng kịp khi người dùng thật sự chậm tay lại.

**Vì sao chỉ là `chốt tạm`:** con số suy từ lập luận về mức nhiễu, **chưa ai gõ thật để kiểm**. Chỉ
người dùng thật mới biết 360 CPM có phải mốc "đã chậm tay lại" đúng không. Hằng số đã được phơi ra
thành `extern const` nên đổi nó là đổi một dòng, và test khoá bằng số thật.

**2. Ca biên `cpm == threshold` → CÓ reo (`>=`).**

Lý lẽ chọn: ngưỡng do **chính người dùng** đặt, nên "đạt đúng mức mình đặt" phải tính là đã tới.

**Vì sao chỉ là `chốt tạm`:** hướng ngược lại (`>`) cũng bảo vệ được, bằng đúng tinh thần *"chuông
là lời mời để ý, không phải kết luận"* — nghiêng về im lặng khi lưỡng lự. Hai hướng đều có lý; đây
là chỗ chủ dự án nên tự chọn chứ không phải agent.

### 2026-08-02 — Q4: quy CPM về biên độ con sóng `~` bằng công thức nào, đặt ở đâu?

> Nguồn: `task-researcher`. Confidence: **high** (hình học + hợp đồng kiểm được trong repo) ·
> hằng số bão hoà là lựa chọn thiết kế mới nên **chưa có nguồn ngoài** — xem caveat.
> **Trạng thái: 🟡 chốt tạm, thi công ở #8, chờ chủ dự án nhìn sóng thật.**

**Đáp án:** đặt phép quy đổi **trong `core/mood`**, dưới dạng hàm nhận **cả `cpm` lẫn `thresholdCpm`
làm hai tham số riêng** — **không** để vỏ tự chia `cpm/threshold` rồi mới truyền vào. Lý do là HĐ-6
và README §6 cấm đúng kiểu logic-hai-bản này.

**Hình học hiện tại** (`EmotionWaveAmplitude.cpp:12-24`): `risk < 0.3` → 0 (mặt hồ phẳng);
`risk ∈ [0.3, 1.0]` → smoothstep `t²(3−2t)` với `t=(risk−0.3)/0.7`; `risk ≥ 1.0` → kẹp cứng 1.0.
Hàm **một tham số** vì `risk` tự nó đã bị chặn trong `[0,1]`. **CPM không có trần tự nhiên như vậy**
— nó có ngưỡng người dùng chọn làm mốc, và bão hoà cơ học ~2048. Đây là lý do **không thể chỉ đổi
tên biến** `risk` → `cpm`.

**Ba phương án** (bảng mốc với `threshold = 400`):

| CPM | (A) tuyến tính kẹp | (B) smoothstep, đỉnh = ngưỡng | (C) bão hoà Hill n=2 — **đề xuất** |
|---|---|---|---|
| 0 | 0.000 | 0.000 | 0.000 |
| 100 | 0.000 | 0.000 | 0.000 |
| 300 | 0.643 | 0.708 | 0.623 |
| 400 (= ngưỡng) | 1.000 | 1.000 | 0.800 |
| 500 | 1.000 | 1.000 | 0.881 |
| 800 | 1.000 | 1.000 | 0.959 |
| 2000 | 1.000 | 1.000 | 0.995 |

(A) có góc gãy đạo hàm hai đầu → không "mượt" đúng nghĩa đã cam kết. (A) và (B) đều **kẹp cứng ngay
tại ngưỡng**: 400, 500, 800, 2000 CPM trông **y hệt nhau** trên sóng. Với một tính năng mà điểm hay
là "gợn nhẹ" khác "dậy sóng", đặt đỉnh ngay tại ngưỡng là **lỗi thiết kế**, không phải đánh đổi.

**Khuyến nghị (C):**

```cpp
// core/mood/CadenceWaveAmplitude.h
extern const double kCadenceWaveDeadZoneRatio;   // 0.3 — TỈ LỆ so với ngưỡng, không phải giá trị tuyệt đối
double CadenceWaveAmplitude(double cpm, double thresholdCpm);
```

```cpp
const double kCadenceWaveDeadZoneRatio = 0.3;
static const double kCadenceWaveSaturationK = 0.1225;  // hiệu chỉnh để amplitude = 0.80 đúng tại cpm == threshold

double CadenceWaveAmplitude(double cpm, double thresholdCpm) {
    double t = thresholdCpm > 0.0 ? thresholdCpm : 1.0;   // kẹp chia-0, cùng phong cách TypingCadence
    double s = cpm / t - kCadenceWaveDeadZoneRatio;
    if (s <= 0.0) return 0.0;
    return (s * s) / (s * s + kCadenceWaveSaturationK);
}
```

Cả hai tham số là `double` → lọt allowlist HĐ-1. Đổi xong phải chạy `--update-pin`.

**Vì sao không thể trôi lệch giữa 3 vỏ:** phép chia, hằng vùng chết, và hằng bão hoà đều nằm **trong
thân hàm C++ dùng chung**. Vỏ chỉ đọc CPM + ngưỡng rồi gọi thẳng — không còn phép tính nào để mỗi
vỏ tự diễn giải.

**Ca "Tắt chuông":** hàm **luôn** đòi một `thresholdCpm` cụ thể, không có nhánh "off" trong core.
"Tắt chuông" chỉ tắt **tiếng**, **không** được làm biến mất mốc quy đổi của sóng — sóng là nhận diện
lõi, độc lập với việc chuông có kêu hay không (§4.1). Quy tắc: mỗi vỏ giữ **hai giá trị tách biệt**
— `bellEnabled` (bool) và `waveReferenceThresholdCpm` (double, mặc định 400); tắt chuông thì
`bellEnabled = false` còn ngưỡng tham chiếu **giữ nguyên giá trị đã chọn lần cuối**. Chi tiết lưu
trữ thuộc #10/#16/#18.

**Ca "CPM vượt ngưỡng rất xa":** với (C) đây là **mất thông tin có chủ đích, không phải lỗi** — 800
(0.959) và 2000 (0.995) vẫn khác nhau về số, chỉ là khác biệt nhỏ dần. Không bao giờ "phẳng lì" ở
1.0.

**Tên mới:** `core/mood/CadenceWaveAmplitude.{h,cpp}` (issue #8 đề xuất `WaveAmplitude` hoặc
`CadenceWaveAmplitude`) — chọn bản dài vì nó nói rõ nguồn nuôi là **nhịp gõ**, khớp họ tên
`TypingCadence*`.

**Caveat phải xử ở #8:**

1. Hằng `k = 0.1225` suy ngược từ mốc **0.80 tại đúng ngưỡng**, lấy ở `MOOD-WAVE-MECHANISM.md:192`.
   Nhưng chính tài liệu đó ghi rõ ba mốc 0.12/0.45/0.80 là *"mốc hình học đang dùng, không phải kết
   quả của công thức đã chốt"*. Tức nó là **mục tiêu hiệu chỉnh**, không phải bằng chứng. **Cần chủ
   dự án nhìn sóng thật** ở vài mốc CPM trước khi khoá `k`.
2. Quy tắc "Tắt chuông không ảnh hưởng biên độ sóng" hiện **chưa có chỗ neo trong hợp đồng** — nên
   ghi một dòng vào HĐ-3 khi #8 đóng, trước khi ba vỏ tự đoán.

**Nguồn:** [Smoothstep — Wikipedia](https://en.wikipedia.org/wiki/Smoothstep) ·
[smoothstep — docs.gl GLSL 4](https://docs.gl/sl4/smoothstep) ·
[Everything About Audio Metering — SonicScoop](https://sonicscoop.com/everything-need-know-audio-meteringand/)
(nguyên lý ballistics: đồng hồ đo thời gian thực không hard-clamp theo bậc) ·
repo: `core/mood/EmotionWaveAmplitude.cpp:1-24`, `core/mood/TypingCadence.h:45-119`,
`docs/04-contracts.md` HĐ-1/HĐ-3/HĐ-6/HĐ-8, `docs/01-intent.md` §4.1,
`docs/tasks/MOOD-WAVE-MECHANISM.md:165-202`, `scripts/check_hd1.py:70-119`.

### 2026-08-01 — Q8: iOS keyboard extension có phát được tiếng chuông không?

> Nguồn: `task-researcher`. Confidence: **high** (đường audio) · **medium** (đường haptic).

**Đáp án:** **Có** — `AudioServicesPlaySystemSound` phát được trong extension
`com.apple.keyboard-service`, nhưng **bắt buộc Full Access**. Full Access ở repo này **đã bật sẵn**
vì lý do khác (macro + App Group), nên chuông âm thanh **không tạo thêm chi phí riêng tư mới**.

**Repo đã tự trả lời bằng code sản xuất:** `platforms/apple/ios/KeyboardExtension/NudgeCoordinatorIOS.mm:29-42`
đã gọi cả `UIImpactFeedbackGenerator` lẫn `AudioServicesPlaySystemSound(1104)` trong đúng loại
extension này; `Info.plist:36` có `RequestsOpenAccess = true`.

**Khuyến nghị cho #17:** tái dùng cặp **haptic (`UIImpactFeedbackGenerator` Medium) +
`AudioServicesPlaySystemSound`** theo đúng pattern `mk_triggerRingEffect()` đã có — chỉ **đổi nơi
gọi** từ `NudgeCoordinatorIOS_RegisterSentenceRisk` sang `BellPolicy`/`TypingCadence`, không viết
lại.

**Tránh `AVAudioSession`/`AVAudioPlayer`:** có báo cáo `setActive` ném lỗi `561015905` trong
extension **kể cả khi Full Access đã bật** — [Apple Developer Forums 709107](https://developer.apple.com/forums/thread/709107).
`AudioServicesPlaySystemSound` không đụng `AVAudioSession` nên an toàn hơn.

**Nguồn Apple:** [App Extension Programming Guide — Custom Keyboard](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)
— `RequestsOpenAccess = NO` (mặc định) thì keyboard **không** được phát âm thanh gì, kể cả
`playInputClick`; chỉ `YES` mới có *"Ability to play audio"*.

**Ba caveat phải xử ở #17:**

1. `SystemSoundID` **không** phải API công khai có catalog chính thức. Giá trị `1104` đang gắn nhãn
   `[Inference]`, **chưa nghe-verify trên máy thật**. Phải nghe tay trên iPhone thật (Simulator
   không dựng được custom keyboard — `FRICTION-LOG.md` 2026-07-13) và chọn tiếng **trung tính,
   ngắn**, không giống âm báo lỗi hệ thống.
2. Giả định *"haptic cũng cần Full Access"* **chưa có trích dẫn Apple chính thức** — chỉ có bằng
   chứng cộng đồng cộng code repo đang chạy song song với Full Access bật. Ở #17 thử tắt Full Access
   xem haptic còn kêu không, ghi kết quả vào `FRICTION-LOG.md`.
3. Dòng "Full Access" ở `FRICTION-LOG.md` (2026-07-13) vẫn **mở**. #17 đi trên giả định Full Access
   tiếp tục tồn tại vì #18/macro. Chủ dự án veto Full Access thì **cả audio lẫn haptic sập theo**,
   chỉ còn phương án tín hiệu thị giác.

**Đường lui không cần quyền:** một xung ngắn trung tính trên chính view `~` sẵn có, chạy 100% trong
sandbox mặc định. Nhưng đây là **quyết định sản phẩm** (đánh đổi UX, dễ bị bỏ lỡ), không phải giới
hạn kỹ thuật — để chủ dự án chốt ở #17. Cẩn thận không biến nó thành "đèn đỏ/xanh" (hiến chương
cấm): chỉ một nhịp trung tính, không đổi màu theo mức.
