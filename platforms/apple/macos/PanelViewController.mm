//
//  PanelViewController.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] "Áo mới" Bước 1 — xem PanelViewController.h.
//  [MINDFUL] Áo mới v2 (2026-07-13, decision-log "Diện mạo mới v2") — header đổi từ chrome teal
//  đặc sang TRẮNG liền mạch với panel (khớp mockup-v2-tabbed.html .top); pill "VN" nhị phân thay
//  chấm+chữ trạng thái cũ. Tab "Hôm nay" giờ có 2 nhóm: "NGAY BÂY GIỜ" (thẻ Gác cổng) + "HÔM NAY"
//  (thẻ dòng sông, khung trống — Bước 3 sẽ đổ dữ liệu thật) + dòng "Chuông tỉnh thức kế tiếp".
//

#import "PanelViewController.h"
#import "GatekeeperCardView.h"
#import "EmotionRiverView.h"
#import "BellSettingsView.h"
#import "InputMethodCardView.h"
#import "BrandColors.h"
#import "BrandControls.h"
#import "BellMac.h"

static const CGFloat kPanelW  = 360.0;
static const CGFloat kMargin  = 16.0;
static const CGFloat kCardW   = kPanelW - 2 * kMargin;   // 328
static const CGFloat kHeaderH = 38.0;
static const CGFloat kFooterH = 34.0;

// Thanh tab (đầu popover, dưới header) — kiểu Haynoi: track nền xám nhạt, ô đang chọn = pill
// TRẮNG nổi (bóng nhẹ) + chữ đậm hơn. CỐ Ý không dùng teal-fill (đó là ngôn ngữ của MKSegmented
// trong BellSettingsView — 1 control khác, ở tầng field-level, không phải nav-level).
static const CGFloat kTabBarH      = 34.0;
static const CGFloat kTabGapTop    = 12.0;   // đáy header → đỉnh tab bar
static const CGFloat kTabGapBottom = 14.0;   // đáy tab bar → đỉnh nội dung

// [MINDFUL] Áo mới v2 — nhịp dọc riêng cho tab "Hôm nay" (2 nhóm eyebrow+thẻ + 1 dòng chuông).
static const CGFloat kEbH        = 13.0;
static const CGFloat kEbGap      = 8.0;
static const CGFloat kSectionGap = 16.0;
static const CGFloat kBellLineH  = 16.0;

typedef NS_ENUM(NSInteger, MKPanelTab) {
    MKPanelTabToday = 0,   // "Hôm nay" — GatekeeperCardView + EmotionRiverView
    MKPanelTabBell  = 1,   // "Chuông"  — BellSettingsView
    MKPanelTabInput = 2,   // "Bộ gõ"   — InputMethodCardView
};

// View lật (gốc trên-trái, y tăng xuống) để xếp mục top-down tự nhiên. Chính là view của popover
// (không dùng NSScrollView — mỗi tab vừa 1 màn, kích thước popover = kích thước nội dung tab đó).
@interface MKFlippedView : NSView
@end
@implementation MKFlippedView
- (BOOL)isFlipped { return YES; }
@end

#pragma mark - MKTabBar (segmented kiểu Haynoi: track xám nhạt, active = pill trắng nổi)

@interface MKTabBar : NSView
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, assign) NSInteger selectedIndex;   // 0-based
@property (nonatomic, copy, nullable) void (^onSelect)(NSInteger index);
@end

@implementation MKTabBar {
    NSView *_indicator;                     // pill trắng nổi sau nhãn đang chọn
    NSMutableArray<NSButton *> *_buttons;
}

- (instancetype)initWithFrame:(NSRect)f {
    if ((self = [super initWithFrame:f])) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [Brand softWhite].CGColor;   // track xám nhạt
        _selectedIndex = 0;
        _buttons = [NSMutableArray array];

        _indicator = [[NSView alloc] initWithFrame:NSZeroRect];
        _indicator.wantsLayer = YES;
        _indicator.layer.backgroundColor = [NSColor whiteColor].CGColor;
        // Bóng nhẹ (KHÔNG phải viền màu cảm xúc) — chỉ để ô đang chọn "nổi" lên khỏi track.
        _indicator.layer.shadowColor = [NSColor blackColor].CGColor;
        _indicator.layer.shadowOpacity = 0.12;
        _indicator.layer.shadowRadius = 3.0;
        _indicator.layer.shadowOffset = CGSizeMake(0, -1.0);
        [self addSubview:_indicator];
    }
    return self;
}

