//
//  BrandControls.cpp — [MINDFUL] nền móng vẽ-tay dùng chung cho vỏ Windows. Xem BrandControls.h.
//
//  Lần đầu dùng GDI THUẦN (CreateRoundRectRgn), KHÔNG GDI+: robust khi vẽ mù (máy dev là macOS,
//  không render được Windows), không dây dưa vòng đời GdiplusStartup. Góc bo hơi gợn — nâng lên
//  GDI+ (anti-alias) SAU khi ảnh Windows thật xác nhận cách tiếp cận. Xem docs/WINDOWS-UI-REDESIGN.md.
//
#include "stdafx.h"
#include "BrandControls.h"
#include "BrandPalette.h"

// Bo góc = radius.control token (8) — khớp macOS (BrandControls.m:16 kCornerCTA=8).
static const int kBrandControlRadius = 8;

// ── Font ──
HFONT BrandControls_Font(BrandFontRole role) {
    static HFONT cache[4] = { NULL, NULL, NULL, NULL };
    if (cache[role])
        return cache[role];

    // Cỡ điểm suy từ DPI màn hình chính. DPI-per-monitor tinh chỉnh sau (ghi WINDOWS-UI-REDESIGN
    // §ràng buộc 3) — lần đầu lấy DPI hệ thống là đủ để thấy hình.
    HDC screen = GetDC(NULL);
    int dpiY = GetDeviceCaps(screen, LOGPIXELSY);
    ReleaseDC(NULL, screen);

    int pt, weight;
    switch (role) {
    case BrandFontTitle:   pt = 13; weight = FW_SEMIBOLD; break;   // tiêu đề thẻ/nhóm (header)
    case BrandFontBody:    pt = 11; weight = FW_NORMAL;   break;
    case BrandFontEyebrow: pt = 8;  weight = FW_SEMIBOLD; break;
    case BrandFontButton:  pt = 10; weight = FW_SEMIBOLD; break;
    default:               pt = 11; weight = FW_NORMAL;   break;
    }
    int height = -MulDiv(pt, dpiY, 72);

    cache[role] = CreateFontW(
        height, 0, 0, 0, weight, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, VARIABLE_PITCH | FF_DONTCARE, L"Segoe UI");
    return cache[role];
}

// ── Tô nền ──
void BrandControls_FillRect(HDC hdc, const RECT& rc, unsigned brandHex) {
    HBRUSH brush = CreateSolidBrush(MK_COLORREF(brandHex));
    FillRect(hdc, &rc, brush);
    DeleteObject(brush);
}

// Trộn một màu về phía đen theo tỉ lệ [0..1] — dùng cho trạng thái nhấn (nhích tối đi một chút).
static COLORREF DarkenColor(COLORREF c, double t) {
    int r = (int)(GetRValue(c) * (1.0 - t));
    int g = (int)(GetGValue(c) * (1.0 - t));
    int b = (int)(GetBValue(c) * (1.0 - t));
    return RGB(r, g, b);
}

