# Bảng điều khiển (Settings window) — Feedback chủ dự án (đợt 2)

> Nghiệm thu tay **v0.4.16/v0.4.17** trên Windows, đối chiếu bản macOS (ảnh đính kèm). Ghi 2026-07-23.
> Đây là đợt 2 (sau đợt Popover). Mục tiêu: cửa Cài đặt Windows **bắt kịp macOS** về tính năng + đồng
> bộ thiết kế. Làm ở **v0.4.18**.

Trạng thái: ⬜ chưa làm · 🔄 đang làm · ✅ xong (chờ mắt người Windows) · ⏸️ hoãn có lý do.

## Nhóm Chuông

| ID | Trạng thái | Việc |
|---|---|---|
| **CP1** | ⬜ | Đổi tên "Phát tiếng gõ" → **"Bật tiếng chuông"** (đúng nghĩa: đây là bật/tắt chuông tỉnh thức, không phải tiếng gõ phím). |
| **CP2** | ⬜ | Cải tiến phần chọn tiếng: icon nốt nhạc (bộ tiếng custom) trên cửa Cài đặt cũng **bấm để chọn .wav** (như popover P2 đã làm), + đưa icon nốt nhạc vào đúng nhóm. |
| **CP3** | ⬜ | **Nới rộng vùng ghi khung giờ yên lặng** — ảnh cho thấy stepper "− ) giờ +" bị chật/cắt chữ ("- 2 gi +"). Cần rộng đủ hiện "NN giờ". |

## Nhóm Bộ gõ

| ID | Trạng thái | Việc |
|---|---|---|
| **CP4** | ⬜ | Thiếu nhóm **Chuyển mã** + **Gõ tắt** (bảng macro). macOS có 3 segment: Kiểu gõ / Gõ tắt / Chuyển mã — Gõ tắt có bảng thêm/xoá macro + Nạp/Xuất file + "tự viết hoa"; Chuyển mã có công cụ đổi bảng mã. Windows Bộ gõ mới có toggle, chưa có 2 nhóm này (mở bảng macro qua `onMacroTable`, công cụ chuyển mã qua `onConvertTool` — đã có sẵn hàm). |

## Nhóm Riêng tư

| ID | Trạng thái | Việc |
|---|---|---|
| **CP5** | ⬜ | Tab Riêng tư Windows đang TRỐNG (đã gỡ control giả ở A4). macOS có đủ 4 nhóm: **Nhật ký cảm xúc** (toggle "Lưu điểm gợn cục bộ" = vMoodWatch/consent), **Cầm trịch dữ liệu** (Xuất CSV), **Tự động dọn dẹp** (tự xóa nhật ký cũ hơn N ngày), **Xóa bỏ** (Xóa toàn bộ nhật ký). ⚠️ A4/FRICTION-LOG 2026-07-23: `MoodStore` Windows CHƯA có hàm purge-theo-ngày / export CSV — cần thêm backend (không bịa). Nhật ký toggle + Xóa toàn bộ thì backend đã có (MoodWatch_Toggle / MoodStore_DeleteAll). |

## Nhóm Giới thiệu (About)

| ID | Trạng thái | Việc |
|---|---|---|
| **CP6** | ⬜ | Đồng bộ thiết kế About giữa macOS ↔ Windows. macOS: icon lớn + "Bộ gõ Tiếng Việt chánh niệm · Một sản phẩm GNH" + phiên bản + "Dựa trên OpenKey — Mai Vũ Tuyên (GPL v3)" + link GitHub + toggle "Kiểm tra bản mới khi khởi động" + nút cam "Kiểm tra bản mới..." + "© 2026 GNH — Lan tỏa điều tử tế". Windows About sơ sài hơn + đã đổi Trang chủ = key.bketech.xyz (v0.4.17). |

## Đã xử ngay ở v0.4.17 (không đợi batch)

- **Trang chủ → `https://key.bketech.xyz`** (2 link SYSLINK_HOME_PAGE + 2 .rc). Nút "mã nguồn" GIỮ
  github (nghĩa vụ GPL — nguồn phải với tới được).
