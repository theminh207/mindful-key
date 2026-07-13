//
//  MoodLakeViewController.m
//  mindful-key — iOS container app (màn "Mặt hồ" — soi lại cuối ngày, Round 3 story 3.3)
//
//  2 trạng thái nội bộ đổi TẠI CHỖ (không push VC mới) — mirror state machine "matho" của bản
//  thiết kế (Mindful Key Prototype.dc.html, tabMatho / mathoSoilai / mathoThang):
//    - Soi lại (mặc định): câu hỏi phản chiếu (qcard) là TIÊU ĐIỂM thị giác — nền card riêng,
//      viền + đổ bóng teal nhạt, chữ đậm. Số liệu Q4 (MoodJournalStore_FetchTodaySummary) chỉ là
//      BỐI CẢNH PHỤ, chữ nhỏ, đặt DƯỚI câu hỏi — không biểu đồ, không timeline.
//    - Thang mặt hồ tâm: 5 mức An/Nhẹ/Gợn/Sóng/Cuộn — biên độ sóng tăng dần, KHÔNG phải điểm số.
//
//  Nav bar hệ thống bị ẩn toàn app (xem AppDelegate.m) — tự vẽ "‹ Quay lại" ở đầu màn, cùng idiom
//  SettingsViewController.m / MacroManagerViewController.m (story 2.3 / 2.4).
//
//  Đối chiếu hiến chương (docs/AGENT-BRIEF.md) trước khi sửa file này: KHÔNG đèn đỏ/xanh cảm xúc,
//  KHÔNG emoji chấm điểm, KHÔNG game hoá kiểu thi đua/tích luỹ (hiến chương §2.2), copy "mô tả
//  không phán xét". Màu CHỈ lấy từ BrandColorsUIKit (moodLevel: là thang biên độ trung tính, không
//  mã hoá valence).
//

#import "MoodLakeViewController.h"
#import "BrandColorsUIKit.h"
#import "OnboardingUI.h"
#import "MoodJournalStore.h"

typedef NS_ENUM(NSInteger, MKMoodLakeState) {
    MKMoodLakeStateSoiLai = 0,
    MKMoodLakeStateThang,
};

#pragma mark - MKChipButton (pill chọn 1-trong-3, state cục bộ trong phiên)

// Mirror ".qc/.qc.on" trong bản thiết kế: viền 1.5, radius = nửa chiều cao (bo tròn hết cỡ),
// chọn = viền teal + chữ tealStrong + nền tealLight. KHÔNG dùng UIButton.buttonWithType: (subclass
// qua factory đó không đáng tin cậy) — alloc/init trực tiếp.
@interface MKChipButton : UIButton
@property (nonatomic, assign, getter=isChipSelected) BOOL chipSelected;
- (instancetype)initWithChipTitle:(NSString *)title;
@end

@implementation MKChipButton

- (instancetype)initWithChipTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setTitle:title forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        self.titleLabel.adjustsFontForContentSizeCategory = YES;
        self.titleLabel.numberOfLines = 1;
        self.contentEdgeInsets = UIEdgeInsetsMake(8, 14, 8, 14);
        self.layer.borderWidth = 1.5;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        // Sàn cứng 44pt (đúng nguyên tắc OnboardingUI ghostButton) — ưu tiên a11y hit-target hơn
        // đúng y hệt chiều cao pill nhỏ (~30pt) trong ảnh thiết kế.
        [self.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
        [self mk_applyChipStyle];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2.0;
}

- (void)setChipSelected:(BOOL)chipSelected {
    _chipSelected = chipSelected;
    if (chipSelected) {
        self.accessibilityTraits |= UIAccessibilityTraitSelected;
    } else {
        self.accessibilityTraits &= ~UIAccessibilityTraitSelected;
    }
    [self mk_applyChipStyle];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    // Màu động (Light/Dark) không tự cập nhật cho borderColor (CGColor) → set lại khi theme đổi.
    [self mk_applyChipStyle];
}

- (void)mk_applyChipStyle {
    if (self.chipSelected) {
        self.layer.borderColor = [BrandColorsUIKit brandTeal].CGColor;
        self.backgroundColor = [BrandColorsUIKit tealLight];
        [self setTitleColor:[BrandColorsUIKit tealStrong] forState:UIControlStateNormal];
    } else {
        self.layer.borderColor = [BrandColorsUIKit divider].CGColor;
        self.backgroundColor = [UIColor clearColor];
        [self setTitleColor:[BrandColorsUIKit inkPrimary] forState:UIControlStateNormal];
    }
}

