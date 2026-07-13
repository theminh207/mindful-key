//
//  SettingsViewController.m
//  mindful-key — iOS container app (màn Cài đặt bàn phím, story 2.3)
//

#import "SettingsViewController.h"
#import "BrandColorsUIKit.h"
#import "OnboardingUI.h"
#import "KeyboardPreviewView.h"
#import "KeyboardSettingsBridge.h"
#import "MacroManagerViewController.h"
#import "BellReminderSettingsBridge.h"   // story 2.6: chuông nhắc nghỉ (cấu hình bật/tắt + hoãn)

@interface SettingsViewController ()
@property (nonatomic, strong) KeyboardPreviewView *previewView;
@property (nonatomic, strong) UISegmentedControl *inputTypeControl;
@property (nonatomic, strong) UISlider *heightSlider;
@property (nonatomic, strong) UISwitch *bellReminderSwitch;      // story 2.6
@property (nonatomic, strong) UIButton *bellSnoozeButton;        // story 2.6
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    [self mk_buildUI];
    [self mk_refreshFromStore];
}

// Đề phòng giá trị đổi từ nơi khác trong cùng phiên (Dev Notes AC #4) — đọc lại App Group + set
// lại control/preview mỗi lần màn hiện, không chỉ lúc viewDidLoad.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self mk_refreshFromStore];
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
    stack.spacing = 20;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    self.previewView = [[KeyboardPreviewView alloc] init];
    UILabel *previewCaption = [OnboardingUI subtitleLabel:@"Preview sống"];
    [stack addArrangedSubview:previewCaption];
    [stack addArrangedSubview:self.previewView];

    [stack addArrangedSubview:[self mk_inputTypeRow]];
    [stack addArrangedSubview:[self mk_dividerView]];
    [stack addArrangedSubview:[self mk_heightRow]];
    [stack addArrangedSubview:[self mk_dividerView]];
    // Story 2.6: "Chuông nhắc nghỉ" chèn ở ĐÚNG chỗ đã chừa (giữa divider sau "Chiều cao" và row
    // "Gõ tắt / macro") — không sửa 2 row Telex/VNI + chiều cao ở trên (sở hữu 2.3).
    [stack addArrangedSubview:[self mk_bellReminderRow]];
    [stack addArrangedSubview:[self mk_bellSnoozeRow]];
    [stack addArrangedSubview:[self mk_dividerView]];
    [stack addArrangedSubview:[self mk_macroRow]];

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
// MacroManagerViewController (story 2.4).
- (UIView *)mk_headerRow {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8;

    UIButton *back = [OnboardingUI ghostButton:@"‹ Quay lại"];
    back.accessibilityLabel = @"Quay lại";
    [back addTarget:self action:@selector(mk_backTapped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *title = [OnboardingUI titleLabel:@"Cài đặt bàn phím"];
    title.textAlignment = NSTextAlignmentCenter;
    title.accessibilityTraits |= UIAccessibilityTraitHeader;

    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    [row addArrangedSubview:back];
    [row addArrangedSubview:title];
    [row addArrangedSubview:spacer];
    return row;
}

// Row chuẩn iOS: nhãn trái, control phải, cao >= 44pt (DESIGN.md §2.7).
- (UIView *)mk_inputTypeRow {
    UILabel *label = [OnboardingUI bodyLabel:@"Kiểu gõ"];

    self.inputTypeControl = [[UISegmentedControl alloc] initWithItems:@[@"Telex", @"VNI"]];
    // AC #1: KHÔNG BAO GIỜ tint xanh-lá/xanh-dương mặc định — set thẳng token teal cho pill đang
    // chọn + track, KHÔNG dùng .tintColor.
    self.inputTypeControl.backgroundColor = [BrandColorsUIKit tealLight];
    self.inputTypeControl.selectedSegmentTintColor = [BrandColorsUIKit surfaceCard];
    [self.inputTypeControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [BrandColorsUIKit tealStrong]}
                                          forState:UIControlStateSelected];
    [self.inputTypeControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [BrandColorsUIKit inkSecondary]}
                                          forState:UIControlStateNormal];
    self.inputTypeControl.accessibilityLabel = @"Kiểu gõ";
    [self.inputTypeControl addTarget:self
                               action:@selector(mk_inputTypeChanged)
                     forControlEvents:UIControlEventValueChanged];
    [self.inputTypeControl.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;

    return [self mk_rowWithLabel:label control:self.inputTypeControl];
}

- (UIView *)mk_heightRow {
    UILabel *label = [OnboardingUI bodyLabel:@"Chiều cao"];

    self.heightSlider = [[UISlider alloc] init];
    self.heightSlider.minimumValue = 0.0;
    self.heightSlider.maximumValue = 1.0;
    // AC #2: track đã tô = brand.teal, track trống = line.divider, KHÔNG tint hệ thống.
    self.heightSlider.minimumTrackTintColor = [BrandColorsUIKit brandTeal];
    self.heightSlider.maximumTrackTintColor = [BrandColorsUIKit divider];
    self.heightSlider.accessibilityLabel = @"Chiều cao bàn phím";
    [self.heightSlider addTarget:self
                           action:@selector(mk_heightChanged)
                 forControlEvents:UIControlEventValueChanged];
    [self.heightSlider addTarget:self
                           action:@selector(mk_heightSettled)
                 forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    [self.heightSlider.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;

    return [self mk_rowWithLabel:label control:self.heightSlider];
}

// Story 2.6 (AC#3): switch bật/tắt chuông nhắc nghỉ — KHÔNG hiện số câu/số lần đã nhắc ở đâu
// trong row này (AC#5, không gamify), chỉ 1 nhãn tĩnh + 1 công tắc.
- (UIView *)mk_bellReminderRow {
    UILabel *label = [OnboardingUI bodyLabel:@"Chuông nhắc nghỉ"];

    self.bellReminderSwitch = [[UISwitch alloc] init];
    // AC #1 (kế thừa từ 2.3): KHÔNG BAO GIỜ dùng tint xanh-lá mặc định của UISwitch — set thẳng
    // token teal, đúng nguyên tắc đã áp cho inputTypeControl ở trên.
    self.bellReminderSwitch.onTintColor = [BrandColorsUIKit brandTeal];
    self.bellReminderSwitch.accessibilityLabel = @"Chuông nhắc nghỉ";
    [self.bellReminderSwitch addTarget:self
                                 action:@selector(mk_bellReminderChanged)
                       forControlEvents:UIControlEventValueChanged];

    return [self mk_rowWithLabel:label control:self.bellReminderSwitch];
}

// Story 2.6 (AC#4): "Tạm hoãn" mirror hành vi macOS "Tạm hoãn chuông 1 giờ" (BellMac_Snooze(60),
// AppDelegate.m dòng 602) — KHÔNG hiện đếm ngược/thời điểm hết hoãn ra chữ (đó cũng là 1 dạng
// đếm/gamify, ngoài AC yêu cầu).
- (UIView *)mk_bellSnoozeRow {
    self.bellSnoozeButton = [OnboardingUI ghostButton:@"Tạm hoãn 1 giờ"];
    self.bellSnoozeButton.accessibilityLabel = @"Tạm hoãn chuông nhắc nghỉ 1 giờ";
    [self.bellSnoozeButton addTarget:self
                               action:@selector(mk_bellSnoozeTapped)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.bellSnoozeButton.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    return self.bellSnoozeButton;
}

- (UIView *)mk_macroRow {
    UIButton *row = [UIButton buttonWithType:UIButtonTypeSystem];
    [row setTitle:@"Gõ tắt / macro  ›" forState:UIControlStateNormal];
    [row setTitleColor:[BrandColorsUIKit inkPrimary] forState:UIControlStateNormal];
    row.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    row.titleLabel.adjustsFontForContentSizeCategory = YES;
    row.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    row.accessibilityLabel = @"Gõ tắt / macro";
    row.accessibilityTraits |= UIAccessibilityTraitButton;
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    [row addTarget:self action:@selector(mk_macroTapped) forControlEvents:UIControlEventTouchUpInside];
    return row;
}

- (UIView *)mk_rowWithLabel:(UILabel *)label control:(UIView *)control {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 12;
    [label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [row addArrangedSubview:label];
    [row addArrangedSubview:control];
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    return row;
}

- (UIView *)mk_dividerView {
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [BrandColorsUIKit divider];
    [divider.heightAnchor constraintEqualToConstant:1].active = YES;
    return divider;
}

#pragma mark - Đọc/ghi App Group + preview realtime

// AC #4: nạp đúng giá trị đã lưu (mặc định Telex/mức giữa nếu chưa từng chỉnh — xử lý ở
// KeyboardSettingsBridge, không suy đoán lại ở đây).
- (void)mk_refreshFromStore {
    KeyboardSettingsInputType inputType = KeyboardSettingsBridge_ReadInputType();
    double heightLevel = KeyboardSettingsBridge_ReadHeightLevel();

    self.inputTypeControl.selectedSegmentIndex = (NSInteger)inputType;
    self.heightSlider.value = (float)heightLevel;
    [self mk_updatePreviewAndAccessibilityAnnounce:NO];

    // Story 2.6: nạp lại cờ bật/tắt + cập nhật nhãn nút hoãn mỗi lần màn hiện (đề phòng đổi từ
    // nơi khác trong cùng phiên, đúng lý do viewWillAppear đã gọi hàm này — Dev Notes AC #4 của 2.3).
    self.bellReminderSwitch.on = BellReminderSettingsBridge_IsEnabled();
    [self mk_refreshBellSnoozeButtonTitle];
}

// Nhãn nút CHỈ nói trạng thái quan sát được ("đang hoãn" / hành động khả dụng) — KHÔNG in ra thời
// điểm hết hoãn hay bất kỳ con số nào (AC#5).
- (void)mk_refreshBellSnoozeButtonTitle {
    NSString *title = BellReminderSettingsBridge_IsSnoozedAt([NSDate date]) ? @"Đang tạm hoãn" : @"Tạm hoãn 1 giờ";
    [self.bellSnoozeButton setTitle:title forState:UIControlStateNormal];
}

- (KeyboardSettingsInputType)mk_currentInputType {
    return (self.inputTypeControl.selectedSegmentIndex == KeyboardSettingsInputTypeVNI)
        ? KeyboardSettingsInputTypeVNI
        : KeyboardSettingsInputTypeTelex;
}

// AC #3: preview đổi NGAY trong cùng thao tác — cập nhật trước, ghi App Group song song không
// chặn UI (setInteger/setDouble đồng bộ nhưng rẻ, không cần async riêng ở quy mô 2 khoá này).
- (void)mk_inputTypeChanged {
    KeyboardSettingsBridge_WriteInputType([self mk_currentInputType]);
    [self mk_updatePreviewAndAccessibilityAnnounce:NO];
}

// Kéo slider (.valueChanged, không chỉ touchUpInside) → preview đổi NGAY, CHƯA ghi App Group
// (tránh ghi dồn dập mỗi pixel kéo — ghi thật ở mk_heightSettled).
- (void)mk_heightChanged {
    [self mk_updatePreviewAndAccessibilityAnnounce:YES];
}

// Thả tay (touchUpInside/touchUpOutside) → ghi App Group đúng 1 lần (AC #4).
- (void)mk_heightSettled {
    KeyboardSettingsBridge_WriteHeightLevel(self.heightSlider.value);
}

// Story 2.6 (AC#3): đổi switch → ghi App Group NGAY, không debounce (cùng lối với inputType).
- (void)mk_bellReminderChanged {
    BellReminderSettingsBridge_SetEnabled(self.bellReminderSwitch.on);
}

// Story 2.6 (AC#4): bấm nút → hoãn 60 phút kể từ bây giờ (mirror macOS "Tạm hoãn chuông 1 giờ").
- (void)mk_bellSnoozeTapped {
    BellReminderSettingsBridge_SnoozeForMinutes(60);
    [self mk_refreshBellSnoozeButtonTitle];
    // Quan sát trung tính, không khen/chê — cùng tinh thần thông báo VoiceOver đã dùng ở 2.1/2.3.
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Đã tạm hoãn chuông nhắc nghỉ 1 giờ");
}

- (void)mk_updatePreviewAndAccessibilityAnnounce:(BOOL)announce {
    double heightLevel = self.heightSlider.value;
    NSInteger step = KeyboardSettingsBridge_HeightLevelToStep(heightLevel);
    self.heightSlider.accessibilityValue = [NSString stringWithFormat:@"mức %ld/5", (long)step];
    [self.previewView updateWithInputType:[self mk_currentInputType] heightLevel:heightLevel];

    // AC #5: VoiceOver phải nghe lại giá trị mới khi chiều cao đổi (không im lặng).
    if (announce) {
        NSString *announcement = [NSString stringWithFormat:@"chiều cao: mức %ld", (long)step];
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
    }
}

#pragma mark - Điều hướng

- (void)mk_backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

// Wireframe EXPERIENCE.md: "Exits to: ... hoặc màn con Gõ tắt/macro" — MacroManagerViewController
// (story 2.4) đã có sẵn, tự chứa (tự pop qua nút Quay lại riêng, không cần callback) nên push
// thẳng ở đây là đủ, không cần thêm dây qua AppDelegate như lối vào riêng từ Home.
- (void)mk_macroTapped {
    [self.navigationController pushViewController:[[MacroManagerViewController alloc] init] animated:YES];
}

@end
