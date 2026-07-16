//
//  SystemSettingsView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Batch "Hệ thống + Chuông" — xem SystemSettingsView.h cho hợp đồng. Cấu trúc/hằng số
//  layout SAO CHÉP nguyên nhịp bố cục của PrivacyPaneView.mm/BellSettingsView.mm (SCREEN-REFERENCE
//  Phần 0): eyebrow + 1 applyThinCardStyle mỗi mục, cách nhau kSectionGap.
//
//  Gate "mô tả hay phán xét?" (HIẾN CHƯƠNG §5.8) — copy trong file: "Tự mở Mindful Key mỗi khi
//  đăng nhập máy", "Tắt vẫn mở lại được...", "Đổi phím tắt trong mục Bộ gõ" — đều MÔ TẢ hành vi
//  thật, không khiển trách. ✅
//

#import "SystemSettingsView.h"
#import "BrandControls.h"
#import "BrandColors.h"
#import "AppDelegate.h"

// [MINDFUL] Cùng idiom "reach into AppDelegate" mà InputMethodCardView.mm/ReflectionScreenMac.mm
// đã dùng — biến global thật, khai extern tại điểm dùng, KHÔNG tạo singleton mới.
extern AppDelegate *appDelegate;

// Layout (điểm) — giống hệt hằng số PrivacyPaneView.mm/BellSettingsView.mm.
static const CGFloat kEbH        = 13.0;
static const CGFloat kEbGap      = 8.0;
static const CGFloat kSectionGap = 16.0;
static const CGFloat kCardPadX   = 14.0;
static const CGFloat kCardPadY   = 13.0;
static const CGFloat kRowH       = 20.0;
static const CGFloat kGapSm      = 9.0;
static const CGFloat kNoteH      = 32.0;
static const CGFloat kSwitchH    = 24.0;
static const CGFloat kBtnH       = 32.0;
static const CGFloat kChipH      = 22.0;

// [MINDFUL] Cùng bit layout hotkey với BellSettingsView.mm/InputMethodCardView.mm (mỗi file giữ 1
// bản tĩnh riêng — quy ước sẵn có trong codebase, không gộp vào header dùng chung). Ở ĐÂY chỉ để
// HIỂN THỊ (task: "hiển thị hotkey HIỆN CÓ, ĐỪNG tạo biến mới") — không thu phím mới, không ghi.
static NSString *StringFromHotkey(int hotkey) {
    if (hotkey == 0) return @"Chưa đặt";
    NSMutableString *s = [NSMutableString string];
    if (hotkey & 0x100) [s appendString:@"⌃"]; // Control
    if (hotkey & 0x200) [s appendString:@"⌥"]; // Option
    if (hotkey & 0x400) [s appendString:@"⌘"]; // Command
    if (hotkey & 0x800) [s appendString:@"⇧"]; // Shift

    unsigned int charCode = (hotkey >> 24) & 0xFF;
    if (charCode > 0) {
        if (charCode == 32) {
            [s appendString:@"Space"];
        } else {
            [s appendFormat:@"%c", toupper(charCode)];
        }
    } else {
        int keycode = hotkey & 0xFF;
        if (keycode != 0xFE) {
            if (keycode == 49) [s appendString:@"Space"];
            else [s appendFormat:@"[Key %d]", keycode];
        }
    }
    return s;
}

// [MINDFUL] version.env (repo root) là NGUỒN DUY NHẤT của số phiên bản (comment đầu file đó +
// Makefile mục `version`). Info.plist CFBundleShortVersionString ($(MARKETING_VERSION) trong
// project.yml) đang LỆCH với version.env — KHÔNG đọc NSBundle cho số hiển thị chính. version.env
// được thêm vào Copy Bundle Resources (project.yml, mục sources) để đọc được cả từ bản đã cài
// /Applications, không chỉ lúc chạy từ Xcode. Có dự phòng nếu vì lý do gì đó resource không kèm.
static NSString *CurrentVersionString(void) {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"version" ofType:@"env"];
    NSString *content = path ? [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] : nil;
    if (content.length > 0) {
        for (NSString *line in [content componentsSeparatedByString:@"\n"]) {
            NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([trimmed hasPrefix:@"VERSION="]) {
                NSString *v = [trimmed substringFromIndex:[@"VERSION=" length]];
                if (v.length > 0) return v;
            }
        }
    }
    NSString *fallback = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return fallback ?: @"—";
}

