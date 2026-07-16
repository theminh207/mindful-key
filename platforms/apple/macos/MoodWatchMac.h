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
double MoodWatchMac_LastSendRisk(void);
void MoodWatchMac_Flush(void);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include <string>
void MoodWatchMac_OnWord(const std::wstring& word);
#endif

#endif /* MoodWatchMac_h */
