# MOOD-WAVE-MECHANISM — cơ chế sóng cảm xúc hiện tại (macOS)

> Tài liệu "một chỗ" mô tả **đúng những gì đang chạy** (đối chiếu code 2026-07-16), để chủ dự án
> và mọi agent đọc chung một nguồn thay vì lần theo 5 file. Kèm mục cuối: hướng cải thiện
> trước-PhoBERT với con số trước/sau — **mới là đề xuất, chưa code, chờ chủ dự án chốt**.
>
> Nguồn sự thật (code): `MoodWatchMac.mm` (chấm điểm + gom mẫu) · `BellMac.mm` (nhịp chung) ·
> `MoodStoreMac.mm` (kho) · `EmotionRiverView.mm` (vẽ) · `MoodPhrasingMac.mm` (câu chữ) ·
> `NudgeCoordinatorMac.mm` (ngưỡng Độ nhạy) · `core/mood/BreathingPause.cpp` (ngưỡng gác cổng).
> Bằng chứng chạy thật: `make test-macos` (tests/macos/mood_pipeline, 2026-07-16).

## 1. Bốn tầng, từ phím tới câu chữ

```
gõ từ ──► [1] CHẤM ĐIỂM mỗi từ (từ điển + công thức bão hòa) ──► risk 0..1
             │ cộng dồn thầm lặng
nhịp chuông (vBellInterval phút, mặc định máy chủ dự án: 15')
             ▼
          [2] GOM: trung bình mọi điểm trong nhịp → ghi ĐÚNG 1 mẫu vào kho
             ▼ (chỉ khi có consent; không gõ = không mẫu, không bịa)
          [3] VẼ: chấm tại đúng giờ, cao = trung bình risk; 2 mẫu cách >1.5 nhịp → NGẮT nước
             ▼
          [4] CÂU CHỮ: chia ngày 4 buổi, buổi nào có mẫu vượt ngưỡng → "có gợn"
```

## 2. Tầng 1 — chấm điểm (lexicon + bão hòa)

- **Từ điển ~40 mục** (`LEX` trong `MoodWatchMac.mm`): mỗi từ có điểm và nhóm.
  Trọng số nhóm (`categoryWeight`): **giận = 1.0** · buồn/mệt/lo = 0.35 · tích cực = 0.6
  (tích cực TRỪ điểm — kéo risk xuống).
- **Danh sách hard-hit** (`LEX_SUB`: chửi thề nặng, teencode tục): dính là ép `raw ≥ 9`.
- **Công thức bão hòa:** `risk = 1 − e^(−raw/5)`, chặn sàn `raw ≥ 0`. Cộng bao nhiêu cũng chỉ
  tiệm cận 1, không vỡ trần.
- Chuỗi kéo dài ("keooooo") được nén trước khi dò (`collapseRuns`).
- Điểm tính trên **cửa sổ chữ gần nhất** (MoodBuffer), nên chấm thực tế mượt hơn ví dụ 1 câu.

Ví dụ tính thật (câu đứng một mình, buffer rỗng — giá trị "bực quá" khớp bằng chứng
`make test-macos` in ra `0.329680`):

| Câu gõ | raw | risk |
|---|---|---|
| "hôm nay trời đẹp" | 0 | **0.00** |
| "mệt" | 1 × 0.35 | **0.07** |
| "buồn" | 2 × 0.35 | **0.13** |
| "bực quá" | 2 × 1.0 | **0.33** |
| "giận quá, buồn thật" | 2 + 0.7 | **0.42** |
| "đm" (teencode) | 4 × 1.0 | **0.55** |
| "bực mình, khó chịu quá" | (2+2)+2 | **0.70** |
| "tức giận" | 2+2+3 *(3 mục cùng khớp — hành vi thật, cụm đôi cộng chồng lên từ đơn)* | **0.75** |
| chửi thề nặng (LEX_SUB) | ≥ 9 | **≥ 0.83** |
| "bực thật, mà thôi cảm ơn nha" | 2 − 1.2 | **0.15** *(tích cực kéo xuống)* |
| "hôm nay **không vui**" | −1.2 → chặn 0 | **0.00** *(điểm mù phủ định — xem §6)* |

