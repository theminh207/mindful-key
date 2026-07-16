//
//  SettingsWindowController.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 2.2 — xem SettingsWindowController.h cho tổng quan.
//
//  KỸ THUẬT NHÚNG (chưa có tiền lệ trong codebase trước story này):
//   - "Bộ gõ ▸ Kiểu gõ" và "Hệ thống": instantiate `ViewController` ĐÚNG 1 LẦN qua storyboard
//     identifier bare-VC "OpenKeyPanel" (KHÔNG qua window-controller "OpenKey"), ép `-view` chạy
//     để `-viewDidLoad` thực thi xong (box đã là live object, đã có card style + shadowPath —
//     `applyBrandCardStyle` tính shadowPath theo `self.bounds`, KHÔNG theo vị trí trong superview,
//     nên reparent xong bóng đổ vẫn đúng MIỄN LÀ không đổi kích thước box, xem BrandControls.m).
//     Sau đó `removeFromSuperview` 2 NSBox `tabviewPrimary`/`tabviewSystem` khỏi `viewParent` gốc,
//     giữ nguyên KÍCH THƯỚC (chỉ reset origin) — target/action bên trong box vẫn hoạt động vì
//     target là chính `ViewController` instance (giữ sống bằng strong ivar).
//   - "Bộ gõ ▸ Gõ tắt"/"Chuyển mã"/"Giới thiệu": KHÔNG có storyboard identifier riêng cho content
//     VC, chỉ window-controller cha có ("MacroWindow"/"ConvertWindow"/"AboutWindow"). Instantiate
//     window-controller, đọc `.window` một lần để ép nib nạp (KHÔNG bao giờ gọi
//     makeKeyAndOrderFront:/show — wrapper window không bao giờ hiện), rồi lấy `.contentViewController`
//     giữ strong ivar. `.view` của các VC này được nhúng thẳng (không phải subview con của nó).
//   - Cả 4 VC được add làm child qua `-addChildViewController:` của 1 root NSViewController ẩn
//     (`_rootVC`, chính là `window.contentViewController`) — đúng API containment AppKit, dù các
//     view con không phải lúc nào cũng nằm trong `_rootVC.view` (tabviewPrimary/tabviewSystem di
//     chuyển qua lại giữa "chưa hiện" và "đang hiện trong paneHost" tuỳ mục nav đang chọn).
//
//  KHÔNG sửa 1 dòng trong ViewController.h/.m, MacroViewController.h/.mm,
//  ConvertToolViewController.h/.mm, AboutViewController.h/.m.
//

#import "SettingsWindowController.h"
#import "ViewController.h"
#import "MacroViewController.h"
#import "ConvertToolViewController.h"
#import "AboutViewController.h"
#import "BrandColors.h"
#import "EmotionRiverView.h"
#import "GatekeeperCardView.h"
#import "PrivacyPaneView.h"
#import "MoodStoreMac.h"
#import "BellSettingsView.h"
#import "SystemSettingsView.h"

// [MINDFUL] `ConvertToolViewController -fillData` tồn tại thật (ConvertToolViewController.mm:64)
// nhưng là method PRIVATE (không khai trong .h) — forward-declare tại đây (KHÔNG sửa
// ConvertToolViewController.h, không thuộc phạm vi sở hữu của story này) để gọi lại refresh mỗi
// khi pane "Chuyển mã" được chọn/mở lại, tránh hiện giá trị cũ từ lúc viewDidLoad.
@interface ConvertToolViewController (MKSettingsRefresh)
- (void)fillData;
@end

#pragma mark - Hằng số layout (điểm) — xem Dev Notes story 2.2 cho nguồn số đo.

static const CGFloat kNavW        = 170.0;   // cột nav trái
static const CGFloat kDividerW    = 1.0;
static const CGFloat kContentPad  = 20.0;    // lề trong của cột nội dung
static const CGFloat kMaxPaneW    = 600.0;   // pane rộng nhất tái dùng (MacroViewController)
static const CGFloat kMaxPaneH    = 472.0;   // pane cao nhất tái dùng (MacroViewController)
static const CGFloat kSubNavH     = 30.0;    // thanh chuyển "Kiểu gõ/Gõ tắt/Chuyển mã"
static const CGFloat kSubNavGap   = 12.0;

static const CGFloat kContentW    = kContentPad * 2 + kMaxPaneW;
static const CGFloat kContentH    = kContentPad * 2 + kSubNavH + kSubNavGap + kMaxPaneH;
static const CGFloat kWindowW     = kNavW + kDividerW + kContentW;
static const CGFloat kWindowH     = kContentH;

static const CGFloat kNavRowH     = 36.0;
static const CGFloat kNavTopPad   = 20.0;

