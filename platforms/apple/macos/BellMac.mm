//
//  BellMac.mm
//  ModernKey
//
//  [MINDFUL] macOS mindfulness bell.
//

#import <Cocoa/Cocoa.h>
#include "BellMac.h"
#include "NudgeCoordinatorMac.h"
#import "BrandColors.h"

int vBell = 0;
int vBellInterval = 60;
int vBellFrom = 8;
int vBellTo = 22;

// [MINDFUL] Áo mới v2 — xem BellMac.h cho hợp đồng.
NSString * const kBellSoundMuteName = @"__silent__";

static NSTimer *g_bellTimer = nil;
static NSTimeInterval g_snoozeUntil = 0; // [MINDFUL] "dễ tắt tạm" — bước 7

static NSString *PROMPTS[] = {
    @"Dừng lại 10 giây. Hít vào thật sâu, thở ra thật chậm. Ngay lúc này, bạn đang thấy thế nào?",
    @"Một nhịp nghỉ cho riêng mình. Thả lỏng vai, buông căng thẳng xuống.",
    @"Khoan đã, kéo mắt rời màn hình một chút. Nhìn ra xa và chớp mắt vài cái.",
    @"Tỉnh thức. Bạn đang ngồi đây, đang thở, đang sống.",
    @"Nghỉ tay một lát. Uống một ngụm nước, vươn vai rồi quay lại.",
};
static const int PROMPT_COUNT = sizeof(PROMPTS) / sizeof(PROMPTS[0]);

// [MINDFUL] Bước 7 — câu riêng cho lúc rung vì phát hiện CHUỖI câu căng thẳng (khác câu rung
// theo lịch cố định ở trên): nói thẳng lý do rung, không giả vờ đây là chuông định kỳ.
static NSString *PROMPTS_TENSE_STREAK[] = {
    @"Nãy giờ có vẻ căng. Một hơi thở chứ? Không cần vội trả lời ai cả.",
    @"Vài câu gõ gần đây nghe hơi nặng. Dừng một nhịp, để đầu óc dịu lại đã.",
    @"Có vẻ bạn đang dồn nén. Rời bàn phím 1 phút, quay lại sẽ rõ ràng hơn.",
};
static const int PROMPTS_TENSE_STREAK_COUNT = sizeof(PROMPTS_TENSE_STREAK) / sizeof(PROMPTS_TENSE_STREAK[0]);

static BOOL isInBellRange(NSInteger hour) {
    if (vBellFrom <= vBellTo)
        return hour >= vBellFrom && hour < vBellTo;
    return hour >= vBellFrom || hour < vBellTo;
}

// [MINDFUL] Story 1.5 — phát âm chuông người dùng CHỌN, ở ÂM LƯỢNG người dùng chọn.
// Đọc tươi từ UserDefaults mỗi lần reo → đổi cài đặt áp dụng ngay, không cần khởi động lại.
// NSUserNotification.soundName KHÔNG chỉnh được âm lượng → tách phần phát âm sang NSSound (Dev Notes #1).
static void playBellSound(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSString *name = [d stringForKey:@"vBellSoundName"];
    if (name.length == 0) name = @"Glass";           // mặc định = "Tiếng chuông"
    if ([name isEqualToString:kBellSoundMuteName]) return;   // "Im" — không phát gì, có chủ đích.
    float vol = [d objectForKey:@"vBellVolume"] ? (float)[d doubleForKey:@"vBellVolume"] : 0.6f;
    if (vol < 0) vol = 0;
    if (vol > 1) vol = 1;                            // user kéo về 0 = im lặng (có chủ đích)

    NSSound *sound = [NSSound soundNamed:name] ?: [NSSound soundNamed:@"Glass"];
    if (sound) {
        if (sound.isPlaying) [sound stop];           // cho phép reo lại liên tiếp
        sound.volume = vol;
        [sound play];
    } else {
        NSBeep();                                    // dự phòng nếu không tìm được âm hệ thống
    }
}

