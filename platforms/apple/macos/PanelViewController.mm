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
#import "MoodStoreMac.h"

// [MINDFUL] 2026-07-16 — `g_checkinLastTime`/`g_checkinTimer` đã XOÁ: khung chấm nhịp không còn tự
// đếm giờ, nó lắng nghe nhịp chung của BellMac (kMKMoodBeatNotification). Xem mk_startCheckinTimerIfNeeded.
// Còn lại đúng 1 đồng hồ, và nó chỉ lo dòng đếm ngược hiển thị — không phải nhịp của app.
static dispatch_source_t g_bellLineTimer = nil;

// [MINDFUL] Chấm nhịp v2 (2026-07-16) — khung check-in giờ ở lại tới khi người dùng CHỌN hoặc
// BỎ QUA (bỏ tự-đóng-sau-8-giây). Phải giữ tham chiếu để: (a) không dựng chồng nhiều khung khi
// rời máy lâu — nhịp sau tới thì thay khung cũ, không xếp đống; (b) đóng đúng khung đang hiện.
static NSPanel *g_checkinPanel = nil;

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
    SensitivityCardView *_sensitivityCard;
    NSTextField        *_ebToday;     // "HÔM NAY"
    EmotionRiverView   *_river;
    NSTextField        *_bellLine;    // "Chuông tỉnh thức kế tiếp: còn X phút"

    BellSettingsView    *_bell;
    InputMethodCardView *_input;

    NSView             *_footerDiv;    // đường kẻ mảnh trước chân trang (kiểu Haynoi)
    NSTextField        *_privacy;

    NSScrollView       *_contentScrollView;
    MKFlippedView      *_contentDocumentView;

    CGFloat             _lastHeight;   // chiều cao nội dung lần reflow gần nhất
}

// [MINDFUL] Epic 3 Chặng 1 (F12) — timer check-in trước đây dựng bên trong -loadView, nên CHỈ
// tồn tại nếu người dùng đã bấm-trái icon 〜 mở popover ít nhất 1 lần trong phiên chạy app đó
// (NSViewController nạp -view lười biếng, chỉ khi contentViewController thật sự cần hiện —
// AppDelegate chỉ gán `_panelPopover.contentViewController = _panelVC`, không ép .view load).
// Với ai chạy app cả ngày mà không đụng icon, "check-in 3 sóng" — 1 trong 3 chân kiềng dữ liệu
// đã chốt 2026-07-13 — chưa từng tồn tại, không phải im lặng vì không có gì để hỏi.
// Đây là timer LỊCH TRÌNH (model), không phải mối bận tâm của VIEW, nên chuyển sang -init: chạy
// đúng 1 lần ngay lúc AppDelegate tạo _panelVC (applicationDidFinishLaunching), không phụ thuộc
// việc popover có được mở hay không. showCheckinOverlay tự dựng NSPanel riêng (không cần self.view);
// updateBellLine ghi vào _bellLine — nil an toàn (no-op) nếu view chưa nạp, không crash.
- (instancetype)init {
    if ((self = [super init])) {
        [self mk_startCheckinTimerIfNeeded];
    }
    return self;
}

