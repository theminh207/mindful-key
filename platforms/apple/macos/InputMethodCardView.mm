//
//  InputMethodCardView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] PHA 2 — thẻ "Bộ gõ" bung được trong panel: Kiểu gõ / Bảng mã / Gõ tiếng Việt +
//  các toggle gõ hằng ngày (chính tả, dấu oà·uý, viết hoa đầu câu, chuyển chế độ thông minh, gõ tắt).
//  Nối vào ĐÚNG hàm/key/global sẵn có (menu + ViewController đang dùng) — KHÔNG tự chế xử lý engine,
//  tránh gãy gõ tiếng Việt. Phần còn lại (macro editor, hệ thống, về) mở qua "Cài đặt đầy đủ ▸".
//

#import "InputMethodCardView.h"
#import "BrandControls.h"
#import "BrandColors.h"
#import "AppDelegate.h"
#import "OpenKeyManager.h"

// Cùng global/callback ViewController.m dùng cho các toggle (định nghĩa ở engine/OpenKey.mm).
extern AppDelegate* appDelegate;
extern "C" void OnSpellCheckingChanged(void);   // định nghĩa C ở OpenKey.mm → cần extern "C" trong .mm
extern int vCheckSpelling;
extern int vUpperCaseFirstChar;
extern int vUseSmartSwitchKey;
extern int vUseMacro;

// Ánh xạ key UserDefaults → biến global tương ứng (đúng như từng IBAction ViewController).
static int* GlobalForKey(NSString *key) {
    if ([key isEqualToString:@"Spelling"])           return &vCheckSpelling;
    if ([key isEqualToString:@"UpperCaseFirstChar"]) return &vUpperCaseFirstChar;
    if ([key isEqualToString:@"UseSmartSwitchKey"])  return &vUseSmartSwitchKey;
    if ([key isEqualToString:@"UseMacro"])           return &vUseMacro;
    return NULL;
}

static const CGFloat kPad     = 16.0;
static const CGFloat kHeaderH = 20.0;    // hàng "● Bộ gõ … ▸" (thu gọn — không dùng trong panel 3-tab)
static const CGFloat kLabelW  = 78.0;
static const CGFloat kLC      = 10.0;
static const CGFloat kRowH    = 26.0;
static const CGFloat kFieldGap= 12.0;
static const CGFloat kToggleH = 28.0;
static const CGFloat kLinkH   = 18.0;

// [MINDFUL] Áo mới v2 (2026-07-13) — 2 thẻ trắng viền mảnh có eyebrow, khớp target-v2-input.png.
static const CGFloat kEbH        = 13.0;
static const CGFloat kEbGap      = 8.0;
static const CGFloat kSectionGap = 16.0;
static const CGFloat kCardPadX   = 14.0;
static const CGFloat kCardPadY   = 13.0;

