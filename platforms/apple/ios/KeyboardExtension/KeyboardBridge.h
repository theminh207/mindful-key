//
//  KeyboardBridge.h
//  mindful-key — iOS keyboard extension (Round 1 walking skeleton)
//
//  Mốc A: chỉ chứng minh core/engine build + init được bên trong sandbox extension.
//  Mốc B sẽ thêm KeyboardBridge_HandleKeyTap() (gọi vKeyHandleEvent + UITextDocumentProxy).
//  KHÔNG sửa core/engine — file này CHỈ tiêu thụ core/engine/Engine.h qua extern.

#import <Foundation/Foundation.h>

// Gọi 1 lần lúc extension khởi động (viewDidLoad). Định nghĩa 21 biến extern mà
// core/engine/Engine.h khai báo (xem platforms/apple/shared/EngineDefaults.h) rồi gọi
// vKeyInit() — đây là bước chứng minh rủi ro lớn nhất của SPEC: engine có sống được trong
// tiến trình extension hay không.
void KeyboardBridge_Init(void);
