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

// ── Thẻ bo tròn (Card) ──
void BrandControls_DrawCard(HDC hdc, const RECT& rc, bool hasBorder) {
    HRGN rgn = CreateRoundRectRgn(rc.left, rc.top, rc.right + 1, rc.bottom + 1, 22, 22); // radius 11px -> width/height of ellipse = 22
    HBRUSH fillBrush = CreateSolidBrush(MK_COLORREF(kBrandPaletteCardWhite));
    FillRgn(hdc, rgn, fillBrush);
    DeleteObject(fillBrush);
    if (hasBorder) {
        HBRUSH borderBrush = CreateSolidBrush(MK_COLORREF(kBrandPaletteDivider));
        FrameRgn(hdc, rgn, borderBrush, 1, 1);
        DeleteObject(borderBrush);
    }
    DeleteObject(rgn);
}

// ── Pill Switch ──
void BrandControls_DrawPillSwitch(HDC hdc, const RECT& rc, bool isOn) {
    // Kích thước mong muốn 36x21, căn giữa trong rc
    int width = 36;
    int height = 21;
    int x = rc.left + (rc.right - rc.left - width) / 2;
    int y = rc.top + (rc.bottom - rc.top - height) / 2;

    HRGN rgn = CreateRoundRectRgn(x, y, x + width + 1, y + height + 1, height, height);
    COLORREF bgColor = isOn ? MK_COLORREF(kBrandPaletteTeal) : MK_COLORREF(kBrandPaletteDivider);
    HBRUSH bgBrush = CreateSolidBrush(bgColor);
    FillRgn(hdc, rgn, bgBrush);
    DeleteObject(bgBrush);
    DeleteObject(rgn);

    // Núm tròn (17x17)
    int knobSize = 17;
    int knobY = y + (height - knobSize) / 2;
    int knobX = isOn ? (x + width - knobSize - 2) : (x + 2);

    HRGN knobRgn = CreateEllipticRgn(knobX, knobY, knobX + knobSize + 1, knobY + knobSize + 1);
    HBRUSH knobBrush = CreateSolidBrush(RGB(255, 255, 255));
    FillRgn(hdc, knobRgn, knobBrush);
    DeleteObject(knobBrush);
    DeleteObject(knobRgn);
}

