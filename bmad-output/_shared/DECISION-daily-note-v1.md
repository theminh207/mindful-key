# Quyết định thiết kế — Ô ghi cảm nhận cuối ngày (daily note) v1

**Ngày chốt:** 2026-07-16 · **Nguồn:** hội thoại chủ dự án + mockup 3 màn (popover / cửa sổ Hôm nay / Soi lại)
**Trạng thái:** ĐÃ CHỐT HƯỚNG — chưa code. Bản này là hợp đồng để lúc thi công không tự nghĩ lại.
**Đụng tới:** `_shared/SYNC-emotion-mechanism-v2.md` (schema nhật ký, mục A) · macOS `ReflectionScreenMac.mm` + `MoodStoreMac` · lộ trình iOS.

> ⚖️ Lọc qua HIẾN CHƯƠNG: câu hỏi > con số · quan sát không phán xét · KHÔNG streak/điểm/gamification ·
> riêng tư mặc định ("không gửi nội dung gõ đi đâu"). Ô ghi này là chỗ **dễ trượt** nhất về cả hai
> mặt (tạo áp lực "phải viết" = streak trá hình; lưu chữ thật = bậc riêng tư mới) → mọi ràng buộc dưới là CỨNG.

---

## 1. Vì sao thêm

Câu hỏi ở nhịp "Soi" hiện hỏi xong rồi bay đi ("mang câu hỏi theo cũng đủ"). Có chỗ ghi một dòng thì
cái *nhận ra* được giữ lại, và vài tuần sau đọc lại **chữ của chính mình** — không phải số máy chấm —
mới là lúc tự soi rõ nhất. Đây đúng là mảnh còn thiếu của trục "thiết kế để **tự nhận ra**". Nhật ký viết
tay (journaling) có bằng chứng trị liệu thật; điểm mấu chốt là giữ nó **là lời mời, không phải bài tập**.

## 2. Quyết định — hình dạng

| # | Chốt | Ghi chú |
|---|------|---------|
| 2.1 | **MỘT ô ghi tùy chọn**, KHÔNG phải 1–2 form | Một ô giữ màn êm; nhiều ô biến Soi lại thành tờ khai. |
| 2.2 | Đặt **dưới nhịp "Soi"**, gắn với câu hỏi hôm đó | Nó là chỗ *đón* câu hỏi, không phải mục riêng. |
| 2.3 | Là **lời mời**: placeholder mờ `"Nếu muốn, ghi lại một dòng cho hôm nay…"` — KHÔNG label bắt buộc | Placeholder ≠ mệnh lệnh. |
| 2.4 | **Trống = im lặng.** CẤM đếm "đã ghi N ngày", CẤM "bạn chưa viết", CẤM nhắc-viết | Ô trống trong app kiểu này giống bảng điểm danh — cảm giác tội lỗi đó chính là streak trá hình HIẾN CHƯƠNG cấm. |
| 2.5 | **Đọc lại được** ở Soi lại của ngày cũ + (sau) tầm nhìn Tuần | Giá trị nằm ở đọc-ngược, không ở lúc viết. |
| 2.6 | 1 note / ngày, **sửa được trong ngày**; gắn ngày + câu hỏi hôm đó | Không phải sổ nhiều dòng — một dòng cho một ngày. |

## 3. Riêng tư — đây là bậc nhạy cảm MỚI (phần quan trọng nhất)

Tới giờ kho nhật ký chỉ giữ **số liệu suy ra** (biên độ, số lần gác cổng, mốc giờ) — **không hề** lưu chữ
người dùng gõ. Đó là cả lời hứa "không gửi nội dung gõ đi đâu". Ô ghi này là **lần đầu tiên** app lưu
**câu chữ thật** — thứ nhạy cảm nhất. Về kỹ thuật rẻ (hạ tầng có sẵn), nhưng *threat model* đổi hẳn:
nhật ký chữ là thứ đáng để mất. Ràng buộc CỨNG:

- **3.1 Lưu tại chỗ, mã hoá.** Dùng chung kho `MoodStore` hiện có (SQLite + AES-256-CBC + khoá Keychain).
  Không thêm dependency. Không bao giờ rời máy.
- **3.2 Consent RIÊNG, tách khỏi consent nhật ký-số.** Hỏi **1 lần** khi người dùng lần đầu chạm vào ô ghi
  (KHÔNG hỏi giữa lúc đang căng). Copy nói thẳng: *chữ bạn viết sẽ được lưu, mã hoá, chỉ nằm trên máy này.*
