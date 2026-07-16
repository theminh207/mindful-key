//
//  GatekeeperCardView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.4 / Áo mới v2 — xem GatekeeperCardView.h cho hợp đồng + ràng buộc hiến chương.
//

#import "GatekeeperCardView.h"
#import "EmotionWaveView.h"
#import "EmotionRiverView.h"
#import "BrandColors.h"
#import "BrandControls.h"
#import "MoodWatchMac.h"
#import "MoodStoreMac.h"
#import "MoodPhrasingMac.h"
#import "ReflectionScreenMac.h"

// [MINDFUL] Zoom-in/Zoom-out (chốt 2026-07-16): thẻ này ("NGAY BÂY GIỜ") giờ là **cửa sổ 6 tiếng**,
// đi cặp với thẻ "Hôm nay" (cả ngày) — người dùng có 2 tầm nhìn cùng một ngày.
//
// Trước đây chỗ này là `EmotionWaveView` 150×26: sóng trang trí vẽ ĐÚNG MỘT giá trị
// (`MoodWatchMac_LastSendRisk()` — rủi ro của chữ vừa gõ), không có trục thời gian.
// ⚠️ Đừng tưởng đổi lại là "khôi phục phản ứng sống": sóng đó CHƯA BAO GIỜ động khi gõ — popover là
// `NSPopoverBehaviorTransient`, bấm ra ngoài là đóng, nên không ai vừa gõ vừa nhìn được nó. Nó luôn
// chỉ là ảnh chụp lúc MỞ. Nay giá trị đó thành ĐẦU SÓNG ở mép phải của sông — vẫn là "khoảnh khắc
// này", nhưng có bối cảnh phía sau.
//
// 3 TIẾNG (chủ dự án chốt 2026-07-16 "khoảng 2-3 tiếng"): chọn 3 chứ không 2 vì trục chia 3 phần ra
// đúng số tròn — "3 giờ trước · 2 giờ · 1 giờ · bây giờ". Để 2 tiếng thì thành "1,3 giờ · 40 phút",
// đọc như đồng hồ đo, mất chất quan sát. 3 tiếng ≈ 12 nhịp chuông (nhịp 15 phút) — đủ dày để thấy
// hình dâng/lắng, đủ hẹp để gọi là "ngay bây giờ".
static const CGFloat kWindowSeconds = 3 * 3600.0;

static const CGFloat kPad         = 14.0;  // padding trong thẻ (mockup .card: 13px 14px)
static const CGFloat kWaveGap     = 6.0;   // sông → tít
// [MINDFUL] 2026-07-16 — 20pt (1 dòng) đủ cho tít CŨ ("Mặt hồ đang phẳng lặng", 22 ký tự). Tít mới
// đọc hình dạng ngày nên dài gấp đôi: "Sáng, trưa và chiều có gợn, phần lớn êm" ≈ 38 ký tự, ở 16pt
// semibold vượt bề ngang thẻ (300pt) → chừa 2 dòng, nếu không là cụt chữ đúng như lỗi đã gặp ở
// nhãn trục. Câu ngắn ("Gác cổng đang tắt") chỉ dùng 1 dòng, thừa chỗ chứ không hỏng.
static const CGFloat kTitleH      = 42.0;  // tít trạng thái, 16pt semibold, tối đa 2 dòng
static const CGFloat kTitleGap    = 8.0;   // tít → hàng phụ đề/link
static const CGFloat kSubRowH     = 34.0;  // hàng phụ đề/link — chừa chỗ tối đa 2 dòng cho state "tắt"

@implementation GatekeeperCardView {
    EmotionRiverView *_river;   // cửa sổ 6 tiếng, mép phải = ngay lúc mở (thay EmotionWaveView 1-giá-trị)
    NSTextField *_title;    // câu TRẠNG THÁI động ("Mặt hồ đang gợn nhẹ"...) — KHÔNG còn tít tĩnh
    NSTextField *_caption;  // "Gác cổng đang canh khi bạn gõ" / "Bật lại trong Cài đặt..."
    NSButton *_reflectLink; // "Soi lại hôm nay →" — cam, link (KHÔNG phải CTA)
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        // [MINDFUL] Áo mới v2 — thẻ TRẮNG viền mảnh (thay dải nền tealLight cũ).
        [self applyThinCardStyle];

        _river = [[EmotionRiverView alloc] initWithFrame:NSZeroRect];
        [_river setCardChromeHidden:YES];   // đang nằm TRONG thẻ này — bật lên là hộp lồng hộp
        [_river setCaptionHidden:YES];      // thẻ đã có tít + phụ đề riêng, thêm caption là 3 câu chồng nhau
        [self addSubview:_river];

        _title = [self labelWithString:@"" font:[NSFont systemFontOfSize:16 weight:NSFontWeightSemibold] color:[Brand charcoal]];
        _title.lineBreakMode = NSLineBreakByWordWrapping;
        _title.maximumNumberOfLines = 2;   // xem kTitleH — tít đọc hình dạng ngày có thể tràn 1 dòng
        [self addSubview:_title];

        _caption = [self labelWithString:@"" font:[NSFont systemFontOfSize:11.5 weight:NSFontWeightRegular] color:[Brand muted]];
        _caption.lineBreakMode = NSLineBreakByWordWrapping;
        _caption.maximumNumberOfLines = 2;
        [self addSubview:_caption];

        // "Soi lại hôm nay →" — link text (KHÔNG phải nút cam CTA), tông cam.
        _reflectLink = [NSButton buttonWithTitle:@"" target:self action:@selector(onReflect:)];
        _reflectLink.bordered = NO;
        _reflectLink.bezelStyle = NSBezelStyleInline;
        [(NSButtonCell *)_reflectLink.cell setBackgroundColor:[NSColor clearColor]];
        _reflectLink.attributedTitle = [self linkTitle:@"Soi lại hôm nay →"];
        [self addSubview:_reflectLink];

        [self refresh];
    }
    return self;
}

