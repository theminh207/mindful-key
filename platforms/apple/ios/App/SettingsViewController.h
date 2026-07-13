//
//  SettingsViewController.h
//  mindful-key — iOS container app (màn Cài đặt bàn phím, story 2.3)
//
//  Chỉnh kiểu gõ (Telex/VNI, segmented) + chiều cao bàn phím (slider), thấy ngay trong khung
//  "Preview sống" — không cần lưu/thoát. Kế thừa "slider trực tiếp" của Laban, BỎ mọi
//  gamification. Đọc/ghi qua KeyboardSettingsBridge (App Group group.vn.gnh.mindfulkey).
//  Push trực tiếp từ Home; tự pop qua nút "Quay lại" riêng (nav bar hệ thống ẩn toàn app,
//  đúng pattern MacroManagerViewController story 2.4), không cần callback pop.
//
//  Chừa 1 chỗ cho story 2.5 (toggle sóng ambient) và 2.6 (toggle chuông nhắc nghỉ) GẮN THÊM
//  row vào màn này sau (xem story 2.3 Dependency Maps "Blocks") — không code sẵn khoảng trống,
//  chỉ không làm layout cứng nhắc khó chèn thêm row.
//
//  Story 2.6: thêm row "Chuông nhắc nghỉ" (switch bật/tắt) + nút "Tạm hoãn 1 giờ", chèn giữa
//  divider sau "Chiều cao" (2.3) và row "Gõ tắt / macro" (2.4) — KHÔNG sửa phần Telex/VNI/slider
//  chiều cao thuộc sở hữu của 2.3. Đọc/ghi qua NudgeCoordinatorIOS (App Group, 2 khoá mới
//  bellReminderEnabled/bellSnoozeUntil). Chỉ hiện trạng thái bật/tắt + đang-hoãn-hay-không —
//  KHÔNG hiển thị số câu/số lần đã nhắc (AC#5, không gamify).
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : UIViewController
@end

NS_ASSUME_NONNULL_END
