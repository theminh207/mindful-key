//
//  BellSettingsViewController.m
//  mindful-key — iOS container app (tab "Chuông" — Chuông tỉnh thức)
//
//  Xem BellSettingsViewController.h. 3 lớp phụ trợ RIÊNG file này (không lộ ra header — đúng
//  "self-contained": chỉ 4 file được tạo cho việc này):
//    - MKBorderedCardView       card viền mảnh bo góc (khối "Lịch ngân chuông" / "Yên tĩnh")
//    - MKBellSoundPillControl   pill chọn tiếng chuông (lớn/nhỏ)
//    - MKBellScheduleRowView    1 dòng lịch: nhãn + công tắc + dòng cấu hình nhỏ khi bật
//    - MKBreathRingsView + MKBreathOverlayViewController   màn hình thở toàn màn ("Ngân thử")
//

#import "BellSettingsViewController.h"
#import "BrandColorsUIKit.h"
#import "OnboardingUI.h"
#import "BellScheduleSettingsBridge.h"

#pragma mark - Tiện ích dùng chung file này

// Nút pill cam — dùng cho cả CTA "Ngân thử một tiếng" (màn chính) và "Xong" (overlay thở).
// Không dùng OnboardingUI primaryCTA vì đó là nút full-width bo góc 8 (kiểu onboarding), còn ở
// đây design là pill bo tròn hoàn toàn (`.mini.pri`, cao 46, radius 999).
static UIButton *MKBellPillButton(NSString *title) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[BrandColorsUIKit onOrange] forState:UIControlStateNormal];   // chữ TỐI trên nền cam, luật cứng
    b.backgroundColor = [BrandColorsUIKit orange];
    b.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    b.titleLabel.adjustsFontForContentSizeCategory = YES;
    b.titleLabel.numberOfLines = 0;
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    b.layer.cornerRadius = 23;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.contentEdgeInsets = UIEdgeInsetsMake(13, 24, 13, 24);
    [b.heightAnchor constraintGreaterThanOrEqualToConstant:46.0].active = YES;
    return b;
}

#pragma mark - MKBorderedCardView

// card2 design: nền surfaceCard, viền divider 1pt, bo góc 14. layer.borderColor là CGColor "chụp"
// tại thời điểm set — KHÔNG tự đổi theo Light/Dark, nên phải nạp lại ở traitCollectionDidChange
// (đúng pattern đã dùng ở BrandMarkView.m / KeyboardBackgroundViewController.m).
@interface MKBorderedCardView : UIView
@end

@implementation MKBorderedCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [BrandColorsUIKit surfaceCard];
        self.layer.cornerRadius = 14.0;
        self.layer.borderWidth = 1.0;
        self.clipsToBounds = YES;
        [self mk_applyBorderColor];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self mk_applyBorderColor];
}

- (void)mk_applyBorderColor {
    self.layer.borderColor = [BrandColorsUIKit divider].CGColor;
}

@end

#pragma mark - MKBellSoundPillControl

// Pill chọn tiếng chuông (`.soundpill` trong design) — chọn = viền teal + nền tealLight, chưa
// chọn = viền divider + nền surfaceCard. Icon "▶" chỉ trang trí (KHÔNG phải nút phát âm thanh
// thật — màn này không phụ thuộc AudioToolbox).
@interface MKBellSoundPillControl : UIControl
@property (nonatomic, assign, getter=isSelectedPill) BOOL selectedPill;
- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
@end

