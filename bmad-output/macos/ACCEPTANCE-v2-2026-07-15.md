# NGHIỆM THU TAY v2 — macOS, 2026-07-15 (lần 1)

**Người nghiệm thu:** chủ dự án · **Cách:** mở app thật, bấm qua 5/6 mục nav, chụp màn hình
**Đối chiếu với:** 2 artifact thiết kế do chủ dự án gửi (xem §0) + `DESIGN-macos-control-panel.md` §5 (ràng buộc HIẾN CHƯƠNG) + `decision-log.md` 2026-07-13 (Diện mạo mới v2)

> **Đây là sự kiện quan trọng của Epic 2.** Trước hôm nay, cả 6 bước v2 chỉ ở mức
> *build-verified* — "build sạch + `make test` xanh + brand-lint 0", **chưa ai mở app nhìn bằng mắt**
> (xem `sprint-status.yaml` → `status_note_2026_07_14`). Hôm nay có người nhìn thật.
> Kết luận một câu: **code chạy, nhưng màn hình thật chưa bằng bản thiết kế.**
>
> Trạng thái đặc tả: file này là **nguồn sự thật của đợt feedback 2026-07-15**. Status thi công
> vẫn sống DUY NHẤT ở `sprint-status.yaml` (Epic 3) — file này không ghi status.

---

## 0. Nguồn thiết kế (2 artifact chủ dự án gửi 2026-07-15)

| # | Tên | Chốt cái gì (phần dùng để đối chiếu) |
|---|-----|--------------------------------------|
| A1 | *Mindful-key — Vòng Soi lại (chuông → sông → câu hỏi)* — artifact `630ae3be` | Vòng khép kín 1 ngày: chuông điểm → 1 chấm lên sông → cuối ngày sông kể thành **câu hỏi**. Đặc tả 3 màn: (1) toast chuông + check-in 3 mức sóng, (2) màn **Soi lại 4 nhịp** (Nhận ra → Cho phép → Soi → Nuôi dưỡng), (3) màn "ngày gõ ít — nói thật" |
| A2 | *Áo mới cho Mindful-key — Ý tưởng + Plan thực thi* — artifact `0be4a103` | Cửa sổ 6 mục nav + bảng "mục nào chứa gì" + **ảnh mockup pane "Hôm nay"** (card gác cổng + chân trang riêng tư) + bảng độ nhạy 3 mức + 6 bước thi công |

> ⚠️ 2 artifact này **không nằm trong repo** (sống trên claude.ai). Nội dung đã trích vào file
> này ở phần Kỳ vọng của từng finding — đọc file này là đủ, không cần mở link.

---

## 1. Bảng findings

Ký hiệu **Mức**: `chặn` (chạm HIẾN CHƯƠNG hoặc cả một mục rỗng) · `nặng` (lệch thiết kế thấy rõ) · `vừa` (lệch nhỏ) · `hỏi` (cần chủ dự án chốt, chưa làm được).

Ký hiệu **Bằng chứng**: `mắt` = chủ dự án nhìn thấy trên app thật · `code` = đã truy ra dòng code · `?` = chưa truy ra nguyên nhân.

