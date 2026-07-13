//
//  KeyboardViewController.mm
//  mindful-key — iOS keyboard extension (Round 1 walking skeleton)
//
//  Bàn phím tự vẽ: 3 hàng chữ QWERTY + hàng chức năng. Mốc B: mỗi lần chạm phím đi QUA
//  core/engine (KeyboardBridge) — gõ Telex ra tiếng Việt có dấu, rồi áp kết quả (xoá lùi +
//  chèn) lên UITextDocumentProxy.
//  Story 1.3: thêm Shift (one-shot) / Caps (khoá) + lớp số & ký hiệu (123↔ABC). Trạng thái
//  Shift đổi bằng SÓNG sáng nền teal-nhạt + chỉ dấu khoá — KHÔNG đèn đỏ/xanh (hiến chương).
//  Story 2.1: đổi kiểu gõ Telex<->VNI qua long-press phím 123/ABC (tạm, chờ Cài đặt ở story
//  2.3) + dựng SuggestionBarView (~40pt, TRỐNG nội dung — bề mặt cho sóng 2.5).

#import "KeyboardViewController.h"
#import "KeyboardBridge.h"
#import "EngineKeyMap.h"
#import "AppGroupBridge.h"
#import "SuggestionBarView.h"
#import "MoodBridge.h"
#import "MacroBridge.h"
#import "Macro.h"   // story 2.4: addMacro() — file này (.mm) đã link core/engine, gọi C++ trực tiếp
#import "EmotionWaveAmplitude.h"   // story 2.5: hàm thuần risk -> biên độ sóng (Q1)

// Story 2.5 (AC#1/#4): nhịp poll giá trị send-risk từ MoodBridge để cập nhật con sóng ambient.
// 300ms — đủ thấp để KHÔNG chạm mạch xử lý phím (chỉ đọc 1 std::atomic<double> + 1 hàm thuần mỗi
// tick, không có I/O/khoá), đủ nhanh để sóng cảm thấy "sống" trong 1 câu đang gõ. Giá trị cụ thể
// không bị khoá bởi AC nào — [Inference] chọn theo tinh thần "ambient, không chặn" (NFR-11),
// KHÔNG đồng bộ với debounce cuối câu bên trong MoodBridge (đọc độc lập, luôn đọc giá trị mới
// nhất đã có, không chờ).
static const NSTimeInterval kEmotionWavePollInterval = 0.3;

typedef NS_ENUM(NSInteger, KVCShiftState) {
    KVCShiftOff = 0,   // chữ thường
    KVCShiftOnce,      // hoa 1 ký tự rồi tự về thường
    KVCShiftLocked,    // Caps: hoa tới khi chạm ⇧ mở khoá
};

static NSArray<NSString *> *KVCRow(NSString *chars) {
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (NSUInteger i = 0; i < chars.length; i++) {
        [out addObject:[chars substringWithRange:NSMakeRange(i, 1)]];
    }
    return out;
}

@interface KeyboardViewController ()
@property (nonatomic, strong) UIButton *nextKeyboardButtonRef;
@property (nonatomic, strong) SuggestionBarView *suggestionBar;   // story 2.1: bar TRỐNG, phía trên rootStack
@property (nonatomic, strong) UIStackView *rootStack;
@property (nonatomic, strong) UIButton *shiftButton;
@property (nonatomic, strong) UIButton *layerButton;      // 123 / ABC
@property (nonatomic, strong) NSMutableArray<UIButton *> *letterButtons; // để đổi hoa/thường
@property (nonatomic, assign) KVCShiftState shiftState;
@property (nonatomic, assign) BOOL numberLayer;           // NO = chữ, YES = số/ký hiệu
@property (nonatomic, assign) NSTimeInterval lastShiftTapAt;
@property (nonatomic, strong) NSTimer *emotionWaveTimer;  // story 2.5: poll MoodBridge -> con sóng
@end

