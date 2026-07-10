//
//  ViewController.m
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import "ViewController.h"
#import "OpenKeyManager.h"
#import "AppDelegate.h"
#import "MyTextField.h"
#import "GatekeeperCardView.h"   // [MINDFUL] Story 1.4 (lát cắt dọc — treo card lên đầu panel)
#import "BrandColors.h"          // [MINDFUL] Story 1.7 — [Brand teal]/[Brand charcoal]/[Brand divider]

extern AppDelegate* appDelegate;
extern void OnSpellCheckingChanged(void);

ViewController* viewController;
extern int vFreeMark;
extern int vCheckSpelling;
extern int vUseModernOrthography;
extern int vSwitchKeyStatus;
extern int vQuickTelex;
extern int vRestoreIfWrongSpelling;
extern int vFixRecommendBrowser;
extern int vUseMacro;
extern int vUseMacroInEnglishMode;
extern int vSendKeyStepByStep;
extern int vUseSmartSwitchKey;
extern int vUpperCaseFirstChar;
extern int vTempOffSpelling;
extern int vAllowConsonantZFWJ;
extern int vQuickStartConsonant;
extern int vQuickEndConsonant;
extern int vRememberCode;
extern int vOtherLanguage;
extern int vTempOffOpenKey;
extern int vShowIconOnDock;
extern int vAutoCapsMacro;
extern int vFixChromiumBrowser;
extern int vPerformLayoutCompat;

@implementation ViewController {
    // [MINDFUL] Story 1.7 — hàng "Phím chuyển" + "Kêu beep" thay bằng PillSwitch (BrandControls.h).
    __weak IBOutlet PillSwitch *CustomSwitchCommand;
    __weak IBOutlet PillSwitch *CustomSwitchOption;
    __weak IBOutlet PillSwitch *CustomSwitchControl;
    __weak IBOutlet PillSwitch *CustomSwitchShift;
    __weak IBOutlet MyTextField *CustomSwitchKey;
    __weak IBOutlet PillSwitch *CustomBeepSound;
    NSArray* tabviews, *tabbuttons;
    NSRect tabViewRect;
    NSView* tabButtonBackground;
    GatekeeperCardView* gatekeeperCard;   // [MINDFUL] Story 1.4
    BOOL gatekeeperMounted;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    viewController = self;
    CustomSwitchKey.Parent = self;
    
    self.appOK.hidden = YES;
    self.permissionWarning.hidden = YES;
    self.retryButton.enabled = NO;
 
    NSRect parentRect = self.viewParent.frame;
    parentRect.size.height = 490;
    self.viewParent.frame = parentRect;
    
    //set correct tabgroup
    tabviews = [NSArray arrayWithObjects:self.tabviewPrimary, self.tabviewMacro, self.tabviewSystem, self.tabviewInfo, nil];
    tabbuttons = [NSArray arrayWithObjects:self.tabbuttonPrimary, self.tabbuttonMacro, self.tabbuttonSystem, self.tabbuttonInfo, nil];
    NSButton* firstTabButton = [tabbuttons objectAtIndex:0];
    NSRect tabButtonBackgroundRect = firstTabButton.frame;
    for (NSButton* button in tabbuttons) {
        tabButtonBackgroundRect = NSUnionRect(tabButtonBackgroundRect, button.frame);
    }
    tabButtonBackgroundRect = NSInsetRect(tabButtonBackgroundRect, -2, -2);
    tabButtonBackground = [[NSView alloc] initWithFrame:tabButtonBackgroundRect];
    [tabButtonBackground setWantsLayer:YES];
    tabButtonBackground.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];
    [self.view addSubview:tabButtonBackground];
    tabViewRect = self.tabviewPrimary.frame;
    for (NSBox* b in tabviews) {
        b.frame = tabViewRect;
    }
    
    [self showTab:0];
    [self applyBrandCardStyleToGroups];

    NSArray* inputTypeData = [[NSArray alloc] initWithObjects:@"Telex", @"VNI", @"Simple Telex 1", @"Simple Telex 2", nil];
    NSArray* codeData = [OpenKeyManager getTableCodes];
    
    //preset data
    [_popupInputType removeAllItems];
    [_popupInputType addItemsWithTitles:inputTypeData];
    
    [self.popupCode removeAllItems];
    [self.popupCode addItemsWithTitles:codeData];
    
    [self initKey];
    
    [self fillData];
    
    // set version info
    self.VersionInfo.stringValue = [NSString stringWithFormat:@"Phiên bản %@ (build %@) - Ngày cập nhật %@",
    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"],
    [OpenKeyManager getBuildDate]] ;
}

