# 02 — Features

> Tầng mô tả **hiện trạng**: sản phẩm đang làm được gì, trên vỏ nào, và đã được chứng minh tới đâu.
> Khác với [tầng Intent](01-intent.md) vốn mô tả điều phải đúng mãi mãi, tầng này đổi theo mỗi lần
> ship. Khi tài liệu và code lệch nhau ở tầng này thì **code là đúng**, tài liệu phải sửa theo.
>
> Cập nhật gần nhất: 2026-07-26 · phiên bản `0.4.24`.
> Bằng chứng chi tiết từng dòng: `tasks/TEST_MATRIX.md`.

## Bốn mức bằng chứng

Dự án phân biệt rạch ròi bốn mức dưới đây. Gộp chúng lại là nguồn cơn của gần như mọi lần nghiệm
thu thất bại trong lịch sử dự án.

| Mức | Nghĩa |
|---|---|
| **Có code** | File tồn tại, đọc thấy logic |
| **Build-verified** | Biên dịch và liên kết sạch, CI xanh |
| **Mắt người** | Có người mở ứng dụng thật và nhìn thấy nó đúng |
| **E2E** | Có người đi trọn luồng người dùng và nó chạy đúng |

Bài học đã trả giá hai lần — macOS 2026-07-15 và Windows 2026-07-23 — là **build-verified không nói
gì về việc màn hình có giống thiết kế hay không**. Nó chỉ nói code hợp lệ.

## Bản đồ nền tảng

| | macOS | Windows | iOS | Android · Linux |
|---|---|---|---|---|
| Bộ gõ tiếng Việt | có | có | có | chưa khởi công |
| Gác cổng trước khi gửi | có | có | **không thể** | chưa |
| Nhật ký cảm xúc | có | có | có | chưa |
| Chuông tỉnh thức | có | có | có | chưa |
| Màn soi lại | có | có | có | chưa |

iOS không có gác cổng là **quyết định, không phải thiếu sót** — sandbox keyboard extension không có
global hook và không thấy nút gửi của ứng dụng chủ. Xem
[ADR-0014](03-decisions/ADR-0014-ios-mandate-hep-do-nhip-trong-ban-phim.md).

---

## A. Bộ gõ tiếng Việt

Lõi kế thừa OpenKey, đặt tại `core/engine`, dùng chung mọi hệ điều hành.

- Gõ **Telex / VNI / VIQR** ra dấu, xuất Unicode và các bảng mã khác.
- Luật ghép vần và bỏ dấu (`Vietnamese.cpp`).
- **Gõ tắt** (macro) — thay chuỗi viết tắt bằng cụm dài.
- **Chuyển mã** giữa các bảng mã.
- **Tự chuyển Việt/Anh** theo ứng dụng (`SmartSwitchKey`).
- Kiểm tra chính tả, phím tắt bật/tắt bộ gõ.

**Bằng chứng:** `make test-core` chạy `tests/core/test_engine`. Engine đã được chứng minh chạy dưới
cả clang (macOS) lẫn MSVC (CI Windows). Còn thiếu ca kiểm riêng cho luật ghép vần nâng cao.

---

## B. Gác cổng trước khi gửi — Feature #1

Trái tim sản phẩm. Chặn tạm đúng khoảnh khắc người dùng bấm gửi một câu có điểm send-risk cao.

Cách hoạt động: bắt phím Enter **không kèm Shift** ngay trong hook bàn phím sẵn có, đối chiếu ứng
dụng đang focus với allow-list, hỏi hợp đồng `core/mood/BreathingPause`, rồi nuốt đúng phím Enter đó
và hiện khung hai lựa chọn. Chọn "vẫn gửi" thì phát lại một sự kiện Enter thật có gắn dấu nguồn
riêng để hook tự bỏ qua, tránh vòng lặp tự chặn chính mình.

Chi tiết hợp đồng và các hạn chế đã biết: [tầng 04](04-contracts.md).

**Trạng thái:**

- macOS — có code, build-verified. Allow-list hiện chỉ gồm hai ứng dụng đã xác minh định danh thật
  trên máy dev. Có công tắc bật/tắt riêng, độc lập với nhật ký.
- Windows — có code, CI xanh. Allow-list **rỗng mặc định** vì máy dev là macOS nên không xác minh
  được tên tiến trình Windows; người dùng tự thêm ứng dụng qua menu khay.
- **Chưa có bằng chứng E2E trên bất kỳ vỏ nào.** Đây là lỗ hổng lớn nhất của dự án tính đến nay.

---

## C. Đọc cảm xúc và nhật ký

### Chấm điểm send-risk

Một bản `core/mood/SendRiskAnalyzer` dùng chung cho cả ba vỏ. Cơ chế hiện tại là **lexicon có trọng
số** cộng công thức bão hòa `risk = 1 − e^(−raw/5)`, nên cộng bao nhiêu cũng chỉ tiệm cận 1.

