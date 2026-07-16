//
//  mood_pipeline_test.mm
//  mindful-key — test E2E (tầng dữ liệu) cho chuỗi nhịp lấy mẫu macOS:
//
//      gõ từ (MoodWatchMac_OnWord) → nhịp chung (kMKMoodBeatNotification, BellMac)
//      → ghi mẫu (MoodStoreMac_LogSampleEvent) → đọc lại (FetchSamplesSince/FetchTodaySamples)
//
//  Đây là ĐÚNG chuỗi hàm mà popover "Ngay bây giờ" + "Hôm nay" tiêu thụ — link FILE THẬT
//  (MoodWatchMac.mm, MoodStoreMac.mm, BellMac.mm, NudgeCoordinatorMac.mm, MoodBuffer.cpp),
//  không stub logic. Chạy trên HOST macOS, không cần app/Accessibility — theo mẫu
//  tests/ios/mood_journal_store_test.mm.
//
//  CÔ LẬP (bắt buộc, vì MoodStoreMac ghi vào đường dẫn CỐ ĐỊNH của người dùng thật):
//   · MK_TEST_STORE_DIR trỏ vào thư mục tạm (build.sh set; MoodStoreMac chỉ đọc env này khi
//     biên dịch với -DMK_TEST_STORE_DIR_ENV — binary app thật không có nhánh đó) → mood.enc
//     rơi vào thư mục tạm, không đụng ~/Library/Application Support/MindfulKeyboard/mood.enc
//     thật. Ghi chú: cô lập bằng env HOME như tests/ios KHÔNG dùng được — NSHomeDirectory/
//     URLForDirectory trên macOS lấy home qua getpwuid, phớt lờ $HOME (verify 2026-07-16).
//     Test TỰ KIỂM env trước khi chạm bất kỳ thứ gì — sai là abort ngay.
//   · Keychain: build.sh đổi tên SecItemCopyMatching/SecItemAdd/SecItemDelete bằng -D macro
//     → khóa AES là khóa test cố định, KHÔNG đọc/ghi/xóa item thật "com.mindfulkeyboard.moodstore"
//     (binary lạ đụng keychain thật còn làm bật hộp thoại xin quyền — treo CI).
//   · UserDefaults (consent): tiến trình này có domain riêng theo tên binary, không chung
//     domain với app thật; đầu test vẫn reset consent về NO cho idempotent.
//
//  KHÔNG test ở đây (ghi rõ để TEST_MATRIX không hiểu nhầm):
//   · NSTimer của BellMac có tick đúng vBellInterval phút không (chờ ≥1 phút — quá chậm cho
//     vòng test; chỉ kiểm timer ĐÃ được lên lịch qua BellMac_NextRingDate).
//   · Vẽ EmotionRiverView / mở popover thật (cần app + mắt người, xem docs/TEST_MATRIX.md).
//

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#include <string>
#import "MoodWatchMac.h"
#import "MoodStoreMac.h"
#import "BellMac.h"

// MoodWatchMac.mm gán vào con trỏ này (bình thường Engine.cpp định nghĩa) — test không link
// engine nên tự định nghĩa. Chuỗi engine→OnWord đã có tests/core che; ở đây vào thẳng OnWord.
void (*vOnWordCommitted)(const std::wstring& word) = NULL;

#pragma mark - Stub Keychain (build.sh -D rename — xem đầu file)

extern "C" OSStatus MKTestSecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    (void)query;
    static uint8_t bytes[32];
    for (int i = 0; i < 32; i++) bytes[i] = 0x42; // khóa test cố định — dữ liệu test, không cần ngẫu nhiên
    if (result) *result = (CFTypeRef)CFBridgingRetain([NSData dataWithBytes:bytes length:32]);
    return errSecSuccess;
}
extern "C" OSStatus MKTestSecItemAdd(CFDictionaryRef attrs, CFTypeRef *result) {
    (void)attrs; if (result) *result = NULL; return errSecSuccess;
}
extern "C" OSStatus MKTestSecItemDelete(CFDictionaryRef query) {
    (void)query; return errSecSuccess;
}

#pragma mark - Khung expect (theo mẫu mood_journal_store_test.mm)

static int gFail = 0;

static void expectTrue(const char *label, BOOL cond) {
    if (!cond) gFail++;
    printf("  %-72s %s\n", label, cond ? "OK" : "SAI <<<");
}