@interface SystemSettingsView () <NSTextFieldDelegate>
@end

@implementation SystemSettingsView {
    // 1. Khởi động cùng macOS
    NSTextField *_ebStartup;
    NSView      *_cardStartup;
    NSTextField *_lblStartup;
    PillSwitch  *_switchStartup;
    NSTextField *_noteStartup;

    // 2. Hiện biểu tượng trên thanh menu
    NSTextField *_ebMenuBar;
    NSView      *_cardMenuBar;
    NSTextField *_lblMenuBar;
    PillSwitch  *_switchMenuBar;
    NSTextField *_noteMenuBar;

    // 3. Phím tắt bật/tắt bộ gõ (display-only)
    NSTextField *_ebHotkey;
    NSView      *_cardHotkey;
    NSTextField *_lblHotkey;
    NSTextField *_hotkeyChip;
    NSTextField *_noteHotkey;

    // 4. Cập nhật
    NSTextField *_ebUpdate;
    NSView      *_cardUpdate;
    NSTextField *_lblVersion;
    SecondaryButton *_btnReleases;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.wantsLayer = YES;

        [self buildStartupSection];
        [self buildMenuBarSection];
        [self buildHotkeySection];
        [self buildUpdateSection];

        [self refresh];
    }
    return self;
}

#pragma mark - Helpers (giống PrivacyPaneView.mm)

- (NSTextField *)label:(NSString *)s font:(NSFont *)f color:(NSColor *)c {
    NSTextField *l = [NSTextField labelWithString:s];
    l.font = f;
    l.textColor = c;
    l.backgroundColor = [NSColor clearColor];
    l.bordered = NO;
    l.editable = NO;
    [self addSubview:l];
    return l;
}

- (NSFont *)fFieldLbl { return [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold]; }
- (NSFont *)fCaption  { return [NSFont systemFontOfSize:11.5 weight:NSFontWeightRegular]; }

- (NSView *)addCard {
    NSView *v = [[NSView alloc] initWithFrame:NSZeroRect];
    [v applyThinCardStyle];
    [self addSubview:v];
    return v;
}

#pragma mark - Build subviews

- (void)buildStartupSection {
    _ebStartup = [NSTextField mk_eyebrowLabelWithTitle:@"Khởi động"];
    [self addSubview:_ebStartup];
    _cardStartup = [self addCard];

    _lblStartup = [self label:@"Khởi động cùng macOS" font:[self fFieldLbl] color:[Brand charcoal]];

    _switchStartup = [[PillSwitch alloc] initWithFrame:NSZeroRect];
    _switchStartup.target = self;
    _switchStartup.action = @selector(onStartupSwitch:);
    [self addSubview:_switchStartup];

    _noteStartup = [self label:@"Tự mở Mindful Key mỗi khi đăng nhập máy."
                           font:[self fCaption] color:[Brand muted]];
    _noteStartup.lineBreakMode = NSLineBreakByWordWrapping;
    _noteStartup.maximumNumberOfLines = 2;
}

