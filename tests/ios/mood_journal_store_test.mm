//
//  mood_journal_store_test.mm
//  mindful-key — test tự động cho MoodJournalStore (Round 3, story 3.1: kho nhật ký cảm xúc
//  on-device mã hóa + consent).
//
//  Chạy trên HOST (macOS) — không cần Simulator. containerURLForSecurityApplicationGroupIdentifier:
//  vẫn trả về 1 URL hợp lệ dưới ~/Library/Group Containers/<id>/ cho tiến trình KHÔNG ký (đã verify
//  thực nghiệm trước khi viết file này) — nên test chạy được với đúng API sản phẩm thật, KHÔNG cần
//  giả lập container riêng. Việc CHIA SẺ khóa Keychain giữa 2 tiến trình (extension <-> container)
//  qua keychain-access-groups là DEVICE-ONLY (cần Team ID thật để ký) — KHÔNG test được ở đây, xem
//  tests/ios/MANUAL-TEST-SCRIPT.md.
//
//  Mỗi ca test gọi MoodJournalStore_ResetForTesting() TRƯỚC để không rò rỉ state giữa các ca (đúng
//  pattern NudgeCoordinatorIOS_ResetStateForTesting) — file này dùng App Group suite THẬT
//  (group.vn.gnh.mindfulkey) và Keychain thật, không phải suite/keychain giả lập, vì API public của
//  MoodJournalStore không nhận suite làm tham số (khác BellReminderSettingsBridge/
//  KeyboardSettingsBridge) — ResetForTesting() dọn sạch sau mỗi ca nên không để lại rác lâu dài.

#import <Foundation/Foundation.h>
#include <stdint.h>
#include <string.h>
#import "MoodJournalStore.h"

static int gFail = 0;

static void expectTrue(const char *label, BOOL cond) {
    if (!cond) gFail++;
    printf("  %-70s %s\n", label, cond ? "OK" : "SAI <<<");
}

static void expectEqualInt(const char *label, long got, long want) {
    BOOL ok = (got == want);
    if (!ok) gFail++;
    printf("  %-70s got=%ld  want=%ld  %s\n", label, got, want, ok ? "OK" : "SAI <<<");
}

// ts của "hôm nay" tại giờ `hour` (giữ nguyên năm/tháng/ngày hiện tại, chỉ đổi giờ) — để
// FetchTodaySummary (dùng NSCalendar startOfDay CỦA "bây giờ" thật) luôn coi các event này là
// "hôm nay", bất kể test chạy lúc mấy giờ.
static int64_t TodayAtHourTS(int hour) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                      fromDate:[NSDate date]];
    comps.hour = hour;
    comps.minute = 0;
    comps.second = 0;
    NSDate *date = [cal dateFromComponents:comps];
    return (int64_t)[date timeIntervalSince1970];
}

// ===== Ca 1: round-trip cơ bản =====
static void testRoundTrip(void) {
    printf("\n-- Ca 1: consent YES -> log vài event -> FetchTodaySummary đúng tenseCount --\n");
    MoodJournalStore_ResetForTesting();

    expectTrue("chưa consent lúc mới reset", !MoodJournalStore_HasConsent());
    MoodJournalStore_SetConsent(YES);
    expectTrue("sau SetConsent(YES) -> HasConsent đúng YES", MoodJournalStore_HasConsent());
    expectTrue("sau SetConsent(YES) -> HasAskedConsent đúng YES", MoodJournalStore_HasAskedConsent());

    MoodJournalStore_LogTenseMoment(0.42);
    MoodJournalStore_LogTenseMoment(0.51);
    MoodJournalStore_LogTenseMoment(0.99);

    NSDictionary *summary = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("tenseCount = 3 sau 3 lần log", [summary[@"tenseCount"] integerValue], 3);
    expectTrue("peakHour hợp lệ (>= 0, vì có dữ liệu hôm nay)", [summary[@"peakHour"] intValue] >= 0);
}