// [MINDFUL] Story 3.5 — pane "Hôm nay": khoảng cách giữa tiêu đề/card/sông, theo lưới 8px
// (DESIGN.md §1.4: 4·8·12·16·24·32). 40.0 khớp đúng quy ước "title reserve" Bell/Privacy đã
// dùng trong file này (mk_instantiateEmbeddedViewControllers, dòng ~322-328).
static const CGFloat kTodayTitleReserve = 40.0;
static const CGFloat kTodaySectionGap   = 16.0;
static const CGFloat kTodayRiverH       = 140.0;
static const CGFloat kDateRangeSegH     = 28.0;   // [MINDFUL] Story 3.7/3.8 — "Ngày/Tuần/Tháng"

typedef NS_ENUM(NSInteger, MKSettingsSection) {
    MKSettingsSectionToday    = 0,
    MKSettingsSectionBell     = 1,
    MKSettingsSectionInput    = 2,
    MKSettingsSectionPrivacy  = 3,
    MKSettingsSectionSystem   = 4,
    MKSettingsSectionAbout    = 5,
};

#pragma mark - MKSettingsNavRow (1 hàng nav trái: chấm 6px + nhãn 12.5px)

@interface MKSettingsNavRow : NSView
@property (nonatomic, copy, nullable) void (^onTap)(void);
- (instancetype)initWithFrame:(NSRect)frameRect title:(NSString *)title;
- (void)setSelectedRow:(BOOL)selected;
@end

@implementation MKSettingsNavRow {
    NSView *_dot;
    NSTextField *_label;
    BOOL _selected;
}

- (instancetype)initWithFrame:(NSRect)frameRect title:(NSString *)title {
    if ((self = [super initWithFrame:frameRect])) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = 8.0;

        CGFloat h = NSHeight(frameRect);

        _dot = [[NSView alloc] initWithFrame:NSMakeRect(12.0, (h - 6.0) / 2.0, 6.0, 6.0)];
        _dot.wantsLayer = YES;
        _dot.layer.cornerRadius = 3.0;
        [self addSubview:_dot];

        _label = [NSTextField labelWithString:title];
        _label.font = [NSFont systemFontOfSize:12.5 weight:NSFontWeightRegular];
        [_label sizeToFit];
        NSRect lf = _label.frame;
        lf.origin = NSMakePoint(28.0, (h - NSHeight(lf)) / 2.0);
        _label.frame = lf;
        [self addSubview:_label];

        // Overlay bấm-toàn-hàng trong suốt — cùng idiom với InputMethodCardView/GatekeeperCardView
        // (NSButton title rỗng làm hit-area thay vì tự bắt mouseDown:).
        NSButton *hit = [NSButton buttonWithTitle:@"" target:self action:@selector(mk_onTap:)];
        hit.bordered = NO;
        ((NSButtonCell *)hit.cell).backgroundColor = [NSColor clearColor];
        hit.frame = self.bounds;
        hit.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:hit];

        [self mk_applyStyle];
    }
    return self;
}

- (void)mk_onTap:(id)sender {
    if (self.onTap) self.onTap();
}

- (void)setSelectedRow:(BOOL)selected {
    if (_selected == selected) return;
    _selected = selected;
    [self mk_applyStyle];
}

- (void)mk_applyStyle {
    self.layer.backgroundColor = _selected ? [Brand tealLight].CGColor : [NSColor clearColor].CGColor;
    _dot.layer.backgroundColor = _selected ? [Brand teal].CGColor : [Brand stone].CGColor;
    _label.textColor = _selected ? [Brand teal] : [Brand charcoal];
}

@end

#pragma mark - MKDateRangeSeg (Story 3.7/3.8 — "Ngày / Tuần / Tháng")

// [MINDFUL] Story 3.7 — segmented control riêng cho SettingsWindowController.mm, KHÔNG tái dùng
// `MKSegmented` (nội bộ BellSettingsView.mm) — file đó đang có thay đổi chưa ổn định từ 1 phiên
// song song (xem docs/TEST_MATRIX.md 2026-07-15 mục F16), tránh đụng vào tránh xung đột merge.
// Cùng ngôn ngữ hình ảnh: pill teal cho mục đang chọn, chữ trắng; các mục khác chữ muted.
@interface MKDateRangeSeg : NSControl
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation MKDateRangeSeg

- (instancetype)initWithFrame:(NSRect)f {
    if ((self = [super initWithFrame:f])) { _selectedIndex = 0; self.wantsLayer = YES; }
    return self;
}
- (void)setTitles:(NSArray<NSString *> *)t { _titles = [t copy]; [self setNeedsDisplay:YES]; }
- (void)setSelectedIndex:(NSInteger)i { if (_selectedIndex == i) return; _selectedIndex = i; [self setNeedsDisplay:YES]; }

