//
//  BellSettingsView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.5 / Áo mới v2 — xem BellSettingsView.h cho hợp đồng + ràng buộc hiến chương.
//
//  Gate "mô tả hay phán xét?" (HIẾN CHƯƠNG §5.8) — mọi copy trong file này đã tự soi:
//    "Ít nhạy/Vừa/Nhạy", "Giờ yên lặng", "Khoảng giờ chưa hợp lệ", "Đồng bộ Chế độ Tập trung",
//    "…cần cấp quyền, mặc định tắt", ghi chú độ nhạy — đều MÔ TẢ thiết lập/hành vi, KHÔNG khiển
//    trách/thúc ép người dùng. ✅
//

#import "BellSettingsView.h"
#import "BrandControls.h"
#import "BrandColors.h"
#import "EmotionWaveView.h"
#import "NudgeCoordinatorMac.h"
#import "PanelViewController.h"
#import "BellMac.h"   // [MINDFUL] Story 1.5 — BellMac_PreviewSound() / kBellSoundMuteName

// UserDefaults keys (story 1.5). Đặt cạnh nhau để không rải magic-string.
static NSString *const kKeySensitivity = @"vBellSensitivity"; // int 1..3
static NSString *const kKeySoundName   = @"vBellSoundName";    // NSString (tên NSSound hệ thống, hoặc kBellSoundMuteName)
static NSString *const kKeyVolume      = @"vBellVolume";       // float 0..1
static NSString *const kKeyFocusSync   = @"vBellFocusSync";    // bool
static NSString *const kKeyBellFrom    = @"vBellFrom";         // int giờ — chuông ĐƯỢC PHÉP reo (từ)
static NSString *const kKeyBellTo      = @"vBellTo";           // int giờ — chuông ĐƯỢC PHÉP reo (đến)

// Layout (điểm) — kiểu Haynoi: mỗi nhóm = 1 eyebrow + 1 thẻ trắng viền mảnh (mockup .card: padding
// 13px 14px, bo góc 11px, margin-bottom 16px giữa các nhóm).
static const CGFloat kEbH        = 13.0;   // chiều cao dòng eyebrow
static const CGFloat kEbGap      = 8.0;    // eyebrow → đỉnh thẻ
static const CGFloat kSectionGap = 16.0;   // đáy 1 thẻ → eyebrow nhóm kế tiếp
static const CGFloat kCardPadX   = 14.0;
static const CGFloat kCardPadY   = 13.0;
static const CGFloat kRowH       = 20.0;
static const CGFloat kSegH       = 28.0;
static const CGFloat kGapSm      = 9.0;
static const CGFloat kGapMd      = 12.0;
static const CGFloat kNoteH      = 32.0;   // ghi chú tối đa 2 dòng
static const CGFloat kSwitchH    = 24.0;
static const CGFloat kExplainH   = 44.0;
static const CGFloat kInvalidH   = 16.0;
static const CGFloat kLabelWQ    = 90.0;   // cột nhãn cho hàng "Giờ yên lặng"

// Ánh xạ nhãn thân thiện (mockup "Bộ tiếng") → tên NSSound hệ thống thật (hoặc sentinel "Im").
static NSString *SoundNameForIndex(NSInteger i) {
    switch (i) { case 1: return @"Chuông gió"; case 2: return @"Chuông reo"; default: return @"Chuông chùa"; }
}
static NSInteger IndexForSoundName(NSString *name) {
    if ([name isEqualToString:@"Chuông gió"]) return 1;
    if ([name isEqualToString:@"Chuông reo"]) return 2;
    return 0;
}

static NSInteger ParseHour(NSString *s) {
    NSString *t = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSRange colon = [t rangeOfString:@":"];
    if (colon.location != NSNotFound) t = [t substringToIndex:colon.location];
    if (t.length == 0) return -1;
    for (NSUInteger i = 0; i < t.length; i++) {
        unichar c = [t characterAtIndex:i];
        if (c < '0' || c > '9') return -1;
    }
    NSInteger h = t.integerValue;
    return (h >= 0 && h <= 23) ? h : -1;
}

#pragma mark - MKSegmented (segmented control tự vẽ)

// Tự vẽ (như PillSwitch) để chắc chắn: nền pill softWhite, ô chọn = teal + chữ TRẮNG, ô khác =
// chữ muted. KHÔNG số, KHÔNG progress bar (HIẾN CHƯƠNG §5). NSSegmentedControl/ NSButton viền-off
// không cho ép "teal + chữ trắng" đáng tin nên vẽ tay, đồng ngôn ngữ với PillSwitch/styleTabButton.
@interface MKSegmented : NSControl
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, assign) NSInteger selectedIndex;   // 0-based
@end