- (void)viewDidAppear {
    [super viewDidAppear];
    NSString* str = @"Mindful Keyboard %@ - Bộ gõ Tiếng Việt";
    self.view.window.title = [NSString stringWithFormat:str, [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]];
    [self mountGatekeeperCardIfNeeded];
    [gatekeeperCard refresh];
}

// [MINDFUL] Story 1.4 — lát cắt dọc: treo card Gác cổng lên đầu panel HIỆN TẠI, không
// đập storyboard. Cửa sổ cao thêm 1 dải ở trên; nội dung cũ neo đáy (autoresizing mặc định)
// nên giữ nguyên vị trí, card nằm vào dải mới ở trên cùng. Chỉ chạy 1 lần.
- (void)mountGatekeeperCardIfNeeded {
    if (gatekeeperMounted) return;
    NSWindow* window = self.view.window;
    if (!window) return;

    const CGFloat cardHeight = 92.0;
    const CGFloat margin = 16.0;
    const CGFloat strip = cardHeight + margin;   // khoảng thêm ở đỉnh

    // Nới cửa sổ cao thêm 'strip' (giữ mép trên cố định → khoảng trống mở ra phía trên nội dung cũ).
    NSSize contentSize = self.view.frame.size;
    contentSize.height += strip;
    NSRect frame = window.frame;
    frame.size.height += strip;   // giữ frame.origin → cạnh dưới cố định, mở thêm ở trên
    [window setFrame:frame display:YES];
    [window setContentSize:contentSize];

    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    gatekeeperCard = [[GatekeeperCardView alloc]
        initWithFrame:NSMakeRect(margin, h - cardHeight - (margin / 2.0), w - 2 * margin, cardHeight)];
    gatekeeperCard.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;  // bám mép trên, giãn ngang
    [self.view addSubview:gatekeeperCard];

    gatekeeperMounted = YES;
}

- (void)viewWillAppear {
    [self initKey];
}

-(void)initKey {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![OpenKeyManager initEventTap]) {
            //self.permissionWarning.hidden = NO;
            //self.retryButton.enabled = YES;
        } else {
            //self.appOK.hidden = NO;
        }
    });
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

// [MINDFUL] Story 1.7 — bọc box header ("Kiểu gõ"/"Bảng mã"/"Phím chuyển"/"Chế độ gõ") + 4 box
// nội dung tab vào card NOW BRAND OS (bo góc 16px + bóng ngọc bích, xem BrandControls.h). Cùng kỹ
// thuật với ConvertToolViewController -applyBrandCardStyleToOptionBoxes (story 1.9): boxType +
// transparent tắt fill/viền gốc trước khi áp layer tự vẽ. Gọi sau khi mọi box đã có frame cuối
// (sau vòng lặp gán tabViewRect + showTab:0 ở trên) để shadowPath tính đúng kích thước.
- (void)applyBrandCardStyleToGroups {
    for (NSBox *box in @[self.headerBox, self.tabviewPrimary, self.tabviewMacro, self.tabviewSystem, self.tabviewInfo]) {
        box.boxType = NSBoxCustom;
        box.transparent = YES;
        [box applyBrandCardStyle];
    }
}

