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
| 🔴 **Cao** | Riêng tư: ô mật khẩu | Chạm cột trụ riêng tư. Test cả điều **KHÔNG được xảy ra**. Đã vá bằng UI Automation (`SecureField.{h,cpp}`, 2026-07-17) — CHƯA có mắt người xác nhận | §5 ca P1a–P1f |
| 🟠 **Vừa** | Lớp cảm xúc (ngưỡng, cooldown) | Sai ngưỡng = nhắc bừa (phiền) hoặc câm (vô dụng) | §4 ca M1–M6 |
| 🟠 **Vừa** | Màu brand (COLORREF đảo byte) | Truyền hex thẳng vào GDI ra **sai màu mà build vẫn sạch**: teal `#1D7C91` → `#917C1D` cam đất | §6 ca D1 |
| 🟡 **Thấp** | DPI, layout, chuỗi tràn control | Xấu, không hại | §6 ca D2–D3 |

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

## 4c. E2E — Chuông tỉnh thức + tiếng cá nhân hoá (GĐ4)

> Bản cũ KHÔNG phát tiếng nào — chỉ ding mặc định của Windows. Ca B0 dưới là ca **quan trọng
> nhất** của giai đoạn này: nó chứng minh đúng thứ chủ dự án yêu cầu.

| # | Bước | Phải xảy ra |
|---|---|---|
| B0 | Khay → "Chuông tỉnh thức..." → bấm **"Nghe thử"** | 🔴 Nghe **tiếng chuông chùa** — KHÔNG phải tiếng "ding" của Windows. Đây là điều bản cũ làm sai |
| B1 | Đổi ô "Tiếng chuông" sang **Chuông gió** → Nghe thử | Nghe tiếng **khác hẳn** B0 |
| B2 | Đổi sang **Chuông reo** → Nghe thử | Nghe tiếng thứ ba, khác 2 tiếng trên |
| B3 | Đặt Âm lượng **20** → Nghe thử · rồi **100** → Nghe thử | Nghe **nhỏ hẳn** rồi **to hẳn**. Âm lượng app KHÁC phải **không đổi** (mở YouTube kiểm) |
| B4 | Đặt Âm lượng **0** → Nghe thử | **Im hoàn toàn** — có chủ đích, không phải lỗi |
| B5 | Chọn **Im** → Nghe thử | **Im hoàn toàn** |
| B6 | Bấm **"Chọn tệp .wav của tôi..."** → chọn 1 tệp `.wav` bất kỳ | Ô tiếng nhảy sang **"Tiếng của tôi..."** và **phát ngay tệp vừa chọn** |
| B7 | Thử chọn tệp **`.mp3`** | Hộp chọn tệp **không cho thấy** tệp mp3 (chỉ lọc `.wav`). Đây là **khác biệt có chủ đích** với macOS |
| B8 | Chọn tệp `.wav` xong → xoá tệp GỐC đi → Nghe thử | Vẫn **nghe được** (app đã chép vào kho riêng) |
| B9 | Xoá `%LOCALAPPDATA%\MindfulKeyboard\CustomBell.wav` → Nghe thử | Rơi về **Chuông chùa** — KHÔNG rơi về beep hệ thống, KHÔNG im |
| B10 | Đặt "Nhắc mỗi" = **5** → Lưu → mở lại | Hiện **15**, không hiện 5 — sàn 15 phút (quyết định riêng tư 2026-07-15). UI phải nói thật về thứ đang chạy |
| B11 | Bật chuông, đặt nhắc mỗi 15 phút, chờ | Reo **1 lần** kèm hộp nhắc; nội dung quan sát không phán xét |

