//
//  EngineKeyMap.h
//  mindful-key — shared (macOS + iOS)
//
//  Rút từ platforms/apple/macos/OpenKey.mm (keyStringToKeyCodeMap, dòng 29-43) — bảng tra
//  ký tự gõ -> hằng số KEY_x của core/engine (core/engine/platforms/mac.h). Thuần Foundation
//  (NSDictionary), không đụng AppKit/UIKit, nên dùng chung được cho cả 2 vỏ Apple.
//
//  macOS cần bảng này để bù layout bàn phím vật lý lệch chuẩn (ConvertKeyStringToKeyCode
//  trong OpenKey.mm). iOS cần CHÍNH bảng này làm đường vào chính: bàn phím tự vẽ không có
//  keycode phần cứng, chỉ biết "người dùng chạm chữ nào" — phải tra ngược ra KEY_x trước khi
//  gọi vKeyHandleEvent().

#import <Foundation/Foundation.h>

// Map ký tự thường (chưa phân biệt hoa/thường — Shift/Caps xử lý riêng ở lớp gọi) sang
// hằng số KEY_x của core/engine. Giá trị y hệt platforms/apple/macos/OpenKey.mm.
FOUNDATION_EXPORT NSDictionary<NSString *, NSNumber *> *EngineKeyMap_CharacterToKeyCode(void);
