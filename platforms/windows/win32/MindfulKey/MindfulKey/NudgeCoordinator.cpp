//
// NudgeCoordinator.cpp — [MINDFUL] xem NudgeCoordinator.h.
// Rút nguyên hành vi từ platforms/apple/macos/NudgeCoordinatorMac.mm (chuẩn hành vi).
//
#include "stdafx.h"
#include "NudgeCoordinator.h"

static const DWORD kCooldownMs = 45000;   // = kCooldownSeconds 45.0 bên macOS
static DWORD g_lastNudgeAt = 0;

bool NudgeCoordinator_ShouldNudge() {
    if (g_lastNudgeAt == 0)
        return true;
    // GetTickCount tràn về 0 sau ~49 ngày máy chạy liên tục. Trừ kiểu unsigned thì phép trừ vẫn
    // đúng qua chỗ tràn, nên KHÔNG so `now < g_lastNudgeAt` — làm vậy mới là chỗ sinh lỗi.
    return (GetTickCount() - g_lastNudgeAt) >= kCooldownMs;
}

void NudgeCoordinator_MarkNudged() {
    DWORD now = GetTickCount();
    g_lastNudgeAt = (now == 0) ? 1 : now;   // 0 là giá trị "chưa nhắc lần nào" — đừng đụng vào
}

int NudgeCoordinator_TenseStreakTrigger() {
    switch (MindfulKeyHelper::getRegInt(_T("vBellSensitivity"), 0)) {
    case 1:  return 5;   // Ít nhạy — cần chuỗi dài hơn mới rung
    case 3:  return 2;   // Nhạy — rung sớm hơn
    case 2:
    default: return 3;   // Vừa, gồm cả trường hợp chưa từng lưu
    }
}

double NudgeCoordinator_RippleThreshold() {
    switch (MindfulKeyHelper::getRegInt(_T("vBellSensitivity"), 0)) {
    case 1:  return 0.6; // Ít nhạy
    case 3:  return 0.4; // Nhạy
    case 2:
    default: return 0.5; // Vừa
    }
}
