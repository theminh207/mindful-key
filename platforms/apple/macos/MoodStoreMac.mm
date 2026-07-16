//
//  MoodStoreMac.mm
//  ModernKey
//
//  [MINDFUL] Xem MoodStoreMac.h + docs/PRIVACY-NOTE.md + docs/PRD.md §5.
//
//  Thiết kế mã hóa: KHÔNG dùng SQLCipher (thêm dependency nặng cho MVP) — thay vào đó, file
//  SQLite thật chỉ tồn tại ở dạng PLAINTEXT trong 1 file tạm, trong đúng khoảng thời gian
//  đang đọc/ghi; ngay sau đó nó được mã hóa AES-256-CBC (khóa ngẫu nhiên lưu trong Keychain,
//  không bao giờ ra khỏi máy) và lưu vào file .enc thật; file tạm bị xóa ngay. Trên đĩa lâu
//  dài, CHỈ tồn tại bản mã hóa.
//

#import "MoodStoreMac.h"
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>
#include <sqlite3.h>

static NSString *const kKeychainService = @"com.mindfulkeyboard.moodstore";
static NSString *const kKeychainAccount = @"mood-store-key";
static NSString *const kConsentGrantedKey = @"MoodStoreConsentGranted";
static NSString *const kConsentAskedKey   = @"MoodStoreConsentAsked";

// [MINDFUL] Consent RIÊNG cho ô ghi (DECISION-daily-note-v1.md §3.2). CỐ Ý không tái dùng 2 khoá
// trên: đồng ý cho app đếm điểm gợn ≠ đồng ý cho app giữ CHỮ mình viết. Gộp chung là âm thầm mở
// rộng phạm vi của một lời đồng ý đã cho trước đó cho một việc nhạy cảm hơn hẳn.
static NSString *const kNoteConsentGrantedKey = @"MoodStoreNoteConsentGranted";
static NSString *const kNoteConsentAskedKey   = @"MoodStoreNoteConsentAsked";
static const NSUInteger kKeySize = 32; // AES-256

#pragma mark - Đường dẫn file

static NSURL *SupportDirectoryURL(void) {
#ifdef MK_TEST_STORE_DIR_ENV
    // [MINDFUL] Nhánh này CHỈ tồn tại trong binary test (tests/macos/mood_pipeline_build.sh định
    // nghĩa macro; project.yml không bao giờ) — cần vì URLForDirectory:/NSHomeDirectory trên macOS
    // lấy home qua getpwuid, PHỚT LỜ $HOME (đã verify thực nghiệm 2026-07-16), nên test không thể
    // cô lập kho khỏi dữ liệu thật của người dùng bằng env HOME như tests/ios vẫn làm.
    const char *testDir = getenv("MK_TEST_STORE_DIR");
    if (testDir && testDir[0]) {
        NSURL *dir = [NSURL fileURLWithPath:[NSString stringWithUTF8String:testDir] isDirectory:YES];
        [[NSFileManager defaultManager] createDirectoryAtURL:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        return dir;
    }
#endif
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

static NSURL *EncryptedFileURL(void) {
    return [SupportDirectoryURL() URLByAppendingPathComponent:@"mood.enc"];
}

#pragma mark - Khóa mã hóa (Keychain)

static NSData *LoadKeyFromKeychain(void) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
    };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess && result) {
        return (__bridge_transfer NSData *)result;
    }
    return nil;
}

static NSData *CreateAndStoreKey(void) {
    uint8_t bytes[kKeySize];
    if (SecRandomCopyBytes(kSecRandomDefault, kKeySize, bytes) != errSecSuccess)
        return nil;
    NSData *key = [NSData dataWithBytes:bytes length:kKeySize];

    NSDictionary *attrs = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount,
        (__bridge id)kSecValueData: key,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    };
    SecItemDelete((__bridge CFDictionaryRef)@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount,
    });
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attrs, NULL);
    if (status != errSecSuccess)
        return nil;
    return key;
}

static NSData *MoodStoreKey(void) {
    NSData *key = LoadKeyFromKeychain();
    if (key)
        return key;
    return CreateAndStoreKey();
}

#pragma mark - AES-256-CBC (CommonCrypto) — IV ngẫu nhiên gắn vào đầu ciphertext

static NSData *AESEncrypt(NSData *plaintext, NSData *key) {
    uint8_t iv[kCCBlockSizeAES128];
    if (SecRandomCopyBytes(kSecRandomDefault, sizeof(iv), iv) != errSecSuccess)
        return nil;

    size_t outCapacity = plaintext.length + kCCBlockSizeAES128;
    NSMutableData *out = [NSMutableData dataWithLength:outCapacity];
    size_t outMoved = 0;

    CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                      key.bytes, key.length, iv,
                                      plaintext.bytes, plaintext.length,
                                      out.mutableBytes, outCapacity, &outMoved);
    if (status != kCCSuccess)
        return nil;

    NSMutableData *result = [NSMutableData dataWithBytes:iv length:sizeof(iv)];
    [result appendBytes:out.mutableBytes length:outMoved];
    return result;
}

static NSData *AESDecrypt(NSData *blob, NSData *key) {
    if (blob.length <= kCCBlockSizeAES128)
        return nil;
    const uint8_t *iv = (const uint8_t *)blob.bytes;
    const uint8_t *cipher = (const uint8_t *)blob.bytes + kCCBlockSizeAES128;
    size_t cipherLen = blob.length - kCCBlockSizeAES128;

    size_t outCapacity = cipherLen + kCCBlockSizeAES128;
    NSMutableData *out = [NSMutableData dataWithLength:outCapacity];
    size_t outMoved = 0;

    CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                      key.bytes, key.length, iv,
                                      cipher, cipherLen,
                                      out.mutableBytes, outCapacity, &outMoved);
    if (status != kCCSuccess)
        return nil;

    return [out subdataWithRange:NSMakeRange(0, outMoved)];
}

