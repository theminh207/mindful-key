//
//  HomeViewController.m
//  mindful-key — iOS container app (Màn Home, story 1.7)
//
//  Copy lấy NGUYÊN VĂN bản nháp EXPERIENCE.md §Màn-Home.
//  // TODO(chủ dự án): giọng copy chờ chốt Q10b — đang dùng bản nháp EXPERIENCE.md.
//

#import "HomeViewController.h"
#import "BrandColorsUIKit.h"
#import "BrandMarkView.h"
#import "OnboardingUI.h"
#import "AppGroupBridge.h"

@interface HomeViewController ()
@property (nonatomic, strong) BrandMarkView *brandMark;
@property (nonatomic, strong) UILabel *statusTitle;
@property (nonatomic, strong) UILabel *statusBody;
@property (nonatomic, strong) UITextField *testField;
@property (nonatomic, strong) UIButton *returnButton;   // chỉ hiện ở nhánh "chưa bật"
@property (nonatomic, strong) UIButton *macroButton;    // story 2.4: lối vào màn Gõ tắt, luôn hiện
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    [self mk_buildUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self mk_refreshStatus];   // đọc heartbeat mỗi lần màn hiện
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.brandMark startWaveAnimationIfAllowed];
}

- (void)mk_buildUI {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    // Header nhận diện (không có chỉ báo bước ở Home)
    UIStackView *header = [[UIStackView alloc] init];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 8;
    // // TODO(chủ dự án): asset nhận diện chờ chốt Q10b — sóng placeholder + wordmark text.
    self.brandMark = [[BrandMarkView alloc] initWithStyle:BrandMarkStyleWave];
    self.brandMark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.brandMark.widthAnchor constraintEqualToConstant:36].active = YES;
    [self.brandMark.heightAnchor constraintEqualToConstant:20].active = YES;
    UILabel *wordmark = [[UILabel alloc] init];
    wordmark.text = @"Mindful Key";   // TODO(chủ dự án): wordmark/logo chờ chốt Q10b
    wordmark.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    wordmark.adjustsFontForContentSizeCategory = YES;
    wordmark.textColor = [BrandColorsUIKit brandTeal];
    [header addArrangedSubview:self.brandMark];
    [header addArrangedSubview:wordmark];
    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [header addArrangedSubview:spacer];
    [stack addArrangedSubview:header];

    // Tiêu đề trạng thái (mô tả, không khen) + body — nội dung set ở mk_refreshStatus.
    self.statusTitle = [OnboardingUI titleLabel:@""];
    self.statusBody = [OnboardingUI bodyLabel:@""];
    [stack setCustomSpacing:24 afterView:header];
    [stack addArrangedSubview:self.statusTitle];
    [stack addArrangedSubview:self.statusBody];

    // Ô gõ thử — giữ khả năng kiểm bàn phím thủ công (Mốc B).
    self.testField = [[UITextField alloc] init];
    self.testField.borderStyle = UITextBorderStyleRoundedRect;
    self.testField.placeholder = @"Gõ thử ở đây…";
    self.testField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.testField.adjustsFontForContentSizeCategory = YES;
    self.testField.accessibilityLabel = @"Ô gõ thử";
    self.testField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.testField.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    [stack addArrangedSubview:self.testField];

    // Story 2.4: lối vào màn Gõ tắt — luôn hiện (không phụ thuộc trạng thái heartbeat như
    // returnButton bên dưới).
    self.macroButton = [OnboardingUI ghostButton:@"Gõ tắt…"];
    [self.macroButton addTarget:self action:@selector(mk_openMacroManager) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:self.macroButton];

    // Nút quay lại hướng dẫn — chỉ hiện khi "chưa bật".
    self.returnButton = [OnboardingUI ghostButton:@"Quay lại hướng dẫn kích hoạt"];
    [self.returnButton addTarget:self action:@selector(mk_returnToActivation) forControlEvents:UIControlEventTouchUpInside];
    self.returnButton.hidden = YES;
    [stack addArrangedSubview:self.returnButton];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:32],
        [stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
    ]];
}

- (void)mk_refreshStatus {
    AppGroupKeyboardStatus status = ContainerApp_ReadKeyboardStatus();
    if (status == AppGroupKeyboardStatusNeverRan) {
        // Nhánh "chưa bật" — đoán từ heartbeat trống. Giọng bình thản, KHÔNG quở.
        self.statusTitle.text = @"Có vẻ bàn phím chưa bật";
        self.statusBody.text = @"Thử lại nhé — mở Cài đặt để thêm Mindful Key. Sau đó chạm 🌐 trên bàn phím để chuyển sang Mindful Key.";
        self.returnButton.hidden = NO;
    } else {
        self.statusTitle.text = @"Bàn phím đã sẵn sàng";
        self.statusBody.text = @"Chạm 🌐 trên bàn phím để chuyển sang Mindful Key.";
        self.returnButton.hidden = YES;
    }
}

- (void)mk_returnToActivation {
    if (self.onReturnToActivation) { self.onReturnToActivation(); }
}

- (void)mk_openMacroManager {
    if (self.onOpenMacroManager) { self.onOpenMacroManager(); }
}

@end
