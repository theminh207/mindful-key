# Nhật Ký Tâm + phím tắt + dữ liệu mẫu — Feedback chủ dự án (đợt 5)

> Nghiệm thu tay **v0.4.21** trên Windows + macOS. Ghi 2026-07-24.
> Đợt 5. Chia 2 bản: **v0.4.22** (H2 + H3) và **v0.4.23** (H4 — mục nav "Nhật Ký Tâm").

Trạng thái: ⬜ chưa làm · 🔄 đang làm · ✅ xong (chờ mắt người) · ⏸️ hoãn có lý do.

| ID | Trạng thái | Việc |
|---|---|---|
| **H1** | ⏸️ | "Cho tự đổi phím tắt thay vì fix cứng." Chủ dự án chốt **để nguyên** (chip cố định Ctrl+Alt+Z), chờ feedback người dùng trước khi làm bộ chỉnh phím tắt. Ghi FRICTION-LOG. |
| **H2** | ✅ (v0.4.22) | Công cụ Thử nghiệm nay có **3 mốc: 12 giờ / 1 tuần / 30 ngày** trên **cả Windows lẫn macOS**. macOS: **phơi ra bản Release** (trước chỉ Debug) trong submenu "Thử nghiệm". Nhãn đồng bộ 2 nền. |
| **H3** | ✅ (v0.4.22) | Màn Soi lại (Windows): thêm **dòng chân trang** tin cậy ("Xử lý trên máy · Câu hỏi mỗi ngày một khác · Không điểm số, không chuỗi ngày") + khung sóng rỗng đã hiện trục (từ v0.4.20/G3). |
| **H4** | ⬜ (v0.4.23) | Thêm mục nav **"Nhật Ký Tâm"** (ngay **dưới "Hôm nay"**) hiện danh sách "Những dòng đã viết", trên **cả macOS & Windows**. GIỮ luôn link "Những dòng đã viết →" trong màn Soi lại. |

## Ghi chú kỹ thuật H4 (làm ở v0.4.23)

- **Windows:** MainControlDialog dùng `currentTab` số. Chèn nav ở GIỮA sẽ đánh số lại mọi pane (dễ vỡ).
  Cách an toàn: thêm pane "Nhật Ký Tâm" ở index MỚI (cuối) + bảng **thứ-tự-hiển-thị** map vị trí nav →
  index, để "Nhật Ký Tâm" đứng thứ 2 mà KHÔNG phải đánh số lại pane cũ. Pane vẽ danh sách note
  (owner-draw) + link "Xem tất cả →" mở cửa sổ cuộn khi tràn.
- **macOS:** `SettingsWindowController` (nav 6 mục có ràng buộc storyboard) — thêm mục + pane nhúng
  view "Những dòng đã viết" (`NotesHistoryMac`).

## Chờ mắt người (v0.4.22)

- Windows + macOS: menu khay → Thử nghiệm → "· 1 tuần" bơm 7 ngày; mở Cài đặt ▸ Hôm nay ▸ Tuần xem biểu đồ.
- macOS bản Release: submenu "Thử nghiệm" có hiện (trước bị ẩn).
- Windows: mở Soi lại thấy dòng chân trang ở đáy.
