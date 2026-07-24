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
    MKSettingsSectionJournal  = 6,   // [MINDFUL] H4 — "Nhật Ký Tâm". Giá trị MỚI ở CUỐI (không đánh
                                     // số lại 5 mục cũ); nav dựng theo THỨ TỰ HIỂN THỊ, xem mk_buildNavRows.
};

// [MINDFUL] H4 (2026-07-24) — helper dựng pane "Nhật Ký Tâm" (mirror NotesHistoryMac: ngày eyebrow
// + câu hỏi mờ + chữ người viết). Đo chiều cao chữ để pane cao đúng, NSScrollView của settings tự cuộn.
static CGFloat MKJournalTextH(NSString *s, NSFont *font, CGFloat width) {
    if (s.length == 0) return 0;
    NSRect r = [s boundingRectWithSize:NSMakeSize(width, 10000)
                               options:NSStringDrawingUsesLineFragmentOrigin
                            attributes:@{NSFontAttributeName: font}];
    return ceil(r.size.height);
}
static NSString *MKJournalDateLabel(long long ts) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)ts];
    NSDateComponents *c = [cal components:(NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:d];
    NSArray<NSString *> *wd = @[@"CHỦ NHẬT", @"THỨ HAI", @"THỨ BA", @"THỨ TƯ", @"THỨ NĂM", @"THỨ SÁU", @"THỨ BẢY"];
    NSString *w = wd[(NSUInteger)c.weekday - 1];
    NSInteger nowYear = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
    if (c.year != nowYear) return [NSString stringWithFormat:@"%@ %02ld·%02ld·%ld", w, (long)c.day, (long)c.month, (long)c.year];
    return [NSString stringWithFormat:@"%@ %02ld·%02ld", w, (long)c.day, (long)c.month];
}
static NSAttributedString *MKJournalEyebrow(NSString *s) {
    return [[NSAttributedString alloc] initWithString:s attributes:@{
        NSFontAttributeName: [NSFont systemFontOfSize:10.5 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [Brand stone],
        NSKernAttributeName: @(1.0),
    }];
}

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

@interface SettingsWindowController () <NSWindowDelegate>
@end

@implementation SettingsWindowController {
    NSViewController *_rootVC;               // window.contentViewController — chỉ là điểm neo containment
    NSView *_navContainer;
    NSView *_contentContainer;
    NSScrollView *_paneScroll;                // [MINDFUL] Epic 3 G1 (F5) — khung nhìn cuộn bọc _paneHost
    NSView *_paneHost;                        // documentView của _paneScroll; hiện ĐÚNG 1 pane tại 1 thời điểm
    NSView *_subNavBar;                       // 3 nút "Kiểu gõ/Gõ tắt/Chuyển mã", chỉ hiện ở mục "Bộ gõ"
    NSMutableArray<MKSettingsNavRow *> *_navRows;
    NSArray<NSNumber *> *_navRowSection;       // [MINDFUL] H4 — map vị-trí-nav -> MKSettingsSection (thứ tự HIỂN THỊ)
    NSMutableArray<NSButton *> *_subNavButtons;

    NSView *_paneToday;
    NSView *_paneJournal;                      // [MINDFUL] H4 — "Nhật Ký Tâm" (dựng lại mỗi lần chọn)
    GatekeeperCardView *_gatekeeperCard;       // [MINDFUL] Story 3.5 — Feature #1, luôn trên cùng
    MKDateRangeSeg *_dateRangeSeg;             // [MINDFUL] Story 3.7/3.8 — "Ngày / Tuần / Tháng"
    EmotionRiverView *_settingsRiver;
    NSView *_paneBell;
    NSTextField *_paneBellTitleLabel;          // nhãn "Chuông" — dịch lại khi mk_relayoutBellPane chạy
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
                                                                NSWindowStyleMaskMiniaturizable |
                                                                NSWindowStyleMaskResizable)   // [MINDFUL] kéo giãn được
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
        // [MINDFUL] Sàn kích thước = cỡ thiết kế gốc (nav 170 + nội dung 600 + lề): kéo TO thì màn
        // "Hôm nay" tự nới, pane mượn (NSBox từ OpenKey — bóng đổ chụp sẵn theo bounds ở
        // applyBrandCardStyle) canh giữa giữ nguyên cỡ; KHÔNG cho bóp nhỏ hơn để pane mượn không bị
        // cắt/lệch bóng. Không đặt trần → phóng bao lớn tuỳ ý.
        window.minSize = NSMakeSize(kWindowW, kWindowH);
        window.delegate = self;
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
    // [MINDFUL] Cửa sổ kéo giãn — nav ghim TRÁI, bề ngang cố định, cao theo cửa sổ (lề phải co giãn).
    _navContainer.autoresizingMask = NSViewMaxXMargin | NSViewHeightSizable;
    [root addSubview:_navContainer];

    NSView *divider = [[NSView alloc] initWithFrame:NSMakeRect(kNavW, 0, kDividerW, kWindowH)];
    divider.wantsLayer = YES;
    divider.layer.backgroundColor = [Brand divider].CGColor;
    divider.autoresizingMask = NSViewMaxXMargin | NSViewHeightSizable;   // đứng yên sau nav, cao theo cửa sổ
    [root addSubview:divider];

    _contentContainer = [[NSView alloc] initWithFrame:NSMakeRect(kNavW + kDividerW, 0, kContentW, kWindowH)];
    // Cột nội dung nuốt toàn bộ phần rộng/cao dư khi kéo (lề trái neo cố định sau divider).
    _contentContainer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
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
    // [MINDFUL] H4 — 7 mục theo THỨ TỰ HIỂN THỊ; _navRowSection map vị-trí-nav -> MKSettingsSection,
    // để "Nhật Ký Tâm" (section 6) đứng thứ 2 mà KHÔNG đánh số lại 5 section cũ (enum==index cũ vỡ dây).
    NSArray<NSString *> *titles = @[@"Hôm nay", @"Nhật Ký Tâm", @"Chuông", @"Bộ gõ", @"Riêng tư", @"Hệ thống", @"Giới thiệu"];
    _navRowSection = @[@(MKSettingsSectionToday), @(MKSettingsSectionJournal), @(MKSettingsSectionBell),
                       @(MKSettingsSectionInput), @(MKSettingsSectionPrivacy), @(MKSettingsSectionSystem), @(MKSettingsSectionAbout)];
    _navRows = [NSMutableArray arrayWithCapacity:titles.count];
    for (NSUInteger i = 0; i < titles.count; i++) {
        CGFloat top = kNavTopPad + (CGFloat)i * kNavRowH;
        NSRect rowFrame = NSMakeRect(8.0, kWindowH - top - kNavRowH + 3.0, kNavW - 16.0, kNavRowH - 6.0);
        MKSettingsNavRow *row = [[MKSettingsNavRow alloc] initWithFrame:rowFrame title:titles[i]];
        NSInteger section = [_navRowSection[i] integerValue];
        __weak SettingsWindowController *weakSelf = self;
        row.onTap = ^{ [weakSelf selectSectionAtIndex:section]; };
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
    // Nhãn tiêu đề "Chuông" là subview DUY NHẤT của _paneBell tại thời điểm này (bellView chưa
    // add) — giữ lại tham chiếu để mk_relayoutBellPane có thể dịch nó khi chiều cao đổi.
    _paneBellTitleLabel = (NSTextField *)_paneBell.subviews.firstObject;
    bellView.frame = NSMakeRect(0, NSHeight(_paneBell.frame) - 40.0 - bh, kMaxPaneW, bh);
    [_paneBell addSubview:bellView];
    // [MINDFUL] Vá (2026-07-16) — `onLayoutChanged` của BellSettingsView đã được wire ở
    // PanelViewController.mm (popover) nhưng CHƯA từng wire ở đây: bấm "Đồng bộ Chế độ Tập trung"
    // hoặc gõ giờ yên lặng không hợp lệ đổi CHIỀU CAO NỘI DUNG thật của bellView (kExplainH/
    // kInvalidH hiện/ẩn), nhưng khung pane + vị trí tiêu đề "Chuông" vẫn đứng yên vì không ai
    // được báo để dựng lại — dẫn tới card cuối bị cắt/chồng lấn tuỳ mức lệch. mk_relayoutBellPane
    // dựng lại đúng khung mỗi khi bellView tự báo đổi cao.
    __weak SettingsWindowController *weakSelf = self;
    bellView.onLayoutChanged = ^{ [weakSelf mk_relayoutBellPane]; };

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

// [MINDFUL] Vá (2026-07-16) — dựng lại khung pane "Chuông" khi BellSettingsView tự báo đổi chiều
// cao thật (bấm "Đồng bộ Chế độ Tập trung", gõ giờ yên lặng không hợp lệ...). Trước đây
// `onLayoutChanged` không được set nên callback này chưa từng chạy; xem chỗ wire ở
// mk_instantiateEmbeddedViewControllers. Công thức giống HỆT lúc dựng ban đầu (dòng ~405-409),
// chỉ khác là bh được đọc LẠI thay vì đọc 1 lần lúc khởi tạo.
- (void)mk_relayoutBellPane {
    BellSettingsView *bellView = nil;
    for (NSView *sub in _paneBell.subviews) {
        if ([sub isKindOfClass:[BellSettingsView class]]) {
            bellView = (BellSettingsView *)sub;
            break;
        }
    }
    if (bellView == nil) return;

    CGFloat bh = [bellView preferredHeight];
    CGFloat paneH = MAX(40.0 + bh, kMaxPaneH);
    _paneBell.frame = NSMakeRect(0, 0, kMaxPaneW, paneH);

    NSRect lf = _paneBellTitleLabel.frame;
    lf.origin = NSMakePoint(0.0, paneH - NSHeight(lf) - 4.0);
    _paneBellTitleLabel.frame = lf;

    bellView.frame = NSMakeRect(0, paneH - 40.0 - bh, kMaxPaneW, bh);

    // Đang đứng đúng mục "Chuông" thì dựng lại khung nhìn NGAY (đừng đợi rời-rồi-quay-lại mới
    // đúng) — mk_showPaneInHost tính lại docH theo _paneBell.frame vừa đổi ở trên.
    if (_selectedIndex == MKSettingsSectionBell) {
        [self mk_showPaneInHost:_paneBell];
    }
}

// [MINDFUL] Story 3.5 — "Hôm nay" giờ là BẢN ĐẦY ĐỦ của popover (decision-log 2026-07-15 "Chốt
// 3 câu chặn Epic 3" mục 1): card Gác cổng (Feature #1) LUÔN đầu tiên/trên cùng (HIẾN CHƯƠNG §5
// điều 10), rồi tới dòng sông. Card + link "Soi lại hôm nay →" TÁI DÙNG nguyên GatekeeperCardView
// đã chạy tốt trong popover (PanelViewController.mm) — không viết lại, link tự gọi
// ReflectionScreenMac_Show() bên trong, không cần wiring thêm.
// [MINDFUL] H4 (2026-07-24) — pane "Nhật Ký Tâm": danh sách "Những dòng đã viết" (ngày + câu hỏi mờ
// + chữ), dựng thẳng vào pane cao đúng nội dung, NSScrollView của settings tự cuộn. Cố ý KHÔNG sóng/
// số/chuỗi ngày (mirror NotesHistoryMac). Link "Những dòng đã viết →" trong Soi lại vẫn giữ song song.
- (NSView *)mk_buildJournalPane {
    NSArray<NSDictionary *> *notes = MoodStoreMac_FetchAllNotes();   // mới nhất trước; @[] nếu chưa consent
    CGFloat textW = kMaxPaneW - 4.0;
    NSFont *qFont = [NSFont systemFontOfSize:12 weight:NSFontWeightRegular];
    NSFont *bFont = [NSFont systemFontOfSize:15 weight:NSFontWeightRegular];
    const CGFloat titleReserve = 48.0;

    if (notes.count == 0) {
        NSView *pane = [self mk_buildEmptyPaneWithTitle:@"Nhật Ký Tâm" height:kMaxPaneH];
        NSTextField *msg = [NSTextField wrappingLabelWithString:
            @"Chưa có dòng nào. Ô ghi nằm ở cuối màn “Soi lại hôm nay” — khi muốn, ghi lại một dòng cho hôm nay."];
        msg.font = [NSFont systemFontOfSize:13 weight:NSFontWeightRegular];
        msg.textColor = [Brand muted];
        msg.frame = NSMakeRect(0, NSHeight(pane.frame) - titleReserve - 44.0, textW, 44.0);
        [pane addSubview:msg];
        return pane;
    }

    const CGFloat dateH = 16, dateGap = 6, qGap = 5, entryGap = 24, ruleGap = 12;
    NSMutableArray<NSNumber *> *qHs = [NSMutableArray array], *bHs = [NSMutableArray array];
    CGFloat total = titleReserve;
    for (NSDictionary *n in notes) {
        NSString *q = n[@"question"]; NSString *t = n[@"text"] ?: @"";
        CGFloat qh = (q.length > 0) ? MKJournalTextH(q, qFont, textW) : 0;
        CGFloat bh = MKJournalTextH(t, bFont, textW);
        [qHs addObject:@(qh)]; [bHs addObject:@(bh)];
        total += dateH + dateGap + (qh > 0 ? qh + qGap : 0) + bh + entryGap;
    }
    total += 8.0;

    NSView *pane = [self mk_buildEmptyPaneWithTitle:@"Nhật Ký Tâm" height:MAX(total, kMaxPaneH)];
    CGFloat y = NSHeight(pane.frame) - titleReserve;   // đi từ dưới tiêu đề xuống (AppKit gốc dưới-trái)
    for (NSUInteger i = 0; i < notes.count; i++) {
        NSDictionary *n = notes[i];
        CGFloat qh = qHs[i].doubleValue, bh = bHs[i].doubleValue;

        NSTextField *dl = [NSTextField labelWithAttributedString:MKJournalEyebrow(MKJournalDateLabel([n[@"ts"] longLongValue]))];
        dl.frame = NSMakeRect(0, y - dateH, textW, dateH);
        [pane addSubview:dl];
        y -= dateH + dateGap;

        NSString *q = n[@"question"];
        if (qh > 0) {
            NSTextField *ql = [NSTextField wrappingLabelWithString:q];
            ql.font = qFont; ql.textColor = [Brand stone];
            ql.frame = NSMakeRect(0, y - qh, textW, qh);
            [pane addSubview:ql];
            y -= qh + qGap;
        }

        NSTextField *bl = [NSTextField wrappingLabelWithString:(n[@"text"] ?: @"")];
        bl.font = bFont; bl.textColor = [Brand charcoal]; bl.selectable = YES;   // chữ của họ — copy được
        bl.frame = NSMakeRect(0, y - bh, textW, bh);
        [pane addSubview:bl];
        y -= bh;

        if (i + 1 < notes.count) {
            NSView *rule = [[NSView alloc] initWithFrame:NSMakeRect(0, y - ruleGap, textW, 1)];
            rule.wantsLayer = YES;
            rule.layer.backgroundColor = [Brand divider].CGColor;
            [pane addSubview:rule];
        }
        y -= entryGap;
    }
    return pane;
}

- (NSView *)mk_buildTodayPane {
    // Instantiate trước để đọc preferredHeight thật, dùng tính tổng chiều cao pane.
    _gatekeeperCard = [[GatekeeperCardView alloc] initWithFrame:NSMakeRect(0, 0, kMaxPaneW, 96)];
    CGFloat cardH = [_gatekeeperCard preferredHeight];

    // [MINDFUL] Story 3.7/3.8 — thêm 1 hàng cho segmented "Ngày/Tuần/Tháng" + khoảng cách, chèn
    // giữa card Gác cổng và dòng sông.
    CGFloat totalH = kTodayTitleReserve + cardH + kTodaySectionGap + kDateRangeSegH + kTodaySectionGap + kTodayRiverH;
    NSView *pane = [self mk_buildEmptyPaneWithTitle:@"Hôm nay" height:totalH];
    // [MINDFUL] Cửa sổ kéo giãn — tít "Hôm nay" ghim trên-trái, giữ nguyên cỡ (card tự vẽ bên dưới
    // mới là thứ nới rộng). Card dùng applyThinCardStyle (bo/viền theo bounds, không bóng chụp sẵn)
    // nên nới bề ngang là -layout của chúng tự vẽ lại đúng — xem GatekeeperCardView/EmotionRiverView.
    pane.subviews.firstObject.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;

    CGFloat cardTop = NSHeight(pane.frame) - kTodayTitleReserve;
    _gatekeeperCard.frame = NSMakeRect(0, cardTop - cardH, kMaxPaneW, cardH);
    _gatekeeperCard.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;   // nới ngang, ghim đỉnh
    [pane addSubview:_gatekeeperCard];

    CGFloat segTop = cardTop - cardH - kTodaySectionGap;
    // [MINDFUL] Story 3.7/3.8 — segmented rộng vừa phải (180pt), neo trái khớp phong cách card
    // Gác cổng/sông bên trên (đều full-width, neo trái) — không căn giữa tách biệt.
    CGFloat segW = 180.0;
    _dateRangeSeg = [[MKDateRangeSeg alloc] initWithFrame:NSMakeRect(0, segTop - kDateRangeSegH, segW, kDateRangeSegH)];
    _dateRangeSeg.titles = @[@"Ngày", @"Tuần", @"Tháng"];
    _dateRangeSeg.target = self;
    _dateRangeSeg.action = @selector(mk_onDateRangeChanged:);
    _dateRangeSeg.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;   // pill giữ nguyên cỡ, ghim trên-trái
    [pane addSubview:_dateRangeSeg];

    // [MINDFUL] Vá lỗi (2026-07-16): trước đây riverTop lặp NGUYÊN công thức của segTop (quên
    // trừ chiều cao segmented + khoảng cách), khiến sông (140pt, add SAU nên nằm TRÊN) đè kín lên
    // đúng phần segmented "Ngày/Tuần/Tháng" — control vẫn tồn tại nhưng bị che hoàn toàn, không
    // ai thấy được. Chủ dự án phát hiện qua ảnh chụp cửa sổ Cài đặt thật.
    CGFloat riverTop = segTop - kDateRangeSegH - kTodaySectionGap;
    _settingsRiver = [[EmotionRiverView alloc] initWithFrame:NSMakeRect(0, riverTop - kTodayRiverH, kMaxPaneW, kTodayRiverH)];
    _settingsRiver.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;   // sông nới ngang, ghim đỉnh
    [pane addSubview:_settingsRiver];
    return pane;
}

#pragma mark - Chọn mục / sub-mục

- (void)selectSectionAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)_navRows.count) return;
    _selectedIndex = index;

    for (NSInteger i = 0; i < (NSInteger)_navRows.count; i++) {
        // [MINDFUL] H4 — tô sáng theo SECTION (map từ vị-trí-nav), không so vị-trí trực tiếp nữa.
        NSInteger sec = (i < (NSInteger)_navRowSection.count) ? [_navRowSection[(NSUInteger)i] integerValue] : i;
        [_navRows[(NSUInteger)i] setSelectedRow:(sec == index)];
    }

    BOOL isBoGo = (index == MKSettingsSectionInput);
    _subNavBar.hidden = !isBoGo;

    // [MINDFUL] Cửa sổ kéo giãn — khung cuộn + thanh sub-nav "Bộ gõ" nay tính theo kích thước THẬT
    // của cột nội dung (trước đây đóng cứng theo hằng kMaxPaneH); chừa chỗ thanh sub-nav khi ở "Bộ gõ".
    [self mk_layoutScrollAndSubnav];

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
        case MKSettingsSectionJournal:
            // [MINDFUL] H4 — dựng LẠI mỗi lần chọn: note có thể vừa được viết thêm ở màn Soi lại.
            _paneJournal = [self mk_buildJournalPane];
            [self mk_showPaneInHost:_paneJournal];
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
    // [MINDFUL] Vá vệt chữ nhòe (2026-07-16) — trước khi gỡ pane cũ, ép NSClipView vẽ lại đúng
    // vùng nó đang chiếm (rect tính theo hệ toạ độ của clip view, KHÔNG phải của _paneHost).
    // NSClipView mặc định chỉ invalidate phần diện tích THỰC SỰ đổi khi tính toán được (để đỡ vẽ
    // lại tốn kém) — khi ta thay NGUYÊN documentView (gỡ pane cũ, gắn pane khác kích thước khác)
    // rồi NHẢY thẳng vị trí cuộn (không phải cử chỉ cuộn mượt của người dùng), phép tính "phần nào
    // đổi" của nó có thể sai, để lại pixel CŨ (vd tiêu đề pane vừa rời) không được vẽ đè — đúng
    // dạng "2 lớp chữ đè nhau" chủ dự án chụp được. `-setNeedsDisplayInRect:` là cách Apple khuyến
    // nghị thay cho `copiesOnScroll` (đã bị loại bỏ tác dụng từ macOS 11).
    NSClipView *clipView = _paneScroll.contentView;
    [clipView setNeedsDisplayInRect:clipView.bounds];

    for (NSView *v in [_paneHost.subviews copy]) {
        [v removeFromSuperview];
    }
    if (paneView == nil) return;

    [_paneHost addSubview:paneView];
    [self mk_layoutHostForCurrentPane];   // định cỡ documentView + đặt pane theo bề ngang hiện tại

    // Đổi mục thì luôn bắt đầu từ đỉnh — không thừa hưởng vị trí cuộn của mục vừa xem.
    const CGFloat viewportH = NSHeight(_paneScroll.contentView.bounds);
    [_paneScroll.contentView scrollToPoint:NSMakePoint(0.0, NSHeight(_paneHost.frame) - viewportH)];
    [_paneScroll reflectScrolledClipView:_paneScroll.contentView];

    // Ép vẽ lại lần nữa SAU khi nội dung mới đã vào đúng vị trí — đảm bảo khung nhìn hiển thị
    // đúng pixel hiện tại, không phải bitmap còn sót từ pane/scroll-position trước đó.
    [clipView setNeedsDisplayInRect:clipView.bounds];
}

