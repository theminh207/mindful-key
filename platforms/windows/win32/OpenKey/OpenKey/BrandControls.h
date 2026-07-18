//
//  BrandControls.h — [MINDFUL] nền móng vẽ-tay dùng chung cho MỌI bề mặt brand của vỏ Windows.
//  File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
//
//  Đối ứng Win32 của platforms/apple/macos/BrandControls.m — macOS là CHUẨN HÀNH VI. Mọi hộp thoại
//  vẽ lại theo nhận diện GỌI LẠI đây, KHÔNG tự chép GDI: hai bản GDI chép tay sẽ trôi lệch (đúng mô
//  hình đã đẻ bug lexicon). Xem docs/WINDOWS-UI-REDESIGN.md.
//
//  Xây DẦN theo nhu cầu từng màn (YAGNI) — hiện có đúng thứ màn "Nhịp thở" (Phase 1) cần: font,
//  tô nền, nút bo tròn. Thêm thẻ/PillSwitch/segmented khi màn tương ứng tới lượt.
//
#pragma once
#include <windows.h>

// ── Font ──
// Segoe UI ở cỡ/nét brand. KHỚP LỰA CHỌN THẬT của macOS: dùng font HỆ THỐNG (SF trên Mac, Segoe UI
// trên Windows), KHÔNG nhúng Montserrat — tokens.json ghi Montserrat nhưng macOS cố ý bỏ qua
// (SettingsWindowController.mm:450). Trả HFONT CHIA SẺ (cache tĩnh) — người gọi KHÔNG DeleteObject.
enum BrandFontRole {
    BrandFontTitle,    // tiêu đề màn/nhóm
    BrandFontBody,     // câu chữ thường
    BrandFontEyebrow,  // nhãn nhóm nhỏ (in hoa, giãn chữ) — dành cho màn sau
    BrandFontButton,   // chữ trên nút
};
HFONT BrandControls_Font(BrandFontRole role);

// ── Tô nền ──
// Tô đặc một vùng bằng màu brand (hex 0xRRGGBB — TỰ qua MK_COLORREF, đừng truyền COLORREF thô).
// Gọi trong WM_ERASEBKGND để thay nền xám hệ thống bằng nền brand.
void BrandControls_FillRect(HDC hdc, const RECT& rc, unsigned brandHex);

// ── Nút bo tròn (owner-draw) ──
// Gọi trong WM_DRAWITEM cho nút style BS_OWNERDRAW. Chữ lấy từ window-text của nút (GetWindowText),
// nên .rc vẫn khai chữ như thường. Có xử trạng thái nhấn (ODS_SELECTED) + vô hiệu (ODS_DISABLED).
enum BrandButtonStyle {
    BrandButtonPrimary,   // nền teal, chữ trắng — hành động chính
    BrandButtonAccent,    // nền cam, chữ charcoal — "khoảnh khắc người" (nhịp thở); cam KHÔNG mã hoá cảm xúc
    BrandButtonNeutral,   // nền trắng, viền divider, chữ charcoal — hành động phụ/an toàn
};
void BrandControls_DrawButton(const DRAWITEMSTRUCT* dis, BrandButtonStyle style);
