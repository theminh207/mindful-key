//
//  BellMac.mm
//  ModernKey
//
//  [MINDFUL] macOS mindfulness bell.
//

#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>
#include "BellMac.h"
#include "NudgeCoordinatorMac.h"
#import "BrandColors.h"

int vBell = 0;
int vBellInterval = 60;
int vBellFrom = 8;
int vBellTo = 22;
int vBellHotkey = 0x6200060B;

// [MINDFUL] Áo mới v2 — xem BellMac.h cho hợp đồng.
NSString * const kBellSoundMuteName = @"__silent__";

NSString * const kBellSoundIdTemple = @"temple";
NSString * const kBellSoundIdChime  = @"chime";
NSString * const kBellSoundIdWind   = @"wind";
NSString * const kBellSoundIdCustom = @"custom";
NSString * const kBellSoundDefaultId = @"temple";   // = kBellSoundIdTemple (hằng compile-time, không tự tham chiếu được)
NSString * const kBellCustomPathKey  = @"vBellCustomSoundPath";

// [MINDFUL] Chỗ DUY NHẤT biết tên file .wav. Tên file vẫn tiếng Việt (nghịch luật "định danh =
// tiếng Anh" — nợ có sẵn, đổi tên file là đụng bundle/đóng gói nên tách việc, xem FRICTION-LOG
// 2026-07-17); bù lại mọi nơi khác trong app chỉ nói chuyện bằng id tiếng Anh qua hàm này.
static NSString *ResourceNameForSoundId(NSString *sid) {
    if ([sid isEqualToString:kBellSoundIdChime]) return @"Chuông gió";
    if ([sid isEqualToString:kBellSoundIdWind])  return @"Chuông reo";
    return @"Chuông chùa";
}

NSString *BellMac_SoundIdFromStored(NSString *stored) {
    if (stored.length == 0) return kBellSoundDefaultId;   // cài mới, chưa ai chọn gì
    if ([stored isEqualToString:kBellSoundMuteName]) return stored;
    for (NSString *sid in @[kBellSoundIdTemple, kBellSoundIdChime, kBellSoundIdWind, kBellSoundIdCustom]) {
        if ([stored isEqualToString:sid]) return sid;
    }
    // Đời cũ: kho từng lưu thẳng nhãn tiếng Việt (trước 2026-07-17).
    if ([stored isEqualToString:@"Chuông chùa"]) return kBellSoundIdTemple;
    if ([stored isEqualToString:@"Chuông gió"])  return kBellSoundIdChime;
    if ([stored isEqualToString:@"Chuông reo"])  return kBellSoundIdWind;
    return kBellSoundDefaultId;   // tên lạ: "Glass"/"Tink" thời placeholder, hoặc rác
}

// Kho riêng của app — CÙNG thư mục MoodStoreMac dùng cho mood.enc (một chỗ duy nhất chứa đồ của
// người dùng). An toàn: MoodStoreMac_DeleteAll() chỉ xoá đúng file mood.enc, không quét cả thư mục.
static NSURL *CustomSoundDirURL(void) {
    NSURL *base = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                         inDomain:NSUserDomainMask
                                                appropriateForURL:nil
                                                           create:YES
                                                            error:nil];
    NSURL *dir = [base URLByAppendingPathComponent:@"MindfulKeyboard" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:dir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    return dir;
}

NSString *BellMac_CustomSoundPath(void) {
    NSString *p = [[NSUserDefaults standardUserDefaults] stringForKey:kBellCustomPathKey];
    if (p.length == 0) return nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:p]) return nil;   // tệp bốc hơi → coi như chưa có
    return p;
}

// Bộ nhớ đệm cho tiếng riêng: NSSound hệ thống tự cache theo tên, tệp ngoài thì không — nạp lại
// 1 file 20s mỗi lần reo là phí. Khoá theo path KHÔNG đủ (tệp đích luôn tên CustomBell.<đuôi> nên
// đổi tệp khác cùng đuôi ⇒ path y hệt) → BellMac_InstallCustomSound phải tự dội cache.
static NSSound *g_customSound = nil;
static NSString *g_customSoundPath = nil;

static NSSound *CustomSound(void) {
    NSString *p = BellMac_CustomSoundPath();
    if (p.length == 0) return nil;
    if (g_customSound && [g_customSoundPath isEqualToString:p]) return g_customSound;
    NSSound *s = [[NSSound alloc] initWithContentsOfFile:p byReference:NO];
    if (!s) return nil;
    g_customSound = s;
    g_customSoundPath = p;
    return s;
}

