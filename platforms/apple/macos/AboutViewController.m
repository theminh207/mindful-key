//
//  AboutViewController.m
//  OpenKey
//
//  Created by Tuyen on 2/15/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import "AboutViewController.h"
#import "OpenKeyManager.h"
#import "BrandColors.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    self.TitleLabel.textColor = [Brand teal]; // [MINDFUL] NOW BRAND OS — màu thương hiệu chính
    self.GitHubLink.textColor = [Brand teal]; // [MINDFUL] Story 1.10 — link GitHub tô Brand.teal

    self.VersionInfo.stringValue = [NSString stringWithFormat:@"Phiên bản %@ (build %@) - Ngày cập nhật %@",
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"],
                                    [OpenKeyManager getBuildDate]] ;

    NSInteger dontCheckUpdate = [[NSUserDefaults standardUserDefaults] integerForKey:@"DontCheckUpdate"];
    [self.CheckUpdateOnStatus setOn:!dontCheckUpdate animated:NO];
}

- (IBAction)onHomePage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/tuyenvm/OpenKey"]];
}

- (IBAction)onLatestReleaseVersion:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/tuyenvm/OpenKey/releases"]];
}

- (IBAction)onCheckUpdateOnStartup:(PillSwitch *)sender {
    // [MINDFUL] Story 1.10 — PillSwitch (giống NSButton checkbox) đã tự lật `on` TRƯỚC khi bắn
    // action (xem PillSwitch.mouseDown: trong BrandControls.m), nên logic giữ y hệt bản gốc:
    // isOn == YES nghĩa là "đang bật kiểm tra khi khởi động" → DontCheckUpdate = 0.
    NSInteger val = sender.isOn ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"DontCheckUpdate"];
}

- (IBAction)onCheckNewVersion:(id)sender {
    
    self.CheckNewVersionButton.title = @"Đang kiểm tra...";
    self.CheckNewVersionButton.enabled = false;
    
    [OpenKeyManager checkNewVersion: self.view.window callbackFunc:^{
        self.CheckNewVersionButton.enabled = true;
        self.CheckNewVersionButton.title = @"Kiểm tra bản mới...";
    }];
}

@end
