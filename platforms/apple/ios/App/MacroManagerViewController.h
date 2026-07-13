//
//  MacroManagerViewController.h
//  mindful-key — iOS container app (màn Gõ tắt, story 2.4)
//
//  Màn quản lý macro (gõ tắt): xem/thêm/sửa/xoá, áp dụng NGAY khi xác nhận từng hành động
//  (không có nút "Lưu" tổng — đúng tinh thần "slider trực tiếp" đã dùng ở màn Cài đặt story 2.3).
//  Đọc/ghi qua MacroBridge (App Group group.vn.gnh.mindfulkey) — KHÔNG gọi thẳng core/engine
//  (container app không link core/engine, xem MacroBridge.h Dev Notes).
//

#import <UIKit/UIKit.h>

// Push trực tiếp từ Home (AppDelegate mk_makeMacroManager) — tự pop lại về màn trước qua nút
// "Quay lại" riêng (nav bar hệ thống đang ẩn toàn app, xem AppDelegate.m), không cần callback.
@interface MacroManagerViewController : UIViewController
@end
