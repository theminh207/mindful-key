//
//  AppDelegate.m
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>
#include <libproc.h>
#include <sys/proc_info.h>
#import "AppDelegate.h"
#import "ViewController.h"
#import "OpenKeyManager.h"
#import "MJAccessibilityUtils.h"
#import "MoodWatchMac.h"
#import "BellMac.h"
#import "MoodStoreMac.h"
#import "ReflectionScreenMac.h"
#import <UserNotifications/UserNotifications.h>
#import "PanelViewController.h"   // [MINDFUL] PHA 1 — popover panel trạng thái
#import "SettingsWindowController.h"   // [MINDFUL] Story 2.2 — cửa sổ quản lý nav-trái 6 mục

AppDelegate* appDelegate;
extern ViewController* viewController;
extern void OnTableCodeChange(void);
extern void OnInputMethodChanged(void);
extern void RequestNewSession(void);
extern void OnActiveAppChanged(void);

//see document in Engine.h
int vLanguage = 1;
int vInputType = 0;
int vFreeMark = 0;
int vCodeTable = 0;
int vCheckSpelling = 1;
int vUseModernOrthography = 1;
int vQuickTelex = 0;
#define DEFAULT_SWITCH_STATUS 0x7A000206 //default option + z
int vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
int vRestoreIfWrongSpelling = 0;
int vFixRecommendBrowser = 1;
int vUseMacro = 1;
int vUseMacroInEnglishMode = 1;
int vAutoCapsMacro = 0;
int vSendKeyStepByStep = 0;
int vUseSmartSwitchKey = 1;
int vUpperCaseFirstChar = 0;
int vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0;
int vQuickStartConsonant = 0;
int vQuickEndConsonant = 0;
int vRememberCode = 1; //new on version 2.0
int vOtherLanguage = 1; //new on version 2.0
int vTempOffOpenKey = 0; //new on version 2.0

int vShowIconOnDock = 0; //new on version 2.0

int vPerformLayoutCompat = 0;

//beta feature
int vFixChromiumBrowser = 0; //new on version 2.0

extern int convertToolHotKey;
extern bool convertToolDontAlertWhenCompleted;

@interface AppDelegate ()

@end


@implementation AppDelegate {
    NSWindowController *_mainWC;
    NSWindowController *_macroWC;
    NSWindowController *_convertWC;
    NSWindowController *_aboutWC;
    SettingsWindowController *_settingsWC;   // [MINDFUL] Story 2.2 — cửa sổ quản lý nav-trái 6 mục

    NSStatusItem *statusItem;
    NSMenu *theMenu;

    // [MINDFUL] PHA 1 — popover panel trạng thái (bấm trái icon). Menu cũ chuyển sang bấm phải / gear.
    NSPopover *_panelPopover;
    PanelViewController *_panelVC;

    NSMenuItem* menuInputMethod;
    
    NSMenuItem* mnuTelex;
    NSMenuItem* mnuVNI;
    NSMenuItem* mnuSimpleTelex1;
    NSMenuItem* mnuSimpleTelex2;
    
    NSMenuItem* mnuUnicode;
    NSMenuItem* mnuTCVN;
    NSMenuItem* mnuVNIWindows;
    
    NSMenuItem* mnuUnicodeComposite;
    NSMenuItem* mnuVietnameseLocaleCP1258;
    
    NSMenuItem* mnuQuickConvert;
    NSMenuItem* mnuMoodWatch;
    NSMenuItem* mnuBellSettings;
    NSMenuItem* mnuBellToggle;
}