- (void)setTitles:(NSArray<NSString *> *)titles {
    _titles = [titles copy];
    for (NSButton *b in _buttons) [b removeFromSuperview];
    [_buttons removeAllObjects];
    for (NSUInteger i = 0; i < titles.count; i++) {
        NSButton *b = [NSButton buttonWithTitle:@"" target:self action:@selector(onTapSegment:)];
        b.tag = (NSInteger)i;
        b.bordered = NO;
        ((NSButtonCell *)b.cell).backgroundColor = [NSColor clearColor];
        [self addSubview:b];
        [_buttons addObject:b];
    }
    [self updateAppearance];
    self.needsLayout = YES;
}

- (void)setSelectedIndex:(NSInteger)i {
    if (_selectedIndex == i) return;
    _selectedIndex = i;
    [self updateAppearance];
    self.needsLayout = YES;
}

- (void)onTapSegment:(NSButton *)sender {
    if (sender.tag == _selectedIndex) return;
    _selectedIndex = sender.tag;
    [self updateAppearance];
    self.needsLayout = YES;
    if (self.onSelect) self.onSelect(_selectedIndex);
}

- (void)updateAppearance {
    for (NSUInteger i = 0; i < _buttons.count; i++) {
        BOOL sel = ((NSInteger)i == _selectedIndex);
        NSFont *f = [NSFont systemFontOfSize:12.5 weight:(sel ? NSFontWeightSemibold : NSFontWeightRegular)];
        NSColor *c = sel ? [Brand charcoal] : [Brand muted];
        _buttons[i].attributedTitle = [[NSAttributedString alloc] initWithString:(_titles[i] ?: @"")
            attributes:@{ NSForegroundColorAttributeName:c, NSFontAttributeName:f }];
    }
}

- (void)layout {
    [super layout];
    self.layer.cornerRadius = NSHeight(self.bounds) / 2.0;

    NSInteger n = (NSInteger)_buttons.count;
    if (n == 0) return;
    CGFloat segW = NSWidth(self.bounds) / n;
    for (NSInteger i = 0; i < n; i++) {
        _buttons[i].frame = NSMakeRect(i * segW, 0, segW, NSHeight(self.bounds));
    }

    CGFloat inset = 3.0;
    NSRect ind = NSMakeRect(_selectedIndex * segW + inset, inset,
                            segW - 2 * inset, NSHeight(self.bounds) - 2 * inset);
    _indicator.layer.cornerRadius = NSHeight(ind) / 2.0;
    // Trượt nhẹ giữa các ô khi đổi tab; tôn trọng "Giảm chuyển động" (cùng ngôn ngữ PillSwitch).
    if (![[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceMotion]) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
            ctx.duration = 0.15;
            _indicator.animator.frame = ind;
        } completionHandler:nil];
    } else {
        _indicator.frame = ind;
    }
}

- (NSAccessibilityRole)accessibilityRole { return NSAccessibilityTabGroupRole; }

@end

#pragma mark - PanelViewController

@implementation PanelViewController {
    // Header — [MINDFUL] Áo mới v2: TRẮNG liền mạch (không còn chrome teal đặc).
    NSView             *_header;
    NSTextField        *_vnPill;      // "VN" — CHỈ báo bộ gõ Việt bật/tắt (nhị phân teal), KHÔNG BAO GIỜ báo cảm xúc
    NSButton           *_gear;        // ⋯ → menu cũ

    MKTabBar           *_tabBar;      // "Hôm nay · Chuông · Bộ gõ"

    // Tab "Hôm nay"
    NSTextField        *_ebNow;       // "NGAY BÂY GIỜ"
    GatekeeperCardView *_gatekeeper;
    NSTextField        *_ebToday;     // "HÔM NAY"
    EmotionRiverView   *_river;
    NSTextField        *_bellLine;    // "Chuông tỉnh thức kế tiếp: còn X phút"

    BellSettingsView    *_bell;
    InputMethodCardView *_input;

    NSView             *_footerDiv;    // đường kẻ mảnh trước chân trang (kiểu Haynoi)
    NSTextField        *_privacy;

    CGFloat             _lastHeight;   // chiều cao nội dung lần reflow gần nhất
}

