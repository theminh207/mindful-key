//
//  ReflectionScreenMac.h
//  ModernKey
//
//  [MINDFUL] Bước 8 — màn soi lại cuối ngày. Đọc MoodStoreMac_FetchTodaySummary(), hiện 1 câu
//  phản chiếu (không phán xét) + 1 gợi ý nhỏ. Thiết kế để TỰ NHẬN RA, không phải thống kê cho
//  vui — số liệu chỉ là bối cảnh phụ, câu hỏi phản chiếu mới là trọng tâm.
//

#ifndef ReflectionScreenMac_h
#define ReflectionScreenMac_h

#ifdef __cplusplus
extern "C" {
#endif

// Hiện màn soi lại (NSAlert non-blocking-ish, gọi từ menu "Soi lại hôm nay...").
void ReflectionScreenMac_Show(void);

#ifdef __cplusplus
}
#endif

#endif /* ReflectionScreenMac_h */