// [MINDFUL] Cửa sổ kéo giãn — dựng lại khung cuộn + thanh sub-nav "Bộ gõ" theo kích thước THẬT của
// cột nội dung (đang tự giãn bằng autoresizing). Lề trái + đáy neo cố định kContentPad; khi ở "Bộ
// gõ" thì chừa chỗ thanh "Kiểu gõ/Gõ tắt/Chuyển mã" bên trên. Ở cỡ cửa sổ gốc, số ra y hệt các hằng
// kMaxPaneW/kMaxPaneH cũ (scrollW=600, scrollH=514 hoặc 472 khi Bộ gõ) — refactor không đổi bố cục.
- (void)mk_layoutScrollAndSubnav {
    CGFloat cw = NSWidth(_contentContainer.bounds);
    CGFloat ch = NSHeight(_contentContainer.bounds);
    BOOL isBoGo = (_selectedIndex == MKSettingsSectionInput);
    CGFloat scrollW = MAX(cw - 2 * kContentPad, 0.0);
    CGFloat topInset = isBoGo ? (kSubNavH + kSubNavGap) : 0.0;
    CGFloat scrollH = MAX(ch - 2 * kContentPad - topInset, 0.0);
    _paneScroll.frame = NSMakeRect(kContentPad, kContentPad, scrollW, scrollH);
    if (isBoGo) {
        _subNavBar.frame = NSMakeRect(kContentPad, kContentPad + scrollH + kSubNavGap, scrollW, kSubNavH);
    }
    // Ép NSScrollView chia lại khung NGAY để mk_layoutHostForCurrentPane đọc đúng bề ngang khả dụng
    // của clip view (không phải giá trị cũ trước khi đổi frame).
    [_paneScroll tile];
}

