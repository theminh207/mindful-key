//
//  EmotionWaveAmplitude.h
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ: macOS · iOS · Windows)
//
//  [MINDFUL] 2026-07-17 — DỜI từ platforms/apple/ios/KeyboardExtension/. File này vốn ĐÃ thuần
//  C++ (0 chỗ dính UIKit/Foundation) và đã host-testable — nó chỉ nằm nhầm chỗ. Vỏ Windows cần
//  đúng phép quy đổi này để đổi icon khay theo biên độ (BRAND-ASSETS.md §6 "StatusAlert"), mà
//  với tới thư mục iOS thì không được. Đây là mảnh thứ NĂM của dự án bị kẹt trong 1 vỏ
//  (lexicon send-risk · bảng màu · câu chữ · hình dạng ngày · nay là biên độ sóng).
//  Đường include của cả 3 vỏ đã có core/mood nên nơi gọi KHÔNG phải sửa 1 dòng.
//
//  Hàm THUẦN risk -> biên độ sóng, đúng Q1 (decision-log.md#2026-07-13): ngưỡng chết ~0.3
//  ("mặt hồ phẳng") + dâng MƯỢT, LIÊN TỤC (không bậc thang) tới biên độ chuẩn hoá tối đa (1.0)
//  ở risk=1.0. KHÔNG phụ thuộc UIKit/Foundation — host-testable (tests/ios/emotion_wave_test.mm)
//  không cần Simulator, đúng pattern tách TÍNH khỏi VẼ đã dùng ở KeyboardBridge/MoodBridge.
//
//  KHÔNG side-effect, KHÔNG tự đọc risk (input truyền vào bởi nơi gọi) — nơi gọi
//  (KeyboardViewController, story 2.5) chịu trách nhiệm đọc MoodBridge_LastSendRisk() + tự kiểm
//  cổng Full Access / mk_isSecureField TRƯỚC khi gọi hàm này (xem Dev Notes story 2.5).

#ifndef EmotionWaveAmplitude_h
#define EmotionWaveAmplitude_h

#ifdef __cplusplus
extern "C" {
#endif

// Ngưỡng chết Q1 — risk dưới ngưỡng này luôn cho biên độ = 0.0 ("mặt hồ phẳng").
extern const double kEmotionWaveDeadZoneThreshold; // 0.3

// risk (kỳ vọng [0.0, 1.0]; NGOÀI khoảng thì tự CLAMP — không crash/NaN, xem Testing story 2.5)
// -> biên độ CHUẨN HOÁ [0.0, 1.0]:
//   - risk < kEmotionWaveDeadZoneThreshold  -> 0.0 (vùng chết, gồm cả risk âm)
//   - risk trong [threshold, 1.0]           -> tăng ĐƠN ĐIỆU, LIÊN TỤC (smoothstep — không bậc
//                                              thang/không nhảy cấp ở bất kỳ điểm nào, kể cả tại
//                                              chính ngưỡng 0.3)
//   - risk >= 1.0                           -> 1.0 (biên độ tối đa)
// Bên gọi (view) tự nhân kết quả này với biên độ pixel tối đa của khung vẽ — hàm này không biết
// gì về UIKit/kích thước view.
double EmotionWaveAmplitude(double risk);

#ifdef __cplusplus
}
#endif

#endif /* EmotionWaveAmplitude_h */