@implementation MKSegmented

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

#pragma mark - BellSettingsView

@interface BellSettingsView () <NSTextFieldDelegate>
@end

@implementation BellSettingsView {
    // Trạng thái (Status)
    NSTextField *_ebStatus;
    NSView      *_cardStatus;
    NSTextField *_lblBellEnable;
    PillSwitch  *_bellEnableSwitch;
    NSTextField *_noteStatus;
    NSButton    *_hotkeyBtn;

    // Nhịp (Interval)
    NSTextField *_ebInterval;
    NSView      *_cardInterval;
    NSTextField *_lblInterval;
    MKSegmented *_intervalSeg;
    NSTextField *_noteInterval;



    // Âm thanh
    NSTextField *_ebSound;
    NSView      *_cardSound;
    NSTextField *_lblSound;
    NSButton    *_btnBell1;
    NSButton    *_btnBell2;
    NSButton    *_btnBell3;
    NSView      *_bellIndicator;
    NSInteger    _bellSelectedIndex;
    NSTextField *_lblVolume;
    NSSlider    *_volume;

    // Yên lặng
    NSTextField *_ebQuiet;
    NSView      *_cardQuiet;
    NSTextField *_lblQuiet;
    NSTextField *_quietFrom;   // giờ bắt đầu yên lặng
    NSTextField *_arrow;
    NSTextField *_quietTo;      // giờ kết thúc yên lặng
    NSTextField *_quietError;
    NSInteger    _quietFromHour;
    NSInteger    _quietToHour;
    BOOL         _quietInvalid;
    NSTextField *_lblFocus;
    PillSwitch  *_focusSwitch;
    NSTextField *_focusExplain;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.wantsLayer = YES;

        [self buildStatusSection];
        [self buildIntervalSection];
        [self buildSoundSection];
        [self buildQuietSection];

        [self refresh];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:@"BellStateChangedNotification"
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Helpers

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

- (NSFont *)fFieldLbl { return [NSFont systemFontOfSize:12 weight:NSFontWeightRegular]; }
- (NSFont *)fCaption  { return [NSFont systemFontOfSize:11.5 weight:NSFontWeightRegular]; }

- (NSView *)addCard {
    NSView *v = [[NSView alloc] initWithFrame:NSZeroRect];
    [v applyThinCardStyle];
    [self addSubview:v];
    return v;
}

#pragma mark - Build subviews

- (void)buildStatusSection {
    _ebStatus = [NSTextField mk_eyebrowLabelWithTitle:@"Trạng thái"];
    [self addSubview:_ebStatus];
    _cardStatus = [self addCard];

    _lblBellEnable = [self label:@"Bật chuông tỉnh thức" font:[NSFont systemFontOfSize:12 weight:NSFontWeightSemibold] color:[Brand charcoal]];
    
    _hotkeyBtn = [NSButton buttonWithTitle:@"⌥⌘B" target:self action:@selector(onHotkeyClick:)];
    _hotkeyBtn.bordered = NO;
    _hotkeyBtn.wantsLayer = YES;
    _hotkeyBtn.layer.backgroundColor = [NSColor colorWithWhite:0.95 alpha:1.0].CGColor;
    _hotkeyBtn.layer.cornerRadius = 4.0;
    _hotkeyBtn.font = [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold];
    [self addSubview:_hotkeyBtn];

    _bellEnableSwitch = [[PillSwitch alloc] initWithFrame:NSZeroRect];
    _bellEnableSwitch.target = self;
    _bellEnableSwitch.action = @selector(onBellEnableSwitch:);
    [self addSubview:_bellEnableSwitch];

    _noteStatus = [self label:@"Chuông đang tắt" font:[self fCaption] color:[Brand muted]];
    _noteStatus.lineBreakMode = NSLineBreakByWordWrapping;
    _noteStatus.maximumNumberOfLines = 2;
}

static NSString *StringFromHotkey(int hotkey) {
    if (hotkey == 0) return @"Chưa set";
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

- (void)updateHotkeyButtonTitle:(int)hotkey {
    NSString *title = StringFromHotkey(hotkey);
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    _hotkeyBtn.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
        NSForegroundColorAttributeName: [Brand teal],
        NSParagraphStyleAttributeName: style,
        NSFontAttributeName: [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold]
    }];
}

