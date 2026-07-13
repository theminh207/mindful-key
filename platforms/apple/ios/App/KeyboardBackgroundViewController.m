//
//  KeyboardBackgroundViewController.m
//  mindful-key — iOS container app (màn "Nền bàn phím", Round 3 Story 3.2 / màn M6)
//

#import "KeyboardBackgroundViewController.h"
#import "BrandColorsUIKit.h"
#import "OnboardingUI.h"
#import "ThemeBridge.h"

// ===== Cảnh nền — hằng số TRANG TRÍ =====
//
// 5 bộ hex dưới đây lấy NGUYÊN VĂN từ design handoff (Mindful Key Prototype.dc.html, section
// caidatNen, 5 khối linear-gradient inline). Đây là gradient TRANG TRÍ cho 5 CẢNH TĨNH người dùng
// tự chọn làm nền bàn phím — KHÔNG mã hoá cảm xúc/trạng thái (hiến chương §2.2/2.3 cấm đỏ/xanh
// gắn với TÂM TRẠNG người gõ; 5 cảnh này không đổi theo tâm trạng, không đèn đỏ/xanh, không thang
// biên độ). Gom hằng số ở ĐÚNG MỘT chỗ này (không rải hex rải rác trong code) để dễ soát bằng
// scripts/brand-lint.sh và để đổi cảnh sau này chỉ sửa 1 nơi. Chữ/viền vẫn LUÔN dùng
// BrandColorsUIKit (brandTeal cho viền chọn, divider cho viền chấm ô "Ảnh của bạn").
static const UInt32 kMkSceneGradientStops[5][3] = {
    {0xDCEBEE, 0xA7C2C8, 0x6E8E97}, // Cảnh 1 — hồ sương teal (mặc định, index 0)
    {0xE8EDEF, 0xC7D2D6, 0xAAB8BD}, // Cảnh 2 — xám nhạt
    {0xE4E0DA, 0xC8C2B8, 0xA39D92}, // Cảnh 3 — đá be
    {0xECDFCA, 0xD8C3A3, 0xBFA37E}, // Cảnh 4 — cát vàng
    {0xDDE3D7, 0xBCC7B4, 0x9AA889}, // Cảnh 5 — lá cây trầm
};
// Góc gradient theo đúng quy ước CSS linear-gradient() trong design handoff (165deg/170deg/160deg).
static const CGFloat kMkSceneGradientAngleDegrees[5] = {165.0, 170.0, 160.0, 160.0, 160.0};
// Vị trí stop giữa (0..1) — khớp "55%"/"60%" trong design handoff.
static const CGFloat kMkSceneGradientMidLocation[5] = {0.55, 0.60, 0.55, 0.55, 0.55};

static const NSInteger kMkSceneCount = 5;
static const NSInteger kMkPhotoTileIndex = 5; // ô "Ảnh của bạn" — placeholder, không phải 1 cảnh thật

// Quy đổi hex quyết định TẠI ĐÂY (không mượn hàm private của BrandColorsUIKit.m) vì đây là màu
// TRANG TRÍ cảnh nền, tách bạch khỏi bảng màu thương hiệu/ngữ nghĩa trong BrandColorsUIKit.
static UIColor *mk_sceneColorFromHex(UInt32 hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:1.0];
}

// Quy đổi góc theo quy ước CSS linear-gradient (0deg = hướng lên, tăng dần theo chiều kim đồng hồ)
// sang startPoint/endPoint của CAGradientLayer (hệ toạ độ đơn vị 0..1, gốc trên-trái, y xuống
// dưới) — để TÁI TẠO ĐÚNG hướng 5 gradient trong design handoff thay vì đoán bừa hướng.
static void mk_gradientPointsForAngleDegrees(CGFloat degrees, CGPoint *outStart, CGPoint *outEnd) {
    CGFloat radians = degrees * (CGFloat)M_PI / 180.0;
    CGFloat dx = sin(radians);
    CGFloat dy = -cos(radians);
    CGPoint center = CGPointMake(0.5, 0.5);
    *outStart = CGPointMake(center.x - dx * 0.5, center.y - dy * 0.5);
    *outEnd   = CGPointMake(center.x + dx * 0.5, center.y + dy * 0.5);
}

// ===== Tile trong lưới =====
//
// UIControl (không phải UIButton) để tránh style mặc định (tint/highlight) đè lên gradient — viền
// chọn/dashed vẽ thẳng qua CALayer. gradientLayer nil cho ô "Ảnh của bạn" (không có cảnh thật).
@interface MKBackgroundTile : UIControl
@property (nonatomic, strong, nullable) CAGradientLayer *gradientLayer;
@property (nonatomic, strong, nullable) CAShapeLayer *dashBorderLayer; // chỉ ô "Ảnh của bạn"
@end

