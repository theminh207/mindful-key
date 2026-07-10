//
//  BrandPalette.h
//  mindful-key — shared (macOS + iOS)
//
//  Giá trị hex NOW BRAND OS rút từ platforms/apple/macos/BrandColors.h (comment trên mỗi
//  accessor). File đó dùng NSColor (Cocoa/AppKit) — KHÔNG build được trên iOS. File này chỉ
//  giữ DATA thuần (hex, không phụ thuộc AppKit/UIKit) để cả 2 vỏ tự bọc theo API màu riêng
//  (NSColor bên macOS, UIColor bên iOS) mà không lệch giá trị. Đổi màu ở ĐÂY trước, rồi 2
//  wrapper đọc theo — không hard-code hex ở 2 nơi.
//
//  Nhận diện theo Hiến chương §2.3: những màu này là token thẩm mỹ trung tính (chữ, nền,
//  CTA/nhịp thở) — KHÔNG dùng bất kỳ màu nào ở đây để MÃ HOÁ trạng thái cảm xúc (đèn đỏ/xanh).

#ifndef BrandPalette_h
#define BrandPalette_h

#define kBrandPaletteTeal        0x1D7C91   // thương hiệu chính, tiêu đề
#define kBrandPaletteTealLight   0xE8F2F4   // hover, nền phụ
#define kBrandPaletteOrange      0xFF7A1A   // CTA/lớp nhịp thở/khoảnh khắc người — KHÔNG mã hoá cảm xúc
#define kBrandPaletteOrangeLight 0xFFF2E8
#define kBrandPaletteCharcoal    0x2A2A2A   // chữ chính
#define kBrandPaletteMuted       0x666666   // chữ phụ
#define kBrandPaletteSoftWhite   0xF8F8F8   // nền trang/card
#define kBrandPaletteDivider     0xE5E7E8   // đường ngăn mảnh, viền/nền off của toggle
#define kBrandPaletteStone       0x8A9BA0   // sắc độ trung tính-đá, sóng biên độ thấp — KHÔNG dùng như màu cảnh báo

#endif /* BrandPalette_h */
