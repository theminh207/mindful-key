# QA-WINDOWS — kịch bản kiểm thử trước khi đóng gói .exe cho người dùng

**Lập:** 2026-07-17 · **Theo:** `.claude/skills/mindful-test-design` (Risk-Based + "verify đừng đoán")
**Chuẩn hành vi:** `platforms/apple/macos/` · **Luật tối cao:** `docs/AGENT-BRIEF.md`

> ⚠️ **Vì sao tài liệu này tồn tại:** máy dev là macOS. CI `windows-latest` chỉ chứng minh
> **compile + link** — nó KHÔNG chứng minh gõ ra đúng chữ, không chứng minh popup hiện đúng chỗ,
> không chứng minh màu đúng brand. Toàn bộ phần đó cần **mắt người trên máy Windows thật**.
> Không có bước này thì bản `.exe` giao cho người dùng là hàng chưa ai thử.

---

## 0. Cần gì để chạy kịch bản này

- Một máy **Windows 10/11 64-bit** bất kỳ (máy thật, máy ảo, PC mượn).
- **KHÔNG cần cài Visual Studio.** Tải `.exe` từ Actions → run "Windows" → mục *Artifacts* →
  `mindful-key-windows-Release-x64`.
- Notepad (hoặc bất cứ ô nhập chữ nào).

---

## 1. Xếp rủi ro (Risk-Based) — cho vỏ Windows

| Mức | Vùng | Vì sao nguy | Cách kiểm |
|---|---|---|---|
| 🔴 **Cao** | **Hook bàn phím bị Windows gỡ** | `LowLevelHooksTimeout` (mặc định 300ms): hook chạy lâu là Windows **âm thầm gỡ**, không báo lỗi. Triệu chứng: đang gõ tự nhiên hết ra dấu. Đây là rủi ro RIÊNG Windows, macOS không có | §3 ca T7 |
| 🔴 **Cao** | Gõ Telex/VNI ra dấu | Việc lõi. Engine dùng chung đã PASS ở tầng unit dưới MSVC, nhưng **chưa ai gõ thật qua vỏ** | §3 ca T1–T6 |
| 🔴 **Cao** | Riêng tư: ô mật khẩu | Chạm cột trụ riêng tư. Test cả điều **KHÔNG được xảy ra** | §5 ca P1–P3 |
| 🟠 **Vừa** | Lớp cảm xúc (ngưỡng, cooldown) | Sai ngưỡng = nhắc bừa (phiền) hoặc câm (vô dụng) | §4 ca M1–M6 |
| 🟠 **Vừa** | Màu brand (COLORREF đảo byte) | Truyền hex thẳng vào GDI ra **sai màu mà build vẫn sạch**: teal `#1D7C91` → `#917C1D` cam đất | §6 ca B1 |
| 🟡 **Thấp** | DPI, layout, chuỗi tràn control | Xấu, không hại | §6 ca B2–B3 |

---

## 2. Nguyên tắc của mọi ca dưới đây

Kỳ vọng **không chép từ trí nhớ**. Cột "Màn hình phải ra" và cột "risk" lấy từ **một lần chạy thật
chuỗi `Telex → engine → MoodBuffer → SendRiskAnalyzer`** (2026-07-17), và khớp khít các con số đã
khoá regression trong `tests/core/test_engine.cpp` + `tests/core/test_send_risk.cpp`.

> 🔑 **HÀNH VI PHẢI BIẾT TRƯỚC KHI TEST — không thì báo nhầm bug:**
> Engine chỉ giao một từ cho lớp cảm xúc **khi từ TIẾP THEO bắt đầu** (`emitCommittedWord()` chỉ
> được gọi từ `startNewSession()` — `core/engine/Engine.cpp:477`). Gõ `ddm` rồi **ngồi im là
> KHÔNG hiện gì**. Phải gõ **dấu cách** sau đó. Đây là hành vi ĐÚNG, không phải lỗi.

---

## 3. E2E — Gõ tiếng Việt (làm trong Notepad)

