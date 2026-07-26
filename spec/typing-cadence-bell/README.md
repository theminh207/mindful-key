# Typing Cadence Bell — đo nhịp gõ, ngân chuông tỉnh thức

> **Đây là nơi làm việc của cả đợt chuyển đổi này.** Kế hoạch nằm ở file này, tiến độ ghi ở
> [PROGRESS.md](PROGRESS.md). Ai làm issue nào cũng đọc file này trước và cập nhật lại sau khi xong.

| | |
|---|---|
| **Bắt đầu** | 2026-07-26 |
| **Hiến chương** | [`docs/01-intent.md`](../../docs/01-intent.md) — luật tối cao, đã sửa |
| **Issue** | [#3 → #18](https://github.com/theminh207/mindful-key/issues) trên GitHub |
| **Trạng thái** | Phase 0 chưa bắt đầu |

---

## 1. Đổi cái gì

Bỏ **Sense** (đọc nội dung câu để đoán cảm xúc) và bỏ **Pause** (gác cổng nút gửi). Thay bằng phép đo
duy nhất: **tốc độ gõ**.

```
CŨ:   Sense  →  Pause  →  Remind  →  Reflect
MỚI:  Measure  →  Bell  →  Reflect
```

- **Measure** — đo **ký tự/phút (CPM)** trên cửa sổ trượt. Chỉ đếm nhịp phím, không đọc ký tự.
- **Bell** — vượt ngưỡng thì ngân **một tiếng chuông**. Chỉ âm thanh. Không khung nổi, không chặn phím.
- **Reflect** — ghi lại mỗi lần chuông, màn soi lại đếm số lần theo thời gian.

**Ngưỡng thuộc về người dùng** — mỗi người một nhịp tay, sản phẩm không tự quyết hộ.

## 2. Vì sao đổi

Nhịp gõ đo được mà **không cần đọc chữ**. Lời hứa riêng tư từ chỗ "chúng tôi có đọc nhưng không lưu"
chuyển thành "chúng tôi không đọc" — mạnh hơn hẳn, và kiểm chứng được bằng cách nhìn vào code.

Đánh đổi phải nói thẳng: gõ nhanh **không luôn** có nghĩa tâm đang động, và sản phẩm mất khả năng
nhận ra một câu tiêu cực sắp gửi đi. Chuông là **lời mời để ý**, không phải kết luận.

## 3. Hình dung đường ống

App hiện tại như một cái máy nước: đầu nguồn là **máy đọc chữ** (chấm điểm cảm xúc), giữa đường có
**van chặn** (gác cổng lúc gửi), cuối đường là **chuông + cuốn sổ**.

Việc của đợt này: thay máy đọc chữ bằng **đồng hồ đo nhịp tay**, tháo hẳn cái van. Chuông, sổ, con
sóng, màn cài đặt **giữ nguyên** — đó là lý do đây không phải viết lại từ đầu.

## 4. Bảng tiến độ

Trạng thái: `⬜ chưa bắt đầu` · `🔄 đang làm` · `✅ xong` · `⏸ chặn`

### Phase 0 — Chốt luật (docs/ADR)

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#3](https://github.com/theminh207/mindful-key/issues/3) | ADR "đo nhịp gõ thay đọc cảm xúc" + 4 ADR cũ thành Superseded | — | |
| ⬜ | [#4](https://github.com/theminh207/mindful-key/issues/4) | Đồng bộ tầng 02/04/06/07 theo vòng lặp mới | #3 | |
| ⬜ | [#5](https://github.com/theminh207/mindful-key/issues/5) | Đồng bộ `docs/tasks/` + harness `.claude/` | #3 | |

### Phase 1 — Bộ não C++ (`core/`)

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#6](https://github.com/theminh207/mindful-key/issues/6) | `core/mood/TypingCadence` — đo CPM trên cửa sổ trượt | #3 | |
| ⬜ | [#7](https://github.com/theminh207/mindful-key/issues/7) | `core/mood/BellPolicy` — chính sách reo chuông dùng chung 3 vỏ | #6 | |
| ⬜ | [#8](https://github.com/theminh207/mindful-key/issues/8) | Con sóng đổi nguồn: biên độ theo nhịp gõ | #6 | |

### Phase 2 — macOS (công dân hạng nhất, chạy thật trước)

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#9](https://github.com/theminh207/mindful-key/issues/9) | Nối nhịp gõ vào mạch chuông | #6 #7 #8 | |
| ⬜ | [#10](https://github.com/theminh207/mindful-key/issues/10) | Người dùng chọn ngưỡng tốc độ trong màn Chuông | #9 | |
| ⬜ | [#11](https://github.com/theminh207/mindful-key/issues/11) | Kho ghi số lần chuông + màn soi lại | #9 | |

### Phase 3 — Gỡ đồ cũ

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#12](https://github.com/theminh207/mindful-key/issues/12) | Gỡ nhánh gác cổng gửi tin | #9 | |
| ⬜ | [#13](https://github.com/theminh207/mindful-key/issues/13) | Gỡ nhánh đọc cảm xúc + `models/` | #8 #9 #15 #17 | |
| ⬜ | [#14](https://github.com/theminh207/mindful-key/issues/14) | Câu chữ onboarding/riêng tư + xử lý nhật ký cũ | #11 #12 | |

### Phase 4 — Windows

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#15](https://github.com/theminh207/mindful-key/issues/15) | Nối nhịp gõ vào `Bell.cpp` + icon khay | #6 #7 #8 | |
| ⬜ | [#16](https://github.com/theminh207/mindful-key/issues/16) | Chọn ngưỡng + kho DPAPI + màn soi lại | #15 | |

### Phase 5 — iOS

| | Issue | Việc | Chặn bởi | Người làm |
|---|---|---|---|---|
| ⬜ | [#17](https://github.com/theminh207/mindful-key/issues/17) | Đo nhịp trong keyboard extension + tín hiệu chuông | #6 #7 #8 | |
| ⬜ | [#18](https://github.com/theminh207/mindful-key/issues/18) | Chọn ngưỡng qua App Group + nhật ký mặt hồ | #17 | |

## 5. Quyết định đang mở

Chưa chốt thì **đừng tự quyết trong im lặng** — hỏi chủ dự án, rồi ghi câu trả lời vào đây kèm ngày.

| # | Câu hỏi | Chốt ở | Trạng thái |
|---|---|---|---|
| Q1 | Ngưỡng CPM mặc định là bao nhiêu? Các mức cho user chọn đặt tên gì? | #3 | ❓ chưa chốt |
| Q2 | Cửa sổ trượt dài bao nhiêu giây? | #3 | ❓ chưa chốt |
| Q3 | Nhịp phím lấy từ đâu — (A) từng phím ở hook bàn phím, hay (B) tại điểm kết từ qua `vOnWordCommitted`? | #6 | ❓ chưa chốt |
| Q4 | Quy CPM về biên độ sóng `[0,1]` theo công thức nào, và đặt ở đâu để 3 vỏ không trôi lệch? | #8 | ❓ chưa chốt |
| Q5 | Có đếm nhịp trong ô mật khẩu không? | #9 | ❓ chưa chốt |
| Q6 | Nhật ký cũ trên máy người dùng: xoá sạch hay giữ đọc song song? | #11 | ❓ chưa chốt |
| Q7 | Giữ hay bỏ check-in tự thuật "Mặt hồ đang thế nào?" (người dùng tự nói, không phải máy đoán) | #11 | ❓ chưa chốt |
| Q8 | Bàn phím iOS có phát được tiếng chuông trong app extension không? Không được thì thay bằng gì? | #17 | ❓ chưa chốt |

**Đã chốt:**

- 2026-07-26 — Bỏ **hẳn** lớp sentiment, không giữ lại để ghi nhật ký.
- 2026-07-26 — Đơn vị đo là **CPM (ký tự/phút)**, không phải WPM. Telex/VNI gõ dấu tốn thêm phím nên đếm "từ" bị méo.

## 6. Ba cái bẫy đã biết trước

**Đừng để một mảnh logic tồn tại hai bản.** Lexicon send-risk từng có 2 bản ở macOS và iOS rồi trôi
lệch thật (macOS coi dấu câu là dấu tách từ, iOS thì không). Chính sách chuông hiện cũng đang có 2
bản chép tay — `NudgeCoordinatorIOS.h` tự thú là "sao y bản chính từ macOS". Vì vậy #7 gom về `core/`
ngay từ đầu, trước khi Windows kịp thành bản thứ ba.

**Lời hứa riêng tư chỉ thật khi code biến mất.** Hiến chương ghi "không đọc nội dung" — chừng nào
`SendRiskAnalyzer` còn trong repo và còn được nạp vào app, câu đó là quảng cáo. #13 quan trọng nhất
Phase 3, nhưng phải đợi cả 3 vỏ chuyển xong, gỡ sớm là vỡ build.

**Người dùng cũ sẽ mất tính năng.** Bản đang phát hành ngoài đời có gác cổng gửi tin và nhật ký theo
thước đo cũ. #14 lo chuyện nói thật. Khuyến nghị: xoá nhật ký cũ chứ đừng trộn — điểm cũ đo bằng
thước khác, vẽ chung một biểu đồ là nói dối người dùng.

## 7. Luật cập nhật — làm xong issue thì phải làm gì

Mỗi lần một issue đóng lại, **cùng trong PR đó** (không để dồn):

1. Đổi ô trạng thái ở [§4](#4-bảng-tiến-độ) sang `✅` và điền tên người làm.
2. Thêm một mục vào [PROGRESS.md](PROGRESS.md): ngày · issue · làm gì · **quyết định đã chốt** ·
   chỗ nào phải đoán.
3. Có quyết định nào ở [§5](#5-quyết-định-đang-mở) được chốt → chuyển xuống mục "Đã chốt" kèm ngày
   và lý do. Đây là thứ session sau và đồng đội sau đọc để khỏi hỏi lại.
4. Phát sinh câu hỏi mới → thêm vào bảng §5, đừng giấu trong đầu.
5. Chỗ nào phải **đoán** vì tài liệu không nói rõ → ghi thêm vào
   [`docs/tasks/FRICTION-LOG.md`](../../docs/tasks/FRICTION-LOG.md), đúng chỗ nó sinh ra để ghi.

Cổng chất lượng trước khi coi là xong (theo `CLAUDE.md`): `make test` xanh · `make build` sạch, không
thêm warning · `make brand-lint` 0 vi phạm · CI xanh.
