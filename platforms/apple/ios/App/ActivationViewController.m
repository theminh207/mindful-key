//
//  ActivationViewController.m
//  mindful-key — iOS container app (onboarding Màn 01, story 1.7)
//
//  Copy lấy NGUYÊN VĂN bản nháp EXPERIENCE.md §Màn-01 (không tự diễn giải lại giọng văn).
//  // TODO(chủ dự án): giọng copy onboarding chờ chốt Q10b — đang dùng bản nháp EXPERIENCE.md.
//

#import "ActivationViewController.h"
#import "BrandColorsUIKit.h"
#import "BrandMarkView.h"
#import "OnboardingUI.h"

@interface ActivationViewController ()
@property (nonatomic, strong) BrandMarkView *brandMark;
@property (nonatomic, strong) UILabel *fallbackLabel;    // hướng dẫn "Chưa thấy?" — ẩn mặc định
@property (nonatomic, strong) UIButton *continueButton;  // lối tiến thủ công — ẩn tới khi rời-về Cài đặt
@property (nonatomic, assign) BOOL didLeaveForSettings;  // đã bấm "Mở Cài đặt" và rời app chưa
@end

@implementation ActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    [self mk_buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.brandMark startWaveAnimationIfAllowed];
    // Quay lại màn này SAU KHI đã rời sang Cài đặt mà AppDelegate không tự chuyển Màn 02
    // (heartbeat chưa/không nhảy) → hé lối tiến thủ công để người dùng không kẹt.
    if (self.didLeaveForSettings && self.continueButton.hidden) {
        self.continueButton.hidden = NO;
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.continueButton);
    }
}

- (void)mk_buildUI {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 20;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    // — Header nhận diện: sóng `~` + wordmark + chỉ báo bước 1/2 —
    [stack addArrangedSubview:[self mk_brandHeaderStep:1]];

    // — Tiêu đề + phụ đề (EXPERIENCE.md §Màn-01) —
    [stack addArrangedSubview:[OnboardingUI titleLabel:@"Thêm Mindful Key vào bàn phím của bạn"]];
    [stack addArrangedSubview:[OnboardingUI subtitleLabel:@"Chỉ một lần. Sau đó chạm 🌐 để gọi bất cứ khi nào."]];

    // — 3 bước đánh số (số = trình tự thật) —
    [stack setCustomSpacing:28 afterView:stack.arrangedSubviews.lastObject];
    [stack addArrangedSubview:[self mk_stepRow:1 text:@"Mở Cài đặt › Cài đặt chung › Bàn phím"]];
    [stack addArrangedSubview:[self mk_stepRow:2 text:@"Bàn phím › Thêm bàn phím mới…"]];
    [stack addArrangedSubview:[self mk_stepRow:3 text:@"Chọn Mindful Key"]];

    // — CTA "Mở Cài đặt" —
    UIButton *cta = [OnboardingUI primaryCTA:@"Mở Cài đặt"];
    [cta addTarget:self action:@selector(mk_openSettings) forControlEvents:UIControlEventTouchUpInside];
    cta.accessibilityHint = @"Mở app Cài đặt của iPhone.";
    [stack setCustomSpacing:28 afterView:stack.arrangedSubviews.lastObject];
    [stack addArrangedSubview:cta];

    // — Ghost "Chưa thấy Mindful Key?" —
    UIButton *ghost = [OnboardingUI ghostButton:@"Chưa thấy Mindful Key?"];
    [ghost addTarget:self action:@selector(mk_toggleFallback) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:ghost];

    // — Hướng dẫn fallback (ẩn mặc định), giọng bình thản, KHÔNG tô đỏ / KHÔNG "Lỗi" —
    self.fallbackLabel = [OnboardingUI subtitleLabel:
        @"Có thể iOS cần vài giây để hiện. Mở app Cài đặt › Cài đặt chung › Bàn phím để thêm Mindful Key, rồi thử lại."];
    self.fallbackLabel.hidden = YES;
    [stack addArrangedSubview:self.fallbackLabel];

    // — Lối tiến thủ công (ẩn tới khi rời-về Cài đặt): tránh kẹt vĩnh viễn nếu heartbeat App
    //   Group không nhảy. Giọng bình thản, không nài, không "Bỏ qua". —
    self.continueButton = [OnboardingUI ghostButton:@"Đã thêm xong — tiếp tục"];
    [self.continueButton addTarget:self action:@selector(mk_continueAnyway) forControlEvents:UIControlEventTouchUpInside];
    self.continueButton.hidden = YES;
    [stack addArrangedSubview:self.continueButton];

    UILayoutGuide *cg = scroll.contentLayoutGuide;
    UILayoutGuide *fg = scroll.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [stack.topAnchor constraintEqualToAnchor:cg.topAnchor constant:48],
        [stack.bottomAnchor constraintEqualToAnchor:cg.bottomAnchor constant:-32],
        [stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:fg.widthAnchor constant:-40],
    ]];
}