- (void)mk_startCheckinTimerIfNeeded {
    // [MINDFUL] 2026-07-16 — TỪNG tự đếm giờ ở đây (dispatch_source 60s, tự cộng dồn tới đủ
    // vBellInterval, mốc bắt đầu = lúc _panelVC được tạo). Chuông đếm từ mốc khác, nhật ký đếm từ
    // mốc khác nữa → BA đồng hồ trôi lệch nhau, trong khi màn Chuông hứa "Một nhịp, hai vai".
    // Nay khung chấm nhịp LẮNG NGHE nhịp chung do BellMac điểm.
    [[NSNotificationCenter defaultCenter] addObserverForName:kMKMoodBeatNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        [self showCheckinOverlay];   // tự bỏ qua nếu chưa có consent
    }];

    // Đồng hồ 60 giây VẪN CÒN, nhưng nay chỉ còn ĐÚNG MỘT việc: cập nhật dòng đếm ngược "chuông kế
    // tiếp: còn N phút" trong popover. Đây là nhịp HIỂN THỊ (phải đập từng phút thì số mới trôi),
    // KHÔNG phải nhịp của app — nên nó không thuộc diện "3 đồng hồ trôi lệch" vừa gộp. Gộp nốt nó
    // vào nhịp 15 phút sẽ làm số đếm ngược đứng hình 15 phút một lần.
    if (g_bellLineTimer != nil) return;
    g_bellLineTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(g_bellLineTimer, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), 60 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(g_bellLineTimer, ^{
        [self updateBellLine];
    });
    dispatch_resume(g_bellLineTimer);
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

    // Khởi tạo ScrollView chứa nội dung động
    _contentScrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    _contentScrollView.hasVerticalScroller = YES;
    _contentScrollView.hasHorizontalScroller = NO;
    _contentScrollView.drawsBackground = NO;
    [root addSubview:_contentScrollView];

    _contentDocumentView = [[MKFlippedView alloc] initWithFrame:NSZeroRect];
    _contentDocumentView.wantsLayer = YES;
    _contentDocumentView.layer.backgroundColor = [NSColor clearColor].CGColor;
    _contentScrollView.documentView = _contentDocumentView;

    _ebNow = [NSTextField mk_eyebrowLabelWithTitle:@"Ngay bây giờ"];
    [_contentDocumentView addSubview:_ebNow];

    _gatekeeper = [[GatekeeperCardView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 96)];
    [_contentDocumentView addSubview:_gatekeeper];

    _sensitivityCard = [[SensitivityCardView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 100)];
    [_contentDocumentView addSubview:_sensitivityCard];

    _ebToday = [NSTextField mk_eyebrowLabelWithTitle:@"Hôm nay"];
    [_contentDocumentView addSubview:_ebToday];

    // [MINDFUL] Áo mới v2 mục 5 — khung "dòng sông", TRẠNG THÁI TRỐNG (Bước 3 chưa có nguồn dữ
    // liệu thật). KHÔNG gọi setSamples: ở đây — mặc định nil = trống thật thà. Bước 3/4 sẽ đổ dữ
    // liệu thật vào bằng đúng API này, không cần sửa layout.
    _river = [[EmotionRiverView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 100)];
    [_contentDocumentView addSubview:_river];

    _bellLine = [NSTextField labelWithString:@""];
    _bellLine.backgroundColor = [NSColor clearColor];
    _bellLine.bordered = NO;
    _bellLine.editable = NO;
    [_contentDocumentView addSubview:_bellLine];

    _bell = [[BellSettingsView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 100)];
    _bell.onLayoutChanged = ^{ [weakSelf reflow]; };   // đổi cao khi 1 mục con trong Chuông bung (vd giải thích Focus)
    [_contentDocumentView addSubview:_bell];

    _input = [[InputMethodCardView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 48)];
    [_input expandForTabPresentation];
    _input.onOpen = ^{ if (weakSelf.onOpenFullSettings) weakSelf.onOpenFullSettings(); };
    _input.onLayoutChanged = ^{ [weakSelf reflow]; };
    [_contentDocumentView addSubview:_input];

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshAll)
                                                 name:@"InputMethodChangedNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshAll)
                                                 name:@"BellStateChangedNotification"
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showCheckinOverlay {
    if (!MoodStoreMac_HasConsent()) return;

    // [MINDFUL] Chấm nhịp v2 — khung ở lại tới khi chọn/bỏ qua, nên nhịp sau tới mà khung cũ còn
    // đó thì THAY, không xếp chồng (rời máy 2 tiếng = 8 khung đè nhau). Khung cũ tự tan đúng lúc
    // nhịp mới tới → thời hạn buông tay bám nhịp lấy mẫu, không phải một con số hết-giờ tuỳ tiện.
    if (g_checkinPanel) {
        [g_checkinPanel close];
        g_checkinPanel = nil;
    }

    NSRect screenRect = [NSScreen mainScreen].visibleFrame;
    CGFloat w = 320;
    CGFloat h = 116;   // +26 so với bản cũ: chừa hàng "Bỏ qua" bên dưới 3 lựa chọn
    NSRect frame = NSMakeRect(screenRect.origin.x + screenRect.size.width - w - 20,
                              screenRect.origin.y + screenRect.size.height - h - 40,
                              w, h);

    NSPanel *panel = [[NSPanel alloc] initWithContentRect:frame
                                                styleMask:(NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel)
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    panel.level = NSStatusWindowLevel;
    panel.backgroundColor = [NSColor clearColor];
    panel.hasShadow = NO;
    panel.opaque = NO;
    // [MINDFUL] NSPanel mặc định hidesOnDeactivate = YES. Bản cũ tự đóng sau 8 giây nên không ai
    // thấy hệ quả; nay khung phải sống tới khi người dùng chạm, mà người dùng thì LUÔN đang gõ ở
    // app khác (đây là bộ gõ) — để mặc định thì khung lặng lẽ biến mất, phá đúng thứ vừa chốt.
    // Tắt hẳn, cùng cách SendGatekeeperMac.mm đã làm cho overlay nhịp thở.
    panel.hidesOnDeactivate = NO;

    NSVisualEffectView *vev = [[NSVisualEffectView alloc] initWithFrame:panel.contentView.bounds];
    vev.material = NSVisualEffectMaterialPopover;
    vev.state = NSVisualEffectStateActive;
    vev.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    vev.wantsLayer = YES;
    vev.layer.cornerRadius = 12.0;
    vev.layer.masksToBounds = YES;
    panel.contentView = vev;

    NSTextField *label = [NSTextField labelWithString:@"Mặt hồ đang thế nào?"];
    label.font = [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];
    label.textColor = [Brand charcoal];
    label.frame = NSMakeRect(20, h - 35, w - 40, 20);
    [vev addSubview:label];

    NSArray *titles = @[@"Phẳng lặng", @"Gợn nhẹ", @"Gợn sóng"];
    CGFloat btnW = (w - 40 - 20) / 3.0;
    for (int i = 0; i < 3; i++) {
        NSButton *btn = [NSButton buttonWithTitle:titles[i] target:self action:@selector(onCheckin:)];
        btn.tag = i + 1; // 1, 2, 3
        btn.frame = NSMakeRect(20 + i * (btnW + 10), 41, btnW, 30);
        btn.bezelStyle = NSBezelStyleRounded;
        [vev addSubview:btn];
    }

    // [MINDFUL] Chấm nhịp v2 — "Bỏ qua" LÀ điều kiện để khung được phép ở lại. Có nó thì khung nằm
    // chờ = tôn trọng (không biến mất lúc người ta đang nghĩ); không có nó thì khung nằm chờ = cái
    // bẫy, cứ mỗi nhịp lại chặn người dùng, không đáp không cho đi — đúng thứ HIẾN CHƯƠNG gọi là
    // hối thúc. Câu chữ lấy nguyên artifact "Vòng Soi lại" đã duyệt (.skip): bỏ qua KHÔNG mất nhịp,
    // app vẫn tự ghi điểm — nói rõ để người dùng không thấy có lỗi khi im lặng.
    // Link mờ tông đá, KHÔNG phải nút CTA: đây là lối thoát, không phải lời mời chào.
    NSButton *skip = [NSButton buttonWithTitle:@"" target:self action:@selector(onCheckinSkip:)];
    skip.bordered = NO;
    skip.bezelStyle = NSBezelStyleInline;
    [(NSButtonCell *)skip.cell setBackgroundColor:[NSColor clearColor]];
    skip.attributedTitle = [[NSAttributedString alloc] initWithString:@"Bỏ qua — app vẫn tự ghi nhịp này"
        attributes:@{ NSForegroundColorAttributeName: [Brand stone],
                      NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular] }];
    skip.frame = NSMakeRect(20, 12, w - 40, 20);
    [vev addSubview:skip];

    [panel orderFront:nil];
    g_checkinPanel = panel;   // KHÔNG còn tự đóng theo giờ — chỉ đóng khi người dùng chạm, hoặc khi nhịp sau tới

    // [MINDFUL] 2026-07-16 (chủ dự án chốt) — khung này trước đây hiện HOÀN TOÀN IM, dễ trôi qua
    // không ai thấy. Nay báo bằng "Chuông gió" nhỏ — tiếng CỐ ĐỊNH, khác hẳn tiếng chuông tỉnh thức
    // người dùng chọn, để nghe ra ngay đây là việc khác: mời ghi nhận cảm xúc, không phải nhắc nghỉ.
    // Hàm tự bỏ qua nếu chuông đang tắt / tạm hoãn / ngoài giờ chuông / "Im" / âm lượng 0.
    BellMac_PlayCheckinChime();
}

