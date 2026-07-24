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
// [MINDFUL] 2026-07-20 — dict giờ có thêm key thứ 3 "checkin" (NSNumber BOOL): YES = điểm này đến
// từ câu trả lời tự thuật "Mặt hồ đang thế nào?" (LogCheckinEvent), quy đổi sang cùng thang biên
// độ 0-1; NO = tự tính từ chữ gõ (send_risk), như trước giờ. Gộp 2 nguồn vào ĐÂY (không phải ở
// tầng vẽ) để mọi nơi đọc mẫu — "Ngay bây giờ", "Hôm nay", "Soi lại" — đều thấy đủ cả 2, không
// còn cảnh trả lời xong rồi biến mất khỏi mọi màn hình. Tắt được qua cờ vShowCheckinOnRiver.
// TUẦN/THÁNG (FetchWeekSamples/FetchMonthSamples) CHƯA gộp — đó là trung bình theo NGÀY (1 chấm =
// 1 ngày), khái niệm "chấm này tự thuật hay tự đoán" không còn ý nghĩa ở granularity đó; để ngỏ,
// xem docs/FRICTION-LOG.md 2026-07-20.
NSArray<NSDictionary *> *MoodStoreMac_FetchTodaySamples(void);

// [MINDFUL] 2026-07-16 — mẫu trong `secondsAgo` giây gần nhất, cửa sổ TRƯỢT tính từ BÂY GIỜ (khác
// FetchTodaySamples: cái đó cắt theo mốc nửa đêm). Dùng cho "Ngay bây giờ" (zoom-in 6 tiếng) — cửa
// sổ này VẮT QUA NỬA ĐÊM được, đúng thứ FetchTodaySamples không làm nổi. Cùng dạng trả về (xem
// key "checkin" ở chú thích FetchTodaySamples ngay trên):
// {@"ts": epoch giây, @"value": biên độ 0..1, @"checkin": BOOL}, xếp tăng dần theo ts.
NSArray<NSDictionary *> *MoodStoreMac_FetchSamplesSince(double secondsAgo);
void MoodStoreMac_LogCheckinEvent(NSInteger waveLevel);

// [MINDFUL] 2026-07-20 — công tắc gộp check-in tự thuật vào sông. Mặc định BẬT (=1): sửa đúng lỗ
// "trả lời xong biến mất" người dùng phát hiện. Tắt = sông chỉ vẽ từ chữ gõ (send_risk) như bản
// cũ, cho ai thấy trộn 2 nguồn là rối. Đổi qua menu khay "Hiện chấm tự đánh giá trên sông".
extern int vShowCheckinOnRiver;

// [MINDFUL] Story 3.7/3.8 — dòng sông theo Tuần/Tháng. Mỗi phần tử: {"day": NSString "yyyy-MM-dd",
// "value": NSNumber 0..1 (trung bình send_risk trong ngày) HOẶC NSNull (ngày đó 0 mẫu — quãng
// trống thật, KHÔNG nội suy)}. Luôn trả đủ N phần tử theo thứ tự cũ→mới (kể cả ngày thiếu dữ
// liệu) — caller KHÔNG cần tự phát hiện gap như FetchTodaySamples (bài học: gap-detection từng
// bị lặp lại ở 2 caller khác nhau cho FetchTodaySamples, story 3.7 tránh lặp lại lần 3).
NSArray<NSDictionary *> *MoodStoreMac_FetchWeekSamples(void);   // 7 ngày gần nhất, tính cả hôm nay
NSArray<NSDictionary *> *MoodStoreMac_FetchMonthSamples(void);  // 30 ngày gần nhất, tính cả hôm nay

// [MINDFUL] H2 (2026-07-24) — TRƯỚC ở `#if DEBUG` (ẩn khỏi Release). Nay PHƠI cả bản Release vì chủ
// dự án cần bơm dữ liệu mẫu để test biểu đồ Ngày/Tuần/Tháng trên bản đã cài (giống Windows F6). Ghi
// thẳng vào ĐÚNG kho thật nhưng đánh dấu ẩn ở cột app_bundle_id (không dùng cho 'sample') để tách
// khỏi dữ liệu thật; DeleteSimulatedData chỉ xóa đúng phần đánh dấu. ⚠️ FRICTION-LOG: ẩn/bỏ trước 1.0.
void MoodStoreMac_SeedFakeSamplesForTesting(NSInteger numDays);  // numDays ngày (vd 7 = 1 tuần, 30 = tháng)
// 1 ngày 12-18h chấm DÀY (~8 phút/mẫu) để test sông live "Ngay bây giờ". Cùng marker nên dọn chung.
void MoodStoreMac_SeedDenseDayForTesting(void);
void MoodStoreMac_DeleteSimulatedData(void);
BOOL MoodStoreMac_HasSimulatedData(void);

