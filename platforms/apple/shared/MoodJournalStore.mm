//
//  MoodJournalStore.mm
//  mindful-key — shared (iOS container <-> keyboard extension, Round 3 story 3.1)
//
//  Xem MoodJournalStore.h + docs/PRIVACY-NOTE.md + bmad-output/ios/tech-spec-r3.md "Kiến trúc kho
//  nhật ký đã chốt". Mã hóa: AES-256-CBC (CommonCrypto), IV ngẫu nhiên gắn đầu ciphertext, khóa
//  32B trong Keychain — cùng công thức MoodStoreMac.mm, KHÁC ở chỗ payload là buffer event 16
//  byte/event thay vì file SQLite tạm.
//
//  ⚠️ KEYCHAIN ACCESS GROUP (chia sẻ khóa extension <-> container) — GIỚI HẠN ĐÃ BIẾT: giá trị
//  kKeychainAccessGroup dưới đây là "vn.gnh.mindfulkey.shared" (KHÔNG có tiền tố Team ID thật —
//  dự án ký AD-HOC, không có Apple Developer Team, xem project.yml "DEVELOPMENT_TEAM: cố ý bỏ
//  trống"). $(AppIdentifierPrefix) trong 2 file .entitlements chỉ được Xcode/codesign thay thế lúc
//  KÝ THẬT bằng 1 Team ID thật — KHÔNG thể biết giá trị đó lúc biên dịch file .mm này. Việc
//  kSecAttrAccessGroup có khớp đúng giá trị đã ký trong entitlements hay không CHỈ verify được
//  trên thiết bị thật/Simulator có Team ID thật (device-only, giống giới hạn App Group heartbeat ở
//  AppGroupBridge.h) — xem báo cáo cuối story 3.1 cho chi tiết. Nếu SecItemAdd/SecItemCopyMatching
//  lỗi errSecMissingEntitlement trên thiết bị thật, đây là chỗ đầu tiên cần soát lại.
//

#import "MoodJournalStore.h"
#import "AppGroupConstants.h"
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>
#include <TargetConditionals.h>
#include <string.h>

static NSString *const kAppGroupSuiteName = kMindfulKeyAppGroupSuiteName; // group.vn.gnh.mindfulkey — DÙNG LẠI hằng số chung (AppGroupConstants.h), không hardcode literal riêng.

static NSString *const kKeychainService = @"vn.gnh.mindfulkey.moodjournal";
static NSString *const kKeychainAccount = @"mood-journal-key";
#if TARGET_OS_IPHONE
static NSString *const kKeychainAccessGroup = @"vn.gnh.mindfulkey.shared"; // xem cảnh báo device-only ở đầu file
#endif

static NSString *const kConsentGrantedKey = @"moodJournalConsentGranted";
static NSString *const kConsentAskedKey   = @"moodJournalConsentAsked";

static const NSUInteger kKeySize = 32;      // AES-256
static const NSUInteger kEventSize = 16;    // 8B ts (int64 LE) + 8B sendRisk (double, bit pattern LE)
static NSString *const kJournalFileName = @"mood-journal.enc";

#pragma mark - Đường dẫn file (App Group container — KHÁC MoodStoreMac dùng Application Support riêng)

// Trả về container App Group thật. nil nếu tiến trình KHÔNG có entitlement App Group đúng (trên
// iOS thật: thiếu/sai `com.apple.security.application-groups`). Đã verify thực nghiệm: trên host
// test macOS (binary KHÔNG ký), containerURLForSecurityApplicationGroupIdentifier: vẫn trả về 1
// URL hợp lệ dưới ~/Library/Group Containers/<id>/ (macOS không ép entitlement cho tiến trình
// unsandboxed) — nên host test chạy được với đúng API thật, KHÔNG cần fallback riêng.
static NSURL *_Nullable AppGroupContainerURL(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupSuiteName];
}

static NSURL *_Nullable JournalFileURL(void) {
    NSURL *container = AppGroupContainerURL();
    if (container == nil) {
        return nil; // entitlement thiếu/sai -> im lặng bỏ qua (đúng triết lý AppGroupBridge)
    }
    NSError *mkdirError = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:container
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&mkdirError];
    return [container URLByAppendingPathComponent:kJournalFileName];
}

#pragma mark - Khóa mã hóa (Keychain, chia sẻ qua keychain-access-groups trên iOS thật)

static NSMutableDictionary *KeychainBaseQuery(void) {
    NSMutableDictionary *q = [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount,
    } mutableCopy];
#if TARGET_OS_IPHONE
    q[(__bridge id)kSecAttrAccessGroup] = kKeychainAccessGroup;
