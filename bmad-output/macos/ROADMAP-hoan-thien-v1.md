# ROADMAP — Đường tới bản hoàn thiện (macOS v1)

> 🟡 **ĐỀ XUẤT — CHỜ CHỦ DỰ ÁN DUYỆT. Chưa thi công.**
> Cố ý CHƯA ghi vào `sprint-status.yaml`/`epics.md` — vào đó là thành lệnh thi công.
> Duyệt xong mới wire vào, kèm 1 entry `decision-log.md`.
>
> **Ngày:** 2026-07-15 · **Soạn từ:** `docs/PRD.md` (chuẩn "xong" của MVP) · `ACCEPTANCE-v2-2026-07-15.md`
> (10 finding nghiệm thu tay) · `docs/TEST_MATRIX.md` (12 ô ❌) · audit code "cái gì chưa nối dây"
> (2026-07-15, phát hiện thêm F11–F15) · `docs/INSTALL.md` (tình trạng phát hành).

## ⚙️ PHẠM VI ĐỢT NÀY — chủ dự án chốt 2026-07-15

**Làm:** Chặng 1 (vòng lặp lõi có sống không) · Chặng 2 (diện mạo) · Chặng 4 (vùng mù).
**HOÃN, không chạy đợt này:** Chặng 3 (đủ app chat như PRD hứa) · Chặng 5 (bản người khác cài được).

**Ý đồ:** đưa macOS về trạng thái **chạy đúng và đủ trên máy mình** → rồi mới đóng gói/chuyển sang
**phiên bản Windows**. Ký thật + notarize + phủ thêm app chat để dành cho lúc phát hành thật.

> ⚠️ **Hệ quả phải nói thẳng — hoãn 2 chặng này KHÔNG miễn phí:**
> 1. **Đợt này CỐ Ý KHÔNG đạt chuẩn MVP của `docs/PRD.md` §2** — PRD ghi *"MVP thành công = vòng
>    lặp này chạy mượt… trong ít nhất **2–3 app chat phổ biến**"*. Hoãn chặng 3 → allow-list vẫn chỉ
>    **Zalo + Discord**, chứng minh được nhiều nhất ở **1 app thật** (Zalo). Đây là lựa chọn có ý
>    thức của chủ dự án, KHÔNG phải quên — nhưng phải ghi `decision-log`, và **không được gọi kết
>    quả đợt này là "MVP xong"**. Gọi đúng tên: *"macOS chạy đúng trên máy dev"*.
> 2. **Không ai ngoài chủ dự án cài được** — `.dmg` vẫn ký ad-hoc. Không mời được người thử beta.
> 3. **Apple Developer Program duyệt mất vài ngày** — hoãn chặng 5 thì lúc muốn ship phải chờ. Đăng
>    ký là việc của chủ dự án, không phải việc code; có thể bấm nút bất cứ lúc nào để chạy nền.

---

## 0. Vì sao sản phẩm "chưa thấy hoàn thiện" — chẩn đoán thật

Cảm giác của chủ dự án là ĐÚNG, nhưng lý do **không nằm ở chỗ dễ thấy nhất**.

Nghiệm thu hôm nay bắt được 10 lỗi giao diện. Sửa hết 10 cái đó, app vẫn sẽ chưa hoàn thiện —
vì vấn đề lớn nhất không phải cái ta NHÌN thấy, mà cái ta chưa bao giờ THỬ:

> ### ⚠️ Tính năng số 1 của sản phẩm chưa bao giờ được chứng minh là chạy.
>
> `docs/PRD.md` §1 nói thẳng: *"một bộ gõ tiếng Việt tồn tại vì **một nhiệm vụ duy nhất** — đứng
> giữa bạn và khoảnh khắc bạn sắp gửi đi thứ mà 5 phút sau bạn sẽ hối hận"*, và *"mọi tính năng
> khác phục vụ cho feature này, không ngang hàng với nó"*.
>
> `docs/TEST_MATRIX.md:30` nói thẳng không kém:
> `| Gác cổng Enter-không-Shift (Zalo/Discord) | — | ❌ | ❌ | none — luồng chính chưa có bằng chứng E2E |`
>
> **Chưa một ai từng gõ một câu giận trong Zalo và thấy app dừng mình lại.** Cả code lẫn kế hoạch
> đều đã chạy quanh tính năng này 7 tháng mà chưa từng kiểm nó bằng tay một lần.

