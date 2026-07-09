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
static const NSUInteger kKeySize = 32; // AES-256

#pragma mark - Đường dẫn file

static NSURL *SupportDirectoryURL(void) {
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
    // KHÔNG có cột nào chứa câu chữ/văn bản gốc — chỉ số + nhãn ngắn đã định nghĩa trước.
    const char *sql =
        "CREATE TABLE IF NOT EXISTS mood_events ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  ts INTEGER NOT NULL,"
        "  event_type TEXT NOT NULL,"     // 'gatekeeper' | 'checkin' (bước 7/8)
        "  send_risk REAL,"               // 0..1, NULL nếu event_type != 'gatekeeper'
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
}

// Mở bản làm việc: giải mã file .enc (nếu có) ra file tạm plaintext rồi sqlite3_open nó.
// Trả về sqlite3* đã mở (hoặc NULL nếu lỗi) + ghi đường dẫn tạm vào outTempPath.
static sqlite3 *OpenWorkingDB(NSString **outTempPath) {
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
        @"Mindful Keyboard có thể ghi lại các lần \"gác cổng\" (điểm rủi ro, ứng dụng, lựa chọn "
         "của bạn) để sau này cho bạn xem thống kê. CÂU CHỮ BẠN GÕ KHÔNG BAO GIỜ được lưu — chỉ "
         "1 con số rủi ro + thời điểm + tên ứng dụng. Dữ liệu chỉ lưu trên máy này, mã hóa, "
         "không gửi lên mạng. Bạn có thể xóa toàn bộ hoặc tắt bất cứ lúc nào.";
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
