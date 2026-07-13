//
//  KeyboardBridge.mm
//  mindful-key — iOS keyboard extension (Round 1 walking skeleton)
//
//  Định nghĩa 22 biến `extern int` mà core/engine/Engine.h khai báo (core/engine/*.cpp CHỈ
//  dùng qua extern, không tự định nghĩa — xem platforms/apple/shared/EngineDefaults.h để
//  biết vì sao). Không sửa 1 dòng nào trong core/engine/.

#import "KeyboardBridge.h"
#import "Engine.h"
#import "EngineDefaults.h"

int vLanguage              = kEngineDefaultLanguage;
int vInputType             = kEngineDefaultInputType;
int vFreeMark               = kEngineDefaultFreeMark;
int vCodeTable               = kEngineDefaultCodeTable;
int vSwitchKeyStatus         = kEngineDefaultSwitchKeyStatusIOS;
int vCheckSpelling         = kEngineDefaultCheckSpelling;
int vUseModernOrthography  = kEngineDefaultUseModernOrthography;
int vQuickTelex            = kEngineDefaultQuickTelex;
int vRestoreIfWrongSpelling = kEngineDefaultRestoreIfWrongSpelling;
int vFixRecommendBrowser   = kEngineDefaultFixRecommendBrowser;
int vUseMacro              = kEngineDefaultUseMacro;
int vUseMacroInEnglishMode = kEngineDefaultUseMacroInEnglishMode;
int vAutoCapsMacro         = kEngineDefaultAutoCapsMacro;
int vUseSmartSwitchKey     = kEngineDefaultUseSmartSwitchKey;
int vUpperCaseFirstChar    = kEngineDefaultUpperCaseFirstChar;
int vTempOffSpelling       = kEngineDefaultTempOffSpelling;
int vAllowConsonantZFWJ    = kEngineDefaultAllowConsonantZFWJ;
int vQuickStartConsonant   = kEngineDefaultQuickStartConsonant;
int vQuickEndConsonant     = kEngineDefaultQuickEndConsonant;
int vRememberCode          = kEngineDefaultRememberCode;
int vOtherLanguage         = kEngineDefaultOtherLanguage;
int vTempOffOpenKey        = kEngineDefaultTempOffOpenKey;
// vOnWordCommitted: core/engine/Engine.cpp đã tự định nghĩa (= nullptr mặc định) — xác nhận
// bằng thực nghiệm lúc viết tech-spec (định nghĩa lại ở đây sẽ bị lỗi "duplicate symbol").
// Round 1 KHÔNG set con trỏ này (Non-Goal: chưa nối MoodBuffer).

@implementation KeyboardBridgeResult
@end

// Con trỏ HookState do vKeyInit() trả về — engine ghi kết quả mỗi phím vào đây.
static vKeyHookState *sHookState = NULL;
static dispatch_once_t sKeyboardBridgeInitOnce;

void KeyboardBridge_Init(void) {
    dispatch_once(&sKeyboardBridgeInitOnce, ^{
        sHookState = (vKeyHookState *)vKeyInit();
    });
}

// Giải mã 1 phần tử charData sang mã Unicode (chế độ vCodeTable = 0, Unicode dựng sẵn) —
// y hệt OpenKey.mm SendNewCharString (dòng 446-457) và tests/core/test_engine.cpp decodeChar.
static unichar KBDecodeChar(Uint32 data) {
    if (data & PURE_CHARACTER_MASK) return (unichar)(data & 0xFFFF); // ký tự literal
    if (!(data & CHAR_CODE_MASK))   return (unichar)keyCodeToCharacter(data); // mã phím thô -> chữ
    return (unichar)(data & 0xFFFF); // đã là mã Unicode
}

static NSString *KBStringFromChar(unichar ch) {
    if (ch == 0) return @"";
    return [NSString stringWithCharacters:&ch length:1];
}

// Ký tự literal cho phím điều khiển mà keyCodeToCharacter() không biết (trả 0). Round 1 chỉ có
// space là phím "break" được vẽ; các phím khác trả rỗng (an toàn, không chèn bừa).
static NSString *KBLiteralForControlKey(unsigned short keyCode) {
    if (keyCode == KEY_SPACE) return @" ";
    return @"";
}

KeyboardBridgeResult *KeyboardBridge_HandleKeyTap(unsigned short keyCode, BOOL isShift) {
    KeyboardBridgeResult *result = [KeyboardBridgeResult new];
    result.backspaceCount = 0;
    result.textToInsert = @"";
    if (sHookState == NULL) {
        // Chưa init (không nên xảy ra vì viewDidLoad gọi KeyboardBridge_Init trước) — an toàn:
        // chèn thô đúng phím để không "nuốt" ký tự người dùng.
        result.textToInsert = KBStringFromChar((unichar)keyCodeToCharacter(keyCode));
        return result;
    }

    Uint8 caps = isShift ? 1 : 0;
    vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, keyCode, caps, false);

    switch (sHookState->code) {
        case vWillProcess:
        case vRestore:
        case vRestoreAndStartNewSession: {
            result.backspaceCount = sHookState->backspaceCount;

            NSMutableString *out = [NSMutableString string];
            if (sHookState->newCharCount > 0 && sHookState->newCharCount <= MAX_BUFF) {
                // charData xếp NGƯỢC (index 0 = ký tự phải nhất) — duyệt từ cuối về đầu để ra
                // đúng thứ tự hiển thị trái→phải.
                for (int i = sHookState->newCharCount - 1; i >= 0; i--) {
                    [out appendString:KBStringFromChar(KBDecodeChar(sHookState->charData[i]))];
                }
            }
            // vRestore*: từ không hợp lệ → engine trả lại chữ gốc, rồi phát lại chính phím vừa gõ.
            if (sHookState->code == vRestore || sHookState->code == vRestoreAndStartNewSession) {
                unichar rc = (unichar)keyCodeToCharacter((Uint32)keyCode | (caps ? CAPS_MASK : 0));
                if (rc != 0) {
                    [out appendString:KBStringFromChar(rc)];
                } else {
                    [out appendString:KBLiteralForControlKey(keyCode)]; // vd space kết thúc từ
                }
            }
            if (sHookState->code == vRestoreAndStartNewSession) {
                startNewSession();
            }
            result.textToInsert = out;
            break;
        }
        case vDoNothing:
        default: {
            // Engine không biến đổi — phát ký tự thô đúng như phím vừa chạm.
            unichar ch = (unichar)keyCodeToCharacter((Uint32)keyCode | (caps ? CAPS_MASK : 0));
            if (ch != 0) {
                result.textToInsert = KBStringFromChar(ch);
            } else if (keyCode == KEY_SPACE) {
                result.textToInsert = @" ";
            } else if (keyCode == KEY_DELETE) {
                result.backspaceCount = 1; // xoá 1 ký tự
            }
            // vBreakWord / vReplaceMaro (macro): Round 1 macro rỗng nên không phát sinh — rơi vào
            // đây = no-op an toàn.
            break;
        }
    }
    return result;
}

KeyboardBridgeResult *KeyboardBridge_HandleSpace(void) {
    return KeyboardBridge_HandleKeyTap(KEY_SPACE, NO);
}

KeyboardBridgeResult *KeyboardBridge_HandleBackspace(void) {
    return KeyboardBridge_HandleKeyTap(KEY_DELETE, NO);
}

void KeyboardBridge_ToggleInputType(void) {
    vInputType = (vInputType == vTelex) ? vVNI : vTelex;
}

BOOL KeyboardBridge_IsVNI(void) {
    return vInputType == vVNI;
}