@implementation InputMethodCardView {
    StatusDot   *_dot;
    NSTextField *_title;
    NSTextField *_value;     // "Telex" hiện khi thu gọn
    NSTextField *_chevron;   // ▸ / ▾
    NSButton    *_hit;       // vùng bấm header → thu gọn/bung

    NSTextField  *_lblType;
    NSPopUpButton*_typePopup;
    NSTextField  *_lblCode;
    NSPopUpButton*_codePopup;
    NSTextField  *_lblVN;
    PillSwitch   *_vnSwitch;

    NSArray<NSDictionary *> *_toggleDefs;    // {t: nhãn, k: key, spell: có gọi OnSpellCheckingChanged}
    NSMutableArray<NSTextField *> *_toggleLabels;
    NSMutableArray<PillSwitch *>  *_toggleSwitches;

    NSButton     *_fullLink;
    BOOL _collapsed;
    BOOL _hideHeaderRow;   // [MINDFUL] popover 3-tab: ẩn hàng "● Bộ gõ ▸" khi đã có tab label riêng

    // [MINDFUL] Áo mới v2 — 2 thẻ trắng viền mảnh (KIỂU GÕ / TÙY CHỌN), chỉ dùng khi hideHeaderRow.
    NSTextField *_ebType;
    NSView      *_cardType;
    NSTextField *_ebOptions;
    NSView      *_cardOptions;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        // [MINDFUL] Compact (như Haynoi): KHÔNG vỏ card — mục nằm trên nền panel trắng, phân tách
        // bằng divider mảnh.
        self.wantsLayer = YES;
        _collapsed = YES;

        _dot = [[StatusDot alloc] initWithFrame:NSZeroRect];
        [self addSubview:_dot];
        _title   = [self label:@"Bộ gõ" font:[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold] color:[Brand charcoal]];
        _value   = [self label:@"Telex" font:[NSFont systemFontOfSize:12 weight:NSFontWeightRegular] color:[Brand muted]];
        _chevron = [self label:@"▸"     font:[NSFont systemFontOfSize:12 weight:NSFontWeightSemibold] color:[Brand muted]];

        _hit = [NSButton buttonWithTitle:@"" target:self action:@selector(onToggle:)];
        _hit.bordered = NO;
        ((NSButtonCell *)_hit.cell).backgroundColor = [NSColor clearColor];
        [self addSubview:_hit];

        // [MINDFUL] Áo mới v2 — 2 thẻ trắng viền mảnh: "KIỂU GÕ" (Kiểu gõ + Bảng mã) và "TÙY CHỌN"
        // (Gõ tiếng Việt + 4 toggle gõ hằng ngày). Chỉ dùng khi hideHeaderRow (panel 3-tab).
        _ebType = [NSTextField mk_eyebrowLabelWithTitle:@"Kiểu gõ"];
        [self addSubview:_ebType];
        _cardType = [[NSView alloc] initWithFrame:NSZeroRect];
        [_cardType applyThinCardStyle];
        [self addSubview:_cardType];

        _lblType = [self label:@"Kiểu gõ" font:[self fFieldLbl] color:[Brand muted]];
        _typePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        // [MINDFUL] Giữ NGUYÊN 4 lựa chọn thật của engine (KHÔNG gộp "Simple Telex 1/2" thành 1
        // "Đơn giản" như mockup — sẽ làm mất lựa chọn/đổi index đang lưu, phạm "tránh gãy gõ").
        [_typePopup addItemsWithTitles:@[@"Telex", @"VNI", @"Simple Telex 1", @"Simple Telex 2"]];
        _typePopup.target = self; _typePopup.action = @selector(onType:);
        [self addSubview:_typePopup];

        _lblCode = [self label:@"Bảng mã" font:[self fFieldLbl] color:[Brand muted]];
        _codePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        [_codePopup addItemsWithTitles:[OpenKeyManager getTableCodes]];
        _codePopup.target = self; _codePopup.action = @selector(onCode:);
        [self addSubview:_codePopup];

        _ebOptions = [NSTextField mk_eyebrowLabelWithTitle:@"Tùy chọn"];
        [self addSubview:_ebOptions];
        _cardOptions = [[NSView alloc] initWithFrame:NSZeroRect];
        [_cardOptions applyThinCardStyle];
        [self addSubview:_cardOptions];

        _lblVN = [self label:@"Gõ tiếng Việt" font:[NSFont systemFontOfSize:12 weight:NSFontWeightSemibold] color:[Brand charcoal]];
        _vnSwitch = [[PillSwitch alloc] initWithFrame:NSZeroRect];
        _vnSwitch.target = self; _vnSwitch.action = @selector(onVN:);
        [self addSubview:_vnSwitch];

        // Toggle gõ hằng ngày — key/global khớp đúng IBAction ViewController. [MINDFUL] Áo mới v2:
        // bỏ "Đặt dấu oà, uý (kiểu mới)" khỏi thẻ gọn này (vẫn còn ở "Cài đặt đầy đủ →") — khớp
        // đúng 5 switch mục tiêu (Gõ tiếng Việt + 4 mục dưới đây) trong target-v2-input.png.
        _toggleDefs = @[
            @{@"t":@"Kiểm tra chính tả",        @"k":@"Spelling",           @"spell":@YES},
            @{@"t":@"Viết hoa đầu câu",         @"k":@"UpperCaseFirstChar"},
            @{@"t":@"Chuyển chế độ thông minh",  @"k":@"UseSmartSwitchKey"},
            @{@"t":@"Gõ tắt (macro)",           @"k":@"UseMacro"},
        ];
        _toggleLabels = [NSMutableArray array];
        _toggleSwitches = [NSMutableArray array];
        for (NSUInteger i = 0; i < _toggleDefs.count; i++) {
            NSTextField *l = [self label:_toggleDefs[i][@"t"] font:[NSFont systemFontOfSize:12 weight:NSFontWeightRegular] color:[Brand charcoal]];
            [_toggleLabels addObject:l];
            PillSwitch *sw = [[PillSwitch alloc] initWithFrame:NSZeroRect];
            sw.tag = (NSInteger)i;
            sw.target = self; sw.action = @selector(onFeatureToggle:);
            [self addSubview:sw];
            [_toggleSwitches addObject:sw];
        }

        _fullLink = [NSButton buttonWithTitle:@"" target:self action:@selector(onFull:)];
        _fullLink.bordered = NO;
        ((NSButtonCell *)_fullLink.cell).backgroundColor = [NSColor clearColor];
        _fullLink.attributedTitle = [[NSAttributedString alloc] initWithString:@"Cài đặt đầy đủ ▸"
            attributes:@{ NSForegroundColorAttributeName:[Brand teal],
                          NSFontAttributeName:[NSFont systemFontOfSize:12 weight:NSFontWeightSemibold] }];
        [self addSubview:_fullLink];

        [self refresh];
    }
    return self;
}