- (void)onHotkeyClick:(id)sender {
    NSResponder *next = self.nextResponder;
    PanelViewController *panelVC = nil;
    while (next != nil) {
        if ([next isKindOfClass:[PanelViewController class]]) {
            panelVC = (PanelViewController *)next;
            break;
        }
        next = next.nextResponder;
    }
    
    if (!panelVC) return;
    
    if (panelVC.isRecordingHotkey) {
        panelVC.isRecordingHotkey = NO;
        panelVC.onHotkeyRecorded = nil;
        extern int vBellHotkey;
        [self updateHotkeyButtonTitle:vBellHotkey];
        return;
    }
    
    panelVC.isRecordingHotkey = YES;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    _hotkeyBtn.attributedTitle = [[NSAttributedString alloc] initWithString:@"..." attributes:@{
        NSForegroundColorAttributeName: [NSColor systemRedColor],
        NSParagraphStyleAttributeName: style,
        NSFontAttributeName: [NSFont systemFontOfSize:11.5 weight:NSFontWeightBold]
    }];
    
    __weak BellSettingsView *weakSelf = self;
    __weak PanelViewController *weakVC = panelVC;
    panelVC.onHotkeyRecorded = ^(NSEvent *event) {
        weakVC.isRecordingHotkey = NO;
        weakVC.onHotkeyRecorded = nil;
        
        if (event.keyCode == 53) { // Esc
            extern int vBellHotkey;
            [weakSelf updateHotkeyButtonTitle:vBellHotkey];
            return;
        }
        
        int newHotkey = 0;
        if (event.modifierFlags & NSEventModifierFlagControl) newHotkey |= 0x100;
        if (event.modifierFlags & NSEventModifierFlagOption)  newHotkey |= 0x200;
        if (event.modifierFlags & NSEventModifierFlagCommand) newHotkey |= 0x400;
        if (event.modifierFlags & NSEventModifierFlagShift)   newHotkey |= 0x800;
        
        newHotkey |= (event.keyCode & 0xFF);
        NSString *chars = [event.charactersIgnoringModifiers lowercaseString];
        if (chars.length > 0) {
            unichar c = [chars characterAtIndex:0];
            newHotkey |= ((unsigned int)c << 24);
        }
        
        extern int vBellHotkey;
        vBellHotkey = newHotkey;
        [[NSUserDefaults standardUserDefaults] setInteger:newHotkey forKey:@"BellToggleHotkey"];
        
        [weakSelf updateHotkeyButtonTitle:vBellHotkey];
    };
}

- (void)onBellEnableSwitch:(PillSwitch *)sender {
    BOOL on = sender.isOn;
    extern int vBell;
    vBell = on ? 1 : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:vBell forKey:@"vBell"];
    BellMac_ApplySettings();
    [self updateStatusLabel];
    [self notifyLayoutChanged];
}

- (void)updateStatusLabel {
    extern int vBell;
    if (!vBell) {
        _noteStatus.stringValue = @"Chuông đang tắt";
        return;
    }
    
    int minutes = BellMac_MinutesUntilNextRing();
    NSDate *nextDate = BellMac_NextRingDate();
    if (minutes >= 0 && nextDate != nil) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"HH:mm";
        NSString *timeStr = [df stringFromDate:nextDate];
        _noteStatus.stringValue = [NSString stringWithFormat:@"Dự kiến reo lúc: %@ (còn %d phút)", timeStr, minutes];
    } else {
        _noteStatus.stringValue = @"Chuông đang bật (chưa lên lịch reo)";
    }
}

- (void)buildIntervalSection {
    _ebInterval = [NSTextField mk_eyebrowLabelWithTitle:@"Nhịp"];
    [self addSubview:_ebInterval];
    _cardInterval = [self addCard];

    _lblInterval = [self label:@"Chuông định kỳ mỗi" font:[self fFieldLbl] color:[Brand muted]];
    
    _intervalSeg = [[MKSegmented alloc] initWithFrame:NSZeroRect];
    _intervalSeg.titles = @[@"15", @"30", @"60"];
    _intervalSeg.target = self;
    _intervalSeg.action = @selector(onInterval:);
    [self addSubview:_intervalSeg];

    _noteInterval = [self label:@"Cứ mỗi nhịp chuông, app ghi một điểm lên dòng sông cảm xúc ở tab Hôm nay. Một nhịp, hai vai."
                           font:[self fCaption] color:[Brand muted]];
    _noteInterval.lineBreakMode = NSLineBreakByWordWrapping;
    _noteInterval.maximumNumberOfLines = 3;
}