- (void)mouseDown:(NSEvent *)e {
    NSInteger n = (NSInteger)self.titles.count;
    if (n == 0) return;
    NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];
    NSInteger idx = (NSInteger)(p.x / (NSWidth(self.bounds) / n));
    if (idx < 0) idx = 0;
    if (idx >= n) idx = n - 1;
    if (idx != _selectedIndex) {
        _selectedIndex = idx;
        [self setNeedsDisplay:YES];
        [self sendAction:self.action to:self.target];
    }
}

- (void)drawRect:(NSRect)dirty {
    NSRect b = self.bounds;
    CGFloat rad = NSHeight(b) / 2.0;
    [[Brand softWhite] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:b xRadius:rad yRadius:rad] fill];

    NSInteger n = (NSInteger)self.titles.count;
    if (n == 0) return;
    CGFloat segW = NSWidth(b) / n;
    CGFloat inset = 3.0;
    NSFont *font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
    for (NSInteger i = 0; i < n; i++) {
        BOOL sel = (i == _selectedIndex);
        NSColor *tc = [Brand muted];
        if (sel) {
            NSRect seg = NSMakeRect(i * segW + inset, inset, segW - 2 * inset, NSHeight(b) - 2 * inset);
            CGFloat sr = NSHeight(seg) / 2.0;
            [[Brand teal] setFill];
            [[NSBezierPath bezierPathWithRoundedRect:seg xRadius:sr yRadius:sr] fill];
            tc = [NSColor whiteColor];
        }
        NSDictionary *attrs = @{ NSForegroundColorAttributeName:tc, NSFontAttributeName:font };
        NSAttributedString *s = [[NSAttributedString alloc] initWithString:self.titles[i] attributes:attrs];
        NSSize sz = [s size];
        NSRect full = NSMakeRect(i * segW, 0, segW, NSHeight(b));
        [s drawAtPoint:NSMakePoint(NSMidX(full) - sz.width / 2.0, NSMidY(full) - sz.height / 2.0)];
    }
}

- (NSAccessibilityRole)accessibilityRole { return NSAccessibilityRadioGroupRole; }

@end

#pragma mark - SettingsWindowController

@implementation SettingsWindowController {
    NSViewController *_rootVC;               // window.contentViewController — chỉ là điểm neo containment
    NSView *_navContainer;
    NSView *_contentContainer;
    NSScrollView *_paneScroll;                // [MINDFUL] Epic 3 G1 (F5) — khung nhìn cuộn bọc _paneHost
    NSView *_paneHost;                        // documentView của _paneScroll; hiện ĐÚNG 1 pane tại 1 thời điểm
    NSView *_subNavBar;                       // 3 nút "Kiểu gõ/Gõ tắt/Chuyển mã", chỉ hiện ở mục "Bộ gõ"
    NSMutableArray<MKSettingsNavRow *> *_navRows;
    NSMutableArray<NSButton *> *_subNavButtons;

    NSView *_paneToday;
    GatekeeperCardView *_gatekeeperCard;       // [MINDFUL] Story 3.5 — Feature #1, luôn trên cùng
    MKDateRangeSeg *_dateRangeSeg;             // [MINDFUL] Story 3.7/3.8 — "Ngày / Tuần / Tháng"
    EmotionRiverView *_settingsRiver;
    NSView *_paneBell;
    NSView *_panePrivacy;
    NSView *_paneSystem;

    ViewController *_openKeyVC;               // strong — giữ sống dù .view gốc không bao giờ show
    MacroViewController *_macroVC;
    ConvertToolViewController *_convertVC;
    AboutViewController *_aboutVC;

    NSInteger _selectedIndex;
    NSInteger _boGoSubIndex;                  // 0=Kiểu gõ, 1=Gõ tắt, 2=Chuyển mã
}

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, kWindowW, kWindowH);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                     styleMask:(NSWindowStyleMaskTitled |
                                                                NSWindowStyleMaskClosable |
                                                                NSWindowStyleMaskMiniaturizable)
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
    window.title = @"Cài đặt Mindful Keyboard";
    // KHÔNG để mặc định YES (window tạo bằng code) — mọi cửa sổ storyboard khác trong app này đều
    // releasedWhenClosed=NO để đóng-rồi-mở-lại không mất state; giữ nhất quán.
    window.releasedWhenClosed = NO;
    [window center];

    self = [super initWithWindow:window];
    if (self) {
        _boGoSubIndex = 0;
        [self mk_buildContent];
    }
    return self;
}

