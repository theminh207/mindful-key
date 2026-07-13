//
//  AppGroupConstants.h
//  mindful-key — shared (macOS + iOS)
//
//  Chuỗi App Group đã CHỐT (Q7, 2026-07-11) — PHẢI trùng byte-for-byte với 2 file .entitlements
//  (MindfulKeyiOS + KeyboardExtension). Trước story 2.4, chuỗi này bị lặp lại làm literal riêng
//  trong AppGroupBridge.mm — epics.md Notes đã flag "Chuỗi App Group literal lặp nhiều lần → gom
//  hằng số dùng chung khi dev." File này là điểm gom MỚI cho mọi bridge App Group THÊM SAU
//  (MacroBridge ở đây, KeyboardSettingsBridge story 2.3...). AppGroupBridge.h/.mm (sở hữu bởi
//  story 1.6) giữ nguyên literal riêng của nó — KHÔNG đụng file đó (đóng băng theo Owned Scope
//  story 2.4).
//
//  #define thay vì extern NSString* — tránh phải thêm 1 file .mm chỉ để định nghĩa 1 hằng số.
//

#ifndef AppGroupConstants_h
#define AppGroupConstants_h

#define kMindfulKeyAppGroupSuiteName @"group.vn.gnh.mindfulkey"

#endif /* AppGroupConstants_h */
