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

#if DEBUG
// [MINDFUL] `showCheckinOverlay` là method PRIVATE của PanelViewController (không khai trong .h —
// nó là việc nội bộ của timer chấm nhịp, không phải API công khai). Forward-declare tại đây cho
// riêng mục [DEV], KHÔNG sửa PanelViewController.h — cùng idiom file SettingsWindowController.mm
// đã dùng cho `ConvertToolViewController -fillData`.
@interface PanelViewController (MKDebugCheckin)
- (void)showCheckinOverlay;
@end
#endif
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
    NSMenuItem* mnuGatekeeper;
    NSMenuItem* mnuShowCheckinOnRiver;
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

// ── [MINDFUL] Tự tắt bộ gõ xung đột (chủ dự án chốt 2026-07-17) ──
// TRƯỚC (cùng ngày): thấy OpenKey đang chạy thì hiện hộp thoại 2 nút hỏi người dùng. Chủ dự án
// chốt lại NGAY SAU đó: KHÔNG hỏi — "mở MindfulKey là tắt luôn OpenKey để không bị đụng, đảm bảo
// ổn định". Hai bộ gõ cùng bắt phím (CGEventTap) là gõ ra chữ đôi/loạn dấu, và người đã chủ động
// mở MindfulKey gần như chắc chắn muốn dùng MindfulKey. Đường chính giờ: tắt tự động + 1
// notification mô tả (không chặn, không hỏi); hộp thoại chỉ còn cho ca hiếm "tắt mãi không chết".

// Notification mô tả sau khi đã tắt xong — giọng quan sát, không phán xét (hiến chương §2.2).
// Best-effort CÓ CHỦ ĐÍCH: quyền notification được xin trong cùng lượt khởi động này, lần chạy
// đầu tiên có thể chưa kịp cấp → notification rơi im. Chấp nhận: icon menu bar xuất hiện + gõ
// tiếng Việt chạy được đã là tín hiệu "MindfulKey đang làm việc"; không dựng modal chỉ để nói.
- (void)notifyDidQuitConflictApp:(NSString *)appName {
    if (@available(macOS 10.14, *)) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"MindfulKey đang gõ thay bộ gõ khác";
        content.body = [NSString stringWithFormat:@"Đã tắt %@ để hai bộ gõ không tranh nhau bắt phím.", appName];
        UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"mindfulkey-conflict-takeover"
                                                                          content:content
                                                                          trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:nil];
    }
}

// Ca hiếm: cả forceTerminate (SIGKILL cùng UID — gần như luôn thắng) cũng không hạ được OpenKey.
// Chạy tiếp là gõ loạn, mà tự thoát câm là lặp đúng lỗi P0 hôm nay — nên nói thẳng rồi mới thoát.
// Hàm này chỉ được gọi qua dispatch_after SAU khi launch đã xong, nên cú terminate ở đây không
// còn dính bẫy "terminate giữa didFinishLaunching"; guard g_moodQueue trong MoodWatchMac_Flush()
// vẫn là lưới đỡ cuối.
- (void)showCannotQuitConflictAlertThenQuit:(NSString *)appName {
    // App là LSUIElement — phải nâng activationPolicy rồi mới activate, không thì alert bung
    // sau lưng app đang active và người dùng lại tưởng app hỏng (bài học P0 cùng ngày).
    NSApplicationActivationPolicy previousPolicy = [NSApp activationPolicy];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Không tắt được bộ gõ đang chạy";
    alert.informativeText = [NSString stringWithFormat:
        @"MindfulKey đã thử tắt “%@” để hai bộ gõ không tranh nhau bắt phím, nhưng chưa tắt được. "
        @"Bạn hãy tự thoát “%@” rồi mở lại MindfulKey nhé.", appName, appName];
    [alert addButtonWithTitle:@"Thoát MindfulKey"];
    alert.window.level = NSStatusWindowLevel;
    [alert runModal];
    [NSApp setActivationPolicy:previousPolicy];

    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp terminate:nil];
    });
}

