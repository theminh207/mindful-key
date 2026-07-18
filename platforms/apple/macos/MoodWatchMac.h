//
//  MoodWatchMac.h
//  ModernKey
//
//  [MINDFUL] macOS shell for mood watching.
//

#ifndef MoodWatchMac_h
#define MoodWatchMac_h

#ifdef __cplusplus
extern "C" {
#endif

extern int vMoodWatch;

void MoodWatchMac_Init();
void MoodWatchMac_SetEnabled(int enabled);
int MoodWatchMac_IsEnabled();

// [MINDFUL] Send-risk: 0.0 (an toàn) .. 1.0 (nguy cơ cao nếu gửi). Cập nhật sau mỗi câu hoàn chỉnh.
// Bước 3/5 (hợp đồng "nhịp thở" + gác cổng gửi tin) sẽ đọc giá trị này để quyết định có chặn-mềm hay không.
// LƯU Ý: đây là điểm THÔ của câu cuối, KHÔNG phai theo thời gian — dùng cho quyết định chặn-mềm
// (đúng lúc bấm Enter). ĐỪNG dùng làm "đầu sóng bây giờ" của biểu đồ (sẽ cắm điểm cũ ở chỗ hiện
// tại) — cái đó dùng MoodWatchMac_LiveAmplitude() bên dưới.
double MoodWatchMac_LastSendRisk(void);
void MoodWatchMac_Flush(void);

// [MINDFUL] 2026-07-19 — "sông sống" cho thẻ "Ngay bây giờ" (batch biểu đồ cảm xúc).
// LiveAmplitude: giá trị đầu sóng "bây giờ" đã LÀM MƯỢT (EMA vài câu gần nhất) và PHAI dần về 0
//   theo thời gian im lặng. Trả -1.0 khi KHÔNG nên vẽ đầu sóng (chưa gõ gì, hoặc đã im đủ lâu ->
//   mặt hồ tự lặng, giống lúc mới mở app). GatekeeperCardView truyền thẳng vào liveHead.
// FetchLiveTrace: vệt điểm DÀY trong RAM (tối đa ~1 điểm/30s khi có gõ), KHÔNG persist (nhật ký
//   mã hoá vẫn nhịp thưa như cũ — riêng-tư-mặc-định). Đã trộn nền quá khứ từ kho persisted cho
//   phần TRƯỚC khi phiên này bắt đầu. Idle = không thêm điểm (nhịp không gõ != ghi 0, hiến chương dec.4).
double MoodWatchMac_LiveAmplitude(void);
NSArray<NSDictionary *> *MoodWatchMac_FetchLiveTrace(double windowSeconds);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include <string>
void MoodWatchMac_OnWord(const std::wstring& word);
#endif

#endif /* MoodWatchMac_h */