## 3. Tầng 2+3 — gom mẫu và vẽ

- Nhịp gốc DUY NHẤT: `g_bellTimer` (BellMac) bắn `kMKMoodBeatNotification` mỗi `vBellInterval`
  phút — **kể cả khi chuông tắt/hoãn** (tắt chuông = tắt TIẾNG, không tắt nhật ký).
- Mỗi nhịp: nếu có ≥1 từ được gõ từ nhịp trước → ghi 1 mẫu = **trung bình** risk; không gõ →
  không ghi. Thoát app giữa nhịp → `MoodWatchMac_Flush()` ghi nốt phần dở.
- Kho: SQLite mã hóa AES-256 (khóa Keychain), **không có cột nào chứa câu chữ**, chỉ ghi khi
  đã consent (từ 2026-07-16: chưa consent thì cả hàm ĐỌC cũng không tạo file — vá qua test E2E).
- Vẽ ("Ngay bây giờ" = cửa sổ trượt 3h; "Hôm nay" = từ 0h): chấm đặt đúng vị trí giờ, 2 chấm
  cách nhau quá **1.5 × nhịp** (15' → 22.5') thì KHÔNG nối nước — quãng rời máy là quãng trống
  thật (luật dec.4 "cấm bịa nước").

## 4. Tầng 4 — kho câu chữ (fix khung, lắp ruột)

Nguồn duy nhất: `MoodPhrasing_DayShapeSentence()`. Ngày chia 4 buổi: sáng 5–11h · trưa 11–13h ·
chiều 13–18h · tối 18–24h(+0–5h). Buổi có ≥1 mẫu vượt ngưỡng = "gợn". Toàn bộ kho câu:

| Tình huống | Câu |
|---|---|
| 0 mẫu hôm nay | "Chưa có nhịp nào hôm nay" *(cố ý KHÔNG nói "êm" — im lặng của bàn phím không phải bằng chứng bình yên)* |
| Có mẫu, 0 buổi gợn | "Hôm nay tới giờ vẫn êm" |
| 1+ buổi gợn | "«Sáng» có gợn" / "«Sáng và chiều» có gợn" / "«Sáng, trưa và tối» có gợn" — tên buổi lắp động, nối kiểu người nói |
| …và >50% tổng mẫu vẫn êm | nối đuôi ", phần lớn êm" *(chỉ khi ĐÚNG là quá nửa — nói bừa cho dịu tai là phán xét trá hình)* |

Không có AI sinh câu, không random — cùng dữ liệu luôn ra cùng câu.

## 5. Độ nhạy — MỘT núm, những ai ăn theo

Thanh **Độ nhạy** (popover, lưu `vBellSensitivity`) đặt ngưỡng "thế nào là gợn"
(`NudgeCoordinatorMac_RippleThreshold`) và độ dài chuỗi câu căng làm chuông rung
(`TenseStreakTrigger`):

| Mức | Ngưỡng gợn | Chuông rung sau |
|---|---|---|
| Ít nhạy | 0.6 | 5 câu căng liên tiếp |
| Vừa (mặc định) | 0.5 | 3 câu |
| Nhạy | 0.4 | 2 câu |

**Cùng một ngày gõ, ba mức đọc ra ba câu chuyện** (lấy ví dụ §2):

| Mẫu trong ngày | Nhạy (0.4) | Vừa (0.5) | Ít nhạy (0.6) |
|---|---|---|---|
| chỉ có "giận quá, buồn thật" (0.42) buổi chiều | "Chiều có gợn" | "Hôm nay tới giờ vẫn êm" | "…vẫn êm" |
| thêm "đm" (0.55) buổi tối | "Chiều và tối có gợn" | "Tối có gợn" | "…vẫn êm" |
| thêm "tức giận" (0.75) buổi sáng | sáng+chiều+tối gợn | sáng+tối gợn | "Sáng có gợn" |