// [MINDFUL] Allow-list bộ gõ tranh phím — báo cáo người dùng 2026-07-17 mục 5.1: không chỉ
// OpenKey, các bộ gõ Việt khác cũng bắt phím toàn cục qua event tap, chạy chung là giành nhau
// từng phím gõ. Bundle id ĐÃ XÁC MINH từ Homebrew cask chính thức (zap path), KHÔNG đoán:
//   OpenKey      [Legacy Bundle ID]         (gốc fork)
//                                            KHÔNG đưa vào: helper không bắt phím)
//   EVKey        com.lamquangminh.evkey     (helper com.lamquangminh.evkeyhelper: như trên)
//   GoTiengViet  com.trankynam.GoTiengViet
// UniKey không có bản macOS chính thức nên không có bundle id để bắt.
// So sánh sau khi hạ chữ thường (danh sách dưới lưu sẵn chữ thường): CFBundleIdentifier viết
// hoa/thường tùy từng bản đóng gói — lệch 1 ký tự là lọt lưới im lặng, không ai lần ra được.
static BOOL IsConflictingInputMethodBundleID(NSString *bundleID) {
    static NSSet<NSString *> *ids;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ids = [NSSet setWithArray:@[ OPENKEY_BUNDLE,
                                     @"com.lamquangminh.evkey",
                                     @"com.trankynam.gotiengviet" ]];
    });
    return bundleID != nil && [ids containsObject:bundleID.lowercaseString];
}

