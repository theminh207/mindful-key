//
//  SuggestionBarView.h
//  mindful-key — iOS keyboard extension (Round 2, story 2.1)
//
//  Thanh ~40pt nằm phía TRÊN 4 hàng phím. Story 2.1: LUÔN TRỐNG — audit trực tiếp
//  core/engine/{Vietnamese,Macro,Engine}.h không tìm thấy API gợi ý từ/tự sửa lỗi kiểu
//  autocomplete nào được expose (xem Dev Agent Record của story 2.1). Đây chỉ là bề mặt UIKit
//  thuần để story 2.5 gắn con sóng `~` chánh niệm vào, cộng 1 điểm nối tương lai cho gợi ý từ
//  thật (nếu engine có sau này) — KHÔNG wiring dữ liệu giả ở story này.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Chiều cao cố định của thanh — khớp EXPERIENCE.md/DESIGN.md (~40pt). Dùng hằng số này thay vì
// hard-code lại 40 ở nơi khác (vd khi cộng vào height constraint tổng của bàn phím).
FOUNDATION_EXPORT const CGFloat SuggestionBarViewHeight;

@interface SuggestionBarView : UIView

// Điểm nối tương lai (AC#5): nhận danh sách từ gợi ý để hiển thị. Story 2.1 KHÔNG có nguồn dữ
// liệu thật nên hàm này chỉ được gọi với mảng rỗng — mảng rỗng thì không hiển thị gì. BẤT KỲ
// consumer tương lai nào truyền dữ liệu đọc từ nội dung đang gõ (vd gợi ý từ thật, sau khi engine
// có API) PHẢI tự kiểm `-mk_isSecureField` (KeyboardViewController) TRƯỚC khi gọi hàm này, đúng
// hợp đồng riêng tư đã lập ở story 1.4 — không đọc/không hiện gợi ý ở ô bảo mật.
- (void)setSuggestions:(NSArray<NSString *> *)suggestions;

@end

NS_ASSUME_NONNULL_END