- (void)mk_closeCheckinPanel {
    if (g_checkinPanel) {
        [g_checkinPanel close];
        g_checkinPanel = nil;
    }
}

- (void)onCheckin:(NSButton *)sender {
    MoodStoreMac_LogCheckinEvent(sender.tag);
    [self mk_closeCheckinPanel];
}

// [MINDFUL] Bỏ qua = KHÔNG ghi checkin (nhịp lấy mẫu tự động vẫn chạy riêng ở MoodWatchMac —
// đúng như câu chữ đã hứa với người dùng). Chỉ đóng, không log, không đếm, không nhắc lại.
- (void)onCheckinSkip:(NSButton *)sender {
    [self mk_closeCheckinPanel];
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
    [_sensitivityCard refresh];
    [_bell refresh];
    [_input refresh];

    BOOL vnOn = ([[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"] == 1);
    [self styleVNPill:vnOn];
    [self updateBellLine];

    // [MINDFUL] Cập nhật dòng sông
    extern int vBellInterval;
    int intervalMins = vBellInterval > 0 ? vBellInterval : 60;
    // [MINDFUL] Vá trục thời gian (2026-07-16) — đưa thẳng mẫu KÈM timestamp xuống sông để chấm
    // nằm đúng giờ. Bản cũ tự chép một vòng lặp gom NSNull rồi VỨT ts đi, nên sông chỉ còn biết
    // thứ tự: 7 mẫu buổi sáng bị giãn ra thành trọn một ngày, chấm 10h08 rơi xuống dưới "Tối".
    NSArray<NSDictionary *> *raw = MoodStoreMac_FetchTodaySamples();
    [_river setTodaySamples:raw.count > 0 ? raw : nil gapSeconds:intervalMins * 60.0 * 1.5];

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
    NSDate *nextDate = BellMac_NextRingDate();
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc]
        initWithString:@"Chuông tỉnh thức kế tiếp: " attributes:leadAttrs];
    NSString *value = @"—";
    if (minutes >= 0 && nextDate != nil) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"HH:mm";
        NSString *timeStr = [df stringFromDate:nextDate];
        value = [NSString stringWithFormat:@"lúc %@ (còn %d phút)", timeStr, minutes];
    }
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

    CGFloat contentStartY = y;

    MKPanelTab tab = (MKPanelTab)_tabBar.selectedIndex;
    BOOL isToday = (tab == MKPanelTabToday);
    _ebNow.hidden = !isToday;
    _gatekeeper.hidden = !isToday;
    _sensitivityCard.hidden = !isToday;
    _ebToday.hidden = !isToday;
    _river.hidden = !isToday;
    _bellLine.hidden = !isToday;
    _bell.hidden  = (tab != MKPanelTabBell);
    _input.hidden = (tab != MKPanelTabInput);

    CGFloat contentH = 0;
    if (isToday) {
        CGFloat cy = 0;
        _ebNow.frame = NSMakeRect(kMargin, cy, kCardW, kEbH);
        cy += kEbH + kEbGap;

        CGFloat gkH = [_gatekeeper preferredHeight];
        _gatekeeper.frame = NSMakeRect(kMargin, cy, kCardW, gkH);
        cy += gkH + kSectionGap;

        CGFloat sensH = [_sensitivityCard preferredHeight];
        _sensitivityCard.frame = NSMakeRect(kMargin, cy, kCardW, sensH);
        cy += sensH + kSectionGap;

        _ebToday.frame = NSMakeRect(kMargin, cy, kCardW, kEbH);
        cy += kEbH + kEbGap;

        CGFloat riverH = [_river preferredHeight];
        _river.frame = NSMakeRect(kMargin, cy, kCardW, riverH);
        cy += riverH + kSectionGap;

        _bellLine.frame = NSMakeRect(kMargin, cy, kCardW, kBellLineH);
        cy += kBellLineH;

        contentH = cy;
    } else if (tab == MKPanelTabBell) {
        contentH = [_bell preferredHeight];
        _bell.frame = NSMakeRect(kMargin, 0, kCardW, contentH);
    } else {
        contentH = [_input preferredHeight];
        _input.frame = NSMakeRect(kMargin, 0, kCardW, contentH);
    }

    _contentDocumentView.frame = NSMakeRect(0, 0, kPanelW, contentH);

    // [MINDFUL] 2026-07-16 — trần này TỪNG là số cứng 430, nhỏ hơn màn hình thật rất nhiều: tab
    // "Hôm nay" bị cắt ngang GIỮA một dòng chữ ở đáy (ảnh chủ dự án). Nội dung không mất — vùng này
    // vốn cuộn được — nhưng macOS ẩn thanh cuộn khi không kéo, nên nửa dòng chữ cụt đọc ra "app
    // lỗi", không đọc ra "còn nữa, cuộn xuống". Thẻ "Ngay bây giờ" nay là sông 6 tiếng (cao hơn ~50pt)
    // càng làm nó tệ. Nay đo theo MÀN HÌNH THẬT: chỉ cuộn khi thực sự không vừa.
    //   contentStartY = đã gồm header + tab bar. Cộng nốt chân trang + đệm/mũi tên popover.
    CGFloat chromeH = contentStartY + 1.0 + 10.0 + kFooterH + 12.0 + 28.0;
    // [MINDFUL] 2026-07-16 — đo theo MÀN HÌNH POPOVER ĐANG HIỆN, không phải mainScreen.
    // mainScreen = màn có cửa sổ key (có thể là màn khác, hoặc không có cửa sổ nào key); khi nó
    // cao hơn màn thật chứa icon menu bar, trần tính dư → popover không cuộn → tràn quá màn, macOS
    // đẩy phần đầu (tiêu đề + tab) lòi khỏi mép trên. self.view.window = cửa sổ popover sau khi show.
    NSScreen *popoverScreen = self.view.window.screen;
    if (!popoverScreen) {
        NSPoint mouseLoc = [NSEvent mouseLocation];
        for (NSScreen *screen in [NSScreen screens]) {
            if (NSMouseInRect(mouseLoc, screen.frame, NO)) {
                popoverScreen = screen;
                break;
            }
        }
    }
    if (!popoverScreen) popoverScreen = [NSScreen mainScreen];
    CGFloat screenH = popoverScreen.visibleFrame.size.height;
    CGFloat maxContentH = MAX(200.0, screenH - chromeH - 80.0);
    CGFloat scrollH = MIN(contentH, maxContentH);

    _contentScrollView.frame = NSMakeRect(0, contentStartY, kPanelW, scrollH);
    y = contentStartY + scrollH;

    _footerDiv.frame = NSMakeRect(0, y, kPanelW, 1.0);  y += 1.0;
    y += 10.0;
    _privacy.frame = NSMakeRect(kMargin, y, kCardW, kFooterH);  y += kFooterH + 12.0;

    _lastHeight = y;
    self.preferredContentSize = NSMakeSize(kPanelW, y);   // NSPopover theo dõi để đổi kích thước
}

- (void)layoutHeaderChildren {
    CGFloat pillH = 18.0, pillW = 30.0;
    CGFloat gearX = kPanelW - kMargin - 24;
    _vnPill.frame = NSMakeRect(gearX - 8.0 - pillW, (kHeaderH - pillH) / 2.0, pillW, pillH);
    _vnPill.layer.cornerRadius = pillH / 2.0;
}

- (NSSize)panelContentSize { return NSMakeSize(kPanelW, _lastHeight); }

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    if (self.isRecordingHotkey && self.onHotkeyRecorded) {
        self.onHotkeyRecorded(event);
        return YES;
    }
    return [super performKeyEquivalent:event];
}

- (void)onGear:(id)sender {
    if (self.onShowMenu) self.onShowMenu(_gear);
}

@end
