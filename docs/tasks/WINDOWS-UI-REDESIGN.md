# Vẽ lại giao diện vỏ Windows theo nhận diện

> Chủ dự án chốt 2026-07-18: vẽ lại TOÀN BỘ UI Windows cho khớp bản macOS. File này là bản đặc tả
> + lộ trình, đối ứng của `bmad-output/macos/SCREEN-REFERENCE.md`. **Spec trước, code sau** — đúng
> cách bản Mac đã làm. Không có file này thì mỗi hộp thoại vẽ một kiểu, lạc pixel.

## Ràng buộc thật (đọc trước khi tô một pixel)

1. **"Khớp macOS" = khớp lựa chọn THẬT của macOS, không phải khớp tokens.json.** Bản Mac cố ý
   *bỏ qua* hai token dễ thấy nhất: font ghi `Montserrat/Inter` nhưng Mac dùng **font hệ thống (SF)**
   (`SettingsWindowController.mm:450`); card ghi radius 16 nhưng Mac dùng **11px** (`BrandControls.m:376`).
   → Trên Windows, "khớp Mac" nghĩa là dùng **Segoe UI (font hệ thống Windows)**, KHÔNG nhúng
   Montserrat. Đây là tin tốt: bỏ được rủi ro nhúng/bản quyền font, và Windows vốn đã dùng Segoe UI.
2. **Vẽ lại = tô lại MÀU + HÌNH + CONTROL, không phải đổi bố cục logic.** Giữ nguyên hành vi/luồng
   (đã test), chỉ thay lớp "da": nền brand, thẻ bo tròn thay groupbox xám, control vẽ tay (pill,
   nút brand), popup được thiết kế thay `MessageBox` trần.
3. **Máy dev là macOS — KHÔNG render được Windows.** Mỗi màn: tôi vẽ (mù) → CI chứng minh biên dịch
   → chủ dự án build trên Windows thật + gửi ẢNH → tôi chỉnh cỡ/lề/màu → chốt. Không màn nào coi là
   "xong" khi chưa có ảnh thật xác nhận. Cỡ font/lề trong lần vẽ đầu là **ước lượng**, chờ ảnh tinh chỉnh.
4. **Nhận diện bất khả xâm phạm vẫn tối cao** (§2.2): không đỏ/xanh cảm xúc, không emoji chấm điểm,
   không gamification. Cam CHỈ cho CTA + 2 "khoảnh khắc người" (nhịp thở, thẻ gợi ý Soi lại). Sóng
   `~` + biên độ là tín hiệu cảm xúc, không phải màu.

## Nền móng (Phase 1 — làm TRƯỚC mọi màn)

`BrandControls.{h,cpp}` — đối ứng Win32 của `platforms/apple/macos/BrandControls.m`. Mọi màn vẽ lại
GỌI LẠI đây, KHÔNG tự chép GDI (tránh trôi lệch — đúng mô hình đã đẻ bug lexicon). Xây DẦN theo nhu
cầu từng màn (YAGNI), không dựng cả thư viện control đầu cơ:
- ✅ `BrandControls_Font(role)` — Segoe UI ở cỡ/nét brand (title/body/eyebrow/button). DPI-aware.
- ✅ `BrandControls_FillRect(hdc, rc, hex)` — tô nền brand (WM_ERASEBKGND). Qua `MK_COLORREF` chống đảo byte.
- ✅ `BrandControls_DrawButton(dis, style)` — nút bo tròn owner-draw (Primary teal / Accent cam / Neutral trắng-viền).
- ⏳ (thêm khi màn cần) thẻ bo tròn, PillSwitch, MKSegmented, eyebrow label, nền cửa sổ brand.

Đã có sẵn để tái dùng: `BrandPalette.h` (đủ màu + macro `MK_COLORREF`/`MK_ARGB` chống đảo byte),
mẫu vẽ GDI+ ở `ReflectionScreen.cpp` (kèm bẫy `objidl.h`). Lần đầu dùng GDI thuần (RoundRectRgn) cho
nút — robust khi vẽ mù; nâng lên GDI+ (góc mượt anti-alias) SAU khi ảnh thật xác nhận cách tiếp cận.

## Kiểm kê bề mặt + thứ tự vẽ

Xếp theo: (a) chạm cảm xúc nhiều nhất + (b) gọn/bounded để chứng minh cách tiếp cận trước.