@implementation MKBellSoundPillControl {
    UIView *_iconCircle;
}

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layer.cornerRadius = 14.0;
        self.layer.borderWidth = 1.5;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", title, subtitle];

        _iconCircle = [[UIView alloc] init];
        _iconCircle.translatesAutoresizingMaskIntoConstraints = NO;
        _iconCircle.layer.cornerRadius = 16.0;
        _iconCircle.layer.borderWidth = 1.5;
        _iconCircle.userInteractionEnabled = NO;
        [_iconCircle.widthAnchor constraintEqualToConstant:32.0].active = YES;
        [_iconCircle.heightAnchor constraintEqualToConstant:32.0].active = YES;

        UILabel *iconLabel = [[UILabel alloc] init];
        iconLabel.text = @"▶";
        iconLabel.font = [UIFont systemFontOfSize:10.0];
        iconLabel.textColor = [BrandColorsUIKit brandTeal];
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.translatesAutoresizingMaskIntoConstraints = NO;
        iconLabel.userInteractionEnabled = NO;
        [_iconCircle addSubview:iconLabel];
        [NSLayoutConstraint activateConstraints:@[
            [iconLabel.centerXAnchor constraintEqualToAnchor:_iconCircle.centerXAnchor],
            [iconLabel.centerYAnchor constraintEqualToAnchor:_iconCircle.centerYAnchor],
        ]];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = title;
        UIFontDescriptor *bold = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleSubheadline]
                                  fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        titleLabel.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:bold size:0]];
        titleLabel.textColor = [BrandColorsUIKit inkPrimary];
        titleLabel.adjustsFontForContentSizeCategory = YES;
        titleLabel.numberOfLines = 0;
        titleLabel.userInteractionEnabled = NO;

        UILabel *subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.text = subtitle;
        subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        subtitleLabel.textColor = [BrandColorsUIKit inkSecondary];
        subtitleLabel.adjustsFontForContentSizeCategory = YES;
        subtitleLabel.numberOfLines = 0;
        subtitleLabel.userInteractionEnabled = NO;

        UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, subtitleLabel]];
        textStack.axis = UILayoutConstraintAxisVertical;
        textStack.spacing = 2.0;
        textStack.userInteractionEnabled = NO;

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[_iconCircle, textStack]];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.alignment = UIStackViewAlignmentCenter;
        row.spacing = 10.0;
        row.userInteractionEnabled = NO;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.layoutMarginsRelativeArrangement = YES;
        row.layoutMargins = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);
        [self addSubview:row];
        [NSLayoutConstraint activateConstraints:@[
            [row.topAnchor constraintEqualToAnchor:self.topAnchor],
            [row.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [row.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];

        [self mk_applyStyle];
    }
    return self;
}

- (void)setSelectedPill:(BOOL)selectedPill {
    _selectedPill = selectedPill;
    [self mk_applyStyle];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self mk_applyStyle];
}

- (void)mk_applyStyle {
    UIColor *borderColor = self.selectedPill ? [BrandColorsUIKit brandTeal] : [BrandColorsUIKit divider];
    self.layer.borderColor = borderColor.CGColor;
    self.backgroundColor = self.selectedPill ? [BrandColorsUIKit tealLight] : [BrandColorsUIKit surfaceCard];
    _iconCircle.layer.borderColor = [BrandColorsUIKit brandTeal].CGColor;
    self.accessibilityTraits = self.selectedPill
        ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected)
        : UIAccessibilityTraitButton;
}

@end

#pragma mark - MKBellScheduleRowView

// 1 dòng trong card "Lịch ngân chuông" (`.mrow` trong design): nhãn + mô tả ngắn bên trái, công
// tắc bên phải; khi BẬT hiện thêm 1 dòng cấu hình nhỏ màu teal bên dưới (`.mcfg`). `configText`
// nil (dòng "Đầu mỗi giờ") -> không có dòng cấu hình, đúng design (không phải thiếu sót).
@interface MKBellScheduleRowView : UIView
@property (nonatomic, strong, readonly) UISwitch *toggleSwitch;
@property (nonatomic, copy, nullable) void (^onToggle)(BOOL on);
- (instancetype)initWithTitle:(NSString *)title detail:(NSString *)detail configText:(nullable NSString *)configText;
// Nạp giá trị đã lưu — KHÔNG bắn onToggle (tránh ghi App Group lại giá trị vừa đọc ra).
- (void)setToggleOn:(BOOL)on;
@end

@implementation MKBellScheduleRowView {
    UILabel *_configLabel;
}

