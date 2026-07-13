//
//  KeyboardPreviewView.m
//  mindful-key — iOS container app (khung "Preview sống", story 2.3)
//

#import "KeyboardPreviewView.h"
#import "BrandColorsUIKit.h"

// Chiều cao khung co giãn theo heightLevel 0.0-1.0 — khoảng nhỏ hơn bàn phím thật (260pt,
// KeyboardViewController.mm) vì đây chỉ là khung MINH HOẠ bên trong 1 màn cài đặt, không phải
// bàn phím thật chiếm toàn màn hình.
static const CGFloat kMkPreviewMinHeight = 100.0;
static const CGFloat kMkPreviewMaxHeight = 180.0;

@interface KeyboardPreviewView ()
@property (nonatomic, strong) UILabel *modeLabel;
@property (nonatomic, strong) UIStackView *rowsStack;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@end

@implementation KeyboardPreviewView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self mk_buildUI];
        // Toàn khung là trang trí/minh hoạ — EXPERIENCE.md: "Preview là minh hoạ → không bắt
        // buộc là accessibility element". Thông báo giá trị mới (AC #5) là việc của
        // SettingsViewController (nơi slider/segmented sống), không phải view này.
        self.accessibilityElementsHidden = YES;
    }
    return self;
}

- (void)mk_buildUI {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [BrandColorsUIKit surfaceCard];
    self.layer.cornerRadius = 16;
    self.clipsToBounds = YES;

    UIStackView *outer = [[UIStackView alloc] init];
    outer.axis = UILayoutConstraintAxisVertical;
    outer.alignment = UIStackViewAlignmentFill;
    outer.spacing = 8;
    outer.layoutMarginsRelativeArrangement = YES;
    outer.layoutMargins = UIEdgeInsetsMake(12, 12, 12, 12);
    outer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:outer];

    self.modeLabel = [[UILabel alloc] init];
    self.modeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.modeLabel.adjustsFontForContentSizeCategory = YES;
    self.modeLabel.textColor = [BrandColorsUIKit inkSecondary];
    [outer addArrangedSubview:self.modeLabel];

    self.rowsStack = [[UIStackView alloc] init];
    self.rowsStack.axis = UILayoutConstraintAxisVertical;
    self.rowsStack.distribution = UIStackViewDistributionFillEqually;
    self.rowsStack.spacing = 6;
    [outer addArrangedSubview:self.rowsStack];
    [self mk_buildDecorativeRows];

    [NSLayoutConstraint activateConstraints:@[
        [outer.topAnchor constraintEqualToAnchor:self.topAnchor],
        [outer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [outer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [outer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    self.heightConstraint = [self.heightAnchor constraintEqualToConstant:kMkPreviewMinHeight];
    self.heightConstraint.active = YES;
}

// 3 hàng "phím" trang trí (KHÔNG tương tác) — chỉ minh hoạ hình dáng bàn phím QWERTY thu nhỏ,
// giống bố cục thật (KeyboardViewController.mm) nhưng không đi qua engine/gõ chữ nào cả.
- (void)mk_buildDecorativeRows {
    NSArray<NSString *> *rows = @[@"qwertyuiop", @"asdfghjkl", @"zxcvbnm"];
    for (NSString *chars in rows) {
        UIStackView *row = [[UIStackView alloc] init];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.distribution = UIStackViewDistributionFillEqually;
        row.spacing = 3;
        for (NSUInteger i = 0; i < chars.length; i++) {
            UIView *key = [[UIView alloc] init];
            key.backgroundColor = [BrandColorsUIKit tealLight];
            key.layer.cornerRadius = 3;
            [key.heightAnchor constraintEqualToConstant:14].active = YES;
            [row addArrangedSubview:key];
        }
        [self.rowsStack addArrangedSubview:row];
    }
}

- (void)updateWithInputType:(KeyboardSettingsInputType)inputType heightLevel:(double)heightLevel {
    double clamped = MAX(0.0, MIN(1.0, heightLevel));
    self.modeLabel.text = (inputType == KeyboardSettingsInputTypeVNI)
        ? @"Kiểu gõ: VNI"
        : @"Kiểu gõ: Telex";

    CGFloat height = kMkPreviewMinHeight + clamped * (kMkPreviewMaxHeight - kMkPreviewMinHeight);
    // Đổi TỨC THÌ, không animate — đúng AC #3 (VoiceOver/Reduce Motion vẫn tức thì); đơn giản hoá
    // bằng cách không bao giờ animate khung này thay vì rẽ nhánh theo UIAccessibilityIsReduceMotionEnabled.
    self.heightConstraint.constant = height;
    [self layoutIfNeeded];
}

@end
