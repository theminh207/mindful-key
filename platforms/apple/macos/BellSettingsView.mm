//
//  BellSettingsView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.5 — xem BellSettingsView.h cho hợp đồng + ràng buộc hiến chương.
//
//  Gate "mô tả hay phán xét?" (HIẾN CHƯƠNG §5.8) — mọi copy trong file này đã tự soi:
//    "Ít nhạy/Vừa/Nhạy", "Giờ yên lặng", "Khoảng giờ chưa hợp lệ", "Đồng bộ Chế độ Tập trung",
//    "…cần cấp quyền, mặc định tắt", "câu căng liên tiếp trước khi chuông rung" — đều MÔ TẢ
//    thiết lập/hành vi, KHÔNG khiển trách/thúc ép người dùng. ✅
//

#import "BellSettingsView.h"
#import "BrandControls.h"
#import "BrandColors.h"
#import "EmotionWaveView.h"
#import "NudgeCoordinatorMac.h"

// UserDefaults keys (story 1.5). Đặt cạnh nhau để không rải magic-string.
static NSString *const kKeySensitivity = @"vBellSensitivity"; // int 1..3
static NSString *const kKeySoundName   = @"vBellSoundName";    // NSString (tên NSSound hệ thống)
static NSString *const kKeyVolume      = @"vBellVolume";       // float 0..1
static NSString *const kKeyFocusSync   = @"vBellFocusSync";    // bool
static NSString *const kKeyBellFrom    = @"vBellFrom";         // int giờ — chuông ĐƯỢC PHÉP reo (từ)
static NSString *const kKeyBellTo      = @"vBellTo";           // int giờ — chuông ĐƯỢC PHÉP reo (đến)

// Layout (điểm). Lưới 8px NOW BRAND OS; label cột trái 74px như DESIGN §1.4 / mockup .field.
static const CGFloat kPad       = 16.0;
static const CGFloat kLabelW    = 74.0;
static const CGFloat kLC        = 10.0;   // gap label↔control
static const CGFloat kFieldGap  = 12.0;   // gap giữa các field
static const CGFloat kTitleH    = 20.0;
static const CGFloat kSegH      = 28.0;
static const CGFloat kDemoH     = 20.0;
static const CGFloat kRowH      = 26.0;   // sound/volume/quiet row
static const CGFloat kToggleH   = 22.0;
static const CGFloat kAdvBtnH   = 18.0;
static const CGFloat kExplainH  = 44.0;
static const CGFloat kAdvPanelH = 46.0;
static const CGFloat kInvalidH  = 16.0;

// Ánh xạ nhãn thân thiện (mockup) → tên NSSound hệ thống thật (dùng khi nối audio ở việc kế).
static NSString *SoundNameForIndex(NSInteger i) {
    switch (i) { case 1: return @"Tink"; case 2: return @"Pop"; default: return @"Glass"; }
}
static NSInteger IndexForSoundName(NSString *name) {
    if ([name isEqualToString:@"Tink"]) return 1;
    if ([name isEqualToString:@"Pop"])  return 2;
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
    NSTextField *_title;

    // Độ nhạy
    NSTextField *_lblSensitivity;
    MKSegmented *_seg;
    NSInteger    _sensitivity;          // 1..3
    EmotionWaveView *_demoWave;
    NSTextField *_demoCap;

    // Âm thanh
    NSTextField  *_lblSound;
    NSPopUpButton *_soundPopup;

    // Âm lượng
    NSTextField *_lblVolume;
    NSSlider    *_volume;

    // Giờ yên lặng
    NSTextField *_lblQuiet;
    NSTextField *_quietFrom;   // giờ bắt đầu yên lặng
    NSTextField *_arrow;
    NSTextField *_quietTo;      // giờ kết thúc yên lặng
    NSTextField *_quietError;
    NSInteger    _quietFromHour;
    NSInteger    _quietToHour;
    BOOL         _quietInvalid;

    // Focus sync
    NSTextField *_lblFocus;
    PillSwitch  *_focusSwitch;
    NSTextField *_focusExplain;

    // Nâng cao
    NSButton    *_advBtn;
    NSTextField *_advChevron;
    NSTextField *_advNumber;
    NSTextField *_advNote;
    BOOL         _advExpanded;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        // Card: nền trắng + viền divider 1px (nhỏ hơn Gác cổng, KHÔNG viền teal nhấn) — DESIGN §2.3.
        self.wantsLayer = YES;
        self.layer.cornerRadius = 16.0;
        self.layer.backgroundColor = [NSColor whiteColor].CGColor;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [Brand divider].CGColor;

        [self buildTitle];
        [self buildSensitivity];
        [self buildSound];
        [self buildVolume];
        [self buildQuietHours];
        [self buildFocusSync];
        [self buildAdvanced];

        [self refresh];
    }
    return self;
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