// Trả nil nếu id không dựng được thành tiếng (thiếu file trong bundle / tệp riêng hỏng-mất).
static NSSound *SoundForId(NSString *sid) {
    if ([sid isEqualToString:kBellSoundIdCustom]) return CustomSound();
    return [NSSound soundNamed:ResourceNameForSoundId(sid)];
}

BOOL BellMac_InstallCustomSound(NSURL *src, NSString **outMessage) {
    // Thử phát TRƯỚC khi chép: NSOpenPanel không lọc kiểu tệp (lọc bằng API mới đòi macOS 11+ /
    // API cũ đã deprecated ⇒ thêm warning), nên đây là chỗ duy nhất chặn tệp macOS không mở nổi.
    NSSound *probe = [[NSSound alloc] initWithContentsOfURL:src byReference:NO];
    if (!probe) {
        if (outMessage) *outMessage = @"macOS không mở được tệp này. Thử tệp .wav, .aiff, .mp3 hoặc .m4a nhé.";
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *ext = src.pathExtension.length ? src.pathExtension : @"wav";
    NSURL *dst = [CustomSoundDirURL() URLByAppendingPathComponent:
                  [NSString stringWithFormat:@"CustomBell.%@", ext]];

    // Dọn mọi bản cũ (kể cả đuôi khác) — nếu không, đổi từ .wav sang .mp3 sẽ để lại tệp mồ côi.
    NSURL *dir = CustomSoundDirURL();
    for (NSURL *f in [fm contentsOfDirectoryAtURL:dir includingPropertiesForKeys:nil options:0 error:nil]) {
        if ([f.lastPathComponent hasPrefix:@"CustomBell."])
            [fm removeItemAtURL:f error:nil];
    }

    NSError *err = nil;
    if (![fm copyItemAtURL:src toURL:dst error:&err]) {
        if (outMessage) *outMessage = [NSString stringWithFormat:@"Không chép được tệp vào kho của app: %@",
                                       err.localizedDescription ?: @"lý do không rõ"];
        return NO;
    }

    g_customSound = nil;        // dội cache: path có thể trùng y hệt bản trước
    g_customSoundPath = nil;
    [[NSUserDefaults standardUserDefaults] setObject:dst.path forKey:kBellCustomPathKey];
    return YES;
}

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
    NSString *sid = BellMac_SoundIdFromStored([d stringForKey:@"vBellSoundName"]);
    if ([sid isEqualToString:kBellSoundMuteName]) return;   // "Im" — không phát gì, có chủ đích.
    float vol = [d objectForKey:@"vBellVolume"] ? (float)[d doubleForKey:@"vBellVolume"] : 0.6f;
    if (vol < 0) vol = 0;
    if (vol > 1) vol = 1;                            // user kéo về 0 = im lặng (có chủ đích)

    // Dựng không nổi (tệp riêng bị xoá, file thiếu trong bundle) → rơi về tiếng THIẾT KẾ, KHÔNG rơi
    // về ping hệ thống: người dùng mất tệp riêng vẫn nghe chuông của app, không nghe tiếng lạ hoắc.
    NSSound *sound = SoundForId(sid) ?: SoundForId(kBellSoundDefaultId);
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
    // [MINDFUL] 2026-07-18 — NSUserNotification (deprecated từ macOS 11) đổi sang
    // UNUserNotificationCenter khi nâng sàn lên 13.0. Nhánh dự phòng NSAlert runModal cũ đã gỡ:
    // chỉ chạy khi NSUserNotificationCenter không tồn tại (macOS < 10.8) — chết sẵn từ thời sàn
    // 10.15, và một cái modal chặn tay giữa lúc gõ là trái tinh thần chuông (nhắc, không chặn).
    // Tiến trình không bundle (test harness) — UN center ném exception, xem chú thích MoodWatchMac.
    if ([NSBundle mainBundle].bundleIdentifier == nil)
        return;
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Chuông tỉnh thức - Mindful";
    content.body = message;
    content.sound = nil;   // đã tự phát âm (có âm lượng) ở trên → tránh phát trùng âm mặc định
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"mindfulkey-bell"
                                                                      content:content
                                                                      trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req
                                                           withCompletionHandler:nil];
}

static BOOL isSnoozed(void) {
    return g_snoozeUntil > 0 && [NSDate timeIntervalSinceReferenceDate] < g_snoozeUntil;
}