// ===== Ca 2: peakHour =====
static void testPeakHour(void) {
    printf("\n-- Ca 2: peakHour = giờ nhiều lần gợn nhất; rỗng -> -1 --\n");
    MoodJournalStore_ResetForTesting();

    NSDictionary *emptySummary = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("chưa log gì -> tenseCount = 0", [emptySummary[@"tenseCount"] integerValue], 0);
    expectEqualInt("chưa log gì -> peakHour = -1", [emptySummary[@"peakHour"] intValue], -1);

    MoodJournalStore_SetConsent(YES);
    // 9h: 1 lần · 14h: 2 lần · 20h: 1 lần -> peak = 14h
    MoodJournalStore_LogTenseMomentAtForTesting(0.40, TodayAtHourTS(9));
    MoodJournalStore_LogTenseMomentAtForTesting(0.40, TodayAtHourTS(14));
    MoodJournalStore_LogTenseMomentAtForTesting(0.40, TodayAtHourTS(14));
    MoodJournalStore_LogTenseMomentAtForTesting(0.40, TodayAtHourTS(20));

    NSDictionary *summary = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("tenseCount = 4", [summary[@"tenseCount"] integerValue], 4);
    expectEqualInt("peakHour = 14 (2 lần, nhiều nhất)", [summary[@"peakHour"] intValue], 14);
}