-(void)askPermission {
    // [MINDFUL] Bộ gõ cần CẢ HAI quyền: Accessibility + Input Monitoring cho CGEventTap.
    // TRƯỚC: thiếu quyền → hiện hộp này rồi [NSApp terminate] (app tự thoát) → người dùng
    // không xem/chỉnh được giao diện, phải mò cấp quyền + tự mở lại. NAY: chỉ NHẮC + mở đúng
    // 2 panel Cài đặt, KHÔNG thoát app — luồng khởi động vẫn dựng bảng điều khiển để xem/chỉnh.
    // Phần GÕ (event tap) tự thất bại êm và bật lại sau khi cấp đủ 2 quyền rồi mở lại app.
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Cần cấp quyền để gõ tiếng Việt"];
    [alert setInformativeText:@"Phần GÕ cần quyền Trợ năng (Accessibility) VÀ Giám sát Nhập liệu (Input Monitoring). Bạn vẫn mở/chỉnh được bảng điều khiển ngay bây giờ; riêng phần gõ chỉ hoạt động sau khi cấp đủ 2 quyền trong System Settings › Privacy & Security rồi mở lại ứng dụng."];

    [alert addButtonWithTitle:@"Để sau"];
    [alert addButtonWithTitle:@"Mở cài đặt quyền"];

    [alert.window makeKeyAndOrderFront:nil];
    [alert.window setLevel:NSStatusWindowLevel];

    NSModalResponse res = [alert runModal];

    if (res == 1001) {
        if (!MJAccessibilityIsEnabled())
            MJAccessibilityOpenPanel();
        if (!MJInputMonitoringIsEnabled())
            MJInputMonitoringOpenPanel();
    }
    // KHÔNG [NSApp terminate] nữa — để app sống tiếp và dựng giao diện.
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    appDelegate = self;
    
    [self registerSupportedNotification];
    
    //set quick tooltip
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: 50]
                                              forKey: @"NSInitialToolTipDelay"];
    
    //check whether this app has been launched before that or not
    //Only check instances owned by current user (for multi-user/Fast User Switching support)
    uid_t currentUID = getuid();
    NSArray<NSRunningApplication *>* runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    pid_t myPID = [[NSProcessInfo processInfo] processIdentifier];
    BOOL alreadyRunning = NO;

    for (NSRunningApplication *app in runningApps) {
        if ([app.bundleIdentifier isEqualToString:OPENKEY_BUNDLE] &&
            app.processIdentifier != myPID) {
            pid_t pid = app.processIdentifier;
            struct proc_bsdinfo proc;
            int size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &proc, sizeof(proc));
            if (size == sizeof(proc) && proc.pbi_uid == currentUID) {
                alreadyRunning = YES;
                break;
            }
        }
    }

    if (alreadyRunning) {
        [NSApp terminate:nil];
        return;
    }
    
    // check if user granted Accessibility + Input Monitoring permission (cả 2 đều bắt buộc
    // cho CGEventTap trên macOS hiện đại — xem MJAccessibilityUtils.h)
    // [MINDFUL] Thiếu quyền: KHÔNG return/thoát app nữa. Chỉ ghi cờ + kích popup hệ thống ở đây;
    // hộp NHẮC quyền (askPermission) được đẩy xuống CUỐI, hiện SAU khi bảng điều khiển đã render —
    // nếu hiện modal ngay đây thì nó chặn luồng khiến cửa sổ điều khiển tạo ra nhưng trắng, chưa vẽ.
    BOOL permissionMissing = (!MJAccessibilityIsEnabled() || !MJInputMonitoringIsEnabled());
    if (permissionMissing) {
        MJInputMonitoringRequestAccess(); // kích hoạt popup hệ thống lần đầu nếu chưa từng hỏi
    }

    vShowIconOnDock = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"vShowIconOnDock"];
    if (vShowIconOnDock)
        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];

    if (vSwitchKeyStatus & 0x8000)
        NSBeep();

    [self createStatusBarMenu];

    //init
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![OpenKeyManager initEventTap]) {
            [self onControlPanelSelected];
        } else {
            NSInteger showui = [[NSUserDefaults standardUserDefaults] integerForKey:@"ShowUIOnStartup"];
            if (showui == 1) {
                [self onControlPanelSelected];
            }
        }
        [self setQuickConvertString];
        // [MINDFUL] Nhắc quyền SAU khi UI đã hiện — panel render trước, hộp nhắc bung lên trên.
        if (permissionMissing) {
            [self askPermission];
        }
    });
    
    //load default config if is first launch
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NonFirstTime"] == 0) {
        [self loadDefaultConfig];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"NonFirstTime"];
    
    // [MINDFUL] ĐÃ GỠ tự-kiểm-tra-cập-nhật lúc khởi động. Bộ updater kế thừa từ OpenKey hỏi
    // version.json của kho tuyenvm/OpenKey (bản 2.0.3 / versionCode 47) rồi so với MindfulKey
    // (versionCode 1) → LẦN NÀO MỞ CŨNG nag "có bản mới 2.0.3" và trỏ người dùng về OpenKey —
    // sai nhận diện + tự gọi mạng lúc khởi động. Auto-update thật sẽ làm sau bằng Sparkle.
    // Preference "DontCheckUpdate" vẫn được giữ để Sparkle đọc lại sau này.

    //correct run on startup
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:@"RunOnStartup"];
    [appDelegate setRunOnStartup:val];

    // [MINDFUL] Kích hoạt lớp cảm xúc — TRƯỚC bản vá này, MoodWatchMac_Init() không hề được
    // gọi ở đâu cả, nên vOnWordCommitted không bao giờ được set dù code đã build sạch.
    MoodWatchMac_Init();
    BellMac_Init();

    if (@available(macOS 10.14, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                                                                           completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification authorization error: %@", error);
            }
        }];
    }

    // [MINDFUL] Hỏi đồng ý ghi nhật ký cảm xúc (bước 6) — hỏi lúc khởi động bình thường,
    // KHÔNG hỏi giữa lúc đang có 1 khoảnh khắc căng thẳng thật. Idempotent, chỉ hỏi 1 lần.
    dispatch_async(dispatch_get_main_queue(), ^{
        MoodStoreMac_AskConsentIfNeeded();
    });
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self onControlPanelSelected];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void) createStatusBarMenu {
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    statusItem.button.image = [NSImage imageNamed:@"Status"];
    statusItem.button.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
    
    theMenu = [[NSMenu alloc] initWithTitle:@""];
    [theMenu setAutoenablesItems:NO];
    
    menuInputMethod = [theMenu addItemWithTitle:@"Bật Tiếng Việt"
                                                     action:@selector(onInputMethodSelected)
                                              keyEquivalent:@""];
    [theMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem* menuInputType = [theMenu addItemWithTitle:@"Kiểu gõ" action:nil keyEquivalent:@""];
    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    mnuUnicode = [theMenu addItemWithTitle:@"Unicode dựng sẵn" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuUnicode.tag = 0;
    mnuTCVN = [theMenu addItemWithTitle:@"TCVN3 (ABC)" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuTCVN.tag = 1;
    mnuVNIWindows = [theMenu addItemWithTitle:@"VNI Windows" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuVNIWindows.tag = 2;
    NSMenuItem* menuCode = [theMenu addItemWithTitle:@"Bảng mã khác" action:nil keyEquivalent:@""];
    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    [theMenu addItemWithTitle:@"Công cụ chuyển mã..." action:@selector(onConvertTool) keyEquivalent:@""];
    mnuQuickConvert = [theMenu addItemWithTitle:@"Chuyển mã nhanh" action:@selector(onQuickConvert) keyEquivalent:@""];
    
    [theMenu addItem:[NSMenuItem separatorItem]];

    mnuMoodWatch = [theMenu addItemWithTitle:@"Bật Nhắc tâm (cảm xúc)" action:@selector(onMoodWatchSelected) keyEquivalent:@""];
    mnuBellToggle = [theMenu addItemWithTitle:@"Bật chuông tỉnh thức" action:@selector(onBellToggleSelected) keyEquivalent:@""];
    mnuBellSettings = [theMenu addItemWithTitle:@"Cài đặt Chuông tỉnh thức..." action:@selector(onBellSettingsSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Tạm hoãn chuông 1 giờ" action:@selector(onSnoozeBellSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Soi lại hôm nay..." action:@selector(onShowReflectionSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Xóa nhật ký cảm xúc..." action:@selector(onDeleteMoodLogSelected) keyEquivalent:@""];

#if DEBUG
    // [MINDFUL] 2026-07-16 — CHỈ có trong build Debug (biến mất khỏi bản Release, xem
    // MoodStoreMac.h). Giả lập 30 ngày dữ liệu (đủ cho cả Tuần lẫn Tháng) để test sông mà không
    // cần chờ dùng thật nhiều ngày; "Xóa dữ liệu giả lập" chỉ xóa đúng phần đánh dấu, dữ liệu
    // thật (nếu có) không bị đụng tới.
    [theMenu addItem:[NSMenuItem separatorItem]];
    [theMenu addItemWithTitle:@"[DEV] Giả lập 30 ngày dữ liệu sông" action:@selector(onSeedFakeMoodDataSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"[DEV] Xóa dữ liệu giả lập" action:@selector(onDeleteSimulatedMoodDataSelected) keyEquivalent:@""];
#endif

    [theMenu addItem:[NSMenuItem separatorItem]];
    
    // [MINDFUL] Story 2.2 — "Bảng điều khiển…"/"Gõ tắt…"/"Giới thiệu" gộp vào cửa sổ quản lý mới
    // (SettingsWindowController, nav trái 6 mục). onMacroSelected/onAboutSelected/onControlPanelSelected
    // KHÔNG bị xoá — vẫn được gọi từ nút "Bảng gõ tắt..." trong tabviewMacro + 3 đường fallback khởi động.
    [theMenu addItemWithTitle:@"Cài đặt…" action:@selector(onSettingsSelected) keyEquivalent:@""];
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    [theMenu addItemWithTitle:@"Thoát" action:@selector(terminate:) keyEquivalent:@"q"];
    
    
    [self setInputTypeMenu:menuInputType];
    [self setCodeMenu:menuCode];

    // [MINDFUL] PHA 1 — KHÔNG dùng setMenu (sẽ khiến bấm-trái mở menu). Thay: bấm TRÁI icon → popover
    // panel trạng thái; bấm PHẢI (hoặc gear trong panel) → menu cũ. Menu 'theMenu' giữ nguyên.
    _panelVC = [[PanelViewController alloc] init];
    __weak AppDelegate *weakSelf = self;
    // [MINDFUL] Story 2.2 — link "Cài đặt đầy đủ ▸" mở cửa sổ quản lý mới (KHÔNG còn cửa sổ 4-tab cũ).
    _panelVC.onOpenFullSettings = ^{ [weakSelf onSettingsSelected]; };
    _panelVC.onShowMenu = ^(NSView *anchor) { [weakSelf showLegacyMenu]; };

    _panelPopover = [[NSPopover alloc] init];
    _panelPopover.contentViewController = _panelVC;
    _panelPopover.behavior = NSPopoverBehaviorTransient;   // bấm ra ngoài tự đóng
    _panelPopover.animates = YES;

    statusItem.button.target = self;
    statusItem.button.action = @selector(onStatusItemClicked:);
    [statusItem.button sendActionOn:(NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp)];

    [self fillData];
}

- (void)onStatusItemClicked:(id)sender {
    NSEvent *e = [NSApp currentEvent];
    BOOL wantsMenu = (e.type == NSEventTypeRightMouseUp) ||
                     ((e.modifierFlags & NSEventModifierFlagControl) != 0);
    if (wantsMenu) {
        [self showLegacyMenu];
    } else {
        [self togglePanelPopover];
    }
}

- (void)togglePanelPopover {
    if (_panelPopover.isShown) {
        [_panelPopover close];
        return;
    }
    [_panelPopover showRelativeToRect:statusItem.button.bounds
                               ofView:statusItem.button
                        preferredEdge:NSMinYEdge];
    [_panelVC refreshAll];                                  // view đã load → cập nhật trạng thái mới nhất
    _panelPopover.contentSize = [_panelVC panelContentSize];
}

// Hiện menu cũ (mọi mục còn lại) — dùng chung cho bấm phải icon và nút gear ⋯ trong panel.
// popUpMenuPositioningItem:atLocation:inView: (KHÔNG deprecated như popUpStatusItemMenu:).
- (void)showLegacyMenu {
    if (_panelPopover.isShown) [_panelPopover close];
    [theMenu popUpMenuPositioningItem:nil atLocation:NSZeroPoint inView:statusItem.button];
}

-(void)setQuickConvertString {
    NSMutableString* hotKey = [NSMutableString stringWithString:@""];
    bool hasAdd = false;
    if (convertToolHotKey & 0x100) {
        [hotKey appendString:@"⌃"];
        hasAdd = true;
    }
    if (convertToolHotKey & 0x200) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        [hotKey appendString:@"⌥"];
        hasAdd = true;
    }
    if (convertToolHotKey & 0x400) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        [hotKey appendString:@"⌘"];
        hasAdd = true;
    }
    if (convertToolHotKey & 0x800) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        [hotKey appendString:@"⇧"];
        hasAdd = true;
    }
    
    unsigned short k = ((convertToolHotKey>>24) & 0xFF);
    if (k != 0xFE) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        if (k == kVK_Space)
            [hotKey appendFormat:@"%@", @"␣ "];
        else
            [hotKey appendFormat:@"%c", k];
    }
    [mnuQuickConvert setTitle: hasAdd ? [NSString stringWithFormat:@"Chuyển mã nhanh - [%@]", [hotKey uppercaseString]] : @"Chuyển mã nhanh"];
}

-(void)loadDefaultConfig {
    vLanguage = 1; [[NSUserDefaults standardUserDefaults] setInteger:vLanguage forKey:@"InputMethod"];
    vInputType = 0; [[NSUserDefaults standardUserDefaults] setInteger:vInputType forKey:@"InputType"];
    vFreeMark = 0; [[NSUserDefaults standardUserDefaults] setInteger:vFreeMark forKey:@"FreeMark"];
    vCheckSpelling = 1; [[NSUserDefaults standardUserDefaults] setInteger:vCheckSpelling forKey:@"Spelling"];
    vCodeTable = 0; [[NSUserDefaults standardUserDefaults] setInteger:vCodeTable forKey:@"CodeTable"];
    vSwitchKeyStatus = DEFAULT_SWITCH_STATUS; [[NSUserDefaults standardUserDefaults] setInteger:vCodeTable forKey:@"SwitchKeyStatus"];
    vQuickTelex = 0; [[NSUserDefaults standardUserDefaults] setInteger:vQuickTelex forKey:@"QuickTelex"];
    vUseModernOrthography = 0; [[NSUserDefaults standardUserDefaults] setInteger:vUseModernOrthography forKey:@"ModernOrthography"];
    vRestoreIfWrongSpelling = 0; [[NSUserDefaults standardUserDefaults] setInteger:vRestoreIfWrongSpelling forKey:@"RestoreIfInvalidWord"];
    vFixRecommendBrowser = 1; [[NSUserDefaults standardUserDefaults] setInteger:vFixRecommendBrowser forKey:@"FixRecommendBrowser"];
    vUseMacro = 1; [[NSUserDefaults standardUserDefaults] setInteger:vUseMacro forKey:@"UseMacro"];
    vUseMacroInEnglishMode = 0; [[NSUserDefaults standardUserDefaults] setInteger:vUseMacroInEnglishMode forKey:@"UseMacroInEnglishMode"];
    vSendKeyStepByStep = 0;[[NSUserDefaults standardUserDefaults] setInteger:vUseMacroInEnglishMode forKey:@"SendKeyStepByStep"];
    vUseSmartSwitchKey = 1;[[NSUserDefaults standardUserDefaults] setInteger:vUseSmartSwitchKey forKey:@"UseSmartSwitchKey"];
    vUpperCaseFirstChar = 0;[[NSUserDefaults standardUserDefaults] setInteger:vUpperCaseFirstChar forKey:@"UpperCaseFirstChar"];
    vTempOffSpelling = 0;[[NSUserDefaults standardUserDefaults] setInteger:vTempOffSpelling forKey:@"vTempOffSpelling"];
    vAllowConsonantZFWJ = 0;[[NSUserDefaults standardUserDefaults] setInteger:vAllowConsonantZFWJ forKey:@"vAllowConsonantZFWJ"];
    vQuickStartConsonant = 0;[[NSUserDefaults standardUserDefaults] setInteger:vQuickStartConsonant forKey:@"vQuickStartConsonant"];
    vQuickEndConsonant = 0;[[NSUserDefaults standardUserDefaults] setInteger:vQuickEndConsonant forKey:@"vQuickEndConsonant"];
    vRememberCode = 1;[[NSUserDefaults standardUserDefaults] setInteger:vRememberCode forKey:@"vRememberCode"];
    vOtherLanguage = 1;[[NSUserDefaults standardUserDefaults] setInteger:vOtherLanguage forKey:@"vOtherLanguage"];
    vTempOffOpenKey = 0;[[NSUserDefaults standardUserDefaults] setInteger:vTempOffOpenKey forKey:@"vTempOffOpenKey"];
    vShowIconOnDock = 0;[[NSUserDefaults standardUserDefaults] setInteger:vShowIconOnDock forKey:@"vShowIconOnDock"];
    vFixChromiumBrowser = 0;[[NSUserDefaults standardUserDefaults] setInteger:vFixChromiumBrowser forKey:@"vFixChromiumBrowser"];
    vPerformLayoutCompat = 0;[[NSUserDefaults standardUserDefaults] setInteger:vPerformLayoutCompat forKey:@"vPerformLayoutCompat"];
    vMoodWatch = 1;[[NSUserDefaults standardUserDefaults] setInteger:vMoodWatch forKey:@"vMoodWatch"];
    vBell = 0;[[NSUserDefaults standardUserDefaults] setInteger:vBell forKey:@"vBell"];
    vBellInterval = 60;[[NSUserDefaults standardUserDefaults] setInteger:vBellInterval forKey:@"vBellInterval"];
    vBellFrom = 8;[[NSUserDefaults standardUserDefaults] setInteger:vBellFrom forKey:@"vBellFrom"];
    vBellTo = 22;[[NSUserDefaults standardUserDefaults] setInteger:vBellTo forKey:@"vBellTo"];

    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"GrayIcon"];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"RunOnStartup"];

    [self fillData];
    [viewController fillData];
}

-(void)setRunOnStartup:(BOOL)val {
    CFStringRef appId = (__bridge CFStringRef)@"com.tuyenmai.OpenKeyHelper";
    SMLoginItemSetEnabled(appId, val);
}

-(void)setGrayIcon:(BOOL)val {
    [self fillData];
}

-(void)showIconOnDock:(BOOL)val {
    [NSApp setActivationPolicy: val ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory];
}

#pragma mark -StatusBar menu data

- (void)setInputTypeMenu:(NSMenuItem*) parent {
    //sub for Kieu Go
    NSMenu *sub = [[NSMenu alloc] initWithTitle:@""];
    [sub setAutoenablesItems:NO];
    mnuTelex = [sub addItemWithTitle:@"Telex" action:@selector(onInputTypeSelected:) keyEquivalent:@""];
    mnuTelex.tag = 0;
    mnuVNI = [sub addItemWithTitle:@"VNI" action:@selector(onInputTypeSelected:) keyEquivalent:@""];
    mnuVNI.tag = 1;
    mnuSimpleTelex1 = [sub addItemWithTitle:@"Simple Telex 1" action:@selector(onInputTypeSelected:) keyEquivalent:@""];
    mnuSimpleTelex1.tag = 2;
    mnuSimpleTelex2 = [sub addItemWithTitle:@"Simple Telex 2" action:@selector(onInputTypeSelected:) keyEquivalent:@""];
    mnuSimpleTelex2.tag = 3;
    [theMenu setSubmenu:sub forItem:parent];
}

- (void)setCodeMenu:(NSMenuItem*) parent {
    //sub for Code
    NSMenu *sub = [[NSMenu alloc] initWithTitle:@""];
    [sub setAutoenablesItems:NO];
    mnuUnicodeComposite = [sub addItemWithTitle:@"Unicode tổ hợp" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuUnicodeComposite.tag = 3;
    mnuVietnameseLocaleCP1258 = [sub addItemWithTitle:@"Vietnamese Locale CP 1258" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuVietnameseLocaleCP1258.tag = 4;
    
    [theMenu setSubmenu:sub forItem:parent];
}

- (void) fillData {
    //fill data
    NSInteger intInputMethod = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
    NSInteger grayIcon = [[NSUserDefaults standardUserDefaults] integerForKey:@"GrayIcon"];
    if (intInputMethod == 1) {
        [menuInputMethod setState:NSControlStateValueOn];
        statusItem.button.image = [NSImage imageNamed:@"Status"];
        [statusItem.button.image setTemplate:(grayIcon ? YES : NO)];
        statusItem.button.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
    } else {
        [menuInputMethod setState:NSControlStateValueOff];
        statusItem.button.image = [NSImage imageNamed:@"StatusEng"];
        [statusItem.button.image setTemplate:(grayIcon ? YES : NO)];
        statusItem.button.alternateImage = [NSImage imageNamed:@"StatusHighlightedEng"];
    }
    vLanguage = (int)intInputMethod;
    
    NSInteger intInputType = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputType"];
    [mnuTelex setState:NSControlStateValueOff];
    [mnuVNI setState:NSControlStateValueOff];
    [mnuSimpleTelex1 setState:NSControlStateValueOff];
    [mnuSimpleTelex2 setState:NSControlStateValueOff];
    if (intInputType == 0) {
        [mnuTelex setState:NSControlStateValueOn];
    } else if (intInputType == 1) {
        [mnuVNI setState:NSControlStateValueOn];
    } else if (intInputType == 2) {
        [mnuSimpleTelex1 setState:NSControlStateValueOn];
    } else if (intInputType == 3) {
        [mnuSimpleTelex2 setState:NSControlStateValueOn];
    }
    vInputType = (int)intInputType;
    
    NSInteger intSwitchKeyStatus = [[NSUserDefaults standardUserDefaults] integerForKey:@"SwitchKeyStatus"];
    vSwitchKeyStatus = (int)intSwitchKeyStatus;
    if (vSwitchKeyStatus == 0)
        vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
    
    NSInteger intCode = [[NSUserDefaults standardUserDefaults] integerForKey:@"CodeTable"];
    [mnuUnicode setState:NSControlStateValueOff];
    [mnuTCVN setState:NSControlStateValueOff];
    [mnuVNIWindows setState:NSControlStateValueOff];
    [mnuUnicodeComposite setState:NSControlStateValueOff];
    [mnuVietnameseLocaleCP1258 setState:NSControlStateValueOff];
    if (intCode == 0) {
        [mnuUnicode setState:NSControlStateValueOn];
    } else if (intCode == 1) {
        [mnuTCVN setState:NSControlStateValueOn];
    } else if (intCode == 2) {
        [mnuVNIWindows setState:NSControlStateValueOn];
    } else if (intCode == 3) {
        [mnuUnicodeComposite setState:NSControlStateValueOn];
    } else if (intCode == 4) {
        [mnuVietnameseLocaleCP1258 setState:NSControlStateValueOn];
    }
    vCodeTable = (int)intCode;
    
    //
    NSInteger intRunOnStartup = [[NSUserDefaults standardUserDefaults] integerForKey:@"RunOnStartup"];
    [self setRunOnStartup:intRunOnStartup ? YES : NO];

    NSNumber *moodValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"vMoodWatch"];
    vMoodWatch = moodValue == nil ? 1 : (int)[moodValue integerValue];
    [mnuMoodWatch setState:vMoodWatch ? NSControlStateValueOn : NSControlStateValueOff];

    extern int vBell;
    vBell = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"vBell"];
    [mnuBellToggle setState:vBell ? NSControlStateValueOn : NSControlStateValueOff];
}

-(void)onImputMethodChanged:(BOOL)willNotify {
    NSInteger intInputMethod = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
    if (intInputMethod == 0)
        intInputMethod = 1;
    else
        intInputMethod = 0;
    vLanguage = (int)intInputMethod;
    [[NSUserDefaults standardUserDefaults] setInteger:intInputMethod forKey:@"InputMethod"];

    [self fillData];
    [viewController fillData];
    
    if (willNotify) {
        OnInputMethodChanged();
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InputMethodChangedNotification" object:nil];
    }
}

#pragma mark -StatusBar menu action
- (void)onInputMethodSelected {
    [self onImputMethodChanged:YES];
}

- (void)onInputTypeSelected:(id)sender {
    NSMenuItem *menuItem = (NSMenuItem*) sender;
    [self onInputTypeSelectedIndex:(int)menuItem.tag];
}

- (void)onInputTypeSelectedIndex:(int)index {
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"InputType"];
    vInputType = index;
    [self fillData];
    [viewController fillData];
}

- (void)onCodeTableChanged:(int)index {
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CodeTable"];
    vCodeTable = index;
    [self fillData];
    [viewController fillData];
    OnTableCodeChange();
}

- (void)onCodeSelected:(id)sender {
    NSMenuItem *menuItem = (NSMenuItem*) sender;
    [self onCodeTableChanged:(int)menuItem.tag];
}

-(void)onConvertTool {
    if (_convertWC == nil) {
        _convertWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"ConvertWindow"];
    }
    //[OpenKeyManager showDockIcon:YES];
    if ([_convertWC.window isVisible])
        return;
    [_convertWC.window makeKeyAndOrderFront:nil];
    [_convertWC.window setLevel:NSFloatingWindowLevel];
}

