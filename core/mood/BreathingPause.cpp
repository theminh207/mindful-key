//
//  BreathingPause.cpp
//  OpenKey
//
//  [MINDFUL] Implementation of the platform-agnostic "breathing pause" contract.
//  See BreathingPause.h for the design rationale and non-blocking guarantee.
//

#include "BreathingPause.h"

const double kBreathingPauseRiskThreshold = 0.5;

static BreathingPauseChoice g_lastChoice = BreathingPauseChoice::Dismissed;

bool BreathingPause_Evaluate(double sendRisk, BreathingPausePrompt* outPrompt) {
    if (outPrompt == nullptr)
        return false;
    if (sendRisk < kBreathingPauseRiskThreshold)
        return false;

    outPrompt->sendRisk = sendRisk;
    outPrompt->durationSeconds = 3.0;
    outPrompt->message =
        L"Khoan đã — câu này nghe có thể làm tổn thương nếu gửi. Đợi một chút, hay vẫn gửi?";
    return true;
}

void BreathingPause_ReportChoice(BreathingPauseChoice choice) {
    g_lastChoice = choice;
    // [MINDFUL] Bước 6 (kho SQLite local, mã hóa) sẽ đọc/ghi từ đây thay vì biến tĩnh tạm thời này.
}

BreathingPauseChoice BreathingPause_LastChoice() {
    return g_lastChoice;
}