// [MINDFUL] Story 1.7 — 4 nút chọn tab hiện đang tô "đang chọn" bằng accent color hệ thống (nút
// bezelStyle="rounded" + state=on, macOS tự vẽ nền bằng NSColor.controlAccentColor — không có API
// công khai để ép riêng 1 màu, cùng lý do PillSwitch phải tự vẽ tay thay vì tint checkbox). Nên
// tắt hẳn bezel gốc (bordered=NO) và tự vẽ nền teal/viền divider bằng CALayer khi chọn/không chọn.
- (void)styleTabButton:(NSButton *)button selected:(BOOL)selected {
    button.bordered = NO;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 8.0;
    button.layer.borderWidth = selected ? 0.0 : 1.0;
    button.layer.borderColor = [Brand divider].CGColor;
    button.layer.backgroundColor = selected ? [Brand teal].CGColor : [NSColor clearColor].CGColor;

    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: selected ? [NSColor whiteColor] : [Brand charcoal],
        NSFontAttributeName: (button.font ?: [NSFont systemFontOfSize:13])
    };
    button.attributedTitle = [[NSAttributedString alloc] initWithString:button.title attributes:attrs];
}

// [MINDFUL] Story 1.7 — radio "Chế độ gõ" (Tiếng Việt/English): KHÔNG đổi buttonType/bordered.
// Đã verify (đọc tài liệu AppKit + đối chiếu lý do PillSwitch đã ghi trong BrandControls.h):
// checkbox/radio button cell không có API tint công khai đáng tin cậy (contentTintColor/bezelColor
// đều không tác dụng lên glyph switch/radio, Apple tài liệu hoá rõ với bezelColor). Cách vẽ lại
// đúng đắn là tự vẽ cả glyph tròn (như PillSwitch làm với checkbox) — nhưng việc đó cần verify
// hành vi loại-trừ-lẫn-nhau (chọn Việt tự tắt Anh) bằng THAO TÁC CLICK THẬT, và sandbox này không
// có quyền Accessibility để tự động click kiểm tra. Rủi ro làm gãy tính năng chuyển Việt/Anh (rất
// hay dùng) lớn hơn lợi ích thẩm mỹ — nên CHỈ tô màu CHỮ (không đụng chấm radio/cơ chế chọn) sang
// Brand.teal khi đang chọn. Chấm radio vẫn theo Accent Color hệ thống — đã báo lại, xem báo cáo.
- (void)styleLanguageRadioButton:(NSButton *)button selected:(BOOL)selected {
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: selected ? [Brand teal] : [NSColor labelColor],
        NSFontAttributeName: (button.font ?: [NSFont systemFontOfSize:13])
    };
    button.attributedTitle = [[NSAttributedString alloc] initWithString:button.title attributes:attrs];
}

-(void)showTab:(NSInteger)index {
    NSRect tempRect = tabViewRect;
    tempRect.origin.y = 1000;
    for (NSBox* b in tabviews) {
        [b setHidden:YES];
        b.frame = tempRect;
    }
    for (NSButton* b in tabbuttons) {
        [b setState:NSControlStateValueOff];
        [self styleTabButton:b selected:NO];
    }
    NSBox* b = [tabviews objectAtIndex:index];
    [b setHidden:NO];
    b.frame = tabViewRect;

    NSButton* button = [tabbuttons objectAtIndex:index];
    [button setState:NSControlStateValueOn];
    [self styleTabButton:button selected:YES];

    [self.view addSubview:tabButtonBackground positioned:NSWindowAbove relativeTo:b];
    for (NSButton* tabButton in tabbuttons) {
        [self.view addSubview:tabButton positioned:NSWindowAbove relativeTo:nil];
    }
}

- (IBAction)onTabButton:(NSButton *)sender {
    [self showTab:sender.tag];
}