static void expectEqualInt(const char *label, long got, long want) {
    BOOL ok = (got == want);
    if (!ok) gFail++;
    printf("  %-72s got=%ld want=%ld %s\n", label, got, want, ok ? "OK" : "SAI <<<");
}

static NSString *StorePath(void) {
    return [[NSString stringWithUTF8String:getenv("MK_TEST_STORE_DIR")]
            stringByAppendingPathComponent:@"mood.enc"];
}

// Nhịp thật do g_bellTimer (BellMac) bắn; test bắn tay đúng notification đó — cùng tên hằng
// kMMoodBeatNotification link từ BellMac.mm thật, không chép chuỗi.
static void PostBeat(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMKMoodBeatNotification object:nil];
}

// Observer nhịp trong MoodWatchMac chạy đồng bộ trên luồng post (queue:nil) rồi dispatch_async
// vào g_moodQueue nội bộ. MoodWatchMac_Flush dùng dispatch_sync vào đúng queue đó → gọi sau
// PostBeat là hàng rào chờ mẫu ghi xong (beat đã tiêu g_sampleCount nên Flush không ghi thêm).
static void WaitMoodQueueDrained(void) {
    MoodWatchMac_Flush();
}

static void TypeWord(const wchar_t *w) {
    MoodWatchMac_OnWord(std::wstring(w));
}