Và chuẩn "xong" của chính PRD cũng chưa đạt:

| PRD hứa gì | Thực tế |
|---|---|
| §2: gác cổng chạy trong **Zalo, Messenger, Telegram** | Allow-list chỉ có **Zalo** + **Discord** (`SendGatekeeperMac.mm:27-35`). Discord là app *để test*, tự comment ghi "ngoài mục tiêu gốc". → **Thiếu Messenger + Telegram**, tức thiếu 2/3 app đã hứa |
| §2: "MVP thành công = vòng lặp này chạy mượt… trong ít nhất **2–3 app chat phổ biến**" | Chưa chứng minh ở **0** app |
| §6: đóng gói `.dmg` **ký Developer ID + notarize** | Đang ký **ad-hoc** (`docs/INSTALL.md:3`) → máy người khác mở sẽ bị Gatekeeper chặn. **Chưa ai ngoài chủ dự án cài được** |

**Kết luận:** "chưa hoàn thiện" = **chưa có bằng chứng vòng lặp lõi sống**, chứ không phải thiếu
nút. Nên roadmap này để việc chứng minh vòng lặp **lên trước** việc sửa giao diện.

---

## 1. "Hoàn thiện" nghĩa là gì — định nghĩa để chốt

### 1a. Đích ĐỢT NÀY — "macOS chạy đúng trên máy dev"

Gọi là xong khi **cả 4 câu dưới trả lời được bằng "rồi, tôi thấy tận mắt"**:

1. Tôi gõ một câu giận trong **Zalo** → app dừng tôi lại → tôi bấm "Vẫn gửi" → tin vẫn gửi được bình thường.
2. Mọi thứ app hứa trong giao diện đều **bấm tới được** và **giống bản thiết kế**.
3. Cuối ngày tôi mở "Soi lại", thấy dòng sông có **dữ liệu thật của chính tôi** + một câu hỏi.
4. Không còn chỗ nào là **code chết** — thứ gì có trong code thì người dùng với tới được, thứ gì
   với không tới thì đã xoá hoặc đã ghi rõ là để dành.

Đạt 4 câu này = **đủ điều kiện bắt tay làm vỏ Windows**, vì lúc đó macOS đã là bản mẫu ĐÃ CHỨNG
MINH chạy, không phải bản mẫu chỉ-build-sạch. (Chép một bản mẫu chưa ai thử sang OS khác = nhân đôi
lỗi chưa biết mặt.)

### 1b. Đích PHÁT HÀNH — hoãn, giữ nguyên để dùng lại sau

Hai câu này thuộc chặng 3 + 5 đã hoãn. **Không xoá** — v1 phát hành thật vẫn phải trả lời được:

5. Vòng lặp chạy được ở **ít nhất 2 app chat** (PRD §2: Zalo + Messenger hoặc Telegram).
6. Tôi gửi `.dmg` cho một người bạn, họ cài được mà **không phải lách cảnh báo bảo mật**.

Ngoài phạm vi v1 (giữ nguyên non-goal của PRD): PhoBERT · tín hiệu "gõ thế nào" · Mac App Store ·
phủ hết mọi app chat.

### 1c. Món nợ kiến trúc cần chốt TRƯỚC khi làm Windows

Đợt này kết thúc là sang vỏ Windows — nên phải nhìn trước một cái bẫy **đã có thật trong sổ**:

> `docs/FRICTION-LOG.md` (2026-07-13, còn `mở`): lexicon tính **send-risk nằm ở vỏ macOS**
> (`MoodWatchMac.mm`), **KHÔNG** ở `core/mood` — `MoodBuffer` chỉ gom câu, tự ghi "shells decide how
> to analyze". Đội iOS vì thế đã phải làm **bản analyzer thứ 2** ở `platforms/apple/shared/`.

Windows sẽ là **bản thứ 3**. Lúc đó "1 bộ não + nhiều vỏ" trên giấy trở thành **3 bộ não** trong
thực tế: sửa một luật cảm xúc phải sửa 3 nơi, và 3 nơi sẽ trôi lệch nhau. Đây đúng thứ HIẾN CHƯƠNG
gọi là *"engine dùng chung, không fork logic gõ"*.

→ **Q7 (mới, §4):** trước khi mở vỏ Windows, có đưa analyzer send-risk về `core/mood` không?
Rẻ nhất là làm lúc **chỉ mới có 2 bản** (macOS + iOS), không phải lúc đã 3.

