//
//  KeyboardBridge.h
//  mindful-key — iOS keyboard extension (Round 1 walking skeleton)
//
//  Cầu nối DUY NHẤT giữa vỏ bàn phím iOS và core/engine (bộ não C++ dùng chung).
//  - Mốc A: KeyboardBridge_Init() — chứng minh engine build + init được trong sandbox extension.
//  - Mốc B: KeyboardBridge_HandleKeyTap() — đưa 1 lần chạm phím vào vKeyHandleEvent() rồi GIẢI MÃ
//    kết quả HookState thành thao tác trên ô nhập (xoá lùi + chèn chuỗi). Logic diễn giải HookState
//    giống hệt vỏ macOS (OpenKey.mm) và harness tham chiếu tests/core/test_engine.cpp (typeChar).
//
//  KHÔNG import UIKit ở đây — file này thuần Foundation nên tests/ios chạy được trên host (không
//  cần Simulator). Việc áp kết quả lên UITextDocumentProxy nằm ở KeyboardViewController.
//  KHÔNG sửa core/engine — chỉ tiêu thụ qua Engine.h.

#import <Foundation/Foundation.h>

// Thao tác cần áp lên ô nhập sau 1 lần chạm phím, đã giải mã sẵn khỏi HookState của engine.
@interface KeyboardBridgeResult : NSObject
// Số lần xoá lùi (deleteBackward) cần làm TRƯỚC khi chèn.
@property (nonatomic, assign) NSInteger backspaceCount;
// Chuỗi cần chèn (insertText) SAU khi xoá. Đã xếp đúng thứ tự hiển thị. Rỗng = không chèn.
@property (nonatomic, copy) NSString *textToInsert;
@end

// Gọi 1 lần lúc extension khởi động (viewDidLoad). Định nghĩa 22 biến extern của Engine.h
// (xem platforms/apple/shared/EngineDefaults.h) rồi gọi vKeyInit(), giữ con trỏ HookState.
void KeyboardBridge_Init(void);

// Mốc B: đưa 1 lần chạm phím vào engine, trả thao tác cần áp lên ô nhập.
//   keyCode = hằng số KEY_x của core/engine (core/engine/platforms/mac.h). Với phím chữ, tra
//             từ EngineKeyMap_CharacterToKeyCode(); space = KEY_SPACE, xoá = KEY_DELETE.
//   isShift = phím Shift/Caps đang bật (Round 1 chưa vẽ Shift → luôn NO, để sẵn tham số cho sau).
// Giả định vCodeTable = 0 (Unicode dựng sẵn) đúng như mặc định Round 1.
KeyboardBridgeResult *KeyboardBridge_HandleKeyTap(unsigned short keyCode, BOOL isShift);

// Tiện ích ngữ nghĩa để vỏ UI khỏi cần biết mã phím KEY_x của engine: chạm phím cách / xoá.
// Cả hai vẫn ĐI QUA engine (để buffer từ trong bộ não luôn đồng bộ), không chèn/xoá "tắt".
KeyboardBridgeResult *KeyboardBridge_HandleSpace(void);
KeyboardBridgeResult *KeyboardBridge_HandleBackspace(void);

// Story 2.1 — đổi kiểu gõ Telex<->VNI.
//
// Đổi giá trị biến `vInputType` engine đã định nghĩa sẵn (KeyboardBridge.mm dòng 14, mặc định
// vTelex) — KHÔNG tạo biến mới. Đây là thay đổi CẤU HÌNH (không phải đường chèn văn bản) nên
// KHÔNG bắt buộc đi qua vKeyHandleEvent(). An toàn gọi bất cứ lúc nào: engine tự đọc vInputType
// ở đầu mỗi macro xử lý phím (IS_KEY_S/IS_KEY_F/...), không có state trung gian "kiểu gõ lúc bắt
// đầu từ" — nếu gọi giữa 1 từ đang gõ dở, những phím tiếp theo trong CÙNG từ áp bảng MỚI ngay
// (verify hành vi thật, ghi lại trong Dev Agent Record — không giả định).
void KeyboardBridge_ToggleInputType(void);

// YES nếu đang ở kiểu gõ VNI, NO nếu Telex. Tiện cho vỏ UI khỏi phải import core/engine để biết
// enum vKeyInputType — giữ KeyboardBridge là cửa DUY NHẤT vào engine (đúng doc-comment đầu file).
BOOL KeyboardBridge_IsVNI(void);