// ===== Ca 3: cổng consent =====
static void testConsentGate(void) {
    printf("\n-- Ca 3: chưa consent -> KHÔNG tạo file, KHÔNG ghi gì --\n");
    MoodJournalStore_ResetForTesting();
    expectTrue("chưa consent (mặc định sau reset)", !MoodJournalStore_HasConsent());

    NSURL *fileURL = MoodJournalStore_FileURLForTesting();
    expectTrue("file .enc CHƯA tồn tại trước khi log",
               ![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);

    MoodJournalStore_LogTenseMoment(0.90); // risk cao nhưng KHÔNG có consent
    expectTrue("sau LogTenseMoment KHÔNG consent -> file VẪN chưa tồn tại",
               ![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);

    NSDictionary *summary = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("FetchTodaySummary -> tenseCount = 0", [summary[@"tenseCount"] integerValue], 0);

    // Test seam LogTenseMomentAtForTesting cũng PHẢI tôn trọng cổng consent (không đường tắt).
    MoodJournalStore_LogTenseMomentAtForTesting(0.90, TodayAtHourTS(10));
    expectTrue("LogTenseMomentAtForTesting KHÔNG consent -> file vẫn chưa tồn tại",
               ![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
}

// ===== Ca 4: mã hóa — file trên đĩa KHÔNG chứa plaintext nhận ra được =====
static void testEncryption(void) {
    printf("\n-- Ca 4: file .enc trên đĩa KHÔNG chứa plaintext nhận ra được --\n");
    MoodJournalStore_ResetForTesting();
    MoodJournalStore_SetConsent(YES);

    int64_t ts = TodayAtHourTS(11);
    double risk = 0.777;
    MoodJournalStore_LogTenseMomentAtForTesting(risk, ts);

    NSURL *fileURL = MoodJournalStore_FileURLForTesting();
    expectTrue("file .enc tồn tại sau khi log",
               [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);

    NSData *raw = [NSData dataWithContentsOfURL:fileURL];
    expectTrue("đọc được raw bytes file .enc", raw != nil && raw.length > 0);

    // Dựng tay đúng 16 byte plaintext mà event này lẽ ra sẽ có NẾU không mã hóa — rồi assert
    // KHÔNG tìm thấy chuỗi byte đó y nguyên trong file trên đĩa (negative test "không plaintext").
    uint8_t handBuilt[16];
    uint64_t tsBits = (uint64_t)ts;
    uint64_t riskBits = 0;
    memcpy(&riskBits, &risk, sizeof(riskBits));
    for (int i = 0; i < 8; i++) {
        handBuilt[i]     = (uint8_t)(tsBits >> (8 * i));
        handBuilt[8 + i] = (uint8_t)(riskBits >> (8 * i));
    }
    NSData *handBuiltPlaintext = [NSData dataWithBytes:handBuilt length:sizeof(handBuilt)];

    NSRange found = [raw rangeOfData:handBuiltPlaintext options:0 range:NSMakeRange(0, raw.length)];
    expectTrue("raw bytes KHÔNG chứa plaintext 16-byte dựng tay (đã mã hóa)", found.location == NSNotFound);

    // Chứng minh giải mã lại ĐÚNG (round-trip end-to-end qua đúng API sản phẩm, không chỉ "không
    // phải plaintext" mà còn "vẫn đọc lại đúng dữ liệu" — qua FetchTodaySummary).
    NSDictionary *summary = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("giải mã lại đúng -> tenseCount = 1", [summary[@"tenseCount"] integerValue], 1);
    expectEqualInt("giải mã lại đúng -> peakHour = 11", [summary[@"peakHour"] intValue], 11);
}

// ===== Ca 5: DeleteAll =====
static void testDeleteAll(void) {
    printf("\n-- Ca 5: DeleteAll xóa file, FetchTodaySummary về rỗng --\n");
    MoodJournalStore_ResetForTesting();
    MoodJournalStore_SetConsent(YES);
    MoodJournalStore_LogTenseMoment(0.5);

    NSURL *fileURL = MoodJournalStore_FileURLForTesting();
    expectTrue("file tồn tại trước khi DeleteAll",
               [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);

    MoodJournalStore_DeleteAll();

    expectTrue("file KHÔNG còn tồn tại sau DeleteAll",
               ![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
    NSDictionary *summary = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("sau DeleteAll -> tenseCount = 0", [summary[@"tenseCount"] integerValue], 0);
    expectEqualInt("sau DeleteAll -> peakHour = -1", [summary[@"peakHour"] intValue], -1);
}

// ===== Ca 6: SetConsent(NO) xóa sạch =====
static void testSetConsentNoWipesEverything(void) {
    printf("\n-- Ca 6: SetConsent(NO) xóa sạch (mirror MoodStoreMac_SetConsent) --\n");
    MoodJournalStore_ResetForTesting();
    MoodJournalStore_SetConsent(YES);
    MoodJournalStore_LogTenseMoment(0.6);
    MoodJournalStore_LogTenseMoment(0.7);

    NSDictionary *before = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("có 2 event trước khi thu hồi consent", [before[@"tenseCount"] integerValue], 2);

    MoodJournalStore_SetConsent(NO);

    expectTrue("HasConsent -> NO sau khi thu hồi", !MoodJournalStore_HasConsent());
    NSURL *fileURL = MoodJournalStore_FileURLForTesting();
    expectTrue("file KHÔNG còn tồn tại sau SetConsent(NO)",
               ![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
    NSDictionary *after = MoodJournalStore_FetchTodaySummary();
    expectEqualInt("sau SetConsent(NO) -> tenseCount = 0", [after[@"tenseCount"] integerValue], 0);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        printf("=== TEST MoodJournalStore (Round 3, story 3.1: kho nhật ký cảm xúc mã hóa + consent) ===\n");

        testRoundTrip();
        testPeakHour();
        testConsentGate();
        testEncryption();
        testDeleteAll();
        testSetConsentNoWipesEverything();

        // Dọn sạch lần cuối — không để lại rác App Group/Keychain thật trên máy dev sau khi test xong.
        MoodJournalStore_ResetForTesting();

        if (gFail == 0) {
            printf("\n=== XONG — TẤT CẢ PASS ===\n");
        } else {
            printf("\n=== XONG — %d CA SAI (make test-ios sẽ đỏ) ===\n", gFail);
        }
    }
    return gFail == 0 ? 0 : 1;
}