Ai ăn theo núm này: **câu chữ thẻ Hôm nay** + **chuông theo chuỗi căng** + **màn Soi lại**
(cùng gọi RippleThreshold). Ai KHÔNG ăn theo — cố ý:

- **Gác cổng Enter (Feature #1):** ngưỡng cứng **0.5** (`kBreathingPauseRiskThreshold`,
  `core/mood/BreathingPause.cpp:11` — hợp đồng tầng core, chung mọi OS). Lý do: người dùng vặn
  "Ít nhạy" để đỡ ồn chuông thì KHÔNG được vô tình hạ luôn tấm lưới an toàn chặn tin nhắn giận.
  Caption dưới thanh Độ nhạy nói thẳng điều này ("Không đổi ngưỡng gác cổng").
- **Popup nhắc thụ động** trong MoodWatch: cũng dùng ngưỡng cứng 0.5 (`kSendRiskThreshold`).

## 6. Điểm mù hiện tại (nói thẳng)

1. **Phủ định:** "không vui" → thấy "vui" (+) → risk 0.00, thậm chí *kéo xuống*. Nói dối theo
   chiều nguy hiểm: người buồn mà sóng bảo êm.
2. **Cường độ:** "hơi bực" = "bực điên lên" = 0.33 — trạng từ vô hình.
3. **Mỉa mai/ẩn ý:** "Tao đang RẤT bình tĩnh đấy nhé." → 0.00. Từ điển mù hoàn toàn.
4. **Vốn từ mỏng (~40):** "cay", "ức chế", "toang", "hết chịu nổi", "phát điên", "nản"… đều 0.00.
5. **Chỉ thấy khi bộ gõ BẬT + chế độ tiếng Việt** — ô mật khẩu, chế độ EN = mù (điểm mù kiến
   trúc, mọi bản nâng cấp model đều không chữa được).
6. **Hai bản từ điển đang tồn tại song song** (chấp nhận có chủ đích, đã ghi FRICTION-LOG
   2026-07-13): `MoodWatchMac.mm` (macOS) và `platforms/apple/shared/SendRiskAnalyzer.mm` (iOS
   dùng). Nâng từ điển 1 chỗ mà quên chỗ kia = 2 OS cảm nhận khác nhau về cùng một câu.

## 7. Hướng cải thiện NGAY (trước-PhoBERT) — đề xuất chờ chốt

Xếp theo tiền-nào-của-nấy. Mỗi mục có giá trị trước/sau tính bằng chính công thức đang chạy.
PhoBERT (spec `SEND-RISK-MODEL-SPEC.md`) vẫn là đích; các mục dưới là nâng cấp *bên trong* hàm
tính risk, không đổi hợp đồng `câu → risk [0,1]`, nên không cản đường thay model sau này.

| # | Việc | Trước → Sau (ví dụ) | Công sức | Ghi chú |
|---|---|---|---|---|
| 0 | **Hợp nhất macOS dùng `SendRiskAnalyzer` chung** (xóa bản sao trong MoodWatchMac) | không đổi số — đổi CHỖ: nâng từ điển 1 lần ăn cả macOS + iOS | nhỏ | nên làm TRƯỚC #1–#3 kẻo phải sửa 2 nơi; trả luôn món nợ FRICTION-LOG 2026-07-13 |
| 1 | **Luật phủ định** ("không/chẳng/chả/đâu" đứng trước từ cảm xúc → đảo dấu) | "không vui": **0.00 → ~0.21** (đảo +1.2 thành −(−1.2)); "chẳng buồn" hết bị tính là buồn | nhỏ (~20 dòng) | chữa điểm mù nguy hiểm nhất — hiện đang *hạ* risk cho câu tiêu cực |
| 2 | **Trạng từ cường độ** ("rất/quá/cực/vãi/kinh khủng" cạnh từ cảm xúc → ×1.5) | "bực quá": **0.33 → 0.45** — bắt đầu thành "gợn" ở mức Nhạy (0.4), trước đây tàng hình ở mọi mức | nhỏ | làm câu chữ + chuông phản ứng đúng với mức độ, không chỉ có/không |
| 3 | **Mở rộng từ điển 40 → ~200 mục** (teencode + khẩu ngữ: cay, ức chế, toang, nản, tủi thân, hết chịu nổi, phát điên…) | "cay thật sự": **0.00 → ~0.33**; "ức chế quá" (kèm #2): **0.00 → ~0.45** | vừa (chọn từ + điểm cần người duyệt — chủ dự án nên duyệt danh sách) | tăng độ phủ nhiều nhất trên mỗi giờ công |
| 4 | PhoBERT ONNX on-device (spec sẵn) | hiểu cả mỉa mai/ngữ cảnh — "Tao đang RẤT bình tĩnh." từ 0.00 lên mức có nghĩa | lớn | fast-follow, giữ nguyên lộ trình |

Trình tự đề nghị: **#0 → #1 → #2 → #3** (mỗi bước một commit, có ca test riêng trong
`tests/macos/mood_pipeline` + bản đối chiếu iOS), PhoBERT giữ nguyên là đích dài hạn.