- **3.3 Xoá được.** Từng ghi chú xoá được; và nối vào nút "xoá toàn bộ nhật ký" sẵn có.
- **3.4 KHÔNG nằm trong export mặc định.** Theo đúng tinh thần đã chốt 2026-07-14 (story 2.6: "hẹp hơn khi dữ
  liệu rời vùng mã hoá") — CSV export mặc định **loại** nội dung note. Nếu muốn xuất note thì phải là một
  lựa chọn opt-in riêng, cảnh báo rõ.
- **3.5 CẤM TUYỆT ĐỐI chạy sentiment/model lên nội dung note.** Máy đọc *cách gõ* để vẽ sóng là một chuyện;
  máy đọc *nhật ký tâm* của người dùng là phản bội lòng tin. Note **chỉ cho con người đọc**, không bao giờ
  là đầu vào cho bất kỳ tính toán nào.

## 4. Schema — hợp đồng dùng chung (đồng bộ với `SYNC` mục A)

- Thêm `event_type = 'note'` vào schema nhật ký, với một cột text **mã hoá** (nội dung note). Phân biệt rõ với
  `'checkin'` đã khai báo sẵn: **checkin** = tự thuật 1-chạm 3 sóng (dữ liệu có cấu trúc); **note** = chữ tự do.

> **[CHỐT 2026-07-16 — hỏi chủ dự án trước khi code, §4 "cột text mã hoá" nghĩa là gì]**
> **Mã hoá RIÊNG TỪNG NỘI DUNG NOTE (field-level), không chỉ dựa vào mã hoá cả file.**
> *Lý do — phát hiện lúc đọc code, hợp đồng gốc chưa lường:* `OpenWorkingDB()` giải mã **toàn bộ**
> kho ra 1 file SQLite **plaintext** ở thư mục tạm mỗi lần đọc/ghi (kể cả mỗi nhịp lấy mẫu ~15 phút),
> `FlushAndCloseDB()` mới mã hoá lại + xoá. Tới giờ kho chỉ có số liệu nên chấp nhận được; nhưng note
> là **chữ thật** → nếu chỉ dựa vào mã hoá cả file thì nhật ký của người dùng nằm dạng đọc-được trên đĩa
> mỗi 15 phút, và app **sập giữa chừng** thì file ở lại (đêm 2026-07-16 app đã sập thật nhiều lần).
> Field-level dùng lại `AESEncrypt/AESDecrypt` + khoá Keychain **đã có sẵn** (~20 dòng, 0 dependency mới),
> và đúng nghĩa đen chữ "cột text mã hoá" của §4/§5.
> **Hệ quả bắt buộc:** iOS kế thừa cùng giao ước — note **field-encrypted** ở cả hai vỏ, không chỉ file-encrypted.

> **[CHỐT 2026-07-16 — phạm vi v1 của §2.5 "đọc lại ở Soi lại của ngày cũ"]**
> **v1 CHỈ làm note của HÔM NAY** (ghi + sửa trong ngày). Đọc lại ngày cũ **tách sang đợt sau**.
> *Lý do:* màn Soi lại hiện chỉ mở được hôm nay — không có bất kỳ cách điều hướng ngày nào. Làm "đọc lại
> ngày cũ" = phải thiết kế cách chọn ngày, mà thứ đó **rất dễ trượt thành lịch/dashboard** (§5.7 HIẾN CHƯƠNG
> cấm) → là quyết định nhận diện riêng, phải chốt riêng, không đính kèm vào ô ghi. Đúng tinh thần §6 non-goals.

