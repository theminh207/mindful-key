//
//  SendGatekeeperMac.mm
//  ModernKey
//
//  [MINDFUL] Xem SendGatekeeperMac.h + docs/BREATHING-PAUSE-CONTRACT.md.
//

#import "SendGatekeeperMac.h"
#import <Carbon/Carbon.h>
#include "MoodWatchMac.h"
#include "BreathingPause.h"
#import "MoodStoreMac.h"
#import "BrandColors.h"

// [MINDFUL] Nguồn sự kiện riêng của OpenKey (khai báo trong OpenKey.mm, extern "C" file-scope).
// Dùng để gắn cho phím Enter TỰ TẠO khi người dùng chọn "Vẫn gửi" — nhờ vậy check đầu tiên
// của OpenKeyCallback ("đừng xử lý sự kiện tự mình tạo ra") sẽ bỏ qua nó, tránh vòng lặp
// gatekeeper tự chặn chính phím Enter mà nó vừa tạo ra.
extern "C" {
    extern CGEventSourceRef myEventSource;
}

// [MINDFUL] 2026-07-19 — công tắc gác cổng gửi tin (xem SendGatekeeperMac.h). Mặc định BẬT.
int vSendGatekeeper = 1;

// Allow-list app chat — CHỈ liệt kê app đã cài & xác minh bundle id THẬT trên máy dev
// (qua `defaults read <app>/Contents/Info.plist CFBundleIdentifier`). Đừng thêm bundle id
// đoán theo trí nhớ — rủi ro #3 trong roadmap đã lường trước việc phát hiện "sắp gửi" dễ vỡ
// giữa nhiều app; mở rộng list này CHỈ sau khi xác minh thật trên máy có cài app đó.
static NSArray<NSString *> *AllowedChatBundleIDs(void) {
    return @[
        @"com.vng.zalo",     // Zalo — đã xác minh trên máy dev, đúng mục tiêu sản phẩm
        @"com.hnc.Discord",  // Discord — đã xác minh trên máy dev, dùng để test (ngoài mục tiêu gốc)
        // Mục tiêu sản phẩm còn thiếu Messenger/Telegram — CHƯA cài trên máy dev để xác minh
        // bundle id thật, KHÔNG đoán. Thêm dòng tương ứng khi cài app thật và `defaults read`
        // ra đúng CFBundleIdentifier.
    ];
}

static BOOL IsFrontmostAppAllowed(void) {
    NSString *bundleID = [[NSWorkspace sharedWorkspace] frontmostApplication].bundleIdentifier;
    if (!bundleID)
        return NO;
    return [AllowedChatBundleIDs() containsObject:bundleID];
}

BOOL SendGatekeeperMac_ShouldIntercept(CGEventRef event, CGEventType type) {
    if (!vSendGatekeeper)   // gác cổng tắt — để Enter đi thẳng, không chặn-mềm
        return NO;

    if (type != kCGEventKeyDown)
        return NO;

    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    if (keycode != kVK_Return)
        return NO;

    CGEventFlags flags = CGEventGetFlags(event);
    if (flags & kCGEventFlagMaskShift) // Shift+Enter = xuống dòng trong hầu hết app chat, không phải gửi
        return NO;

    if (!IsFrontmostAppAllowed())
        return NO;

    return MoodWatchMac_LastSendRisk() >= kBreathingPauseRiskThreshold;
}

// ── Overlay nhịp thở (NSPanel nổi, không chiếm focus) ──

@interface MindfulPauseButtonTarget : NSObject
@property (nonatomic, assign) BreathingPauseChoice choice;
- (void)clicked:(id)sender;
@end

static NSPanel *g_pausePanel = nil;
static MindfulPauseButtonTarget *g_sendTarget = nil;
static MindfulPauseButtonTarget *g_waitTarget = nil;
static NSString *g_pauseAppBundleID = nil; // chụp lại lúc hiện panel, dùng khi ghi log
static double g_pauseSendRisk = 0.0;

static NSString *ChoiceLabel(BreathingPauseChoice choice) {
    switch (choice) {
        case BreathingPauseChoice::SendAnyway: return @"send_anyway";
        case BreathingPauseChoice::Wait:       return @"wait";
        default:                               return @"dismissed";
    }
}

