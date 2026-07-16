//
//  MoodStoreMac.h
//  ModernKey
//
//  [MINDFUL] Bước 6 — kho nhật ký cảm xúc: LOCAL, MÃ HÓA (AES-256-CBC, khóa trong Keychain),
//  KHÔNG BAO GIỜ chứa văn bản gốc — schema không có cột nào chứa câu chữ, nên không thể lưu
//  nhầm dù có bug. Xem docs/PRIVACY-NOTE.md + docs/PRD.md §5.
//

#ifndef MoodStoreMac_h
#define MoodStoreMac_h

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif

// Đồng ý (consent) — mặc định NO cho tới khi người dùng chủ động bật. Nếu chưa đồng ý,
// MoodStoreMac_LogGatekeeperEvent không ghi gì cả (không tạo file, không âm thầm log).
BOOL MoodStoreMac_HasConsent(void);
void MoodStoreMac_SetConsent(BOOL granted);
BOOL MoodStoreMac_HasAskedConsent(void); // đã từng hỏi chưa — tránh hỏi lại mỗi lần khởi động

// Hiện dialog xin phép 1 lần đầu tiên (idempotent — gọi nhiều lần chỉ hỏi 1 lần thật).
// An toàn gọi từ bất kỳ đâu; tự bỏ qua nếu đã từng hỏi rồi.
void MoodStoreMac_AskConsentIfNeeded(void);

// Ghi 1 sự kiện gác cổng gửi tin (bước 5): điểm risk + app + lựa chọn người dùng.
// Không làm gì (kể cả không tạo file) nếu chưa có consent.
void MoodStoreMac_LogGatekeeperEvent(double sendRisk, NSString *appBundleID, NSString *choice);

// Xóa TOÀN BỘ nhật ký local (không thể hoàn tác) — dùng khi người dùng thu hồi consent hoặc
// chủ động bấm "Xóa nhật ký" trong app.
void MoodStoreMac_DeleteAll(void);

// [MINDFUL] Bước 8 — tóm tắt sự kiện gác cổng TRONG NGÀY HÔM NAY (giờ địa phương), cho màn
// soi lại cuối ngày. Trả NSDictionary thay vì danh sách thô — màn soi lại chỉ cần tổng hợp,
// không phải xem từng dòng (tránh biến thành "thống kê cho vui"). Key:
//   "gatekeeperCount" (NSNumber int), "sendAnywayCount" (NSNumber int), "waitCount" (NSNumber int),
//   "peakHour" (NSNumber int, -1 nếu chưa có dữ liệu), "topAppBundleID" (NSString hoặc nil).
NSDictionary *MoodStoreMac_FetchTodaySummary(void);

// [MINDFUL] Story 2.3 — lấy mẫu định kỳ và check-in tự nguyện
void MoodStoreMac_LogSampleEvent(double avgAmplitude);
NSArray<NSDictionary *> *MoodStoreMac_FetchTodaySamples(void);

// [MINDFUL] 2026-07-16 — mẫu trong `secondsAgo` giây gần nhất, cửa sổ TRƯỢT tính từ BÂY GIỜ (khác
// FetchTodaySamples: cái đó cắt theo mốc nửa đêm). Dùng cho "Ngay bây giờ" (zoom-in 6 tiếng) — cửa
// sổ này VẮT QUA NỬA ĐÊM được, đúng thứ FetchTodaySamples không làm nổi. Cùng dạng trả về:
// {@"ts": epoch giây, @"value": biên độ 0..1}, xếp tăng dần theo ts.
NSArray<NSDictionary *> *MoodStoreMac_FetchSamplesSince(double secondsAgo);
void MoodStoreMac_LogCheckinEvent(NSInteger waveLevel);

// [MINDFUL] Story 3.7/3.8 — dòng sông theo Tuần/Tháng. Mỗi phần tử: {"day": NSString "yyyy-MM-dd",
// "value": NSNumber 0..1 (trung bình send_risk trong ngày) HOẶC NSNull (ngày đó 0 mẫu — quãng
// trống thật, KHÔNG nội suy)}. Luôn trả đủ N phần tử theo thứ tự cũ→mới (kể cả ngày thiếu dữ
// liệu) — caller KHÔNG cần tự phát hiện gap như FetchTodaySamples (bài học: gap-detection từng
// bị lặp lại ở 2 caller khác nhau cho FetchTodaySamples, story 3.7 tránh lặp lại lần 3).
NSArray<NSDictionary *> *MoodStoreMac_FetchWeekSamples(void);   // 7 ngày gần nhất, tính cả hôm nay
NSArray<NSDictionary *> *MoodStoreMac_FetchMonthSamples(void);  // 30 ngày gần nhất, tính cả hôm nay

#if DEBUG
// [MINDFUL] 2026-07-16 — CHỈ tồn tại trong build Debug (biến mất hoàn toàn khỏi bản Release/phát
// hành, xem project.yml GCC_PREPROCESSOR_DEFINITIONS). Giả lập dữ liệu sông để test hiển thị
// Tuần/Tháng mà không cần chờ dùng thật nhiều ngày — chủ dự án đã chốt cách làm (2026-07-16):
// ghi thẳng vào ĐÚNG kho thật (không có kho nháp riêng) nhưng đánh dấu ẩn ở cột app_bundle_id
// (vốn không dùng cho event 'sample'), để tách biệt khỏi dữ liệu thật.
// MoodStoreMac_DeleteSimulatedData() CHỈ xóa đúng phần đánh dấu này — dữ liệu thật không đụng tới.
void MoodStoreMac_SeedFakeSamplesForTesting(NSInteger numDays);
void MoodStoreMac_DeleteSimulatedData(void);
BOOL MoodStoreMac_HasSimulatedData(void);
#endif

// [MINDFUL] Story 2.6 — Riêng tư
BOOL MoodStoreMac_ExportCSVToURL(NSURL *url);
void MoodStoreMac_SetAutoPurgeDays(NSInteger days);
NSInteger MoodStoreMac_AutoPurgeDays(void);
void MoodStoreMac_RunAutoPurgeIfNeeded(void);

#ifdef __cplusplus
}
#endif

#endif /* MoodStoreMac_h */