---

## 2. Năm chặng

### 🔴 Chặng 1 — Vòng lặp lõi có sống không? *(quan trọng nhất, làm trước)*

Mục tiêu: trả lời câu "sản phẩm này có làm được việc nó sinh ra để làm không?". Không viết tính
năng mới — chỉ **thử và vá**.

| # | Việc | Vì sao |
|---|------|--------|
| 1.1 | **E2E gác cổng trong Zalo bằng tay**: gõ câu giận → panel nhịp thở hiện → "Đợi chút" nuốt Enter → "Vẫn gửi" gửi lại được. Ghi bằng chứng vào TEST_MATRIX | Ô ❌ quan trọng nhất bảng. Chưa làm = không biết sản phẩm có chạy |
| 1.2 | **F12 — nghi án check-in là code chết**: timer check-in chỉ được tạo trong `-loadView` của `PanelViewController` (`PanelViewController.mm:280-296`) → nghi chỉ chạy nếu người dùng **đã từng mở popover** trong phiên đó. Nếu đúng → 1 trong "3 chân kiềng dữ liệu" (chốt 2026-07-13) **chưa bao giờ đứng** | Đúng hệt tiền lệ `MoodWatchMac_Init()` chưa ai gọi. Phải chạy thử để biết, không suy luận |
| 1.3 | **F14 — code chết xác nhận**: `MoodStoreMac_FetchTodaySummary` (`MoodStoreMac.h:42`) **0 nơi gọi**; `ReflectionScreenMac.h:5` ghi là dùng nó nhưng `.mm:81` thực tế gọi `FetchTodaySamples`. Bên iOS bản song sinh CÓ nối dây | Xoá hay nối? Quyết rồi làm — đừng để nằm đó đánh lừa người đọc sau |
| 1.4 | **Soi lại có dữ liệu thật**: chạy app một ngày, cuối ngày mở "Soi lại" xem sông + câu hỏi có lên đúng không (mọi ảnh nghiệm thu đều chụp lúc sông rỗng) | Câu 4 của định nghĩa xong |

**Cổng ra chặng 1:** TEST_MATRIX có **ít nhất 1 ô E2E = ✅ thật**. Chưa có thì không sang chặng khác.

---

### 🟠 Chặng 2 — Đóng diện mạo (Epic 3 hiện có + 3 finding mới)

| # | Việc | Trạng thái |
|---|------|-----------|
| 2.1 | **G1** — cuộn + nhãn cụt | ✅ code xong, `review` — chờ mắt chủ dự án |
| 2.2 | **G2** — soát chấm cam ở "Bộ tiếng" (nghi phạm HIẾN CHƯƠNG §5.6) | chờ |
| 2.3 | **G3** — card Gác cổng + lối vào Soi lại + copy rỗng có câu hỏi, vào pane "Hôm nay" | hết chặn (3 câu đã chốt) |
| 2.4 | **G4** — điều tra "Hệ thống" trắng trơn | chưa biết nguyên nhân |
| 2.5 | **F11 (mới)** — `SensitivityCardView` chỉ có ở popover, **không có trong cửa sổ Cài đặt**: muốn đổi Độ nhạy phải mở popover nhỏ | mới phát hiện |
| 2.6 | **F13 (mới)** — menu "Cài đặt Chuông tỉnh thức…" mở **NSAlert đời cũ** (`BellMac_ShowSettings`, 3 ô nhập tay), trong khi `BellSettingsView` mới đủ 3 thẻ đã tồn tại → **2 UI chuông đá nhau** | mới phát hiện |
| 2.7 | **F9** — quét tên "Mindful Keyboard" → **"Mindful Key"**. Nặng hơn tưởng: `Info.plist:8 CFBundleDisplayName` (tên trong Finder/Spotlight), storyboard (~12 chỗ), **`vi-VN.lproj/Main.strings` (8 chỗ — bản dịch này ĐÈ storyboard, máy chạy tiếng Việt thì đây mới là chữ thật hiện ra)**, `SendGatekeeperMac.mm:135`, `MoodWatchMac.mm:161/173`, `MoodStoreMac.mm:236`, `ViewController.m:113` | đã chốt tên, chưa quét |
| 2.8 | **F10** — chuông: 2 nút nhanh 30/60 + ô "Tùy chỉnh" (sàn 15, trần 240) + sửa `PRIVACY-NOTE.md` cho khớp | đã chốt, chưa làm |

