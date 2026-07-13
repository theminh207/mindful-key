//
//  MoodJournalStore.h
//  mindful-key — shared (iOS container <-> keyboard extension, Round 3 story 3.1)
//
//  Kho nhật ký "khoảnh khắc căng" (tense-event) on-device, mã hóa AES-256-CBC — MƯỢN TINH THẦN
//  MoodStoreMac.mm (macOS: xem file đó cho tiền lệ crypto + consent gate) nhưng KHÁC 3 điểm kiến
//  trúc đã chốt ở bmad-output/ios/tech-spec-r3.md "Kiến trúc kho nhật ký đã chốt":
//   1. CHỈ ghi "khoảnh khắc căng" (send-risk >= NudgeCoordinatorIOS_TenseThreshold) — KHÔNG ghi
//      mọi câu như macOS — tối thiểu hóa dữ liệu triệt để hơn.
//   2. KHÔNG SQLite (tránh link thêm sqlite3 cho extension vốn đã chật RAM). Mỗi event 16 byte
//      (8B ts int64 little-endian + 8B sendRisk double) — append theo pattern macOS (giải mã toàn
//      bộ buffer -> append 16 byte -> mã hóa lại toàn bộ -> ghi đè file .enc). Dữ liệu thưa nên
//      re-encrypt cả file mỗi lần là chấp nhận được.
//   3. Extension GHI (MoodBridge.mm), container ĐỌC (màn soi lại story 3.3, sau file này) — file
//      .enc nằm trong APP GROUP CONTAINER (containerURLForSecurityApplicationGroupIdentifier:,
//      KHÔNG phải Application Support riêng của process như macOS), khóa AES trong Keychain CHIA
//      SẺ qua keychain-access-groups (xem .mm cho giới hạn host-test không verify được phần chia
//      sẻ cross-process — CHỈ verify trên thiết bị thật/Simulator).
//
//  RIÊNG TƯ (cứng — hiến chương + docs/PRIVACY-NOTE.md): schema TUYỆT ĐỐI CHỈ {ts:int64,
//  sendRisk:double}. KHÔNG trường văn bản gốc, KHÔNG app id/lựa chọn (khác macOS — iOS sandbox
//  không biết host app đang gõ ở đâu). KHÔNG NSLog/os_log nội dung gõ ở bất cứ đâu trong file này.
//
//  Consent lưu qua APP GROUP SUITE DEFAULTS (kMindfulKeyAppGroupSuiteName), KHÔNG phải
//  NSUserDefaults standard local — vì CẢ container (hỏi/hiện consent) lẫn extension (kiểm tra
//  trước khi ghi) đều phải thấy CÙNG 1 giá trị, khác MoodStoreMac (1 process macOS duy nhất nên
//  NSUserDefaults standard là đủ).
//
//  KHÔNG import UIKit/AppKit — thuần Foundation + CommonCrypto + Security, để tests/ios chạy được
//  trên host và để file dùng chung được cho cả 2 target iOS (App + KeyboardExtension) mà không lệ
//  thuộc API riêng OS (đúng pattern mọi bridge khác trong platforms/apple/shared/).
//

#ifndef MoodJournalStore_h
#define MoodJournalStore_h

#import <Foundation/Foundation.h>
#include <stdint.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

// Đồng ý (consent) — mặc định NO cho tới khi container hỏi + người dùng chủ động bật (màn hỏi
// consent thật là việc của story sau, KHÔNG phải file này — file này chỉ phơi cờ + gác cổng ghi).
FOUNDATION_EXPORT BOOL MoodJournalStore_HasConsent(void);

// SetConsent(NO) gọi luôn MoodJournalStore_DeleteAll() — mirror MoodStoreMac_SetConsent: thu hồi
// đồng ý nghĩa là XÓA SẠCH ngay, không phải "ngừng ghi thêm nhưng giữ dữ liệu cũ".
FOUNDATION_EXPORT void MoodJournalStore_SetConsent(BOOL granted);

