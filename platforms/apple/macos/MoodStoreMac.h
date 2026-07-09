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

#ifdef __cplusplus
}
#endif

#endif /* MoodStoreMac_h */