Bật bộ gõ, chế độ **Tiếng Việt + Telex**.

| # | Gõ đúng chuỗi này | Màn hình PHẢI ra | Nguồn kỳ vọng |
|---|---|---|---|
| T1 | `xin chaof cacs banj` | `xin chào các bạn` | đã khoá `test_engine.cpp` |
| T2 | `tieengs vieetj` | `tiếng việt` | đã khoá |
| T3 | `hoom nay meejt quas` | `hôm nay mệt quá` | đã khoá |
| T4 | `nawm` · `hown` · `tuw` | `năm` · `hơn` · `tư` | đã khoá (biến hình aw/ow/uw) |
| T5 | `dddi` | `ddi` | đã khoá — gõ `đ` lần 3 trả lại chữ gốc |
| T6 | `hello` | `hello` | đã khoá — từ tiếng Anh **không bị bỏ dấu bừa** |
| T7 | **Gõ liên tục thật nhanh ~30 giây** (giữ phím, gõ ẩu) rồi thử `tieengs vieetj` | Vẫn ra `tiếng việt` | 🔴 **Ca quan trọng nhất của Windows.** Nếu sau một lúc gõ mà **hết ra dấu** → Windows đã gỡ hook vì quá `LowLevelHooksTimeout` |

**T7 fail trông như thế nào:** không có thông báo lỗi nào cả. Chỉ là đang gõ ngon rồi tự nhiên
chữ ra không dấu, phải tắt/bật lại app mới gõ tiếp được. Nếu thấy → **DỪNG, báo ngay**, đừng đóng gói.

---

## 4. E2E — Lớp cảm xúc (ngưỡng 0.5)

> Nhớ: gõ xong **phải gõ thêm dấu cách** thì lớp cảm xúc mới nghe thấy.

| # | Gõ | Màn hình ra | risk | Phải xảy ra |
|---|---|---|---|---|
| M1 | `tooi vui` + dấu cách | `tôi vui` | 0.0000 | **KHÔNG hiện gì** |
| M2 | `tooi giaanj` + dấu cách | `tôi giận` | 0.3297 | **KHÔNG hiện gì** — dưới ngưỡng 0.5. Ca phản trực giác, chứng minh ngưỡng có tác dụng thật |
| M3 | `hoom nay meejt quas` + dấu cách | `hôm nay mệt quá` | 0.0676 | **KHÔNG hiện gì** |
| M4 | `ddm` + dấu cách | `đm` | 0.5507 | **HIỆN** hộp "Nhắc tâm - Mindful Keyboard", nội dung: *"Câu bạn vừa gõ nghe đang giận. Khoan gửi đã, hít thở 10 giây rồi hãy quyết định nhé."* |
| M5 | `ddijt mej` + dấu cách | `địt mẹ` | 0.8347 | **HIỆN** cùng nội dung như M4 |
| M6 | Ngay sau M4, bấm OK, gõ lại `ddm` + dấu cách **trong vòng 15 giây** | `đm` | 0.5507 | **KHÔNG hiện lại** — cooldown 15s. Chờ quá 15 giây gõ lại thì **hiện** |

**Kiểm nhận diện của chính hộp thoại (HIẾN CHƯƠNG §2.2):**
- [ ] Nội dung viết **thường**, giọng quan sát: KHÔNG có chữ "GIẬN"/"BUỒN" viết hoa dán nhãn.
- [ ] KHÔNG emoji mặt cười/mếu, KHÔNG đèn đỏ/xanh, KHÔNG điểm số/streak/huy hiệu.
- [ ] Không có câu nào nghe như khiển trách.

---

## 4b. E2E — Gác cổng gửi tin (Feature #1)

> **Danh sách app RỖNG lúc mới cài** — cố ý. Máy dev là macOS nên không xác minh được tên tiến
> trình Windows của Zalo/Discord, và luật dự án cấm bịa. Người dùng tự thêm app đang mở qua menu
> khay. **Lợi cho QA:** test được ngay trong **Notepad**, không cần cài app chat nào.

