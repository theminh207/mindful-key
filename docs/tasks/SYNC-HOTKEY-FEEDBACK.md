# Đồng bộ Cài đặt↔Popover + phím tắt — Feedback chủ dự án (đợt 4)

> Nghiệm thu tay **v0.4.19** trên Windows, đối chiếu bản macOS + Popover. Ghi 2026-07-24.
> Đợt 4. Trọng tâm: phím tắt bật/tắt bộ gõ + kéo cửa Cài đặt cho khớp Popover + vá lệch màn Soi lại.
> Làm ở **v0.4.20**.

Trạng thái: ⬜ chưa làm · 🔄 đang làm · ✅ xong (chờ mắt người Windows) · ⏸️ hoãn có lý do.

## G1 — Phím tắt bật/tắt "Gõ tiếng Việt"

| ID | Trạng thái | Việc |
|---|---|---|
| **G1** | ✅ | Chủ dự án báo "chưa có phím tắt". Điều tra: phím tắt CÓ code nhưng **không nổ trên Windows** — mặc định cũ `0x7A000206` có mã phím byte-thấp `0x06` = keycode của **macOS** (kVK_Z), còn hook Windows so bằng **vkCode Windows** (VK_Z=0x5A) → không bao giờ khớp. Chủ dự án chọn **Ctrl + Alt + Z** → sửa mặc định `0x5A00035A` (VK_Z đúng) + migrate máy đã cài bản Mac-hỏng + **hiện chip phím tắt** read-only cạnh nút "Gõ tiếng Việt" (popover + Cài đặt), mirror chip macOS. |

## G2 — Đồng bộ Cài đặt ↔ Popover

| ID | Trạng thái | Việc |
|---|---|---|
| **G2a** | ✅ | Nhịp chuông: Cài đặt dùng "Nhanh/Vừa/Chậm" còn Popover dùng "30 / 60 / Tùy chỉnh + stepper". Kéo Cài đặt về **giống Popover** (30/60/Tùy chỉnh + stepper "− NN phút +" + nút Đặt, so-sánh-bằng để 45' không bị xếp nhầm vào 60'). |
| **G2b** | ✅ | Tab Hôm nay: Popover có toggle "Ngay bây giờ / Hôm nay" (3h ↔ 24h) + link "Soi lại hôm nay →", Cài đặt thiếu. **Thêm cả hai** vào tab Hôm nay của Cài đặt. |

## G3 — Màn Soi lại (lệch dòng + chưa đồng bộ)

| ID | Trạng thái | Việc |
|---|---|---|
| **G3** | ✅ | (a) **Khung sóng rỗng** khi chưa có dữ liệu (hộp trống): nay vẫn vẽ **khung trục** (nét đứt + Sáng·Trưa·Chiều·Tối) như macOS, chỉ không vẽ nước giả (luật dec.4 giữ nguyên). (b) **Thẻ Nuôi dưỡng cắt chữ** ("đóng máy" mất) + lệch dòng: đo **chiều cao thật** của câu quan sát / câu hỏi / gợi ý (DT_CALCRECT) rồi layout theo → không cắt, không lệch, dài mấy dòng cũng vừa. |

## Chờ mắt người Windows

- Bấm **Ctrl + Alt + Z** ở ô gõ bất kỳ → bật/tắt tiếng Việt (chip cạnh toggle hiện đúng "Ctrl + Alt + Z").
- Tab Chuông (Cài đặt): chọn "Tùy chỉnh" → stepper hiện, chỉnh phút + Đặt ăn; số khớp popover.
- Tab Hôm nay (Cài đặt): toggle Ngay-bây-giờ/Hôm-nay đổi khung sóng; link "Soi lại hôm nay →" mở màn Soi lại.
- Màn Soi lại lúc chưa có data: thấy khung trục (không hộp trống); gợi ý dài không bị cắt chữ.

## Còn treo (ghi FRICTION-LOG)

- **G1 config UI:** hiện phím tắt là **cố định Ctrl+Alt+Z** + chip read-only. Chưa có bộ cho người
  dùng TỰ ĐỔI tổ hợp. Chủ dự án cân nhắc có cần không, hay 1 tổ hợp cố định là đủ.