| ID | Quan sát thật (chủ dự án thấy) | Kỳ vọng theo thiết kế | Mức | Bằng chứng | Về ai |
|----|-------------------------------|----------------------|------|-----------|-------|
| **F1** | Mục **"Hệ thống" trắng trơn hoàn toàn** — không tiêu đề, không control, không gì cả | A2 bảng dọn nhà: Hệ thống = "Khởi động cùng máy · icon Dock/menu · kiểm tra bản mới · đặt mặc định" (dời từ tab Hệ thống cũ) | **chặn** | mắt + code-một-nửa (`?` nguyên nhân) | platform-shell |
| **F2** | Mục **"Hôm nay" KHÔNG có card Gác cổng**, không link "Soi lại →", không chân trang riêng tư. Chỉ có tiêu đề + khung sông rỗng | A2 mockup pane Hôm nay: card gác cổng nền `#F4FAFB` viền teal 1.5px, tiêu đề "Gác cổng gửi tin", sóng `~`, copy "Mặt hồ đang phẳng lặng. Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi.", link cam "Soi lại →", chân trang "Xử lý trên máy · không gửi nội dung gõ đi đâu" | **chặn** (chạm §5 điều 10: Feature #1 luôn nổi nhất) | mắt + code | platform-shell + mood-layer |
| **F3** | **Không có lối vào màn "Soi lại"** từ cửa sổ | A1: màn Soi lại 4 nhịp (Nhận ra → Cho phép → Soi → Nuôi dưỡng), **câu hỏi là chữ to nhất màn**, số liệu nép làm bối cảnh, 1 gợi ý một chạm ("Đặt chuông 15–17h"), chân trang "Xử lý trên máy · Câu hỏi mỗi ngày một khác · Không điểm số, không chuỗi ngày" | **nặng** | mắt | mood-layer |
| **F4** | Copy rỗng của sông: **"Hồ chưa đủ nét — ngày mới bắt đầu."** — hết | A1 màn 3 "ngày gõ ít — nói thật": "Hôm nay bàn phím nghỉ nhiều." + "Mặt hồ chưa đủ nét để vẽ — và điều đó cũng chẳng sao. **Hôm nay anh đã ở đâu nhiều hơn, ngoài bàn phím?**" → bản thật **thiếu hẳn câu hỏi phản chiếu**, phần hồn của màn | **vừa** (chạm nhận diện) | mắt + code | mood-layer |
| **F5** | **Nội dung bị cắt cụt ở đáy** — "Chuông" cụt ở thanh Âm lượng; "Riêng tư" cụt giữa nút "Xóa toàn bộ nhật ký". Không cuộn được | Mọi mục xem hết được nội dung | **nặng** | mắt + code | platform-shell |
| **F6** | Nhãn bị cắt chữ: **"Tạm tắt Mindful Keyboard bằng p"** (cụt) ở Bộ gõ ▸ Kiểu gõ. "Tạm tắt chính tả bằng phím ^" cũng sát mép | Nhãn hiện đủ chữ | **vừa** | mắt | platform-shell |
| **F7** | Ở Chuông ▸ Bộ tiếng: **chấm CAM** đánh dấu bộ tiếng đang chọn (dưới icon chuông chùa) | §5 điều 6 (bất khả xâm phạm): *"Cam `#FF7A1A` **CHỈ** ở CTA + link active. **Không ở trạng thái ON/OFF**"* — đang-chọn là trạng thái, không phải CTA | **chặn** (nghi phạm hiến chương) | mắt | platform-shell + soát nhận diện |
| **F8** | PillSwitch ở **Bộ gõ nhạt hơn** hẳn PillSwitch ở **Chuông** — cùng trạng thái ON, 2 sắc teal khác nhau | 1 token `color.brand.teal` duy nhất cho mọi PillSwitch ON | **vừa** | mắt | platform-shell |
| **F9** | Tiêu đề cửa sổ: **"Cài đặt Mindful Keyboard"** | Artifact A2 + repo + DMG đều gọi **"mindful-key"** / `MindfulKey` | **hỏi** | mắt | chủ dự án |
| **F10** | Chuông định kỳ có mức **15** phút (đang chọn), cùng 30 · 60 | A2 §Cách lấy mẫu: *"Để ý liên tục trong suốt mỗi nhịp chuông (**30 hoặc 60 phút**)… Cả ngày chỉ ~24–48 chấm"*. Mức 15 → ~96 chấm/ngày, gấp đôi trần đã chốt | **hỏi** | mắt | chủ dự án |

---

## 2. Chi tiết 3 finding cần đọc kỹ trước khi sửa

### F1 — "Hệ thống" trắng trơn: KHÔNG được vá mò

Đường đi hiện tại (`SettingsWindowController.mm`):

- `mk_instantiateEmbeddedViewControllers` (dòng ~268–281): dựng `ViewController` 1 lần qua identifier
  `OpenKeyPanel`, rồi `removeFromSuperview` **cả hai** NSBox `tabviewPrimary` + `tabviewSystem`.
- `selectSectionAtIndex` case `MKSettingsSectionSystem` (dòng ~388): `mk_showPaneInHost:_openKeyVC.tabviewSystem`.
- Outlet có thật trong storyboard: `Main.storyboard:1871` → `tabviewSystem` destination `mf4-Da-qrL`.

**Nguyên nhân THẬT: chưa biết.** Giả thuyết đáng soi đầu tiên: 2 outlet khai `@property (weak)`
(`ViewController.h:19` và `:21`) — `removeFromSuperview` bỏ tham chiếu strong duy nhất (mảng
`subviews` của superview) → box bị giải phóng → outlet `weak` thành `nil` → hiện `nil` = trắng.

**NHƯNG giả thuyết này chưa giải thích được vì sao "Bộ gõ ▸ Kiểu gõ" (`tabviewPrimary`, y hệt cơ
chế) lại hiện bình thường.** Còn một mắt xích chưa hiểu → **phải điều tra tới nơi rồi mới sửa**,
không được đoán rồi vá. (Kỷ luật "CẤM đoán" — `CLAUDE.md` §Think Before Coding.)

### F5 — Cắt cụt đáy: đã truy ra, không cần điều tra

`SettingsWindowController.mm:55` — `kMaxPaneH = 472.0` cố định, và **không có `NSScrollView` nào
trong cả file**. Pane cao hơn 472pt thì phần dưới bị cắt, không có đường cuộn xuống.

Đối chiếu: popover ĐÃ được bọc `NSScrollView` ở commit `d377eaf` ("add NSScrollView to popover").
**Cửa sổ quản lý bị bỏ sót** trong lần vá đó — cùng một bệnh, mới chữa một nửa.

### F2 — Card gác cổng: có code, nhưng không có mặt ở đây

`GatekeeperCardView` tồn tại và ĐÃ được gắn vào **popover** (story 1.4, commit `3651a25`).
Nhưng `mk_buildTodayPane` (`SettingsWindowController.mm:333–337`) chỉ dựng đúng 2 thứ: tiêu đề
"Hôm nay" + `EmotionRiverView`. **Không có dòng nào mount card gác cổng vào pane này.**

Đây không phải bug — là **việc chưa làm**. Pane "Hôm nay" của cửa sổ chưa bao giờ được dựng theo
mockup A2. Cần chốt: Hôm nay-trong-cửa-sổ có phải là bản đầy đủ của Hôm nay-trong-popover không,
hay hai chỗ cố ý khác nhau? (→ ghi FRICTION-LOG 2026-07-15.)

---

## 3. Cái gì ĐÃ đúng thiết kế (ghi cho công bằng — không chỉ chê)

- **Khung nhà 6 mục nav trái** dựng đúng mockup A2: đúng 6 mục, đúng thứ tự (Hôm nay · Chuông ·
  Bộ gõ · Riêng tư · Hệ thống · Giới thiệu), chấm tròn trung tính, mục đang chọn nền `tealLight` + chữ teal.
- **Bộ gõ** có thanh sub-nav 3 mục (Kiểu gõ · Gõ tắt · Chuyển mã) — đúng ý "gộp 3 cửa sổ cũ" của A2.
- **Riêng tư** gần đủ A2: bật/tắt nhật ký + Xuất CSV + tự xoá 90 ngày + xoá toàn bộ, copy đúng
  giọng quan sát ("Quên có chủ đích — các sự kiện cũ sẽ tự biến mất để tâm trí nhẹ nhàng hơn").
- **Chuông** có Trạng thái + Nhịp + Âm thanh, câu nối chuông↔sông đúng tinh thần "một nhịp, hai vai"
  ("Cứ mỗi nhịp chuông, app ghi một điểm lên dòng sông cảm xúc ở tab Hôm nay").
- **Không thấy vi phạm hiến chương nào** ở 5 màn ngoài nghi phạm F7: không đèn đỏ/xanh, không mặt
  cười, không streak/điểm/huy hiệu, không copy khiển trách.

---

## 4. Thứ tự đề xuất (dễ+chặn trước, mò sau)

Lý do thứ tự này: **F5 phải đi trước F2/F3** — chưa có đường cuộn thì nhồi thêm card gác cổng vào
"Hôm nay" chỉ làm nội dung bị cắt sâu hơn. F1 để riêng vì phải điều tra, đừng để nó chặn các bước rõ ràng.

| Thứ tự | Gói | Gồm | Vì sao đứng đây |
|--------|-----|-----|-----------------|
| 1 | **Cắt cụt + nhãn** | F5, F6 | Rõ nguyên nhân, sửa xong thấy ngay, mở đường cho gói 3 |
| 2 | **Soát nhận diện** | F7 | Chạm hiến chương — soát sớm, rẻ; nếu là vi phạm thì càng để lâu càng lan |
| 3 | **Hồn của "Hôm nay"** | F2, F3, F4 | Phần nặng nhất, cần đường cuộn (gói 1) xong trước |
| 4 | **Điều tra "Hệ thống"** | F1 | Chưa biết nguyên nhân — hộp thời gian riêng, không trộn vào gói khác |
| — | **Chờ chủ dự án** | F9, F10 | Không code được tới khi có câu trả lời |

---

## 5. Nghiệm thu này CHƯA phủ

Ghi ra để không ai tưởng "đã soi hết" (đúng tinh thần TEST_MATRIX: không suy diễn từ im lặng):

- **Mục "Giới thiệu"** — chưa có ảnh, chưa ai xem (credit Mai Vũ Tuyên + GPL v3 nằm ở đây → hệ trọng pháp lý).
- **Popover 3 tab** (bấm icon `〜` menu-bar) — đợt này chỉ nghiệm thu **cửa sổ quản lý**.
- **Luồng động**: chuông reo thật, check-in 3 sóng hiện thật, gác cổng nuốt Enter trong Zalo/Discord,
  sông có dữ liệu thật (mọi ảnh đều chụp lúc sông rỗng).
- **A11y**: VoiceOver, bàn phím Tab, Giảm chuyển động — chưa thử.
