//
//  MacroBridge.h
//  mindful-key — shared (iOS container <-> keyboard extension)
//
//  Cầu nối App Group cho DANH SÁCH MACRO (gõ tắt) người dùng tự định nghĩa trong màn quản lý
//  của container — TÁCH BIỆT khỏi AppGroupBridge.h (chỉ 2 khoá heartbeat vận hành) và
//  KeyboardSettingsBridge (story 2.3, inputType/heightLevel). Đúng tiền lệ "1 bridge = 1 mối
//  quan tâm" (xem Learnings from Previous Stories, story 2.4).
//
//  Vì sao macro KHÔNG vi phạm ràng buộc "App Group không chứa nội dung gõ" của AppGroupBridge.h:
//  ràng buộc đó nhắm nội dung gõ THEO THỜI GIAN THỰC (giám sát riêng tư). Macro là dữ liệu người
//  dùng CHỦ ĐỘNG cấu hình trong 1 màn cài đặt (giống settings, không giống dòng chữ đang gõ ở app
//  khác). Xem story 2.4 Dev Notes.
//
//  Vì sao dùng NSDictionary (trigger/content) thay vì định dạng byte của
//  initMacroMap/getMacroSaveData: container app (MindfulKeyiOS) KHÔNG link core/engine (chỉ
//  MindfulKeyKeyboard/MindfulKey macOS link) — bắt container tự dựng byte-format sẽ kéo theo việc
//  định nghĩa lại 22 extern int engine cần, phình phạm vi ngoài scope story. MacroBridge lưu
//  plist-compatible thuần Foundation; phía extension (đã link core/engine) đọc mảng này rồi tự
//  gọi addMacro(). Xem story 2.4 Dev Notes.
//
//  KHÔNG import UIKit/AppKit — thuần Foundation, để tests/ios chạy được trên host và dùng chung
//  được cho cả vỏ macOS lẫn iOS mà không lệ thuộc API riêng OS.
//

#ifndef MacroBridge_h
#define MacroBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Tên khoá bên trong mỗi NSDictionary của mảng trả về bởi MacroBridge_ReadAll() — export ở đây
// để mọi consumer (extension lẫn container) đọc đúng cùng 2 khoá, không tự gõ lại literal.
FOUNDATION_EXPORT NSString *const MacroBridgeFieldTrigger;   // từ gõ tắt, vd "vn"
FOUNDATION_EXPORT NSString *const MacroBridgeFieldContent;   // nội dung bung, vd "Việt Nam"

// Đọc TOÀN BỘ macro đã lưu qua App Group group.vn.gnh.mindfulkey. Mỗi phần tử là 1 NSDictionary
// 2 khoá: "trigger" (từ gõ tắt) / "content" (nội dung bung). Suite không mở được (entitlement
// thiếu/sai) hoặc chưa từng ghi gì → trả mảng RỖNG, không crash (đúng AC #5: mặc định rỗng).
// FOUNDATION_EXPORT = extern "C" khi biên dịch C++ (.mm) → giữ C linkage nhất quán, để container
// (.m, Objective-C thuần) và extension (.mm, Objective-C++) cùng gọi được một symbol.
FOUNDATION_EXPORT NSArray<NSDictionary<NSString *, NSString *> *> *MacroBridge_ReadAll(void);

// Ghi lại TOÀN BỘ danh sách macro (THAY THẾ hoàn toàn danh sách cũ, không append) qua App Group.
// Gọi ngay sau mỗi thao tác thêm/sửa/xoá thành công ở màn quản lý macro (AC #1: không có nút
// "Lưu" tổng). Suite không mở được → trả NO, không crash (caller tự quyết định báo lỗi hay im
// lặng bỏ qua).
FOUNDATION_EXPORT BOOL MacroBridge_WriteAll(NSArray<NSDictionary<NSString *, NSString *> *> *macros);

NS_ASSUME_NONNULL_END

#endif /* MacroBridge_h */
