//
//  SystemSettingsView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Batch "Hệ thống + Chuông" (bmad-output/macos/SCREEN-REFERENCE.md §2.5) — pane "Hệ
//  thống" dựng MỚI bằng linh kiện brand, thay cho storyboard cũ `tabviewSystem` (rỗng, không có
//  nội dung — xem SettingsWindowController.mm). 4 mục đã chốt (decision-log 2026-07-16 "Chẩn UI
//  lệch"): Khởi động cùng macOS · Hiện icon menu bar · Phím tắt bật/tắt bộ gõ (chỉ HIỂN THỊ, không
//  sửa ở đây) · Cập nhật (phiên bản thật từ version.env + link GitHub Releases — dự án chưa có
//  backend tự kiểm bản mới nên không dựng nút giả).
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SystemSettingsView : NSView

- (CGFloat)preferredHeight;

/// Đọc lại trạng thái THẬT (login item, status bar, phím tắt, phiên bản) — gọi mỗi khi pane "Hệ
/// thống" được chọn, để không hiện giá trị cũ nếu đổi từ nơi khác (vd tray) lúc cửa sổ đang đóng.
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