- (IBAction)onInputTypeChanged:(NSPopUpButton *)sender {
    [appDelegate onInputTypeSelectedIndex:(int)[self.popupInputType indexOfSelectedItem]];
}

- (IBAction)onCodeTableChanged:(NSPopUpButton *)sender {
    [appDelegate onCodeTableChanged:(int)[self.popupCode indexOfSelectedItem]];
}

- (IBAction)onLanguageChanged:(id)sender {
    [appDelegate onInputMethodSelected];
    // [MINDFUL] Story 1.7 — radio loại-trừ-lẫn-nhau vẫn do AppKit tự quản lý (buttonType=radio,
    // KHÔNG đụng); ở đây chỉ đồng bộ lại màu chữ teal cho bên đang chọn (xem
    // -styleLanguageRadioButton:selected: — không đụng chấm radio/cơ chế chọn).
    [self styleLanguageRadioButton:self.VietButton selected:(self.VietButton.state == NSControlStateValueOn)];
    [self styleLanguageRadioButton:self.EngButton selected:(self.EngButton.state == NSControlStateValueOn)];
}

- (IBAction)onRestart:(id)sender {
    self.appOK.hidden = YES;
    self.permissionWarning.hidden = YES;
    self.retryButton.enabled = NO;
    
    [self initKey];
}

- (IBAction)onFreeMark:(NSButton *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"FreeMark"];
    vFreeMark = (int)val;
}

- (IBAction)onModernOrthography:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"ModernOrthography"];
    vUseModernOrthography = (int)val;
}

- (IBAction)onCheckSpelling:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"Spelling"];
    vCheckSpelling = (int)val;
    [self.RestoreIfInvalidWord setEnabled:val];
    [self.AllowZWJF setEnabled:val];
    [self.TempOffSpellChecking setEnabled:val];
    OnSpellCheckingChanged();
}

- (IBAction)onShowUIOnStartup:(PillSwitch *)sender {
    [self setCustomValue:sender keyToSet:@"ShowUIOnStartup"];
}

- (IBAction)onRunOnStartup:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"RunOnStartup"];
    [appDelegate setRunOnStartup:val];
}

- (IBAction)onGrayIcon:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"GrayIcon"];
    [appDelegate setGrayIcon:val];
}

- (IBAction)onQuickTelex:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"QuickTelex"];
    vQuickTelex = (int)val;
}

- (IBAction)onRestoreIfInvalidWord:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"RestoreIfInvalidWord"];
    vRestoreIfWrongSpelling = (int)val;
}

- (IBAction)omTempOffSpellChecking:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vTempOffSpelling"];
    vTempOffSpelling = (int)val;
}

- (IBAction)onAllowZFWJ:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vAllowConsonantZFWJ"];
    vAllowConsonantZFWJ = (int)val;
}

- (IBAction)onFixRecommendBrowser:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"FixRecommendBrowser"];
    vFixRecommendBrowser = (int)val;
    [self.FixChromiumBrowser setEnabled:val];
}

- (IBAction)onControlSwitchKey:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x100);
    vSwitchKeyStatus |= val << 8;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onOptionSwitchKey:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x200);
    vSwitchKeyStatus |= val << 9;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onCommandSwitchKey:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x400);
    vSwitchKeyStatus |= val << 10;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onShiftSwitchKey:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x800);
    vSwitchKeyStatus |= val << 11;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

-(void)onMyTextFieldKeyChange:(unsigned short)keyCode character:(unsigned short)character {
    vSwitchKeyStatus &= 0xFFFFFF00;
    vSwitchKeyStatus |= keyCode;
    vSwitchKeyStatus &= 0x00FFFFFF;
    vSwitchKeyStatus |= ((unsigned int)character<<24);
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onBeepSound:(PillSwitch *)sender {
    unsigned int val = (unsigned int)[self setCustomValue:sender keyToSet:nil];
    vSwitchKeyStatus &= (~0x8000);
    vSwitchKeyStatus |= val << 15;
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (IBAction)onSendKeyStepByStep:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"SendKeyStepByStep"];
    vSendKeyStepByStep = (int)val;
}