| # | Bề mặt | Hiện trạng | Đích (theo macOS) | Trạng thái |
|---|--------|-----------|-------------------|-----------|
| 1 | **Nhịp thở** (`IDD_DIALOG_PAUSE`) | Hộp xám 2 nút | Nền `orangeLight` "khoảnh khắc người", nút brand (Đợi chút=cam, Vẫn gửi=trung tính) — đối ứng `SendGatekeeperMac.mm` NSPanel | 🔨 Phase 1 (đang) |
| 2 | **Nhắc tâm** (`MoodWatch.cpp` MessageBox) | `MessageBox` trần + ding | Bề mặt dịu vẽ tay, không ding, màu brand | ⏳ |
| 3 | **Chuông** (`IDD_DIALOG_BELL`) | Lưới Win32 xám | Nhóm eyebrow + thẻ; PillSwitch; 4 glyph chuông có chấm teal | ⏳ |
| 4 | **Cửa sổ chính** (`IDD_DIALOG_MAIN`) | Tab control + lưới checkbox | Điều hướng + thẻ brand; khu tâm trạng | ⏳ (lớn nhất) |
| 5 | **Soi lại** (`IDD_DIALOG_REFLECT`) | Khung xám + sông GDI+ | Bọc sông trong thẻ brand + eyebrow beats như macOS | ⏳ (sông đã brand) |
| 6 | **Giới thiệu** (`IDD_ABOUTBOX`) | Hộp xám | Nền brand + credit GPL giữ nguyên | ⏳ |
| 7 | Các `MessageBox` phụ (xác nhận xoá, cảnh báo…) | Trần | Cân nhắc giữ native (quy ước Windows) hay vẽ lại — chốt sau | ⏳ |

## Reference macOS đã chốt (từ 2 artifact chủ dự án 2026-07-19)

> Nguồn: artifact "Mindful Key — Hướng dẫn sử dụng" (vẽ đủ mọi màn) + "Áo mới cho Mindful-key —
> Ý tưởng + Plan" (6 bước). Đây là SỐ ĐO ĐÍCH — vẽ theo đây, không đoán. Bảng màu Windows
> (`BrandPalette.h`) đã đối chiếu: **khớp từng hex** (teal 1D7C91 · tealLight E8F2F4 · orange FF7A1A
> · orangeLight FFF2E8 · card FFFFFF · charcoal 2A2A2A · divider E5E7E8 · stone 8A9BA0). `teal-ink
> #125766`/`teal-deep #0F5566` CHỈ có trong mockup — code macOS thật thay bằng teal, nên Windows
> dùng teal, KHÔNG bịa teal-deep.

**Linh kiện chung (khoá số):**
- **Thẻ (card):** radius **11px**, viền 1px `divider`, padding ~12×14, cách nhau ~12–16px.
- **Eyebrow (nhãn nhóm):** ~10px, IN HOA, giãn chữ ~1.2px, màu `stone`.
- **Tiêu đề pane (mkh):** ~18px semibold, `charcoal`.
- **PillSwitch:** 36×21, bo tròn hết, tắt=`divider`, bật=`teal`, núm 17px trắng có bóng nhẹ.
- **Segmented:** track `#EFEFEC` radius ~8, ô đang chọn = `teal` nền + chữ trắng.
- **Header thẻ:** `~` teal + tên charcoal semibold + (popover: pill "VN" teal + `⋯`). ĐÃ xác nhận
  tiêu đề màu **charcoal #2A2A2A** (không phải nâu) — khớp cái tôi đã làm ở màn Nhịp thở.
- **Dòng sông:** trục nét đứt màu `stone`-mờ dash 2/4, sóng teal nét 2.2–2.6 bo tròn đầu, chấm teal r~3. KHÔNG mẫu = KHÔNG vẽ.
- **Chân trang trust:** "Xử lý trên máy · không gửi nội dung gõ đi đâu" ~11.5px `stone`, canh giữa.

**Bề mặt CHÍNH — và lỗ hổng lớn nhất:** macOS lấy **popover trên thanh menu** làm MẶT TIỀN (rộng
**338px**, radius 16, 3 tab pill *Hôm nay · Chuông · Bộ gõ* — tab đang chọn = pill TRẮNG nổi có bóng,
chữ charcoal semibold). **Windows KHÔNG có popover này** — chỉ có menu chuột phải + hộp Cài đặt.
Muốn khớp mặt tiền phải dựng một flyout kiểu popover từ khay. Đây là bề mặt MỚI lớn nhất, và là một
QUYẾT ĐỊNH (dựng popover, hay dồn nội dung popover vào cửa sổ chính) — chờ chủ dự án chốt.

**Cửa sổ Cài đặt 6 mục** (đối ứng cửa sổ six-nav macOS): nav trái ~150px nền softWhite, mỗi mục =
chấm 6px + nhãn 12.5px, đang chọn = nền `tealLight` + chấm/chữ teal; pane phải = tiêu đề mkh + các
nhóm eyebrow+thẻ. Sáu mục: Hôm nay · Chuông · Bộ gõ · Riêng tư · Hệ thống · Giới thiệu.

## Lịch sử
| Ngày | Việc |
|------|------|
| 2026-07-18 | Lập spec + Phase 1 (nền móng `BrandControls` + màn Nhịp thở làm mẫu chứng minh). Chờ ảnh Windows thật. |
| 2026-07-19 | Nạp 2 artifact reference macOS của chủ dự án → khoá số đo đích (màu khớp 100%, linh kiện, popover 338px 3-tab, cửa sổ 6 mục). Lộ lỗ hổng lớn: Windows thiếu hẳn popover mặt-tiền. |