**Chuỗi câu căng (chuông data-driven):** gõ liên tiếp 3 câu có risk ≥ 0.5 (vd `ddm` + cách,
`ddijt mej` + cách, `ddm` + cách) → chuông rung với câu **khác** chuông theo lịch ("Nãy giờ có vẻ
căng..."). Độ nhạy đổi ngưỡng: registry `vBellSensitivity` 1=ít nhạy (cần 5 câu) · 2=vừa (3) ·
3=nhạy (2).

---

## 4d. E2E — Nhật ký cảm xúc mã hoá (GĐ3)

> **Không SQLite** (chủ dự án chốt): một tệp phẳng `%LOCALAPPDATA%\MindfulKeyboard\mood.enc`, mã
> hoá bằng **DPAPI** (khoá theo tài khoản Windows). Nhật ký **không bao giờ chứa chữ bạn gõ** —
> chỉ thời điểm + điểm số + tên app.

| # | Bước | Phải xảy ra |
|---|---|---|
| J0 | Cài mới, chạy lần đầu | **KHÔNG hộp thoại nào lúc khởi động** — chỉ icon sóng `~` hiện ở khay. (Đổi 2026-07-18: hộp hỏi-lúc-khởi-động chính là bug treo-vô-hình của 0.3.0, đã nhổ. Thấy hộp thoại nào lúc mới mở = **lỗi chặn phát hành**) |
| J0b | Bật lớp cảm xúc trong cửa sổ Điều khiển | Hỏi **hai bước tách nhau**: (1) "Bật lớp cảm xúc?" (quyền ĐỌC sóng) → (2) "Bật nhật ký?" (quyền GHI, nói rõ không chứa nội dung gõ). Đồng ý cái này không kéo theo cái kia |
| J1 | Tắt app, mở lại | **KHÔNG hỏi lại** — hỏi 1 lần trong đời, không phải mỗi lần khởi động |
| J2 | Chọn **Không** ở bước nhật ký (J0b) → gõ `ddm` + cách → Enter (app đã gác) → chọn gì đó | Tệp `mood.enc` **không tồn tại**. Không đồng ý = không ghi gì |
| J3 | Chọn **Có** → gõ + Enter qua gác cổng → bấm "Vẫn gửi" | `mood.enc` **xuất hiện** |
| J4 | 🔴 Mở `mood.enc` bằng Notepad | **Toàn ký tự rác** — KHÔNG đọc được chữ nào. Nếu thấy chữ Việt/số đọc được → **lỗi chặn phát hành** |
| J5 | 🔴 Gõ vài câu có chữ, chờ ghi, rồi mở `mood.enc` bằng trình xem hex hoặc `findstr` | **KHÔNG có nội dung gõ**. Đây là bất biến quan trọng nhất của kho này |
| J6 | Chép `mood.enc` sang máy khác / tài khoản Windows khác, mở app ở đó | **Không đọc được** — DPAPI khoá theo tài khoản. Đúng thiết kế, không phải lỗi |
| J7 | Khay → **"Xóa toàn bộ nhật ký cảm xúc..."** | Hỏi xác nhận trước; đồng ý → `mood.enc` **biến mất** |
| J8 | Bật chuông nhắc mỗi 15 phút, gõ vài câu, chờ 1 nhịp | Có thêm bản ghi `sample`. Kiểm gián tiếp: kích thước `mood.enc` tăng |
| J9 | **Tắt chuông** hoàn toàn, gõ vài câu, chờ 1 nhịp | Nhật ký **VẪN ghi** — tắt chuông là tắt TIẾNG, không phải tắt việc ghi nhận ("nhịp trước, tiếng sau") |
| J10 | Không gõ gì suốt 1 nhịp | **KHÔNG** có bản ghi cho nhịp đó — quãng không gõ để TRỐNG, không ghi 0 (0 nghĩa là "đã đo, thấy phẳng") |
| J11 | Đang ghi thì tắt máy đột ngột (rút điện/máy ảo) → mở lại | Nhật ký **cũ còn nguyên** (ghi qua tệp tạm rồi mới thay — mất bản ghi cuối, không mất cả sổ) |

---

## 4e. E2E — Vòng đời bộ cài: cài mới / cài LẠI / gỡ (đợt R)

> Sinh từ sự cố thật 2026-07-17: cài 0.3.0 xong **không gì mở lên**, và `MindfulKey-setup.exe`
> trong Downloads **không xoá được** ("being used by another process"). Gốc đã vá (0.4.0+), nhưng
> đường **cài lại đè lên bản đang chạy** là một con đường KHÁC cài mới — phải test riêng từng ca.
>
> **2026-07-18 — vá thêm sau audit "cài lại":** cửa sổ ẩn trước đây không xử lý WM_CLOSE/
> WM_QUERYENDSESSION/WM_ENDSESSION nên bộ cài KHÔNG đóng được app đang chạy (Inno Restart Manager
> xin đóng nhưng app im lặng); nay có case xử sạch (gỡ hook, xoá khay, thoát tiến trình) + `.iss`
> thêm `AppMutex`/`SetupMutex`/`CloseApplications=yes`. Ca R2/R4 dưới đây CHÍNH LÀ phép thử của
> bản vá này — chưa ai chạy trên Windows thật.
>
> ⚠️ **Máy ĐANG kẹt bản 0.3.0 cũ (đúng máy anh dính sự cố) KHÔNG tự thoát được dù cài bản mới đè
> lên** — code 0.3.0 không biết cơ chế đóng-sạch mới. Trước khi chạy R2 trên máy đó: mở Task
> Manager → tìm `MindfulKey.exe` → **End Task** một lần, RỒI mới cài 0.4.2. Từ đó về sau, mọi lần
> nâng cấp 0.4.x→0.4.y sẽ tự động, không cần lặp lại bước này.

| # | Bước | Phải xảy ra |
|---|---|---|
| R0 | 🔴 Tải setup từ site → SmartScreen chặn → More info → Run anyway → cài hết → bộ cài tự mở app | **Icon sóng `~` hiện ở khay trong vài giây.** Không gì hiện = đúng triệu chứng 0.3.0 tái phát = **chặn phát hành** |
| R1 | 🔴 NGAY sau R0 (app đang chạy): xoá `MindfulKey-setup.exe` trong Downloads | **Xoá được liền.** "Being used by another process" = tái phát khoá file = **chặn phát hành** |
| R2 | 🔴 App đang chạy → tải bản setup MỚI hơn → chạy đè ("cài lại") | Setup tự đóng app (Restart Manager) HOẶC hỏi rõ ràng — **không** vòng lặp Retry/Abort câm, **không** đòi khởi động lại máy vô cớ. Cài xong app bản mới tự chạy, **không** ra hai tiến trình song song |
| R2b | 🔴 Ngay sau R2: Task Manager tìm `MindfulKey.exe` | **Đúng MỘT** tiến trình — không phải tiến trình cũ còn sống ngầm cạnh tiến trình mới |
| R3 | Khay → Thoát → mở Task Manager tìm `MindfulKey.exe` | **Không còn tiến trình nào.** Thoát mà tiến trình sống ngầm = mầm của khoá file |
| R4 | 🔴 Gỡ cài đặt (Settings → Apps) TRONG LÚC app đang chạy | Trình gỡ **hỏi đóng app trước** (AppMutex) rồi gỡ trọn vẹn — không lỗi "file in use"; tiến trình + icon khay biến mất |
| R5 | Cài lại sau khi gỡ (R4) | Chạy như cài mới; gõ tắt/tuỳ chỉnh cũ **còn nguyên** (registry cố ý giữ khi gỡ — xem MindfulKey.iss) |

---

## 5. Bất biến riêng tư — test cả điều KHÔNG được xảy ra

| # | Kịch bản | Bất biến |
|---|---|---|
| P1a | Gõ `ddm` + dấu cách vào ô mật khẩu **Win32 gốc** (vd Notepad giả lập bằng ô Password trong hộp thoại RDP/VPN client cũ, hoặc bất kỳ dialog Windows nào dùng control EDIT chuẩn với thuộc tính "ẩn ký tự") | **KHÔNG** hiện hộp nhắc. Lớp rẻ (`GetGUIThreadInfo` + `ES_PASSWORD`) không cần UIA, xác nhận NGAY — không có khoảng "mù" đợi UIA trả lời cho loại ô này |
| P1b | Gõ `ddm` + dấu cách vào ô **password trên trang web mở bằng Chrome/Edge** (`<input type="password">` bất kỳ, vd trang đăng nhập Gmail/Facebook) | **KHÔNG** hiện hộp nhắc. Đi qua lớp UI Automation (`UIA_IsPasswordPropertyId`) — CHƯA có mắt người xác nhận trên Windows thật, xem cảnh báo dưới bảng |
| P1c | Gõ `ddm` + dấu cách vào ô mật khẩu của **app UWP** (Microsoft Store), nếu có sẵn trên máy test | **KHÔNG** hiện hộp nhắc. Cùng đường UIA như P1b — UWP dùng XAML, khác cây accessibility của Win32 lẫn Chromium, nên là ca phủ riêng, không suy được từ P1b PASS |
| P1d | Gõ `ddm` + dấu cách vào ô mật khẩu của **app Electron** nếu có sẵn trên máy test (vd một app chat cài từ Microsoft Store hoặc .exe) | **KHÔNG** hiện hộp nhắc. Electron tự vẽ UI — việc nó có khai đúng thuộc tính mật khẩu cho UIA hay không tuỳ từng app, không suy được từ P1b/P1c |
| P1e 🔴 | **Khoá máy** (Win+L) rồi mở lại, gõ `ddm` + dấu cách vào ô mật khẩu màn hình đăng nhập Windows | **KHÔNG** hiện hộp nhắc. Ca THIỆT HẠI NẶNG NHẤT nếu lọt — mật khẩu tài khoản Windows chính, không phải mật khẩu 1 trang web |
| P1f | Vừa Tab/click đổi focus từ ô thường sang ô mật khẩu (bất kỳ loại nào ở trên), gõ `ddm` NGAY LẬP TỨC (trong khoảng dưới 1 giây) rồi dấu cách | **KHÔNG** hiện hộp nhắc. Đây là ca "vừa đổi focus, UIA chưa kịp trả lời" — thiết kế fail-closed: cờ hạ xuống "che" ngay khi focus đổi, TRƯỚC khi biết ô đó có phải mật khẩu hay không, nên gõ ngay sau khi bấm vào vẫn phải bị che |
| P2 | Bật app, gõ 5 phút, mở Resource Monitor lọc theo tiến trình `MindfulKey.exe` | **0 kết nối mạng.** Từ 2026-07-17 điều này **chứng minh được bằng code**, không chỉ quan sát: `getContentOfUrl` (URLDownloadToFile/Urlmon) là code mạng DUY NHẤT của app và đã bị gỡ cùng chuỗi kiểm-tra-phiên-bản hỏng. `grep -rE "URLDownload\|Urlmon\|InternetOpen\|WinHttp\|WSAStartup" platforms/windows` → **rỗng**. App không còn KHẢ NĂNG gọi mạng |
| P3 | Tắt "Nhắc tâm (cảm xúc)" trong cửa sổ Điều khiển, gõ `ddijt mej` + dấu cách | **KHÔNG** hiện gì |

> ✅ **P1 ĐÃ VÁ trong code (2026-07-17) — nhưng CHƯA CÓ MẮT NGƯỜI XÁC NHẬN, vẫn CHẶN PHÁT HÀNH tới
> khi có.** Xem `docs/FRICTION-LOG.md` cùng ngày, mục "CHẶN PHÁT HÀNH", cho lịch sử điều tra đầy đủ.
>
> **Cách vá:** file mới `platforms/windows/win32/OpenKey/OpenKey/SecureField.{h,cpp}`. Một luồng
> riêng (không phải luồng hook bàn phím) dựng `SetWinEventHook(EVENT_OBJECT_FOCUS)` + COM apartment
> riêng cho UI Automation. Mỗi lần focus đổi: hạ cờ xuống "che" NGAY (fail-closed), rồi mới hỏi (1)
> lớp rẻ `GetGUIThreadInfo` + `ES_PASSWORD` cho control Win32 gốc, (2) nếu không phải, hỏi UI
> Automation (`UIA_IsPasswordPropertyId`) cho control tự vẽ (Chrome/Electron/UWP). Chỉ khi CẢ HAI
> đều xác nhận "không phải" thì cờ mới hạ xuống "không che". `MoodWatch_OnWord` (đọc cờ, bỏ từ +
> xoá `MoodBuffer`) và `SendGatekeeper_ShouldIntercept` (đọc cờ, không gác cổng) đều đọc đúng 1 cờ
> đã có sẵn trên luồng hook — không có lệnh UIA nào chạy trên luồng hook.
>
> **Vì sao vẫn chặn phát hành dù đã có code:** máy dev là macOS, KHÔNG build/chạy được MSVC.
> `git diff core/` rỗng và CI Windows compile+link được là thứ DUY NHẤT đã chứng minh — chưa ai gõ
> thật vào bất kỳ ô mật khẩu nào trên Windows để xem cờ có hạ đúng lúc hay không. Bốn mức phủ khác
> nhau (Win32 gốc / Chromium / UWP / Electron) đi qua 2 đường code khác nhau, nên PASS ở P1a KHÔNG
> chứng minh được P1b/P1c/P1d/P1e — phải thử đủ cả 6 ca (P1a–P1f) ở trên, không thử 1 ca rồi suy ra
> hết. **P1e là ca có giá cao nhất** — mật khẩu tài khoản Windows chính.
>
> | Vỏ | Ô mật khẩu được bảo vệ bằng gì |
> |---|---|
> | iOS | **Code thật**: `MoodBridge_SetSecureFieldActive([self mk_isSecureField])`, gọi TRƯỚC khi engine kịp chốt từ |
> | macOS | **KHÔNG một dòng code nào** — dựa vào HỆ ĐIỀU HÀNH: macOS bật Secure Input Mode ở ô mật khẩu và OS **chặn luôn CGEventTap** |
> | **Windows** | **Code thật, mới (2026-07-17), chưa build-verify**: `SecureField.{h,cpp}` — xem trên |

---

## 6. Nhận diện & hiển thị

| # | Kiểm | Đạt khi |
|---|---|---|
| D1 | Bất kỳ chỗ nào tô màu brand (khi GĐ6 xong) | Teal phải là **xanh mòng két `#1D7C91`**, KHÔNG phải cam đất `#917C1D`. Sai màu này = quên `MK_COLORREF()`, byte bị đảo — build vẫn sạch nên chỉ mắt người bắt được |
| D2 | Đặt Windows ở **150% / 200% scaling**, mở mọi cửa sổ | Chữ không tràn/không đè, nút không bị cắt |
| D3 | Mở hộp **Giới thiệu** | Có dòng **"Dựa trên OpenKey — Mai Vũ Tuyên (GPL v3)"**, không bị cắt chữ (GPL — bắt buộc) |
| D4 | Icon trên khay hệ thống + icon app | ⚠️ Hiện vẫn là icon OpenKey gốc — **đã biết, chưa sửa** (GĐ6). Không tính là fail ở vòng này |

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
- [ ] **J0–J11** PASS — **J4/J5 là cổng chặn phát hành**: nhật ký phải là ciphertext và tuyệt đối không chứa nội dung gõ
- [ ] **B0–B11** PASS — đặc biệt **B0** (nghe đúng chuông chùa, không phải ding Windows) và **B9** (mất tệp riêng vẫn nghe chuông app)
- [ ] **G0–G11** PASS — đặc biệt **G5** ("Vẫn gửi" phải gửi được NGAY — cam kết không chặn cứng, vỡ cái này là vỡ hiến chương) và **G7** (hết giờ ≠ gửi)
- [ ] **P1a–P1f, P2–P3** PASS — CẢ 6 CA P1 (không chỉ 1) là cổng chặn phát hành, **P1e** (màn đăng nhập Windows) là ca giá cao nhất
- [ ] **D2–D3** PASS
- [ ] Ca chập chờn (hook, popup) → **PASS 2 lần liên tiếp** mới tính

### Cổng sổ sách
- [ ] `docs/TEST_MATRIX.md` ghi ca đã chứng minh, cột bằng chứng trỏ tới thứ có thật
- [ ] Chỗ phải đoán → `docs/FRICTION-LOG.md`
- [ ] Còn nợ đã biết (icon khay, ô mật khẩu…) → ghi RÕ trong release notes, **không giấu**

### Cổng chủ dự án
- [ ] Chốt: chứng chỉ Authenticode (chưa có → SmartScreen báo "Unknown publisher")
- [ ] Chốt: link Facebook OpenKeyVN · `CompanyName` · tên `MindfulKey.exe` trong bộ cài

---

## 8. Mẫu báo cáo (giọng mô tả, KHÔNG gamify)

```
QA Windows — bản <sha> — <ngày> — máy: Windows 11 23H2, 150% scaling

Gõ tiếng Việt : T1..T6 PASS · T7 PASS (gõ nhanh 40s, hook còn sống)
Lớp cảm xúc   : M1..M5 PASS · M6 FAIL — nhắc lại sau 6 giây, cooldown không ăn
Gác cổng      : G0..G11 PASS
Chuông        : B0..B9 PASS · B10 FAIL — lưu 5 rồi mở lại vẫn hiện 5, không về sàn 15
                B11 chưa thử (chưa chờ đủ 15 phút)
Nhật ký       : J0..J3 PASS · J4/J5 PASS — mở mood.enc thấy toàn ký tự rác, findstr
                không ra chữ nào đã gõ · J6..J11 PASS
Riêng tư      : P1a PASS · P1b FAIL — ô password Gmail trên Chrome VẪN hiện nhắc
                P1c skip (máy không có app UWP) · P1d skip (không có app Electron)
                P1e PASS · P1f PASS · P2 PASS · P3 PASS
Nhận diện     : D2 PASS · D3 PASS · D4 skip (đã biết)

Chặn phát hành: P1b, M6, B10
Chưa phủ      : P1c, P1d (không có app để thử) · B11
```

**Ba luật khi viết, đừng bỏ:**

1. **FAIL phải kèm cái MẮT THẤY, không kèm phán đoán.** "M6 FAIL — nhắc lại sau 6 giây" là mô tả;
   "M6 FAIL — chắc cooldown sai" là đoán. Người sửa cần thứ nhất.
2. **`skip` và `PASS` là hai chuyện khác nhau.** Không có app Electron để thử thì ghi `skip`, đừng
   ghi PASS. Dòng **Chưa phủ** tồn tại để chỗ chưa ai nhìn không lặng lẽ biến thành "chắc ổn".
3. **Ca P1 không suy được cho nhau.** `P1a PASS` KHÔNG nói gì về `P1b` — chúng đi qua hai đường code
   khác nhau (xem §5). Từng ca một, ghi từng ca một.

> Không chấm điểm, không xếp hạng, không streak — kể cả trong báo cáo test. Hiến chương áp cho cả
> cách ta nói về công việc, không chỉ cho UI.
