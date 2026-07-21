//
//  BrandPalette.h
//  mindful-key — vỏ Windows (Win32)
//
//  TỰ SINH từ brand/tokens.json bởi brand/gen-palette.py — ĐỪNG SỬA TAY.
//
//  Cùng giá trị hex với platforms/apple/shared/BrandPalette.h vì cùng sinh từ brand/tokens.json —
//  đó là điểm của việc sinh tự động: 3 vỏ không thể trôi lệch màu.
//
//  Nhận diện theo Hiến chương §2.3: token thẩm mỹ trung tính — KHÔNG dùng màu nào ở đây để MÃ HOÁ
//  trạng thái cảm xúc (đèn đỏ/xanh). Biên độ sóng mới là tín hiệu.

#ifndef BrandPalette_h
#define BrandPalette_h

// BẪY BYTE-ORDER: hex dưới đây là 0xRRGGBB (đọc như người). GDI của Win32 lại dùng COLORREF =
// 0x00BBGGRR — ĐẢO NGƯỢC. Truyền thẳng hằng số vào hàm nhận COLORREF là ra sai màu mà vẫn build
// sạch (teal #1D7C91 hoá thành #917C1D — cam đất). LUÔN đi qua 2 macro dưới.
#define MK_COLORREF(hex)  RGB((((hex) >> 16) & 0xFF), (((hex) >> 8) & 0xFF), ((hex) & 0xFF))
#define MK_ARGB(hex)      ((Gdiplus::ARGB)(0xFF000000 | (hex)))   // GDI+ dùng 0xAARRGGBB, đục

#define kBrandPaletteTeal        0x1D7C91   // thương hiệu chính, tiêu đề
#define kBrandPaletteTealLight   0xE8F2F4   // hover, nền phụ
#define kBrandPaletteOrange      0xFF7A1A   // CTA/lớp nhịp thở/khoảnh khắc người — KHÔNG mã hoá cảm xúc
#define kBrandPaletteOrangeLight 0xFFF2E8   // nền nhạt đi kèm cam
#define kBrandPaletteSoftWhite   0xF8F8F8   // nền trang/card
#define kBrandPaletteCardWhite   0xFFFFFF   // nền card trắng tinh
#define kBrandPaletteCharcoal    0x2A2A2A   // chữ chính
#define kBrandPaletteMuted       0x666666   // chữ phụ
#define kBrandPaletteDivider     0xE5E7E8   // đường ngăn mảnh, viền/nền off của toggle
#define kBrandPaletteStone       0x8A9BA0   // sắc độ trung tính-đá, sóng biên độ thấp — KHÔNG dùng như màu cảnh báo

// Thang "mặt hồ tâm" — biên độ sóng LÀ tín hiệu, màu chỉ là sắc độ trung tính đậm dần theo biên
// độ (KHÔNG đỏ/xanh-lá valence, KHÔNG chấm điểm — hiến chương §2.3).
#define kBrandPaletteMood1       0x9FB6BC   // An   — mặt hồ đang lặng
#define kBrandPaletteMood2       0x86A2AA   // Nhẹ  — có chút gợn thoảng qua
#define kBrandPaletteMood3       0x6E8E97   // Gợn  — mặt hồ đang gợn sóng
#define kBrandPaletteMood4       0x567A84   // Sóng — sóng đang lên rõ rệt
#define kBrandPaletteMood5       0x3F646E   // Cuộn — mặt hồ đang cuộn

#endif /* BrandPalette_h */