- (instancetype)initWithTitle:(NSString *)title detail:(NSString *)detail configText:(nullable NSString *)configText {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        UILabel *titleLabel = [OnboardingUI bodyLabel:title];
        UILabel *detailLabel = [[UILabel alloc] init];
        detailLabel.text = detail;
        detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        detailLabel.textColor = [BrandColorsUIKit inkSecondary];
        detailLabel.numberOfLines = 0;
        detailLabel.adjustsFontForContentSizeCategory = YES;

        UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, detailLabel]];
        textStack.axis = UILayoutConstraintAxisVertical;
        textStack.spacing = 2.0;
        [textStack setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

        _toggleSwitch = [[UISwitch alloc] init];
        // KHÔNG dùng tint xanh-lá mặc định của UISwitch — set thẳng token teal (đúng nguyên tắc
        // đã áp cho inputTypeControl/heightSlider ở SettingsViewController.m).
        _toggleSwitch.onTintColor = [BrandColorsUIKit brandTeal];
        _toggleSwitch.accessibilityLabel = title;
        [_toggleSwitch addTarget:self action:@selector(mk_switchChanged) forControlEvents:UIControlEventValueChanged];
        [_toggleSwitch setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[textStack, _toggleSwitch]];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.alignment = UIStackViewAlignmentCenter;
        row.spacing = 12.0;
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;

        UIStackView *outer = [[UIStackView alloc] initWithArrangedSubviews:@[row]];
        outer.axis = UILayoutConstraintAxisVertical;
        outer.spacing = 4.0;
        outer.translatesAutoresizingMaskIntoConstraints = NO;

        if (configText != nil) {
            _configLabel = [[UILabel alloc] init];
            _configLabel.text = configText;
            _configLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            _configLabel.textColor = [BrandColorsUIKit tealStrong];
            _configLabel.numberOfLines = 0;
            _configLabel.adjustsFontForContentSizeCategory = YES;
            _configLabel.hidden = YES;   // ẩn mặc định — chỉ hiện khi công tắc BẬT
            [outer addArrangedSubview:_configLabel];
        }

        [self addSubview:outer];
        [NSLayoutConstraint activateConstraints:@[
            [outer.topAnchor constraintEqualToAnchor:self.topAnchor constant:8.0],
            [outer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8.0],
            [outer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:15.0],
            [outer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-15.0],
        ]];
    }
    return self;
}

- (void)mk_switchChanged {
    BOOL on = self.toggleSwitch.on;
    _configLabel.hidden = !on;
    if (self.onToggle != nil) {
        self.onToggle(on);
    }
}

- (void)setToggleOn:(BOOL)on {
    self.toggleSwitch.on = on;
    _configLabel.hidden = !on;
}

@end

#pragma mark - MKBreathRingsView

// 2 vòng tròn lan toả + 1 sóng ngang tĩnh — hoạt cảnh "thở" (`.rings`/`.rg`/wave svg trong overlay
// design). Honor Reduce Motion (hiến chương + DESIGN.md a11y): -startAnimatingIfAllowed KHÔNG
// thêm animation nào nếu UIAccessibilityIsReduceMotionEnabled() — vòng tròn/sóng vẫn vẽ, chỉ
// đứng yên.
@interface MKBreathRingsView : UIView
- (void)startAnimatingIfAllowed;
@end

@implementation MKBreathRingsView {
    UIView *_ring1;
    UIView *_ring2;
    CAShapeLayer *_waveLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.isAccessibilityElement = NO;   // trang trí — nghĩa nằm ở label "Thở vào… thở ra" đi kèm

        _ring1 = [self mk_makeRing];
        _ring2 = [self mk_makeRing];
        [self addSubview:_ring1];
        [self addSubview:_ring2];

        _waveLayer = [CAShapeLayer layer];
        _waveLayer.fillColor = [UIColor clearColor].CGColor;
        _waveLayer.lineWidth = 3.0;
        _waveLayer.lineCap = kCALineCapRound;
        _waveLayer.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_waveLayer];

        [self mk_applyStrokeColors];
    }
    return self;
}