-(void)onQuickConvert {
    if ([OpenKeyManager quickConvert]) {
        if (!convertToolDontAlertWhenCompleted) {
            [OpenKeyManager showMessage: nil message:@"Chuyển mã thành công!" subMsg:@"Kết quả đã được lưu trong clipboard."];
        }
    } else {
        [OpenKeyManager showMessage: nil message:@"Không có dữ liệu trong clipboard!" subMsg:@"Hãy sao chép một đoạn text để chuyển đổi!"];
    }
}

-(void)onMoodWatchSelected {
    MoodWatchMac_SetEnabled(MoodWatchMac_IsEnabled() ? 0 : 1);
    [self fillData];
}

-(void)onBellToggleSelected {
    extern int vBell;
    vBell = vBell ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:vBell forKey:@"vBell"];
    BellMac_ApplySettings();
    [self fillData];
    if (_panelPopover.isShown) {
        [_panelVC refreshAll];
    }
}

// [MINDFUL] Epic 3 Chặng 2 (F13) — trước đây gọi BellMac_ShowSettings() (NSAlert đời cũ, đã xoá):
// 2 UI cùng ghi UserDefaults "vBell*" nhưng khác hẳn nhau (không Độ nhạy/Âm thanh, không sàn 15
// phút cho nhịp tuỳ chỉnh). Giờ mở thẳng mục "Chuông" (index 1 = MKSettingsSectionBell, xem enum
// trong SettingsWindowController.mm) của cửa sổ Cài đặt — đúng 1 UI chuông duy nhất trong app.
-(void)onBellSettingsSelected {
    [self onSettingsSelected];
    [_settingsWC selectSectionAtIndex:1];
}