| # | Bước | Phải xảy ra |
|---|---|---|
| G0 | Mở Notepad → bấm icon khay → xem menu | Có mục **"Gác cổng gửi tin cho app này"**, **chưa** có dấu tích |
| G1 | Bấm mục đó → mở lại menu | Giờ **có dấu tích** (đã thêm `notepad.exe`) |
| G2 | Trong Notepad gõ `tooi vui` + dấu cách, rồi bấm **Enter** | Xuống dòng **bình thường** — risk 0.0, không gác |
| G3 | Gõ `tooi giaanj` + dấu cách, rồi **Enter** | Xuống dòng **bình thường** — risk 0.3297, **dưới ngưỡng** |
| G4 | Gõ `ddm` + dấu cách, rồi **Enter** | 🔴 **Enter bị NUỐT** (không xuống dòng) + hiện hộp **"Mindful Keyboard"** với 2 nút **"Đợi chút"** / **"Vẫn gửi"** |
| G5 | Ở hộp G4 bấm **"Vẫn gửi"** | Hộp đóng, con trỏ **xuống dòng ngay** (Enter được gửi lại). Đây là **cam kết không chặn cứng** — phải luôn đúng |
| G6 | Lặp G4, bấm **"Đợi chút"** | Hộp đóng, **KHÔNG** xuống dòng. Chữ vẫn còn nguyên để sửa |
| G7 | Lặp G4, **không bấm gì**, chờ ~3 giây | Hộp tự đóng, **KHÔNG** xuống dòng (hết giờ = Dismissed, không suy thành gửi) |
| G8 | Lặp G4, khi hộp hiện thì bấm **Enter** trên bàn phím | Chọn **"Đợi chút"** (nút mặc định) — bấm Enter theo quán tính phải là dừng lại, không phải gửi |
| G9 | Gõ `ddm` + dấu cách, **Shift+Enter** | Xuống dòng **bình thường**, không gác (Shift+Enter = xuống dòng, không phải gửi) |
| G10 | Bỏ tích ở menu khay → gõ `ddm` + dấu cách → Enter | Xuống dòng bình thường, **không gác nữa** |
| G11 | Tắt app, mở lại, xem menu khay | Dấu tích **vẫn còn** (danh sách lưu registry, sống qua lần chạy) |

**Bẫy dễ báo nhầm bug:** ở G4 **phải gõ dấu cách sau `ddm`** trước khi bấm Enter. Engine chỉ giao
từ cho lớp cảm xúc khi từ tiếp theo bắt đầu — gõ `ddm` rồi Enter luôn thì risk vẫn là của câu
TRƯỚC đó, nên không gác. **Đây là hạn chế đã biết, bản macOS cũng y hệt** (ghi ở `OpenKey.mm` +
`docs/BREATHING-PAUSE-CONTRACT.md`), không phải lỗi riêng Windows.

---

## 5. Bất biến riêng tư — test cả điều KHÔNG được xảy ra

| # | Kịch bản | Bất biến |
|---|---|---|
| P1 | Gõ `ddm` + dấu cách vào **ô mật khẩu** (vd màn đăng nhập Windows, ô password trên web) | **KHÔNG** hiện hộp nhắc. Không có gì được đọc/ghi |
| P2 | Bật app, gõ 5 phút, mở Task Manager → tab **Performance → Network** hoặc Resource Monitor lọc theo tiến trình | **0 kết nối mạng** mang nội dung gõ |
| P3 | Tắt "Nhắc tâm (cảm xúc)" trong cửa sổ Điều khiển, gõ `ddijt mej` + dấu cách | **KHÔNG** hiện gì |

> P1 là ca 🔴: hiện tại vỏ Windows **chưa có** cơ chế phát hiện ô mật khẩu (bản macOS/iOS có).
> Nếu P1 FAIL → **đây là lỗi chặn phát hành**, không phải "cải thiện sau".

---

## 6. Nhận diện & hiển thị