Điểm mù đã biết và **cố ý công khai**: phủ định ("không vui" bị đọc thành "vui"), cường độ ("hơi
bực" bằng "bực điên lên"), mỉa mai, vốn từ còn mỏng. Ngoài ra có điểm mù kiến trúc không model nào
chữa được — chỉ thấy khi bộ gõ bật và đang ở chế độ tiếng Việt.

**Bằng chứng:** 27 ca kiểm trong `tests/core/test_send_risk`, số kỳ vọng lấy từ lần chạy đối chiếu
thật chứ không tự nghĩ ra.

### Nhịp lấy mẫu và kho dữ liệu

Mỗi nhịp chuông ghi đúng một mẫu là trung bình các điểm trong nhịp. **Không gõ thì không ghi mẫu.**
Tắt chuông là tắt tiếng, không tắt việc ghi nhận.

Kho dữ liệu mã hóa at-rest, khác nhau theo vỏ vì lý do hạ tầng: macOS và iOS dùng SQLite mã hóa
AES-256 với khóa trong Keychain; Windows dùng tệp phẳng TSV mã hóa toàn tệp bằng DPAPI, ghi nguyên
tử qua tệp tạm. Schema giữ **bất biến** giữa các vỏ: `ts`, `event_type`, `send_risk`,
`app_bundle_id`, `choice`.

Chưa đồng ý thì không tạo file — kể cả các hàm chỉ đọc cũng không được tạo kho rỗng.

**Bằng chứng:** `make test-macos` chạy `tests/macos/mood_pipeline` — chuỗi gõ → nhịp → ghi → đọc, có
ca kiểm chứng minh tệp at-rest đúng là ciphertext. iOS có 6 ca host kiểm mã hóa và cổng consent,
gồm cả kiểm chứng phủ định "không có plaintext trên đĩa".

### Nhắc thụ động và chuông

Popup nhắc khi một câu vượt ngưỡng cứng, có cooldown. Chuông ngân theo nhịp định kỳ và theo chuỗi
câu căng liên tiếp. Ba bộ tiếng thiết kế sẵn cộng tùy chọn nạp tiếng riêng. Có khung tự thuật "mặt
hồ đang thế nào" xuất hiện sau nhịp chuông.

---

## D. Nhìn lại

- **Dòng sông cảm xúc** — đồ thị theo Ngày, Tuần, Tháng. Chấm đặc là mẫu tự động, vòng rỗng là lần
  tự thuật. Hai mẫu cách nhau quá 1.5 lần nhịp thì ngắt nét thay vì nội suy.
- **Đầu sóng sống** — biên độ hiện tại làm mượt bằng EMA, phai dần về phẳng lặng sau 5 phút không
  gõ. Có trên macOS; Windows còn thiếu tầng này.
- **Màn Soi lại** — ba nhịp Nhận ra / Soi / Nuôi dưỡng, kèm câu mô tả theo buổi trong ngày.
- **Nhật Ký Tâm** — chồng ghi chú tay, chỉ hiện ngày có viết. Ghi chú được **chừa ra** khỏi cơ chế
  tự xóa theo hạn, vì xóa chữ người dùng tự viết mà chưa ai đọc lại được thì tệ hơn là giữ.
- **Câu chữ tóm tắt** — sinh từ một nguồn duy nhất `MoodPhrasing_DayShapeSentence()`, chia ngày bốn
  buổi. Không có AI sinh câu, không random: cùng dữ liệu luôn ra cùng câu.

---

## E. Riêng tư và kiểm soát

- Cổng đồng ý hỏi một lần vào lúc bình thường, không phải giữa lúc người dùng đang bực.
- Tắt lớp cảm xúc bất cứ lúc nào; xóa sạch nhật ký bất cứ lúc nào.
- Xuất CSV — bản xuất **hẹp hơn** kho tại chỗ, cố ý bỏ tên ứng dụng và lựa chọn, vì tệp CSV không
  còn được mã hóa.
- Tự xóa theo hạn, mặc định 90 ngày, chừa ô ghi chú.
- **Loại trừ ô mật khẩu** — có trên iOS (kiểm bằng audit tĩnh) và Windows (theo dõi sự kiện focus
  trên luồng riêng, hỏi Win32 rồi hỏi UI Automation, mặc định fail-closed).

---

## F. Vận hành và nhận diện

- Nhận diện sinh từ một nguồn `brand/tokens.json` cho cả ba vỏ; có cổng chống trôi lệch.
- `make brand-lint` cưỡng chế luật nhận diện, chặn ở CI, git pre-commit và hook agent.
- Tự tắt bộ gõ đối thủ đang chạy (allow-list định danh đã xác minh), chống chạy trùng instance.
- Đóng gói `.dmg` cho macOS và `.exe` cho Windows trong cùng một Release.

---

## Khoảng trống lớn nhất hiện nay

1. **Feature #1 chưa có bằng chứng E2E** trên bất kỳ vỏ nào — chưa ai đi trọn luồng gõ câu giận
   trong ứng dụng chat thật rồi quan sát khung gác cổng.
2. **Vỏ Windows còn nhiều tầng chưa nối dây** sau nghiệm thu tay lần đầu: hit-test một số tab, sóng
   sống, và credit GPL bị một lần đổi tên hàng loạt làm sai. Phần credit chạm pháp lý.
3. **iOS chưa có device-verify** — toàn bộ mới ở mức build-verified và test host.
4. **Hai bản từ điển từng tồn tại song song** giữa các vỏ; việc hợp nhất về một nguồn đã làm nhưng
   cần giữ kỷ luật để không tái diễn.