int main(void) {
    @autoreleasepool {
        // ===== Cổng an toàn: kho PHẢI đang trỏ vào thư mục tạm trước khi chạm consent/store =====
        const char *storeDir = getenv("MK_TEST_STORE_DIR");
        if (!storeDir || !strstr(storeDir, "mk-e2e-store")) {
            fprintf(stderr, "ABORT: MK_TEST_STORE_DIR không phải thư mục tạm mk-e2e-store (đang là %s).\n"
                            "Chạy qua tests/macos/mood_pipeline_build.sh, đừng chạy binary trực tiếp.\n",
                    storeDir ? storeDir : "(chưa set)");
            return 2;
        }
        printf("Kho cô lập: %s\n", storeDir);

        // Reset consent (domain UserDefaults riêng của tiến trình test, idempotent giữa các lần chạy).
        // SetConsent(NO) đồng thời xóa kho — kho ở fake home nên vô hại.
        MoodStoreMac_SetConsent(NO);

        // ===== Ca 0: chưa consent → không ghi, KHÔNG tạo file (lời hứa PRIVACY-NOTE) =====
        printf("\n-- Ca 0: consent NO -> LogSampleEvent không ghi gì, không tạo file --\n");
        MoodStoreMac_LogSampleEvent(0.5);
        expectEqualInt("FetchTodaySamples khi chưa consent", (long)MoodStoreMac_FetchTodaySamples().count, 0);
        expectTrue("mood.enc KHÔNG tồn tại khi chưa consent",
                   ![[NSFileManager defaultManager] fileExistsAtPath:StorePath()]);

        MoodStoreMac_SetConsent(YES);
        MoodWatchMac_Init();

        // ===== Ca 1: nhịp đến mà KHÔNG gõ gì → không bịa mẫu =====
        printf("\n-- Ca 1: nhịp không gõ -> 0 mẫu (không bịa dữ liệu) --\n");
        PostBeat();
        WaitMoodQueueDrained();
        expectEqualInt("FetchSamplesSince(1h) sau nhịp chay", (long)MoodStoreMac_FetchSamplesSince(3600).count, 0);

        // ===== Ca 2: gõ câu êm → nhịp → đúng 1 mẫu, biên độ thấp =====
        printf("\n-- Ca 2: gõ êm -> nhịp -> 1 mẫu biên độ thấp --\n");
        TypeWord(L"hôm"); TypeWord(L"nay"); TypeWord(L"trời"); TypeWord(L"đẹp");
        PostBeat();
        WaitMoodQueueDrained();
        NSArray<NSDictionary *> *samples = MoodStoreMac_FetchSamplesSince(3600);
        expectEqualInt("số mẫu sau nhịp đầu có gõ", (long)samples.count, 1);
        if (samples.count == 1) {
            double v = [samples[0][@"value"] doubleValue];
            expectTrue("biên độ câu êm trong [0, 0.2)", v >= 0.0 && v < 0.2);
        }
        expectEqualInt("FetchTodaySamples khớp (số 'nhịp chuông hôm nay' trên popover)",
                       (long)MoodStoreMac_FetchTodaySamples().count, 1);

        // ===== Ca 3: nhịp thứ hai không gõ thêm → vẫn 1 mẫu (quãng lặng là quãng lặng thật) =====
        printf("\n-- Ca 3: nhịp thứ hai không gõ thêm -> vẫn 1 mẫu --\n");
        PostBeat();
        WaitMoodQueueDrained();
        expectEqualInt("số mẫu sau nhịp chay thứ hai", (long)MoodStoreMac_FetchSamplesSince(3600).count, 1);

        // ===== Ca 4: từ căng thẳng → mẫu mới biên độ cao hơn hẳn câu êm =====
        // "bực" (-2, nhóm giận, trọng số 1.0) → raw=2 → risk = 1-e^(-2/5) ≈ 0.33: đủ cao để
        // so sánh, vẫn dưới kSendRiskThreshold (0.5) nên KHÔNG kéo popup NSPanel vào vòng test.
        printf("\n-- Ca 4: gõ từ căng -> mẫu biên độ cao hơn --\n");
        TypeWord(L"bực"); TypeWord(L"quá");
        PostBeat();
        WaitMoodQueueDrained();
        samples = MoodStoreMac_FetchSamplesSince(3600);
        expectEqualInt("số mẫu sau nhịp thứ ba", (long)samples.count, 2);
        if (samples.count == 2) {
            double calm  = [samples[0][@"value"] doubleValue];
            double tense = [samples[1][@"value"] doubleValue];
            expectTrue("mẫu căng > mẫu êm", tense > calm);
            expectTrue("mẫu căng trong (0.1, 1.0]", tense > 0.1 && tense <= 1.0);
        }
        expectTrue("LastSendRisk phản ánh câu căng (> 0.1)", MoodWatchMac_LastSendRisk() > 0.1);

        // ===== Ca 5: Flush lúc thoát app (commit d37820f) → mẫu dở dang không mất =====
        printf("\n-- Ca 5: gõ rồi Flush (mô phỏng thoát app) -> mẫu được ghi --\n");
        TypeWord(L"mệt");
        MoodWatchMac_Flush();
        expectEqualInt("số mẫu sau Flush", (long)MoodStoreMac_FetchSamplesSince(3600).count, 3);

        // ===== Ca 6: at-rest thật sự mã hóa — file không phải SQLite trần =====
        printf("\n-- Ca 6: mood.enc mã hóa at-rest --\n");
        NSData *head = [[NSFileHandle fileHandleForReadingAtPath:StorePath()] readDataOfLength:15];
        expectTrue("mood.enc tồn tại sau khi có consent + có mẫu", head != nil);
        if (head) {
            expectTrue("15 byte đầu KHÔNG phải header 'SQLite format 3'",
                       memcmp(head.bytes, "SQLite format 3", 15) != 0);
        }

        // ===== Ca 7: nhịp gốc (g_bellTimer) có được lên lịch — nguồn bắn notification thật =====
        printf("\n-- Ca 7: BellMac_ApplySettings lên lịch nhịp gốc --\n");
        vBell = 1; // NextRingDate cố ý trả nil khi tắt chuông — bật để đọc được fireDate
        BellMac_ApplySettings(); // dispatch_async main queue → phải bơm runloop cho block chạy
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
        NSDate *next = BellMac_NextRingDate();
        expectTrue("g_bellTimer đã lên lịch (NextRingDate != nil)", next != nil);
        if (next) {
            NSTimeInterval secs = [next timeIntervalSinceNow];
            expectTrue("tick kế tiếp trong (0, vBellInterval phút]",
                       secs > 0 && secs <= (NSTimeInterval)vBellInterval * 60.0 + 1.0);
        }

        // Dọn: xóa kho fake-home (build.sh cũng rm -rf cả HOME tạm).
        MoodStoreMac_SetConsent(NO);

        printf("\n%s (%d lỗi)\n", gFail == 0 ? "TẤT CẢ CA ĐỀU ĐẠT" : "CÓ CA SAI", gFail);
        return gFail == 0 ? 0 : 1;
    }
}