- (void)buildSoundSection {
    _ebSound = [NSTextField mk_eyebrowLabelWithTitle:@"Âm thanh"];
    [self addSubview:_ebSound];
    _cardSound = [self addCard];

    _lblSound = [self label:@"Bộ tiếng" font:[self fFieldLbl] color:[Brand muted]];
    
    // Nút hình ảnh (3 loại chuông)
    _btnBell1 = [self createBellButtonWithTag:0 image:@"bell_temple"];
    _btnBell2 = [self createBellButtonWithTag:1 image:@"bell_chime"];
    _btnBell3 = [self createBellButtonWithTag:2 image:@"bell_wind"];
    [self addSubview:_btnBell1];
    [self addSubview:_btnBell2];
    [self addSubview:_btnBell3];

    // Dấu chấm cam báo hiệu trạng thái được chọn
    // [MINDFUL] Epic 3 G2 (F7) — trước đây [Brand orange]: chấm này di chuyển theo _bellSelectedIndex
    // (xem dòng ~585-596), tức là chấm ĐÁNH DẤU ĐANG CHỌN, không phải CTA. DESIGN.md §5 điều 6:
    // "Cam CHỈ ở CTA + link active. Không ở trạng thái ON/OFF" — đổi sang teal, khớp đúng cách
    // MKSegmented (cùng file) đã tô ô-đang-chọn của Nhịp chuông, không phải quyết định nhận diện mới.
    _bellIndicator = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 12, 12)];
    _bellIndicator.wantsLayer = YES;
    _bellIndicator.layer.backgroundColor = [Brand teal].CGColor;
    _bellIndicator.layer.cornerRadius = 6.0;
    [self addSubview:_bellIndicator];

    _lblVolume = [self label:@"Âm lượng" font:[self fFieldLbl] color:[Brand muted]];
    _volume = [NSSlider sliderWithValue:0.6 minValue:0.0 maxValue:1.0
                                 target:self action:@selector(onVolume:)];
    _volume.numberOfTickMarks = 0;
    // Track fill = 1 hue teal (HIẾN CHƯƠNG: cấm cam/gradient cho track). trackFillColor có từ 10.12.2.
    if ([_volume respondsToSelector:@selector(setTrackFillColor:)]) {
        _volume.trackFillColor = [Brand teal];
    }
    [self addSubview:_volume];
}

- (void)buildQuietSection {
    _ebQuiet = [NSTextField mk_eyebrowLabelWithTitle:@"Yên lặng"];
    [self addSubview:_ebQuiet];
    _cardQuiet = [self addCard];

    _lblQuiet = [self label:@"Giờ yên lặng" font:[self fFieldLbl] color:[Brand muted]];
    _quietFrom = [self timeChip];
    _arrow = [self label:@"→" font:[self fFieldLbl] color:[Brand muted]];
    _quietTo = [self timeChip];
    _quietError = [self label:@"Khoảng giờ chưa hợp lệ" font:[self fCaption] color:[Brand muted]];
    _quietError.hidden = YES;   // ẩn khi hợp lệ; caption trung tính, KHÔNG đỏ

    _lblFocus = [self label:@"Đồng bộ Chế độ Tập trung" font:[NSFont systemFontOfSize:12 weight:NSFontWeightSemibold] color:[Brand charcoal]];
    _focusSwitch = [[PillSwitch alloc] initWithFrame:NSZeroRect];
    _focusSwitch.target = self;
    _focusSwitch.action = @selector(onFocusSwitch:);
    [self addSubview:_focusSwitch];

    _focusExplain = [self label:@"Ứng dụng sẽ đọc trạng thái Chế độ Tập trung của macOS để tự áp giờ yên lặng — cần cấp quyền, mặc định tắt."
                           font:[self fCaption] color:[Brand muted]];
    _focusExplain.lineBreakMode = NSLineBreakByWordWrapping;
    _focusExplain.maximumNumberOfLines = 3;
    _focusExplain.hidden = YES;   // chỉ hiện khi bật (giải thích quyền hiện SAU khi bật)
}

- (NSTextField *)timeChip {
    NSTextField *f = [[NSTextField alloc] initWithFrame:NSZeroRect];
    f.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
    f.textColor = [Brand charcoal];
    f.alignment = NSTextAlignmentCenter;
    f.bordered = NO;
    f.wantsLayer = YES;
    f.layer.cornerRadius = 8.0;
    f.layer.borderWidth = 1.0;
    f.layer.borderColor = [Brand divider].CGColor;
    f.backgroundColor = [NSColor whiteColor];
    f.drawsBackground = YES;
    f.delegate = self;   // commit khi rời ô (controlTextDidEndEditing:)
    [self addSubview:f];
    return f;
}

