---
name: typing-cadence-layer
description: Thiết kế/sửa lớp đo nhịp gõ và chính sách chuông — TypingCadence (đếm nhịp phím → CPM trên cửa sổ trượt), BellPolicy (ngưỡng + cooldown, dùng chung 3 vỏ), kho ghi lần chuông, và biên độ con sóng. PHẢI dùng khi việc nhắc tới: đo tốc độ gõ, CPM, cửa sổ trượt, ngưỡng chuông, khoảng lặng giữa hai lần chuông, nhật ký số lần chuông, biên độ sóng `~`, hoặc quyền riêng tư của lớp này. KHÔNG dùng để sửa core/engine/ hay code riêng từng OS.
---

# Typing Cadence Layer

> ⚖️ Luật tối cao là hiến chương `docs/01-intent.md`. Hợp đồng ràng buộc code là
> `docs/04-contracts.md` **HĐ-1 → HĐ-4** (cộng HĐ-6 ranh giới core/vỏ, HĐ-8 không bịa dữ liệu). Lộ trình thi công ở
> `spec/typing-cadence-bell/README.md`. Mơ hồ → **hỏi chủ dự án**, đừng tự quyết.

## Vòng lặp

```
Measure  →  Bell  →  Reflect
```

Lớp này sở hữu **Measure** và **Bell**, và cấp dữ liệu cho **Reflect**.

## Luồng dữ liệu

```
HOOK BÀN PHÍM của từng vỏ  (macOS CGEventTap · Win32 LowLevelKeyboardProc · iOS insertText)
   │  mỗi phím bấm = MỘT DẤU THỜI GIAN. Không có ký tự nào đi qua đây.
   │  ⚠️ cổng kiểm ô mật khẩu nằm TRƯỚC lời gọi này (HĐ-4, fail-closed)
   ▼
core/mood/TypingCadence   — cửa sổ trượt 30 giây, trả CPM
   │  registerKeystroke(int64_t nowMs)
   │  currentCPM(int64_t nowMs) -> double
   ▼
core/mood/BellPolicy      — so CPM với ngưỡng người dùng + cooldown + chống rung
   │  BellPolicy(int64_t cooldownMs)
   │  evaluate(double cpm, double thresholdCpm, int64_t nowMs, bool enabled, bool snoozed) -> bool
   │  ⚠️ MỘT lời gọi duy nhất — trả `true` là core ĐÃ tự ghi nhận đã reo, vỏ không phải
   │     gọi thêm hàm "báo đã reo" nào nữa (chốt ở #7)
   ▼
VỎ phát MỘT tiếng chuông  (đẩy ra khỏi luồng hook)  +  ghi một dòng vào kho
   ▼
Màn soi lại: đếm số lần chuông theo thời gian · biên độ con sóng `~`

Nhánh SONG SONG (không đi qua BellPolicy — sóng vẽ liên tục, không chỉ lúc chuông reo):

core/mood/CadenceWaveAmplitude  — CPM + ngưỡng -> biên độ sóng `~` trong [0,1]
   │  CadenceWaveAmplitude(double cpm, double thresholdCpm) -> double
   │  kCadenceWaveDeadZoneRatio (0.3 — TỈ LỆ so với ngưỡng, không phải CPM tuyệt đối)
   │  kCadenceWaveDefaultThresholdCPM (400.0 — dùng khi người dùng chưa chọn ngưỡng)
   │  ⚠️ Vỏ truyền CẢ HAI số thô. TUYỆT ĐỐI không tự chia cpm/threshold rồi truyền tỉ lệ —
   │     phép chia phải nằm MỘT chỗ trong core, nếu không ba vỏ sẽ trôi lệch (chốt ở #8)
   │  ⚠️ "Tắt chuông" chỉ tắt TIẾNG. Sóng vẫn vẽ — nó là nhận diện lõi, độc lập với chuông.
   │     Vỏ giữ `waveReferenceThresholdCpm` tách biệt khỏi `bellEnabled` (HĐ-3)
```

