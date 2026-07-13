# MANUAL-TEST-SCRIPT — Round 1 iOS, kiểm tay trước khi coi là "trải nghiệm được"

> **Đây KHÔNG phải tài liệu phân tích mới** — chỉ tổng hợp + sắp thứ tự những gì đã có sẵn:
> Acceptance Criteria đã khóa trong `bmad-output/ios/stories/1.*.story.md`, journey trong
> `bmad-output/ios/EXPERIENCE.md`, và ma trận ca test trong
> `.claude/skills/mindful-test-design/references/telex-vni-edge-cases.md`. Không viết lại nội
> dung — chỉ trỏ + đóng gói thành thứ tự bấm tay được, để KHÔNG đẻ thêm nguồn sự thật thứ 2/3.
>
> **Mỗi mục tick xong** → cập nhật đúng dòng đó trong `docs/TEST_MATRIX.md` (nâng `✅¹`/`⚠️²`
> lên `✅` thật, kèm 1 câu mô tả những gì quan sát được — không chỉ tick suông).

---

## Chuẩn bị (1 lệnh)

- [ ] `make run-ios` — build + boot Simulator + cài + mở app + in hướng dẫn. (Đổi máy: `make run-ios IOS_SIM="iPhone 15"`.)

---

## Phần A — Onboarding (story 1.7 → FR-A04/A05)

> Nguồn AC: `1.7.onboarding-two-screens.story.md` · Journey: `EXPERIENCE.md` Journey 1

