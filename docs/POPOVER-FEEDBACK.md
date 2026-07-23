# Popover — Feedback chủ dự án (đợt 1)

> Nghiệm thu tay **v0.4.16** trên Windows, đối chiếu bản macOS. Ghi ngày 2026-07-23.
> Sau đợt popover này, chủ dự án sẽ feedback tiếp ở **Bảng điều khiển** (Settings window) — đợt 2.

Trạng thái: ⬜ chưa làm · 🔄 đang làm · ✅ xong (chờ mắt người Windows) · ⏸️ hoãn có lý do · 🔎 chẩn (không phải lỗi code).

> **Xử lý đợt v0.4.17** (2026-07-23). Điều tra 8-agent (hiện trạng + macOS + cách vá) → làm tuần tự →
> review đối kháng. Mỗi mục 1 commit. Nghiệm thu cuối = mắt người Windows.

## Nhóm Chuông (tiếng chuông)

| ID | Trạng thái | Việc |
|---|---|---|
| **P1** | ✅ | Nhịp "Tùy chỉnh": thay ô tĩnh bằng **stepper "− NN phút +" (bước 5, kẹp 15–240) + nút "Đặt"**. Owner-draw thuần chuột nên không dùng ô EDIT gõ-số (dễ nhấp nháy, không verify mù) — stepper đủ đặt khung giờ. Kẹp im lặng (không câu khiển trách). |
| **P2** | ✅ | Bấm icon nốt nhạc (bộ tiếng custom) **luôn mở hộp chọn .wav** (GetOpenFileName → Bell_InstallCustomSound → nghe thử), tách khỏi guard `!= currentSnd` để đổi tệp được. Mirror macOS onBellClick + B6. |
| **P3** | 🔎 | Popover ĐÃ có dòng "Dự kiến reo" từ B5 (TrayPopover.cpp:129-143) — **code KHÔNG hỏng**. Điều tra kết luận: nhiều khả năng chạy **bản .exe cũ ở Program Files** (bẫy quen thuộc) hoặc đang "tạm hoãn". Cần: gỡ bản cũ, cài v0.4.17, mở lại. Dòng cho tab Chuông cửa Cài đặt (parity) để dành **batch bảng điều khiển**. |

## Nhóm Hôm nay (độ cảm xúc — chưa đủ như macOS)

| ID | Trạng thái | Việc |
|---|---|---|
| **P4** | ✅ | **Bug thật:** nhãn trục vẽ SAU `if (xs.empty()) return` nên rỗng = mất khung (ô chấm-chấm trống). Đã nhấc khối nhãn lên trên return → khung **3 giờ/2 giờ/1 giờ/bây giờ** luôn hiện. dec.4: rỗng chỉ vẽ trục, không bịa nước. |
| **P5** | ✅ | Thêm **toggle "Ngay bây giờ / Hôm nay"**: 24h dùng `FetchTodaySamples` + trục Sáng/trưa/chiều/tối (engine vẽ đã có ở màn Soi lại). |
| **P6** | ✅ | Link **"Soi lại hôm nay →"** dưới sông (khi nhật ký bật) → `ReflectionScreen_Show`. Cam = lớp CTA, không mã hoá cảm xúc. |

## Nhóm Bộ gõ

| ID | Trạng thái | Việc |
|---|---|---|
| **P7** | ✅ | Thêm thẻ **"GÕ TẮT"**: bật Macro (vUseMacro) + Chuyển chế độ thông minh (vUseSmartSwitchKey) + link "Cấu hình gõ tắt ▸" → `onMacroTable`. |

## Khác

| ID | Trạng thái | Việc |
|---|---|---|
| **P8** | ✅ | **DEV seed (chỉ bản DEBUG):** `MoodStore_DevSeed` rải ~180 sample backdate 24h + 5 checkin, mỗi dòng đánh dấu để `MoodStore_DeleteSimulatedData` dọn riêng. 2 mục menu khay "[DEV] Tạo/Xoá dữ liệu mẫu". KHÔNG lọt bản Release. |