-(void)onSnoozeBellSelected {
    BellMac_Snooze(60);
}

-(void)onShowReflectionSelected {
    ReflectionScreenMac_Show();
}

-(void)onDeleteMoodLogSelected {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Xóa toàn bộ nhật ký cảm xúc?";
    alert.informativeText = @"Hành động này không thể hoàn tác. Toàn bộ dữ liệu đã ghi (điểm rủi ro, thời điểm, ứng dụng) trên máy này sẽ bị xóa vĩnh viễn.";
    [alert addButtonWithTitle:@"Xóa"];
    [alert addButtonWithTitle:@"Hủy"];
    alert.window.level = NSStatusWindowLevel;

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        MoodStoreMac_DeleteAll();
    }
}

#if DEBUG
-(void)onSeedFakeMoodDataSelected {
    MoodStoreMac_SeedFakeSamplesForTesting(30);
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Đã giả lập 30 ngày dữ liệu";
    alert.informativeText = @"Mở Cài đặt ▸ Hôm nay ▸ Tuần/Tháng để xem. Dữ liệu này có đánh dấu riêng — dùng \"Xóa dữ liệu giả lập\" khi xong, không ảnh hưởng dữ liệu thật.";
    [alert addButtonWithTitle:@"Đã hiểu"];
    alert.window.level = NSStatusWindowLevel;
    [alert runModal];
}

