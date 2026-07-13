//
//  BellSettingsView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.5 — Card "Chuông" (BellSettings).
//  [MINDFUL] Áo mới v2 (2026-07-13, decision-log "Diện mạo mới v2") — nội dung tab "Chuông" trong
//  popover 3-tab: gom lại thành 3 thẻ TRẮNG viền mảnh có eyebrow riêng (NHẬN DIỆN / ÂM THANH /
//  YÊN LẶNG), khớp mockup-v2-tabbed.html. View này LUÔN hiện đủ (không còn khái niệm thu gọn/mở
//  của bản danh sách cũ — tab đã tự phân tách nội dung rồi).
//
//  Ràng buộc HIẾN CHƯƠNG khoá trong file này (docs/AGENT-BRIEF.md §2.2/2.3):
//    - Độ nhạy = 3 nhãn CHỮ ("Ít nhạy · Vừa · Nhạy"), KHÔNG số, KHÔNG progress bar,
//      KHÔNG nút "xem thử ngay" cạnh slider số.
//    - Track slider = 1 màu teal (cấm cam/gradient/đầu mút màu cảnh báo).
//    - Toggle Focus sync mặc định OFF, opt-in có caption giải thích quyền TRƯỚC khi bật.
//    - Giờ yên lặng thủ công; mọi copy qua gate "mô tả hay phán xét?".
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BellSettingsView : NSView

/// Chiều cao cần để hiện đủ nội dung theo trạng thái hiện tại (caption lỗi giờ / giải thích
/// quyền Focus có đang hiện hay không). Host (ViewController) gọi để tính khung cửa sổ.
- (CGFloat)preferredHeight;

/// Gọi khi 1 phần đổi làm thay đổi preferredHeight (lỗi giờ yên lặng / bật-tắt Focus sync) → host
/// cần nới cửa sổ + đặt lại frame.
@property (nonatomic, copy, nullable) void (^onLayoutChanged)(void);

/// Đọc lại giá trị từ UserDefaults và cập nhật control (gọi khi panel mở).
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
