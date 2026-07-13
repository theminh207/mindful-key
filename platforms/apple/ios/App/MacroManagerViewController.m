//
//  MacroManagerViewController.m
//  mindful-key — iOS container app (màn Gõ tắt, story 2.4)
//

#import "MacroManagerViewController.h"
#import "BrandColorsUIKit.h"
#import "OnboardingUI.h"
#import "MacroBridge.h"

static NSString *const kMacroCellReuseId = @"MacroManagerCell";

@interface MacroManagerViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSString *> *> *macros;
// Sống trong thời gian 1 UIAlertController thêm/sửa đang hiện — dùng để bật/tắt nút xác nhận
// theo AC #2 (không cho thêm macro trống) khi người dùng gõ vào 2 ô nhập.
@property (nonatomic, weak) UIAlertController *pendingAlert;
@property (nonatomic, weak) UIAlertAction *pendingConfirmAction;
@end

@implementation MacroManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [BrandColorsUIKit surfacePage];
    // AC #5: nạp đúng những gì đã lưu — chưa từng thêm gì thì mảng RỖNG (MacroBridge_ReadAll
    // không seed macro mẫu nào).
    self.macros = [MacroBridge_ReadAll() mutableCopy];
    [self mk_buildUI];
}

#pragma mark - Dựng UI

- (void)mk_buildUI {
    UIView *header = [self mk_headerRow];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [header.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],

        [self.tableView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:12],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self mk_refreshTableAppearance];
}

// nav bar hệ thống bị ẩn toàn app (self.nav.navigationBarHidden = YES ở AppDelegate, onboarding
// tự vẽ header riêng) — màn này cũng tự vẽ "Quay lại" + tiêu đề + "Thêm", cùng nguyên tắc.
- (UIView *)mk_headerRow {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8;

    UIButton *back = [OnboardingUI ghostButton:@"‹ Quay lại"];
    back.accessibilityLabel = @"Quay lại";
    [back addTarget:self action:@selector(mk_backTapped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *title = [OnboardingUI subtitleLabel:@"Gõ tắt"];
    title.textAlignment = NSTextAlignmentCenter;
    title.accessibilityTraits |= UIAccessibilityTraitHeader;

    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    UIButton *add = [OnboardingUI ghostButton:@"+ Thêm"];
    add.accessibilityLabel = @"Thêm gõ tắt mới";
    [add addTarget:self action:@selector(mk_addTapped) forControlEvents:UIControlEventTouchUpInside];

    [row addArrangedSubview:back];
    [row addArrangedSubview:title];
    [row addArrangedSubview:spacer];
    [row addArrangedSubview:add];
    return row;
}

// Trạng thái rỗng — copy trung tính "mô tả không phán xét" (hiến chương), KHÔNG giọng thúc giục
// kiểu quảng cáo ("hãy thêm macro để gõ nhanh hơn!").
- (UIView *)mk_emptyStateView {
    UIView *container = [[UIView alloc] init];
    UILabel *label = [OnboardingUI bodyLabel:@"Chưa có từ gõ tắt nào."];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-40],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:container.leadingAnchor constant:32],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor constant:-32],
    ]];
    return container;
}