#pragma mark - SQLite: mở bản làm việc plaintext tạm thời, đóng lại + mã hóa

static NSString *TempWorkingPath(void) {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:
            [NSString stringWithFormat:@"mindful-mood-%d.sqlite", (int)getpid()]];
}

static void EnsureSchema(sqlite3 *db) {
    // [MINDFUL] Tới 2026-07-16 bảng này KHÔNG có cột nào chứa câu chữ người dùng gõ — chỉ số suy ra
    // + nhãn ngắn định nghĩa sẵn. `note_blob` (thêm bên dưới) là NGOẠI LỆ DUY NHẤT và có hợp đồng
    // riêng: xem MoodStoreMac.h + DECISION-daily-note-v1.md. Nó chứa CIPHERTEXT, không phải chữ thô.
    const char *sql =
        "CREATE TABLE IF NOT EXISTS mood_events ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  ts INTEGER NOT NULL,"
        "  event_type TEXT NOT NULL,"     // 'gatekeeper' | 'checkin' | 'sample' | 'note'
        "  send_risk REAL,"               // 0..1, cho gatekeeper (risk 1 câu) hoặc sample (risk trung bình)
        "  app_bundle_id TEXT,"           // vd 'com.vng.zalo'
        "  choice TEXT,"                  // 'send_anyway' | 'wait' | 'dismissed'
        "  mood_label TEXT,"              // cho 'checkin' (bước 7/8)
        "  intensity INTEGER"             // cho 'checkin' (bước 7/8)
        ");";
    char *err = NULL;
    if (sqlite3_exec(db, sql, NULL, NULL, &err) != SQLITE_OK) {
        NSLog(@"[MoodStoreMac] tạo schema lỗi: %s", err ? err : "?");
        if (err) sqlite3_free(err);
    }

    // [MINDFUL] MIGRATION ĐẦU TIÊN của dự án (2026-07-16, ô ghi cảm nhận).
    // Vì sao KHÔNG chỉ thêm cột vào câu CREATE ở trên: `IF NOT EXISTS` nghĩa là bảng đã có rồi thì
    // câu đó KHÔNG chạy — máy người dùng đang có kho cũ sẽ VĨNH VIỄN thiếu cột, và mọi INSERT note
    // sẽ lỗi "no such column" một cách lặng lẽ. Phải ALTER thật, có kiểm tra trước.
    BOOL hasNoteBlob = NO;
    sqlite3_stmt *chk = NULL;
    if (sqlite3_prepare_v2(db, "PRAGMA table_info(mood_events);", -1, &chk, NULL) == SQLITE_OK) {
        while (sqlite3_step(chk) == SQLITE_ROW) {
            const unsigned char *col = sqlite3_column_text(chk, 1);   // cột 1 = tên
            if (col && strcmp((const char *)col, "note_blob") == 0) { hasNoteBlob = YES; break; }
        }
        sqlite3_finalize(chk);
    }
    if (!hasNoteBlob) {
        // BLOB chứ không TEXT: đây là đầu ra AES (bytes nhị phân), nhét vào cột TEXT là SQLite sẽ
        // diễn giải theo encoding và làm hỏng dữ liệu.
        char *aerr = NULL;
        if (sqlite3_exec(db, "ALTER TABLE mood_events ADD COLUMN note_blob BLOB;", NULL, NULL, &aerr) != SQLITE_OK) {
            NSLog(@"[MoodStoreMac] migration note_blob lỗi: %s", aerr ? aerr : "?");
            if (aerr) sqlite3_free(aerr);
        }
    }
}

// Mở bản làm việc: giải mã file .enc (nếu có) ra file tạm plaintext rồi sqlite3_open nó.
// Trả về sqlite3* đã mở (hoặc NULL nếu lỗi) + ghi đường dẫn tạm vào outTempPath.
static sqlite3 *OpenWorkingDB(NSString **outTempPath) {
    // [MINDFUL] Vá 2026-07-16 (test E2E tests/macos/mood_pipeline Ca 0 tóm được): các hàm ĐỌC
    // (FetchTodaySamples… — popover gọi mỗi lần mở) đi qua đây và từng TẠO kho rỗng + khóa AES
    // thật trong Keychain dù người dùng chưa/không đồng ý — trái lời hứa ở MoodStoreMac.h
    // ("không tạo file, không âm thầm log"). Chưa có consent nào (số LẪN ô ghi) và cũng chưa có
    // kho từ trước → không có gì để đọc, không được phép tạo.
    if (!MoodStoreMac_HasConsent() && !MoodStoreMac_HasNoteConsent() &&
        ![[NSFileManager defaultManager] fileExistsAtPath:EncryptedFileURL().path]) {
        return NULL;
    }

    NSData *key = MoodStoreKey();
    if (!key) {
        NSLog(@"[MoodStoreMac] không tạo/đọc được khóa Keychain — bỏ qua ghi log lần này");
        return NULL;
    }

    NSString *tempPath = TempWorkingPath();
    NSData *encrypted = [NSData dataWithContentsOfURL:EncryptedFileURL()];
    if (encrypted) {
        NSData *plaintext = AESDecrypt(encrypted, key);
        if (plaintext) {
            [plaintext writeToFile:tempPath atomically:YES];
        }
    }

    sqlite3 *db = NULL;
    if (sqlite3_open(tempPath.UTF8String, &db) != SQLITE_OK) {
        NSLog(@"[MoodStoreMac] mở SQLite tạm lỗi: %s", sqlite3_errmsg(db));
        if (db) sqlite3_close(db);
        return NULL;
    }
    EnsureSchema(db);
    *outTempPath = tempPath;
    return db;
}

