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

/// Biên độ mỗi mẫu (0.0..1.0), hoặc NSNull cho quãng trống (chưa/không gõ) — mẫu giãn ĐỀU theo
/// thứ tự. Đúng cho Tuần/Tháng (1 chấm = 1 ngày, các ngày vốn cách đều nhau).
/// KHÔNG dùng cho "Hôm nay" — nhịp chuông trong ngày cách nhau không đều, dùng
/// setTodaySamples:gapSeconds: để chấm nằm đúng giờ.
/// nil hoặc rỗng = CHƯA có dữ liệu → view hiện trạng thái trống thật thà (KHÔNG vẽ đường/chấm giả).
- (void)setSamples:(nullable NSArray *)samples;

/// [MINDFUL] Vá trục thời gian (2026-07-16) — mẫu của HÔM NAY, đặt theo GIỜ THẬT trong ngày.
/// Trước đó "Hôm nay" cũng đi qua setSamples: (giãn đều theo thứ tự) nên chấm cuối LUÔN dính mép
/// phải — tức luôn nằm dưới nhãn "Tối", kể cả khi nó vừa được ghi lúc 10h sáng. Bắt được trên máy
/// chủ dự án 2026-07-16: 7 mẫu trong 48 phút buổi sáng bị vẽ như trọn một ngày.
///
/// @param samples Mảng dict `{@"ts": epoch giây (NSNumber), @"value": biên độ 0..1 (NSNumber)}`,
///                xếp tăng dần theo ts — đúng dạng `MoodStoreMac_FetchTodaySamples()` trả về.
/// @param gapSeconds 2 mẫu cách nhau quá ngần này = quãng không gõ → không nối nước qua (dec.4).
///                   Thường là `vBellInterval * 60 * 1.5`. Truyền 0 để không bao giờ ngắt.
- (void)setTodaySamples:(nullable NSArray<NSDictionary *> *)samples gapSeconds:(double)gapSeconds;

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
