//
//  ViewController.m
//  mindful-key — iOS container app (Round 1 walking skeleton)
//

#import "ViewController.h"
#import "AppGroupBridge.h"

@interface ViewController ()
@property (nonatomic, strong) UITextField *testField;
@property (nonatomic, strong) UILabel *statusLabel;   // placeholder trạng thái heartbeat (story 1.6)
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Mindful Key — iOS Round 1";
    label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];

    // Trạng thái "đã kích hoạt?" đọc từ App Group heartbeat — UI placeholder tối thiểu cho
    // story 1.6; màn onboarding đầy đủ thuộc story 1.7. Cập nhật lúc màn hiện + mỗi lần app
    // quay lại foreground (bàn phím có thể vừa chạy lần đầu ở app khác).
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:15];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // Ô nhập thử — dùng để verify bàn phím tuỳ biến ở Mốc B (gõ Telex), không phải UI
    // onboarding cuối cùng.
    self.testField = [[UITextField alloc] init];
    self.testField.borderStyle = UITextBorderStyleRoundedRect;
    self.testField.placeholder = @"Gõ thử ở đây (chọn bàn phím Mindful Key qua nút 🌐)";
    self.testField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.testField];

    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],

        [self.statusLabel.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:16],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.testField.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:24],
        [self.testField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.testField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshKeyboardStatus)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshKeyboardStatus];
}

- (void)refreshKeyboardStatus {
    switch (ContainerApp_ReadKeyboardStatus()) {
        case AppGroupKeyboardStatusRanWithFullAccess:
        case AppGroupKeyboardStatusRanNoFullAccess:
            // Đủ cho story 1.6: chỉ cần phân biệt "đã kích hoạt" vs "chưa". Phân nhánh Full
            // Access chi tiết là việc của onboarding story 1.7.
            self.statusLabel.text = @"Bàn phím đã kích hoạt.";
            break;
        case AppGroupKeyboardStatusNeverRan:
        default:
            self.statusLabel.text = @"Chưa thấy bàn phím chạy. Mở Cài đặt › Cài đặt chung › "
                                     "Bàn phím để thêm Mindful Key, rồi gõ thử ở ô dưới.";
            break;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
