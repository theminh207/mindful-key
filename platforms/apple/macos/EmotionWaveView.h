//
//  EmotionWaveView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.2 — widget "con sóng" ~ biểu đạt trạng thái cảm xúc bằng BIÊN ĐỘ.
//
//  Ràng buộc HIẾN CHƯƠNG khoá trong file này (docs/AGENT-BRIEF.md §2.2/2.3):
//    - CHỈ 1 hue: nội suy màu giữa teal (#1D7C91) và stone (#8A9BA0). KHÔNG bao giờ đổi
//      sang cam/đỏ. Biên độ chỉ đổi độ cao sóng / tần số / độ dày nét.
//    - Mặc định THU GỌN. Nghỉ (biên độ ~0) = tĩnh phẳng im lặng, KHÔNG loop animation.
//    - Input DUY NHẤT là 1 con số biên độ 0..1 — KHÔNG nhận/giữ/vẽ chuỗi gõ thật, giờ, tên app.
//      (Người ráp sau — story 1.4/1.6 — bơm MoodWatchMac_LastSendRisk() vào đây.)
//    - Copy trạng thái là câu MÔ TẢ trung tính (gate "mô tả hay phán xét?").
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmotionWaveView : NSView

/// Biên độ hiện tại, 0.0 (phẳng lặng) .. 1.0 (gợn sóng). Input duy nhất của view.
@property (nonatomic, assign) CGFloat amplitude;

/// Mặc định NO (thu gọn). Story 1.4/1.6 bật lên khi người dùng chủ động mở rộng.
@property (nonatomic, assign, getter=isExpanded) BOOL expanded;

/// Câu mô tả trạng thái hiện tại (mô tả, không phán xét) — cũng là accessibilityLabel.
@property (nonatomic, readonly) NSString *stateDescription;

/// Đổi biên độ. animated=YES → chuyển mượt 400–600ms (tự tắt khi "Giảm chuyển động" bật).
- (void)setAmplitude:(CGFloat)amplitude animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
