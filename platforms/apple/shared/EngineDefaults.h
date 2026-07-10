//
//  EngineDefaults.h
//  mindful-key — shared (macOS + iOS)
//
//  core/engine/Engine.h khai báo 21 biến `extern int` (+ 1 con trỏ hàm vOnWordCommitted,
//  core/engine/Engine.cpp đã tự định nghĩa cái đó) mà Engine.cpp CHỈ dùng qua extern —
//  không định nghĩa. Bất kỳ vỏ OS nào dùng core/engine đều PHẢI tự định nghĩa 21 biến này.
//  File này chỉ khai báo GIÁ TRỊ MẶC ĐỊNH dùng chung (macro, không chiếm bộ nhớ) — nơi thật
//  sự ĐỊNH NGHĨA (int vX = ...) nằm ở từng vỏ (xem platforms/apple/macos/AppDelegate.m cho
//  macOS, platforms/apple/ios/KeyboardExtension/KeyboardBridge.mm cho iOS).
//
//  Giá trị lấy nguyên xi từ platforms/apple/macos/AppDelegate.m dòng 32-62, TRỪ
//  kEngineDefaultSwitchKeyStatus — xem giải thích dưới.

#ifndef EngineDefaults_h
#define EngineDefaults_h

#define kEngineDefaultLanguage              1   // 1 = tiếng Việt
#define kEngineDefaultInputType             0   // 0 = Telex (vTelex trong DataType.h)
#define kEngineDefaultFreeMark               0
#define kEngineDefaultCodeTable               0   // 0 = Unicode dựng sẵn
#define kEngineDefaultCheckSpelling         1
#define kEngineDefaultUseModernOrthography  1
#define kEngineDefaultQuickTelex            0
#define kEngineDefaultRestoreIfWrongSpelling 0
#define kEngineDefaultFixRecommendBrowser   1
#define kEngineDefaultUseMacro              1
#define kEngineDefaultUseMacroInEnglishMode 1
#define kEngineDefaultAutoCapsMacro         0
#define kEngineDefaultUseSmartSwitchKey     1
#define kEngineDefaultUpperCaseFirstChar    0
#define kEngineDefaultTempOffSpelling       0
#define kEngineDefaultAllowConsonantZFWJ    0
#define kEngineDefaultQuickStartConsonant   0
#define kEngineDefaultQuickEndConsonant     0
#define kEngineDefaultRememberCode          1
#define kEngineDefaultOtherLanguage         1
#define kEngineDefaultTempOffOpenKey        0

// vSwitchKeyStatus (macOS: DEFAULT_SWITCH_STATUS = 0x7A000206 = phím tắt Option+Z toàn hệ
// thống, dùng để đổi Việt/Anh không cần rời bàn phím vật lý). core/engine KHÔNG tự đọc biến
// này (0 lần xuất hiện trong core/engine/*.cpp — xác nhận bằng grep) — nó chỉ tồn tại để
// SHELL macOS tự so khớp phím tắt qua CGEventTap (OpenKey.mm: checkHotKey/GET_SWITCH_KEY).
// iOS KHÔNG có khái niệm phím tắt toàn cục (bàn phím tự vẽ, đổi ngôn ngữ qua nút bấm ngay
// trong khung bàn phím) — dùng sentinel "không có hotkey" (EMPTY_HOTKEY trong OpenKey.mm)
// thay vì copy mù giá trị Option+Z vô nghĩa trên iOS.
#define kEngineDefaultSwitchKeyStatusIOS    0xFE0000FE

#endif /* EngineDefaults_h */