// ── Nút bo tròn ──
void BrandControls_DrawButton(const DRAWITEMSTRUCT* dis, BrandButtonStyle style) {
    RECT rc = dis->rcItem;
    bool pressed  = (dis->itemState & ODS_SELECTED) != 0;
    bool disabled = (dis->itemState & ODS_DISABLED) != 0;

    COLORREF fill, textColor, border;
    bool hasBorder = false;
    switch (style) {
    case BrandButtonPrimary:
        fill = MK_COLORREF(kBrandPaletteTeal);
        textColor = MK_COLORREF(kBrandPaletteCardWhite);
        break;
    case BrandButtonAccent:
        fill = MK_COLORREF(kBrandPaletteOrange);
        // Chữ charcoal trên cam, KHÔNG trắng: trắng-trên-cam trượt chuẩn tương phản WCAG
        // (BrandControls.m:210 bên macOS đã chốt đúng điều này).
        textColor = MK_COLORREF(kBrandPaletteCharcoal);
        break;
    case BrandButtonNeutral:
    default:
        fill = MK_COLORREF(kBrandPaletteCardWhite);
        textColor = MK_COLORREF(kBrandPaletteCharcoal);
        border = MK_COLORREF(kBrandPaletteDivider);
        hasBorder = true;
        break;
    }
    if (pressed)
        fill = DarkenColor(fill, 0.08);   // nhấn = tối đi 8%, đối ứng hover-blend bên macOS

    // Hình bo tròn. +1 vì CreateRoundRectRgn loại trừ cạnh phải/dưới.
    HRGN rgn = CreateRoundRectRgn(rc.left, rc.top, rc.right + 1, rc.bottom + 1,
                                  kBrandControlRadius * 2, kBrandControlRadius * 2);
    HBRUSH fillBrush = CreateSolidBrush(fill);
    FillRgn(dis->hDC, rgn, fillBrush);
    DeleteObject(fillBrush);
    if (hasBorder) {
        HBRUSH borderBrush = CreateSolidBrush(border);
        FrameRgn(dis->hDC, rgn, borderBrush, 1, 1);
        DeleteObject(borderBrush);
    }
    DeleteObject(rgn);

    // Chữ — lấy từ window-text của nút (.rc vẫn khai chữ như thường).
    wchar_t label[128] = { 0 };
    GetWindowTextW(dis->hwndItem, label, 128);

    SetBkMode(dis->hDC, TRANSPARENT);
    SetTextColor(dis->hDC, disabled ? MK_COLORREF(kBrandPaletteStone) : textColor);
    HFONT font = BrandControls_Font(BrandFontButton);
    HFONT oldFont = (HFONT)SelectObject(dis->hDC, font);
    RECT textRc = rc;
    DrawTextW(dis->hDC, label, -1, &textRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    SelectObject(dis->hDC, oldFont);
}

// ── Header của thẻ brand ──
void BrandControls_DrawCardHeader(HDC hdc, int clientWidth, const wchar_t* title) {
    const int pad = 18;        // lề trái = radius.card-ish, khớp lề thẻ macOS (18px)
    const int iconSize = 16;
    const int iconY = 14;
    const int dividerY = 40;   // đường kẻ ngăn dưới header

    // Icon sóng ~ teal (dùng đúng icon khay chế độ Việt — nguồn brand duy nhất, không vẽ lại).
    HICON icon = (HICON)LoadImageW(GetModuleHandleW(NULL), MAKEINTRESOURCEW(IDI_ICON_STATUS_VIET),
                                   IMAGE_ICON, iconSize, iconSize, LR_DEFAULTCOLOR);
    if (icon) {
        DrawIconEx(hdc, pad, iconY, icon, iconSize, iconSize, 0, NULL, DI_NORMAL);
        DestroyIcon(icon);
    }

    // Tiêu đề — charcoal semibold, đối ứng tiêu đề header charcoal bên macOS (PanelViewController).
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, MK_COLORREF(kBrandPaletteCharcoal));
    HFONT font = BrandControls_Font(BrandFontTitle);
    HFONT oldFont = (HFONT)SelectObject(hdc, font);
    RECT titleRc = { pad + iconSize + 8, iconY - 3, clientWidth - pad, iconY + iconSize + 3 };
    DrawTextW(hdc, title, -1, &titleRc, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
    SelectObject(hdc, oldFont);

    // Đường kẻ ngăn mảnh (divider token) hết chiều ngang trừ lề.
    HPEN pen = CreatePen(PS_SOLID, 1, MK_COLORREF(kBrandPaletteDivider));
    HPEN oldPen = (HPEN)SelectObject(hdc, pen);
    MoveToEx(hdc, pad, dividerY, NULL);
    LineTo(hdc, clientWidth - pad, dividerY);
    SelectObject(hdc, oldPen);
    DeleteObject(pen);
}
