//
//  AboutViewController.h
//  OpenKey
//
//  Created by Tuyen on 2/15/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BrandControls.h"

NS_ASSUME_NONNULL_BEGIN

@interface AboutViewController : NSViewController
@property (weak) IBOutlet NSTextField *VersionInfo;
// [MINDFUL] Story 1.10 — nút "Kiểm tra bản mới..." → CTAButton, checkbox → PillSwitch (BrandControls.h).
@property (weak) IBOutlet CTAButton *CheckNewVersionButton;
@property (weak) IBOutlet PillSwitch *CheckUpdateOnStatus;
@property (weak) IBOutlet NSTextField *TitleLabel;
// [MINDFUL] Story 1.10 — dòng "Trang GitHub: <link>" tách riêng khỏi credit OpenKey (vá bug đè chữ), tô Brand.teal.
@property (weak) IBOutlet NSTextField *GitHubLink;

@end

NS_ASSUME_NONNULL_END
