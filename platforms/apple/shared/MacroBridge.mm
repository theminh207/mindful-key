//
//  MacroBridge.mm
//  mindful-key — shared (iOS container <-> keyboard extension)
//
//  Xem MacroBridge.h. 1 khoá App Group MỚI — KHÔNG đụng 2 khoá heartbeat của AppGroupBridge.mm
//  hay 2 khoá inputType/heightLevel của KeyboardSettingsBridge (story 2.3).
//

#import "MacroBridge.h"
#import "AppGroupConstants.h"

// Chuỗi App Group — gom từ AppGroupConstants.h (xem comment ở đó) thay vì lặp literal riêng.
static NSString *const kMacroAppGroupSuiteName = kMindfulKeyAppGroupSuiteName;

// Khoá App Group riêng cho danh sách macro — mảng plist-compatible các NSDictionary.
static NSString *const kKeyMacroList = @"macroList";

// Tên khoá bên trong mỗi phần tử của kKeyMacroList — định nghĩa thật của 2 hằng số export ở
// MacroBridge.h (MacroBridgeFieldTrigger/MacroBridgeFieldContent).
NSString *const MacroBridgeFieldTrigger = @"trigger";
NSString *const MacroBridgeFieldContent = @"content";
static NSString *const kMacroFieldTrigger = MacroBridgeFieldTrigger;
static NSString *const kMacroFieldContent = MacroBridgeFieldContent;

NSArray<NSDictionary<NSString *, NSString *> *> *MacroBridge_ReadAll(void) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kMacroAppGroupSuiteName];
    if (shared == nil) {
        // Suite không mở được (entitlement thiếu/sai) → mảng rỗng an toàn, không crash.
        return @[];
    }
    id raw = [shared arrayForKey:kKeyMacroList];
    if (![raw isKindOfClass:[NSArray class]]) {
        return @[]; // chưa từng ghi gì (AC #5: mặc định RỖNG) hoặc dữ liệu hỏng.
    }

    NSMutableArray<NSDictionary<NSString *, NSString *> *> *out = [NSMutableArray array];
    for (id item in (NSArray *)raw) {
        if (![item isKindOfClass:[NSDictionary class]]) continue; // bỏ qua phần tử hỏng, không crash.
        NSDictionary *dict = (NSDictionary *)item;
        id trigger = dict[kMacroFieldTrigger];
        id content = dict[kMacroFieldContent];
        if ([trigger isKindOfClass:[NSString class]] && [content isKindOfClass:[NSString class]]) {
            [out addObject:@{kMacroFieldTrigger: trigger, kMacroFieldContent: content}];
        }
    }
    return out;
}

BOOL MacroBridge_WriteAll(NSArray<NSDictionary<NSString *, NSString *> *> *macros) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kMacroAppGroupSuiteName];
    if (shared == nil) {
        return NO; // Suite không mở được — caller tự quyết định báo lỗi hay im lặng bỏ qua.
    }
    // Ghi lại đúng mảng NSDictionary<trigger,content> đầu vào — plist-compatible, NSUserDefaults
    // tự serialize, không cần bước chuyển đổi thêm.
    [shared setObject:macros forKey:kKeyMacroList];
    return YES;
}