- (UIView *)mk_makeRing {
    UIView *ring = [[UIView alloc] init];
    ring.backgroundColor = [UIColor clearColor];
    ring.layer.borderWidth = 2.0;
    ring.layer.cornerRadius = 33.0;   // 66pt đường kính, khớp `.rg{width:66;height:66}`
    ring.layer.opacity = 0.5;
    return ring;
}

- (void)mk_applyStrokeColors {
    CGColorRef teal = [BrandColorsUIKit brandTeal].CGColor;
    _ring1.layer.borderColor = teal;
    _ring2.layer.borderColor = teal;
    _waveLayer.strokeColor = teal;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self mk_applyStrokeColors];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat ringSize = 66.0;
    CGRect ringFrame = CGRectMake((CGRectGetWidth(self.bounds) - ringSize) / 2.0,
                                   (CGRectGetHeight(self.bounds) - ringSize) / 2.0 - 10.0,
                                   ringSize, ringSize);
    _ring1.frame = ringFrame;
    _ring2.frame = ringFrame;

    _waveLayer.frame = self.bounds;
    _waveLayer.path = [self mk_wavePath].CGPath;
    [self mk_applyStrokeColors];
}

// Sóng ngang lặp chu kỳ 40pt, vẽ dư 1 chu kỳ mỗi bên để trượt ngang mượt không lộ mép khi animate.
- (UIBezierPath *)mk_wavePath {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat midY = CGRectGetHeight(self.bounds) - 18.0;
    CGFloat amp = 11.0;
    CGFloat period = 40.0;
    NSInteger steps = 64;
    CGFloat startX = -period;
    CGFloat totalW = w + period * 2.0;
    for (NSInteger i = 0; i <= steps; i++) {
        CGFloat t = (CGFloat)i / (CGFloat)steps;
        CGFloat x = startX + t * totalW;
        CGFloat y = midY - amp * sin((x / period) * 2.0 * M_PI);
        if (i == 0) {
            [path moveToPoint:CGPointMake(x, y)];
        } else {
            [path addLineToPoint:CGPointMake(x, y)];
        }
    }
    return path;
}

- (void)startAnimatingIfAllowed {
    if (UIAccessibilityIsReduceMotionEnabled()) {
        return;   // Giảm chuyển động — vòng tròn/sóng đứng yên, KHÔNG thêm animation nào.
    }
    [self mk_startRingPulse:_ring1 delay:0.0];
    [self mk_startRingPulse:_ring2 delay:1.6];   // lệch pha nửa chu kỳ, khớp `.rg.r2{animation-delay:1.6s}`
    [self mk_startWaveDrift];
}

- (void)mk_startRingPulse:(UIView *)ring delay:(CFTimeInterval)delay {
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @(0.55);
    scale.toValue = @(2.5);

    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = @(0.55);
    opacity.toValue = @(0.0);

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, opacity];
    group.duration = 3.2;   // khớp `@keyframes rp{...} .rg{animation:rp 3.2s ease-out infinite}`
    group.repeatCount = HUGE_VALF;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.beginTime = CACurrentMediaTime() + delay;
    [ring.layer addAnimation:group forKey:@"mkBreathRingPulse"];
}

// byValue = -period sóng: mỗi vòng lặp "giật" về vị trí gốc, nhưng vì path lặp đúng chu kỳ 40pt
// nên khung hình reset trông giống hệt khung trước đó — mắt thấy sóng trôi liên tục, không giật.
- (void)mk_startWaveDrift {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position.x"];
    anim.byValue = @(-40.0);
    anim.duration = 2.0;
    anim.repeatCount = HUGE_VALF;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [_waveLayer addAnimation:anim forKey:@"mkBreathWaveDrift"];
}

@end

#pragma mark - MKBreathOverlayViewController