@implementation MKBackgroundTile

- (instancetype)init {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layer.cornerRadius = 10.0; // radius lưới, đúng design handoff
        self.layer.masksToBounds = YES;
        self.accessibilityTraits |= UIAccessibilityTraitButton;
    }
    return self;
}

// Auto Layout quyết định bounds sau viewDidLoad — gradient/dashed path phải bám theo bounds thật,
// không tính tay ở lúc khởi tạo (khi đó frame còn = CGRectZero).
- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
    if (self.dashBorderLayer != nil) {
        self.dashBorderLayer.frame = self.bounds;
        self.dashBorderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:10.0].CGPath;
    }
}

@end

@interface KeyboardBackgroundViewController ()
@property (nonatomic, strong) NSArray<MKBackgroundTile *> *tiles;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation KeyboardBackgroundViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    [self mk_buildUI];
    [self mk_applySelectedIndex:ThemeBridge_SelectedBackgroundIndex()];
}

// Đề phòng giá trị đổi từ nơi khác trong cùng phiên — cùng lý do SettingsViewController đọc lại
// App Group mỗi lần màn hiện (story 2.3 Dev Notes AC #4), không chỉ lúc viewDidLoad.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self mk_applySelectedIndex:ThemeBridge_SelectedBackgroundIndex()];
}

#pragma mark - Dựng UI

- (void)mk_buildUI {
    UIView *header = [self mk_headerRow];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    UILabel *subtitle = [OnboardingUI subtitleLabel:@"Cảnh tĩnh lặng — nền nào cũng tự phủ màng để chữ phím rõ."];
    [stack addArrangedSubview:subtitle];
    [stack addArrangedSubview:[self mk_gridView]];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [header.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],

        [scroll.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:16],
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

// nav bar hệ thống bị ẩn toàn app (AppDelegate.m) — tự vẽ "Quay lại" + tiêu đề, đúng pattern
// SettingsViewController/MacroManagerViewController.
- (UIView *)mk_headerRow {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8;

    UIButton *back = [OnboardingUI ghostButton:@"‹ Quay lại"];
    back.accessibilityLabel = @"Quay lại";
    [back addTarget:self action:@selector(mk_backTapped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *title = [OnboardingUI titleLabel:@"Nền bàn phím"];
    title.textAlignment = NSTextAlignmentCenter;
    title.accessibilityTraits |= UIAccessibilityTraitHeader;

    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    [row addArrangedSubview:back];
    [row addArrangedSubview:title];
    [row addArrangedSubview:spacer];
    return row;
}

// Lưới 3 cột x 2 hàng = 5 cảnh + 1 ô "Ảnh của bạn", đúng bố cục caidatNen trong design handoff.
- (UIView *)mk_gridView {
    NSMutableArray<MKBackgroundTile *> *tiles = [NSMutableArray arrayWithCapacity:kMkSceneCount + 1];
    for (NSInteger i = 0; i < kMkSceneCount; i++) {
        [tiles addObject:[self mk_sceneTileAtIndex:i]];
    }
    [tiles addObject:[self mk_photoPlaceholderTile]];
    self.tiles = tiles;

    UIStackView *rowA = [self mk_gridRowWithTiles:@[tiles[0], tiles[1], tiles[2]]];
    UIStackView *rowB = [self mk_gridRowWithTiles:@[tiles[3], tiles[4], tiles[5]]];

    UIStackView *grid = [[UIStackView alloc] init];
    grid.axis = UILayoutConstraintAxisVertical;
    grid.spacing = 9; // gap ~9, đúng design handoff
    grid.distribution = UIStackViewDistributionFillEqually;
    [grid addArrangedSubview:rowA];
    [grid addArrangedSubview:rowB];
    return grid;
}

- (UIStackView *)mk_gridRowWithTiles:(NSArray<MKBackgroundTile *> *)rowTiles {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 9;
    row.distribution = UIStackViewDistributionFillEqually;
    for (MKBackgroundTile *tile in rowTiles) {
        // aspect-ratio 3/2 (rộng:cao), đúng design handoff — chiều cao ăn theo chiều rộng thật.
        [tile.heightAnchor constraintEqualToAnchor:tile.widthAnchor multiplier:(2.0 / 3.0)].active = YES;
        [row addArrangedSubview:tile];
    }
    return row;
}

- (MKBackgroundTile *)mk_sceneTileAtIndex:(NSInteger)sceneIndex {
    MKBackgroundTile *tile = [[MKBackgroundTile alloc] init];
    tile.tag = sceneIndex;
    tile.accessibilityLabel = [NSString stringWithFormat:@"Cảnh nền %ld", (long)(sceneIndex + 1)];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)mk_sceneColorFromHex(kMkSceneGradientStops[sceneIndex][0]).CGColor,
        (id)mk_sceneColorFromHex(kMkSceneGradientStops[sceneIndex][1]).CGColor,
        (id)mk_sceneColorFromHex(kMkSceneGradientStops[sceneIndex][2]).CGColor,
    ];
    gradient.locations = @[@0.0, @(kMkSceneGradientMidLocation[sceneIndex]), @1.0];
    CGPoint start, end;
    mk_gradientPointsForAngleDegrees(kMkSceneGradientAngleDegrees[sceneIndex], &start, &end);
    gradient.startPoint = start;
    gradient.endPoint = end;
    [tile.layer addSublayer:gradient];
    tile.gradientLayer = gradient;

    [tile addTarget:self action:@selector(mk_tileTapped:) forControlEvents:UIControlEventTouchUpInside];
    return tile;
}

// Placeholder TRỰC QUAN — KHÔNG có picker thật đứng sau (yêu cầu rõ: đừng cài photo picker). Cố ý
// KHÔNG gắn tap target/ThemeBridge cho ô này — chạm vào không làm gì, chỉ 1 nhãn "sắp có" trung
// tính (không phải lời hứa cam kết ngày ra mắt, đúng tinh thần "mô tả không phán xét/không thổi
// phồng" — hiến chương §2.2).
- (MKBackgroundTile *)mk_photoPlaceholderTile {
    MKBackgroundTile *tile = [[MKBackgroundTile alloc] init];
    tile.tag = kMkPhotoTileIndex;
    tile.enabled = NO; // không tương tác — thuần trực quan
    tile.accessibilityLabel = @"Ảnh của bạn";
    tile.accessibilityHint = @"Sắp có";
    tile.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
    tile.layer.borderWidth = 0.0; // viền chọn KHÔNG áp cho ô này (không phải 1 lựa chọn thật)

    CAShapeLayer *dash = [CAShapeLayer layer];
    dash.strokeColor = [BrandColorsUIKit divider].CGColor;
    dash.fillColor = [UIColor clearColor].CGColor;
    dash.lineDashPattern = @[@4, @3];
    dash.lineWidth = 2.0;
    [tile.layer addSublayer:dash];
    tile.dashBorderLayer = dash;

    UILabel *label = [OnboardingUI subtitleLabel:@"Ảnh của bạn — sắp có"];
    label.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont systemFontOfSize:11.0]]; // ~11px, Dynamic Type
    label.adjustsFontForContentSizeCategory = YES;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [BrandColorsUIKit inkSecondary];
    label.numberOfLines = 2;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.isAccessibilityElement = NO; // gộp vào accessibilityLabel/Hint của tile, tránh đọc trùng
    [tile addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:tile.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:tile.centerYAnchor],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:tile.leadingAnchor constant:6],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:tile.trailingAnchor constant:-6],
    ]];

    return tile;
}