---

### ⏸️ Chặng 3 — Đủ app chat như PRD đã hứa — **HOÃN (chốt 2026-07-15)**

> **Không chạy đợt này.** Giữ nguyên để dùng lại khi phát hành thật.
> Hệ quả đang gánh: allow-list vẫn **Zalo + Discord** → đợt này chứng minh được nhiều nhất ở **1 app**,
> tức **chưa đạt chuẩn MVP "2–3 app chat" của PRD §2**. Đã ghi ở khối PHẠM VI đầu file.
> Việc 3.1 (thêm Messenger/Telegram) là **1 dòng allow-list + xác minh bundle id** — rẻ về code,
> đắt về **thử tay** (phải cài + gõ thật từng app). Đó mới là lý do thật để hoãn.

| # | Việc |
|---|------|
| 3.1 | Thêm **Messenger** + **Telegram** vào allow-list (`SendGatekeeperMac.mm:27-35`). **Bắt buộc xác minh bundle id thật** bằng `defaults read <app>/Contents/Info.plist CFBundleIdentifier` — skill `platform-porting` ghi rõ: đừng đoán theo trí nhớ |
| 3.2 | E2E lại ở app thứ 2 (chuẩn PRD: "ít nhất 2–3 app") |
| 3.3 | Cân nhắc bỏ **Discord** khỏi allow-list bản phát hành (nó là app *để test*, không thuộc mục tiêu) — **cần chủ dự án chốt** |
| 3.4 | Quyết: có cho người dùng **tự thêm app** không? PRD §3 non-goal nói *"không hứa phủ hết mọi app chat"* → đề xuất **KHÔNG làm ở v1**, giữ allow-list cứng. **Cần chốt** |

---

### 🟢 Chặng 4 — Nghiệm thu nốt vùng mù

Nghiệm thu 2026-07-15 chỉ xem **5/6 mục của cửa sổ**. Còn nguyên:

| # | Việc | Vì sao gấp |
|---|------|-----------|
| 4.1 | **Mục "Giới thiệu"** — chưa ai từng nhìn. Credit **Mai Vũ Tuyên + GPL v3** nằm đúng ở đây | **Pháp lý.** Hiến chương: giữ credit là bất khả xâm phạm |
| 4.2 | **Popover 3 tab** (bấm icon `〜`) — đợt vừa rồi không nghiệm thu | Đây là mặt tiền dùng hằng ngày |
| 4.3 | **Chuông reo thật** + check-in 3 sóng hiện thật | Gắn với 1.2 |
| 4.4 | **A11y**: VoiceOver đọc con sóng, Tab đi hết control, Giảm chuyển động | DESIGN §3 đã hứa; chưa thử lần nào |

---

### ⏸️ Chặng 5 — Bản người khác cài được — **HOÃN (chốt 2026-07-15)**

> **Không chạy đợt này.** Giữ nguyên để dùng lại khi phát hành thật.
> Hệ quả đang gánh: `.dmg` vẫn ký ad-hoc → **chỉ chủ dự án cài được**, chưa mời được ai thử beta.
> Lưu ý thời gian: **5.1 mất vài ngày chờ Apple duyệt** và chặn cứng 5.2–5.4. Nó là việc giấy tờ,
> chạy nền được, không tốn công code — nên lúc nào muốn ship, bấm nút 5.1 TRƯỚC rồi làm việc khác.

| # | Việc |
|---|------|
| 5.1 | **Apple Developer Program** ($99/năm) — *chủ dự án làm, không phải việc code*. **Chặn cứng 5.2–5.4** |
| 5.2 | Ký **Developer ID** + **notarize** + staple (đã có skill `macos-release-pipeline` + `scripts/release.sh`) |
| 5.3 | Viết lại `docs/INSTALL.md` — bỏ hết phần "lách cảnh báo bảo mật" |
| 5.4 | Gửi `.dmg` cho 1 người thật cài thử → câu 5 của định nghĩa xong |

---

## 3. Thứ tự — và vì sao KHÔNG làm theo thứ tự dễ

Bản năng sẽ là: sửa nốt giao diện (chặng 2) cho đẹp rồi mới thử. **Đề xuất ngược lại:**

> **Chặng 1 trước chặng 2.** Nếu gác cổng hoá ra không chạy trong Zalo, thì mọi công sửa giao
> diện đều là kê lại ghế trên con tàu chưa biết có nổi không. Chặng 1 tốn ít công nhất
> (chủ yếu là **thử tay**, không viết mới) mà trả lời câu đắt nhất.