@end

#pragma mark - MKMoodWaveView (sóng mini cho 5 hàng thang mặt hồ)

// Vẽ 1 đường sin tĩnh (KHÔNG animate — 5 hàng liệt kê tĩnh, không phải sóng "ambient" như
// BrandMarkView) — biên độ TĂNG DẦN theo mức, mirror biên độ tương đối trong 5 path .mmw của bản
// thiết kế (quy đổi theo chiều cao view thật thay vì hard-code toạ độ viewBox 88x40 cố định).
@interface MKMoodWaveView : UIView
- (instancetype)initWithLevel:(NSInteger)level;
@end

@implementation MKMoodWaveView {
    NSInteger _level;
    CAShapeLayer *_waveLayer;
}

- (instancetype)initWithLevel:(NSInteger)level {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _level = level;
        self.backgroundColor = [UIColor clearColor];
        self.isAccessibilityElement = NO;   // trang trí — nghĩa nằm ở tên mức + trích dẫn đi kèm

        _waveLayer = [CAShapeLayer layer];
        _waveLayer.fillColor = [UIColor clearColor].CGColor;
        _waveLayer.lineWidth = 3.0;
        _waveLayer.lineCap = kCALineCapRound;
        _waveLayer.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_waveLayer];
        [self mk_applyStrokeColor];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self mk_applyStrokeColor];
}

- (void)mk_applyStrokeColor {
    // moodLevel: trung tính ở cả 2 theme (BrandColorsUIKit.m) nhưng CGColor là snapshot — vẫn set
    // lại cho an toàn, cùng pattern BrandMarkView.
    _waveLayer.strokeColor = [BrandColorsUIKit moodLevel:_level].CGColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _waveLayer.frame = self.bounds;
    _waveLayer.path = [self mk_wavePath].CGPath;
}

- (UIBezierPath *)mk_wavePath {
    // Phân số biên độ/chiều cao — lấy từ 5 path .mmw gốc (viewBox 0 0 88 40, baseline y=20):
    // mức 1 lệch ~2/40, mức 2 ~5/40, mức 3 ~9/40, mức 4 ~14/40, mức 5 ~18/40.
    static const CGFloat kAmplitudeFraction[6] = {0.0, 0.05, 0.125, 0.225, 0.35, 0.45};
    NSInteger clampedLevel = MAX(1, MIN(5, _level));
    CGFloat fraction = kAmplitudeFraction[clampedLevel];

    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat midY = h / 2.0;
    CGFloat amp = h * fraction;

    UIBezierPath *path = [UIBezierPath bezierPath];
    NSInteger steps = 48;
    CGFloat cycles = 2.5;
    for (NSInteger i = 0; i <= steps; i++) {
        CGFloat t = (CGFloat)i / (CGFloat)steps;
        CGFloat x = t * w;
        CGFloat y = midY - amp * sin(t * M_PI * cycles);
        if (i == 0) {
            [path moveToPoint:CGPointMake(x, y)];
        } else {
            [path addLineToPoint:CGPointMake(x, y)];
        }
    }
    return path;
}

@end

#pragma mark - MoodLakeViewController

@interface MoodLakeViewController ()
@property (nonatomic, assign) MKMoodLakeState currentState;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UIView *numericContextContainer;
@property (nonatomic, strong) NSArray<MKChipButton *> *chipButtons;
// State cục bộ trong phiên (KHÔNG lưu trữ/không cần persist — đúng yêu cầu story) — giữ nguyên
// khi chuyển qua lại 2 trạng thái nội bộ để không "quên" lựa chọn người dùng vừa chạm.
@property (nonatomic, assign) NSInteger selectedChipIndex;
@end

@implementation MoodLakeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    self.selectedChipIndex = 0;   // mặc định "Có, vài lần" — đúng bản thiết kế
    [self mk_buildChrome];
    [self mk_switchToState:MKMoodLakeStateSoiLai];
}

#pragma mark - Khung màn (header cố định + scroll nội dung đổi theo state)