- (NSTextField *)label:(NSString *)s font:(NSFont *)f color:(NSColor *)c {
    NSTextField *l = [NSTextField labelWithString:s];
    l.font = f; l.textColor = c; l.backgroundColor = [NSColor clearColor]; l.bordered = NO; l.editable = NO;
    [self addSubview:l];
    return l;
}
- (NSFont *)fFieldLbl { return [NSFont systemFontOfSize:12 weight:NSFontWeightRegular]; }

#pragma mark - State

- (void)refresh {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSInteger t = [d integerForKey:@"InputType"];
    if (t < 0 || t >= _typePopup.numberOfItems) t = 0;
    [_typePopup selectItemAtIndex:t];
    _value.stringValue = _typePopup.titleOfSelectedItem ?: @"Telex";

    NSInteger c = [d integerForKey:@"CodeTable"];
    if (c >= 0 && c < _codePopup.numberOfItems) [_codePopup selectItemAtIndex:c];

    BOOL vn = ([d integerForKey:@"InputMethod"] == 1);
    [_vnSwitch setOn:vn animated:NO];
    [_dot setOn:vn];

    for (NSUInteger i = 0; i < _toggleDefs.count; i++) {
        [_toggleSwitches[i] setOn:([d integerForKey:_toggleDefs[i][@"k"]] != 0) animated:NO];
    }

    [self applyCollapsedState];
    self.needsLayout = YES;
}

- (void)applyCollapsedState {
    BOOL c = _collapsed;
    _chevron.stringValue = c ? @"▸" : @"▾";
    _value.hidden = !c;   // giá trị inline chỉ hiện khi thu gọn (bung thì đã có dropdown)
    NSMutableArray<NSView *> *fields = [@[_lblType, _typePopup, _lblCode, _codePopup, _lblVN, _vnSwitch, _fullLink,
                                          _ebType, _cardType, _ebOptions, _cardOptions] mutableCopy];
    [fields addObjectsFromArray:_toggleLabels];
    [fields addObjectsFromArray:_toggleSwitches];
    for (NSView *v in fields) v.hidden = c;
}

- (CGFloat)preferredHeight {
    if (_hideHeaderRow) return [self relayoutCards:NO];
    if (_collapsed) return 48.0;
    CGFloat h = kPad;
    h += kHeaderH + kFieldGap;
    h += 3 * (kRowH + kFieldGap);                    // Kiểu gõ, Bảng mã, Gõ tiếng Việt
    h += _toggleDefs.count * kToggleH;               // các toggle
    h += kFieldGap + kLinkH + kPad;                  // link + đáy
    return h;
}