- (void)mk_refreshTableAppearance {
    [self.tableView reloadData];
    self.tableView.backgroundView = (self.macros.count == 0) ? [self mk_emptyStateView] : nil;
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.macros.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMacroCellReuseId];
    if (cell == nil) {
        // UITableViewCellStyleSubtitle (không phải registerClass mặc định Default) để có
        // detailTextLabel hiển thị nội dung bung dưới từ gõ tắt.
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:kMacroCellReuseId];
    }
    NSDictionary<NSString *, NSString *> *macro = self.macros[indexPath.row];
    NSString *trigger = macro[MacroBridgeFieldTrigger];
    NSString *content = macro[MacroBridgeFieldContent];
    cell.textLabel.text = trigger;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"→ %@", content];
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@ bung ra %@", trigger, content];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary<NSString *, NSString *> *macro = self.macros[indexPath.row];
    NSInteger editIndex = indexPath.row;
    __weak typeof(self) weakSelf = self;
    [self mk_presentFormWithTitle:@"Sửa gõ tắt"
                       actionTitle:@"Lưu"
                           trigger:macro[MacroBridgeFieldTrigger]
                           content:macro[MacroBridgeFieldContent]
                         onConfirm:^(NSString *trigger, NSString *content) {
        [weakSelf mk_upsertTrigger:trigger content:content excludingIndex:editIndex];
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    [self.macros removeObjectAtIndex:indexPath.row];
    MacroBridge_WriteAll(self.macros);
    [self mk_refreshTableAppearance];
}

#pragma mark - Thêm / sửa (form dùng chung)

- (void)mk_addTapped {
    __weak typeof(self) weakSelf = self;
    [self mk_presentFormWithTitle:@"Thêm gõ tắt"
                       actionTitle:@"Thêm"
                           trigger:nil
                           content:nil
                         onConfirm:^(NSString *trigger, NSString *content) {
        [weakSelf mk_upsertTrigger:trigger content:content excludingIndex:NSNotFound];
    }];
}

- (void)mk_backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

// Form dùng chung cho thêm/sửa — 2 ô nhập (từ gõ tắt / nội dung bung). Nút xác nhận CHỈ bật khi
// cả 2 ô không rỗng (AC #2, lớp phòng thủ đầu — lớp thứ 2 là trim trong mk_upsertTrigger:).
- (void)mk_presentFormWithTitle:(NSString *)title
                     actionTitle:(NSString *)actionTitle
                         trigger:(nullable NSString *)trigger
                         content:(nullable NSString *)content
                       onConfirm:(void (^)(NSString *trigger, NSString *content))onConfirm {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                     message:nil
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Từ gõ tắt (vd: vn)";
        tf.text = trigger;
        tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
        tf.accessibilityLabel = @"Từ gõ tắt";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Nội dung bung ra (vd: Việt Nam)";
        tf.text = content;
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
        tf.accessibilityLabel = @"Nội dung bung ra";
    }];

    __weak UIAlertController *weakAlert = alert;
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:actionTitle
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        UIAlertController *strongAlert = weakAlert;
        if (strongAlert == nil) return;
        onConfirm(strongAlert.textFields[0].text, strongAlert.textFields[1].text);
    }];
    confirm.enabled = (trigger.length > 0 && content.length > 0); // sửa macro có sẵn -> bật ngay
    [alert addAction:[UIAlertAction actionWithTitle:@"Huỷ" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:confirm];

    self.pendingAlert = alert;
    self.pendingConfirmAction = confirm;
    for (UITextField *tf in alert.textFields) {
        [tf addTarget:self action:@selector(mk_formFieldChanged) forControlEvents:UIControlEventEditingChanged];
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)mk_formFieldChanged {
    UIAlertController *alert = self.pendingAlert;
    if (alert == nil) return;
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trigger = [alert.textFields[0].text stringByTrimmingCharactersInSet:ws];
    NSString *content = [alert.textFields[1].text stringByTrimmingCharactersInSet:ws];
    self.pendingConfirmAction.enabled = (trigger.length > 0 && content.length > 0);
}

// AC #2: từ gõ tắt/nội dung rỗng (sau khi trim) -> KHÔNG lưu; từ gõ tắt trùng đúng 1 bản ghi
// khác -> SỬA bản ghi đó thay vì tạo bản ghi trùng (kể cả khi đang sửa 1 hàng khác mà đổi trigger
// trùng sang 1 hàng có sẵn — gộp về hàng có sẵn, xoá hàng đang sửa).
- (void)mk_upsertTrigger:(NSString *)rawTrigger
                   content:(NSString *)rawContent
           excludingIndex:(NSInteger)excludeIndex {
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trigger = [rawTrigger stringByTrimmingCharactersInSet:ws];
    NSString *content = [rawContent stringByTrimmingCharactersInSet:ws];
    if (trigger.length == 0 || content.length == 0) return;

    NSDictionary<NSString *, NSString *> *entry = @{MacroBridgeFieldTrigger: trigger,
                                                       MacroBridgeFieldContent: content};

    NSInteger existingIndex = NSNotFound;
    for (NSInteger i = 0; i < (NSInteger)self.macros.count; i++) {
        if (i == excludeIndex) continue;
        if ([self.macros[i][MacroBridgeFieldTrigger] isEqualToString:trigger]) {
            existingIndex = i;
            break;
        }
    }

    if (existingIndex != NSNotFound) {
        self.macros[existingIndex] = entry;
        if (excludeIndex != NSNotFound && excludeIndex != existingIndex) {
            [self.macros removeObjectAtIndex:excludeIndex];
        }
    } else if (excludeIndex != NSNotFound && excludeIndex < (NSInteger)self.macros.count) {
        self.macros[excludeIndex] = entry;
    } else {
        [self.macros addObject:entry];
    }

    MacroBridge_WriteAll(self.macros);
    [self mk_refreshTableAppearance];
}

@end