// Đóng db, đọc lại bytes plaintext từ file tạm, mã hóa, ghi đè file .enc, xóa file tạm.
static void FlushAndCloseDB(sqlite3 *db, NSString *tempPath) {
    if (db) sqlite3_close(db);

    NSData *key = MoodStoreKey();
    NSData *plaintext = [NSData dataWithContentsOfFile:tempPath];
    if (key && plaintext) {
        NSData *encrypted = AESEncrypt(plaintext, key);
        if (encrypted) {
            [encrypted writeToURL:EncryptedFileURL() atomically:YES];
        }
    }
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

#pragma mark - Consent

BOOL MoodStoreMac_HasConsent(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kConsentGrantedKey];
}

void MoodStoreMac_SetConsent(BOOL granted) {
    [[NSUserDefaults standardUserDefaults] setBool:granted forKey:kConsentGrantedKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kConsentAskedKey];
    if (!granted) {
        MoodStoreMac_DeleteAll();
    }
}

BOOL MoodStoreMac_HasAskedConsent(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kConsentAskedKey];
}

void MoodStoreMac_AskConsentIfNeeded(void) {
    if (MoodStoreMac_HasAskedConsent())
        return;

    // [MINDFUL] Onboarding đầy đủ (giải thích trước popup hệ thống, xin quyền, v.v.) là việc
    // của bước 9. Ở đây chỉ đảm bảo KHÔNG BAO GIỜ ghi log khi chưa hỏi/chưa đồng ý.
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Bật nhật ký cảm xúc (local, mã hóa)?";
    alert.informativeText =
        @"Mindful Keyboard có thể ghi lại một điểm gợn trung bình mỗi nhịp chuông, các lượt \"gác cổng\" (điểm rủi ro, "
         "ứng dụng, lựa chọn) và check-in tự nguyện để vẽ lại dòng sông cảm xúc của bạn. CÂU CHỮ BẠN GÕ KHÔNG BAO GIỜ "
         "được lưu — chỉ 1 con số mức độ + thời điểm. Dữ liệu chỉ lưu trên máy này, mã hóa, không gửi lên mạng. Bạn có thể "
         "xóa toàn bộ hoặc tắt bất cứ lúc nào.";
    [alert addButtonWithTitle:@"Đồng ý"];
    [alert addButtonWithTitle:@"Không, cảm ơn"];
    alert.window.level = NSStatusWindowLevel;

    NSModalResponse res = [alert runModal];
    MoodStoreMac_SetConsent(res == NSAlertFirstButtonReturn);
}

#pragma mark - Ghi sự kiện

void MoodStoreMac_LogGatekeeperEvent(double sendRisk, NSString *appBundleID, NSString *choice) {
    if (!MoodStoreMac_HasConsent())
        return; // chưa đồng ý -> không tạo file, không ghi gì cả

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db)
        return;

    sqlite3_stmt *stmt = NULL;
    const char *sql =
        "INSERT INTO mood_events (ts, event_type, send_risk, app_bundle_id, choice) "
        "VALUES (?, 'gatekeeper', ?, ?, ?);";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(stmt, 1, (sqlite3_int64)[[NSDate date] timeIntervalSince1970]);
        sqlite3_bind_double(stmt, 2, sendRisk);
        sqlite3_bind_text(stmt, 3, appBundleID.UTF8String ?: "", -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 4, choice.UTF8String ?: "", -1, SQLITE_TRANSIENT);
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"[MoodStoreMac] ghi sự kiện lỗi: %s", sqlite3_errmsg(db));
        }
        sqlite3_finalize(stmt);
    }

    FlushAndCloseDB(db, tempPath);
}

void MoodStoreMac_LogSampleEvent(double avgAmplitude) {
    if (!MoodStoreMac_HasConsent())
        return;

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db)
        return;

    sqlite3_stmt *stmt = NULL;
    const char *sql =
        "INSERT INTO mood_events (ts, event_type, send_risk) "
        "VALUES (?, 'sample', ?);";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(stmt, 1, (sqlite3_int64)[[NSDate date] timeIntervalSince1970]);
        sqlite3_bind_double(stmt, 2, avgAmplitude);
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"[MoodStoreMac] ghi sample lỗi: %s", sqlite3_errmsg(db));
        }
        sqlite3_finalize(stmt);
    }
    FlushAndCloseDB(db, tempPath);
}

void MoodStoreMac_LogCheckinEvent(NSInteger waveLevel) {
    if (!MoodStoreMac_HasConsent())
        return;
    
    NSString *label = @"calm";
    if (waveLevel == 2) label = @"ripple";
    else if (waveLevel == 3) label = @"wave";

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db)
        return;

    sqlite3_stmt *stmt = NULL;
    const char *sql =
        "INSERT INTO mood_events (ts, event_type, mood_label, intensity) "
        "VALUES (?, 'checkin', ?, ?);";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(stmt, 1, (sqlite3_int64)[[NSDate date] timeIntervalSince1970]);
        sqlite3_bind_text(stmt, 2, label.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_int64(stmt, 3, waveLevel);
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"[MoodStoreMac] ghi checkin lỗi: %s", sqlite3_errmsg(db));
        }
        sqlite3_finalize(stmt);
    }
    FlushAndCloseDB(db, tempPath);
}

#pragma mark - Tóm tắt hôm nay (bước 8)