- (void)buildMenuBarSection {
    _ebMenuBar = [NSTextField mk_eyebrowLabelWithTitle:@"Thanh menu"];
    [self addSubview:_ebMenuBar];
    _cardMenuBar = [self addCard];

    _lblMenuBar = [self label:@"Hiện biểu tượng trên thanh menu" font:[self fFieldLbl] color:[Brand charcoal]];

    _switchMenuBar = [[PillSwitch alloc] initWithFrame:NSZeroRect];
    _switchMenuBar.target = self;
    _switchMenuBar.action = @selector(onMenuBarSwitch:);
    [self addSubview:_switchMenuBar];

    // [MINDFUL] Đã xác nhận trong AppDelegate.m: -applicationShouldHandleReopen:hasVisibleWindows:
    // gọi thẳng -onSettingsSelected, nên tắt icon KHÔNG khoá người dùng ra khỏi app (mở lại app từ
    // Spotlight/Finder khi đang chạy nền vẫn bật lại được cửa sổ Cài đặt) — caption nói đúng sự thật.
    _noteMenuBar = [self label:@"Tắt vẫn mở lại được: tìm \"Mindful Key\" bằng Spotlight hoặc mở lại từ Finder."
                           font:[self fCaption] color:[Brand muted]];
    _noteMenuBar.lineBreakMode = NSLineBreakByWordWrapping;
    _noteMenuBar.maximumNumberOfLines = 2;
}

- (void)buildHotkeySection {
    _ebHotkey = [NSTextField mk_eyebrowLabelWithTitle:@"Phím tắt"];
    [self addSubview:_ebHotkey];
    _cardHotkey = [self addCard];

    _lblHotkey = [self label:@"Phím tắt bật/tắt bộ gõ" font:[self fFieldLbl] color:[Brand charcoal]];

    // Chỉ HIỂN THỊ (task [A].3: display-only) — chip đọc-only bằng NSTextField, CỐ Ý không dùng
    // NSButton: bấm-được-mà-không-làm-gì là đúng thứ checklist nghiệm thu cấm ("UI trang trí không
    // nối gì"). Sửa phím tắt này vẫn làm ở tab Bộ gõ ▸ Kiểu gõ (InputMethodCardView, đã có sẵn).
    _hotkeyChip = [[NSTextField alloc] initWithFrame:NSZeroRect];
    _hotkeyChip.font = [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold];
    _hotkeyChip.textColor = [Brand teal];
    _hotkeyChip.alignment = NSTextAlignmentCenter;
    _hotkeyChip.bordered = NO;
    _hotkeyChip.editable = NO;
    _hotkeyChip.selectable = NO;
    _hotkeyChip.wantsLayer = YES;
    _hotkeyChip.layer.cornerRadius = 8.0;
    _hotkeyChip.layer.borderWidth = 1.0;
    _hotkeyChip.layer.borderColor = [Brand divider].CGColor;
    _hotkeyChip.backgroundColor = [Brand softWhite];   // token, KHÔNG [NSColor whiteColor] thô
    _hotkeyChip.drawsBackground = YES;
    [self addSubview:_hotkeyChip];

    _noteHotkey = [self label:@"Đổi phím tắt trong mục Bộ gõ."
                          font:[self fCaption] color:[Brand muted]];
    _noteHotkey.lineBreakMode = NSLineBreakByWordWrapping;
    _noteHotkey.maximumNumberOfLines = 2;
}

- (void)buildUpdateSection {
    _ebUpdate = [NSTextField mk_eyebrowLabelWithTitle:@"Phiên bản"];
    [self addSubview:_ebUpdate];
    _cardUpdate = [self addCard];

    _lblVersion = [self label:@"—" font:[self fFieldLbl] color:[Brand charcoal]];

    // [MINDFUL] Dự án CHƯA có backend tự kiểm bản mới (không Sparkle — xem OpenKeyManager.m comment
    // "Auto-update thật sẽ làm sau bằng Sparkle"). KHÔNG dựng nút "Kiểm tra cập nhật" chạy rỗng —
    // mở thẳng trang GitHub Releases, cùng URL AboutViewController.m đã dùng.
    _btnReleases = [[SecondaryButton alloc] initWithFrame:NSZeroRect];
    _btnReleases.title = @"Xem bản mới";
    _btnReleases.target = self;
    _btnReleases.action = @selector(onOpenReleases:);
    [self addSubview:_btnReleases];
}

#pragma mark - State

