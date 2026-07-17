//
// SecureField.h — [MINDFUL] cổng ô mật khẩu cho vỏ Windows.
// File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
//
// VÌ SAO FILE NÀY TỒN TẠI (docs/FRICTION-LOG.md 2026-07-17 "CHẶN PHÁT HÀNH", docs/QA-WINDOWS.md §5
// ca P1): iOS chặn đọc ô mật khẩu bằng CODE THẬT (MoodBridge_SetSecureFieldActive, platforms/
// apple/ios/KeyboardExtension/MoodBridge.mm). macOS không cần code — hệ điều hành tự bật Secure
// Input Mode và chặn luôn CGEventTap ở ô mật khẩu. Windows KHÔNG CÓ CƠ CHẾ TƯƠNG ĐƯƠNG:
// WH_KEYBOARD_LL thấy MỌI phím, kể cả lúc đang gõ mật khẩu. Không có file này thì Windows là vỏ
// DUY NHẤT mà lớp cảm xúc đọc được mật khẩu người dùng — chạm thẳng cột trụ riêng tư.
//
// CÁCH VÁ: UI Automation (UIA), theo phương án chủ dự án đã chốt (FRICTION-LOG, không phải tự
// chọn). UIA phải hỏi tiến trình khác qua COM — có thể chậm, có thể treo nếu app kia đứng hình.
// Vì vậy toàn bộ việc hỏi UIA chạy trên MỘT LUỒNG RIÊNG có message loop + COM apartment riêng
// (SecureField.cpp), KHÔNG BAO GIỜ trên luồng `SetWindowsHookEx(WH_KEYBOARD_LL)`. Luồng hook đó bị
// Windows âm thầm gỡ nếu chạy quá `LowLevelHooksTimeout` (mặc định 300ms, xem docs/QA-WINDOWS.md
// ca T7) — cược một lệnh UIA có thể treo cả giây vào luồng đó là tự sát cho toàn bộ bộ gõ.
//
// FAIL-CLOSED (bắt buộc — riêng tư mặc định là cột trụ hiến chương): bất cứ lúc nào CHƯA BIẾT
// CHẮC — vừa đổi focus, UIA chưa kịp trả lời, UIA lỗi, hoặc COM init lỗi ngay từ đầu — coi như
// ĐANG Ở Ô MẬT KHẨU. Cái giá là vài trăm mili-giây "mù" mỗi lần đổi cửa sổ/control (hoặc mù suốt
// phiên nếu COM hỏng hẳn) — chấp nhận được. Đọc nhầm mật khẩu thì không.
//
#pragma once

// Dựng luồng theo dõi focus (SetWinEventHook EVENT_OBJECT_FOCUS) + khởi COM cho luồng đó + hỏi
// UIA. Gọi ĐÚNG MỘT LẦN lúc app khởi động, cạnh MoodWatch_Init() (xem OpenKey.cpp: OpenKeyInit()).
void SecureField_Init();

// true = ĐANG ở ô mật khẩu, HOẶC CHƯA CHẮC là không (fail-closed) — nơi gọi phải coi như bị che:
// không đọc thêm, không phân tích, không ghi nhật ký.
// An toàn gọi từ BẤT KỲ luồng nào, kể cả luồng hook: chỉ đọc một cờ đã có sẵn trong bộ nhớ, không
// chờ, không I/O, không gọi COM/UIA tại chỗ.
bool SecureField_IsActive();