- (void)showWindow:(nullable id)sender {
    [super showWindow:sender];
    // Cửa sổ vừa mở (có thể đang mở lại sau khi đóng) — refresh đúng mục đang chọn để không hiện
    // giá trị cũ nếu setting bị đổi từ nơi khác (vd tray menu) trong lúc cửa sổ đóng.
    [self selectSectionAtIndex:_selectedIndex];
}

#pragma mark - Build UI (1 lần trong -init)

- (void)mk_buildContent {
    _rootVC = [[NSViewController alloc] init];
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowW, kWindowH)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = [NSColor whiteColor].CGColor;
    _rootVC.view = root;

    _navContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kNavW, kWindowH)];
    _navContainer.wantsLayer = YES;
    _navContainer.layer.backgroundColor = [Brand softWhite].CGColor;
    [root addSubview:_navContainer];

    NSView *divider = [[NSView alloc] initWithFrame:NSMakeRect(kNavW, 0, kDividerW, kWindowH)];
    divider.wantsLayer = YES;
    divider.layer.backgroundColor = [Brand divider].CGColor;
    [root addSubview:divider];

    _contentContainer = [[NSView alloc] initWithFrame:NSMakeRect(kNavW + kDividerW, 0, kContentW, kWindowH)];
    [root addSubview:_contentContainer];

    [self mk_buildNavRows];
    [self mk_buildBoGoSubNav];

    // [MINDFUL] Epic 3 G1 (F5) — trước đây `_paneHost` là NSView phẳng cắm thẳng vào
    // `_contentContainer`, cao ĐÓNG CỨNG kMaxPaneH: pane nào cao hơn thì phần dưới bị cắt mất,
    // không có đường xuống (nghiệm thu 2026-07-15 thấy "Chuông" cụt ở Âm lượng, "Riêng tư" cụt
    // giữa nút "Xóa toàn bộ nhật ký"). Nay `_paneHost` thành documentView của 1 NSScrollView —
    // pane cao hơn khung nhìn thì cuộn được. Popover đã chữa y hệt ở commit d377eaf; đây là
    // nửa còn lại (cửa sổ) bị bỏ sót lần đó.
    _paneScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(kContentPad, kContentPad, kMaxPaneW, kMaxPaneH)];
    _paneScroll.hasVerticalScroller = YES;
    _paneScroll.hasHorizontalScroller = NO;
    _paneScroll.autohidesScrollers = YES;
    _paneScroll.borderType = NSNoBorder;
    // Nền trong suốt: giữ nguyên nền trắng của root — nếu để NSScrollView tự vẽ, macOS ở chế độ
    // Sáng vẫn cho ra xám nhạt, lệch khỏi nền card đã khoá ở AppDelegate (NSAppearanceNameAqua).
    _paneScroll.drawsBackground = NO;
    [_contentContainer addSubview:_paneScroll];

    _paneHost = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, kMaxPaneH)];
    _paneScroll.documentView = _paneHost;

    self.window.contentViewController = _rootVC;

    [self mk_instantiateEmbeddedViewControllers];

    [self selectSectionAtIndex:MKSettingsSectionToday];
}

- (void)mk_buildNavRows {
    NSArray<NSString *> *titles = @[@"Hôm nay", @"Chuông", @"Bộ gõ", @"Riêng tư", @"Hệ thống", @"Giới thiệu"];
    _navRows = [NSMutableArray arrayWithCapacity:titles.count];
    for (NSUInteger i = 0; i < titles.count; i++) {
        CGFloat top = kNavTopPad + (CGFloat)i * kNavRowH;
        NSRect rowFrame = NSMakeRect(8.0, kWindowH - top - kNavRowH + 3.0, kNavW - 16.0, kNavRowH - 6.0);
        MKSettingsNavRow *row = [[MKSettingsNavRow alloc] initWithFrame:rowFrame title:titles[i]];
        NSInteger idx = (NSInteger)i;
        __weak SettingsWindowController *weakSelf = self;
        row.onTap = ^{ [weakSelf selectSectionAtIndex:idx]; };
        [_navContainer addSubview:row];
        [_navRows addObject:row];
    }
}

