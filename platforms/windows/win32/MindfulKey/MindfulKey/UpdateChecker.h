//
// UpdateChecker.h — [MINDFUL] Tự kiểm + tự tải + tự mở bộ cài bản mới từ GitHub Releases.
//
// Trước đây "Kiểm tra bản mới..." chỉ mở trang Releases trong trình duyệt, người dùng phải tự đọc
// số phiên bản + tự tải + tự chạy .exe. Hàm này tự làm 3 bước đó cho họ (đúng phản hồi "bấm nút là
// tự cập nhật"). Bộ cài (.iss) đã sẵn AppMutex + CloseApplications=yes nên tự đóng app đang chạy
// + gỡ bản cũ + cài bản mới — file này chỉ cần tìm đúng bản mới nhất, tải, rồi MỞ nó ra như người
// dùng tự bấm đúp — KHÔNG né tránh SmartScreen/UAC của Windows (xem UpdateChecker.cpp).
//
#pragma once
#include <windows.h>

// Hỏi GitHub bản mới nhất; nếu mới hơn bản đang chạy thì hỏi 1 câu rồi tự tải + mở bộ cài. Lỗi ở
// bất kỳ bước nào (mạng, phân tích, tải, mở) đều lùi về mở trang Releases trong trình duyệt — không
// bao giờ để người dùng mắc kẹt không biết làm gì tiếp. owner = cha cho các hộp thoại (NULL cũng được).
void UpdateChecker_CheckAndUpdate(HWND owner);