-(void)onDeleteSimulatedMoodDataSelected {
    if (!MoodStoreMac_HasSimulatedData()) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Không có dữ liệu giả lập nào để xóa";
        [alert addButtonWithTitle:@"Đã hiểu"];
        alert.window.level = NSStatusWindowLevel;
        [alert runModal];
        return;
    }
    MoodStoreMac_DeleteSimulatedData();
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Đã xóa dữ liệu giả lập";
    alert.informativeText = @"Dữ liệu thật (nếu có) vẫn còn nguyên.";
    [alert addButtonWithTitle:@"Đã hiểu"];
    alert.window.level = NSStatusWindowLevel;
    [alert runModal];
}
#endif

-(void) onControlPanelSelected {
    if (_mainWC == nil) {
        _mainWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"OpenKey"];
    }
    //[OpenKeyManager showDockIcon:YES];
    if ([_mainWC.window isVisible]) {
        return;
    }
    [_mainWC.window makeKeyAndOrderFront:nil];
    [_mainWC.window setLevel:NSFloatingWindowLevel];
}

// [MINDFUL] Story 2.2 — mở cửa sổ quản lý DUY NHẤT (nav trái 6 mục), thay 4 cửa sổ rời rạc cũ.
// Cùng pattern lazy-instantiate + visible-check-return như onControlPanelSelected/onMacroSelected/
// onAboutSelected bên dưới, cộng showWindow:/activateIgnoringOtherApps: để bảo đảm cửa sổ lên
// trước khi mở từ status item (app chạy accessory, không có Dock icon theo mặc định).
-(void) onSettingsSelected {
    if (_settingsWC == nil) {
        _settingsWC = [[SettingsWindowController alloc] init];
    }
    if ([_settingsWC.window isVisible]) {
        [NSApp activateIgnoringOtherApps:YES];
        return;
    }
    [_settingsWC showWindow:nil];
    [_settingsWC.window makeKeyAndOrderFront:nil];
    [_settingsWC.window setLevel:NSFloatingWindowLevel];
    [NSApp activateIgnoringOtherApps:YES];
}