- (void)mk_buildBoGoSubNav {
    NSRect barFrame = NSMakeRect(kContentPad, kContentPad + kMaxPaneH + kSubNavGap, kMaxPaneW, kSubNavH);
    _subNavBar = [[NSView alloc] initWithFrame:barFrame];
    _subNavBar.hidden = YES;   // mục mặc định là "Hôm nay", không phải "Bộ gõ"

    NSArray<NSString *> *titles = @[@"Kiểu gõ", @"Gõ tắt", @"Chuyển mã"];
    _subNavButtons = [NSMutableArray arrayWithCapacity:titles.count];
    CGFloat bw = 104.0, gap = 8.0, x = 0.0;
    for (NSUInteger i = 0; i < titles.count; i++) {
        NSButton *b = [NSButton buttonWithTitle:titles[i] target:self action:@selector(mk_onSubNavTap:)];
        b.tag = (NSInteger)i;
        b.bordered = NO;
        b.wantsLayer = YES;
        b.layer.cornerRadius = 8.0;
        b.frame = NSMakeRect(x, 0, bw, kSubNavH);
        [_subNavBar addSubview:b];
        [_subNavButtons addObject:b];
        x += bw + gap;
    }
    [_contentContainer addSubview:_subNavBar];
}

- (void)mk_instantiateEmbeddedViewControllers {
    NSStoryboard *sb = [NSStoryboard storyboardWithName:@"Main" bundle:nil];

    // "Bộ gõ ▸ Kiểu gõ" + "Hệ thống" — bare VC qua identifier có sẵn "OpenKeyPanel".
    _openKeyVC = [sb instantiateControllerWithIdentifier:@"OpenKeyPanel"];
    [_openKeyVC view];   // ép -viewDidLoad chạy — box đã live object, đã có frame + card style cuối.
    [_rootVC addChildViewController:_openKeyVC];

    // [MINDFUL] Batch "Hệ thống + Chuông" — "Hệ thống" KHÔNG còn tái dùng `tabviewSystem` (hộp cũ
    // rỗng, xem SCREEN-REFERENCE.md §2.5); pane thật dựng bằng SystemSettingsView bên dưới. Chỉ
    // còn `tabviewPrimary` ("Bộ gõ ▸ Kiểu gõ", ngoài phạm vi batch này) cần reparent từ VC cũ.
    NSBox *primary = _openKeyVC.tabviewPrimary;
    [primary removeFromSuperview];
    // Chỉ reset ORIGIN — giữ nguyên KÍCH THƯỚC để shadowPath (tính theo self.bounds) không lệch.
    primary.frame = (NSRect){NSZeroPoint, primary.frame.size};

    // "Bộ gõ ▸ Gõ tắt" — không có identifier riêng, qua window-controller cha "MacroWindow".
    NSWindowController *macroWC = [sb instantiateControllerWithIdentifier:@"MacroWindow"];
    (void)macroWC.window;   // ép nib nạp — KHÔNG makeKeyAndOrderFront:, wrapper window không bao giờ hiện.
    _macroVC = (MacroViewController *)macroWC.contentViewController;
    [_rootVC addChildViewController:_macroVC];

    // "Bộ gõ ▸ Chuyển mã" — qua window-controller cha "ConvertWindow".
    NSWindowController *convertWC = [sb instantiateControllerWithIdentifier:@"ConvertWindow"];
    (void)convertWC.window;
    _convertVC = (ConvertToolViewController *)convertWC.contentViewController;
    [_rootVC addChildViewController:_convertVC];

    // "Giới thiệu" — qua window-controller cha "AboutWindow".
    NSWindowController *aboutWC = [sb instantiateControllerWithIdentifier:@"AboutWindow"];
    (void)aboutWC.window;
    _aboutVC = (AboutViewController *)aboutWC.contentViewController;
    [_rootVC addChildViewController:_aboutVC];

    // Các pane khác
    _paneToday   = [self mk_buildTodayPane];

    // [MINDFUL] Epic 3 G1 (F5) — pane cao THEO NỘI DUNG (40pt chừa cho tiêu đề "Chuông", giữ đúng
    // khoảng cách của bản cũ). Trước đây pane đóng cứng kMaxPaneH nên `bh` lớn hơn (kMaxPaneH-40)
    // là đẩy bellView xuống dưới y=0 → mất hút, không cuộn tới được.
    BellSettingsView *bellView = [[BellSettingsView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, kMaxPaneH - 40)];
    CGFloat bh = [bellView preferredHeight];
    _paneBell = [self mk_buildEmptyPaneWithTitle:@"Chuông" height:(40.0 + bh)];
    bellView.frame = NSMakeRect(0, NSHeight(_paneBell.frame) - 40.0 - bh, kMaxPaneW, bh);
    [_paneBell addSubview:bellView];

    // Riêng tư cố ý KHÔNG có tiêu đề lớn (PrivacyPaneView tự mở đầu bằng section "Nhật ký cảm xúc")
    // — giữ nguyên như bản cũ, chỉ bỏ trần cứng kMaxPaneH.
    PrivacyPaneView *pv = [[PrivacyPaneView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, kMaxPaneH)];
    CGFloat ph = [pv preferredHeight];
    _panePrivacy = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, MAX(ph, kMaxPaneH))];
    pv.frame = NSMakeRect(0, NSHeight(_panePrivacy.frame) - ph, kMaxPaneW, ph);
    [_panePrivacy addSubview:pv];

    // [MINDFUL] Batch "Hệ thống + Chuông" — "Hệ thống" dựng mới bằng SystemSettingsView (4 mục đã
    // chốt, xem SCREEN-REFERENCE.md §2.5), cùng khuôn MAX(height, kMaxPaneH) như PrivacyPaneView
    // ngay trên (pane ngắn vẫn lấp khung nhìn, pane dài NSScrollView lo phần cuộn).
    SystemSettingsView *sv = [[SystemSettingsView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, kMaxPaneH)];
    CGFloat svh = [sv preferredHeight];
    _paneSystem = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, MAX(svh, kMaxPaneH))];
    sv.frame = NSMakeRect(0, NSHeight(_paneSystem.frame) - svh, kMaxPaneW, svh);
    [_paneSystem addSubview:sv];
}