// [MINDFUL] Áo mới v2 — layout card-wrapped dùng khi hideHeaderRow (panel 3-tab, đường dùng
// THẬT DUY NHẤT hiện nay). apply=NO chỉ đo tổng chiều cao (preferredHeight), không set frame.
- (CGFloat)relayoutCards:(BOOL)apply {
    CGFloat W = NSWidth(self.bounds);
    CGFloat H = NSHeight(self.bounds);
    CGFloat top = 0;
    CGFloat ctlX = kCardPadX + kLabelW + kLC;
    CGFloat ctlW = MAX(60.0, W - ctlX - kCardPadX);

#define SET(v, x, t, w, h) if (apply) { (v).frame = NSMakeRect((x), H - (t) - (h), (w), (h)); }

    // ---- Kiểu gõ ----
    SET(_ebType, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat typeTop = top;
    CGFloat cy = kCardPadY;
    SET(_lblType, kCardPadX, typeTop + cy, kLabelW, kRowH);
    SET(_typePopup, ctlX, typeTop + cy, ctlW, kRowH);
    cy += kRowH + kFieldGap;
    SET(_lblCode, kCardPadX, typeTop + cy, kLabelW, kRowH);
    SET(_codePopup, ctlX, typeTop + cy, ctlW, kRowH);
    cy += kRowH + kCardPadY;
    SET(_cardType, 0, typeTop, W, cy);
    top = typeTop + cy + kSectionGap;

    // ---- Tùy chọn ---- (Gõ tiếng Việt + 4 toggle, 1 danh sách đều nhau — khớp target-v2-input.png)
    SET(_ebOptions, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat optTop = top;
    cy = kCardPadY;
    CGFloat rowGap = 10.0;

    SET(_lblVN, kCardPadX, optTop + cy, W - kCardPadX - 60.0, kToggleH);
    if (apply) {
        _vnSwitch.frame = NSMakeRect(W - kCardPadX - 40.0,
                                     H - (optTop + cy) - kToggleH + (kToggleH - 24.0) / 2.0, 40.0, 24.0);
    }
    cy += kToggleH + rowGap;

    for (NSUInteger i = 0; i < _toggleDefs.count; i++) {
        SET(_toggleLabels[i], kCardPadX, optTop + cy, W - kCardPadX - 60.0, kToggleH);
        if (apply) {
            _toggleSwitches[i].frame = NSMakeRect(W - kCardPadX - 40.0,
                                                  H - (optTop + cy) - kToggleH + (kToggleH - 24.0) / 2.0, 40.0, 24.0);
        }
        cy += kToggleH + ((i + 1 < _toggleDefs.count) ? rowGap : 0.0);
    }
    cy += kCardPadY;
    SET(_cardOptions, 0, optTop, W, cy);
    top = optTop + cy + kSectionGap;

    // "Cài đặt đầy đủ →" — teal, canh giữa (khớp mockup, khác bản cũ canh trái).
    NSSize ls = _fullLink.attributedTitle.size;
    SET(_fullLink, (W - ls.width) / 2.0, top, ls.width, kLinkH);
    top += kLinkH;

#undef SET
    return top;
}

#pragma mark - Actions (nối hàm/key/global sẵn có — KHÔNG tự chế)

- (void)onToggle:(id)sender {
    _collapsed = !_collapsed;
    [self applyCollapsedState];
    self.needsLayout = YES;
    if (self.onLayoutChanged) self.onLayoutChanged();
}

// [MINDFUL] popover 3-tab — xem InputMethodCardView.h. Gọi 1 lần lúc tạo view; không đổi logic
// nối global/UserDefaults (onType/onCode/onVN/onFeatureToggle... nguyên vẹn).
- (void)expandForTabPresentation {
    _hideHeaderRow = YES;
    _collapsed = NO;
    _dot.hidden = YES;
    _title.hidden = YES;
    _value.hidden = YES;
    _chevron.hidden = YES;
    _hit.hidden = YES;
    [self applyCollapsedState];
    self.needsLayout = YES;
    if (self.onLayoutChanged) self.onLayoutChanged();
}

- (void)onType:(NSPopUpButton *)sender {
    [appDelegate onInputTypeSelectedIndex:(int)sender.indexOfSelectedItem];
    _value.stringValue = sender.titleOfSelectedItem ?: @"Telex";
}

- (void)onCode:(NSPopUpButton *)sender {
    [appDelegate onCodeTableChanged:(int)sender.indexOfSelectedItem];
}

- (void)onVN:(PillSwitch *)sender {
    [appDelegate onInputMethodSelected];   // toggle Việt/Anh (đúng path menu "Bật Tiếng Việt")
    BOOL vn = ([[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"] == 1);
    [_vnSwitch setOn:vn animated:NO];       // đồng bộ lại theo trạng thái thật
    [_dot setOn:vn];
}

// Toggle tính năng gõ: setInteger key + set global + callback — y hệt IBAction ViewController.
- (void)onFeatureToggle:(PillSwitch *)sender {
    NSDictionary *def = _toggleDefs[(NSUInteger)sender.tag];
    NSString *key = def[@"k"];
    int val = sender.isOn ? 1 : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:key];
    int *g = GlobalForKey(key);
    if (g) *g = val;
    if ([def[@"spell"] boolValue]) OnSpellCheckingChanged();
}

- (void)onFull:(id)sender { if (self.onOpen) self.onOpen(); }

#pragma mark - Layout

- (void)layout {
    [super layout];

    // [MINDFUL] popover 3-tab (đường dùng THẬT DUY NHẤT hiện nay): tab đã có nhãn "Bộ gõ" rồi,
    // bỏ hàng tiêu đề + luôn bung (expandForTabPresentation đã ép _collapsed = NO) → 2 thẻ trắng
    // viền mảnh (xem relayoutCards:).
    if (_hideHeaderRow) { [self relayoutCards:YES]; return; }

    // Đường dự phòng (KHÔNG có caller nào dùng hiện nay — giữ nguyên hành vi gốc phòng khi view
    // này được gắn ở nơi khác không qua expandForTabPresentation).
    CGFloat w = NSWidth(self.bounds), h = NSHeight(self.bounds);
    CGFloat ctlX = kPad + kLabelW + kLC;
    CGFloat ctlW = MAX(60.0, w - ctlX - kPad);

    CGFloat headerMid = h - kPad - kHeaderH / 2.0;
    _dot.frame = NSMakeRect(kPad, headerMid - 5.0, 10.0, 10.0);
    NSSize ts = _title.intrinsicContentSize;
    _title.frame = NSMakeRect(kPad + 18.0, headerMid - ts.height / 2.0, ts.width, ts.height);
    NSSize vs = _value.intrinsicContentSize;
    _value.frame = NSMakeRect(NSMaxX(_title.frame) + 8.0, headerMid - vs.height / 2.0, vs.width, vs.height);
    _chevron.frame = NSMakeRect(w - kPad - 10.0, headerMid - 8.0, 12.0, 16.0);
    _hit.frame = NSMakeRect(0, h - kPad - kHeaderH - 4.0, w, kHeaderH + 8.0);

    if (_collapsed) return;
    CGFloat top = kPad + kHeaderH + kFieldGap;

    [self placeLabel:_lblType control:_typePopup top:top ctlX:ctlX ctlW:ctlW H:h]; top += kRowH + kFieldGap;
    [self placeLabel:_lblCode control:_codePopup top:top ctlX:ctlX ctlW:ctlW H:h]; top += kRowH + kFieldGap;

    // Gõ tiếng Việt (label trái, switch phải)
    _lblVN.frame    = NSMakeRect(kPad, h - top - kRowH + (kRowH - 16.0) / 2.0, w - kPad - 60.0, 16.0);
    _vnSwitch.frame = NSMakeRect(w - kPad - 40.0, h - top - kRowH + (kRowH - 24.0) / 2.0, 40.0, 24.0);
    top += kRowH + kFieldGap;

    // Các toggle tính năng (label trái, switch phải)
    for (NSUInteger i = 0; i < _toggleDefs.count; i++) {
        _toggleLabels[i].frame = NSMakeRect(kPad, h - top - kToggleH + (kToggleH - 16.0) / 2.0, w - kPad - 60.0, 16.0);
        _toggleSwitches[i].frame = NSMakeRect(w - kPad - 40.0, h - top - kToggleH + (kToggleH - 24.0) / 2.0, 40.0, 24.0);
        top += kToggleH;
    }
    top += kFieldGap;

    NSSize ls = _fullLink.attributedTitle.size;
    _fullLink.frame = NSMakeRect(kPad, h - top - kLinkH, ls.width + 8.0, kLinkH);
}

- (void)placeLabel:(NSTextField *)lbl control:(NSView *)ctl top:(CGFloat)top ctlX:(CGFloat)ctlX ctlW:(CGFloat)ctlW H:(CGFloat)h {
    lbl.frame = NSMakeRect(kPad, h - top - kRowH + (kRowH - 16.0) / 2.0, kLabelW, 16.0);
    ctl.frame = NSMakeRect(ctlX, h - top - kRowH, ctlW, kRowH);
}

@end
