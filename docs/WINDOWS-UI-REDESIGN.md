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

## Lịch sử
| Ngày | Việc |
|------|------|
| 2026-07-18 | Lập spec + Phase 1 (nền móng `BrandControls` + màn Nhịp thở làm mẫu chứng minh). Chờ ảnh Windows thật. |