// Màn thở toàn màn (`.ov` trong design) — mở từ "Ngân thử một tiếng". KHÔNG âm thanh (container
// app không link AudioToolbox cho việc này — chỉ hoạt cảnh thị giác).
@interface MKBreathOverlayViewController : UIViewController
@end

@implementation MKBreathOverlayViewController {
    MKBreathRingsView *_ringsView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 14.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    _ringsView = [[MKBreathRingsView alloc] init];
    _ringsView.translatesAutoresizingMaskIntoConstraints = NO;
    [_ringsView.widthAnchor constraintEqualToConstant:200.0].active = YES;
    [_ringsView.heightAnchor constraintEqualToConstant:150.0].active = YES;
    [stack addArrangedSubview:_ringsView];

    UILabel *heading = [[UILabel alloc] init];
    heading.text = @"Thở vào… thở ra";
    heading.textColor = [BrandColorsUIKit brandTeal];
    UIFontDescriptor *bold = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleTitle2]
                              fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    heading.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:bold size:0]];
    heading.adjustsFontForContentSizeCategory = YES;
    heading.numberOfLines = 0;
    heading.textAlignment = NSTextAlignmentCenter;
    heading.accessibilityTraits |= UIAccessibilityTraitHeader;
    [stack addArrangedSubview:heading];

    // Quan sát trung tính — "chuông vừa ngân, một hơi thôi" — KHÔNG nhắc nợ/đếm số (hiến chương).
    UILabel *body = [OnboardingUI subtitleLabel:@"Chuông vừa ngân. Một hơi thôi, rồi tiếp tục."];
    body.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:body];
    [stack setCustomSpacing:22.0 afterView:body];

    UIButton *done = MKBellPillButton(@"Xong");
    done.accessibilityLabel = @"Xong, đóng màn thở";
    [done addTarget:self action:@selector(mk_doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:done];

    [NSLayoutConstraint activateConstraints:@[
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:36.0],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-36.0],
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_ringsView startAnimatingIfAllowed];
}

- (void)mk_doneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - BellSettingsViewController

@interface BellSettingsViewController ()
@property (nonatomic, strong) MKBellSoundPillControl *bigPill;
@property (nonatomic, strong) MKBellSoundPillControl *smallPill;
@property (nonatomic, strong) MKBellScheduleRowView *periodicRow;
@property (nonatomic, strong) MKBellScheduleRowView *naturalRow;
@property (nonatomic, strong) MKBellScheduleRowView *reminderRow;
@property (nonatomic, strong) MKBellScheduleRowView *hourlyRow;
@property (nonatomic, strong) UISwitch *quietHoursSwitch;
@end

@implementation BellSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    [self mk_buildUI];
    [self mk_refreshFromStore];
}

// Đề phòng giá trị đổi từ nơi khác trong cùng phiên — đúng pattern SettingsViewController.m.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self mk_refreshFromStore];
}

#pragma mark - Dựng UI

