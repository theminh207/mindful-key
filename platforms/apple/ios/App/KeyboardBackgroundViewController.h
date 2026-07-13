//
//  KeyboardBackgroundViewController.h
//  mindful-key — iOS container app (màn "Nền bàn phím", Round 3 Story 3.2 / màn M6)
//
//  Màn chọn cảnh nền tĩnh cho bàn phím: lưới 3 cột gồm 5 cảnh gradient (đúng design handoff,
//  section caidatNen) + 1 ô "Ảnh của bạn" (placeholder trực quan, CHƯA có picker thật). Chạm 1 ô
//  cảnh -> viền teal 2px + ghi ngay qua ThemeBridge (App Group group.vn.gnh.mindfulkey), không có
//  nút "Lưu" tổng — đúng tinh thần "áp dụng ngay" đã dùng ở SettingsViewController (story 2.3).
//
//  Việc bàn phím THẬT đọc ThemeBridge_SelectedBackgroundIndex() rồi tự vẽ nền là công việc TIẾP
//  THEO chưa có story riêng — file này CHỈ lo màn chọn, KHÔNG đụng KeyboardViewController hay
//  KeyboardExtension.
//

#import <UIKit/UIKit.h>

// Chưa được wire vào điều hướng nào (AppDelegate/SettingsViewController) — push thủ công khi cần,
// tự pop lại qua nút "Quay lại" riêng (nav bar hệ thống đang ẩn toàn app), không cần callback.
@interface KeyboardBackgroundViewController : UIViewController
@end
