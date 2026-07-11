//
//  KeyboardViewController.mm
//  mindful-key — iOS keyboard extension (Round 1 walking skeleton, Mốc A)
//
//  Bàn phím tự vẽ tối thiểu: 3 hàng QWERTY + hàng dưới (chuyển bàn phím / dấu cách / xoá).
//  Mốc B: mỗi lần chạm phím đi QUA core/engine (KeyboardBridge) — gõ Telex ra tiếng Việt có dấu,
//  rồi áp kết quả (xoá lùi + chèn) lên UITextDocumentProxy. Không còn chèn thô như Mốc A.
//  KeyboardBridge_Init() gọi ở viewDidLoad để khởi động engine trong sandbox extension.

#import "KeyboardViewController.h"
#import "KeyboardBridge.h"
#import "EngineKeyMap.h"

static NSArray<NSString *> *KVCRow(NSString *letters) {
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (NSUInteger i = 0; i < letters.length; i++) {
        [out addObject:[letters substringWithRange:NSMakeRange(i, 1)]];
    }
    return out;
}

@interface KeyboardViewController ()
@property (nonatomic, strong) UIButton *nextKeyboardButtonRef;
@end

@implementation KeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Chứng minh rủi ro lớn nhất: core/engine build + init sạch bên trong sandbox extension.
    KeyboardBridge_Init();

    [self buildKeyboardUI];
}

- (void)buildKeyboardUI {
    UIStackView *rootStack = [[UIStackView alloc] init];
    rootStack.axis = UILayoutConstraintAxisVertical;
    rootStack.distribution = UIStackViewDistributionFillEqually;
    rootStack.spacing = 6;
    rootStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:rootStack];

    [NSLayoutConstraint activateConstraints:@[
        [rootStack.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:6],
        [rootStack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-6],
        [rootStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:4],
        [rootStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-4],
    ]];

    NSArray<NSArray<NSString *> *> *rows = @[
        KVCRow(@"qwertyuiop"),
        KVCRow(@"asdfghjkl"),
        KVCRow(@"zxcvbnm"),
    ];

    for (NSArray<NSString *> *row in rows) {
        [rootStack addArrangedSubview:[self rowStackForLetters:row]];
    }

    [rootStack addArrangedSubview:[self bottomRowStack]];
}

- (UIStackView *)rowStackForLetters:(NSArray<NSString *> *)letters {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 4;
    for (NSString *letter in letters) {
        [row addArrangedSubview:[self keyButtonWithTitle:letter action:@selector(letterKeyTapped:)]];
    }
    return row;
}

- (UIStackView *)bottomRowStack {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFill;
    row.spacing = 4;

    // Nút chuyển bàn phím — bắt buộc theo yêu cầu Apple cho custom keyboard.
    UIButton *nextKeyboard = [self keyButtonWithTitle:@"🌐" action:nil];
    [nextKeyboard addTarget:self action:@selector(handleInputModeListFromView:withEvent:)
            forControlEvents:UIControlEventAllTouchEvents];
    self.nextKeyboardButtonRef = nextKeyboard;

    UIButton *space = [self keyButtonWithTitle:@"space" action:@selector(spaceKeyTapped:)];
    UIButton *backspace = [self keyButtonWithTitle:@"⌫" action:@selector(backspaceKeyTapped:)];

    [row addArrangedSubview:nextKeyboard];
    [row addArrangedSubview:space];
    [row addArrangedSubview:backspace];

    [nextKeyboard.widthAnchor constraintEqualToAnchor:space.widthAnchor multiplier:0.5].active = YES;
    [backspace.widthAnchor constraintEqualToAnchor:space.widthAnchor multiplier:0.5].active = YES;

    return row;
}

- (UIButton *)keyButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    button.backgroundColor = [UIColor secondarySystemBackgroundColor];
    button.layer.cornerRadius = 5;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:38].active = YES;
    if (action) {
        [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

#pragma mark - Mốc B: gõ qua core/engine (KeyboardBridge)

// Áp thao tác engine trả về lên ô nhập: xoá lùi TRƯỚC, rồi chèn chuỗi mới.
- (void)applyBridgeResult:(KeyboardBridgeResult *)result {
    for (NSInteger i = 0; i < result.backspaceCount; i++) {
        [self.textDocumentProxy deleteBackward];
    }
    if (result.textToInsert.length > 0) {
        [self.textDocumentProxy insertText:result.textToInsert];
    }
}

- (void)letterKeyTapped:(UIButton *)sender {
    NSString *letter = [sender titleForState:UIControlStateNormal];
    NSNumber *keyCode = EngineKeyMap_CharacterToKeyCode()[letter];
    if (keyCode == nil) {
        // Ký tự không có trong bảng phím engine (không nên xảy ra với QWERTY) — chèn thẳng.
        [self.textDocumentProxy insertText:letter];
        return;
    }
    [self applyBridgeResult:KeyboardBridge_HandleKeyTap(keyCode.unsignedShortValue, NO)];
}

- (void)spaceKeyTapped:(UIButton *)sender {
    [self applyBridgeResult:KeyboardBridge_HandleSpace()];
}

- (void)backspaceKeyTapped:(UIButton *)sender {
    [self applyBridgeResult:KeyboardBridge_HandleBackspace()];
}

@end
