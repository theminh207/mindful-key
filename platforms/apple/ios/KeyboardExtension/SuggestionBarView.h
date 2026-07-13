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

// Story 2.5 (AC#1/#2/#3): đặt biên độ sóng ambient CHUẨN HOÁ [0.0, 1.0] — giá trị đã qua
// EmotionWaveAmplitude(risk) (Q1: ngưỡng chết + dâng mượt). View CHỈ vẽ hình sóng theo biên độ
// này (màu teal cố định, không chữ, không nhánh màu theo risk) — KHÔNG tự đọc MoodBridge, KHÔNG
// tự kiểm Full Access/mk_isSecureField. Nơi gọi (KeyboardViewController) chịu trách nhiệm toàn bộ
// việc gác cổng (AC#6/#7: không Full Access thì KHÔNG BAO GIỜ gọi hàm này; ô bảo mật thì gọi với
// amplitude 0.0) TRƯỚC khi gọi — lazy-tạo layer sóng ở lần gọi đầu tiên, nên chưa từng gọi hàm
// này = thanh gợi ý giữ nguyên trạng thái rỗng Round 1 (đúng AC#7).
- (void)setWaveAmplitude:(double)amplitude;

@end

NS_ASSUME_NONNULL_END
