//
//  KeyboardPreviewView.h
//  mindful-key — iOS container app (khung "Preview sống", story 2.3)
//
//  Khung mô phỏng thu nhỏ trong màn Cài đặt bàn phím — KHÔNG phải KeyboardViewController thật
//  (đó sống trong KeyboardExtension, ngoài Owned Scope story này), chỉ minh hoạ TẠI CHỖ bằng
//  vài hàng phím trang trí + nhãn kiểu gõ. Self-contained: không import KeyboardBridge/engine
//  (xem story 2.3 Dev Notes "vInputType/chiều cao bàn phím THẬT — CHƯA đọc giá trị này").
//
//  AC #3: gọi -updateWithInputType:heightLevel: NGAY trong cùng lần chạm/kéo, không debounce —
//  đổi tức thì, KHÔNG animate (đúng cả khi Reduce Motion bật lẫn tắt, đơn giản hoá bằng cách
//  không bao giờ animate khung này).
//

#import <UIKit/UIKit.h>
#import "KeyboardSettingsBridge.h"

NS_ASSUME_NONNULL_BEGIN

@interface KeyboardPreviewView : UIView

// Cập nhật NGAY (không animate) — nhãn phản ánh Telex/VNI đang chọn + chiều cao khung co giãn
// theo heightLevel (0.0-1.0, đã kẹp biên nếu ngoài khoảng). Gọi lại mỗi lần segmented/slider đổi.
- (void)updateWithInputType:(KeyboardSettingsInputType)inputType heightLevel:(double)heightLevel;

@end

NS_ASSUME_NONNULL_END
