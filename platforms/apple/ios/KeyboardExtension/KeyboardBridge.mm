//
//  KeyboardBridge.mm
//  mindful-key — iOS keyboard extension (Round 1 walking skeleton)
//
//  Định nghĩa 21 biến `extern int` mà core/engine/Engine.h khai báo (core/engine/*.cpp CHỈ
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

static dispatch_once_t sKeyboardBridgeInitOnce;

void KeyboardBridge_Init(void) {
    dispatch_once(&sKeyboardBridgeInitOnce, ^{
        vKeyInit();
    });
}