- (void)mk_buildChrome {
    UIView *header = [self mk_headerRow];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    [self.view addSubview:scroll];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.alignment = UIStackViewAlignmentFill;
    self.contentStack.spacing = 8;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:self.contentStack];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [header.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],

        [scroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:16],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentStack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:8],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-24],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:20],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-20],
        [self.contentStack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-40],
    ]];
}

// Cùng idiom SettingsViewController.m / MacroManagerViewController.m: nav bar hệ thống bị ẩn toàn
// app nên mỗi màn tự vẽ "Quay lại". Tiêu đề header CỐ ĐỊNH "Mặt hồ" (định danh màn) — khác 2 h1
// đổi theo state bên trong nội dung cuộn (đúng bản thiết kế: h1 là tiêu đề CÂU HỎI/THANG, không
// phải tiêu đề màn).
- (UIView *)mk_headerRow {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8;

    UIButton *back = [OnboardingUI ghostButton:@"‹ Quay lại"];
    back.accessibilityLabel = @"Quay lại";
    [back addTarget:self action:@selector(mk_backTapped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *title = [OnboardingUI titleLabel:@"Mặt hồ"];
    title.textAlignment = NSTextAlignmentCenter;
    title.accessibilityTraits |= UIAccessibilityTraitHeader;

    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    [row addArrangedSubview:back];
    [row addArrangedSubview:title];
    [row addArrangedSubview:spacer];
    return row;
}

- (void)mk_backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Đổi trạng thái nội bộ (Soi lại ⇄ Thang mặt hồ) — KHÔNG push VC mới

- (void)mk_switchToState:(MKMoodLakeState)state {
    self.currentState = state;
    for (UIView *v in self.contentStack.arrangedSubviews) {
        [self.contentStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    if (state == MKMoodLakeStateSoiLai) {
        [self mk_populateSoilaiContent];
    } else {
        [self mk_populateThangContent];
    }
}

#pragma mark - State "Soi lại"

- (void)mk_populateSoilaiContent {
    UILabel *title = [OnboardingUI titleLabel:@"Hôm nay, mặt hồ của bạn"];
    UILabel *subtitle = [OnboardingUI subtitleLabel:@"Một câu để soi lại — không chấm điểm, không biểu đồ."];

    UIView *qcard = [self mk_buildQuestionCard];

    self.numericContextContainer = [[UIView alloc] init];
    self.numericContextContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self mk_refreshNumericContext];

    UIView *openScaleRow = [self mk_buildOpenScaleRow];
    UILabel *humanLine = [self mk_buildHumanLine];

    [self.contentStack addArrangedSubview:title];
    [self.contentStack addArrangedSubview:subtitle];
    [self.contentStack setCustomSpacing:18 afterView:subtitle];
    [self.contentStack addArrangedSubview:qcard];
    // Bối cảnh Q4 nằm NGAY dưới câu hỏi nhưng gap nhỏ hơn (10) — giữ nó nhỏ/phụ, không tách xa
    // thành 1 khối riêng biệt trông như phần "quan trọng thứ 2".
    [self.contentStack setCustomSpacing:10 afterView:qcard];
    [self.contentStack addArrangedSubview:self.numericContextContainer];
    [self.contentStack setCustomSpacing:14 afterView:self.numericContextContainer];
    [self.contentStack addArrangedSubview:openScaleRow];
    [self.contentStack setCustomSpacing:16 afterView:openScaleRow];
    [self.contentStack addArrangedSubview:humanLine];
}

// .qcard: card tiêu điểm — nền card, viền mảnh + đổ bóng teal nhạt, bo góc 16, padding 17. Câu hỏi
// (qt) là chữ ĐẬM nhất/màu ink chính trong toàn màn — tiêu điểm phân cấp thị giác theo yêu cầu.
- (UIView *)mk_buildQuestionCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [BrandColorsUIKit surfaceCard];
    card.layer.cornerRadius = 16.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [BrandColorsUIKit divider].CGColor;
    card.layer.shadowColor = [BrandColorsUIKit brandTeal].CGColor;
    card.layer.shadowOpacity = 0.08;
    card.layer.shadowRadius = 13.0;
    card.layer.shadowOffset = CGSizeMake(0, 8);
    card.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *qt = [self mk_questionTextLabel:@"Hôm nay có lúc nào mặt hồ dậy sóng không?"];
    UILabel *qh = [self mk_captionLabel:@"Chỉ bạn thấy. Không có câu trả lời đúng."];
    UIView *chips = [self mk_buildChipsRow];

    UIStackView *inner = [[UIStackView alloc] init];
    inner.axis = UILayoutConstraintAxisVertical;
    inner.alignment = UIStackViewAlignmentFill;
    inner.spacing = 8;
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    [inner addArrangedSubview:qt];
    [inner addArrangedSubview:qh];
    [inner setCustomSpacing:14 afterView:qh];
    [inner addArrangedSubview:chips];

    [card addSubview:inner];
    [NSLayoutConstraint activateConstraints:@[
        [inner.topAnchor constraintEqualToAnchor:card.topAnchor constant:17],
        [inner.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-17],
        [inner.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:17],
        [inner.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-17],
    ]];
    return card;
}

// .qt — 19px/Bold trong bản thiết kế. Dùng Title3 (Dynamic Type) + ép Bold qua UIFontMetrics,
// cùng kỹ thuật OnboardingUI.titleLabel đã dùng cho Title2.
- (UILabel *)mk_questionTextLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    UIFontDescriptor *d = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleTitle3]
                           fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    l.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:d size:0]];
    l.adjustsFontForContentSizeCategory = YES;
    l.textColor = [BrandColorsUIKit inkPrimary];
    l.numberOfLines = 0;
    l.translatesAutoresizingMaskIntoConstraints = NO;
    return l;
}