#pragma mark - Chọn cảnh + App Group

// Chỉ đổi VIỀN/accessibility — không ghi App Group (dùng lúc nạp giá trị đã lưu, KHÔNG phải lúc
// người dùng vừa chạm). Index ngoài khoảng hợp lệ (0..kMkSceneCount, bỏ qua ô "Ảnh của bạn" vì ô
// đó không nhận lựa chọn) -> fallback cảnh đầu tiên, tránh im lặng không tô viền ô nào.
- (void)mk_applySelectedIndex:(NSInteger)index {
    if (index < 0 || index > kMkSceneCount - 1) {
        index = 0;
    }
    self.selectedIndex = index;
    for (MKBackgroundTile *tile in self.tiles) {
        if (tile.tag == kMkPhotoTileIndex) {
            continue; // ô "Ảnh của bạn" không tham gia trạng thái chọn
        }
        BOOL selected = (tile.tag == index);
        tile.layer.borderWidth = selected ? 2.0 : 0.0;
        tile.layer.borderColor = selected ? [BrandColorsUIKit brandTeal].CGColor : nil;
        if (selected) {
            tile.accessibilityTraits |= UIAccessibilityTraitSelected;
        } else {
            tile.accessibilityTraits &= ~UIAccessibilityTraitSelected;
        }
    }
}

// Người dùng chạm 1 cảnh -> đổi viền NGAY + ghi App Group NGAY (không có nút "Lưu" tổng, cùng lối
// với inputType/heightLevel ở SettingsViewController).
- (void)mk_tileTapped:(MKBackgroundTile *)tile {
    [self mk_applySelectedIndex:tile.tag];
    ThemeBridge_SetSelectedBackgroundIndex(tile.tag);
}

#pragma mark - Điều hướng

- (void)mk_backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