static void showBellPrompt(NSString *message) {
    playBellSound();   // thay NSBeep + soundName mặc định: dùng âm + âm lượng đã chọn
    if ([NSUserNotificationCenter class]) {
        NSUserNotification *note = [[NSUserNotification alloc] init];
        note.title = @"Chuông tỉnh thức - Mindful";
        note.informativeText = message;
        note.soundName = nil;   // đã tự phát âm (có âm lượng) ở trên → tránh phát trùng âm mặc định
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Chuông tỉnh thức - Mindful";
    alert.informativeText = message;
    [alert addButtonWithTitle:@"OK"];
    [alert.window setLevel:NSStatusWindowLevel];
    [alert runModal];
}

static BOOL isSnoozed(void) {
    return g_snoozeUntil > 0 && [NSDate timeIntervalSinceReferenceDate] < g_snoozeUntil;
}

static void bellTick(NSTimer *timer) {
    if (!vBell || isSnoozed())
        return;

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour
                                                                    fromDate:[NSDate date]];
    if (!isInBellRange(components.hour))
        return;

    // [MINDFUL] Gộp vào 1 mạch nhắc chung với nhắc thụ động — nếu vừa có 1 lời nhắc khác
    // (thụ động) hiện lên gần đây, bỏ qua lượt rung này để không dồn dập.
    if (!NudgeCoordinatorMac_ShouldNudge())
        return;

    static NSInteger idx = 0;
    idx++;
    showBellPrompt(PROMPTS[idx % PROMPT_COUNT]);
    NudgeCoordinatorMac_MarkNudged();
}

void BellMac_RingForTenseStreak(void) {
    if (!vBell || isSnoozed())
        return;
    if (!NudgeCoordinatorMac_ShouldNudge())
        return;

    static NSInteger idx = 0;
    idx++;
    showBellPrompt(PROMPTS_TENSE_STREAK[idx % PROMPTS_TENSE_STREAK_COUNT]);
    NudgeCoordinatorMac_MarkNudged();
}

void BellMac_Snooze(int minutes) {
    if (minutes < 0) minutes = 0;
    g_snoozeUntil = [NSDate timeIntervalSinceReferenceDate] + (minutes * 60.0);
}

// [MINDFUL] Story 1.5 — nghe thử ngay âm/âm lượng đang chọn (bỏ qua snooze/giờ yên lặng/cooldown:
// đây là hành động chủ động của người dùng, không phải chuông tự reo).
void BellMac_PreviewSound(void) {
    playBellSound();
}

// [MINDFUL] Áo mới v2 — xem BellMac.h cho hợp đồng. Đọc fireDate CỦA CHÍNH g_bellTimer đang chạy
// (không tự tính lại theo interval — timer là nguồn sự thật duy nhất về "khi nào tick kế tiếp").
int BellMac_MinutesUntilNextRing(void) {
    if (!vBell || isSnoozed() || g_bellTimer == nil)
        return -1;
    NSTimeInterval secs = [g_bellTimer.fireDate timeIntervalSinceNow];
    if (secs < 0) secs = 0;
    return (int)((secs + 59.0) / 60.0);   // làm tròn LÊN phút (còn <1 phút vẫn hiện "1 phút", không hiện "0")
}

void BellMac_ApplySettings() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_bellTimer != nil) {
            [g_bellTimer invalidate];
            g_bellTimer = nil;
        }

        if (!vBell)
            return;

        int minutes = vBellInterval;
        if (minutes < 1) minutes = 1;
        if (minutes > 240) minutes = 240;
        g_bellTimer = [NSTimer timerWithTimeInterval:(NSTimeInterval)minutes * 60.0
                                             repeats:YES
                                               block:^(NSTimer *timer) {
            bellTick(timer);
        }];
        [[NSRunLoop mainRunLoop] addTimer:g_bellTimer forMode:NSRunLoopCommonModes];
    });
}