// Dùng chung cho: qh (gợi ý câu hỏi), bối cảnh Q4, trích dẫn ở thang mặt hồ — mọi chữ "phụ/nhỏ"
// trong màn này đều qua đúng 1 chỗ để nhất quán (.qh/.mqq đều muted ~13px trong bản thiết kế).
- (UILabel *)mk_captionLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    l.adjustsFontForContentSizeCategory = YES;
    l.textColor = [BrandColorsUIKit inkSecondary];
    l.numberOfLines = 0;
    l.translatesAutoresizingMaskIntoConstraints = NO;
    return l;
}

// 3 pill chọn 1 — state CỤC BỘ trong phiên (đúng yêu cầu: không cần persist gì thêm).
- (UIView *)mk_buildChipsRow {
    NSArray<NSString *> *titles = @[@"Có, vài lần", @"Một chút", @"Khá lặng"];

    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentLeading;
    row.spacing = 8;
    row.translatesAutoresizingMaskIntoConstraints = NO;

    NSMutableArray<MKChipButton *> *buttons = [NSMutableArray arrayWithCapacity:titles.count];
    for (NSInteger i = 0; i < (NSInteger)titles.count; i++) {
        MKChipButton *chip = [[MKChipButton alloc] initWithChipTitle:titles[i]];
        chip.tag = i;
        chip.chipSelected = (i == self.selectedChipIndex);
        chip.accessibilityLabel = titles[i];
        [chip addTarget:self action:@selector(mk_chipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:chip];
        [row addArrangedSubview:chip];
    }
    self.chipButtons = buttons;
    return row;
}

- (void)mk_chipTapped:(MKChipButton *)sender {
    self.selectedChipIndex = sender.tag;
    for (MKChipButton *chip in self.chipButtons) {
        chip.chipSelected = (chip == sender);
    }
    // Chỉ đổi UI tại chỗ — KHÔNG ghi vào MoodJournalStore, KHÔNG tính điểm/chấm gì thêm (hiến
    // chương: quan sát không phán xét, đây chỉ là 1 câu tự soi của người dùng, không phải input mô
    // hình).
}

// Bối cảnh số liệu Q4 — NHỎ, PHỤ, đặt DƯỚI câu hỏi. Consent NO → mời bật (KHÔNG ép). Consent YES →
// 1 dòng chữ nhỏ, không biểu đồ/timeline (đúng luật cứng story).
- (void)mk_refreshNumericContext {
    for (UIView *v in self.numericContextContainer.subviews) {
        [v removeFromSuperview];
    }
    UIView *content = MoodJournalStore_HasConsent()
        ? [self mk_buildNumericSummaryView]
        : [self mk_buildConsentInviteView];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.numericContextContainer addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:self.numericContextContainer.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:self.numericContextContainer.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:self.numericContextContainer.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:self.numericContextContainer.trailingAnchor],
    ]];
}