#pragma mark - State load / persist

- (void)refresh {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];

    // Trạng thái bật chuông
    extern int vBell;
    BOOL bellEnabled = (vBell != 0);
    [_bellEnableSwitch setOn:bellEnabled animated:NO];
    [self updateStatusLabel];

    extern int vBellHotkey;
    [self updateHotkeyButtonTitle:vBellHotkey];

    // Nhịp
    extern int vBellInterval;
    int curInterval = vBellInterval > 0 ? vBellInterval : (int)[d integerForKey:@"vBellInterval"];
    if (curInterval <= 0) curInterval = 60; // Mặc định 60
    
    NSInteger bestIdx = 2; // "60"
    if (abs(curInterval - 15) < abs(curInterval - 30) && abs(curInterval - 15) < abs(curInterval - 60)) bestIdx = 0;
    else if (abs(curInterval - 30) < abs(curInterval - 60)) bestIdx = 1;
    
    _intervalSeg.selectedIndex = bestIdx;


    // Âm thanh
    NSString *sound = [d stringForKey:kKeySoundName] ?: SoundNameForIndex(0);
    _bellSelectedIndex = IndexForSoundName(sound);
    [self updateBellIndicatorAnimated:NO];

    // Âm lượng
    double vol = [d objectForKey:kKeyVolume] ? [d doubleForKey:kKeyVolume] : 0.6;
    _volume.doubleValue = vol;

    // Giờ yên lặng (đảo chiều từ vBellFrom/vBellTo). Default vBellFrom=8, vBellTo=22
    // ⇒ chuông reo 8–22, yên lặng 22–8 ⇒ quietFrom=22, quietTo=8.
    NSInteger bellFrom = [d objectForKey:kKeyBellFrom] ? [d integerForKey:kKeyBellFrom] : 8;
    NSInteger bellTo   = [d objectForKey:kKeyBellTo]   ? [d integerForKey:kKeyBellTo]   : 22;
    _quietFromHour = bellTo;    // giờ bắt đầu yên lặng = giờ chuông ngừng được phép reo
    _quietToHour   = bellFrom;  // giờ kết thúc yên lặng = giờ chuông bắt đầu được phép reo
    _quietInvalid = NO;
    _quietError.hidden = YES;
    [self syncQuietFields];

    // Focus sync — mặc định OFF.
    BOOL focus = [d boolForKey:kKeyFocusSync];
    [_focusSwitch setOn:focus animated:NO];
    _focusExplain.hidden = !focus;

    self.needsLayout = YES;
}



- (void)syncQuietFields {
    _quietFrom.stringValue = [NSString stringWithFormat:@"%02ld:00", (long)_quietFromHour];
    _quietTo.stringValue   = [NSString stringWithFormat:@"%02ld:00", (long)_quietToHour];
}

#pragma mark - Actions

- (void)onInterval:(MKSegmented *)sender {
    int minutes = 60;
    if (sender.selectedIndex == 0) minutes = 15;
    else if (sender.selectedIndex == 1) minutes = 30;
    
    extern int vBellInterval;
    vBellInterval = minutes;
    [[NSUserDefaults standardUserDefaults] setInteger:minutes forKey:@"vBellInterval"];
    BellMac_ApplySettings();
}


- (NSButton *)createBellButtonWithTag:(NSInteger)tag image:(NSString *)imageName {
    NSButton *btn = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 48, 48)];
    btn.buttonType = NSButtonTypeMomentaryChange;
    btn.bordered = NO;
    btn.imagePosition = NSImageOnly;
    // Tạm thời dùng chung ảnh bell1.png hoặc hình tròn nếu ko load được
    NSImage *img = [NSImage imageNamed:imageName];
    if (!img) {
        img = [[NSImage alloc] initWithSize:NSMakeSize(48, 48)];
        [img lockFocus];
        [[NSColor colorWithWhite:0.9 alpha:1.0] setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(2, 2, 44, 44)] fill];
        [img unlockFocus];
    }
    // bell1.png là ảnh nguồn 1024x1024 — PHẢI ép lại size logic về
    // đúng khung nút (48x48), nếu không AppKit vẽ ảnh tràn khỏi nút ra ngoài popover.
    img.size = NSMakeSize(48, 48);
    btn.image = img;
    btn.target = self;
    btn.action = @selector(onBellClick:);
    btn.tag = tag;
    return btn;
}