NSDictionary *MoodStoreMac_FetchTodaySummary(void) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startOfDay = [cal startOfDayForDate:now];
    NSDate *startOfTomorrow = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];
    sqlite3_int64 tsFrom = (sqlite3_int64)[startOfDay timeIntervalSince1970];
    sqlite3_int64 tsTo   = (sqlite3_int64)[startOfTomorrow timeIntervalSince1970];

    int total = 0, sendAnyway = 0, wait = 0;
    NSMutableDictionary<NSNumber *, NSNumber *> *byHour = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSNumber *> *byApp = [NSMutableDictionary dictionary];

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (db) {
        sqlite3_stmt *stmt = NULL;
        const char *sql =
            "SELECT ts, app_bundle_id, choice FROM mood_events "
            "WHERE event_type = 'gatekeeper' AND ts >= ? AND ts < ?;";
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(stmt, 1, tsFrom);
            sqlite3_bind_int64(stmt, 2, tsTo);
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                total++;
                sqlite3_int64 ts = sqlite3_column_int64(stmt, 0);
                const unsigned char *appC = sqlite3_column_text(stmt, 1);
                const unsigned char *choiceC = sqlite3_column_text(stmt, 2);
                NSString *app = appC ? [NSString stringWithUTF8String:(const char *)appC] : nil;
                NSString *choice = choiceC ? [NSString stringWithUTF8String:(const char *)choiceC] : nil;

                if ([choice isEqualToString:@"send_anyway"]) sendAnyway++;
                else if ([choice isEqualToString:@"wait"]) wait++;

                NSDateComponents *comps = [cal components:NSCalendarUnitHour
                                                  fromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
                NSNumber *hourKey = @(comps.hour);
                byHour[hourKey] = @(byHour[hourKey].integerValue + 1);

                if (app.length > 0) {
                    byApp[app] = @(byApp[app].integerValue + 1);
                }
            }
            sqlite3_finalize(stmt);
        }
        FlushAndCloseDB(db, tempPath); // đọc xong vẫn dọn file tạm plaintext như thường lệ
    }

    int peakHour = -1, peakHourCount = 0;
    for (NSNumber *hour in byHour) {
        if ((int)byHour[hour].integerValue > peakHourCount) {
            peakHourCount = (int)byHour[hour].integerValue;
            peakHour = hour.intValue;
        }
    }
    NSString *topApp = nil;
    int topAppCount = 0;
    for (NSString *app in byApp) {
        if ((int)byApp[app].integerValue > topAppCount) {
            topAppCount = (int)byApp[app].integerValue;
            topApp = app;
        }
    }

    NSMutableDictionary *summary = [NSMutableDictionary dictionary];
    summary[@"gatekeeperCount"] = @(total);
    summary[@"sendAnywayCount"] = @(sendAnyway);
    summary[@"waitCount"] = @(wait);
    summary[@"peakHour"] = @(peakHour);
    if (topApp) summary[@"topAppBundleID"] = topApp;
    return summary;
}

// [MINDFUL] 2026-07-16 — 1 NGUỒN cho mọi lối lấy mẫu theo khoảng thời gian. Trước đây chỉ có
// FetchTodaySamples tự ôm SQL; nay "Ngay bây giờ" (cửa sổ trượt 6 tiếng, VẮT QUA NỬA ĐÊM) cần
// cùng câu lệnh đó với mốc khác → tách ra thay vì chép bản thứ 2 gần giống (đúng bài học đã ghi
// ở FetchDailyAverages: 2 bản SQL na ná nhau là chỗ chúng trôi lệch nhau).
static NSArray<NSDictionary *> *FetchSamplesBetween(sqlite3_int64 tsFrom, sqlite3_int64 tsTo) {
    NSMutableArray<NSDictionary *> *samples = [NSMutableArray array];

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (db) {
        sqlite3_stmt *stmt = NULL;
        const char *sql =
            "SELECT ts, send_risk FROM mood_events "
            "WHERE event_type = 'sample' AND ts >= ? AND ts < ? "
            "ORDER BY ts ASC;";
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(stmt, 1, tsFrom);
            sqlite3_bind_int64(stmt, 2, tsTo);
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                sqlite3_int64 ts = sqlite3_column_int64(stmt, 0);
                double risk = sqlite3_column_double(stmt, 1);
                [samples addObject:@{
                    @"ts": @(ts),
                    @"value": @(risk)
                }];
            }
            sqlite3_finalize(stmt);
        }
        FlushAndCloseDB(db, tempPath);
    }

    return samples;
}

NSArray<NSDictionary *> *MoodStoreMac_FetchTodaySamples(void) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *startOfDay = [cal startOfDayForDate:[NSDate date]];
    NSDate *startOfTomorrow = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];
    return FetchSamplesBetween((sqlite3_int64)[startOfDay timeIntervalSince1970],
                                (sqlite3_int64)[startOfTomorrow timeIntervalSince1970]);
}

// [MINDFUL] 2026-07-16 — "Ngay bây giờ" = cửa sổ TRƯỢT, không phải "hôm nay". Cố ý KHÔNG tái dùng
// FetchTodaySamples rồi lọc: mở popover lúc 1h sáng thì 6 tiếng qua = 19h HÔM QUA → 1h nay, lọc từ
// "hôm nay" sẽ mất sạch phần trước nửa đêm và cửa sổ trông như vừa mới bắt đầu gõ.
NSArray<NSDictionary *> *MoodStoreMac_FetchSamplesSince(double secondsAgo) {
    double now = [[NSDate date] timeIntervalSince1970];
    return FetchSamplesBetween((sqlite3_int64)(now - secondsAgo), (sqlite3_int64)(now + 1));
}

#pragma mark - Ô ghi cảm nhận (daily note) — xem hợp đồng ở MoodStoreMac.h