## Bốn luật không được phá

### 1. Không bao giờ nhận chuỗi ký tự (HĐ-1)

Đây là luật quan trọng nhất của lớp này. Mọi API liên quan tới đo nhịp và quyết định chuông
**không được có tham số kiểu chuỗi**.

```cpp
void   TypingCadence::registerKeystroke(int64_t nowMs);   // ✅ chỉ dấu thời gian
void   TypingCadence::onWord(const std::wstring& word);   // ❌ CẤM
```

Lời hứa riêng tư ở hiến chương §4.2 — *"sản phẩm không đọc nội dung"* — chỉ thật khi người đọc code
**nhìn thấy được** rằng không có đường nào cho chữ đi vào. Nhận chuỗi rồi chỉ dùng `.length()` vẫn
là vi phạm: người review đọc code thấy lớp này cầm text, và lời hứa tụt xuống *"có nhận nhưng hứa
không dùng"*.

**Cụ thể: KHÔNG tái dùng `vOnWordCommitted`.** Callback đó có chữ ký `void (*)(const wstring& word)`.
Ba vỏ đã nối sẵn vào nó nên nuôi nhịp từ đấy là đường ít sửa nhất — và đã bị **bác bỏ có chủ đích**
(Q3, chốt 2026-08-01).

**Cưỡng chế bằng máy — allowlist, không phải denylist.** `scripts/check_hd1.py` (chạy ở bước
*"Cổng HĐ-1"* của `macos.yml`) đòi **mọi tham số** trong header của lớp này phải là `int64_t` ·
`int` · `double` · `bool` · `void`, và **không được là con trỏ / tham chiếu / mảng**. Kiểu nào khác
— kể cả kiểu chưa ai nghĩ tới — là đỏ CI.

Hai bản denylist trước đều thủng (bỏ sót `const wchar_t*`, rồi bỏ sót `Uint16`/`Uint32`/`Byte` là
typedef của chính repo). **Đừng quay lại denylist.** Chạy thử tại chỗ: `python3 scripts/check_hd1.py`.

### 2. Chuông ngân thì được, chặn thì không (HĐ-2)

`BellPolicy::evaluate` trả `true` nghĩa là **phát một tiếng chuông, rồi thôi**. Không nuốt phím,
không khóa phím, không làm chậm ký tự nào, không hiện khung đòi bấm, không hỏi han. Trả `false` thì
vỏ **không làm gì cả** — không có khung rỗng, không có thông báo im.

Cooldown nằm **trong** `BellPolicy`, không phải trong từng vỏ.

### 3. Không đếm nhịp trong ô mật khẩu (HĐ-4)