#endif
    return q;
}

static NSData *_Nullable LoadKeyFromKeychain(void) {
    NSMutableDictionary *query = KeychainBaseQuery();
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess && result) {
        return (__bridge_transfer NSData *)result;
    }
    return nil;
}

static NSData *_Nullable CreateAndStoreKey(void) {
    uint8_t bytes[kKeySize];
    if (SecRandomCopyBytes(kSecRandomDefault, kKeySize, bytes) != errSecSuccess)
        return nil;
    NSData *key = [NSData dataWithBytes:bytes length:kKeySize];

    NSMutableDictionary *attrs = KeychainBaseQuery();
    attrs[(__bridge id)kSecValueData] = key;
    attrs[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;

    SecItemDelete((__bridge CFDictionaryRef)KeychainBaseQuery());
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attrs, NULL);
    if (status != errSecSuccess)
        return nil;
    return key;
}

static NSData *_Nullable MoodJournalKey(void) {
    NSData *key = LoadKeyFromKeychain();
    if (key)
        return key;
    return CreateAndStoreKey();
}

#pragma mark - AES-256-CBC (CommonCrypto) — IV ngẫu nhiên gắn đầu ciphertext (giống MoodStoreMac.mm)

static NSData *_Nullable AESEncrypt(NSData *plaintext, NSData *key) {
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

static NSData *_Nullable AESDecrypt(NSData *blob, NSData *key) {
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

#pragma mark - (De)serialize event 16 byte: 8B ts (int64 LE) + 8B sendRisk (double bit-pattern LE)

static void PackEvent(uint8_t out[kEventSize], int64_t ts, double risk) {
    uint64_t tsBits = (uint64_t)ts;
    uint64_t riskBits = 0;
    memcpy(&riskBits, &risk, sizeof(riskBits));
    for (int i = 0; i < 8; i++) {
        out[i]     = (uint8_t)(tsBits >> (8 * i));
        out[8 + i] = (uint8_t)(riskBits >> (8 * i));
    }
}

static void UnpackEvent(const uint8_t in[kEventSize], int64_t *outTs, double *outRisk) {
    uint64_t tsBits = 0, riskBits = 0;
    for (int i = 0; i < 8; i++) {
        tsBits   |= ((uint64_t)in[i])     << (8 * i);
        riskBits |= ((uint64_t)in[8 + i]) << (8 * i);
    }
    *outTs = (int64_t)tsBits;
    memcpy(outRisk, &riskBits, sizeof(riskBits));
}

#pragma mark - Đọc/ghi buffer plaintext (giải mã file .enc -> buffer, append, mã hóa lại -> ghi đè)

// Trả buffer plaintext hiện có (rỗng nếu chưa có file/giải mã lỗi) — KHÔNG bao giờ trả nil, để
// caller luôn append được vào 1 NSMutableData hợp lệ.
static NSData *ReadPlaintextBuffer(NSURL *fileURL, NSData *key) {
    NSData *encrypted = [NSData dataWithContentsOfURL:fileURL];
    if (!encrypted)
        return [NSData data];
    NSData *plain = AESDecrypt(encrypted, key);
    return plain ?: [NSData data];
}

static BOOL WriteEncryptedBuffer(NSData *plaintext, NSURL *fileURL, NSData *key) {
    NSData *encrypted = AESEncrypt(plaintext, key);
    if (!encrypted)
        return NO;
    return [encrypted writeToURL:fileURL atomically:YES];
}

static void AppendEvent(int64_t ts, double sendRisk) {
    NSData *key = MoodJournalKey();
    if (!key)
        return; // Keychain lỗi (hiếm) -> bỏ qua lần ghi này, không crash bàn phím
    NSURL *fileURL = JournalFileURL();
    if (!fileURL)
        return; // App Group container không mở được -> im lặng bỏ qua

    NSMutableData *buffer = [ReadPlaintextBuffer(fileURL, key) mutableCopy];
    uint8_t event[kEventSize];
    PackEvent(event, ts, sendRisk);
    [buffer appendBytes:event length:kEventSize];

    WriteEncryptedBuffer(buffer, fileURL, key);
}

#pragma mark - Consent (App Group suite defaults — CẢ extension lẫn container đều thấy)

BOOL MoodJournalStore_HasConsent(void) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupSuiteName];
    if (shared == nil)
        return NO; // suite không mở được -> mặc định an toàn: KHÔNG consent
    return [shared boolForKey:kConsentGrantedKey];
}

void MoodJournalStore_SetConsent(BOOL granted) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupSuiteName];
    if (shared != nil) {
        [shared setBool:granted forKey:kConsentGrantedKey];
        [shared setBool:YES forKey:kConsentAskedKey];
    }
    if (!granted) {
        MoodJournalStore_DeleteAll();
    }
}