- (NSFont *)fBody     { return [NSFont systemFontOfSize:13 weight:NSFontWeightRegular]; }
- (NSFont *)fFieldLbl { return [NSFont systemFontOfSize:12 weight:NSFontWeightRegular]; }
- (NSFont *)fSemibold { return [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold]; }
- (NSFont *)fCaption  { return [NSFont systemFontOfSize:11 weight:NSFontWeightRegular]; }

#pragma mark - Build subviews

- (void)buildTitle {
    _title = [self label:@"Chuông"
                    font:[NSFont systemFontOfSize:14 weight:NSFontWeightSemibold]
                   color:[Brand charcoal]];
}

- (void)buildSensitivity {
    _lblSensitivity = [self label:@"Độ nhạy" font:[self fFieldLbl] color:[Brand muted]];
    _seg = [[MKSegmented alloc] initWithFrame:NSZeroRect];
    _seg.titles = @[@"Ít nhạy", @"Vừa", @"Nhạy"];
    _seg.target = self;
    _seg.action = @selector(onSensitivity:);
    [self addSubview:_seg];

    _demoWave = [[EmotionWaveView alloc] initWithFrame:NSZeroRect]; // thu gọn
    [self addSubview:_demoWave];
    _demoCap = [self label:@"xem thử mức" font:[self fCaption] color:[Brand muted]];
}

- (void)buildSound {
    _lblSound = [self label:@"Âm thanh" font:[self fFieldLbl] color:[Brand muted]];
    _soundPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [_soundPopup addItemsWithTitles:@[@"Tiếng chuông", @"Chuông gió", @"Giọt nước"]];
    _soundPopup.target = self;
    _soundPopup.action = @selector(onSound:);
    [self addSubview:_soundPopup];
}