Cổng kiểm đặt **trước** lời gọi `TypingCadence::registerKeystroke`, **mặc định fail-closed** — không xác
định được thì coi là ô mật khẩu và không đếm. Windows đã có (`MoodWatch.cpp`), iOS đã có,
**macOS chưa có** (bổ sung ở #9).

### 4. Một bản trong `core/`, không chép tay (HĐ-6)

Dự án đã trả giá **hai lần** cho việc chép logic sang từng vỏ:

- Hai bản từ điển send-risk trôi lệch thật giữa macOS và iOS (macOS coi dấu câu là dấu tách từ, iOS
  thì không) → cùng một câu chấm khác nhau trên hai máy.
- Chính sách chuông từng có hai bản chép tay — `NudgeCoordinatorIOS.h` tự thú là *"sao y bản chính
  từ macOS"*.

Vì vậy `BellPolicy` nằm ở `core/` **ngay từ đầu**, trước khi Windows kịp thành bản thứ ba.

## Ba tham số đã chốt

| Tham số | Giá trị | Vì sao |
|---|---|---|
| Đơn vị | **CPM** (ký tự/phút), không phải WPM | Telex/VNI gõ dấu tốn thêm phím → gom thành "từ" rồi đếm bị méo |
| Cửa sổ trượt | **30 giây** | Ngắn hơn: một tràng gõ dồn rồi nghỉ cũng vượt ngưỡng. Dài hơn: chuông tới sau khi nhịp đã lắng |
| Ngưỡng mặc định | **400 CPM** (`Rất nhanh`) | Người dùng đổi được bất cứ lúc nào |

Bốn mức người dùng chọn: `Nhanh 300` · `Rất nhanh 400` · `Cực nhanh 500` · `Tắt chuông`.

Nguồn: [ADR-0013](../../../docs/03-decisions/ADR-0013-do-nhip-go-thay-doc-cam-xuc.md).

## Câu chữ — mô tả, không phán xét

Tên mức mô tả **nhịp tay**, không mô tả tâm người gõ. Cấm mọi chữ quy về trạng thái tâm
("bình tĩnh", "mất kiểm soát", "nóng nảy"…). Chỗ nào hiện tên mức thì **hiện kèm con số CPM**, để
đọc ra ngay đây là phép đo chứ không phải lời nhận xét.

Chữ **"quá"** là dấu hiệu cảnh báo. *"Bạn đang gõ quá nhanh"* hàm ý có một mức đúng do sản phẩm
định đoạt — trong khi ngưỡng là do chính người dùng đặt. Viết *"nhịp gõ vượt mức bạn đặt"*.

**Chuông là lời mời để ý, không phải kết luận.** Gõ nhanh không luôn có nghĩa tâm đang động: có thể
người dùng đang chép chính tả, đang gõ lại đoạn đã nghĩ xong, hoặc tay vốn nhanh. Mọi câu chữ quanh
chuông phải giữ đúng khoảng cách này.

## Ràng buộc vận hành

- **Phép đo phải rẻ tới mức chạy thẳng trong hook được**: cập nhật cửa sổ trượt là O(1) biên độ,
  không cấp phát, không khóa. Đây là khác biệt lớn so với lớp chấm điểm cũ vốn buộc phải đẩy sang
  luồng riêng.
- **Phát tiếng chuông thì KHÔNG chạy trong hook.** Vỏ nhận `true` rồi đẩy việc phát tiếng sang luồng
  khác. Chặn luồng hook là làm khựng gõ, và trên Windows còn bị hệ điều hành âm thầm gỡ hook.
- **Không bịa dữ liệu** (HĐ-8): không gõ thì không ghi mẫu. Không trộn số liệu thước cũ (send-risk)
  với thước mới (CPM) trên cùng một đồ thị.

## Thứ đã chết — đừng sinh lại

Lớp đọc cảm xúc đã bị bỏ **hẳn** (2026-07-26). Nếu bạn định viết bất kỳ thứ nào dưới đây thì **dừng
lại** — nó vi phạm hiến chương §5 Non-goals:

| Đã chết | Vì sao |
|---|---|
| `SendRiskAnalyzer`, lexicon cảm xúc, model sentiment | Sản phẩm không đọc nội dung nữa |
| `MoodBuffer` (gom từ → câu) | Không còn câu nào để gom |
| `BreathingPause`, gác cổng gửi tin, allow-list ứng dụng chat | Non-goal — không chen vào giữa người dùng và app chat |
| Popup cảnh báo "câu này nghe đang giận" | Chuông chỉ có âm thanh, không khung nổi |

Chúng còn trong repo tới khi issue #12/#13 gỡ xong. Còn trong repo **không** có nghĩa còn được dùng.

## Phụ thuộc

- Vỏ cấp dấu thời gian phím — phối hợp qua skill `platform-porting` (macOS/Windows) và
  `ios-keyboard-extension` (iOS).
- **Không** phụ thuộc `core/engine` nữa: lớp này không dùng `vOnWordCommitted`. Đây là thay đổi so
  với lớp cảm xúc cũ.