@implementation KeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KeyboardBridge_Init();   // khởi động engine trong sandbox extension
    [self mk_loadStoredMacros];   // story 2.4 (AC #4/#5): nạp macro TRƯỚC khi gõ chữ đầu tiên
    MoodBridge_Init();       // story 2.2: nối vOnWordCommitted -> lớp cảm xúc (chưa hiển thị gì)
    // Nhịp tim App Group: báo cho container "bàn phím đã chạy" + cờ Full Access (chỉ đọc được
    // từ trong extension). Chỉ ghi timestamp/bool — KHÔNG bao giờ nội dung gõ.
    KeyboardExtension_WriteHeartbeat(self.hasFullAccess);
    self.shiftState = KVCShiftOff;
    self.numberLayer = NO;
    self.lastShiftTapAt = 0;
    [self buildKeyboardUI];
    [self mk_startEmotionWavePolling];   // story 2.5: bắt đầu SAU khi suggestionBar đã dựng xong
}

- (void)dealloc {
    [self.emotionWaveTimer invalidate];
}

#pragma mark - Story 2.4: nạp macro đã lưu vào engine

// Container (MindfulKeyiOS) KHÔNG link core/engine nên lưu macro dạng NSDictionary thuần qua
// MacroBridge (xem MacroBridge.h Dev Notes). Extension NÀY đã link core/engine — đọc lại mảng đó
// rồi tự gọi addMacro() C++ để nạp vào macroMap trong bộ nhớ CHO PHIÊN CHẠY HIỆN TẠI (mỗi lần
// extension khởi động lại). AC #5: MacroBridge_ReadAll() trả mảng RỖNG nếu chưa từng thêm macro
// nào — vòng lặp này khi đó không làm gì, macroMap giữ rỗng đúng rào chắn RAM NFR-01.
- (void)mk_loadStoredMacros {
    for (NSDictionary<NSString *, NSString *> *macro in MacroBridge_ReadAll()) {
        NSString *trigger = macro[MacroBridgeFieldTrigger];
        NSString *content = macro[MacroBridgeFieldContent];
        if (trigger.length > 0 && content.length > 0) {
            addMacro(trigger.UTF8String, content.UTF8String);
        }
    }
}

#pragma mark - Dựng UI

- (void)buildKeyboardUI {
    // Story 2.1: SuggestionBarView (~40pt, TRỐNG) nằm TRÊN rootStack — bề mặt cho sóng 2.5.
    self.suggestionBar = [[SuggestionBarView alloc] init];
    [self.view addSubview:self.suggestionBar];
    [self.suggestionBar setSuggestions:@[]];   // AC#5: hố cắm sẵn, KHÔNG dữ liệu giả — luôn rỗng

    self.rootStack = [[UIStackView alloc] init];
    self.rootStack.axis = UILayoutConstraintAxisVertical;
    self.rootStack.distribution = UIStackViewDistributionFillEqually;
    self.rootStack.spacing = 6;
    self.rootStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rootStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.suggestionBar.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.suggestionBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.suggestionBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        // rootStack giờ neo dưới suggestionBar thay vì top view — không co bóp 4 hàng phím cũ,
        // chiều cao thanh gợi ý CỘNG THÊM vào khung (đúng AC#3), không nhường chỗ.
        [self.rootStack.topAnchor constraintEqualToAnchor:self.suggestionBar.bottomAnchor constant:6],
        [self.rootStack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-6],
        [self.rootStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:4],
        [self.rootStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-4],
    ]];

    // BẮT BUỘC: custom keyboard phải TỰ khai chiều cao — hệ thống KHÔNG tự cấp. Thiếu dòng này
    // = bàn phím cao 0pt / dải trắng, không thấy phím, không gõ được (build sạch nhưng runtime
    // hỏng — đúng bẫy "build-verify ≠ device-verify"). Priority 999 (< required 1000) để nhường
    // ràng buộc hệ thống thêm vào input view, tránh "unable to satisfy constraints".
    // Story 2.1: 260 (khung 4 hàng phím cũ) + SuggestionBarViewHeight (~40, thanh gợi ý mới) —
    // cộng thêm vào hằng số cũ, KHÔNG dựng height constraint thứ 2 độc lập cho bar (AC#3).
    NSLayoutConstraint *heightC = [self.view.heightAnchor constraintEqualToConstant:(260 + SuggestionBarViewHeight)];
    heightC.priority = UILayoutPriorityRequired - 1;   // 999
    heightC.active = YES;

    [self rebuildRows];
}