- (NSTextField *)labelWithString:(NSString *)s font:(NSFont *)f color:(NSColor *)c {
    NSTextField *l = [NSTextField labelWithString:s];
    l.font = f;
    l.textColor = c;
    l.backgroundColor = [NSColor clearColor];
    l.bordered = NO;
    l.editable = NO;
    return l;
}

- (NSAttributedString *)linkTitle:(NSString *)s {
    return [[NSAttributedString alloc] initWithString:s attributes:@{
        NSForegroundColorAttributeName : [Brand orange],
        NSFontAttributeName : [NSFont systemFontOfSize:12.5 weight:NSFontWeightSemibold]
    }];
}

#pragma mark - Layout (frame-based, để khớp panel absolute-frame hiện tại)

// Sông trải TRỌN bề ngang thẻ (không trừ kPad): lề trong 14pt của chính nó khớp đúng kPad của thẻ,
// nên nước/trục thẳng hàng với tít bên dưới. Trừ kPad ở đây sẽ thành thụt lề 28pt, lệch với tít.
- (CGFloat)preferredHeight {
    return [_river preferredHeight] + kWaveGap + kTitleH + kTitleGap + kSubRowH + kPad;
}

- (void)layout {
    [super layout];
    CGFloat w = NSWidth(self.bounds);
    CGFloat h = NSHeight(self.bounds);

    CGFloat riverH = [_river preferredHeight];
    _river.frame = NSMakeRect(0, h - riverH, w, riverH);
    CGFloat top = h - riverH - kWaveGap;

    _title.frame = NSMakeRect(kPad, top - kTitleH, w - 2 * kPad, kTitleH);
    top -= kTitleH + kTitleGap;

    // Hàng phụ đề (trái) + link (phải), canh dòng đầu.
    NSSize linkSize = _reflectLink.attributedTitle.size;
    _reflectLink.frame = NSMakeRect(w - kPad - linkSize.width, top - linkSize.height,
                                    linkSize.width, linkSize.height);
    _caption.frame = NSMakeRect(kPad, top - kSubRowH, w - 2 * kPad - linkSize.width - 10.0, kSubRowH);
}

#pragma mark - State

- (void)refresh {
    BOOL enabled = MoodWatchMac_IsEnabled() != 0;
    if (enabled) {
        double risk = MoodWatchMac_LastSendRisk();   // 0..1 — giá trị NGAY LÚC NÀY (chữ vừa gõ)
        // Ngưỡng "quãng không gõ" = 1.5 nhịp chuông, GIỐNG HỆT thẻ "Hôm nay" (PanelViewController)
        // — 2 thẻ đọc cùng một ngày, lệch ngưỡng là chỗ này nối nước còn chỗ kia ngắt.
        extern int vBellInterval;
        double gapSecs = (vBellInterval > 0 ? vBellInterval : 60) * 60.0 * 1.5;
        [_river setRecentSamples:MoodStoreMac_FetchSamplesSince(kWindowSeconds)
                   windowSeconds:kWindowSeconds
                      gapSeconds:gapSecs
                        liveHead:risk];

        // [MINDFUL] 2026-07-16 (chủ dự án chốt) — tít giờ ĐỌC HÌNH DẠNG CẢ NGÀY ("Sáng và chiều có
        // gợn, phần lớn êm") thay vì chỉ gọi tên trạng thái tức thời ("Mặt hồ đang phẳng lặng").
        // Cặp với sóng 3 tiếng bên trên: sóng cho thấy VỪA RỒI, câu cho biết CẢ NGÀY — nhìn 1 thẻ
        // là nắm được 2 tầm. Câu sinh từ MoodPhrasingMac (nguồn duy nhất, cùng ngưỡng với màn Soi lại).
        NSArray<NSDictionary *> *today = MoodStoreMac_FetchTodaySamples();
        _title.stringValue = MoodPhrasing_DayShapeSentence(today);

        // Số nhịp chuông = APP lấy được bao nhiêu mẫu hôm nay → cho biết câu tít dựa trên bao nhiêu
        // dữ liệu. KHÔNG phải điểm số / chuỗi-ngày-liên-tục: không mục tiêu, không so hôm qua,
        // không khen nhiều / trách ít. Minh bạch về ĐỘ DÀY DỮ LIỆU, không phải bảng thành tích.
        _caption.stringValue = [NSString stringWithFormat:@"Gác cổng đang canh khi bạn gõ · %ld nhịp chuông hôm nay",
                                 (long)today.count];
    } else {
        // State "tắt": sông TRỐNG thật thà (không vẽ nước giả), copy trung tính. KHÔNG đỏ/xám-chết.
        [_river setRecentSamples:nil windowSeconds:kWindowSeconds gapSeconds:0 liveHead:-1.0];
        _title.stringValue = @"Gác cổng đang tắt";
        _caption.stringValue = @"Bật lại trong Cài đặt khi bạn sẵn sàng";
    }
    self.needsLayout = YES;
}

- (void)onReflect:(id)sender {
    ReflectionScreenMac_Show();
}

@end