- (void)mk_buildUI {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 8.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    UILabel *title = [OnboardingUI titleLabel:@"Chuông tỉnh thức"];
    UILabel *subtitle = [OnboardingUI subtitleLabel:@"Một tiếng chuông mời bạn dừng lại và thở. Không nhắc nợ, không đếm số."];
    [stack addArrangedSubview:title];
    [stack addArrangedSubview:subtitle];
    [stack setCustomSpacing:24.0 afterView:subtitle];

    // ===== Tiếng chuông =====
    UILabel *soundSection = [self mk_sectionLabel:@"Tiếng chuông"];
    [stack addArrangedSubview:soundSection];
    [stack setCustomSpacing:10.0 afterView:soundSection];

    self.bigPill = [[MKBellSoundPillControl alloc] initWithTitle:@"Chuông lớn" subtitle:@"Ngân sâu, lắng"];
    [self.bigPill addTarget:self action:@selector(mk_selectBig) forControlEvents:UIControlEventTouchUpInside];
    self.smallPill = [[MKBellSoundPillControl alloc] initWithTitle:@"Chuông nhỏ" subtitle:@"Trong, nhẹ"];
    [self.smallPill addTarget:self action:@selector(mk_selectSmall) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *soundRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.bigPill, self.smallPill]];
    soundRow.axis = UILayoutConstraintAxisHorizontal;
    soundRow.distribution = UIStackViewDistributionFillEqually;
    soundRow.spacing = 10.0;
    [stack addArrangedSubview:soundRow];
    [stack setCustomSpacing:24.0 afterView:soundRow];

    // ===== Lịch ngân chuông =====
    UILabel *scheduleSection = [self mk_sectionLabel:@"Lịch ngân chuông"];
    [stack addArrangedSubview:scheduleSection];
    [stack setCustomSpacing:10.0 afterView:scheduleSection];

    self.periodicRow = [[MKBellScheduleRowView alloc] initWithTitle:@"Định kỳ"
                                                               detail:@"Ngân đều theo khoảng thời gian"
                                                           configText:@"Nhỏ mỗi 15 phút · lớn mỗi 30 phút"];
    self.periodicRow.onToggle = ^(BOOL on) { BellScheduleSettingsBridge_SetPeriodicOn(on); };

    self.naturalRow = [[MKBellScheduleRowView alloc] initWithTitle:@"Thưa nhặt tự nhiên"
                                                              detail:@"Cách quãng ngẫu nhiên, không đều"
                                                          configText:@"Cách nhau 15–60 phút"];
    self.naturalRow.onToggle = ^(BOOL on) { BellScheduleSettingsBridge_SetNaturalOn(on); };

    self.reminderRow = [[MKBellScheduleRowView alloc] initWithTitle:@"Hẹn một khắc"
                                                               detail:@"Vào giờ bạn chọn trong ngày"
                                                           configText:@"Chuông lớn lúc 20:52"];
    self.reminderRow.onToggle = ^(BOOL on) { BellScheduleSettingsBridge_SetReminderOn(on); };

    self.hourlyRow = [[MKBellScheduleRowView alloc] initWithTitle:@"Đầu mỗi giờ"
                                                             detail:@"Ngân chuông lớn đầu mỗi giờ"
                                                         configText:nil];
    self.hourlyRow.onToggle = ^(BOOL on) { BellScheduleSettingsBridge_SetHourlyOn(on); };

    UIView *scheduleCard = [self mk_cardWithRows:@[self.periodicRow, self.naturalRow, self.reminderRow, self.hourlyRow]];
    [stack addArrangedSubview:scheduleCard];
    [stack setCustomSpacing:24.0 afterView:scheduleCard];

    // ===== Yên tĩnh =====
    UILabel *quietSection = [self mk_sectionLabel:@"Yên tĩnh"];
    [stack addArrangedSubview:quietSection];
    [stack setCustomSpacing:10.0 afterView:quietSection];

    UIView *quietCard = [self mk_cardWithRows:@[[self mk_quietHoursRow]]];
    [stack addArrangedSubview:quietCard];
    [stack setCustomSpacing:32.0 afterView:quietCard];

    // ===== Ngân thử + credit =====
    UIButton *ringTestButton = MKBellPillButton(@"Ngân thử một tiếng");
    ringTestButton.accessibilityLabel = @"Ngân thử một tiếng";
    [ringTestButton addTarget:self action:@selector(mk_ringTestTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:ringTestButton];
    [stack setCustomSpacing:11.0 afterView:ringTestButton];

    UILabel *credit = [[UILabel alloc] init];
    credit.text = @"Cảm hứng từ lời dạy của Thiền sư Thích Nhất Hạnh.";
    credit.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    credit.textColor = [BrandColorsUIKit inkSecondary];
    credit.textAlignment = NSTextAlignmentCenter;
    credit.numberOfLines = 0;
    credit.adjustsFontForContentSizeCategory = YES;
    [stack addArrangedSubview:credit];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:8],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-24],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-40],
    ]];
}

