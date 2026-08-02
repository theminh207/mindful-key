# 02 — Features

> Tầng mô tả **hiện trạng**: sản phẩm đang làm được gì, trên vỏ nào, và đã được chứng minh tới đâu.
> Khác với [tầng Intent](01-intent.md) vốn mô tả điều phải đúng mãi mãi, tầng này đổi theo mỗi lần
> ship. Khi tài liệu và code lệch nhau ở tầng này thì **code là đúng**, tài liệu phải sửa theo.
>
> Cập nhật gần nhất: 2026-08-01 · phiên bản `0.4.24`.
> Bằng chứng chi tiết từng dòng: `tasks/TEST_MATRIX.md`.

> 🔄 **Đang giữa một đợt chuyển mô hình.** [Tầng Intent](01-intent.md) đã chuyển sang vòng lặp
> `Measure → Bell → Reflect`, nhưng code ba vỏ **chưa** chuyển xong. Tầng này mô tả hiện trạng nên
> nó ghi cả hai: thứ đang chạy (mô hình cũ, đang gỡ) và thứ sắp có (mô hình mới, chưa khởi công).
> Lộ trình và trạng thái từng issue: [`spec/typing-cadence-bell/`](../spec/typing-cadence-bell/README.md).
> Đừng đọc bảng dưới như thể mô hình mới đã chạy — cột **Trạng thái** nói thật.

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
| **Đo nhịp gõ (CPM)** | chưa khởi công (#9) | chưa khởi công (#15) | chưa khởi công (#17) | chưa |
| **Chuông theo nhịp gõ** | chưa khởi công (#9) | chưa khởi công (#15) | chưa khởi công (#17) | chưa |
| **Người dùng chọn ngưỡng** | chưa khởi công (#10) | chưa khởi công (#16) | chưa khởi công (#18) | chưa |
| Nhật ký + màn soi lại | có (schema cũ, đổi ở #11) | có (schema cũ, đổi ở #16) | có (schema cũ) | chưa |
| ~~Chuông theo nhịp lấy mẫu / chuỗi câu căng~~ | có (đổi nguồn ở #9) | có (đổi nguồn ở #15) | có (đổi nguồn ở #17) | không |
| ~~Gác cổng trước khi gửi~~ | đang gỡ (#12) | đang gỡ (#12) | **không bao giờ có** | không |
| ~~Chấm điểm send-risk~~ | đang gỡ (#13) | đang gỡ (#13) | đang gỡ (#13) | không |

Ba dòng gạch ngang **không phải cùng một loại**, đừng đọc gộp:

- **Gác cổng trước khi gửi** và **chấm điểm send-risk** là **non-goal** kể từ 2026-07-26 — xem
  [tầng Intent §5](01-intent.md). Chúng còn trong bảng vì code còn trong repo, không phải vì còn
  được mong muốn.
- **Chuông theo nhịp lấy mẫu / chuỗi câu căng** thì **không** phải non-goal. Sản phẩm hôm nay đã có
  tiếng chuông thật; chỉ có *nguồn nuôi nó* là chết — nó đang ngân theo nhịp lấy mẫu định kỳ và theo
  chuỗi câu có điểm send-risk cao. Việc của #9/#15/#17 là **đổi nguồn sang nhịp gõ**, không phải
  dựng tiếng chuông từ đầu. Gạch ngang ở đây nghĩa là "cơ chế kích hoạt này sắp biến mất", không
  phải "tính năng này bị bỏ".

---

## A. Bộ gõ tiếng Việt

Lõi kế thừa OpenKey, đặt tại `core/engine`, dùng chung mọi hệ điều hành. **Phần này không bị đợt
chuyển mô hình đụng tới.**

- Gõ **Telex / VNI / VIQR** ra dấu, xuất Unicode và các bảng mã khác.
- Luật ghép vần và bỏ dấu (`Vietnamese.cpp`).
- **Gõ tắt** (macro) — thay chuỗi viết tắt bằng cụm dài.
- **Chuyển mã** giữa các bảng mã.
- **Tự chuyển Việt/Anh** theo ứng dụng (`SmartSwitchKey`).
- Kiểm tra chính tả, phím tắt bật/tắt bộ gõ.

**Bằng chứng:** `make test-core` chạy `tests/core/test_engine`. Engine đã được chứng minh chạy dưới
cả clang (macOS) lẫn MSVC (CI Windows). Còn thiếu ca kiểm riêng cho luật ghép vần nâng cao.

---

## B. Chuông tỉnh thức theo nhịp gõ — Feature #1

Trái tim sản phẩm. Đo tốc độ tay đang gõ; vượt mức người dùng đặt thì ngân **một tiếng chuông**.

Cách hoạt động dự kiến: mỗi lần bấm phím, vỏ báo **một dấu thời gian** (không báo phím nào) cho
`core/mood/TypingCadence`; lớp này giữ cửa sổ trượt 30 giây và tính CPM. `core/mood/BellPolicy` so
CPM với ngưỡng người dùng đặt, cộng khoảng lặng giữa hai lần chuông, rồi trả lời có ngân hay không.
Vỏ nhận `true` thì phát tiếng — và **chỉ** phát tiếng.

Ba tham số đã chốt ở [ADR-0013](03-decisions/ADR-0013-do-nhip-go-thay-doc-cam-xuc.md): đơn vị **CPM**
(không phải WPM), cửa sổ trượt **30 giây**, ngưỡng mặc định **400 CPM**. Bốn mức người dùng chọn
được: `Nhanh 300` · `Rất nhanh 400` · `Cực nhanh 500` · `Tắt chuông` — tên mức luôn hiện kèm con số.

Hợp đồng đầy đủ và các ràng buộc: [tầng 04](04-contracts.md) HĐ-1 → HĐ-4.

**Trạng thái: chưa khởi công trên mọi vỏ.** `core/mood/TypingCadence` và `core/mood/BellPolicy` chưa
tồn tại (issue #6, #7). Ba vỏ chưa nối dây (#9 macOS, #15 Windows, #17 iOS). Đây là trạng thái thật
tính đến 2026-08-01, không phải thiếu sót trong tài liệu.

**Vùng mù đã biết, nói thẳng:**

- Không đếm nhịp trong **ô mật khẩu** (hợp đồng HĐ-4), mặc định fail-closed.
- Chỉ đo được khi bộ gõ đang bật.
- Trên iOS, chỉ đo được khi người dùng đang dùng chính bàn phím mindful-key — sandbox không cho
  thấy phím gõ ở bàn phím khác. Xem
  [ADR-0014](03-decisions/ADR-0014-ios-mandate-hep-do-nhip-trong-ban-phim.md).
- **Gõ nhanh không luôn có nghĩa tâm đang động.** Chép chính tả, gõ lại đoạn đã nghĩ xong, hay đơn
  giản là tay nhanh, đều vượt ngưỡng. Chuông là lời mời để ý, không phải kết luận — giới hạn này
  phải được nói ngay từ onboarding ([tầng Intent §4.2](01-intent.md)).

---

## C. Nhật ký và kho dữ liệu

### Nhịp lấy mẫu và kho dữ liệu

Mỗi nhịp ghi đúng một mẫu. **Không gõ thì không ghi mẫu.** Tắt chuông là tắt tiếng, không tắt việc
ghi nhận.

Kho dữ liệu mã hóa at-rest, khác nhau theo vỏ vì lý do hạ tầng: macOS và iOS dùng SQLite mã hóa
AES-256 với khóa trong Keychain; Windows dùng tệp phẳng TSV mã hóa toàn tệp bằng DPAPI, ghi nguyên
tử qua tệp tạm.

Chưa đồng ý thì không tạo file — kể cả các hàm chỉ đọc cũng không được tạo kho rỗng.

**Schema đang là schema cũ**, còn cột `send_risk` — cột chết theo mô hình mới. Schema mới (ghi thời
điểm chuông, CPM đo được lúc đó, ngưỡng đang đặt) chốt ở issue #11 cho macOS và #16 cho Windows.
`ADR-0011` vốn chốt schema "bất biến" cũ đã bị đánh dấu **Bị thay thế** vì lý do này.

Cách xử lý nhật ký cũ trên máy người dùng **chưa chốt** — xem issue #11. Nguyên tắc dẫn đường có
sẵn ở [tầng 04](04-contracts.md) HĐ-8: không trộn hai thước đo trên cùng một đồ thị.

**Bằng chứng:** `make test-macos` chạy `tests/macos/mood_pipeline` — chuỗi gõ → nhịp → ghi → đọc, có
ca kiểm chứng minh tệp at-rest đúng là ciphertext. iOS có 6 ca host kiểm mã hóa và cổng consent,
gồm cả kiểm chứng phủ định "không có plaintext trên đĩa". Các ca này kiểm **tầng lưu trữ**, phần lớn
vẫn dùng được sau khi đổi schema.

---

## D. Nhìn lại

- **Dòng sông nhịp gõ** — đồ thị theo Ngày, Tuần, Tháng. Chấm đặc là mẫu tự động, vòng rỗng là lần
  tự thuật. Hai mẫu cách nhau quá 1.5 lần nhịp thì ngắt nét thay vì nội suy.
- **Đầu sóng sống** — biên độ hiện tại làm mượt bằng EMA, phai dần về phẳng lặng sau 5 phút không
  gõ. Có trên macOS; Windows còn thiếu tầng này. **Nguồn nuôi biên độ đang là send-risk**, đổi sang
  nhịp gõ ở issue #8.
- **Màn Soi lại** — ba nhịp Nhận ra / Soi / Nuôi dưỡng, kèm câu mô tả theo buổi trong ngày.
- **Nhật Ký Tâm** — chồng ghi chú tay, chỉ hiện ngày có viết. Ghi chú được **chừa ra** khỏi cơ chế
  tự xóa theo hạn, vì xóa chữ người dùng tự viết mà chưa ai đọc lại được thì tệ hơn là giữ.
- **Câu chữ tóm tắt** — sinh từ một nguồn duy nhất `MoodPhrasing_DayShapeSentence()`, chia ngày bốn
  buổi. Không có AI sinh câu, không random: cùng dữ liệu luôn ra cùng câu. Câu chữ phải viết lại
  theo mô hình mới (issue #14) — mọi câu suy ra trạng thái từ **nội dung** đều hết căn cứ.

---

## E. Riêng tư và kiểm soát

- Cổng đồng ý hỏi một lần vào lúc bình thường, không phải giữa lúc người dùng đang bực.
- Tắt lớp nhịp gõ bất cứ lúc nào; xóa sạch nhật ký bất cứ lúc nào.
- Xuất CSV — bản xuất **hẹp hơn** kho tại chỗ, cố ý bỏ tên ứng dụng và lựa chọn, vì tệp CSV không
  còn được mã hóa.
- Tự xóa theo hạn, mặc định 90 ngày, chừa ô ghi chú.
- **Loại trừ ô mật khẩu** — có trên iOS (kiểm bằng audit tĩnh) và Windows (theo dõi sự kiện focus
  trên luồng riêng, hỏi Win32 rồi hỏi UI Automation, mặc định fail-closed). macOS còn thiếu, phải
  bổ sung ở #9 theo hợp đồng HĐ-4.

Sau khi đợt chuyển mô hình xong, lời hứa riêng tư mạnh lên một bậc: từ *"chúng tôi có đọc nội dung
nhưng không lưu"* thành ***"chúng tôi không đọc"*** — và câu sau kiểm chứng được bằng cách đọc code,
vì hợp đồng HĐ-1 cấm mọi API của lớp nhịp gõ nhận tham số chuỗi. Câu chữ onboarding và trang riêng
tư viết lại ở issue #14; chừng nào `SendRiskAnalyzer` còn được nạp vào app thì câu đó **chưa được
phép nói**.

---

## F. Vận hành và nhận diện

- Nhận diện sinh từ một nguồn `brand/tokens.json` cho cả ba vỏ; có cổng chống trôi lệch.
- `make brand-lint` cưỡng chế luật nhận diện, chặn ở CI, git pre-commit và hook agent.
- Tự tắt bộ gõ đối thủ đang chạy (allow-list định danh đã xác minh), chống chạy trùng instance.
- Đóng gói `.dmg` cho macOS và `.exe` cho Windows trong cùng một Release.

---

## Khoảng trống lớn nhất hiện nay

1. **Vòng lặp lõi mới đã có bộ não, nhưng chưa vỏ nào nối dây.** `core/mood/TypingCadence` (#6) và
   `core/mood/BellPolicy` (#7) đã tồn tại và có ca kiểm chạy ở CI — nhưng cả hai vẫn là bộ não rời:
   không vỏ nào (macOS/Windows/iOS) gọi tới chúng, nên người dùng chưa thấy gì đổi. Nối dây ở #9
   (macOS) · #15 (Windows) · #17 (iOS). Tính đến 2026-08-02.
2. **Lời hứa riêng tư chưa được phép nói.** `SendRiskAnalyzer` còn trong repo và còn được nạp vào
   app, nên câu "không đọc nội dung" hiện vẫn là quảng cáo. Issue #13 đóng khoảng cách này, nhưng
   phải đợi cả ba vỏ chuyển xong.
3. **Người dùng bản đang phát hành sẽ mất tính năng.** Bản ngoài đời có gác cổng gửi tin và nhật ký
   theo thước đo cũ. Issue #14 lo phần nói thật với họ.
4. **Vỏ Windows còn nhiều tầng chưa nối dây** sau nghiệm thu tay lần đầu: hit-test một số tab, sóng
   sống, và credit GPL bị một lần đổi tên hàng loạt làm sai. Phần credit chạm pháp lý.
5. **iOS chưa có device-verify** — toàn bộ mới ở mức build-verified và test host.
