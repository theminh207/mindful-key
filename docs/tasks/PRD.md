# PRD — Mindful Key: macOS MVP

> 🔄 **Viết lại 2026-08-01 (issue #5)** theo vòng lặp `Measure → Bell → Reflect`. Bản trước mô tả
> `Sense → Pause → Remind → Reflect` (đọc nội dung + gác cổng gửi tin) — mô hình đó đã bị bỏ hẳn,
> xem [`ADR-0013`](../03-decisions/ADR-0013-do-nhip-go-thay-doc-cam-xuc.md). Bản quy phạm ngắn gọn
> hơn ở [`docs/01-intent.md`](../01-intent.md); file này giữ phần bối cảnh dài.

## 1. Định vị: tiếng chuông tỉnh thức theo nhịp gõ

Đây **không phải** một bộ gõ tiếng Việt có thêm tính năng theo dõi cho vui. Định vị ngược lại: một
bộ gõ tồn tại vì **một nhiệm vụ duy nhất** — nhận ra lúc nhịp gõ đang cuốn bạn đi, và ngân một tiếng
chuông kéo bạn về hiện tại.

**Feature #1 (không phải feature thứ n):** tiếng chuông ngân khi tốc độ gõ vượt mức **bạn tự đặt**.
Mọi tính năng khác (thống kê, nhật ký, màn soi lại) phục vụ cho feature này, không ngang hàng với nó.

**Người dùng chính:** cộng đồng thực hành chánh niệm (thiền, mindfulness) — không phải "mọi người gõ
tiếng Việt". Đây là nhóm đã có sẵn động lực nội tại để chấp nhận "chậm lại 1 nhịp", nên ma sát mà
sản phẩm tạo ra được đón nhận như một tính năng, không phải một phiền toái.

**Vì sao macOS trước:** máy dev hiện tại là macOS — build/thử tại chỗ, không phải chờ máy Windows +
Visual Studio. Đổi lại macOS "trói tay" hơn: phải xin quyền **Accessibility + Input Monitoring**, và
muốn phát hành ngoài phải **ký (Developer ID) + notarize** với Apple. MVP này **phân phối trực tiếp
qua .dmg đã ký/notarize, không qua Mac App Store** — App Store review áp thêm ràng buộc (sandbox)
không tương thích với việc bắt phím toàn cục.

## 2. Vòng lặp lõi: Measure → Bell → Reflect

1. **Measure (Đo)** — mỗi lần bấm phím, vỏ báo **một dấu thời gian** (không báo phím nào) cho
   `core/mood/TypingCadence`. Lớp này giữ cửa sổ trượt **30 giây** và tính **CPM** (ký tự mỗi phút).
   Phép đo rẻ tới mức chạy thẳng trong hook bàn phím được — O(1) biên độ, không cấp phát, không khóa.
   **Không đọc ký tự nào là ký tự nào.**
2. **Bell (Chuông)** — `core/mood/BellPolicy` so CPM với ngưỡng người dùng đặt, cộng khoảng lặng tối
   thiểu giữa hai lần chuông, rồi trả lời có ngân hay không. Trả `true` thì vỏ phát **một tiếng
   chuông** — và chỉ phát tiếng. Không khung nổi, không chặn phím, không hỏi han, không đòi bấm gì.
   Việc phát tiếng đẩy ra khỏi luồng hook.
3. **Reflect (Soi lại)** — mỗi lần chuông ghi một dòng vào kho local đã mã hóa; màn soi lại hiện
   tóm tắt số lần chuông theo thời gian, mô tả trần trụi, không gamify.

**Ngưỡng thuộc về người dùng.** Bốn mức: `Nhanh 300` · `Rất nhanh 400` (mặc định) · `Cực nhanh 500` ·
`Tắt chuông`. Đổi được bất cứ lúc nào. Sản phẩm không tự quyết thế nào là "nhanh" cho người khác —
mỗi người một nhịp tay.

MVP thành công = vòng lặp này chạy mượt trong lúc gõ hàng ngày, ở mọi ứng dụng, không làm người dùng
để ý tới nó ngoài đúng lúc chuông ngân.

## 3. Non-goals (loại trừ rõ ràng)

- **Không đọc cảm xúc từ nội dung.** Không phân tích ngữ nghĩa, không chấm điểm câu chữ, không model
  sentiment. Tín hiệu duy nhất là tốc độ gõ. *(Đảo ngược so với bản PRD trước — xem ADR-0013.)*
- **Không gác cổng nút gửi.** Sản phẩm không phát hiện "sắp gửi tin", không chen vào giữa người dùng
  và ứng dụng chat, không có allow-list ứng dụng. *(Cũng đảo ngược so với bản trước.)*
- **Không phải add-on vui vui** — chuông không phải tính năng phụ, nó chính là lý do sản phẩm tồn tại.
- **Không phải công cụ giám sát** — không parental control, không employee monitoring. Dữ liệu chỉ
  người gõ được xem; không có chế độ báo cáo/xem từ xa.
- **Không chặn cứng** — luôn là ma sát mềm. Chuông ngân rồi thôi; phớt lờ bằng cách gõ tiếp là xong.
- **Không gửi bất cứ thứ gì ra khỏi máy** dưới bất kỳ lý do nào, kể cả "để cải thiện sản phẩm".
- **Không đo năng suất.** Tốc độ gõ không bao giờ được trình bày như thành tích hay điểm số.
- **Không qua Mac App Store ở MVP này** — phân phối trực tiếp qua .dmg đã ký + notarize.
- **Không đa nền tảng ở MVP này** — macOS trước, rồi Windows, rồi iOS.
- **Không nhắm độ chính xác tuyệt đối.** Gõ nhanh **không luôn** có nghĩa tâm đang động — chuông là
  lời mời để ý, không phải kết luận. Vùng mù đã biết (ô mật khẩu, bộ gõ tắt, iOS chỉ thấy bàn phím
  của mình) được công khai với người dùng, không che giấu.

## 4. Success metrics (đo được, đúng tầm MVP)

MVP nhắm nhóm nhỏ (cộng đồng chánh niệm), nên không đặt mục tiêu tăng trưởng — mục tiêu là
**validate vòng lặp lõi**:

- **Zero** báo cáo giật/khựng gõ do lớp đo nhịp gây ra — điều kiện sống còn, không phải số liệu
  tăng trưởng. Đây là chỉ tiêu nghiêm ngặt hơn bản trước, vì phép đo nay chạy **trong** hook bàn
  phím chứ không phải trên luồng riêng.
- **Zero** rớt onboarding vì màn xin quyền Accessibility/Input Monitoring gây hoang mang.
- Chuông ngân đúng lúc đủ để người dùng **để yên, không tắt đi vì phiền** — dấu hiệu ngưỡng mặc định
  và khoảng lặng đã hợp lý. Theo dõi tỷ lệ người đổi ngưỡng và tỷ lệ chọn "Tắt chuông".
- Người dùng tự nguyện mở màn soi lại ≥ 1 lần/tuần — chỉ báo bước Reflect có giá trị thật, không chỉ
  tiếng chuông hữu ích.

## 5. Nguyên tắc riêng tư: 100% on-device

- **Sản phẩm không đọc nội dung.** Chỉ đếm nhịp phím để tính tốc độ — không lưu, không phân tích,
  không suy đoán gì từ chữ nghĩa. Ràng buộc này được cưỡng chế bằng hợp đồng
  [`docs/04-contracts.md`](../04-contracts.md) **HĐ-1**: cấm mọi API của lớp nhịp gõ nhận tham số
  kiểu chuỗi, soi được bằng một lệnh `grep`.
- Kho dữ liệu local (mã hóa) chỉ chứa **thời điểm chuông ngân, tốc độ đo được lúc đó, và ngưỡng đang
  đặt** — không cột nào chứa văn bản gốc.
- **Không đếm nhịp trong ô mật khẩu** (HĐ-4), mặc định fail-closed.
- Cần sự đồng ý rõ ràng khi bật lần đầu, tắt được bất cứ lúc nào, có nút xoá toàn bộ nhật ký.
- Vùng mù phải được nói thẳng ngay từ onboarding, gồm cả câu *"tốc độ gõ là một dấu hiệu thô, không
  phải thước đo tâm trạng"*.
- **Zero network telemetry** mặc định — không đồng bộ cloud.

Bản dễ đọc cho người dùng: [`PRIVACY-NOTE.md`](PRIVACY-NOTE.md).

## 6. Phạm vi kỹ thuật MVP

macOS only (deployment target **13.0+** — nâng từ 10.15 ngày 2026-07-18 vì chưa từng test máy cũ hơn
14.8.3 và SMAppService login-item cần 13+, xem [`FRICTION-LOG.md`](FRICTION-LOG.md)); dùng nguyên bộ
não OpenKey đã fork; vỏ = menu-bar app có sẵn, CGEventTap + Accessibility có sẵn.

Lớp nhịp gõ nuôi **từ hook bàn phím, từng phím một** — **không** tái dùng callback `vOnWordCommitted`
của engine, dù ba vỏ đã nối sẵn vào đó. Lý do: chữ ký của callback đó là `const wstring& word`, nên
lớp nhịp sẽ nhận cả từ vừa gõ dù chỉ dùng độ dài, và lời hứa riêng tư tụt từ *"không đọc"* xuống
*"có nhận nhưng hứa không dùng"*. Quyết định Q3, chốt 2026-08-01.

UI = màn chọn ngưỡng trong cửa sổ Chuông + màn soi lại trong app trên thanh menu; đóng gói `.dmg` ký
Developer ID + notarize, launch-at-login, zero telemetry.
