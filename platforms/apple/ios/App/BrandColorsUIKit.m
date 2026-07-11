//
//  BrandColorsUIKit.m
//  mindful-key — iOS container app (onboarding, story 1.7)
//
//  Xem BrandColorsUIKit.h. Giá trị GỐC lấy từ shared/BrandPalette.h; 2 phái sinh (tealStrong,
//  stoneStrong) + các sắc dark khai cục bộ theo DESIGN.md §1.1.
//

#import "BrandColorsUIKit.h"
#import "BrandPalette.h"

// Phái sinh (DESIGN.md §1.1 — không có trong BrandPalette.h vì đó là nguồn màu gốc).
#define kMkTealStrongLight   0x155A66   // 6.86:1 trên tealLight (DESIGN.md §3)
#define kMkStoneStrongLight  0x5E6E73   // 5.00:1 trên surface.page (DESIGN.md §3)

// Sắc dark verify sẵn ở DESIGN.md §1.1.
#define kMkTealDark          0x4FB6CC
#define kMkInkPrimaryDark    0xF2F4F5
#define kMkInkSecondaryDark  0x9BA3A6
#define kMkPageDark          0x000000
#define kMkCardDark          0x1C1C1E
#define kMkStoneStrongDark   0x9BA3A6
#define kMkDividerDark       0x2C2C2E

static UIColor *mk_colorFromHex(UInt32 hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:1.0];
}

// Màu động theo theme (Light/Dark là hợp đồng — DESIGN.md §1.4, không phải tuỳ chọn).
static UIColor *mk_dynamic(UInt32 lightHex, UInt32 darkHex) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return mk_colorFromHex(tc.userInterfaceStyle == UIUserInterfaceStyleDark ? darkHex : lightHex);
    }];
}

@implementation BrandColorsUIKit

+ (UIColor *)surfacePage  { return mk_dynamic(kBrandPaletteSoftWhite, kMkPageDark); }
+ (UIColor *)surfaceCard  { return mk_dynamic(0xFFFFFF, kMkCardDark); }
+ (UIColor *)inkPrimary   { return mk_dynamic(kBrandPaletteCharcoal, kMkInkPrimaryDark); }
+ (UIColor *)inkSecondary { return mk_dynamic(kBrandPaletteMuted, kMkInkSecondaryDark); }
+ (UIColor *)brandTeal    { return mk_dynamic(kBrandPaletteTeal, kMkTealDark); }
+ (UIColor *)tealStrong   { return mk_dynamic(kMkTealStrongLight, kMkTealDark); }
+ (UIColor *)tealLight    { return mk_dynamic(kBrandPaletteTealLight, kMkCardDark); }
+ (UIColor *)orange       { return mk_colorFromHex(kBrandPaletteOrange); }
+ (UIColor *)onOrange     { return mk_colorFromHex(kBrandPaletteCharcoal); }
+ (UIColor *)stoneStrong  { return mk_dynamic(kMkStoneStrongLight, kMkStoneStrongDark); }
+ (UIColor *)divider      { return mk_dynamic(kBrandPaletteDivider, kMkDividerDark); }

@end