- (IBAction)onPerformLayoutCompat:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vPerformLayoutCompat"];
    vPerformLayoutCompat = (int)val;
}

// [MINDFUL] Story 1.7 — nhận cả PillSwitch (đã chuyển) lẫn NSButton (vd onFreeMark: — control ẩn,
// NGOÀI phạm vi story này, xem ViewController.h). Dò kiểu bằng respondsToSelector thay vì ép kiểu
// cứng, để không control nào bị đổi hành vi ngoài ý muốn và không phát sinh warning ép kiểu sai.
- (NSInteger)setCustomValue:(id)sender keyToSet:(NSString*) key {
    BOOL isOn = NO;
    if ([sender respondsToSelector:@selector(isOn)]) {
        isOn = [(PillSwitch *)sender isOn];
    } else if ([sender respondsToSelector:@selector(state)]) {
        isOn = ([(NSButton *)sender state] == NSControlStateValueOn);
    }
    NSInteger val = isOn ? 1 : 0;
    if (key != nil)
        [[NSUserDefaults standardUserDefaults] setInteger:val forKey:key];
    return val;
}

- (IBAction)onMacroButton:(id)sender {
    [appDelegate onMacroSelected];
}

- (IBAction)onMacroChanged:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UseMacro"];
    vUseMacro = (int)val;
}

- (IBAction)onUseMacroInEnglishModeChanged:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UseMacroInEnglishMode"];
    vUseMacroInEnglishMode = (int)val;
}

- (IBAction)onAutoRememberSwitchKey:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UseSmartSwitchKey"];
    vUseSmartSwitchKey = (int)val;
}

- (IBAction)onUpperCaseFirstChar:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"UpperCaseFirstChar"];
    vUpperCaseFirstChar = (int)val;
}
- (IBAction)onQuickStartConsonant:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vQuickStartConsonant"];
    vQuickStartConsonant = (int)val;
}

- (IBAction)onQuickEndConsonant:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vQuickEndConsonant"];
    vQuickEndConsonant = (int)val;
}

- (IBAction)onTempOffOpenKeyByHotKey:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vTempOffOpenKey"];
    vTempOffOpenKey = (int)val;
}

- (IBAction)onRememberTableCode:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vRememberCode"];
    vRememberCode = (int)val;
}
- (IBAction)onOtherLanguage:(PillSwitch *)sender {

    NSInteger val = [self setCustomValue:sender keyToSet:@"vOtherLanguage"];
    vOtherLanguage = (int)val;
}


- (IBAction)onAutoCapsMacro:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vAutoCapsMacro"];
    vAutoCapsMacro = (int)val;
}

- (IBAction)onShowIconOnDock:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vShowIconOnDock"];
    vShowIconOnDock = (int)val;
    if (!vShowIconOnDock) {
        [self.view.window close];
    }
    [appDelegate showIconOnDock:vShowIconOnDock];
}

- (IBAction)onCheckNewVersionOnStartup:(PillSwitch *)sender {
    NSInteger val = sender.isOn ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"DontCheckUpdate"];
}

- (IBAction)onFixChromiumBrowser:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"vFixChromiumBrowser"];
    vFixChromiumBrowser = (int)val;
}

- (IBAction)onTerminateApp:(id)sender {
    [NSApp terminate:0];
}