- (void)buildVolume {
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

- (void)buildQuietHours {
    _lblQuiet = [self label:@"Giờ yên lặng" font:[self fFieldLbl] color:[Brand muted]];
    _quietFrom = [self timeChip];
    _arrow = [self label:@"→" font:[self fFieldLbl] color:[Brand muted]];
    _quietTo = [self timeChip];
    _quietError = [self label:@"Khoảng giờ chưa hợp lệ" font:[self fCaption] color:[Brand muted]];
    _quietError.hidden = YES;   // ẩn khi hợp lệ; caption trung tính, KHÔNG đỏ
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

- (void)buildFocusSync {
    _lblFocus = [self label:@"Đồng bộ Chế độ Tập trung" font:[self fSemibold] color:[Brand charcoal]];
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

- (void)buildAdvanced {
    _advBtn = [NSButton buttonWithTitle:@"Tùy chỉnh nâng cao" target:self action:@selector(onAdvanced:)];
    _advBtn.bordered = NO;
    _advBtn.font = [self fSemibold];
    ((NSButtonCell *)_advBtn.cell).backgroundColor = [NSColor clearColor];
    _advBtn.attributedTitle = [[NSAttributedString alloc] initWithString:@"Tùy chỉnh nâng cao"
        attributes:@{ NSForegroundColorAttributeName:[Brand muted], NSFontAttributeName:[self fSemibold] }];
    [self addSubview:_advBtn];
    _advChevron = [self label:@"▸" font:[self fSemibold] color:[Brand muted]];

    _advNumber = [self label:@"" font:[self fBody] color:[Brand charcoal]];
    _advNote = [self label:@"(giá trị đang áp dụng — chỉnh sâu hơn ở phần sau)"
                      font:[self fCaption] color:[Brand muted]];
    _advNumber.hidden = YES;
    _advNote.hidden = YES;
}

#pragma mark - State load / persist

- (void)refresh {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];

    // Độ nhạy — default 2 (Vừa) = ngưỡng 3 hiện hành (edge case story: cài mới ≈ hành vi cũ).
    NSInteger sens = [d objectForKey:kKeySensitivity] ? [d integerForKey:kKeySensitivity] : 2;
    if (sens < 1 || sens > 3) sens = 2;
    [self setSensitivity:sens persist:NO];

    // Âm thanh
    NSString *sound = [d stringForKey:kKeySoundName] ?: SoundNameForIndex(0);
    [_soundPopup selectItemAtIndex:IndexForSoundName(sound)];

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

    [self syncAdvancedNumber];
    self.needsLayout = YES;
}

- (void)setSensitivity:(NSInteger)s persist:(BOOL)persist {
    _sensitivity = s;
    _seg.selectedIndex = s - 1;
    // Sóng demo "thấy mức": ít→thấp, vừa→giữa, nhạy→cao (chỉ cảm giác, KHÔNG phải ngưỡng thật).
    CGFloat amp = (s == 1) ? 0.2 : (s == 2 ? 0.5 : 0.85);
    [_demoWave setAmplitude:amp animated:YES];

    if (persist) {
        [[NSUserDefaults standardUserDefaults] setInteger:s forKey:kKeySensitivity];
        [self syncAdvancedNumber];
    }
}

- (void)syncQuietFields {
    _quietFrom.stringValue = [NSString stringWithFormat:@"%02ld:00", (long)_quietFromHour];
    _quietTo.stringValue   = [NSString stringWithFormat:@"%02ld:00", (long)_quietToHour];
}

- (void)syncAdvancedNumber {
    int trigger = NudgeCoordinatorMac_TenseStreakTrigger();
    _advNumber.stringValue = [NSString stringWithFormat:@"%d câu căng liên tiếp trước khi chuông rung", trigger];
}

#pragma mark - Actions

- (void)onSensitivity:(MKSegmented *)sender {
    [self setSensitivity:sender.selectedIndex + 1 persist:YES];
}

- (void)onSound:(NSPopUpButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:SoundNameForIndex(sender.indexOfSelectedItem)
                                              forKey:kKeySoundName];
}

- (void)onVolume:(NSSlider *)sender {
    [[NSUserDefaults standardUserDefaults] setDouble:sender.doubleValue forKey:kKeyVolume];
}

- (void)onFocusSwitch:(PillSwitch *)sender {
    BOOL on = sender.isOn;
    // Giải thích quyền hiện NGAY khi bật (không có đường tự bật ngầm); giá trị đổi cùng lúc user chủ động bật.
    _focusExplain.hidden = !on;
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:kKeyFocusSync];
    [self notifyLayoutChanged];
}

