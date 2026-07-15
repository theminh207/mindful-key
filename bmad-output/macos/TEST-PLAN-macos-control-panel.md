# TEST PLAN (Bảng Nghiệm Thu) — Bảng điều khiển macOS (mindful-key)

**Epic:** 1 — Hiện đại hóa Bảng điều khiển macOS · **Loại:** Acceptance test thủ công (manual QA)
**Nguồn:** Acceptance Criteria của 6 story `1.1–1.6` + `DESIGN-` / `EXPERIENCE-macos-control-panel.md`
**Trạng thái:** LOCKED planning artifact — dev tool đọc, không sửa. Đổi test → ghi `decision-log.md`.

> ⚠️ **SUPERSEDED (2026-07-10 UI + 2026-07-13 hướng)** — xem `decision-log.md` entry
> "Reconciliation: huỷ 1.3/1.6" + "Diện mạo mới v2: popover chia tab". Test case cho story 1.3/1.6
> KHÔNG áp dụng (2 story đó đã huỷ, không thi công); UI 4-tab mà mọi `TC-` bên dưới giả định cũng
> đã bị thay bằng popover 3-tab. File này chỉ còn giá trị lịch sử. **Sổ bằng chứng đang hiệu lực:
> `docs/TEST_MATRIX.md`** — dùng file đó để biết cái gì đã/chưa được kiểm chứng cho UI hiện tại.

> **Tài liệu này để làm gì:** cho **người nghiệm thu bằng cách BẤM** (không đọc code) một bảng
> "làm bước này → phải thấy cái này" cho từng tiêu chí. Bạn — hoặc bất kỳ ai — cầm bảng này chạy
> qua app đã build là biết đội thực thi làm ĐÚNG hay chưa, trước khi coi là xong.
>
> **KHÔNG bao gồm:** unit test cho giao diện (over-engineering cho MVP; BMAD không viết test; epic
> này không đụng "bộ não" C++ vốn đã có regression riêng). Logic đáng test tự động (đọc ngưỡng
> UserDefaults, bẫy "giờ yên lặng ngược" ở story 1.5) được ghi làm gợi ý cuối tài liệu, chưa dựng.

---

## 0. Cách dùng bảng này

