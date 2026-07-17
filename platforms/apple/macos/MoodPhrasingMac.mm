//
//  MoodPhrasingMac.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Xem MoodPhrasingMac.h cho lý do tồn tại + ràng buộc hiến chương.
//
//  [MINDFUL] 2026-07-17 — LOGIC + CÂU CHỮ đã dời sang `core/mood/MoodPhrasing` (C++ thuần). File
//  này nay chỉ còn là lớp BỌC: đổi NSArray/NSDictionary <-> vector<MoodSample>, wstring <->
//  NSString, và đưa ngưỡng độ nhạy vào.
//
//  Vì sao dời: chính comment cũ ở đây đã tự cảnh báo "giữ bản chép riêng là sắp có 3 bản trôi lệch
//  nhau" — đúng, nhưng nó chỉ gom về tới ranh giới vỏ macOS. Vỏ Windows tới lượt mình vẫn phải
//  chép lại, thành đúng cái vừa đi sửa. Đây là lần THỨ BA dự án gặp mô hình này (lexicon
//  send-risk, bảng màu brand, nay câu chữ) — nên lần này gom về `core/` để hết đường lặp lại.
//
//  Hành vi KHÔNG đổi: đã đối chiếu bản core cạnh bản cũ trong cùng 1 binary, 18/18 ca trùng khít
//  (gồm ca đúng biên ngưỡng + mọi ranh giới giờ). Khoá bằng tests/core/test_phrasing.cpp.
//

#import "MoodPhrasingMac.h"
#import "NudgeCoordinatorMac.h"
#include "MoodPhrasing.h"

// [MINDFUL] 2026-07-16 — xem hợp đồng ở .h. Uỷ thác cho NudgeCoordinatorMac: nơi đó ĐÃ đọc
// vBellSensitivity cho chuông từ story 1.5. Tự đọc lại UserDefaults ở đây = nguồn thứ 2, sớm muộn
// lệch — mà lệch ở đây nghĩa là chuông và câu chữ nói ngược nhau về cùng một ngày.
//
// Đây cũng là lý do `core/mood/MoodPhrasing` NHẬN ngưỡng qua tham số thay vì tự đọc: cài đặt nằm
// ở UserDefaults (Apple) / registry (Windows), `core/` không được biết tới hai thứ đó.
double MoodPhrasing_RippleThreshold(void) {
    return NudgeCoordinatorMac_RippleThreshold();
}

static NSString *NSStringFromWide(const std::wstring &w) {
    return [[NSString alloc] initWithBytes:w.data()
                                    length:w.size() * sizeof(wchar_t)
                                  encoding:NSUTF32LittleEndianStringEncoding];
}

NSString *MoodPhrasing_TimeOfDayLabel(long long epochSeconds) {
    return NSStringFromWide(MoodPhrasingCore_TimeOfDayLabel(epochSeconds));
}

NSString *MoodPhrasing_DayShapeSentence(NSArray<NSDictionary *> *todaySamples) {
    std::vector<MoodSample> samples;
    samples.reserve(todaySamples.count);
    for (NSDictionary *s in todaySamples) {
        MoodSample m;
        m.ts = [s[@"ts"] longLongValue];
        m.value = [s[@"value"] doubleValue];
        samples.push_back(m);
    }
    return NSStringFromWide(MoodPhrasingCore_DayShapeSentence(samples, MoodPhrasing_RippleThreshold()));
}
