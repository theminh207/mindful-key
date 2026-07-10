//
//  EngineKeyMap.mm
//  mindful-key — shared (macOS + iOS)
//
//  Xem EngineKeyMap.h. Nội dung bảng copy nguyên xi từ
//  platforms/apple/macos/OpenKey.mm dòng 29-43 (keyStringToKeyCodeMap) — KHÔNG đổi giá trị,
//  chỉ đổi chỗ ở để dùng chung.

#import "EngineKeyMap.h"

NSDictionary<NSString *, NSNumber *> *EngineKeyMap_CharacterToKeyCode(void) {
    static NSDictionary<NSString *, NSNumber *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            // Characters from number row
            @"`": @50, @"~": @50, @"1": @18, @"!": @18, @"2": @19, @"@": @19, @"3": @20, @"#": @20, @"4": @21, @"$": @21,
            @"5": @23, @"%": @23, @"6": @22, @"^": @22, @"7": @26, @"&": @26, @"8": @28, @"*": @28, @"9": @25, @"(": @25,
            @"0": @29, @")": @29, @"-": @27, @"_": @27, @"=": @24, @"+": @24,
            // Characters from first keyboard row
            @"q": @12, @"w": @13, @"e": @14, @"r": @15, @"t": @17, @"y": @16, @"u": @32, @"i": @34, @"o": @31, @"p": @35,
            @"[": @33, @"{": @33, @"]": @30, @"}": @30, @"\\": @42, @"|": @42,
            // Characters from second keyboard row
            @"a": @0, @"s": @1, @"d": @2, @"f": @3, @"g": @5, @"h": @4, @"j": @38, @"k": @40, @"l": @37,
            @";": @41, @":": @41, @"'": @39, @"\"": @39,
            // Characters from second third row
            @"z": @6, @"x": @7, @"c": @8, @"v": @9, @"b": @11, @"n": @45, @"m": @46,
            @",": @43, @"<": @43, @".": @47, @">": @47, @"/": @44, @"?": @44
        };
    });
    return map;
}