static void ClosePausePanel(BreathingPauseChoice choice) {
    if (!g_pausePanel)
        return;

    [g_pausePanel orderOut:nil];
    g_pausePanel = nil;
    BreathingPause_ReportChoice(choice);
    // [MINDFUL] Bước 6: ghi lại (nếu đã đồng ý) — CHỈ điểm risk + app + lựa chọn, không câu chữ.
    MoodStoreMac_LogGatekeeperEvent(g_pauseSendRisk, g_pauseAppBundleID, ChoiceLabel(choice));

    if (choice == BreathingPauseChoice::SendAnyway) {
        // Gửi lại 1 phím Enter THẬT — gắn myEventSource để OpenKeyCallback bỏ qua nó (không
        // xử lý lại lần 2, không tự chặn chính phím Enter mà gatekeeper vừa tạo ra).
        CGEventRef down = CGEventCreateKeyboardEvent(myEventSource, kVK_Return, true);
        CGEventRef up   = CGEventCreateKeyboardEvent(myEventSource, kVK_Return, false);
        CGEventPost(kCGSessionEventTap, down);
        CGEventPost(kCGSessionEventTap, up);
        CFRelease(down);
        CFRelease(up);
    }
    // Wait hoặc Dismissed -> không làm gì thêm. Tin nhắn vẫn CHƯA gửi; người dùng tự quyết
    // định bước tiếp theo (sửa câu, hoặc bấm Enter lại — sẽ qua lại đúng gatekeeper này).
}

@implementation MindfulPauseButtonTarget
- (void)clicked:(id)sender {
    ClosePausePanel(self.choice);
}
@end

void SendGatekeeperMac_ShowPause(void) {
    if (g_pausePanel)
        return; // đã có overlay đang hiện, không chồng thêm

    BreathingPausePrompt prompt;
    double risk = MoodWatchMac_LastSendRisk();
    if (!BreathingPause_Evaluate(risk, &prompt))
        return;

    // Chụp lại lúc hiện panel — dùng khi ghi log ở ClosePausePanel (vài giây sau).
    g_pauseSendRisk = risk;
    g_pauseAppBundleID = [[NSWorkspace sharedWorkspace] frontmostApplication].bundleIdentifier;

    NSString *message = [[NSString alloc] initWithBytes:prompt.message.data()
                                                  length:prompt.message.size() * sizeof(wchar_t)
                                                encoding:NSUTF32LittleEndianStringEncoding];

    NSRect frame = NSMakeRect(0, 0, 380, 150);
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:frame
                                                 styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskNonactivatingPanel)
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    panel.title = @"Mindful Keyboard";
    panel.level = NSFloatingWindowLevel;
    panel.releasedWhenClosed = NO;
    panel.hidesOnDeactivate = NO;
    panel.becomesKeyOnlyIfNeeded = YES; // không cướp focus khỏi app chat đang gõ

    // [MINDFUL] Màu NOW BRAND OS (docs/BRAND-ASSETS.md): nền cam nhạt = "khoảnh khắc con
    // người" của lớp nhịp thở (KHÔNG dùng cam để mã hóa trạng thái cảm xúc — chỉ dùng ở đây
    // như brand chrome, đúng ngoại lệ đã ghi trong BRAND-ASSETS.md).
    panel.contentView.wantsLayer = YES;
    panel.contentView.layer.backgroundColor = [Brand orangeLight].CGColor;

    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 55, 340, 75)];
    label.stringValue = message;
    label.editable = NO;
    label.bordered = NO;
    label.drawsBackground = NO;
    label.textColor = [Brand charcoal];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [[label cell] setWraps:YES];
    [panel.contentView addSubview:label];

    g_sendTarget = [[MindfulPauseButtonTarget alloc] init];
    g_sendTarget.choice = BreathingPauseChoice::SendAnyway;
    g_waitTarget = [[MindfulPauseButtonTarget alloc] init];
    g_waitTarget.choice = BreathingPauseChoice::Wait;

    // "Đợi chút" tô đậm bằng cam NOW — nhẹ nhàng gợi ý lựa chọn dừng lại, không ẩn/khoá nút
    // "Vẫn gửi" (quyền quyết định luôn thuộc người dùng, xem docs/PRD.md).
    NSButton *waitBtn = [[NSButton alloc] initWithFrame:NSMakeRect(20, 15, 160, 32)];
    waitBtn.title = @"Đợi chút";
    waitBtn.bezelStyle = NSBezelStyleRounded;
    waitBtn.bezelColor = [Brand orange];
    waitBtn.target = g_waitTarget;
    waitBtn.action = @selector(clicked:);
    [panel.contentView addSubview:waitBtn];

    NSButton *sendBtn = [[NSButton alloc] initWithFrame:NSMakeRect(200, 15, 160, 32)];
    sendBtn.title = @"Vẫn gửi";
    sendBtn.bezelStyle = NSBezelStyleRounded;
    sendBtn.target = g_sendTarget;
    sendBtn.action = @selector(clicked:);
    [panel.contentView addSubview:sendBtn];

    NSRect screenFrame = [NSScreen mainScreen].frame;
    NSPoint origin = NSMakePoint(NSMidX(screenFrame) - frame.size.width / 2,
                                  NSMidY(screenFrame) - frame.size.height / 2);
    [panel setFrameOrigin:origin];
    [panel orderFrontRegardless];

    g_pausePanel = panel;

    double duration = prompt.durationSeconds > 0 ? prompt.durationSeconds : 3.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (g_pausePanel == panel) {
            ClosePausePanel(BreathingPauseChoice::Dismissed);
        }
    });
}
