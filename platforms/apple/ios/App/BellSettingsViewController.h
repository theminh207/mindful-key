//
//  BellSettingsViewController.h
//  mindful-key — iOS container app (tab "Chuông" — Chuông tỉnh thức)
//
//  Rebuild native (UIKit programmatic, KHÔNG storyboard) của design handoff `tabChuong`:
//  chọn tiếng chuông (lớn/nhỏ), 4 công tắc lịch ngân chuông (Định kỳ / Thưa nhặt tự nhiên /
//  Hẹn một khắc / Đầu mỗi giờ) mỗi cái có dòng cấu hình nhỏ khi bật, 1 công tắc Giờ tĩnh lặng,
//  và nút "Ngân thử một tiếng" mở màn hình thở toàn màn (2 vòng tròn lan toả + sóng ngang).
//  Đọc/ghi mọi lựa chọn qua BellScheduleSettingsBridge (App Group group.vn.gnh.mindfulkey).
//
//  THÀNH THẬT: màn này CHỈ LƯU lựa chọn lịch — bàn phím (keyboard extension) CHƯA có scheduler
//  nào đọc các khoá này để ngân chuông thật theo lịch. Xem ghi chú ở đầu
//  BellScheduleSettingsBridge.h.
//
//  Hiến chương: KHÔNG đếm số ngày liên tục/"bạn đã bỏ lỡ N ngày", KHÔNG chấm điểm, KHÔNG đèn
//  đỏ/xanh valence. Copy mời gọi/quan sát, giữ nguyên credit "Thiền sư Thích Nhất Hạnh" ở cuối màn.
//
//  Self-contained: không đăng ký vào tab bar/AppDelegate ở đây — việc gắn màn này vào điều hướng
//  thật (tab bar controller) là bước tiếp theo, ngoài phạm vi 1 màn hình này.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BellSettingsViewController : UIViewController
@end

NS_ASSUME_NONNULL_END
