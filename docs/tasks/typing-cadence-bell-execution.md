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

## 2. Research Findings

Kho kết quả research. Giữ nguyên văn — đây là thứ session sau đọc để khỏi tra lại.

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