Ngoại lệ: **G1 đã xong** rồi, và **G2 (chấm cam)** rất rẻ + chạm hiến chương → làm kèm chặng 1 cũng được.

Lý do thứ hai, riêng cho đợt này: **bước kế tiếp là vỏ Windows.** macOS đang đóng vai **bản mẫu**
để chép sang. Chép một bản mẫu chưa ai thử = nhân đôi những lỗi chưa biết mặt sang OS thứ hai, rồi
gỡ ở cả hai nơi. Nên chặng 1 (chứng minh vòng lặp sống) càng phải đi trước.

```
Chặng 1 (thử tay) ──┬─→ Chặng 2 (diện mạo) ──→ Chặng 4 (vùng mù) ──→ ✅ đủ điều kiện mở vỏ Windows
                    └─→ G2 chấm cam (rẻ, chạm hiến chương)

⏸️ Chặng 3 (app chat) + Chặng 5 (phát hành) — hoãn, gọi lại khi ship thật
   └─ lúc đó: bấm 5.1 (Apple duyệt vài ngày) TRƯỚC, rồi làm 3.x song song
```

---

## 4. Cần chủ dự án chốt trước khi thi công

| # | Câu hỏi | Đề xuất | Trạng thái |
|---|---------|---------|-----------|
| Q1 | Đồng ý **đảo thứ tự** — thử tay Feature #1 trước, sửa giao diện sau? | Đồng ý | ✅ **đã duyệt** (lệnh "triển khai bám plan luôn nhé", 2026-07-15) |
| Q2 | Định nghĩa xong ĐỢT NÀY (**4 câu** ở §1a) có đúng ý anh không? Thiếu/thừa gì? | — | ✅ **đã duyệt** (như trên — chưa nghe phản hồi khác nên giữ nguyên 4 câu) |
| Q6 | `MoodStoreMac_FetchTodaySummary` (code chết): **xoá** hay **nối** vào màn Soi lại? | Xem 1.4 rồi quyết | ✅ **đã chốt: NỐI** — 3 nguồn hội tụ (comment gốc + dữ liệu khớp mockup A1 + bản song sinh iOS đã nối), không cần hỏi thêm. Xem `decision-log.md` 2026-07-15 |
| **Q7** | **(quan trọng nhất cho bước Windows)** Trước khi mở vỏ Windows, có đưa **analyzer send-risk** từ `MoodWatchMac.mm` về `core/mood` không? Không làm → Windows thành **bản analyzer thứ 3**, "1 bộ não" chỉ còn trên giấy (xem §1c) | **Có** — và làm lúc mới 2 bản thì rẻ hơn lúc đã 3. Nhưng chạm `core/` (đang đóng băng với iOS) → phải chốt với cả đội iOS | **CÒN MỞ — chủ ý chưa đụng.** `core/` vẫn nguyên vẹn qua cả 4 fix hôm nay. Xem `sprint-status.yaml` → `epic4_core_loop.q7_pending_before_windows` |
| ~~Q3~~ | ~~Bỏ Discord khỏi allow-list?~~ | thuộc chặng 3 | ⏸️ hoãn |
| ~~Q4~~ | ~~Cho người dùng tự thêm app chat?~~ | thuộc chặng 3 | ⏸️ hoãn |
| ~~Q5~~ | ~~Đăng ký Apple Developer Program?~~ | thuộc chặng 5 — gọi lại khi ship | ⏸️ hoãn |

---

## 5. Ghi chú cho người thi công

- **Định tuyến:** chặng 1/4 = thử tay (chủ dự án + `platform-shell-agent`) · chặng 2 = `platform-shell-agent`
  + `mood-layer-agent` · chặng 3 = `platform-shell-agent` · chặng 5 = skill `macos-release-pipeline`.
- **KHÔNG đụng `core/`** ở bất kỳ chặng nào — giữ `make test` xanh.
- **Luật bằng chứng của Epic 3 áp cho cả roadmap này:** cột macOS chỉ nhận `✅` khi **có mắt nhìn
  app thật**; build sạch chỉ là `⚠️`. Chính build-verified đã để lọt cả 10 finding + 5 cái mới.
- Mỗi việc xong: cập nhật `sprint-status.yaml` + 1 dòng `docs/TEST_MATRIX.md`, **ngay lúc commit**.