- (UIView *)mk_buildNumericSummaryView {
    NSDictionary<NSString *, NSNumber *> *summary = MoodJournalStore_FetchTodaySummary();
    NSInteger tenseCount = [summary[@"tenseCount"] integerValue];
    NSInteger peakHour = [summary[@"peakHour"] integerValue];

    NSString *text;
    if (tenseCount <= 0) {
        text = @"Hôm nay mặt hồ khá lặng.";
    } else {
        text = [NSString stringWithFormat:@"Hôm nay mặt hồ gợn sóng %ld lần", (long)tenseCount];
        if (peakHour >= 0) {
            text = [text stringByAppendingFormat:@" · dễ căng nhất quãng %ldh", (long)peakHour];
        }
    }
    return [self mk_captionLabel:text];
}

// Consent NO — KHÔNG hiện số giả/số 0 gây hiểu lầm, mời bật bằng giọng bình thản + cam kết riêng
// tư ngay trong câu mời (mirror docs/PRIVACY-NOTE.md), nút ghost (phụ, không phải CTA cam nổi bật).
- (UIView *)mk_buildConsentInviteView {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentLeading;
    stack.spacing = 4;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *invite = [self mk_captionLabel:@"Bật ghi nhận nhẹ để soi lại rõ hơn — mọi thứ ở lại trên máy này."];
    UIButton *enable = [OnboardingUI ghostButton:@"Bật ghi nhận"];
    enable.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [enable addTarget:self action:@selector(mk_enableConsentTapped) forControlEvents:UIControlEventTouchUpInside];

    [stack addArrangedSubview:invite];
    [stack addArrangedSubview:enable];
    return stack;
}

- (void)mk_enableConsentTapped {
    MoodJournalStore_SetConsent(YES);
    [self mk_refreshNumericContext];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Đã bật ghi nhận nhẹ");
}

// .card2 .row "Xem thang mặt hồ · 5 mức" — cùng idiom mk_macroRow (MacroManagerViewController):
// chevron gõ thẳng vào chữ title thay vì icon riêng.
- (UIView *)mk_buildOpenScaleRow {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [BrandColorsUIKit surfaceCard];
    card.layer.cornerRadius = 14.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [BrandColorsUIKit divider].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *row = [UIButton buttonWithType:UIButtonTypeSystem];
    [row setTitle:@"Xem thang mặt hồ · 5 mức  ›" forState:UIControlStateNormal];
    [row setTitleColor:[BrandColorsUIKit brandTeal] forState:UIControlStateNormal];
    UIFontDescriptor *d = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody]
                           fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    row.titleLabel.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:d size:0]];
    row.titleLabel.adjustsFontForContentSizeCategory = YES;
    row.titleLabel.numberOfLines = 0;
    row.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    row.accessibilityLabel = @"Xem thang mặt hồ, 5 mức";
    row.accessibilityTraits |= UIAccessibilityTraitButton;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
    [row addTarget:self action:@selector(mk_openThangTapped) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:row];
    [NSLayoutConstraint activateConstraints:@[
        [row.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [row.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
        [row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],
        [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],
    ]];
    return card;
}

- (void)mk_openThangTapped {
    [self mk_switchToState:MKMoodLakeStateThang];
}

// .human — chữ thường ink chính, riêng cụm "điều đó rất người" đậm + teal (.human b{color:teal}).
- (UILabel *)mk_buildHumanLine {
    UILabel *l = [[UILabel alloc] init];
    l.numberOfLines = 0;
    l.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    l.adjustsFontForContentSizeCategory = YES;
    l.translatesAutoresizingMaskIntoConstraints = NO;

    NSString *full = @"Nếu có — điều đó rất người. Sóng lên rồi sóng lặng, mặt hồ vẫn là mặt hồ.";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full];
    [attr addAttribute:NSForegroundColorAttributeName
                  value:[BrandColorsUIKit inkPrimary]
                  range:NSMakeRange(0, full.length)];

    NSRange boldRange = [full rangeOfString:@"điều đó rất người"];
    if (boldRange.location != NSNotFound) {
        UIFontDescriptor *bd = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleSubheadline]
                                fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        UIFont *boldFont = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:bd size:0]];
        [attr addAttribute:NSFontAttributeName value:boldFont range:boldRange];
        [attr addAttribute:NSForegroundColorAttributeName value:[BrandColorsUIKit brandTeal] range:boldRange];
    }
    l.attributedText = attr;
    return l;
}