| # | Kiểm | Đạt khi |
|---|---|---|
| B1 | Bất kỳ chỗ nào tô màu brand (khi GĐ6 xong) | Teal phải là **xanh mòng két `#1D7C91`**, KHÔNG phải cam đất `#917C1D`. Sai màu này = quên `MK_COLORREF()`, byte bị đảo — build vẫn sạch nên chỉ mắt người bắt được |
| B2 | Đặt Windows ở **150% / 200% scaling**, mở mọi cửa sổ | Chữ không tràn/không đè, nút không bị cắt |
| B3 | Mở hộp **Giới thiệu** | Có dòng **"Dựa trên OpenKey — Mai Vũ Tuyên (GPL v3)"**, không bị cắt chữ (GPL — bắt buộc) |
| B4 | Icon trên khay hệ thống + icon app | ⚠️ Hiện vẫn là icon OpenKey gốc — **đã biết, chưa sửa** (GĐ6). Không tính là fail ở vòng này |

---

## 7. Definition of Done — chốt trước khi đóng gói `.exe`

### Cổng máy (tự động, không cần người)
- [ ] `make test` XANH — 8 bộ, 0 fail
- [ ] CI **Windows** xanh: engine dưới MSVC + build Debug **và** Release x64
- [ ] CI **macOS** xanh (không làm hỏng đội khác)
- [ ] `make brand-lint` — 0 vi phạm (nay đã phủ `.cpp` vỏ Windows)
- [ ] `make brand-palette-check` — bảng màu khớp `tokens.json`
- [ ] `git diff core/` **rỗng** nếu thay đổi chỉ thuộc Windows

### Cổng người (bắt buộc — không ai thay được)
- [ ] **T1–T6** PASS trên Windows thật
- [ ] **T7** PASS — gõ nhanh 30s không mất hook 🔴
- [ ] **M1–M6** PASS — đặc biệt M2 (dưới ngưỡng thì im) và M6 (cooldown)
- [ ] **G0–G11** PASS — đặc biệt **G5** ("Vẫn gửi" phải gửi được NGAY — cam kết không chặn cứng, vỡ cái này là vỡ hiến chương) và **G7** (hết giờ ≠ gửi)
- [ ] **P1–P3** PASS — P1 là cổng chặn phát hành
- [ ] **B2–B3** PASS
- [ ] Ca chập chờn (hook, popup) → **PASS 2 lần liên tiếp** mới tính

### Cổng sổ sách
- [ ] `docs/TEST_MATRIX.md` ghi ca đã chứng minh, cột bằng chứng trỏ tới thứ có thật
- [ ] Chỗ phải đoán → `docs/FRICTION-LOG.md`
- [ ] Còn nợ đã biết (icon khay, ô mật khẩu…) → ghi RÕ trong release notes, **không giấu**

### Cổng chủ dự án
- [ ] Chốt: chứng chỉ Authenticode (chưa có → SmartScreen báo "Unknown publisher")
- [ ] Chốt: link Facebook OpenKeyVN · `CompanyName` · tên `OpenKey64.exe` trong bộ cài

---

## 8. Mẫu báo cáo (giọng mô tả, KHÔNG gamify)

```
QA Windows — bản <sha> — <ngày> — máy: Windows 11 23H2, 150% scaling

Gõ tiếng Việt : T1..T6 PASS · T7 PASS (gõ nhanh 40s, hook còn sống)
Lớp cảm xúc   : M1..M5 PASS · M6 FAIL — nhắc lại sau 6 giây, cooldown không ăn
Riêng tư      : P1 FAIL — ô mật khẩu VẪN hiện nhắc · P2 PASS · P3 PASS
Nhận diện     : B2 PASS · B3 PASS · B4 skip (đã biết)

Chặn phát hành: P1, M6
```

> Không chấm điểm, không xếp hạng, không streak — kể cả trong báo cáo test. Hiến chương áp cho cả
> cách ta nói về công việc, không chỉ cho UI.