// Tắt danh sách bộ gõ xung đột theo bậc thang: terminate (lịch sự) → 1.5s sau forceTerminate đứa
// nào còn sống → 1.5s nữa vẫn sống thì nói thật rồi tự thoát. KHÔNG chặn luồng khởi động: mọi
// bước kiểm lại đều qua dispatch_after trên main queue. Block giữ mạnh (retain) từng
// NSRunningApplication nên .terminated luôn hỏi đúng đối tượng gốc — không dính chuyện PID tái dùng.
- (void)quitConflictingInputMethods:(NSArray<NSRunningApplication *> *)apps {
    if (apps.count == 0)
        return;
    // Có thể dính nhiều bộ gõ khác nhau cùng lúc (vd OpenKey + EVKey) — notification nêu đủ tên.
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSRunningApplication *app in apps) {
        NSString *name = app.localizedName;
        if (name && ![names containsObject:name])
            [names addObject:name];
    }
    NSString *displayName = names.count > 0 ? [names componentsJoinedByString:@", "] : @"bộ gõ kia";
    for (NSRunningApplication *app in apps) {
        [app terminate];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        BOOL allGone = YES;
        for (NSRunningApplication *app in apps) {
            if (!app.terminated) {
                [app forceTerminate];
                allGone = NO;
            }
        }
        if (allGone) {
            [self notifyDidQuitConflictApp:displayName];
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            for (NSRunningApplication *app in apps) {
                if (!app.terminated) {
                    [self showCannotQuitConflictAlertThenQuit:displayName];
                    return;
                }
            }
            [self notifyDidQuitConflictApp:displayName];
        });
    });
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    appDelegate = self;
    
    [self registerSupportedNotification];
    
    //set quick tooltip
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: 50]
                                              forKey: @"NSInitialToolTipDelay"];
    
    // [MINDFUL] Quét bộ gõ xung đột đang chạy. Khối này vốn là check single-instance của OpenKey
    // gốc ("check whether this app has been launched before") — sau khi fork đổi bundle id sang
    // vn.gnh.mindfulkey, phép so sánh hết khớp chính bản thân và hoá thành máy dò OpenKey xịn
    // (nguồn cơn lỗi P0 "tự thoát câm" của 0.2.1). Nay giữ đúng vai máy dò, mở rộng qua
    // allow-list IsConflictingInputMethodBundleID; còn chống-chạy-trùng cho CHÍNH MindfulKey
    // giao lại cho LSMultipleInstancesProhibited trong Info.plist (Launch Services tự chặn).
    //Only check instances owned by current user (for multi-user/Fast User Switching support)
    uid_t currentUID = getuid();
    NSArray<NSRunningApplication *>* runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    pid_t myPID = [[NSProcessInfo processInfo] processIdentifier];
    // [MINDFUL] Gom TẤT CẢ instance bộ gõ xung đột đang chạy (không dừng ở cái đầu tiên) — tắt
    // sót một con là hai bộ gõ vẫn đụng phím.
    NSMutableArray<NSRunningApplication *> *conflictApps = [NSMutableArray array];

    for (NSRunningApplication *app in runningApps) {
        if (IsConflictingInputMethodBundleID(app.bundleIdentifier) &&
            app.processIdentifier != myPID) {
            pid_t pid = app.processIdentifier;
            struct proc_bsdinfo proc;
            int size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &proc, sizeof(proc));
            if (size == sizeof(proc) && proc.pbi_uid == currentUID) {
                [conflictApps addObject:app];
            }
        }
    }

    // [MINDFUL] Chủ dự án chốt 2026-07-17 (ghi đè hộp thoại 2 nút cùng ngày — xem FRICTION-LOG):
    // thấy OpenKey là TỰ TẮT rồi chạy tiếp, không hỏi. Không modal, không return — toàn bộ phần
    // còn lại của launch (menu khay, MoodWatchMac_Init...) chạy bình thường ngay lập tức; cú
    // terminate giữa-launch từng gây SIGSEGV (lỗi P0) không còn tồn tại trên đường này.
    [self quitConflictingInputMethods:conflictApps];

    // [MINDFUL] Bộ gõ xung đột mở SAU khi MindfulKey đã chạy (điển hình: OpenKey nằm trong Login Items,
    // khởi động máy xong nó tự bật lại — đúng cảnh báo ⚠️ trong báo cáo người dùng 2026-07-17) →
    // cùng một luật với lúc khởi động: tự tắt + notification. Observer sống suốt đời app, cố ý
    // không removeObserver. Notification của NSWorkspace chỉ báo app trong CHÍNH phiên đăng nhập
    // này nên không cần lặp lại màn kiểm UID của vòng quét trên. Đây là suy diễn từ mandate "đảm
    // bảo ổn định" — chủ dự án xác nhận ở FRICTION-LOG.
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserverForName:NSWorkspaceDidLaunchApplicationNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
        NSRunningApplication *launched = note.userInfo[NSWorkspaceApplicationKey];
        if (launched && IsConflictingInputMethodBundleID(launched.bundleIdentifier)) {
            [appDelegate quitConflictingInputMethods:@[launched]];
        }
    }];

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
        // [MINDFUL] 2026-07-16 — 3 đường fallback này từng mở cửa sổ storyboard CŨ (identifier
        // "OpenKey", class ViewController) — off-brand hoàn toàn so với cửa sổ quản lý mới, và
        // nút "Kết thúc" của nó gọi thẳng onTerminateApp: ([NSApp terminate:0]) chứ không phải
        // đóng riêng cửa sổ đó, nên bấm nhầm là tắt LUÔN CẢ APP. Đổi sang mở cửa sổ quản lý mới
        // (onSettingsSelected) — vẫn giữ đúng ý định "có gì đó hiện lên nếu event tap lỗi", chỉ
        // đổi ĐÚNG cửa sổ mà Story 2.2 đã chốt là bản chính.
        if (![OpenKeyManager initEventTap]) {
            [self onSettingsSelected];
        } else {
            NSInteger showui = [[NSUserDefaults standardUserDefaults] integerForKey:@"ShowUIOnStartup"];
            if (showui == 1) {
                [self onSettingsSelected];
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
    [self onSettingsSelected];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    MoodWatchMac_Flush();
}

// [MINDFUL] Báo cáo 0.2.1 mục 6.6 — người dùng gặp lỗi phải có đường báo ngay trong app,
// không phải tự mò ra GitHub. Chỉ mở trình duyệt; bản thân app không tự gọi mạng.
- (void)onReportIssueSelected {
    [[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"https://github.com/theminh207/mindful-key/issues"]];
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
    // [MINDFUL] 2026-07-19 — công tắc gác cổng gửi tin (Feature #1). Dấu tích = đang canh Enter
    // trong app chat. Tắt vẫn giữ nhật ký/sông (do "Nhắc tâm" quản), chỉ ngừng chặn-mềm lúc gửi.
    mnuGatekeeper = [theMenu addItemWithTitle:@"Gác cổng gửi tin (nhịp thở)" action:@selector(onGatekeeperToggleSelected) keyEquivalent:@""];
    // [MINDFUL] 2026-07-20 — công tắc gộp chấm tự-thuật (check-in) vào sông. Dấu tích = sông vẽ cả
    // câu trả lời "Mặt hồ đang thế nào?" (vòng rỗng) lẫn chữ gõ (chấm đặc). Tắt = về đúng hành vi
    // cũ, chỉ vẽ từ chữ gõ — cho ai thấy trộn 2 nguồn là rối mắt.
    mnuShowCheckinOnRiver = [theMenu addItemWithTitle:@"Hiện chấm tự đánh giá trên sông" action:@selector(onShowCheckinOnRiverToggleSelected) keyEquivalent:@""];
    mnuBellToggle = [theMenu addItemWithTitle:@"Bật chuông tỉnh thức" action:@selector(onBellToggleSelected) keyEquivalent:@""];
    mnuBellSettings = [theMenu addItemWithTitle:@"Cài đặt Chuông tỉnh thức..." action:@selector(onBellSettingsSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Tạm hoãn chuông 1 giờ" action:@selector(onSnoozeBellSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Soi lại hôm nay..." action:@selector(onShowReflectionSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Xóa nhật ký cảm xúc..." action:@selector(onDeleteMoodLogSelected) keyEquivalent:@""];

    // [MINDFUL] H2 (2026-07-24) — submenu "Thử nghiệm" PHƠI cả Release (trước cả nhóm ở #if DEBUG):
    // bơm dữ liệu mẫu để test biểu đồ Ngày/Tuần/Tháng trên bản đã cài. Đánh dấu riêng, "Xóa dữ liệu
    // mẫu" dọn sạch. Nhãn khớp Windows F6. ⚠️ FRICTION-LOG: ẩn/bỏ trước bản công khai 1.0.
    [theMenu addItem:[NSMenuItem separatorItem]];
    NSMenu *seedMenu = [[NSMenu alloc] initWithTitle:@"Thử nghiệm"];
    NSMenuItem *sd12 = [seedMenu addItemWithTitle:@"Tạo dữ liệu mẫu · 12 giờ" action:@selector(onSeedDenseDaySelected) keyEquivalent:@""];
    NSMenuItem *sd7  = [seedMenu addItemWithTitle:@"Tạo dữ liệu mẫu · 1 tuần" action:@selector(onSeedWeekMoodDataSelected) keyEquivalent:@""];
    NSMenuItem *sd30 = [seedMenu addItemWithTitle:@"Tạo dữ liệu mẫu · 30 ngày" action:@selector(onSeedFakeMoodDataSelected) keyEquivalent:@""];
    [seedMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *sdClear = [seedMenu addItemWithTitle:@"Xóa dữ liệu mẫu" action:@selector(onDeleteSimulatedMoodDataSelected) keyEquivalent:@""];
    for (NSMenuItem *it in @[sd12, sd7, sd30, sdClear]) it.target = self;  // submenu -> đặt target rõ
    NSMenuItem *seedItem = [[NSMenuItem alloc] initWithTitle:@"Thử nghiệm" action:nil keyEquivalent:@""];
    [seedItem setSubmenu:seedMenu];
    [theMenu addItem:seedItem];
#if DEBUG
    // Khung chấm nhịp — vẫn Debug-only (khác nhóm seed; công cụ verify nội bộ, không cho end-user).
    [theMenu addItemWithTitle:@"[DEV] Hiện khung chấm nhịp ngay" action:@selector(onShowCheckinNowSelected) keyEquivalent:@""];
#endif

    [theMenu addItem:[NSMenuItem separatorItem]];
    
    // [MINDFUL] Story 2.2 — "Bảng điều khiển…"/"Gõ tắt…"/"Giới thiệu" gộp vào cửa sổ quản lý mới
    // (SettingsWindowController, nav trái 6 mục). onMacroSelected/onAboutSelected/onControlPanelSelected
    // KHÔNG bị xoá — vẫn được gọi từ nút "Bảng gõ tắt..." trong tabviewMacro + 3 đường fallback khởi động.
    [theMenu addItemWithTitle:@"Cài đặt…" action:@selector(onSettingsSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Báo lỗi / Góp ý…" action:@selector(onReportIssueSelected) keyEquivalent:@""];
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
    [_panelVC refreshAll]; // view đã load → cập nhật trạng thái mới nhất và tính toán kích thước
    [_panelPopover showRelativeToRect:statusItem.button.bounds
                               ofView:statusItem.button
                        preferredEdge:NSMinYEdge];

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
    // [MINDFUL] Batch "Hệ thống + Chuông" — SMAppService.mainAppService (tên ObjC thật; header khai
    // `NS_SWIFT_NAME(mainApp)` — đó là tên BÊN SWIFT, không phải selector ObjC, xác nhận bằng cách
    // đọc thẳng SMAppService.h trong SDK) — cùng framework ServiceManagement đã import ở đầu file —
    // KHÔNG cần Helper bundle riêng: chính app tự đăng ký làm login item.
    // [MINDFUL] 2026-07-18 — sàn nâng lên 13.0 (project.yml) nên bỏ @available + gỡ nhánh dự phòng
    // SMLoginItemSetEnabled cũ: nhánh đó dựa Helper cũ không tồn tại trong
    // project (chưa bao giờ thật sự bật được login item máy cũ), thành code chết cứng ở sàn 13.0 và
    // SMLoginItemSetEnabled deprecated đúng từ 13.0 (warning mới). Hạ sàn lại thì phải dựng Helper
    // thật, không khôi phục nhánh cũ.
    if (val) {
        [[SMAppService mainAppService] registerAndReturnError:nil];
    } else {
        [[SMAppService mainAppService] unregisterAndReturnError:nil];
    }
    // [MINDFUL] 2026-07-18 (review) — đồng bộ key "RunOnStartup": cửa sổ Cài đặt mới chỉ gọi hàm
    // này mà KHÔNG ghi key, trong khi khối "correct run on startup" lúc khởi động + fillData vẫn
    // đọc key (bị loadDefaultConfig seed = 1 từ lần chạy đầu) rồi gọi lại hàm này → người dùng
    // TẮT login item xong bị app lật lại BẬT ngược ý (lỗi có sẵn trước đợt này, lộ ra khi review).
    // Ghi key tại đây = một nguồn sự thật duy nhất đi qua hàm này. Câu hỏi "seed = 1 lần chạy đầu
    // (tự bật không hỏi)" vẫn treo — FRICTION-LOG 2026-07-18.
    [[NSUserDefaults standardUserDefaults] setInteger:(val ? 1 : 0) forKey:@"RunOnStartup"];
}

-(BOOL)isRunOnStartup {
    return [SMAppService mainAppService].status == SMAppServiceStatusEnabled;
}

-(void)setGrayIcon:(BOOL)val {
    [self fillData];
}

-(void)showIconOnDock:(BOOL)val {
    [NSApp setActivationPolicy: val ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory];
}

-(BOOL)isStatusItemVisible {
    return statusItem.visible;
}

-(void)setStatusItemVisible:(BOOL)val {
    statusItem.visible = val;
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

    // [MINDFUL] 2026-07-19 — nạp công tắc gác cổng gửi tin. Mặc định BẬT (nil = chưa từng đặt).
    extern int vSendGatekeeper;
    NSNumber *gkValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"vSendGatekeeper"];
    vSendGatekeeper = gkValue == nil ? 1 : (int)[gkValue integerValue];
    [mnuGatekeeper setState:vSendGatekeeper ? NSControlStateValueOn : NSControlStateValueOff];

    // [MINDFUL] 2026-07-20 — nạp công tắc gộp chấm tự-thuật vào sông. Mặc định BẬT.
    NSNumber *ckValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"vShowCheckinOnRiver"];
    vShowCheckinOnRiver = ckValue == nil ? 1 : (int)[ckValue integerValue];
    [mnuShowCheckinOnRiver setState:vShowCheckinOnRiver ? NSControlStateValueOn : NSControlStateValueOff];

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

// [MINDFUL] 2026-07-19 — bật/tắt gác cổng gửi tin (Feature #1). Cùng mạch với onBellToggleSelected:
// lật cờ + lưu defaults + fillData (đồng bộ dấu tích menu) + refresh popover (caption thẻ đổi
// "đang canh"/"tạm nghỉ"). KHÔNG đụng vMoodWatch — nhật ký/sông độc lập với việc chặn Enter.
-(void)onGatekeeperToggleSelected {
    extern int vSendGatekeeper;
    vSendGatekeeper = vSendGatekeeper ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:vSendGatekeeper forKey:@"vSendGatekeeper"];
    [self fillData];
    if (_panelPopover.isShown) {
        [_panelVC refreshAll];
    }
}

// [MINDFUL] 2026-07-20 — bật/tắt gộp chấm tự-thuật (check-in) vào sông. Cùng mạch các toggle
// khác: lật cờ + lưu defaults + fillData + refresh popover (sông đổi ngay, không cần mở lại app).
-(void)onShowCheckinOnRiverToggleSelected {
    vShowCheckinOnRiver = vShowCheckinOnRiver ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:vShowCheckinOnRiver forKey:@"vShowCheckinOnRiver"];
    [self fillData];
    if (_panelPopover.isShown) {
        [_panelVC refreshAll];
    }
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
-(void)onShowCheckinNowSelected {
    [_panelVC showCheckinOverlay];
}
#endif

// [MINDFUL] H2 (2026-07-24) — seed handlers PHƠI cả bản Release (trước ở #if DEBUG). ⚠️ FRICTION-LOG:
// ẩn/bỏ trước bản công khai 1.0 (end-user không nên bơm được dữ liệu giả vào nhật ký).
-(void)onSeedFakeMoodDataSelected {
    MoodStoreMac_SeedFakeSamplesForTesting(30);
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Đã tạo dữ liệu mẫu 30 ngày";
    alert.informativeText = @"Mở Cài đặt ▸ Hôm nay ▸ Tuần/Tháng để xem. Dữ liệu này có đánh dấu riêng — dùng \"Xóa dữ liệu mẫu\" khi xong, không ảnh hưởng dữ liệu thật.";
    [alert addButtonWithTitle:@"Đã hiểu"];
    alert.window.level = NSStatusWindowLevel;
    [alert runModal];
}

-(void)onSeedWeekMoodDataSelected {
    MoodStoreMac_SeedFakeSamplesForTesting(7);
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Đã tạo dữ liệu mẫu 1 tuần";
    alert.informativeText = @"Mở Cài đặt ▸ Hôm nay ▸ Tuần để xem biểu đồ 7 ngày. Dữ liệu có đánh dấu riêng — dùng \"Xóa dữ liệu mẫu\" khi xong.";
    [alert addButtonWithTitle:@"Đã hiểu"];
    alert.window.level = NSStatusWindowLevel;
    [alert runModal];
}

-(void)onSeedDenseDaySelected {
    // Seeder cần đã đồng ý ghi nhật ký (kho mã hoá mới mở được). Nói thẳng nếu chưa, thay vì im lặng.
    if (!MoodStoreMac_HasConsent()) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Chưa bật nhật ký cảm xúc";
        alert.informativeText = @"Bật \"Nhắc tâm (cảm xúc)\" và đồng ý ghi nhật ký trước, rồi giả lập lại. Kho được mã hoá nên cần đồng ý mới ghi được.";
        [alert addButtonWithTitle:@"Đã hiểu"];
        alert.window.level = NSStatusWindowLevel;
        [alert runModal];
        return;
    }
    MoodStoreMac_SeedDenseDayForTesting();
    if (_panelPopover.isShown) {
        [_panelVC refreshAll];
    }
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Đã giả lập 1 ngày dày (12-18 tiếng)";
    alert.informativeText = @"Bấm icon khay mở bảng \"Ngay bây giờ\" để xem sông 3 tiếng gần nhất (chấm dày ~8 phút/mẫu). Gõ thử vài chữ để thấy đầu sóng \"bây giờ\" hiện lên rồi phai dần khi ngừng. Xong thì dùng \"Xóa dữ liệu giả lập\" — dữ liệu thật không bị đụng.";
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
    alert.messageText = @"Đã xóa dữ liệu mẫu";
    alert.informativeText = @"Dữ liệu thật (nếu có) vẫn còn nguyên.";
    [alert addButtonWithTitle:@"Đã hiểu"];
    alert.window.level = NSStatusWindowLevel;
    [alert runModal];
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