#pragma mark - State "Thang mặt hồ"

- (void)mk_populateThangContent {
    UIButton *back = [OnboardingUI ghostButton:@"‹ Soi lại"];
    back.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [back addTarget:self action:@selector(mk_backToSoilaiTapped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *title = [OnboardingUI titleLabel:@"Thang mặt hồ tâm"];
    UILabel *subtitle = [OnboardingUI subtitleLabel:@"Cảm xúc = biên độ sóng, không phải điểm số."];

    [self.contentStack addArrangedSubview:back];
    [self.contentStack setCustomSpacing:8 afterView:back];
    [self.contentStack addArrangedSubview:title];
    [self.contentStack addArrangedSubview:subtitle];
    [self.contentStack setCustomSpacing:18 afterView:subtitle];

    NSArray<NSString *> *names = @[@"An", @"Nhẹ", @"Gợn", @"Sóng", @"Cuộn"];
    NSArray<NSString *> *quotes = @[@"Mặt hồ đang lặng",
                                     @"Có chút gợn thoảng qua",
                                     @"Mặt hồ đang gợn sóng",
                                     @"Sóng đang lên rõ rệt",
                                     @"Mặt hồ đang cuộn"];

    for (NSInteger i = 0; i < 5; i++) {
        if (i > 0) {
            [self.contentStack addArrangedSubview:[self mk_dividerView]];
        }
        UIView *row = [self mk_buildMoodRowLevel:(i + 1) name:names[i] quote:quotes[i]];
        [self.contentStack addArrangedSubview:row];
    }
}

- (void)mk_backToSoilaiTapped {
    [self mk_switchToState:MKMoodLakeStateSoiLai];
}

// .mood: số mức nhỏ muted · sóng mini · tên đậm + trích dẫn muted. Gộp thành 1 phần tử a11y để
// VoiceOver đọc liền mạch "Mức N trên 5, {tên}: {trích dẫn}" thay vì rời rạc 4 lượt focus.
- (UIView *)mk_buildMoodRowLevel:(NSInteger)level name:(NSString *)name quote:(NSString *)quote {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 13;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;

    UILabel *lvl = [[UILabel alloc] init];
    lvl.text = [NSString stringWithFormat:@"%ld", (long)level];
    UIFontDescriptor *ld = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1]
                            fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    lvl.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:ld size:0]];
    lvl.adjustsFontForContentSizeCategory = YES;
    lvl.textColor = [BrandColorsUIKit inkSecondary];
    lvl.translatesAutoresizingMaskIntoConstraints = NO;
    [lvl.widthAnchor constraintGreaterThanOrEqualToConstant:16.0].active = YES;

    MKMoodWaveView *wave = [[MKMoodWaveView alloc] initWithLevel:level];
    wave.translatesAutoresizingMaskIntoConstraints = NO;
    [wave.widthAnchor constraintEqualToConstant:80.0].active = YES;
    [wave.heightAnchor constraintEqualToConstant:36.0].active = YES;

    UIStackView *textStack = [[UIStackView alloc] init];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.alignment = UIStackViewAlignmentLeading;
    textStack.spacing = 1;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = name;
    UIFontDescriptor *nd = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleSubheadline]
                            fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    nameLabel.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:nd size:0]];
    nameLabel.adjustsFontForContentSizeCategory = YES;
    nameLabel.textColor = [BrandColorsUIKit inkPrimary];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *quoteLabel = [self mk_captionLabel:[NSString stringWithFormat:@"“%@”", quote]];

    [textStack addArrangedSubview:nameLabel];
    [textStack addArrangedSubview:quoteLabel];

    [row addArrangedSubview:lvl];
    [row addArrangedSubview:wave];
    [row addArrangedSubview:textStack];

    lvl.isAccessibilityElement = NO;
    nameLabel.isAccessibilityElement = NO;
    quoteLabel.isAccessibilityElement = NO;
    row.isAccessibilityElement = YES;
    row.accessibilityLabel = [NSString stringWithFormat:@"Mức %ld trên 5, %@: %@", (long)level, name, quote];

    return row;
}

// Cùng idiom SettingsViewController mk_dividerView.
- (UIView *)mk_dividerView {
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [BrandColorsUIKit divider];
    [divider.heightAnchor constraintEqualToConstant:1].active = YES;
    return divider;
}

@end
