# Màn Soi lại + nhật ký viết tay — Feedback chủ dự án (đợt 3)

> Nghiệm thu tay **v0.4.18** trên Windows, đối chiếu bản macOS (ảnh đính kèm). Ghi 2026-07-23.
> Đợt 3 (sau Popover = đợt 1, Bảng điều khiển = đợt 2). Trọng tâm: **màn Soi lại** + **nhật ký viết
> tay** bắt kịp macOS, cùng vài chỗ tinh chỉnh tab Chuông. Làm ở **v0.4.19**.

Trạng thái: ⬜ chưa làm · 🔄 đang làm · ✅ xong (chờ mắt người Windows) · ⏸️ hoãn có lý do.

## Tab Chuông (Cài đặt)

| ID | Trạng thái | Việc |
|---|---|---|
| **F1** | ✅ | Gỡ nút **"Chọn tiếng .wav của bạn…"** (card Giờ yên lặng) — icon nốt nhạc trong "BỘ TIẾNG" (CP2) đã mở đúng hộp chọn .wav rồi, nút này là lối thứ hai thừa. Giữ "Tạm hoãn 1 giờ". |
| **F2** | ✅ | **Giãn vùng khung giờ yên lặng** cho rõ khỏi tiêu đề "GIỜ YÊN LẶNG" — card cao hơn (105→116), tăng khoảng cách tiêu đề→hàng giờ (+36→+44), 2 stepper 100px cách nhau qua chữ "đến". |
| **F3** | ✅ | Thêm dòng **"Dự kiến reo lúc HH:MM (còn N phút)"** ngay dưới "Bật chuông tỉnh thức" (mirror card macOS + popover B5). Ẩn khi chuông tắt/đang hoãn. Dùng `Bell_MinutesUntilNextRing` sẵn có. |

## Màn Soi lại + nhật ký

| ID | Trạng thái | Việc |
|---|---|---|
| **F4** | ✅ | **Sóng "hôm nay" bị thiếu** — màn Soi lại nay vẽ **sóng cả ngày** trong thẻ có viền (trục Sáng·Trưa·Chiều·Tối), luôn hiện khung trục kể cả khi chưa đủ mẫu. (Có dữ liệu thật/seed thì thấy sóng ngay.) |
| **F5** | ✅ | **Đồng bộ màn Soi lại + "Những dòng đã viết" giống macOS.** Soi lại dựng lại thành **3 nhịp** (Nhận ra / Soi / Nuôi dưỡng): câu quan sát + dòng gác cổng · câu hỏi phản chiếu + **ô ghi một dòng** + link "Những dòng đã viết →" · thẻ gợi ý nhẹ + link "Chỉnh chuông quanh Nh →". Thêm **backend nhật ký viết tay** (`notes.enc`, DPAPI, consent riêng hỏi đúng lúc gõ dòng đầu, KHÔNG chạy sentiment lên chữ) + **cửa sổ đọc lại** (`NotesHistory`, cuộn được, ngày·câu hỏi·chữ viết). |
| **F6** | ✅ | **Giả lập dữ liệu để test sóng + biểu đồ** — menu khay **"Thử nghiệm"** có "Tạo dữ liệu mẫu · 12 giờ" (sóng hôm nay dày), "· 30 ngày" (sample + checkin + vài note quá khứ), "Xoá dữ liệu mẫu". Dữ liệu đánh dấu riêng (`kSeedMarker`), gỡ sạch được ở cả `mood.enc` lẫn `notes.enc`. |

## Ghi chú kỹ thuật (khác biệt macOS ↔ Windows, có chủ đích)

- **`notes.enc` là TỆP RIÊNG**, KHÔNG nhét vào `mood.enc`: schema `mood.enc` bị khoá "không chứa câu
  chữ" (SYNC-emotion-mechanism-v2 §A), và văn bản nhiều dòng không sống được trong TSV 1-dòng. macOS
  dùng cột `note_blob` trong SQLite; Windows dùng tệp phẳng riêng, cùng DPAPI. Xem `MoodStore.h`.
- **Gợi ý "Nuôi dưỡng" để inline ở vỏ** (như macOS `TinySuggestionsFor`): core `MoodPhrasing` cố ý
  chỉ giữ *quan sát* + *câu hỏi*, không giữ gợi ý. Không phạm ranh giới bộ-não-dùng-chung.
- **Công cụ "Thử nghiệm" (F6) hiện có Ở CẢ BẢN RELEASE** (trước ở `#ifdef _DEBUG`): chủ dự án cần thử
  trên installer đã cài. ⚠️ Xem FRICTION-LOG 2026-07-23 — **PHẢI ẩn/bỏ trước bản công khai 1.0**.

## Chờ mắt người Windows (F4/F5/F6)

- Soi lại: 3 nhịp bố cục có đúng cỡ/không bị cắt trên màn thật không; ô ghi gõ được, hỏi consent đúng
  lúc gõ dòng đầu; đóng màn thì chữ được lưu; mở lại thấy đúng chữ.
- "Những dòng đã viết": mở từ link, cuộn mượt, ngày/câu hỏi/chữ đúng thứ tự mới-nhất-trước.
- Seed 12 giờ → sóng hôm nay dày; 30 ngày → nhật ký có vài dòng cũ; "Xoá dữ liệu mẫu" sạch cả hai.