**Ký hiệu:** mỗi test-case có mã `TC-<story>-<số>`, map 1–1 với Acceptance Criteria cùng số
(vd `TC-1.4-3` kiểm AC #3 của story 1.4). Cột cuối `☐` để bạn tick khi PASS.

**2 cổng tự động phải xanh trước khi nghiệm thu tay** (nhờ dev/agent chạy, bạn chỉ cần thấy chữ "xanh/pass"):

| Cổng | Lệnh | Ý nghĩa (nói người) |
|------|------|---------------------|
| Lưới an toàn "bộ não" | `make test` | Chạy lại test engine C++. Phải 0 lỗi — chứng minh việc sửa giao diện KHÔNG vô tình làm hỏng lõi gõ tiếng Việt. |
| Build sạch | `make build` | Dựng app macOS. Phải 0 error + KHÔNG thêm cảnh báo mới. |

> Nếu 1 trong 2 cổng đỏ → **dừng, chưa nghiệm thu tay**. Như nhà chưa qua kiểm định móng thì chưa vào nghiệm thu nội thất.

**Khi nào kiểm được test-case nào:** story 1.1 và 1.2 tạo "linh kiện" (control, sóng) — mấy tiêu chí
*hình thức* của chúng chỉ **thấy rõ sau khi ráp vào panel ở Đợt 3 (story 1.6)**; nhưng mấy tiêu chí
*vệ sinh code* (không dùng icon cấm, không chữ trắng trên cam) kiểm được ngay tại story bằng cách tìm
trong file (grep). Mỗi bảng ghi rõ cột "kiểm ở đâu".

---

## 1. ⚖️ CỔNG HIẾN CHƯƠNG — kiểm bằng mắt (quan trọng nhất)

Đây là phần bảo vệ *linh hồn sản phẩm*. Chạy cả cụm này trên app hoàn chỉnh (sau Đợt 3). Chỉ cần
**1 dòng FAIL = chưa được release**, dù mọi thứ khác chạy ngon.

| # | Nhìn vào đâu | PHẢI đúng | ☐ |
|---|--------------|-----------|---|
| CH-1 | Toàn panel | KHÔNG có đèn đỏ / vàng / xanh-lá nào mã hoá cảm xúc. Trạng thái cảm xúc chỉ là con sóng `~` teal↔xám-đá. | ☐ |
| CH-2 | Widget sóng | KHÔNG có mặt cười/mếu, KHÔNG icon tam giác cảnh báo, KHÔNG dấu chấm 2 màu, KHÔNG thanh nạp đầy dần. | ☐ |
| CH-3 | Card Chuông | Độ nhạy là 3 chữ "Ít nhạy · Vừa · Nhạy" — KHÔNG số điểm, KHÔNG streak, KHÔNG huy hiệu. | ☐ |
| CH-4 | Màu cam | Cam chỉ xuất hiện ở nút bấm/link. KHÔNG có cam trên thanh trượt, trên trạng thái bật/tắt, hay trên "thang cảm xúc". | ☐ |
| CH-5 | Nút cam bất kỳ | Chữ trên nút cam là chữ **tối**, đọc rõ (không phải chữ trắng mờ). | ☐ |
| CH-6 | Thứ tự card | Card **Gác cổng** nằm **trên cùng**, to/nổi bật nhất, không bao giờ ngang cỡ card Chuông/Bộ gõ. | ☐ |
| CH-7 | Mọi câu chữ trạng thái | Đọc như **mô tả** ("Mặt hồ đang gợn sóng"), KHÔNG như **phán xét/ra lệnh** ("Bạn đang căng thẳng, hãy bình tĩnh"). | ☐ |
| CH-8 | Sóng lúc không gõ | Đứng **yên, phẳng, im lặng** — không nhấp nháy, không loop trang trí, không âm nền. | ☐ |
| CH-9 | Toàn panel | KHÔNG thấy nội dung câu gõ thật, KHÔNG lịch sử từng dòng (giờ/tên app), KHÔNG biểu đồ theo thời gian. | ☐ |
| CH-10 | Trạng thái cảm xúc | Mặc định **thu gọn** (phải chủ động bấm mới mở rộng) — người ngồi cạnh liếc màn hình không đọc được ngay. | ☐ |

---

## 2. Bảng nghiệm thu theo story

### Story 1.1 — Bộ control brand nền tảng (`BrandControls`)
*Kiểm ngay tại story: TC-1.1-5, 1.1-6 (tìm trong file). Kiểm hình thức: sau khi ráp (Đợt 3).*

| Mã | Cách kiểm (bấm/tìm gì) | Kỳ vọng thấy | ☐ |
|----|------------------------|--------------|---|
| TC-1.1-1 | Trên app, Tab tới 1 toggle; bật/tắt; disable thử | Bật = teal, tắt = xám; focus có viền teal 2px; disabled mờ 40%. KHÔNG xanh-lá hệ thống. | ☐ |
| TC-1.1-2 | Nhìn dấu chấm trạng thái | Đúng 1 màu: bật = teal đặc, tắt = chỉ viền, không tô. (API chỉ nhận bật/tắt.) | ☐ |
| TC-1.1-3 | Nhìn 1 nút cam | Nền cam, chữ tối, đọc rõ ở mọi trạng thái. Bo góc 8px. | ☐ |
| TC-1.1-4 | Rê chuột / nhấn / disable nút cam | Hover đậm nhẹ, focus có viền, nhấn lún 1px, disable mờ 40% — 4 trạng thái phân biệt được. | ☐ |
| TC-1.1-5 | Tìm trong `BrandControls.h/.m` các từ `face.`, `exclamationmark.triangle`, `systemGreen/Red/Yellow` | **0 kết quả** (không dùng icon/màu cấm). | ☐ |
| TC-1.1-6 | Chạy `make build`; xem diff `BrandColors.*` | Build sạch, 0 warning mới; `BrandColors` không bị sửa (trừ thêm token đã thoả thuận). | ☐ |

**Coi như XONG (DoD 1.1):** 6 dòng trên PASS + `make build` xanh + `make test` xanh.

---

### Story 1.2 — Widget sóng cảm xúc (`EmotionWaveView`)
*TC-1.2-6, 1.2-7 kiểm được sớm (đọc code/copy). Hình thức: sau khi ráp.*

| Mã | Cách kiểm | Kỳ vọng thấy | ☐ |
|----|-----------|--------------|---|
| TC-1.2-1 | Cho biên độ tăng dần, nhìn sóng | Chỉ đổi độ cao/tần số/độ dày nét, màu chỉ chạy teal↔xám-đá. KHÔNG bao giờ chuyển cam/đỏ. | ☐ |
| TC-1.2-2 | Mở panel lần đầu | Sóng ở dạng **thu gọn** nhỏ; chỉ mở rộng khi bấm rõ ràng. | ☐ |
| TC-1.2-3 | Để yên không gõ, rồi tạo tín hiệu | Lúc nghỉ: đứng im. Có tín hiệu: đổi hình mượt 400–600ms, không giật. | ☐ |
| TC-1.2-4 | Bật "Giảm chuyển động" trong macOS, đổi trạng thái | Đổi hình **tức thời**, không animate. | ☐ |
| TC-1.2-5 | Bật VoiceOver, focus vào sóng | Nghe câu mô tả (vd "mặt hồ đang gợn nhẹ"); đổi trạng thái thì đọc lại. | ☐ |
| TC-1.2-6 | Đọc các câu copy trạng thái | Toàn câu mô tả trung tính, không ra lệnh/khiển trách (gate mô-tả-không-phán-xét). | ☐ |
| TC-1.2-7 | Kiểm input của view | Chỉ nhận 1 con số (biên độ). KHÔNG vẽ/log/giữ chữ gõ thật, giờ, tên app. | ☐ |

**Coi như XONG (DoD 1.2):** 7 dòng PASS + build/test xanh + xác nhận gate copy ghi trong Dev Agent Record.

---

### Story 1.3 — Panel cuộn dọc + InputMethodCard + footer riêng tư

| Mã | Cách kiểm | Kỳ vọng thấy | ☐ |
|----|-----------|--------------|---|
| TC-1.3-1 | Mở panel | KHÔNG còn 4 tab. Là 1 trang cuộn dọc, section ngăn bằng đường mảnh; rộng cố định 360px. | ☐ |
| TC-1.3-2 | Nhìn các card | Card nền trắng, bo góc 16px, bóng ánh ngọc bích nhẹ, không viền gắt. | ☐ |
| TC-1.3-3 | Mở/đóng InputMethodCard | Mọi cài đặt gõ cũ (Telex/VNI/bảng mã, macro, checkbox hệ thống) nằm gọn trong 1 card thu gọn được; toggle là kiểu pill teal, không checkbox vuông. | ☐ |
| TC-1.3-4 | Bật/tắt gõ tiếng Việt | Chấm ở đầu panel đổi teal↔viền, đúng trạng thái gõ. Không dùng chấm này cho cảm xúc. | ☐ |
| TC-1.3-5 | Cuộn lên/xuống, đóng/mở card | Hàng cam kết riêng tư **luôn hiện** ở cuối, không bị che, không biến mất. | ☐ |
| TC-1.3-6 | Thử lần lượt TỪNG tính năng gõ cũ (đổi kiểu gõ, bật/tắt macro, phím tắt, kiểm bản mới, mở link trang chủ/mã nguồn) | Tất cả **vẫn chạy y như bản 4-tab cũ** — không mất tính năng nào. | ☐ |
| TC-1.3-7 | Đọc nhãn chấm, tiêu đề card, câu footer | Không câu nào chấm điểm/khiển trách; không đèn đỏ/xanh mã hoá bật/tắt. | ☐ |

**Coi như XONG (DoD 1.3):** 7 dòng PASS, đặc biệt **TC-1.3-6 (không mất tính năng cũ)** — đây là rủi ro lớn nhất của story này.

---

### Story 1.4 — Card Gác cổng (Feature #1)

| Mã | Cách kiểm | Kỳ vọng thấy | ☐ |
|----|-----------|--------------|---|
| TC-1.4-1 | Nhìn card gác cổng | Full-width, đứng đầu, viền teal đậm hơn card khác, nền nhấn nhẹ; KHÔNG xếp ngang hàng với Chuông/Bộ gõ. | ☐ |
| TC-1.4-2 | Trạng thái bật, đọc câu mô tả | Sóng thu gọn + câu "Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi." (mô tả, không phán xét). | ☐ |
| TC-1.4-3 | Tắt gác cổng | Sóng phẳng + "Gác cổng đang tắt." + nút bật lại. **KHÔNG đỏ, không xám-chết cảnh báo.** | ☐ |
| TC-1.4-4 | Tạo tín hiệu "đang căng" | Biên độ sóng tăng chậm mượt, copy đổi "Mặt hồ đang gợn sóng"; không nhấp nháy, không đổi màu, không hiện số. | ☐ |
| TC-1.4-5 | Bấm "Soi lại hôm nay →" (chuột và Enter khi focus) | Mở đúng màn Soi lại (`ReflectionScreenMac`), không mở view giả khác. | ☐ |
| TC-1.4-6 | Tab tới card | Cả card nhận focus như 1 nhóm, hiện viền teal 2px bao quanh card. | ☐ |
| TC-1.4-7 | Rê chuột lên card | Nền sáng nhẹ hơn + con trỏ pointer trên vùng link; không đổi màu/viền toàn card. | ☐ |

**Coi như XONG (DoD 1.4):** 7 dòng PASS, đặc biệt **TC-1.4-1 (nổi bật nhất)** và **TC-1.4-3 (tắt không đỏ)**.

---

### Story 1.5 — Card cấu hình Chuông

| Mã | Cách kiểm | Kỳ vọng thấy | ☐ |
|----|-----------|--------------|---|
| TC-1.5-1 | Nhìn ô độ nhạy; đổi mức; đóng mở lại panel | Chỉ 3 chữ "Ít nhạy · Vừa · Nhạy", không số/không thanh nạp/không nút "xem thử". Lựa chọn được **nhớ** sau khi mở lại. | ☐ |
| TC-1.5-2 | Đổi âm chuông ở dropdown; cho chuông reo | Chuông reo đúng **âm vừa chọn** (không phải âm mặc định cứng cũ). | ☐ |
| TC-1.5-3 | Nhìn thanh âm lượng; kéo; reo thử | Thanh 1 màu teal (không cầu vồng, không đầu đỏ); kéo xong âm lượng **đổi thật**. | ☐ |
| TC-1.5-4 | Nhập giờ yên lặng vô lý (bắt đầu = kết thúc) | Hiện "Khoảng giờ chưa hợp lệ", **giữ giá trị cũ**, không crash, không tự sửa hộ. | ☐ |
| TC-1.5-5 | Nhìn toggle "Đồng bộ Chế độ Tập trung"; bật thử | Mặc định **TẮT**; bật lên phải hiện giải thích quyền trước khi thật sự đồng bộ. | ☐ |
| TC-1.5-6 | Mở "Tùy chỉnh nâng cao" | Chỉ khi mở mới thấy con số câu căng chính xác; lúc thu gọn (mặc định) không lộ số ra mặt chính. | ☐ |
| TC-1.5-7 | Đọc mọi nhãn/caption trong card | Không câu nào khiển trách/thúc ép (gate mô-tả-không-phán-xét). | ☐ |

**Coi như XONG (DoD 1.5):** 7 dòng PASS. ⚠️ Lưu ý dev: kiểm kỹ **TC-1.5-4** vì biến giờ hiện nghĩa "giờ hoạt động" — dễ làm chuông reo NGƯỢC trong giờ yên lặng (đã cảnh báo trong story).

---

### Story 1.6 — Ráp panel + các trạng thái màn hình

| Mã | Cách kiểm | Kỳ vọng thấy | ☐ |
|----|-----------|--------------|---|
| TC-1.6-1 | Mở panel hoàn chỉnh | Thứ tự dọc: Gác cổng → Chuông → Bộ gõ → cam kết riêng tư. Gác cổng luôn to/nổi nhất, kể cả lúc loading/lỗi. | ☐ |
| TC-1.6-2 | Mở panel lúc mới khởi động (đang đọc dữ liệu) | Mỗi card hiện khung mờ "đang tải" (skeleton) + VoiceOver đọc "Đang tải cấu hình", rồi hiện dữ liệu thật. | ☐ |
| TC-1.6-3 | Mở panel đầu ngày (chưa gõ câu nào) | Sóng phẳng + "Hôm nay chưa có gì làm mặt hồ gợn sóng". **KHÔNG hiện "0 lần", không thúc ép.** | ☐ |
| TC-1.6-4 | Giả lập lỗi lưu cấu hình / lỗi đọc nhật ký | Hiện câu trung tính + nút "Thử lại"; **không màu đỏ**. Lỗi đọc nhật ký KHÔNG khoá card Chuông/Bộ gõ. | ☐ |
| TC-1.6-5 | Chưa cấp quyền nhật ký cảm xúc | Hỏi cấp quyền **đúng 1 lần**; đã hỏi rồi thì không hỏi lại; các card khác vẫn dùng được. | ☐ |
| TC-1.6-6 | Tắt toàn bộ nhắc tâm | Card Chuông + sóng mờ 40% + "Đang tắt nhắc tâm" + nút bật lại. Không icon cảnh báo, không đỏ/xám-chết. | ☐ |
| TC-1.6-7 | (a) bật Focus sync; (b) nhập giờ vô lý; (c) tìm biểu đồ trong panel | (a) hiện giải thích trước khi bật; (b) giữ giá trị cũ + báo trung tính; (c) **không có biểu đồ nào** — mọi "xem lại" qua màn Soi lại. | ☐ |

**Coi như XONG (DoD 1.6):** 7 dòng PASS + chạy lại toàn bộ **Cổng Hiến Chương (mục 1)** vì đây là bản ráp hoàn chỉnh cuối.

---

## 3. Truy vết (traceability)

- **41 test-case** ↔ **41 acceptance criteria** (map 1–1 theo số: `TC-<story>-<n>` ↔ AC #n của story đó).
- **10 dòng Cổng Hiến Chương** ↔ ràng buộc bất khả xâm phạm (`DESIGN §5`, `sharding-context` #1–8).
- Chạy đủ = mỗi AC có ít nhất 1 cách nghiệm thu cụ thể + toàn bộ luật hiến chương được soi bằng mắt.

## 4. Nghiệm thu cuối (sign-off)

Coi epic "Bảng điều khiển macOS" là **đạt** khi:
1. `make test` xanh + `make build` sạch (2 cổng tự động).
2. 41 test-case PASS.
3. 10 dòng Cổng Hiến Chương PASS (bắt buộc tuyệt đối — 1 dòng FAIL = chưa release).
4. Mỗi story có dòng xác nhận gate "mô tả hay phán xét?" trong Dev Agent Record.

## 5. Gợi ý unit-test tự động (CHƯA dựng — để dev cân nhắc sau)

Chỗ *logic thật* (không phải giao diện) đáng test tự động nếu muốn chắc hơn — có thể thành 1 story
riêng sau này, KHÔNG nằm trong epic hiện tại:
- Đọc/ghi ngưỡng độ nhạy + âm + volume + giờ qua `UserDefaults` (story 1.5): given giá trị lưu → khi
  đọc ra phải đúng.
- Bẫy "giờ yên lặng ngược" (`isInBellRange`): given khung giờ yên lặng → hàm phải trả "KHÔNG reo"
  trong khung đó (đây là chỗ dễ sai nhất, đáng 1 test tự động thật).
- Map send-risk (0–1) → mức biên độ sóng (story 1.2): given risk → đúng bucket biên độ.

> Giao diện (view, layout, animation) **cố ý không** unit-test — nghiệm thu bằng mắt (mục 2) hiệu quả hơn.