- (UIView *)mk_brandHeaderStep:(NSInteger)step {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8;
    row.translatesAutoresizingMaskIntoConstraints = NO;

    // // TODO(chủ dự án): asset nhận diện chờ chốt Q10b — sóng placeholder + wordmark text.
    self.brandMark = [[BrandMarkView alloc] initWithStyle:BrandMarkStyleWave];
    self.brandMark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.brandMark.widthAnchor constraintEqualToConstant:36].active = YES;
    [self.brandMark.heightAnchor constraintEqualToConstant:20].active = YES;

    UILabel *wordmark = [[UILabel alloc] init];
    wordmark.text = @"Mindful Key";   // TODO(chủ dự án): wordmark/logo chờ chốt Q10b — tạm text thuần
    wordmark.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    wordmark.adjustsFontForContentSizeCategory = YES;
    wordmark.textColor = [BrandColorsUIKit brandTeal];

    [row addArrangedSubview:self.brandMark];
    [row addArrangedSubview:wordmark];
    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [row addArrangedSubview:spacer];
    [row addArrangedSubview:[OnboardingUI stepIndicatorCurrent:step total:2]];
    return row;
}

- (UIView *)mk_stepRow:(NSInteger)number text:(NSString *)text {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentTop;
    row.spacing = 12;
    row.translatesAutoresizingMaskIntoConstraints = NO;

    // Vòng số bước — trang trí (nghĩa đọc qua nhãn chữ). tealLight nền + tealStrong chữ (6.86:1).
    UILabel *num = [[UILabel alloc] init];
    num.text = [NSString stringWithFormat:@"%ld", (long)number];
    num.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    num.adjustsFontForContentSizeCategory = YES;
    num.textAlignment = NSTextAlignmentCenter;
    num.textColor = [BrandColorsUIKit tealStrong];
    num.backgroundColor = [BrandColorsUIKit tealLight];
    num.layer.cornerRadius = 14;
    num.clipsToBounds = YES;
    num.translatesAutoresizingMaskIntoConstraints = NO;
    num.isAccessibilityElement = NO;
    [num.widthAnchor constraintEqualToConstant:28].active = YES;
    [num.heightAnchor constraintEqualToConstant:28].active = YES;

    UILabel *label = [OnboardingUI bodyLabel:text];
    label.accessibilityLabel = [NSString stringWithFormat:@"Bước %ld. %@", (long)number, text];

    [row addArrangedSubview:num];
    [row addArrangedSubview:label];
    return row;
}

- (void)mk_continueAnyway {
    if (self.onContinueAnyway) { self.onContinueAnyway(); }
}

- (void)mk_openSettings {
    self.didLeaveForSettings = YES;   // đánh dấu để khi quay lại (nếu heartbeat không nhảy) hé lối tiến thủ công
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];   // API CÔNG KHAI (không App-Prefs private)
    UIApplication *app = [UIApplication sharedApplication];
    if (url && [app canOpenURL:url]) {
        __weak typeof(self) weakSelf = self;
        [app openURL:url options:@{} completionHandler:^(BOOL success) {
            if (!success) { [weakSelf mk_revealFallback]; }   // hỏng deep link → hướng dẫn tĩnh, KHÔNG đổi sang "Lỗi"
        }];
    } else {
        [self mk_revealFallback];
    }
}

- (void)mk_toggleFallback {
    self.fallbackLabel.hidden = !self.fallbackLabel.hidden;
    if (!self.fallbackLabel.hidden) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.fallbackLabel);
    }
}

- (void)mk_revealFallback {
    if (self.fallbackLabel.hidden) {
        self.fallbackLabel.hidden = NO;
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.fallbackLabel);
    }
}

@end
