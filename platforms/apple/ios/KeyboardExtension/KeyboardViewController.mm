//
//  KeyboardViewController.mm
//  mindful-key — iOS keyboard extension (Round 1 walking skeleton)
//
//  Bàn phím tự vẽ: 3 hàng chữ QWERTY + hàng chức năng. Mốc B: mỗi lần chạm phím đi QUA
//  core/engine (KeyboardBridge) — gõ Telex ra tiếng Việt có dấu, rồi áp kết quả (xoá lùi +
//  chèn) lên UITextDocumentProxy.
//  Story 1.3: thêm Shift (one-shot) / Caps (khoá) + lớp số & ký hiệu (123↔ABC). Trạng thái
//  Shift đổi bằng SÓNG sáng nền teal-nhạt + chỉ dấu khoá — KHÔNG đèn đỏ/xanh (hiến chương).

#import "KeyboardViewController.h"
#import "KeyboardBridge.h"
#import "EngineKeyMap.h"

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
@property (nonatomic, strong) UIStackView *rootStack;
@property (nonatomic, strong) UIButton *shiftButton;
@property (nonatomic, strong) UIButton *layerButton;      // 123 / ABC
@property (nonatomic, strong) NSMutableArray<UIButton *> *letterButtons; // để đổi hoa/thường
@property (nonatomic, assign) KVCShiftState shiftState;
@property (nonatomic, assign) BOOL numberLayer;           // NO = chữ, YES = số/ký hiệu
@property (nonatomic, assign) NSTimeInterval lastShiftTapAt;
@end

@implementation KeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KeyboardBridge_Init();   // khởi động engine trong sandbox extension
    self.shiftState = KVCShiftOff;
    self.numberLayer = NO;
    self.lastShiftTapAt = 0;
    [self buildKeyboardUI];
}

#pragma mark - Dựng UI

- (void)buildKeyboardUI {
    self.rootStack = [[UIStackView alloc] init];
    self.rootStack.axis = UILayoutConstraintAxisVertical;
    self.rootStack.distribution = UIStackViewDistributionFillEqually;
    self.rootStack.spacing = 6;
    self.rootStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rootStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.rootStack.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:6],
        [self.rootStack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-6],
        [self.rootStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:4],
        [self.rootStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-4],
    ]];

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
    [self applyBridgeResult:KeyboardBridge_HandleSpace()];
}

- (void)backspaceKeyTapped:(UIButton *)sender {
    [self applyBridgeResult:KeyboardBridge_HandleBackspace()];
}

- (void)returnKeyTapped:(UIButton *)sender {
    [self.textDocumentProxy insertText:@"\n"];
}

@end