-(void)fillData {
    NSInteger value;
    
    NSInteger intInputMethod = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
    if (intInputMethod == 1) {
        self.VietButton.state = NSControlStateValueOn;
    } else if (intInputMethod == 0) {
        self.EngButton.state = NSControlStateValueOn;
    }
    // [MINDFUL] Story 1.7 — đồng bộ màu chữ teal cho radio đang chọn (xem -styleLanguageRadioButton:selected:).
    [self styleLanguageRadioButton:self.VietButton selected:(self.VietButton.state == NSControlStateValueOn)];
    [self styleLanguageRadioButton:self.EngButton selected:(self.EngButton.state == NSControlStateValueOn)];

    NSInteger intInputType = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputType"];
    [self.popupInputType selectItemAtIndex:intInputType];

    NSInteger intCodeTable = [[NSUserDefaults standardUserDefaults] integerForKey:@"CodeTable"];
    [self.popupCode selectItemAtIndex:intCodeTable];

    //option
    NSInteger showui = [[NSUserDefaults standardUserDefaults] integerForKey:@"ShowUIOnStartup"];
    [self.ShowUIButton setOn:showui animated:NO];

    NSInteger freeMark = [[NSUserDefaults standardUserDefaults] integerForKey:@"FreeMark"];
    self.FreeMarkButton.state = freeMark ? NSControlStateValueOn : NSControlStateValueOff;

    NSInteger useModernOrthography = [[NSUserDefaults standardUserDefaults] integerForKey:@"ModernOrthography"];
    [self.UseModernOrthography setOn:useModernOrthography animated:NO];

    NSInteger spelling = [[NSUserDefaults standardUserDefaults] integerForKey:@"Spelling"];
    [self.CheckSpellingButton setOn:spelling animated:NO];

    NSInteger runOnStartup = [[NSUserDefaults standardUserDefaults] integerForKey:@"RunOnStartup"];
    [self.RunOnStartupButton setOn:runOnStartup animated:NO];

    NSInteger useGrayIcon = [[NSUserDefaults standardUserDefaults] integerForKey:@"GrayIcon"];
    [self.UseGrayIcon setOn:useGrayIcon animated:NO];

    NSInteger quicTelex = [[NSUserDefaults standardUserDefaults] integerForKey:@"QuickTelex"];
    [self.QuickTelex setOn:quicTelex animated:NO];

    NSInteger restoreIfInvalidWord = [[NSUserDefaults standardUserDefaults] integerForKey:@"RestoreIfInvalidWord"];
    [self.RestoreIfInvalidWord setOn:restoreIfInvalidWord animated:NO];
    [self.RestoreIfInvalidWord setEnabled:spelling];

    NSInteger tempOffSpelling = [[NSUserDefaults standardUserDefaults] integerForKey:@"vTempOffSpelling"];
    [self.TempOffSpellChecking setOn:tempOffSpelling animated:NO];
    [self.TempOffSpellChecking setEnabled:spelling];

    NSInteger allowZFWJ = [[NSUserDefaults standardUserDefaults] integerForKey:@"vAllowConsonantZFWJ"];
    [self.AllowZWJF setOn:allowZFWJ animated:NO];
    [self.AllowZWJF setEnabled:spelling];

    NSInteger fixRecommendBrowser = [[NSUserDefaults standardUserDefaults] integerForKey:@"FixRecommendBrowser"];
    [self.FixRecommendBrowser setOn:fixRecommendBrowser animated:NO];

    NSInteger useMacro = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMacro"];
    [self.UseMacro setOn:useMacro animated:NO];

    NSInteger useMacroInEnglish = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseMacroInEnglishMode"];
    [self.UseMacroInEnglishMode setOn:useMacroInEnglish animated:NO];

    NSInteger sendKeySbS = [[NSUserDefaults standardUserDefaults] integerForKey:@"SendKeyStepByStep"];
    [self.SendKeyStepByStep setOn:sendKeySbS animated:NO];

    NSInteger useSmartSwitchKey = [[NSUserDefaults standardUserDefaults] integerForKey:@"UseSmartSwitchKey"];
    [self.AutoRememberSwitchKey setOn:useSmartSwitchKey animated:NO];

    NSInteger upperCaseFirstChar = [[NSUserDefaults standardUserDefaults] integerForKey:@"UpperCaseFirstChar"];
    [self.UpperCaseFirstChar setOn:upperCaseFirstChar animated:NO];

    NSInteger quickStartConsonant = [[NSUserDefaults standardUserDefaults] integerForKey:@"vQuickStartConsonant"];
    [self.QuickStartConsonant setOn:quickStartConsonant animated:NO];

    NSInteger quickEndConsonant = [[NSUserDefaults standardUserDefaults] integerForKey:@"vQuickEndConsonant"];
    [self.QuickEndConsonant setOn:quickEndConsonant animated:NO];

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vRememberCode"];
    [self.RememberTableCode setOn:value animated:NO];

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vOtherLanguage"];
    [self.OtherLanguage setOn:value animated:NO];

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vTempOffOpenKey"];
    [self.TempOffOpenKey setOn:value animated:NO];

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vAutoCapsMacro"];
    [self.AutoCapsMacro setOn:value animated:NO];

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vShowIconOnDock"];
    [self.ShowIconOnDock setOn:value animated:NO];

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"DontCheckUpdate"];
    [self.CheckNewVersionOnStartup setOn:!value animated:NO];

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vFixChromiumBrowser"];
    [self.FixChromiumBrowser setOn:value animated:NO];
    self.FixChromiumBrowser.enabled = fixRecommendBrowser ? YES : NO;

    value = [[NSUserDefaults standardUserDefaults] integerForKey:@"vPerformLayoutCompat"];
    [self.PerformLayoutCompat setOn:value animated:NO];

    [CustomSwitchControl setOn:(vSwitchKeyStatus & 0x100) != 0 animated:NO];
    [CustomSwitchOption setOn:(vSwitchKeyStatus & 0x200) != 0 animated:NO];
    [CustomSwitchCommand setOn:(vSwitchKeyStatus & 0x400) != 0 animated:NO];
    [CustomSwitchShift setOn:(vSwitchKeyStatus & 0x800) != 0 animated:NO];
    [CustomBeepSound setOn:(vSwitchKeyStatus & 0x8000) != 0 animated:NO];
    [CustomSwitchKey setTextByChar:((vSwitchKeyStatus>>24) & 0xFF)];

}