- (NSView *)mk_buildEmptyPaneWithTitle:(NSString *)title {
    return [self mk_buildEmptyPaneWithTitle:title height:kMaxPaneH];
}

// [MINDFUL] Epic 3 G1 (F5) — `height` kẹp tối thiểu bằng kMaxPaneH: pane ngắn vẫn lấp đầy khung
// nhìn (tiêu đề nằm đúng đỉnh, không trôi xuống giữa), pane dài thì NSScrollView lo phần cuộn.
- (NSView *)mk_buildEmptyPaneWithTitle:(NSString *)title height:(CGFloat)height {
    CGFloat paneH = MAX(height, kMaxPaneH);
    NSView *pane = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, paneH)];
    // Không có Montserrat thật đăng ký trong app (không file font bundle, không fontWithName: ở
    // đâu trong codebase) — dùng systemFont+weight đúng quy ước đã áp dụng cho mọi tiêu đề khác
    // (GatekeeperCardView/PanelViewController), KHÔNG bịa ra 1 font family không tồn tại.
    NSTextField *label = [NSTextField labelWithString:title];
    label.font = [NSFont systemFontOfSize:20.0 weight:NSFontWeightBold];
    label.textColor = [Brand charcoal];
    [label sizeToFit];
    NSRect lf = label.frame;
    lf.origin = NSMakePoint(0.0, NSHeight(pane.frame) - NSHeight(lf) - 4.0);
    label.frame = lf;
    [pane addSubview:label];
    return pane;
}

// [MINDFUL] Story 3.5 — "Hôm nay" giờ là BẢN ĐẦY ĐỦ của popover (decision-log 2026-07-15 "Chốt
// 3 câu chặn Epic 3" mục 1): card Gác cổng (Feature #1) LUÔN đầu tiên/trên cùng (HIẾN CHƯƠNG §5
// điều 10), rồi tới dòng sông. Card + link "Soi lại hôm nay →" TÁI DÙNG nguyên GatekeeperCardView
// đã chạy tốt trong popover (PanelViewController.mm) — không viết lại, link tự gọi
// ReflectionScreenMac_Show() bên trong, không cần wiring thêm.
- (NSView *)mk_buildTodayPane {
    // Instantiate trước để đọc preferredHeight thật, dùng tính tổng chiều cao pane.
    _gatekeeperCard = [[GatekeeperCardView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, 96)];
    CGFloat cardH = [_gatekeeperCard preferredHeight];

    // [MINDFUL] Story 3.7/3.8 — thêm 1 hàng cho segmented "Ngày/Tuần/Tháng" + khoảng cách, chèn
    // giữa card Gác cổng và dòng sông.
    CGFloat totalH = kTodayTitleReserve + cardH + kTodaySectionGap + kDateRangeSegH + kTodaySectionGap + kTodayRiverH;
    NSView *pane = [self mk_buildEmptyPaneWithTitle:@"Hôm nay" height:totalH];

    CGFloat cardTop = NSHeight(pane.frame) - kTodayTitleReserve;
    _gatekeeperCard.frame = NSMakeRect(0, cardTop - cardH, kMaxPaneW, cardH);
    [pane addSubview:_gatekeeperCard];

    CGFloat segTop = cardTop - cardH - kTodaySectionGap;
    // [MINDFUL] Story 3.7/3.8 — segmented rộng vừa phải (180pt), neo trái khớp phong cách card
    // Gác cổng/sông bên trên (đều full-width, neo trái) — không căn giữa tách biệt.
    CGFloat segW = 180.0;
    _dateRangeSeg = [[MKDateRangeSeg alloc] initWithFrame:NSMakeRect(0, segTop - kDateRangeSegH, segW, kDateRangeSegH)];
    _dateRangeSeg.titles = @[@"Ngày", @"Tuần", @"Tháng"];
    _dateRangeSeg.target = self;
    _dateRangeSeg.action = @selector(mk_onDateRangeChanged:);
    [pane addSubview:_dateRangeSeg];

    // [MINDFUL] Vá lỗi (2026-07-16): trước đây riverTop lặp NGUYÊN công thức của segTop (quên
    // trừ chiều cao segmented + khoảng cách), khiến sông (140pt, add SAU nên nằm TRÊN) đè kín lên
    // đúng phần segmented "Ngày/Tuần/Tháng" — control vẫn tồn tại nhưng bị che hoàn toàn, không
    // ai thấy được. Chủ dự án phát hiện qua ảnh chụp cửa sổ Cài đặt thật.
    CGFloat riverTop = segTop - kDateRangeSegH - kTodaySectionGap;
    _settingsRiver = [[EmotionRiverView alloc] initWithFrame:NSMakeRect(0, riverTop - kTodayRiverH, kMaxPaneW, kTodayRiverH)];
    [pane addSubview:_settingsRiver];
    return pane;
}

