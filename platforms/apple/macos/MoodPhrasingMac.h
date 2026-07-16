//
//  MoodPhrasingMac.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] 2026-07-16 — 1 NGUỒN cho "đọc mặt hồ thành câu chữ": ranh giới buổi + ngưỡng gợn +
//  câu tóm tắt hình dạng ngày.
//
//  Vì sao phải có file này: ranh giới buổi ĐÃ nằm ở 2 nơi — `TimeOfDayLabel()` (ReflectionScreenMac.mm)
//  và `kAxisHour*` (EmotionRiverView.mm) — và chính code ở đó đã tự cảnh báo: *"Hai nơi phải cùng một
//  ranh giới, lệch là màn Soi lại nói 'buổi sáng' mà chấm nằm chỗ khác."* Thẻ Gác cổng nay cũng cần
//  đọc buổi → sắp thành bản thứ BA. Gom về đây trước khi kịp trôi lệch.
//
//  Ràng buộc HIẾN CHƯƠNG khoá trong file này:
//    - Câu chữ QUAN SÁT, không phán xét: mô tả mặt hồ đang thế nào, KHÔNG khen/chê người dùng.
//    - KHÔNG số thô ra UI (biên độ 0.73 là chuyện nội bộ) — chỉ mô tả bằng lời.
//    - Số nhịp chuông KHÔNG phải điểm số / chuỗi-ngày-liên-tục: nó nói APP lấy được bao nhiêu mẫu
//      (độ dày dữ liệu đỡ cho câu nhận xét), KHÔNG phải "bạn đã làm được N việc". Tuyệt đối không
//      kèm mục tiêu, không so với hôm qua, không khen khi nhiều / trách khi ít.
//

#ifndef MoodPhrasingMac_h
#define MoodPhrasingMac_h

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Ngưỡng "coi là có gợn". Dùng CHUNG cho mọi câu mô tả — lệch ngưỡng giữa 2 màn là chúng nói
/// ngược nhau về cùng một ngày.
///
/// [MINDFUL] 2026-07-16 — TỪNG là hằng số cứng 0.4, và đó là một lời nói dối: người dùng có nút
/// "Độ nhạy" (Ít nhạy/Vừa/Nhạy → 0.6/0.5/0.4) mà mọi câu chữ đều phớt lờ, chỉ CHUÔNG mới nghe.
/// Để "Ít nhạy" thì chuông coi 0.6 mới là gợn, còn câu chữ vẫn phán "có gợn" từ 0.4 → chuông im
/// mà chữ vẫn nói có gợn. Nay đọc thẳng lựa chọn của người dùng, cùng nguồn với chuông.
double MoodPhrasing_RippleThreshold(void);

/// "buổi sáng" (5-11) · "buổi trưa" (11-13) · "buổi chiều" (13-18) · "buổi tối" (còn lại).
NSString *MoodPhrasing_TimeOfDayLabel(long long epochSeconds);

/// Câu đọc HÌNH DẠNG cả ngày từ mẫu hôm nay, vd "Sáng và chiều có gợn, phần lớn êm".
/// @param todaySamples dạng `MoodStoreMac_FetchTodaySamples()` trả về (`{@"ts", @"value"}`).
/// Rỗng → câu thật thà "chưa đủ nhịp để nói", KHÔNG bịa ra nhận xét từ hư không.
NSString *MoodPhrasing_DayShapeSentence(NSArray<NSDictionary *> *todaySamples);

#ifdef __cplusplus
}
#endif

#endif /* MoodPhrasingMac_h */