void BellMac_Init() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    vBell = (int)[defaults integerForKey:@"vBell"];
    vBellInterval = (int)[defaults integerForKey:@"vBellInterval"];
    vBellFrom = (int)[defaults integerForKey:@"vBellFrom"];
    vBellTo = (int)[defaults integerForKey:@"vBellTo"];

    if (vBellInterval <= 0) vBellInterval = 60;
    if (vBellFrom < 0 || vBellFrom > 23) vBellFrom = 8;
    if (vBellTo < 0 || vBellTo > 23) vBellTo = 22;

    BellMac_ApplySettings();
}

static NSTextField *label(NSString *text, NSRect frame) {
    NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
    field.stringValue = text;
    field.editable = NO;
    field.bezeled = NO;
    field.drawsBackground = NO;
    field.textColor = [Brand charcoal]; // [MINDFUL] NOW BRAND OS — chữ chính trong accessoryView tự vẽ
    return field;
}

void BellMac_ShowSettings() {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Chuông tỉnh thức";
        alert.informativeText = @"Chọn lịch nhắc nghỉ và hít thở. Tất cả cài đặt nằm local trên máy.";
        [alert addButtonWithTitle:@"Lưu"];
        [alert addButtonWithTitle:@"Hủy"];

        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 118)];
        view.wantsLayer = YES;
        // [MINDFUL] Teal nhạt = brand chrome cho màn chuông tỉnh thức (nhắc thụ động, không
        // phải khoảnh khắc gác cổng — cam dành riêng cho lớp nhịp thở, xem SendGatekeeperMac.mm).
        view.layer.backgroundColor = [Brand tealLight].CGColor;
        NSButton *enabled = [[NSButton alloc] initWithFrame:NSMakeRect(0, 88, 260, 22)];
        enabled.buttonType = NSButtonTypeSwitch;
        enabled.title = @"Bật chuông tỉnh thức";
        enabled.state = vBell ? NSControlStateValueOn : NSControlStateValueOff;
        [view addSubview:enabled];

        [view addSubview:label(@"Nhắc mỗi", NSMakeRect(0, 58, 70, 20))];
        NSTextField *interval = [[NSTextField alloc] initWithFrame:NSMakeRect(76, 56, 48, 24)];
        interval.integerValue = vBellInterval;
        [view addSubview:interval];
        [view addSubview:label(@"phút", NSMakeRect(132, 58, 40, 20))];

        [view addSubview:label(@"Từ", NSMakeRect(0, 22, 28, 20))];
        NSTextField *from = [[NSTextField alloc] initWithFrame:NSMakeRect(34, 20, 48, 24)];
        from.integerValue = vBellFrom;
        [view addSubview:from];
        [view addSubview:label(@"giờ đến", NSMakeRect(90, 22, 58, 20))];
        NSTextField *to = [[NSTextField alloc] initWithFrame:NSMakeRect(154, 20, 48, 24)];
        to.integerValue = vBellTo;
        [view addSubview:to];
        [view addSubview:label(@"giờ", NSMakeRect(210, 22, 40, 20))];

        alert.accessoryView = view;
        [alert.window setLevel:NSStatusWindowLevel];
        NSModalResponse response = [alert runModal];
        if (response != NSAlertFirstButtonReturn)
            return;

        int iv = (int)interval.integerValue;
        int fr = (int)from.integerValue;
        int tt = (int)to.integerValue;
        if (iv < 1) iv = 60; if (iv > 240) iv = 240;
        if (fr < 0) fr = 0; if (fr > 23) fr = 23;
        if (tt < 0) tt = 0; if (tt > 23) tt = 23;

        vBell = enabled.state == NSControlStateValueOn ? 1 : 0;
        vBellInterval = iv;
        vBellFrom = fr;
        vBellTo = tt;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:vBell forKey:@"vBell"];
        [defaults setInteger:vBellInterval forKey:@"vBellInterval"];
        [defaults setInteger:vBellFrom forKey:@"vBellFrom"];
        [defaults setInteger:vBellTo forKey:@"vBellTo"];
        BellMac_ApplySettings();
    });
}