#pragma mark - Chọn mục / sub-mục

- (void)selectSectionAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)_navRows.count) return;
    _selectedIndex = index;

    for (NSInteger i = 0; i < (NSInteger)_navRows.count; i++) {
        [_navRows[(NSUInteger)i] setSelectedRow:(i == index)];
    }

    _subNavBar.hidden = (index != MKSettingsSectionInput);

    switch ((MKSettingsSection)index) {
        case MKSettingsSectionToday:
            [self mk_refreshTodayPane];
            [self mk_showPaneInHost:_paneToday];
            break;
        case MKSettingsSectionBell:
            for (NSView *sub in _paneBell.subviews) {
                if ([sub isKindOfClass:[BellSettingsView class]]) {
                    [(BellSettingsView *)sub refresh];
                }
            }
            [self mk_showPaneInHost:_paneBell];
            break;
        case MKSettingsSectionInput:
            [self mk_selectBoGoSub:_boGoSubIndex];
            break;
        case MKSettingsSectionPrivacy:
            if (_panePrivacy.subviews.count > 0 && [_panePrivacy.subviews[0] isKindOfClass:[PrivacyPaneView class]]) {
                [(PrivacyPaneView *)_panePrivacy.subviews[0] refresh];
            }
            [self mk_showPaneInHost:_panePrivacy];
            break;
        case MKSettingsSectionSystem:
            if (_paneSystem.subviews.count > 0 && [_paneSystem.subviews[0] isKindOfClass:[SystemSettingsView class]]) {
                [(SystemSettingsView *)_paneSystem.subviews[0] refresh];
            }
            [self mk_showPaneInHost:_paneSystem];
            break;
        case MKSettingsSectionAbout:
            [self mk_showPaneInHost:_aboutVC.view];
            break;
    }
}

- (void)mk_onSubNavTap:(NSButton *)sender {
    [self mk_selectBoGoSub:sender.tag];
}

- (void)mk_selectBoGoSub:(NSInteger)subIndex {
    _boGoSubIndex = subIndex;
    for (NSInteger i = 0; i < (NSInteger)_subNavButtons.count; i++) {
        [self mk_styleSubNavButton:_subNavButtons[(NSUInteger)i] selected:(i == subIndex)];
    }
    switch (subIndex) {
        case 0:
            [self mk_showPaneInHost:_openKeyVC.tabviewPrimary];
            [_openKeyVC fillData];
            break;
        case 1:
            [self mk_showPaneInHost:_macroVC.view];
            [_macroVC.tableView reloadData];
            break;
        case 2:
        default:
            [self mk_showPaneInHost:_convertVC.view];
            [_convertVC fillData];
            break;
    }
}

- (void)mk_refreshTodayPane {
    [_gatekeeperCard refresh];   // [MINDFUL] Story 3.5 (AC3) — không hiện trạng thái cũ từ lần mở trước
    [self mk_reloadRiverForSelectedRange];
}

// [MINDFUL] Story 3.7/3.8 — action của MKDateRangeSeg: bấm đổi Ngày/Tuần/Tháng ngay lúc đang
// xem "Hôm nay" (KHÔNG cần rời mục rồi quay lại mới thấy đổi).
- (void)mk_onDateRangeChanged:(MKDateRangeSeg *)sender {
    [self mk_reloadRiverForSelectedRange];
}