// ── Segmented Control ──
int BrandControls_DrawSegmentedControl(HDC hdc, const RECT& rc, const wchar_t** labels, int count, int selectedIndex, POINT clickPt, int style) {
    if (count <= 0) return -1;
    
    // Nền thanh tab (màu #EFEFEC) bo góc 8px
    HRGN bgRgn = CreateRoundRectRgn(rc.left, rc.top, rc.right + 1, rc.bottom + 1, 16, 16);
    HBRUSH bgBrush = CreateSolidBrush(RGB(0xEF, 0xEF, 0xEC));
    FillRgn(hdc, bgRgn, bgBrush);
    DeleteObject(bgBrush);
    DeleteObject(bgRgn);

    int itemWidth = (rc.right - rc.left) / count;
    int clickedIndex = -1;

    SetBkMode(hdc, TRANSPARENT);
    HFONT font = BrandControls_Font(BrandFontButton);
    HFONT oldFont = (HFONT)SelectObject(hdc, font);

    for (int i = 0; i < count; i++) {
        RECT itemRc = { rc.left + i * itemWidth, rc.top, rc.left + (i + 1) * itemWidth, rc.bottom };
        
        // Kiểm tra click
        if (clickPt.x != -1 && clickPt.x >= itemRc.left && clickPt.x < itemRc.right && clickPt.y >= itemRc.top && clickPt.y < itemRc.bottom) {
            clickedIndex = i;
        }

        // Vẽ ô được chọn
        if (i == selectedIndex) {
            // Pill con bo góc ~7px, thụt vào 2px
            RECT pillRc = { itemRc.left + 2, itemRc.top + 2, itemRc.right - 2, itemRc.bottom - 2 };
            HRGN pillRgn = CreateRoundRectRgn(pillRc.left, pillRc.top, pillRc.right + 1, pillRc.bottom + 1, 14, 14);
            
            COLORREF pillColor = (style == 1) ? MK_COLORREF(kBrandPaletteTeal) : MK_COLORREF(kBrandPaletteCardWhite);
            HBRUSH pillBrush = CreateSolidBrush(pillColor);
            FillRgn(hdc, pillRgn, pillBrush);
            DeleteObject(pillBrush);
            DeleteObject(pillRgn);
            
            SetTextColor(hdc, (style == 1) ? MK_COLORREF(kBrandPaletteCardWhite) : MK_COLORREF(kBrandPaletteCharcoal));
        } else {
            SetTextColor(hdc, MK_COLORREF(kBrandPaletteMuted));
        }

        DrawTextW(hdc, labels[i], -1, &itemRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    }

    SelectObject(hdc, oldFont);
    return clickedIndex;
}

float BrandControls_DrawSlider(HDC hdc, const RECT& rc, float thumbPos, POINT clickPt) {
    // Kéo thả slider
    if (clickPt.x != -1 && clickPt.x >= rc.left && clickPt.x <= rc.right && clickPt.y >= rc.top && clickPt.y <= rc.bottom) {
        thumbPos = (float)(clickPt.x - rc.left) / (rc.right - rc.left);
        if (thumbPos < 0) thumbPos = 0;
        if (thumbPos > 1) thumbPos = 1;
    }

    // Vẽ track nền (divider)
    int trackHeight = 4;
    int trackY = rc.top + (rc.bottom - rc.top) / 2 - trackHeight / 2;
    RECT trackRc = { rc.left, trackY, rc.right, trackY + trackHeight };
    HRGN trackRgn = CreateRoundRectRgn(trackRc.left, trackRc.top, trackRc.right + 1, trackRc.bottom + 1, 4, 4);
    HBRUSH trackBrush = CreateSolidBrush(MK_COLORREF(kBrandPaletteDivider));
    FillRgn(hdc, trackRgn, trackBrush);
    DeleteObject(trackBrush);
    DeleteObject(trackRgn);

    // Vẽ phần đã chạy (teal)
    int fillWidth = (int)((rc.right - rc.left) * thumbPos);
    if (fillWidth > 0) {
        RECT fillRc = { rc.left, trackY, rc.left + fillWidth, trackY + trackHeight };
        HRGN fillRgn = CreateRoundRectRgn(fillRc.left, fillRc.top, fillRc.right + 1, fillRc.bottom + 1, 4, 4);
        HBRUSH fillBrush = CreateSolidBrush(MK_COLORREF(kBrandPaletteTeal));
        FillRgn(hdc, fillRgn, fillBrush);
        DeleteObject(fillBrush);
        DeleteObject(fillRgn);
    }

    // Vẽ thumb
    int thumbSize = 16;
    int thumbX = rc.left + fillWidth - thumbSize / 2;
    int thumbY = rc.top + (rc.bottom - rc.top) / 2 - thumbSize / 2;
    // Đảm bảo thumb không lọt ra ngoài rc
    if (thumbX < rc.left) thumbX = rc.left;
    if (thumbX + thumbSize > rc.right) thumbX = rc.right - thumbSize;

    Gdiplus::Graphics g(hdc);
    g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    Gdiplus::SolidBrush thumbBrush(Gdiplus::Color(255, 255, 255, 255)); // Trắng
    Gdiplus::Pen thumbPen(Gdiplus::Color(255, (kBrandPaletteDivider >> 16) & 0xFF, (kBrandPaletteDivider >> 8) & 0xFF, kBrandPaletteDivider & 0xFF), 1);
    g.FillEllipse(&thumbBrush, thumbX, thumbY, thumbSize, thumbSize);
    g.DrawEllipse(&thumbPen, thumbX, thumbY, thumbSize, thumbSize);

    return thumbPos;
}

int BrandControls_DrawIconGroup(HDC hdc, const RECT& rc, int count, int selectedIndex, POINT clickPt) {
    if (count <= 0) return -1;
    int itemWidth = (rc.right - rc.left) / count;
    int clickedIndex = -1;

    for (int i = 0; i < count; i++) {
        RECT itemRc = { rc.left + i * itemWidth, rc.top, rc.left + (i + 1) * itemWidth, rc.bottom };
        
        if (clickPt.x != -1 && clickPt.x >= itemRc.left && clickPt.x < itemRc.right && clickPt.y >= itemRc.top && clickPt.y < itemRc.bottom) {
            clickedIndex = i;
        }

        // Tạm vẽ ký tự giả lập icon nếu chưa tải được resource GDI+ image
        // (Sẽ bổ sung logic vẽ PNG từ .rc sau)
        HFONT font = BrandControls_Font(BrandFontTitle);
        HFONT oldFont = (HFONT)SelectObject(hdc, font);
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, MK_COLORREF((i == selectedIndex) ? kBrandPaletteTeal : kBrandPaletteStone));
        
        const wchar_t* fallbackIcons[] = { L"A", L"B", L"C", L"D", L"E" };
        DrawTextW(hdc, i < 5 ? fallbackIcons[i] : L"?", -1, &itemRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        SelectObject(hdc, oldFont);

        // Vẽ indicator (chấm teal) dưới icon được chọn
        if (i == selectedIndex) {
            Gdiplus::Graphics g(hdc);
            g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
            Gdiplus::SolidBrush dotBrush(Gdiplus::Color(255, (kBrandPaletteTeal >> 16) & 0xFF, (kBrandPaletteTeal >> 8) & 0xFF, kBrandPaletteTeal & 0xFF));
            int dotSize = 6;
            int dotX = itemRc.left + (itemRc.right - itemRc.left) / 2 - dotSize / 2;
            int dotY = itemRc.bottom - dotSize - 2;
            g.FillEllipse(&dotBrush, dotX, dotY, dotSize, dotSize);
        }
    }
    return clickedIndex;
}

void BrandControls_DrawTextBoxFrame(HDC hdc, const RECT& rc) {
    HRGN rgn = CreateRoundRectRgn(rc.left, rc.top, rc.right + 1, rc.bottom + 1, 8, 8);
    HBRUSH bgBrush = CreateSolidBrush(RGB(255, 255, 255));
    FillRgn(hdc, rgn, bgBrush);
    
    Gdiplus::Graphics g(hdc);
    g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    Gdiplus::Pen borderPen(Gdiplus::Color(255, (kBrandPaletteDivider >> 16) & 0xFF, (kBrandPaletteDivider >> 8) & 0xFF, kBrandPaletteDivider & 0xFF), 1);
    g.DrawPath(&borderPen, NULL); // TODO: Replace with proper RoundRect path or just rely on FrameRgn
    
    HBRUSH borderBrush = CreateSolidBrush(MK_COLORREF(kBrandPaletteDivider));
    FrameRgn(hdc, rgn, borderBrush, 1, 1);
    
    DeleteObject(bgBrush);
    DeleteObject(borderBrush);
    DeleteObject(rgn);
}
