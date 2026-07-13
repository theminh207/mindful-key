//
//  SuggestionBarView.mm
//  mindful-key — iOS keyboard extension (Round 2, story 2.1)
//
//  Xem SuggestionBarView.h. View UIKit thuần (không blur/ảnh nền/bóng nặng, không nạp từ điển)
//  — đúng NFR-01 (trần jetsam ~48-60MB). Nền secondarySystemBackgroundColor khớp màu phím chức
//  năng hiện có (trung tính, không mã hoá valence — hiến chương).

#import "SuggestionBarView.h"

const CGFloat SuggestionBarViewHeight = 40;

@implementation SuggestionBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [self.heightAnchor constraintEqualToConstant:SuggestionBarViewHeight].active = YES;
        // Bar rỗng không có nội dung trực quan cho VoiceOver — không chặn focus của các phím bên
        // dưới (khác con sóng ở story 2.5, vốn sẽ tự đặt isAccessibilityElement=NO vì là trang trí).
        self.isAccessibilityElement = NO;
    }
    return self;
}

- (void)setSuggestions:(NSArray<NSString *> *)suggestions {
    // Story 2.1: hố cắm sẵn, KHÔNG wiring giả. Engine chưa có API gợi ý từ/tự sửa lỗi (xem audit
    // trong Dev Agent Record của story 2.1) nên nơi gọi hàm này trong story chỉ truyền mảng rỗng
    // — thân hàm để trống là chủ đích (không render gì), không phải bug bỏ sót.
}

@end
