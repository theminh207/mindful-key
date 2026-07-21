//
// SendGatekeeper.h — [MINDFUL] Feature #1: người gác cổng gửi tin, bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
// Đối ứng của platforms/apple/macos/SendGatekeeperMac.{h,mm} — bản macOS là CHUẨN HÀNH VI.
// Bắt Enter-không-Shift trong app người dùng đã thêm vào danh sách, nếu send-risk vượt ngưỡng
// thì NUỐT phím Enter đó và hiện một nhịp thở. Quyết định "khi nào hiện / hiện chữ gì" nằm ở
// core/mood/BreathingPause (C++ thuần, dùng chung) — file này chỉ lo bắt phím và vẽ.
//
// CAM KẾT KHÔNG CHẶN CỨNG (BreathingPause.h): "Vẫn gửi" phải gửi được NGAY. Overlay chỉ là ma
// sát mềm — quyền quyết định luôn thuộc người dùng.
//
// KHÁC bản macOS ở 2 chỗ, cố ý:
//   1. Danh sách app: macOS hardcode bundle id đã xác minh trên máy dev. Máy dev của dự án là
//      macOS nên KHÔNG xác minh được tên tiến trình Windows (Zalo.exe? ZaloPC.exe?) — và luật
//      dự án cấm bịa "reasonable default". Nên: danh sách RỖNG lúc đầu, người dùng tự thêm app
//      đang mở qua menu khay. Không ai phải đoán, kể cả người dùng.
//   2. Hộp thoại LẤY focus (macOS dùng NSPanel không cướp focus). Đổi lại "Đợi chút" là nút mặc
//      định, nên bấm Enter theo quán tính = chọn dừng lại, không phải gửi.
//
#pragma once
#include <windows.h>
#include <string>

// [MINDFUL] 2026-07-19 (port từ macOS SendGatekeeperMac.h) — công tắc bật/tắt gác cổng gửi tin
// (Feature #1). MẶC ĐỊNH BẬT (=1). Tắt = ShouldIntercept luôn trả false (không chặn Enter, không
// hiện màn Nhịp thở), nhưng lớp cảm xúc/nhật ký/sông VẪN chạy độc lập (do vMoodWatch quản). Nạp từ
// registry "vSendGatekeeper" trong MindfulKeyInit, đổi qua menu khay "Gác cổng gửi tin (nhịp thở)".
extern int vSendGatekeeper;

// Gọi 1 lần lúc khởi động (nạp danh sách app từ registry).
void SendGatekeeper_Init();

// Gọi từ keyboardHookProcess. true = NUỐT phím Enter này và hiện nhịp thở.
// CHẠY TRÊN LUỒNG HOOK — chỉ so sánh trong RAM, không I/O, không chờ.
bool SendGatekeeper_ShouldIntercept(WPARAM wParam, const KBDLLHOOKSTRUCT* key);

// Hiện nhịp thở (tự đẩy sang luồng riêng — hộp thoại chặn luồng gọi nó).
void SendGatekeeper_ShowPause();

// ── Menu khay: thêm/bỏ app ĐANG DÙNG khỏi danh sách gác cổng ──
// Dùng MindfulKeyHelper::getLastAppExecuteName() — nó nhớ app trước khi người dùng bấm vào cửa sổ
// bộ gõ, nên "app đang dùng" ở đây là app chat, không phải chính mình.
std::wstring SendGatekeeper_LastAppName();
bool SendGatekeeper_IsAppWatched(const std::wstring& exeName);
void SendGatekeeper_ToggleLastApp();
