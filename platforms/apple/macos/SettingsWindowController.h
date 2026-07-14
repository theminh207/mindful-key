//
//  SettingsWindowController.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 2.2 — cửa sổ quản lý DUY NHẤT, nav trái 6 mục (Hôm nay · Chuông · Bộ gõ ·
//  Riêng tư · Hệ thống · Giới thiệu) thay cho 4 cửa sổ rời rạc cũ (Bảng điều khiển/Gõ tắt/
//  Chuyển mã/Giới thiệu). Nội dung "Bộ gõ ▸ Kiểu gõ" và "Hệ thống" TÁI DÙNG nguyên trạng 2 NSBox
//  của ViewController (tabviewPrimary/tabviewSystem) bằng cách reparent subview; "Bộ gõ ▸ Gõ
//  tắt"/"Chuyển mã"/"Giới thiệu" TÁI DÙNG nguyên trạng MacroViewController/ConvertToolViewController/
//  AboutViewController qua containment (addChildViewController:). "Hôm nay"/"Chuông"/"Riêng tư"
//  là phòng trống (nội dung thật ở story 2.4/2.5/2.6). Xem SettingsWindowController.mm cho chi
//  tiết kỹ thuật + rủi ro đã ghi trong story 2.2 Dev Notes.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsWindowController : NSWindowController

- (instancetype)init;

/// Chọn mục nav theo chỉ số: 0=Hôm nay, 1=Chuông, 2=Bộ gõ, 3=Riêng tư, 4=Hệ thống, 5=Giới thiệu.
/// Mặc định (sau -init) đang ở 0. Gọi lại (kể cả cùng chỉ số) sẽ refresh dữ liệu của mục đó.
- (void)selectSectionAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