BOOL MoodStoreMac_HasNoteConsent(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kNoteConsentGrantedKey];
}

BOOL MoodStoreMac_HasAskedNoteConsent(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kNoteConsentAskedKey];
}

void MoodStoreMac_SetNoteConsent(BOOL granted) {
    [[NSUserDefaults standardUserDefaults] setBool:granted forKey:kNoteConsentGrantedKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNoteConsentAskedKey];
    if (!granted) {
        // Rút lại đồng ý = chữ đã viết phải BIẾN MẤT, không chỉ "thôi ghi tiếp". Xoá đúng dòng
        // note, KHÔNG đụng dữ liệu số (khác MoodStoreMac_SetConsent — cái đó xoá cả kho).
        NSString *tempPath = nil;
        sqlite3 *db = OpenWorkingDB(&tempPath);
        if (!db) return;
        char *err = NULL;
        if (sqlite3_exec(db, "DELETE FROM mood_events WHERE event_type = 'note';", NULL, NULL, &err) != SQLITE_OK) {
            NSLog(@"[MoodStoreMac] xoá note lỗi: %s", err ? err : "?");
            if (err) sqlite3_free(err);
        }
        FlushAndCloseDB(db, tempPath);
    }
}

// Mốc đầu/cuối ngày hôm nay — dùng chung cho lưu (tìm dòng để sửa) và đọc.
static void TodayBounds(sqlite3_int64 *outFrom, sqlite3_int64 *outTo) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *startOfDay = [cal startOfDayForDate:[NSDate date]];
    NSDate *startOfTomorrow = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];
    *outFrom = (sqlite3_int64)[startOfDay timeIntervalSince1970];
    *outTo   = (sqlite3_int64)[startOfTomorrow timeIntervalSince1970];
}

void MoodStoreMac_SaveNoteForToday(NSString *text) {
    if (!MoodStoreMac_HasNoteConsent())
        return;   // chưa đồng ý = KHÔNG ghi gì, kể cả không tạo dòng rỗng

    NSData *key = MoodStoreKey();
    if (!key) return;

    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db) return;

    sqlite3_int64 from = 0, to = 0;
    TodayBounds(&from, &to);

    // Xoá dòng note hôm nay trước, rồi ghi lại — đơn giản hơn UPDATE-hay-INSERT và tự nhiên đúng
    // luật "1 note/ngày". Chuỗi rỗng = chỉ xoá, không ghi lại (người dùng xoá hết chữ = rút lại).
    sqlite3_stmt *del = NULL;
    if (sqlite3_prepare_v2(db, "DELETE FROM mood_events WHERE event_type = 'note' AND ts >= ? AND ts < ?;",
                            -1, &del, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(del, 1, from);
        sqlite3_bind_int64(del, 2, to);
        sqlite3_step(del);
        sqlite3_finalize(del);
    }

    if (trimmed.length > 0) {
        // MÃ HOÁ RIÊNG nội dung TRƯỚC khi chạm SQLite (chốt 2026-07-16). Nhờ vậy file tạm plaintext
        // mà OpenWorkingDB bày ra đĩa mỗi lần đọc/ghi CHỈ chứa ciphertext của ghi chú, không phải chữ.
        NSData *enc = AESEncrypt([trimmed dataUsingEncoding:NSUTF8StringEncoding], key);
        if (enc) {
            sqlite3_stmt *ins = NULL;
            const char *sql = "INSERT INTO mood_events (ts, event_type, note_blob) VALUES (?, 'note', ?);";
            if (sqlite3_prepare_v2(db, sql, -1, &ins, NULL) == SQLITE_OK) {
                sqlite3_bind_int64(ins, 1, (sqlite3_int64)[[NSDate date] timeIntervalSince1970]);
                sqlite3_bind_blob(ins, 2, enc.bytes, (int)enc.length, SQLITE_TRANSIENT);
                if (sqlite3_step(ins) != SQLITE_DONE) {
                    NSLog(@"[MoodStoreMac] ghi note lỗi: %s", sqlite3_errmsg(db));
                }
                sqlite3_finalize(ins);
            }
        }
    }

    FlushAndCloseDB(db, tempPath);
}

NSString *MoodStoreMac_FetchNoteForToday(void) {
    if (!MoodStoreMac_HasNoteConsent())
        return nil;

    NSData *key = MoodStoreKey();
    if (!key) return nil;

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db) return nil;

    sqlite3_int64 from = 0, to = 0;
    TodayBounds(&from, &to);

    NSString *result = nil;
    sqlite3_stmt *stmt = NULL;
    const char *sql =
        "SELECT note_blob FROM mood_events "
        "WHERE event_type = 'note' AND ts >= ? AND ts < ? "
        "ORDER BY ts DESC LIMIT 1;";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(stmt, 1, from);
        sqlite3_bind_int64(stmt, 2, to);
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            const void *bytes = sqlite3_column_blob(stmt, 0);
            int len = sqlite3_column_bytes(stmt, 0);
            if (bytes && len > 0) {
                NSData *dec = AESDecrypt([NSData dataWithBytes:bytes length:(NSUInteger)len], key);
                if (dec) result = [[NSString alloc] initWithData:dec encoding:NSUTF8StringEncoding];
            }
        }
        sqlite3_finalize(stmt);
    }
    FlushAndCloseDB(db, tempPath);
    return result.length > 0 ? result : nil;   // rỗng ⇒ nil, đúng hợp đồng ở .h
}

#pragma mark - Story 3.7/3.8 — Tuần/Tháng (trung bình mỗi ngày, gap = NSNull thật)