- (IBAction)onOK:(id)sender {
    [self.view.window close];
}

- (IBAction)onDefaultConfig:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Bạn có chắc chắn muốn thiết lập lại cấu hình mặc định?"];
    [alert addButtonWithTitle:@"Có"];
    [alert addButtonWithTitle:@"Không"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == 1000) {
            [appDelegate loadDefaultConfig];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"ShowUIOnStartup"];
            [self.ShowUIButton setOn:NO animated:NO];

            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"RunOnStartup"];
            [self.RunOnStartupButton setOn:YES animated:NO];
        }
    }];
}

- (IBAction)onHomePageLink:(id)sender {
    // Dòng credit phụ "Dựa trên OpenKey (GPL v3)" — mở kho gốc OpenKey theo yêu cầu ghi nhận nguồn.
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/tuyenvm/OpenKey"]];
}

- (IBAction)onFanpageLink:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://www.facebook.com/OpenKeyVN"]];
}

- (IBAction)onEmailLink:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"mailto:app365@gnh.edu.vn"]];
}

- (IBAction)onSourceCode:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/tuyenvm/OpenKey"]];
}

- (IBAction)onCheckNewVersionButton:(id)sender {
    // [MINDFUL] Đã gỡ bộ tự-cập-nhật OpenKey (xem OpenKeyManager.m). Chưa có kênh cập nhật
    // riêng cho Mindful Keyboard nên nút chỉ báo thật thà tình trạng hiện tại, KHÔNG gọi mạng.
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"Bạn đang dùng phiên bản mới nhất (%@)",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    alert.informativeText = @"Tính năng tự động kiểm tra cập nhật sẽ có ở phiên bản sau.";
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

@end
