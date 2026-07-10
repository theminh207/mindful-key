//
//  ViewController.m
//  mindful-key — iOS container app (Round 1 walking skeleton)
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) UITextField *testField;
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

        [self.testField.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:24],
        [self.testField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.testField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];
}

@end
