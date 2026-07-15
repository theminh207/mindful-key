//
//  EmotionRiverView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Áo mới v2 (2026-07-13, decision-log "Diện mạo mới v2" mục 3/4) — thẻ "dòng sông":
//  mở rộng con sóng ~ (EmotionWaveView) theo THỜI GIAN trong ngày — 1 đường teal lượn theo biên
//  độ mỗi "nhịp lấy mẫu" (Bước 3 sẽ ghi 1 điểm mỗi lần chuông ngân, xem decision-log mục 4/6).
//
//  View NÀY chỉ là cái KHUNG + trạng thái TRỐNG thật thà — Bước 3 (nguồn dữ liệu thật) CHƯA làm.
//  `setSamples:` là chỗ cắm để bước sau đổ dữ liệu thật vào mà KHÔNG cần sửa layout/host.
//
//  Ràng buộc HIẾN CHƯƠNG khoá trong file này (docs/AGENT-BRIEF.md §2.2/2.3, decision-log dec.4):
//    - 1 hue teal, chỉ đổi biên độ. KHÔNG valence-color (tốt/xấu), KHÔNG số/chuỗi-ngày-liên-tục/heatmap.
//    - CHƯA có mẫu (samples nil/rỗng) → KHÔNG vẽ đường sông/chấm giả. Hiện trạng thái trống
//      THẬT THÀ (vd "Hồ chưa đủ nét — ngày mới bắt đầu"), không giả vờ "phẳng lặng".
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmotionRiverView : NSView

/// Biên độ mỗi nhịp lấy mẫu trong ngày (0.0..1.0), hoặc NSNull cho quãng trống (chưa/không gõ).
/// nil hoặc rỗng = CHƯA có dữ liệu → view hiện trạng thái trống thật thà (KHÔNG vẽ đường/chấm giả).
- (void)setSamples:(nullable NSArray *)samples;

/// [MINDFUL] Story 3.7 — đổi 4 nhãn trục (mặc định "Sáng"/"Trưa"/"Chiều"/"Tối" khi không gọi
/// method này). Dùng khi 1 điểm không còn nghĩa là "1 nhịp trong ngày" mà là "1 ngày trong
/// tuần/tháng" — KHÔNG đổi setSamples:/preferredHeight đã khoá từ 2.4. Cần ĐÚNG 4 phần tử.
- (void)setAxisLabels:(NSArray<NSString *> *)labels;

/// [MINDFUL] Story 3.6 v2 — ẩn dòng caption tự sinh (mặc định hiện). Dùng khi host tự viết câu
/// quan sát riêng ngay bên dưới (vd ReflectionScreenMac) và không muốn 2 câu chồng nhau.
/// preferredHeight tự trừ phần caption khi bị ẩn — KHÔNG đổi setSamples:/preferredHeight đã khoá.
- (void)setCaptionHidden:(BOOL)hidden;

/// Chiều cao cần để hiện đủ thẻ (vùng vẽ + nhãn trục Sáng/Trưa/Chiều/Tối + caption) — host popover
/// dùng để xếp layout.
- (CGFloat)preferredHeight;

@end

NS_ASSUME_NONNULL_END