- (void)loadView {
    MKFlippedView *root = [[MKFlippedView alloc] initWithFrame:NSMakeRect(0, 0, kPanelW, 400)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = [NSColor whiteColor].CGColor;   // nền trắng liền mạch (Haynoi-style)
    self.view = root;

    [self buildHeader];

    __weak PanelViewController *weakSelf = self;

    _tabBar = [[MKTabBar alloc] initWithFrame:NSZeroRect];
    _tabBar.titles = @[@"Hôm nay", @"Chuông", @"Bộ gõ"];
    _tabBar.onSelect = ^(NSInteger index) { (void)index; [weakSelf reflow]; };
    [root addSubview:_tabBar];

    _ebNow = [NSTextField mk_eyebrowLabelWithTitle:@"Ngay bây giờ"];
    [root addSubview:_ebNow];

    _gatekeeper = [[GatekeeperCardView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 96)];
    [root addSubview:_gatekeeper];

    _ebToday = [NSTextField mk_eyebrowLabelWithTitle:@"Hôm nay"];
    [root addSubview:_ebToday];

    // [MINDFUL] Áo mới v2 mục 5 — khung "dòng sông", TRẠNG THÁI TRỐNG (Bước 3 chưa có nguồn dữ
    // liệu thật). KHÔNG gọi setSamples: ở đây — mặc định nil = trống thật thà. Bước 3/4 sẽ đổ dữ
    // liệu thật vào bằng đúng API này, không cần sửa layout.
    _river = [[EmotionRiverView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 100)];
    [root addSubview:_river];

    _bellLine = [NSTextField labelWithString:@""];
    _bellLine.backgroundColor = [NSColor clearColor];
    _bellLine.bordered = NO;
    _bellLine.editable = NO;
    [root addSubview:_bellLine];

    _bell = [[BellSettingsView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 100)];
    _bell.onLayoutChanged = ^{ [weakSelf reflow]; };   // đổi cao khi 1 mục con trong Chuông bung (vd giải thích Focus)
    [root addSubview:_bell];

    _input = [[InputMethodCardView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 48)];
    [_input expandForTabPresentation];
    _input.onOpen = ^{ if (weakSelf.onOpenFullSettings) weakSelf.onOpenFullSettings(); };
    _input.onLayoutChanged = ^{ [weakSelf reflow]; };
    [root addSubview:_input];

    _footerDiv = [[NSView alloc] initWithFrame:NSZeroRect];
    _footerDiv.wantsLayer = YES;
    _footerDiv.layer.backgroundColor = [Brand divider].CGColor;
    [root addSubview:_footerDiv];

    _privacy = [NSTextField labelWithString:@"Xử lý trên máy · không gửi nội dung gõ đi đâu"];
    _privacy.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    _privacy.textColor = [Brand muted];
    _privacy.alignment = NSTextAlignmentCenter;
    _privacy.backgroundColor = [NSColor clearColor];
    _privacy.bordered = NO;
    _privacy.lineBreakMode = NSLineBreakByWordWrapping;
    _privacy.maximumNumberOfLines = 2;
    [root addSubview:_privacy];

    [self refreshAll];
}

- (void)buildHeader {
    // [MINDFUL] Áo mới v2 — header giờ TRẮNG liền mạch với nền panel (khớp mockup-v2-tabbed.html
    // .top), KHÔNG còn chrome teal đặc. "〜" giữ màu teal, "mindful-key" chữ charcoal.
    _header = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kPanelW, kHeaderH)];
    [self.view addSubview:_header];

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:@"〜 "
        attributes:@{ NSForegroundColorAttributeName:[Brand teal],
                      NSFontAttributeName:[NSFont systemFontOfSize:17 weight:NSFontWeightBold] }];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"mindful-key"
        attributes:@{ NSForegroundColorAttributeName:[Brand charcoal],
                      NSFontAttributeName:[NSFont systemFontOfSize:14 weight:NSFontWeightSemibold] }]];
    NSTextField *titleField = [NSTextField labelWithString:@""];
    titleField.attributedStringValue = title;
    titleField.backgroundColor = [NSColor clearColor];
    titleField.bordered = NO;
    [_header addSubview:titleField];
    titleField.frame = NSMakeRect(kMargin, (kHeaderH - 20) / 2.0, 160, 20);

    _gear = [NSButton buttonWithTitle:@"⋯" target:self action:@selector(onGear:)];
    _gear.bordered = NO;
    ((NSButtonCell *)_gear.cell).backgroundColor = [NSColor clearColor];
    _gear.attributedTitle = [[NSAttributedString alloc] initWithString:@"⋯"
        attributes:@{ NSForegroundColorAttributeName:[Brand muted],
                      NSFontAttributeName:[NSFont systemFontOfSize:16 weight:NSFontWeightBold] }];
    [_header addSubview:_gear];
    _gear.frame = NSMakeRect(kPanelW - kMargin - 24, (kHeaderH - 24) / 2.0, 24, 24);

    // [MINDFUL] Áo mới v2 mục 1 — pill "VN": CHỈ báo bộ gõ Việt bật/tắt (nhị phân, 1 màu teal),
    // KHÔNG BAO GIỜ báo cảm xúc. Bật = tô đặc teal + chữ trắng; tắt = viền divider không tô +
    // chữ muted (cùng ngôn ngữ nhị phân với StatusDot — xem BrandControls.h).
    _vnPill = [NSTextField labelWithString:@"VN"];
    _vnPill.alignment = NSTextAlignmentCenter;
    _vnPill.bordered = NO;
    _vnPill.editable = NO;
    _vnPill.drawsBackground = NO;
    _vnPill.wantsLayer = YES;
    [_header addSubview:_vnPill];
}