> **[CHỐT 2026-07-16 — "đợt sau" của §2.5: lối đọc lại = CHỒNG GHI CHÚ]** — `NotesHistoryMac.h/.mm`
> Chủ dự án chọn giữa 3 lối (chồng ghi chú · mũi tên lùi từng ngày · chạm chấm trên sông Tuần/Tháng):
> **chồng ghi chú, CHỈ ngày CÓ viết**, mới nhất trước, mở từ link "Những dòng đã viết →" ngay dưới ô ghi.
> *Vì sao loại 2 lối kia:* **mũi tên lùi ngày** hiện ô trống cho mỗi ngày không viết — đúng cảm giác điểm
> danh §2.4 cấm; **chạm chấm trên sông** thì chấm = nhịp lấy mẫu chứ không phải ghi chú, nên ngày có viết
> mà không gõ tiếng Việt sẽ không có chấm nào để chạm → không tới được chính ghi chú đó.
> *Ràng buộc kèm theo:* ngày trống KHÔNG xuất hiện dưới bất kỳ dạng nào · không đếm/không chuỗi ·
> không sóng/không số đo trên màn này (chỉ chữ người viết + ngày + câu hỏi hôm đó) · link vào **ẩn hẳn**
> khi chưa viết dòng nào (link xám cũng là lời nhắc "bạn chưa viết"). KHÔNG thêm mục nav thứ 7 vào cửa sổ
> Cài đặt — số 6 mục là chốt diện mạo v2, đổi nó là quyết định khác.
> *Kéo theo §2.6 "gắn ngày + câu hỏi hôm đó":* `SaveNoteForToday` nay nhận thêm `question`, lưu **nguyên
> văn** vào cột `mood_label` (vốn khai cho 'checkin', dòng 'note' chưa dùng — tái dùng thay vì ALTER TABLE
> lần nữa). Lưu nguyên văn chứ không lưu index rồi suy lại: sửa lời một câu hỏi là mọi note cũ đột nhiên
> "trả lời" câu khác. Note ghi trước bản này không có câu hỏi → màn đọc lại bỏ trống dòng đó, KHÔNG bịa.
> *Kéo theo auto-purge:* xem chốt phương án (a) — `RunAutoPurgeIfNeeded` chừa `event_type='note'` ra, vì
> chữ người viết mà bị dọn sau 90 ngày thì không ai từng đọc lại được (kể cả chính họ).
- iOS **dùng cùng tên `event_type` + cùng cột** → nhật ký hai vỏ cùng dạng, đọc lại giống nhau.
- Ràng buộc bất biến: cột note mã hoá at-rest ở **cả hai** vỏ.

## 5. Đồng bộ iOS

- iOS thiếu chân kiềng #2 (gác cổng, sandbox chặn — SYNC mục B) → **ô ghi + check-in càng quan trọng** để bù
  mật độ dữ liệu ngày (khớp SYNC mục C.2). iOS kế thừa **cùng schema note**; UI mượn cùng ngôn ngữ Soi lại.
- ⚠️ Vì note = **chữ thật** và iOS đang **mở Full Access** (friction 2026-07-13, còn `mở`), lưu note trên iOS
  làm **tăng hệ trọng** của Full Access. Phải cộng dòng này vào cân nhắc Full Access trước khi iOS bật note.

## 6. Non-goals v1 (để không phình)

Không rich text · không nhiều ô · không tag / mood-picker gắn kèm · không tìm kiếm toàn văn · không nhắc-viết ·
không thống kê/biểu đồ trên note · không phân tích nội dung. Tất cả để đợt sau, nếu thật sự cần.

## 7. Copy khoá giọng (quan sát, không phán xét, không tội lỗi)

- Placeholder: *"Nếu muốn, ghi lại một dòng cho hôm nay…"*
- Dòng cam kết (ngay dưới ô): *"Chỉ nằm trên máy · đã mã hoá · xoá được bất cứ lúc nào."*
- Consent lần đầu: nói rõ *lưu gì, mã hoá, chỉ trên máy* — không hù doạ, không "để không bỏ lỡ".
- Ngày không viết: **không có** câu nào cả. Im lặng là tôn trọng.

## 8. Việc kéo theo khi thi công (không làm = nợ)

1. `MoodStore` (macOS trước): thêm loại `'note'` + cột text mã hoá + migration; hàm lưu/đọc note theo ngày.
2. `ReflectionScreenMac.mm`: ô ghi dưới nhịp "Soi" (load note hôm nay nếu có, lưu khi rời/đổi); consent gate lần đầu.
3. `docs/PRIVACY-NOTE.md`: thêm đoạn "ô ghi cảm nhận — chữ thật, mã hoá, chỉ trên máy, loại khỏi export mặc định".
4. `_shared/SYNC-emotion-mechanism-v2.md` mục A: thêm 1 dòng schema `'note'` (đã phản ánh ở đây, cập nhật khi code).
5. Cân nhắc Full Access iOS (friction 2026-07-13): cộng "lưu note = chữ thật" vào lý do hệ trọng.

---

*Bản này chỉ chốt HƯỚNG + ràng buộc. Khi bắt đầu code, mở kèm `SYNC-emotion-mechanism-v2.md` (schema) và
`ReflectionScreenMac.mm` (chỗ cắm). Mọi thay đổi chạm nhận diện/riêng tư mà mơ hồ → dừng, hỏi chủ dự án.*
