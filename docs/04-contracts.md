# 04 — Contracts

> Các bất biến **đang có hiệu lực** mà mọi vỏ phải giữ. Khác với [tầng Decisions](03-decisions/):
> ADR ghi lại một lựa chọn trong quá khứ và không sửa nữa; hợp đồng ràng buộc code hiện tại và vi
> phạm nó là **bug**, không phải khác biệt phong cách.
>
> Mỗi hợp đồng ở đây được viết sao cho **soi được bằng `grep`**. Đó là tiêu chuẩn để một luật được
> nhận vào tầng này: nếu không kiểm được bằng máy hoặc bằng một lệnh tìm kiếm, nó thuộc tầng khác.
>
> ⚠️ **Tầng này là quy phạm, không phải mô tả hiện trạng.** Theo [`docs/README.md`](README.md),
> tầng 01–04 là nguồn đúng và **code phải sửa theo**. Các hợp đồng dưới đây đã chuyển sang vòng lặp
> `Measure → Bell → Reflect`; code ba vỏ đang được chuyển theo ở
> [`spec/typing-cadence-bell/`](../spec/typing-cadence-bell/README.md) (issue #6 → #18). Chỗ nào
> code chưa khớp là **nợ đã có lịch trả**, không phải hợp đồng sai.

---

## Bảng đánh số lại (2026-08-01, issue #4)

Đợt chuyển mô hình **gỡ 1 hợp đồng, thêm 3 hợp đồng mới, và giữ 1 số nhưng đổi nghĩa** — sáu hợp
đồng thành tám, nên **số thứ tự đã dịch**. Tài liệu và ADR viết trước 2026-08-01 trỏ tới số cũ; tra
ở đây để khỏi đọc nhầm sang một hợp đồng khác hẳn.

| Số cũ | Tên cũ | Nay là |
|---|---|---|
| HĐ-1 | Nhịp thở: đánh giá thì được, chặn thì không | **Đã gỡ.** Gác cổng gửi tin là non-goal ([tầng Intent §5](01-intent.md)). Số HĐ-1 nay thuộc về *"Lớp nhịp gõ không được nhận nội dung"* — hợp đồng **cấm** đúng thứ hợp đồng cũ mô tả |
| HĐ-2 | Khởi động an toàn | → **HĐ-5**, nội dung giữ nguyên |
| HĐ-3 | Hợp đồng send-risk | → **HĐ-3** *"Hợp đồng nhịp gõ"* — cùng số, **khác đơn vị đo**: `câu → risk [0,1]` đổi thành `nhịp phím → CPM`. Đây là ca dễ đọc nhầm nhất |
| HĐ-4 | Copy chuỗi trước khi rời luồng | → **HĐ-7**, thêm ghi chú phạm vi đang thu hẹp |
| HĐ-5 | Ranh giới bộ não và vỏ | → **HĐ-6**, thêm một bằng chứng (chính sách chuông từng có 2 bản chép tay) |
| HĐ-6 | Không bịa dữ liệu | → **HĐ-8**, thêm luật không trộn hai thước đo |

Ba hợp đồng **mới hoàn toàn**, không có số cũ tương ứng: **HĐ-1** (lớp nhịp gõ không nhận nội dung) ·
**HĐ-2** (chuông ngân thì được, chặn thì không) · **HĐ-4** (không đếm trong ô mật khẩu).

Sáu chỗ trong `docs/03-decisions/` còn trỏ số cũ, **cố ý không sửa** vì tầng 03 là *"chỉ thêm, không
sửa"* ([`docs/README.md`](README.md)): `ADR-0003:5` · `ADR-0004:43` · `ADR-0005:5` · `ADR-0011:5` ·
`ADR-0011:41` — bốn ADR, tất cả đều đã mang trạng thái *Bị thay thế*. Riêng `ADR-0002:5` là ADR duy
nhất còn **Đã chốt** nên đã sửa số trực tiếp: đó là dòng metadata *"Liên quan"*, không phải thân
quyết định, và issue #3 đã tạo tiền lệ sửa metadata tầng 03 (đổi Trạng thái, trỏ lại link chết).

---

## HĐ-1 — Lớp nhịp gõ không được nhận nội dung

**Đây là hợp đồng quan trọng nhất của tầng này.** Lời hứa riêng tư ở
[tầng Intent §4.2](01-intent.md) — *"sản phẩm không đọc nội dung người dùng gõ"* — chỉ thật khi
người đọc code **nhìn thấy được** rằng không có đường nào cho chữ đi vào.

**Ràng buộc.** Mọi API của `core/mood` liên quan tới đo nhịp và quyết định chuông **không được có
tham số kiểu chuỗi**. Nhịp gõ nuôi bằng *thời điểm bấm phím*, không phải bằng phím nào được bấm.

```cpp
// Đúng — chỉ có dấu thời gian
class TypingCadence {
public:
    explicit TypingCadence(int64_t windowMs);
    void   registerKeystroke(int64_t nowMs);
    double currentCPM(int64_t nowMs) const;
    int    keystrokesInWindow(int64_t nowMs) const;
    void   reset();
};

// SAI — chuỗi vẫn đi qua lớp này, dù chỉ dùng .length()
class TypingCadence {
public:
    void onWord(const std::wstring& word);   // ❌ cấm
};
```

**Vì sao không tái dùng `vOnWordCommitted`.** Callback chốt từ của engine có sẵn và ba vỏ đã nối
vào đó rồi, nên nuôi nhịp từ đấy là đường ít sửa nhất. Nhưng chữ ký của nó là
`void (*)(const wstring& word)` — lớp nhịp sẽ **nhận** cả từ vừa gõ dù chỉ dùng độ dài. Người review
đọc code vẫn thấy lớp mood cầm text, và lời hứa tụt từ *"không đọc"* xuống *"có nhận nhưng hứa
không dùng"*. Đánh đổi đã cân nhắc và bác bỏ — xem
[ADR-0013](03-decisions/ADR-0013-do-nhip-go-thay-doc-cam-xuc.md).

**Cách soi — cưỡng chế bằng máy, không phụ thuộc có ai đọc tài liệu hay không.**
`scripts/check_hd1.py` (chạy ở bước *"Cổng HĐ-1"* trong `.github/workflows/macos.yml`) là
**allowlist, không phải denylist**: mọi tham số trong **header** của lớp nhịp gõ/chuông phải là một
trong `int64_t` · `int` · `double` · `bool` · `void`, và **không được là con trỏ, tham chiếu hay
mảng**. Kiểu nào khác — kể cả kiểu chưa ai nghĩ tới — là **đỏ CI**.

Phạm vi nói cho chính xác: cổng quét **mọi `.h`/`.cpp` trong `core/mood/`** trừ danh sách miễn trừ
của mô hình cũ (đang chờ #12/#13 gỡ) — nên **file mới thêm vào cũng bị soi ngay**, không cần ai nhớ
đăng ký. Allowlist tham số chỉ áp cho `.h` (nơi duy nhất có mặt API); `.cpp` đi qua một lưới
denylist phụ. Thiếu file bắt buộc, hoặc danh sách miễn trừ trỏ tới file đã biến mất, cũng đỏ.

> ⚠️ **Hai bản denylist trước của cổng này đều THỦNG.** Bản 1 (PR #21) đòi kiểu chuỗi đứng *trước*
> tên lớp trên cùng một dòng → `void TypingCadence_OnWord(const wstring&)` lọt. Bản 2 liệt tên kiểu
> → bỏ sót `const wchar_t*`, rồi sau khi vá vẫn bỏ sót **`Uint16` / `Uint32` / `Byte`** — *typedef
> của chính repo này*, và đúng là cách `core/engine` trao ký tự ra ngoài
> (`Engine.h`: `Uint32 getCharacterCode(const Uint32&)`). Tức hình dạng vi phạm **dễ xảy ra nhất**
> lại là hình dạng lọt.
>
> **Bài học: denylist không bao giờ đủ** — nó chỉ chặn được những kiểu người viết đã *nghĩ tới*, mà
> vi phạm thật thường đến từ kiểu người ta không nghĩ tới. Allowlist đã kiểm bằng **22 hình dạng vi
> phạm**, gồm cả một kiểu tự bịa (`SomeUnknownType`) — cả 22 đều đỏ, code thật vẫn xanh.
>
> Hệ quả thực dụng: **hợp đồng kèm lệnh soi hỏng còn tệ hơn không kèm lệnh nào**, vì nó cho cảm
> giác an toàn giả. Cách duy nhất biết một cổng có chạy hay không là **tiêm vi phạm giả vào rồi xem
> nó có đỏ** — và tiêm những hình dạng mình *chưa* nghĩ tới, không chỉ những hình dạng mình đã tin
> là nguy hiểm.

---

## HĐ-2 — Chuông: ngân thì được, chặn thì không

**Ràng buộc.** Chính sách chuông `core/mood/BellPolicy.h` chỉ trả lời đúng một câu: *lúc này có nên
ngân chuông không*. Nó **không có, và không được có**, bất kỳ cơ chế nào chạm vào luồng gõ.

```cpp
class BellPolicy {
public:
    explicit BellPolicy(int64_t cooldownMs);
    bool evaluate(double cpm, double thresholdCpm, int64_t nowMs, bool enabled, bool snoozed);
};
```

> ⚠️ **Chữ ký ở trên đã đổi so với bản đầu của hợp đồng này** (`bool BellPolicy_ShouldRing(double
> cpm, int64_t nowMs)` + `void BellPolicy_NoteRung(int64_t nowMs)`, hai hàm tự do) — chốt ở issue #7,
> giải trình đầy đủ ở `core/mood/BellPolicy.h`. Tóm tắt hai chỗ đổi:
> 1. **Dạng lớp, không phải hàm tự do** — cùng lý do `TypingCadence` đã chốt thành lớp ở #6 (HĐ-1):
>    cooldown + trạng thái chống rung là *state*, hàm tự do buộc giữ state đó trong biến toàn cục,
>    khiến ba vỏ dùng chung một biến và test không dựng được nhiều thể hiện độc lập.
> 2. **Một hàm `evaluate()`, không phải hai hàm `ShouldRing`/`NoteRung`** — gộp "hỏi" và "báo đã
>    reo" thành một lời gọi để loại bỏ hẳn kiểu lỗi "vỏ hỏi rồi quên báo lại" (cooldown/chống rung
>    không bao giờ nạp) hoặc "báo lại mà không thực sự phát tiếng" (core và vỏ lệch trạng thái).
>
> Nội dung tuyên bố của hợp đồng — *ngân thì được, chặn thì không*; cooldown nằm trong core — **không
> đổi**, chỉ hình dạng API đổi. Tầng 04 là quy phạm nên khối code phải khớp code thật; xem lịch sử ở
> `spec/typing-cadence-bell/PROGRESS.md` mục #7.

- Trả `false` thì vỏ không làm gì cả — không có khung rỗng, không có thông báo im.
- Trả `true` nghĩa là **phát một tiếng chuông, rồi thôi**. Không nuốt phím, không khóa phím, không
  làm chậm ký tự nào, không hiện khung đòi bấm, không hỏi han.
- Hợp đồng thuần C++, không phụ thuộc framework giao diện, để mọi vỏ tự phát tiếng mà không phải
  đoán API.
- Cooldown nằm **trong** `BellPolicy`, không phải trong từng vỏ — nếu để vỏ tự đếm thì ba vỏ sẽ trôi
  lệch, đúng cái bẫy HĐ-6 mô tả. Con số cooldown cụ thể vẫn do vỏ truyền vào constructor — lớp này
  không tự bịa ra một mặc định.
- **Chống rung (hysteresis):** sau khi đã reo, `cpm` phải tụt xuống dưới `thresholdCpm *
  kBellPolicyHysteresisFactor` (0.9, tức 10% dưới ngưỡng) thì mới được coi là một đợt vượt ngưỡng
  mới. Nói cho chính xác thứ **cổng vũ trang** giữ và thứ **độ lớn biên trễ** giữ là hai chuyện
  khác nhau — lẫn hai cái này là hiểu sai cả cơ chế:
  - Thứ giữ *"một tràng gõ nhanh dài liên tục chỉ reo đúng một lần"* là **cổng vũ trang**, không
    phải độ lớn biên trễ. Kể cả với biên trễ bằng 0, tràng gõ liên tục (cpm luôn ≥ ngưỡng) vẫn chỉ
    reo một lần, vì cổng vũ trang chặn trước khi cooldown kịp được xét.
  - Thứ **độ lớn biên trễ** giữ là ca khác: hai gợn nhịp sát nhau, giữa chúng cpm tụt **nhẹ** dưới
    ngưỡng. Với biên trễ 0, một cú tụt 1–2 CPM (đúng mức nhiễu một phím lẻ trên cửa sổ 30 giây) đã
    đủ tái vũ trang → reo hai lần cách nhau vài giây.
- **Tiền điều kiện `thresholdCpm > 0`.** Mức *"Tắt chuông"* biểu đạt bằng `enabled = false`,
  **không** bằng `thresholdCpm = 0`. Truyền 0 thì cổng chống rung (`cpm < 0`) không bao giờ đúng →
  chuông reo một lần rồi câm vĩnh viễn. Core cố ý không kẹp giá trị này; hợp đồng nói rõ thay vì
  dựng thêm nhánh xử một trạng thái vốn đã có đường biểu đạt đúng.

**Cách soi.** Mọi nơi gọi `BellPolicy::evaluate` chỉ được dẫn tới một lệnh phát tiếng khi kết quả là
`true`. Có nhánh nào đi tới `swallow`/`consume`/`return TRUE` của hook bàn phím là vi phạm.

---

## HĐ-3 — Hợp đồng nhịp gõ

**Chữ ký ổn định:**

```
chuỗi thời điểm bấm phím  →  CPM (số thực, ký tự mỗi phút)  →  có/không ngân chuông
```

Đơn vị là *"tay đang chạy nhanh tới đâu"*, **không phải** suy đoán gì về tâm người gõ. Con số này
mô tả một sự việc quan sát được. Mọi diễn giải **suy trạng thái tâm ra từ nội dung** nằm ngoài hợp
đồng và bị [tầng Intent §4.2](01-intent.md) cấm (*"không suy đoán gì từ chữ nghĩa"*). Ẩn dụ mặt hồ ↔
tâm thì **được phép** — §4.1 dùng chính nó; cái bị cấm là lấy phép đo nhịp làm **kết luận** về người
gõ, và 4 thứ §4.1 liệt kê (đèn đỏ/xanh · emoji chấm điểm · gamification · copy khiển trách).

Ba tham số của phép đo, chốt ở [ADR-0013](03-decisions/ADR-0013-do-nhip-go-thay-doc-cam-xuc.md):

| Tham số | Giá trị | Vì sao |
|---|---|---|
| Đơn vị | **CPM**, không phải WPM | Telex/VNI gõ dấu tốn thêm phím → gom thành "từ" rồi đếm bị méo |
| Cửa sổ trượt | **30 giây** | Ngắn hơn: một tràng gõ dồn rồi nghỉ cũng vượt ngưỡng. Dài hơn: chuông tới sau khi nhịp đã lắng |
| Ngưỡng mặc định | **400 CPM** (`Rất nhanh`) | Người dùng đổi được bất cứ lúc nào; sản phẩm không quyết hộ |

Thay cách tính bên trong thì được. Đổi chữ ký hoặc đổi ý nghĩa của con số thì **không**, vì mọi
tầng phía sau (chính sách chuông, kho dữ liệu, biên độ sóng, câu chữ) chỉ tiêu thụ con số này.

Kèm theo hai ràng buộc vận hành:

- Phép đo phải **rẻ tới mức chạy thẳng trong hook bàn phím được**: cập nhật cửa sổ trượt là O(1)
  biên độ, không cấp phát, không khóa. Đây là khác biệt lớn so với lớp chấm điểm cũ vốn buộc phải
  đẩy sang luồng riêng.
- Phát tiếng chuông thì **không** được chạy trong hook. Vỏ nhận `true` từ `BellPolicy` rồi đẩy việc
  phát tiếng sang luồng khác. Chặn luồng hook là làm khựng gõ, và trên Windows còn bị hệ điều hành
  âm thầm gỡ hook.

**"Tắt chuông" không làm biến mất biên độ sóng.** `core/mood/CadenceWaveAmplitude(cpm,
thresholdCpm)` (issue #8) luôn đòi một `thresholdCpm` cụ thể — không có nhánh "off" nào trong core.
Con sóng `~` là nhận diện lõi (tầng Intent §4.1), độc lập với việc `BellPolicy` có phát ra tiếng hay
không. Mỗi vỏ vì vậy phải giữ **hai giá trị tách biệt**: `bellEnabled` (bool, chỉ tắt tiếng) và
`waveReferenceThresholdCpm` (double, ngưỡng tham chiếu của sóng, mặc định 400) — tắt chuông chỉ đặt
`bellEnabled = false`, ngưỡng tham chiếu của sóng giữ nguyên giá trị đã chọn lần cuối. Chi tiết lưu
trữ cụ thể thuộc về #10/#16/#18.

---

## HĐ-4 — Không đếm nhịp trong ô mật khẩu

**Ràng buộc.** Khi ô nhập đang là ô mật khẩu (secure input), vỏ **không** được gọi
`TypingCadence::registerKeystroke`. Không đếm, không tính, không ghi.

Hai lý do, cả hai đều đủ để một mình quyết định:

1. **Chuông reo giữa lúc gõ mật khẩu là hỏng trải nghiệm** — người dùng đang tập trung nhập bí mật,
   một tiếng chuông ở đó là quấy rầy thuần túy.
2. **Không sinh dấu vết thời gian gõ mật khẩu.** Nhịp gõ không phải nội dung, nhưng chuỗi thời điểm
   bấm phím khi nhập mật khẩu là dữ liệu nhạy cảm theo đúng nghĩa đen của tài liệu bảo mật. Không
   thu thập là cách duy nhất chắc chắn không rò.

**Mặc định fail-closed.** Không xác định được ô hiện tại có phải ô mật khẩu không thì coi **là** ô
mật khẩu và không đếm. Thà mất vài nhịp còn hơn đếm nhầm.

**Cách soi.** Mỗi vỏ phải có đúng một cổng kiểm, đặt **trước** lời gọi
`TypingCadence::registerKeystroke`, và cổng đó phải có ca kiểm.

---

## HĐ-5 — Khởi động an toàn

> Ba bất biến áp cho **mọi vỏ**: macOS, Windows, iOS, và Linux sau này.

Hợp đồng này sinh ra sau khi một loại lỗi tái phát **độc lập** qua hai vỏ khác nhau. Trên macOS là
gọi tự tắt ngay trong hàm khởi động xong, khiến hàm dọn dẹp chạm vào một hàng đợi còn rỗng và gây
lỗi bộ nhớ. Trên Windows là mở hộp thoại xin đồng ý ngay trong hàm khởi tạo, trước khi icon khay và
vòng lặp thông điệp tồn tại, khiến hộp thoại mở sau lưng cửa sổ khác và chặn cứng phần còn lại.

Cùng một bệnh: **làm một việc lớn — chặn, modal, tự tắt, hoặc giành quyền — trong lúc khởi động,
trước khi giao diện và vòng lặp và tài nguyên dùng chung được dựng xong.** Cả ba vỏ đều fork từ cùng
bộ khung khởi động nên **thừa hưởng cùng cái bẫy**, và sẽ cứ mỗi vỏ vấp lại một lần nếu không chốt
luật ở một chỗ.

### #1 — Không hành động nặng trước khi ứng dụng dựng xong

Trong đường khởi động, trước khi giao diện, vòng lặp sự kiện và tài nguyên dùng chung tồn tại:
**không** modal chặn, **không** tự thoát, **không** giành quyền, **không** gọi đồng bộ chặn. Cần làm
thì **hoãn ra sau khi launch xong**.

Cách hoãn theo từng vỏ: macOS dùng `dispatch_async` hoặc `dispatch_after`; Windows dùng `PostMessage`
chứ không phải `SendMessage`; iOS không tự tắt được nên tương đương là không chạm tài nguyên chung
trong `viewDidLoad` mà không có guard.

### #2 — Không đường thoát nào được chết câm

Mọi nhánh thoát sớm lúc khởi động phải để lại một dấu vết **người dùng đọc được**. Ứng dụng tiện ích
không cửa sổ mà lặng lẽ biến mất thì người dùng bó tay, tưởng ứng dụng hỏng. "Đúng ý đồ" mà không
nói gì **vẫn là bug**.

Ngoại lệ phải được chốt bằng một quyết định có ghi lại, không phải do bỏ sót.

### #3 — Mọi dọn dẹp phải chịu được trạng thái nửa khởi tạo

Hàm dọn dẹp có thể chạy khi ứng dụng mới dựng một phần. Mọi tài nguyên đụng tới ở đó phải guard
NULL hoặc guard chưa-khởi-tạo.

### Cách soi

```bash
# Hành động nặng trong đường khởi động
grep -nE "terminate|exit\(|_exit|ExitProcess|PostQuitMessage|MessageBox|DialogBox|NSAlert" <vỏ>
```

Mỗi kết quả phải trả lời được ba câu: nó nằm trước hay sau khi ứng dụng dựng xong; nếu là đường
thoát thì có dấu vết đọc được không; nếu là dọn dẹp thì có guard nửa-khởi-tạo không.

---

## HĐ-6 — Ranh giới bộ não và vỏ

**Lỗi riêng của một hệ điều hành không bao giờ được sửa trong `core/`.**

`core/engine` và `core/mood` là bộ não dùng chung. Sửa ở đó để vá một vỏ nghĩa là ba vỏ còn lại
nhận thay đổi mà không ai kiểm. Đúng chỗ sửa là `platforms/<os>/`.

**Cách soi.** Mọi thay đổi chỉ nhắm một vỏ phải để lại `git diff core/` **rỗng**. Đây là câu kiểm
được lặp lại trong hầu hết dòng bằng chứng của dự án, và nên tiếp tục như vậy.

Hệ quả kèm theo: khi hai vỏ cần cùng một logic, viết một bản trong `core/` chứ không chép hai bản.
Dự án đã trả giá cho việc này hai lần:

- Hai bản từ điển send-risk từng trôi lệch giữa macOS và iOS, khiến cùng một câu được chấm khác nhau
  trên hai hệ điều hành (macOS coi dấu câu là dấu tách từ, iOS thì không).
- Chính sách chuông từng có hai bản chép tay — `NudgeCoordinatorIOS.h` tự thú là *"sao y bản chính
  từ macOS"*. Đây là lý do `BellPolicy` (HĐ-2) phải nằm ở `core/` **ngay từ đầu**, trước khi Windows
  kịp thành bản thứ ba.

---

## HĐ-7 — Copy chuỗi trước khi rời luồng

Callback chốt từ của engine (`vOnWordCommitted`) truyền tham chiếu tới một biến sống trên ngăn xếp
của luồng gọi. Mọi vỏ tiêu thụ callback này phải **copy sâu** trước khi đẩy sang luồng khác.

Bẫy này đã cắn iOS rồi cắn macOS trước khi thành luật. Quy ước dập tắt nó là đặt **cùng một tên
biến** ở mọi vỏ để một lệnh `grep` soi được cả hai:

```bash
grep -rn "wordCopy" platforms/
```

> **Phạm vi đang thu hẹp.** Theo HĐ-1, lớp nhịp gõ **không** tiêu thụ callback này nữa. Hợp đồng
> vẫn có hiệu lực với bất kỳ nơi nào còn nhận `vOnWordCommitted`, và sẽ được xem lại khi nhánh đọc
> cảm xúc bị gỡ hẳn (issue #13). Chưa gỡ luật khi code chưa gỡ.

---

## HĐ-8 — Không bịa dữ liệu

Áp cho mọi thứ hiển thị cho người dùng về chính họ.

- Nhịp không gõ thì **không ghi mẫu**, khác hẳn với ghi giá trị 0.
- Hai mẫu cách nhau quá 1.5 lần nhịp thì đồ thị **ngắt nét**, không nội suy — quãng rời máy là quãng
  trống thật.
- Không có mẫu nào trong ngày thì câu chữ nói "chưa có nhịp nào", **không** nói "hôm nay êm". Im
  lặng của bàn phím không phải bằng chứng của bình yên.
- Câu chữ sinh **tất định**: cùng dữ liệu luôn ra cùng câu. Không AI sinh câu, không random.
- **Không trộn thước đo.** Số liệu ghi bằng thước cũ (send-risk) và số liệu ghi bằng thước mới (CPM)
  không được vẽ chung một đồ thị. Hai đơn vị khác nhau đặt cạnh nhau trên cùng một trục là nói dối
  người dùng, kể cả khi hình vẽ ra trông liền mạch. Cách xử lý nhật ký cũ chốt ở issue #11.