#pragma mark - Refresh + reflow

- (void)refreshAll {
    [_gatekeeper refresh];
    [_bell refresh];
    [_input refresh];

    BOOL vnOn = ([[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"] == 1);
    [self styleVNPill:vnOn];
    [self updateBellLine];

    [self reflow];
}

// [MINDFUL] Áo mới v2 — xem buildHeader. Nhị phân 1 màu teal: bật = tô đặc, tắt = viền không tô.
- (void)styleVNPill:(BOOL)on {
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName : (on ? [NSColor whiteColor] : [Brand muted]),
        NSFontAttributeName : [NSFont systemFontOfSize:10.5 weight:NSFontWeightSemibold],
        NSKernAttributeName : @(0.3)
    };
    _vnPill.attributedStringValue = [[NSAttributedString alloc] initWithString:@"VN" attributes:attrs];
    if (on) {
        _vnPill.layer.backgroundColor = [Brand teal].CGColor;
        _vnPill.layer.borderWidth = 0;
    } else {
        _vnPill.layer.backgroundColor = [NSColor clearColor].CGColor;
        _vnPill.layer.borderWidth = 1.0;
        _vnPill.layer.borderColor = [Brand divider].CGColor;
    }
}

// [MINDFUL] Áo mới v2 mục 6 — "Chuông tỉnh thức kế tiếp". Đọc lịch chuông THẬT
// (BellMac_MinutesUntilNextRing — timer đang chạy thật, xem BellMac.mm). Chuông tắt hoặc không rõ
// (đang tạm hoãn / chưa có timer) → text thật thà, KHÔNG đếm ngược giả (HIẾN CHƯƠNG §2.2).
- (void)updateBellLine {
    NSDictionary *leadAttrs = @{ NSForegroundColorAttributeName:[Brand muted],
                                 NSFontAttributeName:[NSFont systemFontOfSize:12.5 weight:NSFontWeightRegular] };
    if (!vBell) {
        _bellLine.attributedStringValue = [[NSAttributedString alloc] initWithString:@"Chuông đang tắt" attributes:leadAttrs];
        return;
    }

    int minutes = BellMac_MinutesUntilNextRing();
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc]
        initWithString:@"Chuông tỉnh thức kế tiếp: " attributes:leadAttrs];
    NSString *value = (minutes >= 0) ? [NSString stringWithFormat:@"còn %d phút", minutes] : @"—";
    [s appendAttributedString:[[NSAttributedString alloc] initWithString:value attributes:@{
        NSForegroundColorAttributeName:[Brand charcoal],
        NSFontAttributeName:[NSFont systemFontOfSize:12.5 weight:NSFontWeightSemibold]
    }]];
    _bellLine.attributedStringValue = s;
}

