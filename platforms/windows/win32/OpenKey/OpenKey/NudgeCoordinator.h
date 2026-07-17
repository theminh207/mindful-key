//
// NudgeCoordinator.h — [MINDFUL] gộp mọi lời nhắc vào MỘT mạch, bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
//
// Đối ứng của platforms/apple/macos/NudgeCoordinatorMac.{h,mm} — bản macOS là CHUẨN HÀNH VI.
//
// VÌ SAO CÓ: app có 2 nguồn nhắc (chuông theo nhịp + nhắc thụ động khi gõ câu căng). Không có
// bộ điều phối thì cùng một khoảnh khắc người dùng ăn 2 lời nhắc chồng nhau — đó là HỐI THÚC,
// thứ HIẾN CHƯƠNG cấm. 45 giây nghỉ chung cho mọi nguồn.
//
// CỐ Ý KHÔNG áp cho gác cổng gửi tin (SendGatekeeper): đó là Feature #1, phải hiện MỌI LẦN đủ
// điều kiện. Nó không phải lời nhắc — nó là chốt chặn ở đúng khoảnh khắc gửi.
//
#pragma once

// true = được phép nhắc (đã qua 45s kể từ lần nhắc gần nhất, bất kể nguồn nào).
bool NudgeCoordinator_ShouldNudge();

// Gọi NGAY sau khi thật sự hiện một lời nhắc.
void NudgeCoordinator_MarkNudged();

// Độ nhạy (registry `vBellSensitivity`): 1=ít nhạy · 2=vừa · 3=nhạy. Chưa lưu = vừa.
// Độ nhạy là LỚP DIỄN GIẢI — nó đổi cách ĐỌC điểm risk, KHÔNG đổi điểm thô
// (bmad-output/_shared/SYNC-emotion-mechanism-v2.md §A).
int    NudgeCoordinator_TenseStreakTrigger();   // cần bao nhiêu câu căng LIÊN TIẾP mới rung
double NudgeCoordinator_RippleThreshold();      // risk từ mức nào thì tính là "câu căng"
