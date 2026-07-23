//
// NotesHistory.h — [MINDFUL] cửa sổ "Những dòng bạn đã viết" (Windows).
// File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
// Đối ứng platforms/apple/macos/NotesHistoryMac.{h,mm} — bản macOS là CHUẨN HÀNH VI.
//
// ── CỐ Ý KHÔNG CÓ ở màn này (xem bản macOS, mỗi cái có lý do, đừng thêm lại) ──
// sóng · số đo · số đếm ngày · chuỗi ngày · ô trống cho ngày không viết · nút "viết ngay".
// Chỉ là một chồng giấy để đọc lại — MÔ TẢ, không phán xét (HIẾN CHƯƠNG §5.8). Ngày (dữ kiện),
// câu hỏi hôm đó (chính chữ app đã hỏi), chữ người viết (nhân vật chính). Không câu nào chấm điểm.
//
#pragma once
#include <windows.h>

// Mở cửa sổ. Không có dòng nào -> hiện thông báo nhẹ + chỉ chỗ ghi, KHÔNG mở cửa sổ rỗng và KHÔNG
// rủ rê "viết đi" (mirror macOS). `parent` chỉ dùng để căn giữa/chủ của MessageBox.
void NotesHistory_Show(HWND parent);

// Có ít nhất 1 dòng đã viết? Để màn Soi lại chỉ hiện link khi thật sự có gì để đọc (không có thì
// một link xám vẫn là lời nhắc "bạn chưa viết gì" — đúng thứ §2.4 cấm).
bool NotesHistory_HasAny();