- (void)onAdvanced:(NSButton *)sender {
    _advExpanded = !_advExpanded;
    _advChevron.stringValue = _advExpanded ? @"▾" : @"▸";
    _advNumber.hidden = !_advExpanded;
    _advNote.hidden = !_advExpanded;
    if (_advExpanded) [self syncAdvancedNumber];
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

// Đi từ ĐỈNH card xuống (top = khoảng cách tính từ mép trên). Khi apply=YES thì set frame, dùng
// self.bounds.height để đổi sang toạ độ AppKit (gốc dưới-trái). Trả về tổng chiều cao cần.
- (CGFloat)relayout:(BOOL)apply {
    CGFloat W = NSWidth(self.bounds);
    CGFloat H = NSHeight(self.bounds);
    CGFloat ctlX = kPad + kLabelW + kLC;
    CGFloat ctlW = MAX(40.0, W - ctlX - kPad);
    CGFloat top = kPad;

#define FRAMEAT(v, x, w, h, t) if (apply) { (v).frame = NSMakeRect((x), H - (t) - (h), (w), (h)); }

    // Tiêu đề
    FRAMEAT(_title, kPad, W - 2 * kPad, kTitleH, top);
    top += kTitleH + kFieldGap;

    // Độ nhạy: label (căn giữa hàng segmented) + segmented + hàng sóng demo dưới.
    FRAMEAT(_lblSensitivity, kPad, kLabelW, 16.0, top + (kSegH - 16.0) / 2.0);
    FRAMEAT(_seg, ctlX, ctlW, kSegH, top);
    CGFloat demoTop = top + kSegH + 6.0;
    FRAMEAT(_demoWave, ctlX, 64.0, kDemoH, demoTop);
    FRAMEAT(_demoCap, ctlX + 72.0, ctlW - 72.0, 14.0, demoTop + (kDemoH - 14.0) / 2.0);
    top += kSegH + 6.0 + kDemoH + kFieldGap;

    // Âm thanh
    FRAMEAT(_lblSound, kPad, kLabelW, 16.0, top + (kRowH - 16.0) / 2.0);
    FRAMEAT(_soundPopup, ctlX, ctlW, kRowH, top);
    top += kRowH + kFieldGap;

    // Âm lượng
    FRAMEAT(_lblVolume, kPad, kLabelW, 16.0, top + (kRowH - 16.0) / 2.0);
    FRAMEAT(_volume, ctlX, ctlW, 20.0, top + (kRowH - 20.0) / 2.0);
    top += kRowH + kFieldGap;

    // Giờ yên lặng: 2 chip + mũi tên
    FRAMEAT(_lblQuiet, kPad, kLabelW, 16.0, top + (kRowH - 16.0) / 2.0);
    if (apply) {
        CGFloat chipW = 62.0, arrowW = 18.0;
        _quietFrom.frame = NSMakeRect(ctlX, H - top - kRowH, chipW, kRowH);
        _arrow.frame = NSMakeRect(ctlX + chipW + 6.0, H - top - kRowH / 2.0 - 8.0, arrowW, 16.0);
        _quietTo.frame = NSMakeRect(ctlX + chipW + 6.0 + arrowW + 6.0, H - top - kRowH, chipW, kRowH);
    }
    top += kRowH;
    if (!_quietError.hidden) {
        top += 4.0;
        FRAMEAT(_quietError, ctlX, ctlW, kInvalidH, top);
        top += kInvalidH;
    }
    top += kFieldGap;

    // Focus sync: label trái + PillSwitch phải
    if (apply) {
        _focusSwitch.frame = NSMakeRect(W - kPad - 40.0, H - top - kToggleH + (kToggleH - 24.0) / 2.0, 40.0, 24.0);
    }
    FRAMEAT(_lblFocus, kPad, W - 2 * kPad - 48.0, 16.0, top + (kToggleH - 16.0) / 2.0);
    top += kToggleH;
    if (!_focusExplain.hidden) {
        top += 6.0;
        FRAMEAT(_focusExplain, kPad, W - 2 * kPad, kExplainH, top);
        top += kExplainH;
    }
    top += kFieldGap;

    // Nâng cao
    FRAMEAT(_advChevron, kPad, 12.0, kAdvBtnH, top);
    FRAMEAT(_advBtn, kPad + 14.0, 160.0, kAdvBtnH, top);
    top += kAdvBtnH;
    if (_advExpanded) {
        top += 8.0;
        FRAMEAT(_advNumber, kPad, W - 2 * kPad, 18.0, top);
        top += 18.0 + 2.0;
        FRAMEAT(_advNote, kPad, W - 2 * kPad, 14.0, top);
        top += 14.0 + (kAdvPanelH - 34.0);
    }

    top += kPad;
#undef FRAMEAT
    return top;
}

@end
