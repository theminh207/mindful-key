//
//  FullAccessViewController.m
//  mindful-key — iOS container app (onboarding Màn 02, story 1.7)
//
//  Copy lấy NGUYÊN VĂN bản nháp EXPERIENCE.md §Màn-02.
//  // TODO(chủ dự án): giọng copy onboarding chờ chốt Q10b — đang dùng bản nháp EXPERIENCE.md.
//

#import "FullAccessViewController.h"
#import "BrandColorsUIKit.h"
#import "BrandMarkView.h"
#import "OnboardingUI.h"

@interface FullAccessViewController ()
@property (nonatomic, strong) BrandMarkView *headerMark;
@property (nonatomic, strong) BrandMarkView *waveRowMark;
@end

@implementation FullAccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    [self mk_buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.headerMark startWaveAnimationIfAllowed];
    [self.waveRowMark startWaveAnimationIfAllowed];
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

    // Header nhận diện + chỉ báo bước 2/2
    [stack addArrangedSubview:[self mk_brandHeader]];

    // Tiêu đề + phụ đề (EXPERIENCE.md §Màn-02)
    [stack addArrangedSubview:[OnboardingUI titleLabel:@"Về quyền Truy cập Đầy đủ"]];
    [stack addArrangedSubview:[OnboardingUI subtitleLabel:
        @"iOS sẽ hỏi bạn bật “Cho phép Truy cập Đầy đủ”. Đây là điều nó thật sự làm."]];

    // CẶP BIÊN ĐỘ (DESIGN.md §2.10): nghĩa nằm ở NHÃN CHỮ, sóng/đường phẳng chỉ minh hoạ.
    self.waveRowMark = [[BrandMarkView alloc] initWithStyle:BrandMarkStyleWave];
    [stack setCustomSpacing:28 afterView:stack.arrangedSubviews.lastObject];
    [stack addArrangedSubview:[self mk_amplitudeRowMark:self.waveRowMark
                                                caption:@"BẬT LÊN ĐỂ"
                                                   body:@"Mindful Key đọc câu bạn vừa gõ — ngay trên máy — để con sóng ~ phản chiếu nhịp gõ của bạn."]];

    BrandMarkView *flat = [[BrandMarkView alloc] initWithStyle:BrandMarkStyleFlat];
    [stack addArrangedSubview:[self mk_amplitudeRowMark:flat
                                                caption:@"KHÔNG BAO GIỜ"
                                                   body:@"Chữ bạn gõ không rời khỏi máy. Không gửi, không lưu, không ai đọc."]];

    // Card trấn an "chưa cần bật"
    [stack setCustomSpacing:28 afterView:stack.arrangedSubviews.lastObject];
    [stack addArrangedSubview:[self mk_reassureCard:@"Bạn vẫn gõ bình thường mà chưa cần bật. Bật khi muốn."]];

    // CTA "Bật Truy cập Đầy đủ" + ghost "Để sau" — cả 2 đều tới Home
    UIButton *cta = [OnboardingUI primaryCTA:@"Bật Truy cập Đầy đủ"];
    [cta addTarget:self action:@selector(mk_enableFullAccess) forControlEvents:UIControlEventTouchUpInside];
    [stack setCustomSpacing:24 afterView:stack.arrangedSubviews.lastObject];
    [stack addArrangedSubview:cta];

    UIButton *later = [OnboardingUI ghostButton:@"Để sau"];
    [later addTarget:self action:@selector(mk_deferForLater) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:later];

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

- (UIView *)mk_brandHeader {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8;

    // // TODO(chủ dự án): asset nhận diện chờ chốt Q10b — sóng placeholder + wordmark text.
    self.headerMark = [[BrandMarkView alloc] initWithStyle:BrandMarkStyleWave];
    self.headerMark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerMark.widthAnchor constraintEqualToConstant:36].active = YES;
    [self.headerMark.heightAnchor constraintEqualToConstant:20].active = YES;

    UILabel *wordmark = [[UILabel alloc] init];
    wordmark.text = @"Mindful Key";   // TODO(chủ dự án): wordmark/logo chờ chốt Q10b
    wordmark.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    wordmark.adjustsFontForContentSizeCategory = YES;
    wordmark.textColor = [BrandColorsUIKit brandTeal];

    [row addArrangedSubview:self.headerMark];
    [row addArrangedSubview:wordmark];
    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [row addArrangedSubview:spacer];
    [row addArrangedSubview:[OnboardingUI stepIndicatorCurrent:2 total:2]];
    return row;
}

// 1 dòng biên độ: graphic (sóng/đường phẳng, isAccessibilityElement=NO) + caption + body.
// Nghĩa đọc được ở NHÃN CHỮ — không phụ thuộc màu/hình (WCAG 1.4.1).
- (UIView *)mk_amplitudeRowMark:(BrandMarkView *)mark caption:(NSString *)caption body:(NSString *)body {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentTop;
    row.spacing = 12;

    mark.translatesAutoresizingMaskIntoConstraints = NO;
    [mark.widthAnchor constraintEqualToConstant:32].active = YES;
    [mark.heightAnchor constraintEqualToConstant:24].active = YES;

    UIStackView *textCol = [[UIStackView alloc] init];
    textCol.axis = UILayoutConstraintAxisVertical;
    textCol.spacing = 4;

    UILabel *cap = [[UILabel alloc] init];
    cap.text = caption;
    cap.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    cap.adjustsFontForContentSizeCategory = YES;
    cap.numberOfLines = 0;
    cap.textColor = [BrandColorsUIKit inkSecondary];

    UILabel *bodyLabel = [OnboardingUI bodyLabel:body];

    [textCol addArrangedSubview:cap];
    [textCol addArrangedSubview:bodyLabel];

    [row addArrangedSubview:mark];
    [row addArrangedSubview:textCol];
    return row;
}

- (UIView *)mk_reassureCard:(NSString *)text {
    UILabel *label = [OnboardingUI bodyLabel:text];
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [BrandColorsUIKit surfaceCard];
    card.layer.cornerRadius = 16;   // radius.card
    card.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [label.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
        [label.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [label.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    ]];
    return card;
}

- (void)mk_enableFullAccess {
    // App KHÔNG kiểm soát popup Full Access — chỉ mở Cài đặt (API công khai). Dù kết quả gì → Home.
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    UIApplication *app = [UIApplication sharedApplication];
    if (url && [app canOpenURL:url]) {
        [app openURL:url options:@{} completionHandler:nil];
    }
    [self mk_finish];
}

- (void)mk_deferForLater {
    // "Để sau" → Home ngay, KHÔNG nài, không popup nhắc lại trong cùng phiên.
    [self mk_finish];
}

- (void)mk_finish {
    if (self.onFinish) { self.onFinish(); }
}

@end