- (void)updateBellIndicatorAnimated:(BOOL)animated {
    CGFloat btnSize = 48.0;
    CGFloat gap = 24.0;
    CGFloat startX = (self.bounds.size.width - (3 * btnSize + 2 * gap)) / 2.0;
    CGFloat targetX = startX + _bellSelectedIndex * (btnSize + gap) + (btnSize - 12.0) / 2.0;
    
    NSRect currentFrame = _bellIndicator.frame;
    currentFrame.origin.x = targetX;
    
    if (animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            context.duration = 0.25;
            _bellIndicator.animator.frame = currentFrame;
        }];
    } else {
        _bellIndicator.frame = currentFrame;
    }
}

- (void)onBellClick:(NSButton *)sender {
    _bellSelectedIndex = sender.tag;
    [self updateBellIndicatorAnimated:YES];
    
    [[NSUserDefaults standardUserDefaults] setObject:SoundNameForIndex(_bellSelectedIndex)
                                              forKey:kKeySoundName];
    BellMac_PreviewSound();
}

- (void)onVolume:(NSSlider *)sender {
    [[NSUserDefaults standardUserDefaults] setDouble:sender.doubleValue forKey:kKeyVolume];
    // Lưu liên tục khi kéo, nhưng chỉ NGHE THỬ lúc thả tay (tránh phát âm dồn dập).
    if ([NSApp currentEvent].type == NSEventTypeLeftMouseUp) {
        BellMac_PreviewSound();
    }
}

- (void)onFocusSwitch:(PillSwitch *)sender {
    BOOL on = sender.isOn;
    // Giải thích quyền hiện NGAY khi bật (không có đường tự bật ngầm); giá trị đổi cùng lúc user chủ động bật.
    _focusExplain.hidden = !on;
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:kKeyFocusSync];
    [self notifyLayoutChanged];
}

// Commit giờ yên lặng khi rời ô. Validate chồng chéo TRƯỚC khi ghi; lỗi → giữ giá trị cũ.
- (void)controlTextDidEndEditing:(NSNotification *)note {
    if (note.object != _quietFrom && note.object != _quietTo) return;

    NSInteger fr = ParseHour(_quietFrom.stringValue);
    NSInteger to = ParseHour(_quietTo.stringValue);

    if (fr < 0 || to < 0 || fr == to) {
        // Vô lý (không đọc được / bắt đầu == kết thúc): caption trung tính, GIỮ giá trị cũ.
        _quietInvalid = YES;
        _quietError.hidden = NO;
        [self syncQuietFields];       // trả ô về giá trị hợp lệ cũ, không tự "sửa hộ" âm thầm
        [self notifyLayoutChanged];
        return;
    }

    _quietFromHour = fr;
    _quietToHour = to;
    BOOL wasInvalid = _quietInvalid;
    _quietInvalid = NO;
    _quietError.hidden = YES;
    [self syncQuietFields];

    // MAP ĐẢO CHIỀU (story 1.5 Dev Notes #3): isInBellRange dùng [vBellFrom,vBellTo] = giờ chuông
    // ĐƯỢC PHÉP reo. "Giờ yên lặng" là phần bù ⇒ vBellFrom = quietTo, vBellTo = quietFrom.
    // ĐỪNG "sửa lại cho giống tên biến" — sẽ khiến chuông reo NGƯỢC lúc lẽ ra yên lặng.
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setInteger:_quietToHour   forKey:kKeyBellFrom];
    [d setInteger:_quietFromHour forKey:kKeyBellTo];

    extern int vBellFrom;
    extern int vBellTo;
    vBellFrom = (int)_quietToHour;
    vBellTo = (int)_quietFromHour;
    BellMac_ApplySettings();

    if (wasInvalid) [self notifyLayoutChanged];
}

- (void)notifyLayoutChanged {
    self.needsLayout = YES;
    if (self.onLayoutChanged) self.onLayoutChanged();
}

#pragma mark - Layout

- (CGFloat)preferredHeight { return [self relayout:NO]; }

- (void)layout {
    [super layout];
    [self relayout:YES];
}

