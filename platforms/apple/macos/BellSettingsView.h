//
//  BellSettingsView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.5 — Card "Chuông" (BellSettings). Đặt DƯỚI GatekeeperCard, nhỏ hơn,
//  không viền nhấn (xem DESIGN-macos-control-panel.md §2.3).
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

/// Chiều cao cần để hiện đủ nội dung theo trạng thái disclosure hiện tại (focus-explain,
/// nâng cao, caption lỗi giờ). Host (ViewController) gọi để tính khung cửa sổ.
- (CGFloat)preferredHeight;

/// Gọi khi 1 disclosure toggle làm đổi preferredHeight → host cần nới cửa sổ + đặt lại frame.
@property (nonatomic, copy, nullable) void (^onLayoutChanged)(void);

/// Đọc lại giá trị từ UserDefaults và cập nhật control (gọi khi panel mở).
- (void)refresh;

/// [MINDFUL] Popover 3-tab ("Áo mới" Bước 1) — gọi 1 LẦN ngay sau khi tạo view khi đặt trong
/// tab "Chuông" riêng: bung nội dung sẵn (không chờ bấm mở) + ẩn hàng tiêu đề "Chuông ▸/▾"
/// (tab đã có nhãn riêng nên hàng đó thừa). KHÔNG đổi logic đọc/ghi UserDefaults bên trong.
- (void)expandForTabPresentation;

@end

NS_ASSUME_NONNULL_END