// [MINDFUL] 2026-07-16 — xem hợp đồng ở BellMac.h. Tiếng riêng cho khung chấm nhịp.
void BellMac_PlayCheckinChime(void) {
    // Cùng bộ cổng chặn với bellTick(): tắt chuông · tạm hoãn · ngoài giờ chuông. Thiếu chỗ này
    // thì khung chấm nhịp sẽ kêu lúc 3h sáng giữa giờ yên lặng — đúng thứ người dùng đã tắt đi.
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    if (!vBell || isSnoozed() || !isInBellRange(hour))
        return;

    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    // Tôn trọng "Im" + âm lượng 0 y như chuông chính, dù tiếng này là tiếng CỐ ĐỊNH không theo lựa chọn.
    if ([[d stringForKey:@"vBellSoundName"] isEqualToString:kBellSoundMuteName])
        return;
    float vol = [d objectForKey:@"vBellVolume"] ? (float)[d doubleForKey:@"vBellVolume"] : 0.6f;
    if (vol <= 0) return;
    vol *= 0.6f;   // "nhỏ" — nhẹ hơn hẳn chuông chính: đây là lời mời, không phải tiếng gọi

    // Chủ dự án chỉ đích danh file 2026-07-16 ("Lấy tiếng chuông này khi hiển thị khung chấm nhịp
    // ngay" → platforms/apple/macos/Chuông reo.wav). CỐ ĐỊNH, không theo tiếng người dùng chọn —
    // kể cả khi họ đã chọn tiếng riêng: khung này phải nghe ra ngay là việc KHÁC chuông tỉnh thức.
    NSSound *sound = [NSSound soundNamed:ResourceNameForSoundId(kBellSoundIdWind)];
    if (!sound) return;   // thiếu file thì IM — KHÔNG NSBeep, beep hệ thống nghe như báo lỗi
    if (sound.isPlaying) [sound stop];
    sound.volume = vol;
    [sound play];
}

NSString * const kMKMoodBeatNotification = @"MKMoodBeatNotification";

static void bellTick(NSTimer *timer) {
    // [MINDFUL] 2026-07-16 — NHỊP trước, TIẾNG sau. Xem hợp đồng ở BellMac.h.
    // Bắn nhịp TRƯỚC mọi cổng chặn: nhật ký + khung chấm nhịp phải chạy kể cả khi người dùng tắt
    // chuông / tạm hoãn / ngoài giờ chuông. Họ tắt TIẾNG, không phải tắt việc ghi nhận.
    [[NSNotificationCenter defaultCenter] postNotificationName:kMKMoodBeatNotification object:nil];

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

NSDate * BellMac_NextRingDate(void) {
    if (!vBell || isSnoozed() || g_bellTimer == nil)
        return nil;
    return g_bellTimer.fireDate;
}

void BellMac_ApplySettings() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_bellTimer != nil) {
            [g_bellTimer invalidate];
            g_bellTimer = nil;
        }

        // [MINDFUL] 2026-07-16 — TỪNG có `if (!vBell) return;` ở đây. Bỏ đi CÓ CHỦ ĐÍCH: từ nay
        // đồng hồ này là NHỊP chung của app (kMKMoodBeatNotification), không còn là đồng hồ riêng
        // của tiếng chuông. Tắt chuông mà dừng nhịp = tắt luôn nhật ký + khung chấm nhịp, tức âm
        // thầm tắt việc ghi nhận khi người dùng chỉ muốn yên tĩnh. Cổng chặn TIẾNG nằm trong
        // bellTick(), không phải ở đây.
        // `BellMac_NextRingDate`/`MinutesUntilNextRing` vẫn tự trả nil khi !vBell nên dòng "Dự kiến
        // reo lúc" không bị ảnh hưởng — đã kiểm, chúng có sẵn check `!vBell` riêng.
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
    vBellHotkey = (int)[defaults integerForKey:@"BellToggleHotkey"];
    if (vBellHotkey == 0) vBellHotkey = 0x6200060B;

    if (vBellInterval <= 0) vBellInterval = 60;
    if (vBellFrom < 0 || vBellFrom > 23) vBellFrom = 8;
    if (vBellTo < 0 || vBellTo > 23) vBellTo = 22;

    BellMac_ApplySettings();
}

// [MINDFUL] Epic 3 Chặng 2 (F13) — BellMac_ShowSettings() (NSAlert đời cũ: input số thô, KHÔNG
// sàn/trần, không Độ nhạy/Âm thanh) đã XOÁ 2026-07-15. Nó ghi CHUNG UserDefaults key với
// BellSettingsView (vBell/vBellInterval/vBellFrom/vBellTo) → 2 UI đá nhau, và bản cũ không hề
// chặn sàn 15 phút vừa chốt cho ô "Tùy chỉnh" (chỉ có `if (iv<1) iv=60`, không có sàn thật) —
// mở lại bằng chính bản cũ là lách thẳng qua quyết định riêng tư vừa chốt cùng ngày. Menu tray
// giờ mở thẳng "Chuông" trong cửa sổ Cài đặt (xem AppDelegate.m onBellSettingsSelected).