-(void) onMacroSelected {
    if (_macroWC == nil) {
        _macroWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"MacroWindow"];
    }
    //[OpenKeyManager showDockIcon:YES];
    if ([_macroWC.window isVisible])
        return;
    
    [_macroWC.window makeKeyAndOrderFront:nil];
    [_macroWC.window setLevel:NSFloatingWindowLevel];
}

-(void) onAboutSelected {
    if (_aboutWC == nil) {
        _aboutWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"AboutWindow"];
    }
    //[OpenKeyManager showDockIcon:YES];
    if ([_aboutWC.window isVisible])
        return;

    [_aboutWC.window makeKeyAndOrderFront:nil];
    [_aboutWC.window setLevel:NSFloatingWindowLevel];
}

#pragma mark -Short key event
-(void)onSwitchLanguage {
    [self onInputMethodSelected];
    [viewController fillData];
}

#pragma mark Reset OpenKey after mac computer awake
-(void)receiveWakeNote: (NSNotification*)note {
    [OpenKeyManager initEventTap];
}

-(void)receiveSleepNote: (NSNotification*)note {
    [OpenKeyManager stopEventTap];
}

-(void)receiveActiveSpaceChanged: (NSNotification*)note {
    RequestNewSession();
}

-(void)activeAppChanged: (NSNotification*)note {
    if (vUseSmartSwitchKey && [OpenKeyManager isInited]) {
        OnActiveAppChanged();
    }
}

-(void)registerSupportedNotification {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveActiveSpaceChanged:)
                                                               name: NSWorkspaceActiveSpaceDidChangeNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(activeAppChanged:)
                                                               name: NSWorkspaceDidActivateApplicationNotification object: NULL];
}
@end