## 8. Hướng dẫn đọc đồ thị dòng sông (Dành cho người dùng)

Dòng sông cảm xúc là một công cụ phản chiếu (gương soi tâm trí), không phải là công cụ chấm điểm. Dưới đây là cách đọc các tín hiệu trên dòng sông:

### Phân biệt loại dữ liệu qua Hình dạng (Không đổi màu)
Toàn bộ dòng sông luôn giữ nguyên màu Teal trung tính. Ứng dụng không dùng màu Đỏ (nguy hiểm) hay Xanh (an toàn) để tránh việc phán xét cảm xúc của bạn là "tốt" hay "xấu".
- **Chấm ĐẶC (Tô kín):** Là những nhịp lấy mẫu **tự động** của hệ thống trong lúc bạn đang gõ phím.
- **Vòng RỖNG (Khoảng trắng ở giữa):** Là những lần **bạn tự đánh giá** (Tự thuật) qua khung "Mặt hồ đang thế nào?" xuất hiện 45 giây sau mỗi tiếng chuông. 
- *Mục đích:* Giúp bạn đối chiếu giữa những gì cơ thể/bàn phím đang thể hiện (chấm đặc) với những gì bạn thực sự nhận thức được về bản thân (vòng rỗng).

### Ý nghĩa của Cơn sóng (Biên độ)
Trục dọc của đồ thị đại diện cho **Biên độ dao động** (sự xáo động của mặt nước):
- **Phẳng lặng (Nằm sát trục giữa):** Bạn đang gõ phím thư giãn, từ tốn, dùng từ ngữ ôn hòa, hoặc bạn vừa tự đánh giá mình đang "Phẳng lặng" (Biên độ ~0.12).
- **Gợn nhẹ:** Tâm trí bắt đầu có sự xáo động nhẹ (Biên độ ~0.45).
- **Gợn sóng / Dậy sóng (Nằm cách xa trục giữa nhất):** Bạn đang gõ phím rất mạnh, nhanh, dùng phím xóa liên tục hoặc sử dụng các từ ngữ mang cảm xúc mạnh, tiêu cực. Sóng lúc này sẽ vút lên cao (hoặc chìm xuống sâu) tạo thành một cơn sóng lớn (Biên độ ~0.80).

**Lưu ý quan trọng:** Cơn sóng lượn lên đỉnh hay lượn xuống đáy chỉ là nét vẽ hình sin theo thời gian. Điều bạn cần quan tâm là **khoảng cách từ điểm đó tới đường đứt nét ở giữa**. Càng xa trung tâm nghĩa là mặt hồ càng xáo động.

---

## 9. Khi nào cập nhật tài liệu này

Đổi công thức/ngưỡng/kho câu → sửa mục tương ứng TẠI ĐÂY cùng commit, và cập nhật dòng liên
quan trong `TEST_MATRIX.md`. Tài liệu này mô tả *hiện tại* — lịch sử quyết định vẫn nằm ở
FRICTION-LOG / decision-log, không chép lại vào đây.
