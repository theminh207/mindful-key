# Popover — Feedback chủ dự án (đợt 1)

> Nghiệm thu tay **v0.4.16** trên Windows, đối chiếu bản macOS. Ghi ngày 2026-07-23.
> Sau đợt popover này, chủ dự án sẽ feedback tiếp ở **Bảng điều khiển** (Settings window) — đợt 2.

Trạng thái: ⬜ chưa làm · 🔄 đang làm · ✅ xong (chờ mắt người Windows) · ⏸️ hoãn có lý do.

## Nhóm Chuông (tiếng chuông)

| ID | Trạng thái | Việc |
|---|---|---|
| **P1** | ⬜ | Nhịp "Tùy chỉnh" trên popover CHƯA có nút "Đặt" + ô nhập số phút. macOS: "30 / 60 / [25] phút [Đặt]" (gõ số rồi Đặt/Enter). Popover hiện chỉ hiện "120 phút" tĩnh, không đặt được. |
| **P2** | ⬜ | Icon nốt nhạc (bộ tiếng "custom") trên popover CHƯA cho chọn file .wav. Bấm vào phải mở hộp chọn tệp (như nút ".wav của bạn" ở tab Chuông cửa Cài đặt — B6). |
| **P3** | ⬜ | Popover CHƯA hiện "Dự kiến reo lúc HH:mm (còn N phút)". B5 đã code dòng này trong `ProcessTabBell` nhưng KHÔNG hiện — cần chẩn (có thể `Bell_MinutesUntilNextRing` trả -1 vì timer chưa arm / interval=0). |

## Nhóm Hôm nay (độ cảm xúc — chưa đủ như macOS)

| ID | Trạng thái | Việc |
|---|---|---|
| **P4** | ⬜ | Khung sóng "hiện tại" với trục thời gian **3 giờ / 2 giờ / 1 giờ / bây giờ** (như macOS). Tab Hôm nay Windows hiện chỉ có ô chấm-chấm TRỐNG. |
| **P5** | ⬜ | Khung sóng **24 giờ** (Sáng / trưa / chiều / tối) — chế độ xem thứ hai. |
| **P6** | ⬜ | Đường dẫn **"Soi lại hôm nay"** trên popover → mở `ReflectionScreen`. |

## Nhóm Bộ gõ

| ID | Trạng thái | Việc |
|---|---|---|
| **P7** | ⬜ | Tab Bộ gõ CHƯA có **gõ tắt (macro)** + một số tính năng khác (đối chiếu macOS + tab đầy đủ cửa Cài đặt). |

## Khác

| ID | Trạng thái | Việc |
|---|---|---|
| **P8** | ⬜ | Tính năng **DEV build dữ liệu mẫu** — seed `MoodStore` bằng dữ liệu giả để test sóng/nhật ký ngay, không phải chờ gõ hàng giờ. |