- (void)refresh {
    [_switchStartup setOn:[appDelegate isRunOnStartup] animated:NO];
    [_switchMenuBar setOn:[appDelegate isStatusItemVisible] animated:NO];

    extern int vSwitchKeyStatus;
    _hotkeyChip.stringValue = StringFromHotkey(vSwitchKeyStatus);

    _lblVersion.stringValue = [NSString stringWithFormat:@"Phiên bản %@", CurrentVersionString()];

    self.needsLayout = YES;
}

#pragma mark - Actions

- (void)onStartupSwitch:(PillSwitch *)sender {
    [appDelegate setRunOnStartup:sender.isOn];
}

- (void)onMenuBarSwitch:(PillSwitch *)sender {
    [appDelegate setStatusItemVisible:sender.isOn];
}

- (void)onOpenReleases:(SecondaryButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/theminh207/mindful-key/releases"]];
}

#pragma mark - Layout

- (CGFloat)preferredHeight { return [self relayout:NO]; }

- (void)layout {
    [super layout];
    [self relayout:YES];
}

- (CGFloat)relayout:(BOOL)apply {
    CGFloat W = NSWidth(self.bounds);
    CGFloat H = NSHeight(self.bounds);
    CGFloat top = 0;

#define SET(v, x, t, w, h) if (apply && (v)) { (v).frame = NSMakeRect((x), H - (t) - (h), (w), (h)); }

    // 1. Khởi động
    SET(_ebStartup, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat startupTop = top;
    CGFloat cy = kCardPadY;

    SET(_lblStartup, kCardPadX, startupTop + cy, W - 2 * kCardPadX - 60.0, kRowH);
    if (apply) {
        _switchStartup.frame = NSMakeRect(W - kCardPadX - 40.0, H - (startupTop + cy) - kRowH + (kRowH - kSwitchH) / 2.0, 40.0, kSwitchH);
    }
    cy += kRowH + kGapSm;
    SET(_noteStartup, kCardPadX, startupTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardStartup, 0, startupTop, W, cy);
    top = startupTop + cy + kSectionGap;

    // 2. Thanh menu
    SET(_ebMenuBar, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat menuBarTop = top;
    cy = kCardPadY;

    SET(_lblMenuBar, kCardPadX, menuBarTop + cy, W - 2 * kCardPadX - 60.0, kRowH);
    if (apply) {
        _switchMenuBar.frame = NSMakeRect(W - kCardPadX - 40.0, H - (menuBarTop + cy) - kRowH + (kRowH - kSwitchH) / 2.0, 40.0, kSwitchH);
    }
    cy += kRowH + kGapSm;
    SET(_noteMenuBar, kCardPadX, menuBarTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardMenuBar, 0, menuBarTop, W, cy);
    top = menuBarTop + cy + kSectionGap;

    // 3. Phím tắt (nhãn trái, chip hiển thị-only bên phải — cùng nhịp hàng label+control các thẻ khác)
    SET(_ebHotkey, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat hotkeyTop = top;
    cy = kCardPadY;

    SET(_lblHotkey, kCardPadX, hotkeyTop + cy, W - 2 * kCardPadX - 90.0, kRowH);
    if (apply) {
        _hotkeyChip.frame = NSMakeRect(W - kCardPadX - 80.0, H - (hotkeyTop + cy) - kRowH + (kRowH - kChipH) / 2.0, 80.0, kChipH);
    }
    cy += kRowH + kGapSm;
    SET(_noteHotkey, kCardPadX, hotkeyTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardHotkey, 0, hotkeyTop, W, cy);
    top = hotkeyTop + cy + kSectionGap;

    // 4. Cập nhật
    SET(_ebUpdate, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat updateTop = top;
    cy = kCardPadY;

    SET(_lblVersion, kCardPadX, updateTop + cy, W - 2 * kCardPadX, kRowH);
    cy += kRowH + kGapSm;
    SET(_btnReleases, kCardPadX, updateTop + cy, 120.0, kBtnH);
    cy += kBtnH + kCardPadY;
    SET(_cardUpdate, 0, updateTop, W, cy);
    top = updateTop + cy;

#undef SET
    return top;
}

@end