FOUNDATION_EXPORT BOOL MoodJournalStore_HasAskedConsent(void);

// Ghi 1 "khoảnh khắc căng" tại thời điểm hiện tại. Return NGAY (không tạo file, không ghi gì) nếu
// CHƯA consent — defense-in-depth: caller (MoodBridge.mm) ĐÃ kiểm ngưỡng risk >=
// NudgeCoordinatorIOS_TenseThreshold TRƯỚC khi gọi hàm này; hàm này KHÔNG tự kiểm lại ngưỡng đó
// (tách rạch ròi: "có nên ghi" là quyết định của caller, "ghi an toàn + đúng riêng tư" là việc của
// kho). An toàn gọi từ thread nền (g_moodQueue của MoodBridge) — làm I/O đồng bộ, KHÔNG tự
// dispatch_async thêm lần nữa (caller đã ở trên serial queue riêng rồi).
FOUNDATION_EXPORT void MoodJournalStore_LogTenseMoment(double sendRisk);

// Tóm tắt "hôm nay" (giờ địa phương, NSCalendar startOfDay — mirror MoodStoreMac_FetchTodaySummary)
// cho màn soi lại (story 3.3, sau file này). Trả về đúng 2 khoá:
//   "tenseCount" (NSNumber int)  — số lần gợn sóng hôm nay.
//   "peakHour"   (NSNumber int, -1 nếu chưa có dữ liệu) — giờ (0-23, giờ địa phương) nhiều lần
//                gợn nhất.
// KHÔNG có app id / lựa chọn (khác MoodStoreMac_FetchTodaySummary) — iOS sandbox không biết host
// app đang gõ ở đâu.
FOUNDATION_EXPORT NSDictionary<NSString *, NSNumber *> *MoodJournalStore_FetchTodaySummary(void);

// Xóa TOÀN BỘ (file .enc trong App Group container + khóa Keychain) — không thể hoàn tác. Dùng
// khi SetConsent(NO) hoặc người dùng bấm "Xóa tất cả" trong màn soi lại/cài đặt.
FOUNDATION_EXPORT void MoodJournalStore_DeleteAll(void);

// ===== CHỈ DÙNG TRONG TEST (tests/ios/mood_journal_store_test.mm) =====
// KHÔNG gọi từ code sản phẩm — đúng pattern *_ForTesting đã dùng xuyên suốt repo
// (MoodBridge_FlushForTesting, NudgeCoordinatorIOS_*ForTesting, BellReminderSettingsBridge_*ForTesting).

// Ghi 1 "khoảnh khắc căng" với timestamp CHÈN TAY (thay vì [NSDate date]) — để test
// FetchTodaySummary/peakHour tất định, không phụ thuộc đồng hồ thật lúc chạy CI. VẪN gác cổng
// consent y hệt MoodJournalStore_LogTenseMoment (giữ đúng bất biến riêng tư: không đường tắt nào
// bỏ qua được cổng consent, kể cả đường test).
FOUNDATION_EXPORT void MoodJournalStore_LogTenseMomentAtForTesting(double sendRisk, int64_t ts);

// Đường dẫn file .enc thật sự đang dùng — CHỈ để test đọc raw bytes kiểm tra "không có plaintext
// trên đĩa" (AC riêng tư). KHÔNG dùng để code sản phẩm tự ý đọc/ghi file ngoài API trên.
FOUNDATION_EXPORT NSURL *_Nullable MoodJournalStore_FileURLForTesting(void);

// Dọn file + khóa Keychain + cờ consent (granted/asked) về trạng thái ban đầu ("chưa từng dùng")
// — mỗi ca test gọi hàm này TRƯỚC để không rò rỉ state giữa các ca (đúng pattern
// NudgeCoordinatorIOS_ResetStateForTesting).
FOUNDATION_EXPORT void MoodJournalStore_ResetForTesting(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END

#endif /* MoodJournalStore_h */
