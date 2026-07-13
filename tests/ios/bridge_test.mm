//
//  bridge_test.mm
//  mindful-key — test tự động cho cầu nối iOS (KeyboardBridge) — Mốc B.
//
//  Mục đích: chứng minh WIRING của bridge (định nghĩa 22 extern config, map ký tự -> KEY_x qua
//  EngineKeyMap, gọi vKeyHandleEvent, giải mã HookState thành xoá-lùi + chèn) là ĐÚNG — bằng cách
//  cho cùng bộ ca Telex của tests/core/test_engine.cpp chạy XUYÊN QUA bridge, mô phỏng ô nhập
//  (UITextDocumentProxy) bằng một NSMutableString. KHÔNG phải UI test.
//
//  Chạy trên HOST (macOS) như tests/core — không cần Simulator. Xem build.sh.

#import <Foundation/Foundation.h>
#import "Engine.h"          // startNewSession() để reset engine giữa các ca
#import "EngineKeyMap.h"
#import "KeyboardBridge.h"

// "Ô nhập ảo" — thay cho UITextDocumentProxy: bridge trả {xoá lùi, chèn chuỗi}, ta áp vào đây.
static NSMutableString *gDoc;
static int gFail = 0;

static void applyResult(KeyboardBridgeResult *r) {
    for (NSInteger i = 0; i < r.backspaceCount; i++) {
        if (gDoc.length > 0) {
            [gDoc deleteCharactersInRange:NSMakeRange(gDoc.length - 1, 1)];
        }
    }
    if (r.textToInsert.length > 0) {
        [gDoc appendString:r.textToInsert];
    }
}

// Gõ 1 ký tự ASCII đúng như vỏ UI làm: space -> HandleSpace; chữ -> tra EngineKeyMap -> HandleKeyTap.
static void typeOneChar(unichar c) {
    if (c == ' ') {
        applyResult(KeyboardBridge_HandleSpace());
        return;
    }
    NSString *ch = [NSString stringWithCharacters:&c length:1];
    NSNumber *keyCode = EngineKeyMap_CharacterToKeyCode()[ch];
    if (keyCode == nil) {
        return; // ký tự ngoài bảng (không xảy ra với các ca Telex chữ thường)
    }
    applyResult(KeyboardBridge_HandleKeyTap(keyCode.unsignedShortValue, NO));
}

static void runCase(const char *telex, const char *expect) {
    gDoc = [NSMutableString string];
    startNewSession();

    NSString *input = [NSString stringWithUTF8String:telex];
    for (NSUInteger i = 0; i < input.length; i++) {
        typeOneChar([input characterAtIndex:i]);
    }

    NSString *expected = [NSString stringWithUTF8String:expect];
    BOOL ok = [gDoc isEqualToString:expected];
    if (!ok) gFail++;
    printf("  gõ Telex qua bridge: %-22s -> \"%s\"   [mong đợi: \"%s\"]  %s\n",
           telex, gDoc.UTF8String, expect, ok ? "OK" : "SAI <<<");
}

// Story 2.1 AC#1/AC#6: gõ CÙNG 1 chuỗi phím vật lý qua KeyboardBridge_ToggleInputType() — trước
// (Telex, mặc định) và sau khi đổi (VNI) — chứng minh việc đổi vInputType có hiệu lực NGAY, và
// cả 2 kết quả vẫn ra qua đúng đường bridge (không insertText: thô nào bỏ qua engine).
static void runInputTypeCase(const char *keys, const char *expectTelex, const char *expectVNI) {
    gDoc = [NSMutableString string];
    startNewSession();
    NSString *input = [NSString stringWithUTF8String:keys];
    for (NSUInteger i = 0; i < input.length; i++) {
        typeOneChar([input characterAtIndex:i]);
    }
    NSString *telexExpected = [NSString stringWithUTF8String:expectTelex];
    BOOL telexOK = [gDoc isEqualToString:telexExpected];
    if (!telexOK) gFail++;
    printf("  gõ %-8s Telex        -> \"%s\"   [mong đợi: \"%s\"]  %s\n",
           keys, gDoc.UTF8String, expectTelex, telexOK ? "OK" : "SAI <<<");

    KeyboardBridge_ToggleInputType();   // Telex -> VNI (AC#1: đổi có hiệu lực ngay)
    gDoc = [NSMutableString string];
    startNewSession();
    for (NSUInteger i = 0; i < input.length; i++) {
        typeOneChar([input characterAtIndex:i]);
    }
    NSString *vniExpected = [NSString stringWithUTF8String:expectVNI];
    BOOL vniOK = [gDoc isEqualToString:vniExpected];
    if (!vniOK) gFail++;
    printf("  gõ %-8s VNI (đã đổi) -> \"%s\"   [mong đợi: \"%s\"]  %s\n",
           keys, gDoc.UTF8String, expectVNI, vniOK ? "OK" : "SAI <<<");

    KeyboardBridge_ToggleInputType();   // về Telex mặc định — không rò trạng thái sang ca sau
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        KeyboardBridge_Init();

        printf("=== TEST CẦU NỐI iOS (KeyboardBridge) — Telex qua vKeyHandleEvent + UITextDocumentProxy ảo ===\n\n");
        // Cùng bộ ca của tests/core/test_engine.cpp — nhưng đi XUYÊN QUA bridge iOS, không gọi thẳng engine.
        runCase("xin chaof cacs banj", "xin chào các bạn");
        runCase("tieengs vieetj",      "tiếng việt");
        runCase("tooi ddang vui",      "tôi đang vui");
        runCase("tooi ddang buoonf",   "tôi đang buồn");
        runCase("hoom nay meejt quas", "hôm nay mệt quá");

        // Story 2.1 AC#1: cùng phím vật lý, khác vInputType -> khác kết quả (đúng bảng mark key
        // core/engine/Engine.cpp dòng 41-54 — Telex: sắc/nặng ứng với chữ S/J; VNI: ứng với
        // KEY_1/KEY_5). "1"/"5" không phải mark key ở Telex nên chèn thô; giá trị mong đợi lấy
        // từ chạy thật ./tests/ios/bridge_test (không phải suy đoán — vd "vieet" mới ghép được ê,
        // "viet5" không doubling e nên VNI ra "viẹt" [ẹ], không phải "việt" [ệ]).
        runInputTypeCase("a1", "a1", "á");
        runInputTypeCase("viet5", "viet5", "viẹt");

        if (gFail == 0) {
            printf("\n=== XONG — TẤT CẢ PASS (bridge gõ Telex ra dấu đúng) ===\n");
        } else {
            printf("\n=== XONG — %d CA SAI (make test-ios sẽ đỏ) ===\n", gFail);
        }
    }
    return gFail == 0 ? 0 : 1; // exit code != 0 để make/CI gate được
}
