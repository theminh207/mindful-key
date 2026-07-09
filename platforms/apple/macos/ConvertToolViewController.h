//
//  ConvertToolViewController.h
//  OpenKey
//
//  Created by Tuyen on 9/4/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyTextField.h"
#import "BrandControls.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConvertToolViewController : NSViewController<MyTextFieldDelegate>
// [MINDFUL] Story 1.9 — 6 checkbox "Tùy chọn chung" thay bằng PillSwitch (xem BrandControls.h).
@property (weak) IBOutlet PillSwitch *AlertWhenComplete;
@property (weak) IBOutlet PillSwitch *ToAllCaps;
@property (weak) IBOutlet PillSwitch *ToNonCaps;
@property (weak) IBOutlet PillSwitch *ToCapsFirstLetter;
@property (weak) IBOutlet PillSwitch *ToCapsCharEachWord;
@property (weak) IBOutlet PillSwitch *ToRemoveSign;

// Luôn khóa+bật (enabled=NO, state=on) — chỉ mang tính hiển thị, không đọc trong code.
@property (weak) IBOutlet PillSwitch *ConvertInClipBoard;

// [MINDFUL] Story 1.9 — 4 chip chọn phím bổ trợ cho hotkey chuyển-mã-nhanh, cũng thay bằng
// PillSwitch (checkbox hệ thống hiện màu theo Accent Color của máy — trên máy dev đang là cam,
// verify bằng ảnh chụp thật, đúng vi phạm HIẾN CHƯƠNG §5.6 cần dọn).
@property (weak) IBOutlet PillSwitch *SControl;
@property (weak) IBOutlet PillSwitch *SOption;
@property (weak) IBOutlet PillSwitch *SCommand;
@property (weak) IBOutlet PillSwitch *SShift;
@property (weak) IBOutlet MyTextField *SHotKey;

@property (weak) IBOutlet NSPopUpButton *FromCode;
@property (weak) IBOutlet NSPopUpButton *ToCode;
@property (weak) IBOutlet NSButton *ReverseCode;

// [MINDFUL] Story 1.9 — 2 khung nhóm checkbox, bọc thành card NOW BRAND OS trong viewDidLoad.
@property (weak) IBOutlet NSBox *CommonOptionsBox;
@property (weak) IBOutlet NSBox *SelectionBox;

@end

NS_ASSUME_NONNULL_END