// Đi từ ĐỈNH view xuống (top = khoảng cách tính từ mép trên). Khi apply=YES thì set frame, dùng
// self.bounds.height để đổi sang toạ độ AppKit (gốc dưới-trái). Trả về tổng chiều cao cần.
- (CGFloat)relayout:(BOOL)apply {
    CGFloat W = NSWidth(self.bounds);
    CGFloat H = NSHeight(self.bounds);
    CGFloat top = 0;

#define SET(v, x, t, w, h) if (apply) { (v).frame = NSMakeRect((x), H - (t) - (h), (w), (h)); }

    // ---- Trạng thái (Status) ----
    SET(_ebStatus, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat statusTop = top;
    CGFloat cy = kCardPadY;

    SET(_lblBellEnable, kCardPadX, statusTop + cy, W - kCardPadX - 60.0, kRowH);
    if (apply) {
        _bellEnableSwitch.frame = NSMakeRect(W - kCardPadX - 40.0, H - (statusTop + cy) - kRowH + (kRowH - kSwitchH) / 2.0, 40.0, kSwitchH);
    }
    cy += kRowH + kGapSm;
    // noteStatus hiển thị thông tin thời gian reo chuông kế tiếp
    if (apply) {
        [self updateStatusLabel];
    }
    SET(_noteStatus, kCardPadX, statusTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardStatus, 0, statusTop, W, cy);
    top = statusTop + cy + kSectionGap;

    // ---- Nhịp ----
    SET(_ebInterval, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat intervalTop = top;
    cy = kCardPadY;

    SET(_lblInterval, kCardPadX, intervalTop + cy, W - 2 * kCardPadX, kRowH);
    cy += kRowH + kGapSm;
    SET(_intervalSeg, kCardPadX, intervalTop + cy, W - 2 * kCardPadX, kSegH);
    cy += kSegH + kGapSm;
    SET(_noteInterval, kCardPadX, intervalTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardInterval, 0, intervalTop, W, cy);
    top = intervalTop + cy + kSectionGap;



    // ---- Âm thanh ----
    SET(_ebSound, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat soundTop = top;
    cy = kCardPadY;

    SET(_lblSound, kCardPadX, soundTop + cy, 90.0, kRowH);
    cy += kRowH + kGapSm; // khoảng cách sau nhãn
    
    CGFloat btnSize = 48.0;
    CGFloat gap = 24.0;
    CGFloat startX = (W - (3 * btnSize + 2 * gap)) / 2.0;
    
    SET(_btnBell1, startX, soundTop + cy, btnSize, btnSize);
    SET(_btnBell2, startX + btnSize + gap, soundTop + cy, btnSize, btnSize);
    SET(_btnBell3, startX + 2 * btnSize + 2 * gap, soundTop + cy, btnSize, btnSize);
    
    cy += btnSize + 8.0; // Khoảng cách tới dấu chấm
    SET(_bellIndicator, 0, soundTop + cy, 12, 12);
    [self updateBellIndicatorAnimated:NO];
    
    cy += 12.0 + kGapMd;
    SET(_lblVolume, kCardPadX, soundTop + cy, 74.0, kRowH);
    CGFloat volX = kCardPadX + 74.0 + 10.0;
    SET(_volume, volX, soundTop + cy + (kRowH - 20.0) / 2.0, W - kCardPadX - volX, 20.0);
    cy += kRowH + kCardPadY;
    SET(_cardSound, 0, soundTop, W, cy);
    top = soundTop + cy + kSectionGap;

    // ---- Yên lặng ----
    SET(_ebQuiet, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat quietTop = top;
    cy = kCardPadY;

    SET(_lblQuiet, kCardPadX, quietTop + cy, kLabelWQ, kRowH);
    CGFloat ctlX = kCardPadX + kLabelWQ + 10.0;
    if (apply) {
        CGFloat chipW = 62.0, arrowW = 18.0;
        CGFloat rowY = H - (quietTop + cy) - kRowH;
        _quietFrom.frame = NSMakeRect(ctlX, rowY, chipW, kRowH);
        _arrow.frame = NSMakeRect(ctlX + chipW + 6.0, rowY + (kRowH - 16.0) / 2.0, arrowW, 16.0);
        _quietTo.frame = NSMakeRect(ctlX + chipW + 6.0 + arrowW + 6.0, rowY, chipW, kRowH);
    }
    cy += kRowH;
    if (!_quietError.hidden) {
        cy += 4.0;
        SET(_quietError, ctlX, quietTop + cy, W - kCardPadX - ctlX, kInvalidH);
        cy += kInvalidH;
    }
    cy += kGapMd;

    SET(_lblFocus, kCardPadX, quietTop + cy, W - kCardPadX - 60.0, kRowH);
    if (apply) {
        _focusSwitch.frame = NSMakeRect(W - kCardPadX - 40.0, H - (quietTop + cy) - kRowH + (kRowH - kSwitchH) / 2.0, 40.0, kSwitchH);
    }
    cy += kRowH;
    if (!_focusExplain.hidden) {
        cy += 6.0;
        SET(_focusExplain, kCardPadX, quietTop + cy, W - 2 * kCardPadX, kExplainH);
        cy += kExplainH;
    }
    cy += kCardPadY;
    SET(_cardQuiet, 0, quietTop, W, cy);
    top = quietTop + cy;

#undef SET
    return top;
}

@end

@implementation SensitivityCardView {
    NSTextField *_ebIdentify;
    NSView      *_cardIdentify;
    NSTextField *_lblSensitivity;
    MKSegmented *_seg;
    NSInteger    _sensitivity;          // 1..3
    EmotionWaveView *_demoWave;
    NSTextField *_noteIdentify;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.wantsLayer = YES;
        [self buildIdentifySection];
        [self refresh];
    }
    return self;
}

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

- (NSFont *)fFieldLbl { return [NSFont systemFontOfSize:12 weight:NSFontWeightRegular]; }
- (NSFont *)fCaption  { return [NSFont systemFontOfSize:11.5 weight:NSFontWeightRegular]; }

- (NSView *)addCard {
    NSView *v = [[NSView alloc] initWithFrame:NSZeroRect];
    [v applyThinCardStyle];
    [self addSubview:v];
    return v;
}

- (void)buildIdentifySection {
    _ebIdentify = [NSTextField mk_eyebrowLabelWithTitle:@"Nhận diện"];
    [self addSubview:_ebIdentify];
    _cardIdentify = [self addCard];

    _lblSensitivity = [self label:@"Độ nhạy" font:[self fFieldLbl] color:[Brand muted]];
    _demoWave = [[EmotionWaveView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_demoWave];

    _seg = [[MKSegmented alloc] initWithFrame:NSZeroRect];
    _seg.titles = @[@"Ít nhạy", @"Vừa", @"Nhạy"];
    _seg.target = self;
    _seg.action = @selector(onSensitivity:);
    [self addSubview:_seg];

    _noteIdentify = [self label:@"Quyết định khi nào mặt hồ được coi là gợn — dùng chung cho nhật ký lấy mẫu và chuông."
                           font:[self fCaption] color:[Brand muted]];
    _noteIdentify.lineBreakMode = NSLineBreakByWordWrapping;
    _noteIdentify.maximumNumberOfLines = 3;
}

- (void)onSensitivity:(MKSegmented *)sender {
    [self setSensitivity:sender.selectedIndex + 1 persist:YES];
}

- (void)setSensitivity:(NSInteger)s persist:(BOOL)persist {
    _sensitivity = s;
    _seg.selectedIndex = s - 1;
    
    // Đổi sóng nhỏ gợn động
    CGFloat amp = (s == 1) ? 0.2 : (s == 2 ? 0.5 : 0.85);
    [_demoWave setAmplitude:amp animated:YES];

    if (persist) {
        [[NSUserDefaults standardUserDefaults] setInteger:s forKey:kKeySensitivity];
    }
}

- (void)refresh {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSInteger sens = [d objectForKey:kKeySensitivity] ? [d integerForKey:kKeySensitivity] : 2;
    if (sens < 1 || sens > 3) sens = 2;
    [self setSensitivity:sens persist:NO];
}

- (void)layout {
    [super layout];
    [self relayout:YES];
}

- (CGFloat)preferredHeight {
    return [self relayout:NO];
}

- (CGFloat)relayout:(BOOL)apply {
    CGFloat W = NSWidth(self.bounds);
    CGFloat H = NSHeight(self.bounds);
    CGFloat top = 0;

#define SET(v, x, t, w, h) if (apply) { (v).frame = NSMakeRect((x), H - (t) - (h), (w), (h)); }

    SET(_ebIdentify, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat identifyTop = top;
    CGFloat cy = kCardPadY;

    SET(_lblSensitivity, kCardPadX, identifyTop + cy, 90.0, kRowH);
    CGFloat waveW = 64.0, waveH = 18.0;
    SET(_demoWave, W - kCardPadX - waveW, identifyTop + cy + (kRowH - waveH) / 2.0, waveW, waveH);
    cy += kRowH + kGapSm;
    SET(_seg, kCardPadX, identifyTop + cy, W - 2 * kCardPadX, kSegH);
    cy += kSegH + kGapSm;
    SET(_noteIdentify, kCardPadX, identifyTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardIdentify, 0, identifyTop, W, cy);
    
    return identifyTop + cy;
#undef SET
}

@end
