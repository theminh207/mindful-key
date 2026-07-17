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

        // ===== Ca 6b: auto-purge dọn SỐ ĐO quá hạn, và ô ghi =====
        //
        // ⚠️ ĐỌC KỸ GIỚI HẠN TRƯỚC KHI TIN CA NÀY (đừng nâng lên ✅ trong TEST_MATRIX):
        // Bản vá 2026-07-16 thêm `AND event_type != 'note'` vào câu DELETE của auto-purge. Ca này
        // KHÔNG chứng minh được bản vá đó, và đây là lý do — ghi ra để người sau khỏi tưởng đã phủ:
        //   · Note LUÔN mang mốc HÔM NAY (SaveNoteForToday ghi theo TodayBounds, không nhận ts).
        //   · Purge chỉ xoá `ts < now − days*86400`, và `days <= 0` bị coi là TẮT (return sớm).
        //   → Với mọi giá trị days hợp lệ, note-hôm-nay LUÔN nằm trong hạn, nên nó sống sót y hệt
        //     nhau ở CẢ bản vá lẫn bản chưa vá. Muốn test thật thì phải ghi note với mốc QUÁ KHỨ,
        //     tức cần một cửa tiêm-ngày cho test — chưa có, và không tự ý thêm chỉ để chiều test.
        // Cái ca này CÓ chứng minh: (1) purge vẫn dọn được số đo quá hạn (bản vá không làm hỏng
        // chính việc dọn — hồi quy đúng nghĩa); (2) hai đường xoá note hợp lệ vẫn hoạt động.
        // Việc "note sống qua mốc N ngày" vẫn cần một người đổi đồng hồ máy mà thử, hoặc chờ cửa
        // tiêm-ngày. Đã ghi ⚠️ ở TEST_MATRIX, không ghi ✅.
        printf("\n-- Ca 6b: auto-purge dọn số đo quá hạn; ô ghi lưu/đọc/xoá --\n");
        MoodStoreMac_SetNoteConsent(YES);
        MoodStoreMac_SaveNoteForToday(@"hôm nay nhẹ nhõm", @"Điều gì đã giữ cho ngày nhẹ như vậy?");
        expectTrue("note hôm nay đọc lại được ngay sau khi lưu",
                   [MoodStoreMac_FetchNoteForToday() isEqualToString:@"hôm nay nhẹ nhõm"]);

        // "Chồng ghi chú" (2026-07-16): FetchAllNotes trả chữ + câu hỏi hôm đó, mới nhất trước.
        NSArray<NSDictionary *> *all = MoodStoreMac_FetchAllNotes();
        expectEqualInt("FetchAllNotes: 1 ngày viết -> 1 dòng", (long)all.count, 1);
        if (all.count == 1) {
            expectTrue("FetchAllNotes trả đúng chữ", [all[0][@"text"] isEqualToString:@"hôm nay nhẹ nhõm"]);
            expectTrue("FetchAllNotes trả kèm câu hỏi hôm đó (§2.6)",
                       [all[0][@"question"] isEqualToString:@"Điều gì đã giữ cho ngày nhẹ như vậy?"]);
        }
        // Sửa trong ngày = SỬA, không đẻ dòng thứ 2 (§2.6) — chồng ghi chú không được nhân đôi 1 ngày.
        MoodStoreMac_SaveNoteForToday(@"hôm nay nhẹ nhõm thật", @"Điều gì đã giữ cho ngày nhẹ như vậy?");
        expectEqualInt("sửa note trong ngày -> chồng ghi chú vẫn 1 dòng",
                       (long)MoodStoreMac_FetchAllNotes().count, 1);
        // Note KHÔNG có câu hỏi (dòng ghi trước bản này) phải chịu được — key vắng, không crash.
        MoodStoreMac_SaveNoteForToday(@"không kèm câu hỏi", nil);
        all = MoodStoreMac_FetchAllNotes();
        expectEqualInt("note thiếu câu hỏi vẫn đọc được", (long)all.count, 1);
        if (all.count == 1) {
            expectTrue("note thiếu câu hỏi -> key 'question' VẮNG (không bịa câu khác)",
                       all[0][@"question"] == nil);
        }
        MoodStoreMac_SaveNoteForToday(@"hôm nay nhẹ nhõm", @"Điều gì đã giữ cho ngày nhẹ như vậy?");
        expectEqualInt("1 note/ngày: lưu lần 2 là SỬA, không đẻ dòng mới",
                       (long)MoodStoreMac_FetchTodaySamples().count, 3);   // note không lẫn vào mẫu

        // days <= 0 = TẮT tự dọn (lựa chọn "Không bao giờ" ở màn Riêng tư) — phải no-op.
        MoodStoreMac_SetAutoPurgeDays(0);
        MoodStoreMac_RunAutoPurgeIfNeeded();
        expectEqualInt("tự dọn TẮT -> số đo còn nguyên", (long)MoodStoreMac_FetchTodaySamples().count, 3);
        expectTrue("tự dọn TẮT -> note còn nguyên",
                   [MoodStoreMac_FetchNoteForToday() isEqualToString:@"hôm nay nhẹ nhõm"]);

        // Dữ liệu QUÁ HẠN thật: seed 30 ngày (mốc quá khứ thật) rồi dọn với hạn 1 ngày.
        // Đây là phần chứng minh purge còn chạy đúng SAU bản vá.
        // Seed gieo phiên gõ rải suốt 30 ngày — KỂ CẢ hôm nay (nên FetchTodaySamples tăng, không
        // còn là 3). Đo sau khi seed thay vì hard-code: số mẫu/ngày là chuyện nội bộ của seed, test
        // không nên khoá cứng vào nó.
        MoodStoreMac_SeedFakeSamplesForTesting(30);
        expectTrue("seed 30 ngày -> có dữ liệu giả trong kho", MoodStoreMac_HasSimulatedData());
        expectEqualInt("FetchWeekSamples luôn trả đủ 7 ô (kể cả ngày trống)",
                       (long)MoodStoreMac_FetchWeekSamples().count, 7);
        NSInteger todayAfterSeed = (NSInteger)MoodStoreMac_FetchTodaySamples().count;
        expectTrue("seed có gieo cả mẫu hôm nay (nền cho phép thử dưới)", todayAfterSeed > 3);

        // Ngày cũ trong tuần CÓ dữ liệu trước khi dọn — mốc để chứng minh purge thật sự xoá.
        NSArray *weekBefore = MoodStoreMac_FetchWeekSamples();
        NSInteger daysWithDataBefore = 0;
        for (NSDictionary *day in weekBefore) {
            if (![day[@"value"] isKindOfClass:[NSNull class]]) daysWithDataBefore++;
        }
        expectTrue("trước khi dọn: tuần qua có ngày cũ mang dữ liệu", daysWithDataBefore > 1);

        MoodStoreMac_SetAutoPurgeDays(1);
        MoodStoreMac_RunAutoPurgeIfNeeded();

        NSInteger daysWithDataAfter = 0;
        for (NSDictionary *day in MoodStoreMac_FetchWeekSamples()) {
            if (![day[@"value"] isKindOfClass:[NSNull class]]) daysWithDataAfter++;
        }
        expectTrue("sau dọn hạn 1 ngày: ngày CŨ đã trống — purge vẫn làm việc sau bản vá",
                   daysWithDataAfter < daysWithDataBefore);
        expectEqualInt("sau dọn: mẫu HÔM NAY (trong hạn) còn nguyên",
                       (long)MoodStoreMac_FetchTodaySamples().count, (long)todayAfterSeed);
        expectTrue("sau dọn: note còn (xem giới hạn ở đầu ca — chưa chứng minh được bản vá)",
                   [MoodStoreMac_FetchNoteForToday() isEqualToString:@"hôm nay nhẹ nhõm"]);

        // Rút consent ô ghi = chữ phải BIẾN MẤT (đường xoá hợp lệ, khác auto-purge) và KHÔNG đụng số đo.
        MoodStoreMac_SetNoteConsent(NO);
        expectTrue("rút consent ô ghi -> note bị xoá", MoodStoreMac_FetchNoteForToday() == nil);
        expectEqualInt("rút consent ô ghi KHÔNG đụng số đo",
                       (long)MoodStoreMac_FetchTodaySamples().count, (long)todayAfterSeed);
        MoodStoreMac_SetAutoPurgeDays(90);   // trả về mặc định, tránh rò trạng thái sang ca sau

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

        // ===== Ca 8: đọc lựa chọn bộ tiếng — KHÔNG ai bị mất tiếng chuông khi app đổi cách lưu =====
        // [MINDFUL] 2026-07-17. Đây là hàm CHUNG cho lối phát (playBellSound) và lối hiện
        // (BellSettingsView refresh) — dựng ra chính vì 2 nơi từng tự đoán mặc định khác nhau
        // (người dùng thật báo: màn sáng "Chuông chùa" mà tai nghe ping "Glass" của macOS).
        // Ca này khoá 2 thứ: (a) dữ liệu ĐỜI CŨ (nhãn tiếng Việt) vẫn ra đúng tiếng cũ — không ai
        // tỉnh dậy thấy chuông mình chọn bị đổi; (b) giá trị rỗng/lạ rơi về tiếng THIẾT KẾ, không
        // rơi về tiếng hệ thống. Hàm thuần, không đụng đĩa/UserDefaults nên chạy được ở đây.
        printf("\n-- Ca 8: BellMac_SoundIdFromStored — dịch lựa chọn đời cũ + rơi về mặc định --\n");
        expectTrue("cài mới (nil)        → tiếng thiết kế, KHÔNG phải ping hệ thống",
                   [BellMac_SoundIdFromStored(nil) isEqualToString:kBellSoundDefaultId]);
        expectTrue("chuỗi rỗng           → tiếng thiết kế",
                   [BellMac_SoundIdFromStored(@"") isEqualToString:kBellSoundDefaultId]);
        expectTrue("đời cũ 'Chuông chùa' → temple (giữ đúng tiếng người dùng đã chọn)",
                   [BellMac_SoundIdFromStored(@"Chuông chùa") isEqualToString:kBellSoundIdTemple]);
        expectTrue("đời cũ 'Chuông gió'  → chime",
                   [BellMac_SoundIdFromStored(@"Chuông gió") isEqualToString:kBellSoundIdChime]);
        expectTrue("đời cũ 'Chuông reo'  → wind",
                   [BellMac_SoundIdFromStored(@"Chuông reo") isEqualToString:kBellSoundIdWind]);
        expectTrue("rác đời placeholder 'Glass' → tiếng thiết kế (đúng bug đã vá)",
                   [BellMac_SoundIdFromStored(@"Glass") isEqualToString:kBellSoundDefaultId]);
        expectTrue("id đời mới 'chime'   → giữ nguyên",
                   [BellMac_SoundIdFromStored(kBellSoundIdChime) isEqualToString:kBellSoundIdChime]);
        expectTrue("id 'custom'          → giữ nguyên (tiếng của người dùng)",
                   [BellMac_SoundIdFromStored(kBellSoundIdCustom) isEqualToString:kBellSoundIdCustom]);
        expectTrue("'__silent__'         → giữ nguyên, KHÔNG bị dịch thành tiếng nào",
                   [BellMac_SoundIdFromStored(kBellSoundMuteName) isEqualToString:kBellSoundMuteName]);

        // Dọn: xóa kho fake-home (build.sh cũng rm -rf cả HOME tạm).
        MoodStoreMac_SetConsent(NO);

        printf("\n%s (%d lỗi)\n", gFail == 0 ? "TẤT CẢ CA ĐỀU ĐẠT" : "CÓ CA SAI", gFail);
        return gFail == 0 ? 0 : 1;
    }
}