// [MINDFUL] Story 3.7/3.8 — 1 điểm nạp lại sông DUY NHẤT cho cả 3 chế độ, tránh 3 nơi tự fetch
// khác nhau. Ngày dùng logic gap-detection sẵn có (FetchTodaySamples không tự lấp gap — xem
// story 3.7 Dev Notes); Tuần/Tháng dùng FetchWeekSamples/FetchMonthSamples (đã lấp gap sẵn bằng
// NSNull, chỉ cần rút field "value").
- (void)mk_reloadRiverForSelectedRange {
    switch (_dateRangeSeg.selectedIndex) {
        case 1: { // Tuần
            [_settingsRiver setAxisLabels:@[@"7 ngày trước", @"5 ngày trước", @"3 ngày trước", @"Hôm nay"]];
            NSArray<NSDictionary *> *daily = MoodStoreMac_FetchWeekSamples();
            NSMutableArray *samples = [NSMutableArray arrayWithCapacity:daily.count];
            for (NSDictionary *d in daily) [samples addObject:d[@"value"]];
            [_settingsRiver setSamples:samples];
            break;
        }
        case 2: { // Tháng
            [_settingsRiver setAxisLabels:@[@"30 ngày trước", @"20 ngày trước", @"10 ngày trước", @"Hôm nay"]];
            NSArray<NSDictionary *> *daily = MoodStoreMac_FetchMonthSamples();
            NSMutableArray *samples = [NSMutableArray arrayWithCapacity:daily.count];
            for (NSDictionary *d in daily) [samples addObject:d[@"value"]];
            [_settingsRiver setSamples:samples];
            break;
        }
        default: { // Ngày — logic gốc, chưa đổi
            [_settingsRiver setAxisLabels:@[@"Sáng", @"Trưa", @"Chiều", @"Tối"]];
            extern int vBellInterval;
            int intervalMins = vBellInterval > 0 ? vBellInterval : 60;
            // [MINDFUL] Vá trục thời gian (2026-07-16) — xem PanelViewController.mm cùng chỗ sửa.
            NSArray<NSDictionary *> *raw = MoodStoreMac_FetchTodaySamples();
            [_settingsRiver setTodaySamples:raw.count > 0 ? raw : nil
                                 gapSeconds:intervalMins * 60.0 * 1.5];
            break;
        }
    }
}

- (void)mk_styleSubNavButton:(NSButton *)button selected:(BOOL)selected {
    button.layer.backgroundColor = selected ? [Brand teal].CGColor : [NSColor clearColor].CGColor;
    button.layer.borderWidth = selected ? 0.0 : 1.0;
    button.layer.borderColor = [Brand divider].CGColor;
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: selected ? [NSColor whiteColor] : [Brand charcoal],
        NSFontAttributeName: [NSFont systemFontOfSize:12.5 weight:NSFontWeightSemibold]
    };
    button.attributedTitle = [[NSAttributedString alloc] initWithString:button.title attributes:attrs];
}

- (void)mk_showPaneInHost:(nullable NSView *)paneView {
    for (NSView *v in [_paneHost.subviews copy]) {
        [v removeFromSuperview];
    }
    if (paneView == nil) return;

    // [MINDFUL] Epic 3 G1 (F5) — documentView cao bằng MAX(pane, khung nhìn):
    //  - pane thấp hơn khung nhìn  → docH = khung nhìn, không sinh thanh cuộn thừa cho pane ngắn;
    //  - pane cao hơn khung nhìn   → docH = pane, cuộn tới được dòng cuối.
    // KHÔNG đổi KÍCH THƯỚC pane (chỉ đặt lại origin) — 2 NSBox tái dùng từ storyboard tính
    // shadowPath theo self.bounds lúc viewDidLoad, resize ở đây là bóng đổ lệch (xem đầu file).
    const CGFloat viewportH = NSHeight(_paneScroll.contentView.bounds);
    const CGFloat docH = MAX(NSHeight(paneView.frame), viewportH);
    _paneHost.frame = NSMakeRect(0.0, 0.0, kMaxPaneW, docH);

    NSRect f = paneView.frame;
    f.origin = NSMakePoint(0.0, docH - NSHeight(f));   // neo đỉnh (view KHÔNG lật, gốc ở dưới-trái)
    paneView.frame = f;
    [_paneHost addSubview:paneView];

    // Đổi mục thì luôn bắt đầu từ đỉnh — không thừa hưởng vị trí cuộn của mục vừa xem.
    [_paneScroll.contentView scrollToPoint:NSMakePoint(0.0, docH - viewportH)];
    [_paneScroll reflectScrolledClipView:_paneScroll.contentView];
}

@end
