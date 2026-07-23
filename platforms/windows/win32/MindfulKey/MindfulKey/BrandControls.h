//
//  BrandControls.h — [MINDFUL] nền móng vẽ-tay dùng chung cho MỌI bề mặt brand của vỏ Windows.
//  File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
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

// ── Header của thẻ brand ──
// Vẽ hàng đầu của một "thẻ" nhận diện: icon sóng ~ teal + tiêu đề + đường kẻ ngăn mảnh bên dưới.
// Đối ứng buildHeader ở PanelViewController.mm bên macOS. Gọi trong WM_PAINT của cửa sổ không viền.
// `clientWidth` = bề rộng vùng client (pixel) để căn đường kẻ ngăn cho hết chiều ngang.
void BrandControls_DrawCardHeader(HDC hdc, int clientWidth, const wchar_t* title);

// ── Thẻ bo tròn (Card) ──
// Nền trắng (cardWhite), bo góc 11px, viền 1px divider (nếu hasBorder).
void BrandControls_DrawCard(HDC hdc, const RECT& rc, bool hasBorder);

// ── Pill Switch ──
// Công tắc bật/tắt (kích thước chuẩn 36x21). Tắt = xám (divider), bật = xanh (teal).
void BrandControls_DrawPillSwitch(HDC hdc, const RECT& rc, bool isOn);

// ── Segmented Control ──
// Thanh tab (Hôm nay | Chuông | Bộ gõ). Nền xám nhạt, tab đang chọn là Pill trắng nổi khối hoặc màu nền tuỳ style.
// [MINDFUL] macOS: tab đang chọn = pill TRẮNG nổi có bóng (ở popover) hoặc pill TEAL (ở six-nav).
// style: 0 = Popover (chọn TRẮNG), 1 = Settings (chọn TEAL nền + chữ trắng).
// Hàm vẽ và trả về index của mục được click nếu chuột nằm trong rect (truyền pt = toạ độ chuột lúc WM_LBUTTONUP, truyền pt.x = -1 lúc WM_PAINT).
int BrandControls_DrawSegmentedControl(HDC hdc, const RECT& rc, const wchar_t** labels, int count, int selectedIndex, POINT clickPt, int style);

// ── Slider (Volume) ──
// Thanh trượt ngang. thumbPos từ 0.0 -> 1.0. 
// Trả về giá trị thumbPos mới nếu pt nằm trong thanh trượt (kéo chuột). Truyền pt.x = -1 để chỉ vẽ.
float BrandControls_DrawSlider(HDC hdc, const RECT& rc, float thumbPos, POINT clickPt);

// ── Icon Group Selector (Bộ tiếng) ──
// Nhóm 4 nút icon (Chuông chùa, Chuông báo, Chuông gió, Nhạc). Indicator là chấm teal dưới icon.
// iconResIds = mảng `count` resource-id icon (.ico trong .rc). NULL -> vẽ chữ A/B/C/D dự phòng.
int BrandControls_DrawIconGroup(HDC hdc, const RECT& rc, int count, int selectedIndex, POINT clickPt, const int* iconResIds);

// ── Text Input / ComboBox Styling ──
// Vẽ viền xám nhạt, nền trắng, bo góc. Thường gọi trong WM_CTLCOLOR hoặc đè WM_NCPAINT của edit native.
void BrandControls_DrawTextBoxFrame(HDC hdc, const RECT& rc);

// ── Hit-test thuần (không vẽ) ──
// Dùng trong WM_LBUTTONUP để dò click mà không cần vẽ lại (khớp TOÁN của bản Draw* tương ứng — xem
// BrandControls.cpp). Các hàm Draw* vẫn nhận pt để vẽ+dò cùng lúc trong WM_PAINT (pt.x=-1 lúc vẽ);
// bộ hàm này dành cho nơi ĐÃ có pt thật (WM_LBUTTONUP) mà không cần vẽ.
int  BrandControls_HitSegmented(const RECT& rc, int count, POINT pt); // trả index 0..count-1, hoặc -1
int  BrandControls_HitIconGroup(const RECT& rc, int count, POINT pt); // như trên
bool BrandControls_HitSlider(const RECT& rc, POINT pt, float* outPos); // true nếu trúng, outPos=0..1