// [MINDFUL] Story 3.7/3.8 — hàm DÙNG CHUNG cho cả Tuần (numDays=7) và Tháng (numDays=30), thay
// vì viết 2 bản SQL gần giống hệt nhau (bài học ghi trong story 3.8 Dev Notes "Tái dùng SQL
// pattern của 3.7"). Trả ĐỦ numDays phần tử theo thứ tự cũ→mới, TỰ chèn NSNull cho ngày SQL
// không trả về hàng nào (0 mẫu hôm đó) — caller không cần tự phát hiện gap như FetchTodaySamples
// từng bắt caller làm (2 nơi từng lặp lại cùng 1 logic gap-detection, không lặp lại lần 3 ở đây).
static NSArray<NSDictionary *> *FetchDailyAverages(NSInteger numDays) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startOfToday = [cal startOfDayForDate:now];
    NSDate *rangeStart = [cal dateByAddingUnit:NSCalendarUnitDay value:-(numDays - 1) toDate:startOfToday options:0];
    NSDate *rangeEnd = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfToday options:0]; // đầu ngày mai
    sqlite3_int64 tsFrom = (sqlite3_int64)[rangeStart timeIntervalSince1970];
    sqlite3_int64 tsTo   = (sqlite3_int64)[rangeEnd timeIntervalSince1970];

    // day-key ("yyyy-MM-dd") tính bằng NSCalendar (Objective-C side), KHÔNG dùng SQLite
    // date('unixepoch','localtime') — tránh 2 nơi tính "ngày local" theo 2 cách khác nhau có thể
    // lệch múi giờ; FetchTodaySamples cũng dùng NSCalendar cho cùng mục đích (dòng ~405-410).
    NSDateFormatter *dayFmt = [[NSDateFormatter alloc] init];
    dayFmt.dateFormat = @"yyyy-MM-dd";
    dayFmt.timeZone = [NSTimeZone localTimeZone];

    NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *byDay = [NSMutableDictionary dictionary];

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (db) {
        sqlite3_stmt *stmt = NULL;
        const char *sql =
            "SELECT ts, send_risk FROM mood_events "
            "WHERE event_type = 'sample' AND ts >= ? AND ts < ? "
            "ORDER BY ts ASC;";
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(stmt, 1, tsFrom);
            sqlite3_bind_int64(stmt, 2, tsTo);
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                sqlite3_int64 ts = sqlite3_column_int64(stmt, 0);
                double risk = sqlite3_column_double(stmt, 1);
                NSString *dayKey = [dayFmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
                NSMutableArray<NSNumber *> *bucket = byDay[dayKey];
                if (!bucket) { bucket = [NSMutableArray array]; byDay[dayKey] = bucket; }
                [bucket addObject:@(risk)];
            }
            sqlite3_finalize(stmt);
        }
        FlushAndCloseDB(db, tempPath);
    }

    // Duyệt đủ numDays ngày theo thứ tự cũ->mới, kể cả ngày SQL không có hàng nào — chèn NSNull
    // thật (quãng trống), KHÔNG suy diễn/nội suy (đúng nguyên tắc dec4 áp lại ở mức NGÀY).
    NSMutableArray<NSDictionary *> *result = [NSMutableArray arrayWithCapacity:(NSUInteger)numDays];
    for (NSInteger i = 0; i < numDays; i++) {
        NSDate *dayDate = [cal dateByAddingUnit:NSCalendarUnitDay value:i toDate:rangeStart options:0];
        NSString *dayKey = [dayFmt stringFromDate:dayDate];
        NSArray<NSNumber *> *bucket = byDay[dayKey];
        id value;
        if (bucket.count > 0) {
            double sum = 0;
            for (NSNumber *n in bucket) sum += n.doubleValue;
            value = @(sum / (double)bucket.count);
        } else {
            value = [NSNull null];
        }
        [result addObject:@{ @"day": dayKey, @"value": value }];
    }
    return result;
}

NSArray<NSDictionary *> *MoodStoreMac_FetchWeekSamples(void) {
    return FetchDailyAverages(7);
}

NSArray<NSDictionary *> *MoodStoreMac_FetchMonthSamples(void) {
    return FetchDailyAverages(30);
}

#if DEBUG
// [MINDFUL] 2026-07-16 — xem MoodStoreMac.h cho bối cảnh đầy đủ. Đánh dấu bằng app_bundle_id vì
// cột này KHÔNG dùng cho event_type='sample' (INSERT thật ở MoodStoreMac_LogSampleEvent phía
// trên chỉ set ts/event_type/send_risk) — tái dùng cột có sẵn, không cần ALTER TABLE/migration
// trên file mã hóa đang chạy thật của người dùng.
static NSString *const kSeedFakeMarker = @"__mk_seed_fake__";

