//
//  MacroViewController.h
//  OpenKey
//
//  Created by Tuyen on 8/4/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BrandControls.h"

NS_ASSUME_NONNULL_BEGIN

@interface MacroViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *macroName;
@property (weak) IBOutlet NSTextField *macroContent;

// [MINDFUL] Story 1.8 — nút "Thêm/Sửa" thay bằng CTAButton (cam, chữ tối); checkbox tự viết hoa
// thay bằng PillSwitch teal (xem BrandControls.h).
@property (weak) IBOutlet CTAButton *buttonAdd;
@property (weak) IBOutlet PillSwitch *AutoCapsMacro;

// [MINDFUL] Story 1.8 — nền card NOW BRAND OS (bo góc 16px + bóng ngọc bích) bọc bảng gõ tắt +
// hàng control (Nạp/Xuất file, switch tự viết hoa). Áp style trong viewDidLoad.
@property (weak) IBOutlet NSView *tableCard;

@end

NS_ASSUME_NONNULL_END