// Dựng lại toàn bộ hàng theo lớp hiện tại (chữ vs số). Gọi khi đổi lớp.
- (void)rebuildRows {
    for (UIView *v in self.rootStack.arrangedSubviews) {
        [self.rootStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    self.letterButtons = [NSMutableArray array];

    NSArray<NSString *> *rows = self.numberLayer
        ? @[@"1234567890", @"-/:;()$&@\"", @".,?!'"]
        : @[@"qwertyuiop", @"asdfghjkl", @"zxcvbnm"];

    // Hàng 1 & 2: phím thường.
    [self.rootStack addArrangedSubview:[self charRow:KVCRow(rows[0])]];
    [self.rootStack addArrangedSubview:[self charRow:KVCRow(rows[1])]];
    // Hàng 3: ⇧ (chỉ lớp chữ) + phím + ⌫.
    [self.rootStack addArrangedSubview:[self thirdRow:KVCRow(rows[2])]];
    // Hàng chức năng.
    [self.rootStack addArrangedSubview:[self bottomRowStack]];

    [self refreshLetterCase];
    [self updateShiftVisual];
}

- (UIStackView *)charRow:(NSArray<NSString *> *)chars {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 4;
    for (NSString *ch in chars) {
        UIButton *b = [self keyButtonWithTitle:ch action:@selector(letterKeyTapped:)];
        b.accessibilityLabel = [NSString stringWithFormat:@"phím %@", ch];
        [self.letterButtons addObject:b];
        [row addArrangedSubview:b];
    }
    return row;
}

- (UIStackView *)thirdRow:(NSArray<NSString *> *)chars {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFill;
    row.spacing = 4;

    UIStackView *mid = [[UIStackView alloc] init];
    mid.axis = UILayoutConstraintAxisHorizontal;
    mid.distribution = UIStackViewDistributionFillEqually;
    mid.spacing = 4;
    for (NSString *ch in chars) {
        UIButton *b = [self keyButtonWithTitle:ch action:@selector(letterKeyTapped:)];
        b.accessibilityLabel = [NSString stringWithFormat:@"phím %@", ch];
        [self.letterButtons addObject:b];
        [mid addArrangedSubview:b];
    }

    UIButton *backspace = [self keyButtonWithTitle:@"⌫" action:@selector(backspaceKeyTapped:)];
    backspace.accessibilityLabel = @"xoá lùi";

    if (!self.numberLayer) {
        // Lớp chữ: ⇧ bên trái.
        UIButton *shift = [self keyButtonWithTitle:@"⇧" action:@selector(shiftKeyTapped:)];
        shift.accessibilityLabel = @"phím hoa";
        self.shiftButton = shift;
        [row addArrangedSubview:shift];
        [row addArrangedSubview:mid];
        [row addArrangedSubview:backspace];
        [shift.widthAnchor constraintEqualToAnchor:backspace.widthAnchor].active = YES;
    } else {
        self.shiftButton = nil;
        [row addArrangedSubview:mid];
        [row addArrangedSubview:backspace];
    }
    return row;
}

- (UIStackView *)bottomRowStack {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFill;
    row.spacing = 4;

    self.layerButton = [self keyButtonWithTitle:(self.numberLayer ? @"ABC" : @"123")
                                         action:@selector(layerKeyTapped:)];
    self.layerButton.accessibilityLabel = @"đổi lớp số";
    // Story 2.1 AC#1: long-press (giữ) trên 123/ABC đổi kiểu gõ Telex<->VNI — giải pháp TẠM
    // (tái dùng nguyên tắc long-press = hành động phụ đã có ở story 1.3) cho tới khi Cài đặt
    // (2.3) có segmented control đầy đủ. Phím này không có ký tự/dấu phụ nào để giữ ra nên
    // không xung đột ngữ nghĩa với long-press hiện có trên phím chữ.
    UILongPressGestureRecognizer *toggleInputType =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(layerButtonLongPressed:)];
    toggleInputType.minimumPressDuration = 0.4;   // ~400ms, ngưỡng long-press DESIGN.md §2.5
    [self.layerButton addGestureRecognizer:toggleInputType];

    UIButton *nextKeyboard = [self keyButtonWithTitle:@"🌐" action:nil];
    nextKeyboard.accessibilityLabel = @"đổi bàn phím";
    [nextKeyboard addTarget:self action:@selector(handleInputModeListFromView:withEvent:)
           forControlEvents:UIControlEventAllTouchEvents];
    self.nextKeyboardButtonRef = nextKeyboard;

    UIButton *space = [self keyButtonWithTitle:@"space" action:@selector(spaceKeyTapped:)];
    space.accessibilityLabel = @"phím cách";
    UIButton *returnKey = [self keyButtonWithTitle:@"return" action:@selector(returnKeyTapped:)];
    returnKey.accessibilityLabel = @"xuống dòng";

    [row addArrangedSubview:self.layerButton];
    [row addArrangedSubview:nextKeyboard];
    [row addArrangedSubview:space];
    [row addArrangedSubview:returnKey];

    [self.layerButton.widthAnchor constraintEqualToAnchor:space.widthAnchor multiplier:0.4].active = YES;
    [nextKeyboard.widthAnchor constraintEqualToAnchor:space.widthAnchor multiplier:0.4].active = YES;
    [returnKey.widthAnchor constraintEqualToAnchor:space.widthAnchor multiplier:0.5].active = YES;
    return row;
}

- (UIButton *)keyButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    button.backgroundColor = [UIColor secondarySystemBackgroundColor];
    button.layer.cornerRadius = 5;
    button.isAccessibilityElement = YES;
    // AC#5: vùng chạm ≥ 44×44pt cho MỌI phím.
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    [button.widthAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    if (action) {
        [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

#pragma mark - Shift / Caps

- (BOOL)shiftActive {
    return self.shiftState == KVCShiftOnce || self.shiftState == KVCShiftLocked;
}

- (void)shiftKeyTapped:(UIButton *)sender {
    NSTimeInterval now = [NSProcessInfo processInfo].systemUptime;
    BOOL doubleTap = (now - self.lastShiftTapAt) < 0.30;
    self.lastShiftTapAt = now;

    if (doubleTap) {
        self.shiftState = KVCShiftLocked;         // double-tap → khoá Caps
    } else if (self.shiftState == KVCShiftLocked) {
        self.shiftState = KVCShiftOff;            // đang khoá + chạm → mở khoá
    } else if (self.shiftState == KVCShiftOnce) {
        self.shiftState = KVCShiftOff;
    } else {
        self.shiftState = KVCShiftOnce;
    }
    [self refreshLetterCase];
    [self updateShiftVisual];
}

- (void)updateShiftVisual {
    if (!self.shiftButton) return;
    switch (self.shiftState) {
        case KVCShiftLocked:
            [self.shiftButton setTitle:@"⇪" forState:UIControlStateNormal];  // chỉ dấu khoá riêng biệt
            self.shiftButton.backgroundColor = [UIColor systemTealColor];
            self.shiftButton.accessibilityLabel = @"khoá hoa";
            break;
        case KVCShiftOnce:
            [self.shiftButton setTitle:@"⇧" forState:UIControlStateNormal];
            self.shiftButton.backgroundColor = [UIColor systemTealColor];    // sáng teal-nhạt
            self.shiftButton.accessibilityLabel = @"phím hoa đang bật";
            break;
        case KVCShiftOff:
        default:
            [self.shiftButton setTitle:@"⇧" forState:UIControlStateNormal];
            self.shiftButton.backgroundColor = [UIColor secondarySystemBackgroundColor];
            self.shiftButton.accessibilityLabel = @"phím hoa";
            break;
    }
}

// Đổi nhãn phím chữ hoa/thường phản ánh trạng thái sắp gõ (AC#3). Chỉ áp cho lớp chữ.
- (void)refreshLetterCase {
    if (self.numberLayer) return;
    BOOL upper = [self shiftActive];
    for (UIButton *b in self.letterButtons) {
        NSString *t = [b titleForState:UIControlStateNormal];
        [b setTitle:(upper ? t.uppercaseString : t.lowercaseString) forState:UIControlStateNormal];
    }
}

#pragma mark - Lớp số / ký hiệu

- (void)layerKeyTapped:(UIButton *)sender {
    self.numberLayer = !self.numberLayer;
    if (self.numberLayer) self.shiftState = KVCShiftOff;  // lớp số không có Shift
    [self rebuildRows];
}

// Story 2.1 AC#1: giữ phím 123/ABC ~400ms đổi kiểu gõ Telex<->VNI (cấu hình engine, không phải
// gõ ký tự). Chỉ xử lý state Began — recognizer mặc định cancelsTouchesInView=YES nên
// touchUpInside (layerKeyTapped:, đổi lớp số) KHÔNG bắn kèm, không nhầm 2 hành động.
- (void)layerButtonLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    KeyboardBridge_ToggleInputType();
    // Thông báo quan sát trung tính — không khen/chê, không đèn đỏ/xanh (hiến chương).
    NSString *announcement = KeyboardBridge_IsVNI() ? @"Đang gõ VNI" : @"Đang gõ Telex";
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
}

#pragma mark - Riêng tư: cổng ô bảo mật (story 1.4 / FR-A07)

// CỔNG BẮT BUỘC (single query point). Trả YES khi con trỏ đang ở ô bảo mật (mật khẩu).
// HỢP ĐỒNG: mọi consumer tương lai ĐỌC nội dung vừa gõ để tính send-risk (FR-A09, R2) hoặc để
// ghi nhật ký cảm xúc (R3) PHẢI gọi hàm này TRƯỚC và BỎ QUA khi nó trả YES — không đọc/không log/
// không hiện sóng ở ô bảo mật, kể cả R2+. Round 1 chưa có consumer nào đọc nội dung (chỉ gõ), nên
// đây là cổng dựng sẵn cho tương lai; KHÔNG dùng nó để chặn/nuốt việc GÕ (gõ ở ô bảo mật giống ô thường).
// App Group (khi story 1.6 nối) chỉ được chứa timestamp/bool vận hành, TUYỆT ĐỐI không nội dung gõ.
- (BOOL)mk_isSecureField {
    return self.textDocumentProxy.secureTextEntry;
}

#pragma mark - Story 2.5: con sóng ambient (FR-A08) — wiring risk (2.2) -> suggestionBar (2.1)

// AC#7: chỉ khởi động vòng poll khi ĐANG có Full Access lúc bàn phím mở lên. `hasFullAccess`
// (thuộc tính hệ thống UIInputViewController) chỉ đổi giá trị thật khi người dùng bật/tắt trong
// Settings rồi MỞ LẠI bàn phím (extension bị huỷ + khởi tạo lại) — không đổi sống giữa 1 phiên
// đang chạy, nên kiểm 1 lần ở đây là đủ, không cần tự poll lại cờ này mỗi tick.
- (void)mk_startEmotionWavePolling {
    if (!self.hasFullAccess) return;   // AC#7: chưa Full Access -> giữ nguyên trạng thái rỗng Round 1, KHÔNG gọi setWaveAmplitude:
    NSTimer *timer = [NSTimer timerWithTimeInterval:kEmotionWavePollInterval
                                               target:self
                                             selector:@selector(mk_updateEmotionWave)
                                             userInfo:nil
                                              repeats:YES];
    // NSRunLoopCommonModes: tick vẫn chạy trong lúc UIKit đang ở tracking mode (vd đang giữ 1
    // phím) — con sóng là ambient thuần túy, không được phép "đứng hình" chỉ vì người dùng đang
    // tương tác. Không liên quan/không chặn mạch xử lý phím (AC#4): timer chỉ ĐỌC risk + vẽ, đi
    // trên main run loop nhưng tách hoàn toàn khỏi các action gõ (letterKeyTapped:/spaceKeyTapped:).
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.emotionWaveTimer = timer;
}

// Mỗi tick: tự kiểm cổng ô bảo mật NGAY TẠI THỜI ĐIỂM VẼ (không tin risk đã tính từ trước — xem
// Dev Notes story 2.5 "race giữa debounce async và chuyển field"), rồi đọc risk mới nhất + hàm
// biên độ thuần, rồi giao cho view VẼ. Không đọc/không phân tích nội dung gõ ở đây — chỉ đọc 1
// giá trị đã tính sẵn (MoodBridge_LastSendRisk(), atomic, không side-effect).
- (void)mk_updateEmotionWave {
    if (!self.hasFullAccess) {
        // Edge case Testing story 2.5: mất Full Access GIỮA phiên gõ (hiếm nhưng có thể) — dừng
        // poll hẳn (đỡ phí CPU/battery) và dập sóng về phẳng, không crash, không đứng hình ở biên
        // độ cũ. Không cần tự khởi động lại poll — extension của phiên bị thu hồi quyền thường bị
        // huỷ/khởi động lại, mk_startEmotionWavePolling sẽ tự kiểm lại từ đầu ở lần chạy sau.
        [self.emotionWaveTimer invalidate];
        self.emotionWaveTimer = nil;
        [self.suggestionBar setWaveAmplitude:0.0];
        return;
    }
    if ([self mk_isSecureField]) {
        // AC#6: ô bảo mật -> không đọc risk, không cập nhật theo giá trị cũ — dập hẳn về 0 (chứ
        // không phải "đứng yên ở giá trị risk trước đó", đúng "không hiện hoạt động sóng nào").
        [self.suggestionBar setWaveAmplitude:0.0];
        return;
    }
    double risk = MoodBridge_LastSendRisk();
    double amplitude = EmotionWaveAmplitude(risk);
    [self.suggestionBar setWaveAmplitude:amplitude];
}

#pragma mark - Gõ qua core/engine (KeyboardBridge)

- (void)applyBridgeResult:(KeyboardBridgeResult *)result {
    for (NSInteger i = 0; i < result.backspaceCount; i++) {
        [self.textDocumentProxy deleteBackward];
    }
    if (result.textToInsert.length > 0) {
        [self.textDocumentProxy insertText:result.textToInsert];
    }
}

- (void)letterKeyTapped:(UIButton *)sender {
    // Story 2.2 (AC#3): đẩy trạng thái ô bảo mật vào MoodBridge TRƯỚC khi phím này có thể khiến
    // engine commit 1 từ — đúng hợp đồng "gọi cổng TRƯỚC" đã khoá ở story 1.4 AC#6.
    MoodBridge_SetSecureFieldActive([self mk_isSecureField]);
    NSString *shown = [sender titleForState:UIControlStateNormal];
    BOOL isShift = [self shiftActive];
    // Engine tra theo ký tự thường; hoa/thường do cờ isShift quyết định.
    NSString *lookup = shown.lowercaseString;
    NSNumber *keyCode = EngineKeyMap_CharacterToKeyCode()[lookup];
    if (keyCode == nil) {
        // Ký tự/ký hiệu ngoài bảng phím engine (vd lớp số): chèn thẳng, tôn trọng hoa/thường đang hiện.
        [self.textDocumentProxy insertText:shown];
    } else {
        [self applyBridgeResult:KeyboardBridge_HandleKeyTap(keyCode.unsignedShortValue, isShift)];
    }

    if (self.shiftState == KVCShiftOnce) {   // one-shot: gõ xong 1 ký tự → về thường
        self.shiftState = KVCShiftOff;
        [self refreshLetterCase];
        [self updateShiftVisual];
    }
}

- (void)spaceKeyTapped:(UIButton *)sender {
    // Story 2.2 (AC#3): space thường chốt 1 từ (vBreakWord) — cùng lý do như letterKeyTapped:.
    MoodBridge_SetSecureFieldActive([self mk_isSecureField]);
    [self applyBridgeResult:KeyboardBridge_HandleSpace()];
}

- (void)backspaceKeyTapped:(UIButton *)sender {
    // Story 2.2 (Opus review): giữ cờ ô bảo mật LUÔN tươi — phòng backspace lỡ chạm word-commit
    // khi state cache còn cũ (phòng thủ riêng tư, rẻ). Callback đọc cờ này trước khi phân tích.
    MoodBridge_SetSecureFieldActive([self mk_isSecureField]);
    [self applyBridgeResult:KeyboardBridge_HandleBackspace()];
}

- (void)returnKeyTapped:(UIButton *)sender {
    [self.textDocumentProxy insertText:@"\n"];
}

@end