// Header → tab bar → ĐÚNG 1 tab đang chọn → chân trang. Tab "Hôm nay" xếp 2 nhóm eyebrow+thẻ +
// 1 dòng chuông; tab "Chuông"/"Bộ gõ" mỗi tab vẫn đúng 1 view như trước.
- (void)reflow {
    CGFloat y = 0;
    _header.frame = NSMakeRect(0, y, kPanelW, kHeaderH);
    [self layoutHeaderChildren];
    y += kHeaderH;

    y += kTabGapTop;
    _tabBar.frame = NSMakeRect(kMargin, y, kCardW, kTabBarH);
    y += kTabBarH + kTabGapBottom;

    MKPanelTab tab = (MKPanelTab)_tabBar.selectedIndex;
    BOOL isToday = (tab == MKPanelTabToday);
    _ebNow.hidden = !isToday;
    _gatekeeper.hidden = !isToday;
    _ebToday.hidden = !isToday;
    _river.hidden = !isToday;
    _bellLine.hidden = !isToday;
    _bell.hidden  = (tab != MKPanelTabBell);
    _input.hidden = (tab != MKPanelTabInput);

    if (isToday) {
        _ebNow.frame = NSMakeRect(kMargin, y, kCardW, kEbH);
        y += kEbH + kEbGap;

        CGFloat gkH = [_gatekeeper preferredHeight];
        _gatekeeper.frame = NSMakeRect(kMargin, y, kCardW, gkH);
        y += gkH + kSectionGap;

        _ebToday.frame = NSMakeRect(kMargin, y, kCardW, kEbH);
        y += kEbH + kEbGap;

        CGFloat riverH = [_river preferredHeight];
        _river.frame = NSMakeRect(kMargin, y, kCardW, riverH);
        y += riverH + kSectionGap;

        _bellLine.frame = NSMakeRect(kMargin, y, kCardW, kBellLineH);
        y += kBellLineH;
    } else if (tab == MKPanelTabBell) {
        CGFloat contentH = [_bell preferredHeight];
        _bell.frame = NSMakeRect(kMargin, y, kCardW, contentH);
        y += contentH;
    } else {
        CGFloat contentH = [_input preferredHeight];
        _input.frame = NSMakeRect(kMargin, y, kCardW, contentH);
        y += contentH;
    }

    _footerDiv.frame = NSMakeRect(0, y, kPanelW, 1.0);  y += 1.0;
    y += 10.0;
    _privacy.frame = NSMakeRect(kMargin, y, kCardW, kFooterH);  y += kFooterH + 12.0;

    _lastHeight = y;
    NSRect rf = self.view.frame; rf.size = NSMakeSize(kPanelW, y); self.view.frame = rf;
    self.preferredContentSize = NSMakeSize(kPanelW, y);   // NSPopover theo dõi để đổi kích thước
}

- (void)layoutHeaderChildren {
    CGFloat pillH = 18.0, pillW = 30.0;
    CGFloat gearX = kPanelW - kMargin - 24;
    _vnPill.frame = NSMakeRect(gearX - 8.0 - pillW, (kHeaderH - pillH) / 2.0, pillW, pillH);
    _vnPill.layer.cornerRadius = pillH / 2.0;
}

- (NSSize)panelContentSize { return NSMakeSize(kPanelW, _lastHeight); }

- (void)onGear:(id)sender {
    if (self.onShowMenu) self.onShowMenu(_gear);
}

@end