- [ ] **A1.** Mở app lần đầu → thấy **Màn 01** với 3 bước đánh số đúng thứ tự ("① Mở Cài đặt › Cài đặt chung › Bàn phím ② ... ③ ..."), nút "Mở Cài đặt" cam. _(AC 1.7 #1)_
- [ ] **A2.** Chạm "Chưa thấy Mindful Key?" → hiện hướng dẫn tĩnh, giọng bình thản, **KHÔNG** icon đỏ / chữ "Lỗi". _(AC 1.7 #2)_
- [ ] **A3.** Chạm "Mở Cài đặt" → vào đúng trang Cài đặt của app (`openSettingsURLString`) → tự bật bàn phím Mindful Key trong Cài đặt hệ thống chung (thủ công ngoài app) → quay lại app.
- [ ] **A3b. (lối tiến thủ công — fix 2026-07-13)** Nếu quay lại app mà **vẫn ở Màn 01** (App Group heartbeat không nhảy — thường gặp trên Simulator), sẽ thấy nút mới **"Đã thêm xong — tiếp tục"** hé ra dưới "Chưa thấy?" → chạm để sang Màn 02. (Trên máy thật heartbeat chạy → tự nhảy, không cần nút này.)
- [ ] **A4.** Thấy **Màn 02** — cặp biên độ "Bật lên để" (sóng) / "Không bao giờ" (đường phẳng), nghĩa nằm ở CHỮ chứ không chỉ màu/hình. Có nút "Để sau". _(AC 1.7 #3, #4)_
- [ ] **A5.** Chạm "Để sau" → vào thẳng **Home**, không bị ép bật Full Access. _(AC 1.7 #5)_
- [ ] **A6.** (Tùy chọn) Bật VoiceOver → duyệt qua Màn 01/02 → xác nhận đọc đúng thứ tự: tiêu đề → nội dung → CTA. _(AC 1.7 #6)_
- [ ] **A7.** Ghi nhận: asset hiện tại là **placeholder** (sóng đơn giản, SF Symbols) — đúng dự kiến, KHÔNG phải lỗi (chờ chủ dự án chốt Q10b). _(AC 1.7 #7)_

→ Cập nhật dòng `TEST_MATRIX.md`: *"Onboarding 2 màn (kích hoạt + Full Access) + Home"*.

---

## Phần B — Gõ Telex ra dấu (story 1.2 → FR-A01, Mốc B) ⭐ quan trọng nhất

> Nguồn AC: `1.2.telex-typing-bridge.story.md` · Ma trận: `telex-vni-edge-cases.md`

- [ ] **B1.** Từ Home, chạm ô "Gõ thử" hoặc mở **Notes** → chạm 🌐 → chọn **Mindful Key**.
- [ ] **B2.** Gõ `vieetj` → phải ra **"việt"**. _(AC 1.2 #1 — đây là dòng ❌ E2E duy nhất trong TEST_MATRIX, ưu tiên số 1)_
- [ ] **B3.** Gõ thêm 4 ca gốc, so khớp với `tests/core/test_engine.cpp`:
  - `xin chaof cacs banj` → "xin chào các bạn"
  - `tieengs vieetj` → "tiếng việt"
  - `tooi ddang vui` → "tôi đang vui"
  - `hoom nay meejt quas` → "hôm nay mệt quá"
- [ ] **B4.** Thử 3 ca biên Loại 6 (backspace) đã khóa trong `test_engine.cpp` — gõ rồi bấm ⌫ thật bằng ngón tay: `vieetj` rồi ⌫ 1 lần → **"việ"**; `tooi` rồi ⌫ rồi `s` → **"tố"**.
- [ ] **B5. (Ca đã biết là quirk, không phải bug cần báo lại)** Gõ `as`, ⌫⌫ về rỗng, gõ `nawm` → dự kiến ra **"nawm"** (không phải "năm") — engine không tái kích hoạt biến hình sau ⌫-về-rỗng. Xác nhận đúng như ghi trong `test_engine.cpp`, không phải lỗi mới.

⚠️ **Chưa cài được Zalo trên Simulator (không có App Store)** — mục "gõ trong Zalo y hệt Notes" _(AC 1.2 #2)_ **chỉ làm được ở Phần D (thiết bị thật)**.

→ Cập nhật dòng `TEST_MATRIX.md`: *"Gõ Telex ra dấu qua core/engine — Mốc B"* — đây là dòng quan trọng nhất để nâng lên `✅`.

---

## Phần C — Shift/Caps + lớp số + ô mật khẩu (story 1.3, 1.4 → FR-A02, FR-A07)

> Nguồn AC: `1.3.keyboard-shift-number-layer.story.md`, `1.4.secure-field-privacy-guard.story.md`

- [ ] **C1.** Chạm `⇧` 1 lần → gõ 1 chữ → ra HOA, `⇧` tự về thường ngay sau đó (one-shot). _(AC 1.3 #1)_
- [ ] **C2.** Double-tap `⇧` (2 chạm nhanh) → thấy chỉ dấu khóa riêng (nút đổi hình `⇪`, nền teal) → mọi chữ gõ tiếp theo đều HOA cho tới khi chạm `⇧` lần nữa. _(AC 1.3 #2, #3)_
- [ ] **C3.** Chạm `123` → hàng phím đổi thành số/ký hiệu, nút đổi thành `ABC` → chạm lại → về QWERTY. _(AC 1.3 #4)_
- [ ] **C4.** Thử chạm các phím hẹp (`⇧`, `⌫`, `123`) — vùng chạm phải đủ rộng, không cần tap chính xác vào giữa nhãn nhỏ. _(AC 1.3 #5)_
- [ ] **C5.** Mở Safari → chạm vào 1 ô nhập **mật khẩu** thật (ví dụ trang đăng nhập bất kỳ) → chuyển sang Mindful Key → gõ chữ vẫn ra bình thường (không bị chặn). _(AC 1.4 #2)_

→ Cập nhật 2 dòng `TEST_MATRIX.md`: *"Shift/Caps + lớp số"*, *"Loại ô mật khẩu"*.

---

## Phần D — Thiết bị thật (bắt buộc, Simulator không mô phỏng đúng)

> ⚠️ 2 mục dưới đây **không thể** làm trên Simulator — lý do đã ghi trong plan trước: Simulator
> không có App Store (không cài Zalo được) và tiến trình Simulator không bị giới hạn RAM như máy
> thật (đo RAM trên Simulator cho số đẹp giả tạo).

- [ ] **D1.** Cắm iPhone thật qua cáp, ký app bằng Apple ID free-provisioning, cài lên máy.
- [ ] **D2.** Mở **Zalo** thật → vào 1 đoạn chat → chuyển sang Mindful Key → gõ `vieetj` → phải ra **"việt"** y hệt Notes (không lệch giữa 2 app). _(AC 1.2 #2 — mục còn thiếu duy nhất để đóng AC 1.2)_
- [ ] **D3.** Gõ liên tục nhiều câu trong Notes + Zalo trong ~5 phút → xác nhận bàn phím **không bị hệ điều hành kill** giữa chừng (không tự nhiên biến mất/treo).
- [ ] **D4.** Mở Xcode → Instruments → attach vào tiến trình `MindfulKeyKeyboard` đang chạy trên máy → đo RAM, xác nhận **dưới trần jetsam ~48–60MB**. Ghi số đo thật vào `tests/ios/README.md` (mục "Kiểm thủ công còn lại").

→ Cập nhật dòng `TEST_MATRIX.md`: *"Đo RAM extension trong giới hạn jetsam"* (từ `planned`) + đóng nốt AC 1.2 #2.

---

## Phần E — App Group heartbeat (story 1.6 → FR-A06, đã có UI placeholder ở 1.7)

> Nguồn AC: `1.6.app-group-heartbeat.story.md`

- [ ] **E1.** Cài app lần đầu, CHƯA gõ gì qua Mindful Key → mở container → thấy trạng thái "hướng dẫn kích hoạt". _(AC 1.6 #4)_
- [ ] **E2.** Gõ 1 lần trong Notes (Phần B) → quay lại container (đưa lên foreground) → trạng thái đổi thành "đã kích hoạt". _(AC 1.6 #5)_
- [ ] **E3.** (Biết trước, không phải bug) Tắt bàn phím lại trong Cài đặt hệ thống → mở container → trạng thái **VẪN** báo "đã kích hoạt" (không phát hiện được lúc tắt — giới hạn chấp nhận ở Round 1). _(AC 1.6 #6)_

→ Cập nhật dòng `TEST_MATRIX.md`: *"App Group heartbeat"*.

---

## Phần F — Round 3 · Kho nhật ký cảm xúc (story 3.1 → FR-A13 nền) — DEVICE-ONLY

> ⚠️ Host test (`tests/ios/mood_journal_store_test`) đã chứng minh: mã hóa AES round-trip, đĩa
> không có plaintext, cổng consent, DeleteAll, SetConsent(NO) xóa sạch. 3 mục dưới **KHÔNG** host-test
> được — cần **thiết bị/Simulator có Team ID thật** (ký ad-hoc không cấp keychain-access-group).

- [ ] **F1.** (Cần Team ID thật) Gõ vài câu căng (`send-risk ≥ 0.35`) qua Mindful Key trong Notes → mở container app → màn soi lại (story 3.3 khi có) đọc được summary → xác nhận extension GHI và container ĐỌC **cùng 1 khóa Keychain** (không `errSecMissingEntitlement`). Nếu lỗi → soát `kSecAttrAccessGroup` trong `MoodJournalStore.mm` (xem FRICTION-LOG 2026-07-13).
- [ ] **F2.** Bật consent → gõ câu căng → kiểm file `mood-journal.enc` xuất hiện trong App Group container; tắt consent → file biến mất (round-trip 2 tiến trình thật).
- [ ] **F3.** Instruments đo RAM extension khi kho + Keychain + crypto đã nạp → xác nhận vẫn **dưới trần jetsam ~48–60MB** (crypto/Keychain không đội RAM quá ngưỡng).

→ Cập nhật dòng `TEST_MATRIX.md`: *"Kho nhật ký cảm xúc mã hóa on-device + consent (story 3.1)"* — nâng phần device-only lên `✅` khi làm xong trên máy thật.

---

## Sau khi xong (định nghĩa "đã trải nghiệm thật")

- [ ] Tất cả ô tick ở Phần A, B, C, E xong trên Simulator.
- [ ] Phần D xong trên thiết bị thật (Zalo + RAM).
- [ ] `docs/TEST_MATRIX.md`: mọi dòng iOS Round 1 chuyển từ `✅¹`/`⚠️²` sang `✅` trần, kèm 1 câu quan sát thật (không phải "đã chạy, chắc ổn").
- [ ] Bug/lệch phát hiện khi bấm tay (nếu có) → ghi vào `docs/FRICTION-LOG.md` hoặc mở lại story tương ứng (KHÔNG tự sửa lặng lẽ nếu chạm hành vi đã khóa AC — quay lại hỏi).

---
*Tổng hợp 2026-07-11, không phải artifact phân tích mới — chỉ đóng gói thứ tự bấm từ story ACs + EXPERIENCE.md + telex-vni-edge-cases.md.*