#pragma mark - Ô ghi cảm nhận cuối ngày (daily note)

// [MINDFUL] Hợp đồng đầy đủ: `bmad-output/_shared/DECISION-daily-note-v1.md`. Tóm tắt ràng buộc CỨNG:
//   · Đây là LẦN ĐẦU app lưu CHỮ THẬT người dùng gõ — tới giờ kho chỉ có số suy ra. Threat model đổi hẳn.
//   · Nội dung mã hoá RIÊNG từng ghi chú (field-level), KHÔNG chỉ dựa vào mã hoá cả file (chốt
//     2026-07-16): mỗi lần đọc/ghi, cả kho bị giải mã ra 1 file tạm plaintext trên đĩa — nhật ký chữ
//     nằm đó dạng đọc được là không chấp nhận được. iOS kế thừa cùng giao ước.
//   · Consent RIÊNG, tách khỏi consent nhật ký-số. Hỏi 1 lần, khi người dùng lần đầu CHẠM vào ô ghi.
//   · CẤM TUYỆT ĐỐI chạy sentiment/model lên nội dung note. Note chỉ cho con người đọc.
//   · KHÔNG nằm trong CSV export mặc định.
//   · v1 CHỈ note HÔM NAY (ghi + sửa trong ngày). Đọc lại ngày cũ = đợt sau (chốt 2026-07-16).

BOOL MoodStoreMac_HasNoteConsent(void);
void MoodStoreMac_SetNoteConsent(BOOL granted);   // NO = xoá sạch mọi ghi chú đã lưu
BOOL MoodStoreMac_HasAskedNoteConsent(void);

// Lưu ô ghi HÔM NAY. 1 note/ngày — gọi nhiều lần trong ngày = SỬA, không đẻ thêm dòng.
// Chuỗi rỗng/nil = xoá ghi chú hôm nay (người dùng xoá hết chữ = rút lại, phải tôn trọng).
// Không làm gì nếu chưa có consent riêng cho ô ghi.
// `question` = câu hỏi hôm đó, lưu NGUYÊN VĂN kèm note (§2.6 "gắn ngày + câu hỏi hôm đó") để lúc
// đọc lại còn biết dòng chữ này đang trả lời cái gì. nil được — note cũ không có, màn đọc lại chịu
// được thiếu. Xem lý do "nguyên văn thay vì suy lại" ở chỗ INSERT trong .mm.
void MoodStoreMac_SaveNoteForToday(NSString *text, NSString *question);

// nil nếu hôm nay chưa ghi gì (hoặc chưa consent). KHÔNG BAO GIỜ trả chuỗi rỗng thay cho nil.
NSString *MoodStoreMac_FetchNoteForToday(void);

// [MINDFUL] 2026-07-16 — "chồng ghi chú": mọi ngày CÓ chữ, mới nhất trước. Ngày không viết KHÔNG
// xuất hiện (§2.4 "Trống = im lặng" — không ô trống, không chỗ để thấy "mình bỏ lỡ").
// Mỗi phần tử: {@"ts": NSNumber epoch giây, @"text": NSString, @"question": NSString HOẶC VẮNG}.
// Trả @[] nếu chưa consent ô ghi.
NSArray<NSDictionary *> *MoodStoreMac_FetchAllNotes(void);

// [MINDFUL] Story 2.6 — Riêng tư
BOOL MoodStoreMac_ExportCSVToURL(NSURL *url);
void MoodStoreMac_SetAutoPurgeDays(NSInteger days);
NSInteger MoodStoreMac_AutoPurgeDays(void);
void MoodStoreMac_RunAutoPurgeIfNeeded(void);

#ifdef __cplusplus
}
#endif

#endif /* MoodStoreMac_h */
