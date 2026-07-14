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

#pragma mark - SettingsWindowController

@implementation SettingsWindowController {
    NSViewController *_rootVC;               // window.contentViewController — chỉ là điểm neo containment
    NSView *_navContainer;
    NSView *_contentContainer;
    NSView *_paneHost;                        // nơi hiện ĐÚNG 1 pane tại 1 thời điểm
    NSView *_subNavBar;                       // 3 nút "Kiểu gõ/Gõ tắt/Chuyển mã", chỉ hiện ở mục "Bộ gõ"
    NSMutableArray<MKSettingsNavRow *> *_navRows;
    NSMutableArray<NSButton *> *_subNavButtons;

    NSView *_paneToday;
    NSView *_paneBell;
    NSView *_panePrivacy;

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

    _paneHost = [[NSView alloc] initWithFrame:NSMakeRect(kContentPad, kContentPad, kMaxPaneW, kMaxPaneH)];
    [_contentContainer addSubview:_paneHost];

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

    NSBox *primary = _openKeyVC.tabviewPrimary;
    NSBox *system  = _openKeyVC.tabviewSystem;
    [primary removeFromSuperview];
    [system removeFromSuperview];
    // Chỉ reset ORIGIN — giữ nguyên KÍCH THƯỚC để shadowPath (tính theo self.bounds) không lệch.
    primary.frame = (NSRect){NSZeroPoint, primary.frame.size};
    system.frame  = (NSRect){NSZeroPoint, system.frame.size};

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

    // 3 pane rỗng thật thà (AC5) — chỉ 1 tiêu đề đúng tên mục, không nội dung khác.
    _paneToday   = [self mk_buildEmptyPaneWithTitle:@"Hôm nay"];
    _paneBell    = [self mk_buildEmptyPaneWithTitle:@"Chuông"];
    _panePrivacy = [self mk_buildEmptyPaneWithTitle:@"Riêng tư"];
}

- (NSView *)mk_buildEmptyPaneWithTitle:(NSString *)title {
    NSView *pane = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, kMaxPaneH)];
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
            [self mk_showPaneInHost:_paneToday];
            break;
        case MKSettingsSectionBell:
            [self mk_showPaneInHost:_paneBell];
            break;
        case MKSettingsSectionInput:
            [self mk_selectBoGoSub:_boGoSubIndex];
            break;
        case MKSettingsSectionPrivacy:
            [self mk_showPaneInHost:_panePrivacy];
            break;
        case MKSettingsSectionSystem:
            [self mk_showPaneInHost:_openKeyVC.tabviewSystem];
            [_openKeyVC fillData];
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
    NSRect f = paneView.frame;
    f.origin = NSMakePoint(0.0, NSHeight(_paneHost.bounds) - NSHeight(f));
    paneView.frame = f;
    [_paneHost addSubview:paneView];
}

@end