// [MINDFUL] Cửa sổ kéo giãn — đặt lại documentView + pane đang hiện theo bề ngang khung nhìn hiện
// tại. Chỉ màn "Hôm nay" (_paneToday: toàn card tự vẽ applyThinCardStyle, bo/viền theo bounds, KHÔNG
// bóng chụp sẵn) mới NỚI RỘNG — autoresizing của 3 card con lo phần còn lại. Các pane khác GIỮ nguyên
// bề ngang, canh giữa cột: nhất là pane mượn NSBox từ OpenKey (applyBrandCardStyle chụp shadowPath
// theo bounds lúc viewDidLoad → resize là bóng lệch, xem đầu file). Với pane cố định CHỈ đổi origin.
//
// [MINDFUL] Epic 3 G1 (F5) — documentView cao bằng MAX(pane, khung nhìn):
//  - pane thấp hơn khung nhìn → docH = khung nhìn, không sinh thanh cuộn thừa cho pane ngắn;
//  - pane cao hơn khung nhìn  → docH = pane, cuộn tới được dòng cuối.
- (void)mk_layoutHostForCurrentPane {
    NSView *pane = _paneHost.subviews.firstObject;
    if (pane == nil) return;

    CGFloat vw = NSWidth(_paneScroll.contentView.bounds);
    CGFloat viewportH = NSHeight(_paneScroll.contentView.bounds);
    if (vw <= 0.0) return;

    BOOL stretchy = (pane == _paneToday);
    CGFloat paneW = stretchy ? vw : NSWidth(pane.frame);
    CGFloat paneH = NSHeight(pane.frame);
    CGFloat docH = MAX(paneH, viewportH);

    _paneHost.frame = NSMakeRect(0.0, 0.0, vw, docH);

    CGFloat x = stretchy ? 0.0 : MAX(0.0, (vw - paneW) / 2.0);   // pane cố định canh giữa cột nội dung
    pane.frame = NSMakeRect(x, docH - paneH, paneW, paneH);       // neo đỉnh (view KHÔNG lật, gốc dưới-trái)
}

// [MINDFUL] Cửa sổ kéo giãn — mỗi lần người dùng kéo cạnh cửa sổ: cột nav/divider/nội dung đã tự
// giãn bằng autoresizing; còn khung cuộn + pane bên trong dựng lại tay ở đây (giữ nguyên vị trí cuộn,
// không nhảy về đỉnh như lúc đổi mục).
- (void)windowDidResize:(NSNotification *)notification {
    [self mk_layoutScrollAndSubnav];
    [self mk_layoutHostForCurrentPane];
}

@end