void MoodStoreMac_SeedFakeSamplesForTesting(NSInteger numDays) {
    if (!MoodStoreMac_HasConsent())
        return;

    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db)
        return;

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    const char *sql =
        "INSERT INTO mood_events (ts, event_type, send_risk, app_bundle_id) "
        "VALUES (?, 'sample', ?, ?);";

    // [MINDFUL] Vá 2026-07-16 (chủ dự án khoanh đỏ ảnh popover: "dòng cảm xúc hôm nay" chỉ có chấm
    // trôi lơ lửng, KHÔNG có dòng). Nguyên nhân là DỮ LIỆU GIẢ SAI BẢN CHẤT, không phải view sai:
    //
    //  · Bản cũ rải 4-6 mẫu ở giờ NGẪU NHIÊN 9h-21h → 2 mẫu bất kỳ cách nhau ~2-3 TIẾNG, vượt xa
    //    ngưỡng "quãng không gõ" (vBellInterval × 1.5 = 22.5 phút) → EmotionRiverView chèn NSNull
    //    giữa MỌI cặp → mọi mẫu bị cô lập → không vẽ nổi một đoạn nước nào. View làm ĐÚNG luật
    //    dec.4 ("cấm bịa nước ở chỗ không có dữ liệu"); chính dữ liệu giả mới là thứ phi thực tế.
    //  · Bản cũ còn đặt mẫu ở 9h-21h CỦA HÔM NAY kể cả khi bây giờ mới 1h sáng → chấm nằm ở TƯƠNG LAI.
    //
    // Người gõ thật đi theo PHIÊN: trong phiên, mỗi nhịp chuông ghi 1 mẫu cách đều đúng
    // vBellInterval phút → nước liền mạch; giữa các phiên mới là quãng trống thật. Biên độ cũng đi
    // bộ dần (random walk) chứ không nhảy cóc 0.1↔0.8 mỗi 15 phút — nhờ vậy sóng có hình dâng/lắng
    // đọc được, đúng thứ cần nhìn để kiểm "sông có bám trạng thái không".
    extern int vBellInterval;
    NSTimeInterval stepSecs = (vBellInterval > 0 ? vBellInterval : 15) * 60.0;
    NSTimeInterval nowTs = [now timeIntervalSince1970];

    // Ghi 1 phiên gõ: runLen mẫu cách đều stepSecs, biên độ đi bộ dần. Bỏ qua mẫu rơi vào tương lai.
    void (^writeSession)(NSTimeInterval, NSInteger) = ^(NSTimeInterval startTs, NSInteger runLen) {
        double risk = (arc4random_uniform(35) + 10) / 100.0;   // mở phiên êm: 0.10..0.44
        NSTimeInterval t = startTs;
        for (NSInteger i = 0; i < runLen; i++) {
            if (t > nowTs) break;                              // KHÔNG bịa mẫu ở tương lai
            sqlite3_stmt *stmt = NULL;
            if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
                sqlite3_bind_int64(stmt, 1, (sqlite3_int64)t);
                sqlite3_bind_double(stmt, 2, risk);
                sqlite3_bind_text(stmt, 3, kSeedFakeMarker.UTF8String, -1, SQLITE_TRANSIENT);
                if (sqlite3_step(stmt) != SQLITE_DONE) {
                    NSLog(@"[MoodStoreMac][SEED] ghi lỗi: %s", sqlite3_errmsg(db));
                }
                sqlite3_finalize(stmt);
            }
            t += stepSecs;
            risk += ((double)arc4random_uniform(21) - 10.0) / 100.0;   // trôi ±0.10 mỗi nhịp
            if (risk < 0.05) risk = 0.05;
            if (risk > 0.85) risk = 0.85;
        }
    };

    for (NSInteger d = 0; d < numDays; d++) {
        if (d == 0) {
            // HÔM NAY: neo phiên KẾT THÚC ngay lúc này (vừa gõ xong). Không neo theo giờ cố định
            // 9h-21h — test lúc 1h sáng sẽ ra ngày trống trơn vì cả khung đó đều ở tương lai.
            NSInteger runLen = 8 + (NSInteger)arc4random_uniform(9);   // 8-16 mẫu = 2-4 tiếng gõ
            writeSession(nowTs - (runLen - 1) * stepSecs, runLen);
        } else {
            NSDate *day = [cal dateByAddingUnit:NSCalendarUnitDay value:-d toDate:now options:0];
            NSDateComponents *dayComps = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:day];
            dayComps.hour = 0; dayComps.minute = 0; dayComps.second = 0;
            NSTimeInterval midnight = [[cal dateFromComponents:dayComps] timeIntervalSince1970];

            NSInteger sessions = 2 + (NSInteger)arc4random_uniform(2);   // 2-3 phiên gõ/ngày
            NSInteger hour = 9;
            for (NSInteger s = 0; s < sessions && hour < 21; s++) {
                NSInteger runLen = 6 + (NSInteger)arc4random_uniform(11);  // 6-16 mẫu
                writeSession(midnight + hour * 3600.0 + arc4random_uniform(40) * 60.0, runLen);
                hour += 3 + (NSInteger)arc4random_uniform(3);             // nghỉ 3-5 tiếng giữa 2 phiên
            }
        }
    }

    FlushAndCloseDB(db, tempPath);
    NSLog(@"[MoodStoreMac][SEED] Đã giả lập %ld ngày theo phiên gõ (đánh dấu, KHÔNG lẫn dữ liệu thật) — DEBUG-ONLY.", (long)numDays);
}

void MoodStoreMac_DeleteSimulatedData(void) {
    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db)
        return;

    sqlite3_stmt *stmt = NULL;
    const char *sql = "DELETE FROM mood_events WHERE app_bundle_id = ?;";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, kSeedFakeMarker.UTF8String, -1, SQLITE_TRANSIENT);
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"[MoodStoreMac][SEED] xóa lỗi: %s", sqlite3_errmsg(db));
        }
        sqlite3_finalize(stmt);
    }
    FlushAndCloseDB(db, tempPath);
    NSLog(@"[MoodStoreMac][SEED] Đã xóa sạch dữ liệu giả lập — dữ liệu thật (nếu có) không đụng tới.");
}

BOOL MoodStoreMac_HasSimulatedData(void) {
    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db)
        return NO;

    BOOL has = NO;
    sqlite3_stmt *stmt = NULL;
    const char *sql = "SELECT 1 FROM mood_events WHERE app_bundle_id = ? LIMIT 1;";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, kSeedFakeMarker.UTF8String, -1, SQLITE_TRANSIENT);
        has = (sqlite3_step(stmt) == SQLITE_ROW);
        sqlite3_finalize(stmt);
    }
    FlushAndCloseDB(db, tempPath);
    return has;
}
#endif