BOOL MoodJournalStore_HasAskedConsent(void) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupSuiteName];
    if (shared == nil)
        return NO;
    return [shared boolForKey:kConsentAskedKey];
}

#pragma mark - Ghi

void MoodJournalStore_LogTenseMoment(double sendRisk) {
    if (!MoodJournalStore_HasConsent())
        return; // chưa đồng ý -> không tạo file, không ghi gì cả
    int64_t ts = (int64_t)[[NSDate date] timeIntervalSince1970];
    AppendEvent(ts, sendRisk);
}

#pragma mark - Tóm tắt hôm nay

NSDictionary<NSString *, NSNumber *> *MoodJournalStore_FetchTodaySummary(void) {
    NSMutableDictionary<NSString *, NSNumber *> *summary = [NSMutableDictionary dictionary];
    summary[@"tenseCount"] = @0;
    summary[@"peakHour"] = @(-1);

    NSData *key = MoodJournalKey();
    NSURL *fileURL = JournalFileURL();
    if (!key || !fileURL)
        return summary;

    NSData *plaintext = ReadPlaintextBuffer(fileURL, key);
    if (plaintext.length < kEventSize)
        return summary; // rỗng hoặc hỏng -> tóm tắt rỗng, không crash

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startOfDay = [cal startOfDayForDate:now];
    NSDate *startOfTomorrow = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];
    int64_t tsFrom = (int64_t)[startOfDay timeIntervalSince1970];
    int64_t tsTo   = (int64_t)[startOfTomorrow timeIntervalSince1970];

    int total = 0;
    NSMutableDictionary<NSNumber *, NSNumber *> *byHour = [NSMutableDictionary dictionary];

    const uint8_t *bytes = (const uint8_t *)plaintext.bytes;
    NSUInteger eventCount = plaintext.length / kEventSize;
    for (NSUInteger i = 0; i < eventCount; i++) {
        int64_t ts = 0;
        double risk = 0.0;
        UnpackEvent(bytes + i * kEventSize, &ts, &risk);
        (void)risk; // schema không có trường nào khác để tổng hợp ngoài đếm + giờ

        if (ts < tsFrom || ts >= tsTo)
            continue;
        total++;

        NSDateComponents *comps = [cal components:NSCalendarUnitHour
                                          fromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)ts]];
        NSNumber *hourKey = @(comps.hour);
        byHour[hourKey] = @(byHour[hourKey].integerValue + 1);
    }

    int peakHour = -1, peakHourCount = 0;
    for (NSNumber *hour in byHour) {
        if ((int)byHour[hour].integerValue > peakHourCount) {
            peakHourCount = (int)byHour[hour].integerValue;
            peakHour = hour.intValue;
        }
    }

    summary[@"tenseCount"] = @(total);
    summary[@"peakHour"] = @(peakHour);
    return summary;
}

#pragma mark - Xóa toàn bộ

void MoodJournalStore_DeleteAll(void) {
    NSURL *fileURL = JournalFileURL();
    if (fileURL) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
    // Xóa luôn khóa Keychain — nếu còn sót file nào đó (không nên xảy ra), nó sẽ không thể giải mã
    // được nữa (mirror MoodStoreMac_DeleteAll).
    SecItemDelete((__bridge CFDictionaryRef)KeychainBaseQuery());
}

#pragma mark - CHỈ DÙNG TRONG TEST

void MoodJournalStore_LogTenseMomentAtForTesting(double sendRisk, int64_t ts) {
    if (!MoodJournalStore_HasConsent())
        return; // giữ ĐÚNG bất biến riêng tư: kể cả đường test cũng không bỏ qua cổng consent
    AppendEvent(ts, sendRisk);
}

NSURL *_Nullable MoodJournalStore_FileURLForTesting(void) {
    return JournalFileURL();
}

void MoodJournalStore_ResetForTesting(void) {
    MoodJournalStore_DeleteAll();
    // Xóa CHÍNH XÁC 2 khoá consent của kho này — KHÔNG removePersistentDomainForName: toàn bộ
    // suite group.vn.gnh.mindfulkey (suite đó còn được BellReminderSettingsBridge/
    // KeyboardSettingsBridge/MacroBridge dùng chung — xoá sạch domain sẽ ảnh hưởng dữ liệu của
    // chúng nếu tình cờ tồn tại trên máy đang chạy test).
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupSuiteName];
    [shared removeObjectForKey:kConsentGrantedKey];
    [shared removeObjectForKey:kConsentAskedKey];
}