// Nhãn mục ("TIẾNG CHUÔNG" kiểu chữ hoa nhỏ, `.sec` trong design).
- (UILabel *)mk_sectionLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = [text uppercaseString];
    UIFontDescriptor *bold = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote]
                              fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    label.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:bold size:0]];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [BrandColorsUIKit inkSecondary];
    return label;
}

// Card chung cho "Lịch ngân chuông" / "Yên tĩnh" — nối các dòng bằng 1 divider mảnh giữa 2 dòng
// liên tiếp (`.rowb` trong design), KHÔNG chèn divider trước dòng đầu hay sau dòng cuối.
- (UIView *)mk_cardWithRows:(NSArray<UIView *> *)rows {
    MKBorderedCardView *card = [[MKBorderedCardView alloc] init];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSUInteger i = 0; i < rows.count; i++) {
        if (i > 0) {
            [stack addArrangedSubview:[self mk_hairlineDivider]];
        }
        [stack addArrangedSubview:rows[i]];
    }
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
    ]];
    return card;
}

- (UIView *)mk_hairlineDivider {
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [BrandColorsUIKit divider];
    [divider.heightAnchor constraintEqualToConstant:1.0].active = YES;
    return divider;
}

// "Giờ tĩnh lặng · 22:00–06:00" — 1 dòng đơn giản (nhãn + công tắc), KHÔNG có dòng cấu hình phụ
// (khác `.mrow`, đây là `.row` thường trong design — chỉ 22:00–06:00 tĩnh, không phải number picker).
- (UIView *)mk_quietHoursRow {
    UILabel *label = [OnboardingUI bodyLabel:@"Giờ tĩnh lặng · 22:00–06:00"];
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    self.quietHoursSwitch = [[UISwitch alloc] init];
    self.quietHoursSwitch.onTintColor = [BrandColorsUIKit brandTeal];
    self.quietHoursSwitch.accessibilityLabel = @"Giờ tĩnh lặng";
    [self.quietHoursSwitch addTarget:self action:@selector(mk_quietHoursChanged) forControlEvents:UIControlEventValueChanged];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[label, self.quietHoursSwitch]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 12.0;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.layoutMarginsRelativeArrangement = YES;
    row.layoutMargins = UIEdgeInsetsMake(14.0, 15.0, 14.0, 15.0);
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
    return row;
}

#pragma mark - Đọc/ghi App Group

- (void)mk_refreshFromStore {
    [self mk_refreshSoundPills];
    [self.periodicRow setToggleOn:BellScheduleSettingsBridge_IsPeriodicOn()];
    [self.naturalRow setToggleOn:BellScheduleSettingsBridge_IsNaturalOn()];
    [self.reminderRow setToggleOn:BellScheduleSettingsBridge_IsReminderOn()];
    [self.hourlyRow setToggleOn:BellScheduleSettingsBridge_IsHourlyOn()];
    self.quietHoursSwitch.on = BellScheduleSettingsBridge_IsQuietHoursOn();
}

- (void)mk_refreshSoundPills {
    BellScheduleSound choice = BellScheduleSettingsBridge_ReadSoundChoice();
    self.bigPill.selectedPill = (choice == BellScheduleSoundBig);
    self.smallPill.selectedPill = (choice == BellScheduleSoundSmall);
}

- (void)mk_selectBig {
    BellScheduleSettingsBridge_WriteSoundChoice(BellScheduleSoundBig);
    [self mk_refreshSoundPills];
}

- (void)mk_selectSmall {
    BellScheduleSettingsBridge_WriteSoundChoice(BellScheduleSoundSmall);
    [self mk_refreshSoundPills];
}

- (void)mk_quietHoursChanged {
    BellScheduleSettingsBridge_SetQuietHoursOn(self.quietHoursSwitch.on);
}

#pragma mark - Ngân thử

- (void)mk_ringTestTapped {
    MKBreathOverlayViewController *overlay = [[MKBreathOverlayViewController alloc] init];
    overlay.modalPresentationStyle = UIModalPresentationFullScreen;
    overlay.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:overlay animated:YES completion:nil];
}

@end