void MoodStoreMac_DeleteAll(void) {
    [[NSFileManager defaultManager] removeItemAtURL:EncryptedFileURL() error:nil];
    // Xóa luôn khóa Keychain — lần ghi kế tiếp (nếu có) sẽ tạo khóa mới, dữ liệu cũ (nếu sót
    // file nào đó) sẽ không thể giải mã được nữa.
    SecItemDelete((__bridge CFDictionaryRef)@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount,
    });
}

#pragma mark - Riêng tư (Export & Auto-purge)

BOOL MoodStoreMac_ExportCSVToURL(NSURL *url) {
    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db) return NO;
    
    NSMutableString *csv = [NSMutableString stringWithString:@"ts,event_type,send_risk,mood_label,intensity\n"];
    
    sqlite3_stmt *stmt = NULL;
    // Xuất hẹp: chỉ lấy các cột này, bỏ qua app_bundle_id và choice
    // [MINDFUL] 2026-07-16 — LOẠI HẲN dòng 'note' (DECISION-daily-note-v1.md §3.4). Cột `note_blob`
    // vốn đã không được SELECT nên chữ không lọt; nhưng để dòng note lại thì file xuất vẫn khai ra
    // "21:03 ngày 15/7 người này có viết nhật ký" — đó là metadata của nhật ký riêng tư rời khỏi
    // vùng mã hoá. Đúng tinh thần đã chốt 2026-07-14: hẹp hơn khi dữ liệu ra ngoài. Muốn xuất note
    // thì phải là lựa chọn opt-in riêng, có cảnh báo rõ — không phải mặc định.
    const char *sql = "SELECT ts, event_type, send_risk, mood_label, intensity FROM mood_events "
                      "WHERE event_type != 'note' ORDER BY ts ASC;";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            sqlite3_int64 ts = sqlite3_column_int64(stmt, 0);
            const unsigned char *typeC = sqlite3_column_text(stmt, 1);
            double risk = sqlite3_column_type(stmt, 2) == SQLITE_NULL ? 0.0 : sqlite3_column_double(stmt, 2);
            const unsigned char *labelC = sqlite3_column_text(stmt, 3);
            sqlite3_int64 intensity = sqlite3_column_type(stmt, 4) == SQLITE_NULL ? 0 : sqlite3_column_int64(stmt, 4);
            
            NSString *type = typeC ? [NSString stringWithUTF8String:(const char *)typeC] : @"";
            NSString *label = labelC ? [NSString stringWithUTF8String:(const char *)labelC] : @"";
            
            [csv appendFormat:@"%lld,%@,%.2f,%@,%lld\n", ts, type, risk, label, intensity];
        }
        sqlite3_finalize(stmt);
    }
    
    FlushAndCloseDB(db, tempPath);
    
    NSError *err = nil;
    [csv writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&err];
    return err == nil;
}

static NSString *const kAutoPurgeDaysKey = @"MoodStoreAutoPurgeDays";

void MoodStoreMac_SetAutoPurgeDays(NSInteger days) {
    [[NSUserDefaults standardUserDefaults] setInteger:days forKey:kAutoPurgeDaysKey];
}

NSInteger MoodStoreMac_AutoPurgeDays(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:kAutoPurgeDaysKey]) {
        return [d integerForKey:kAutoPurgeDaysKey];
    }
    return 90; // Mặc định 90 ngày
}

void MoodStoreMac_RunAutoPurgeIfNeeded(void) {
    NSInteger days = MoodStoreMac_AutoPurgeDays();
    if (days <= 0) return;
    
    sqlite3_int64 threshold = (sqlite3_int64)([[NSDate date] timeIntervalSince1970] - days * 24 * 3600);
    
    NSString *tempPath = nil;
    sqlite3 *db = OpenWorkingDB(&tempPath);
    if (!db) return;
    
    sqlite3_stmt *stmt = NULL;
    // [MINDFUL] Vá 2026-07-16 (chủ dự án chốt phương án (a)) — TỪNG là `WHERE ts < ?` trần, không
    // lọc loại, nên nó cuốn theo cả dòng 'note'. Ghép với sự thật "v1 chỉ đọc được note HÔM NAY"
    // (DECISION-daily-note-v1.md) thì hậu quả là: chữ người dùng tự tay viết đi vào kho KHÔNG có
    // cửa đọc, rồi bị xoá sau 90 ngày — không một ai, kể cả chính họ, từng đọc lại được. Số đo suy
    // ra thì xoá được (còn sinh lại được khi gõ tiếp); CHỮ NGƯỜI VIẾT thì mất là mất hẳn.
    // Nên auto-purge từ nay CHỪA note ra, chờ tính năng đọc lại ngày cũ (đợt sau).
    // ⚠️ Hệ quả phải nói thật với người dùng: lời hứa "tự xoá sau N ngày" ở màn Riêng tư nay KHÔNG
    // còn đúng với ô ghi. Copy màn Riêng tư đã sửa kèm trong commit này. Note vẫn xoá được bằng:
    // tắt consent ô ghi (xoá sạch note) · "Xoá nhật ký" (xoá cả kho) · tự xoá chữ trong ngày.
    const char *sql = "DELETE FROM mood_events WHERE ts < ? AND event_type != 'note';";
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(stmt, 1, threshold);
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"[MoodStoreMac] xóa tự động lỗi: %s", sqlite3_errmsg(db));
        }
        sqlite3_finalize(stmt);
    }
    FlushAndCloseDB(db, tempPath);
}
