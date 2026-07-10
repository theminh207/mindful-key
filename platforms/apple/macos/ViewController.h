//
//  ViewController.h
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyTextField.h"
#import "BrandControls.h"

@interface ViewController : NSViewController<MyTextFieldDelegate>
@property (strong) IBOutlet NSView *viewParent;
@property (weak) IBOutlet NSButton *tabbuttonPrimary;
@property (weak) IBOutlet NSButton *tabbuttonMacro;
@property (weak) IBOutlet NSButton *tabbuttonSystem;
@property (weak) IBOutlet NSButton *tabbuttonInfo;
@property (weak) IBOutlet NSBox *tabviewPrimary;
@property (weak) IBOutlet NSBox *tabviewMacro;
@property (weak) IBOutlet NSBox *tabviewSystem;
@property (weak) IBOutlet NSBox *tabviewInfo;

// [MINDFUL] Story 1.7 — box header (Kiểu gõ/Bảng mã/Phím chuyển/Chế độ gõ), bọc card NOW BRAND OS.
@property (weak) IBOutlet NSBox *headerBox;

@property (weak) IBOutlet NSPopUpButton *popupInputType;
@property (weak) IBOutlet NSPopUpButton *popupCode;

@property (weak) IBOutlet NSBox *appOK;
@property (weak) IBOutlet NSBox *permissionWarning;
@property (weak) IBOutlet NSButton *retryButton;

@property (weak) IBOutlet NSButton *VietButton;
@property (weak) IBOutlet NSButton *EngButton;

@property (weak) IBOutlet NSButton *FreeMarkButton;
// [MINDFUL] Story 1.7 — checkbox 4-tab thay bằng PillSwitch (xem BrandControls.h). FreeMarkButton
// ở trên KHÔNG đổi — nó là control ẨN (hidden=YES) nằm ngoài 4 tab, không thuộc phạm vi story này.
@property (weak) IBOutlet PillSwitch *UseModernOrthography;

@property (weak) IBOutlet PillSwitch *CheckSpellingButton;

@property (weak) IBOutlet PillSwitch *RunOnStartupButton;
@property (weak) IBOutlet PillSwitch *ShowUIButton;

@property (weak) IBOutlet PillSwitch *UseGrayIcon;
@property (weak) IBOutlet PillSwitch *QuickTelex;

@property (weak) IBOutlet PillSwitch *RestoreIfInvalidWord;
@property (weak) IBOutlet PillSwitch *FixRecommendBrowser;
@property (weak) IBOutlet PillSwitch *AllowZWJF;
@property (weak) IBOutlet PillSwitch *TempOffSpellChecking;

@property (weak) IBOutlet PillSwitch *UseMacro;
@property (weak) IBOutlet PillSwitch *UseMacroInEnglishMode;

@property (weak) IBOutlet PillSwitch *SendKeyStepByStep;
@property (weak) IBOutlet PillSwitch *AutoRememberSwitchKey;
@property (weak) IBOutlet PillSwitch *UpperCaseFirstChar;
@property (weak) IBOutlet PillSwitch *QuickStartConsonant;
@property (weak) IBOutlet PillSwitch *QuickEndConsonant;

@property (weak) IBOutlet PillSwitch *RememberTableCode;
@property (weak) IBOutlet PillSwitch *OtherLanguage;

@property (weak) IBOutlet PillSwitch *TempOffOpenKey;
@property (weak) IBOutlet PillSwitch *AutoCapsMacro;
@property (weak) IBOutlet PillSwitch *ShowIconOnDock;
@property (weak) IBOutlet PillSwitch *CheckNewVersionOnStartup;
@property (weak) IBOutlet PillSwitch *FixChromiumBrowser;
@property (weak) IBOutlet PillSwitch *PerformLayoutCompat;

@property (weak) IBOutlet NSButton *CheckNewVersionButton;
@property (weak) IBOutlet NSTextField *VersionInfo;

@property (weak) IBOutlet NSImageView *cursorImage;

-(void)fillData;
@end

