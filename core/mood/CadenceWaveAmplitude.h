//
//  CadenceWaveAmplitude.h
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ: macOS · iOS · Windows)
//
//  [MINDFUL] 2026-08-02 (issue #8, Q4) — ĐỔI TÊN + ĐỔI NGUỒN NUÔI từ `EmotionWaveAmplitude.h`.
//  Con sóng `~` là NHẬN DIỆN LÕI (docs/01-intent.md §4.1) — hình học vẫn ở lại. Nhưng nguồn nuôi
//  cũ (`risk` [0,1], điểm chấm từ ĐỌC NỘI DUNG câu) đã chết theo ADR-0013. Nguồn mới là NHỊP GÕ
//  (CPM) — hàm này quy CPM về biên độ sóng chuẩn hoá [0,1].
//
//  VÌ SAO NHẬN HAI THAM SỐ THÔ (cpm, thresholdCpm) — KHÔNG để vỏ tự chia `cpm/threshold` rồi mới
//  truyền một số đã quy về [0,1]:
//  Bản `risk` cũ chỉ nhận MỘT tham số vì risk tự nó đã bị chặn trong [0,1] — không có phép chia
//  nào cần làm trước khi gọi. CPM thì không có trần tự nhiên như vậy: nó có NGƯỠNG NGƯỜI DÙNG CHỌN
//  làm mốc so sánh. Nếu để mỗi vỏ tự tính `cpm/threshold` trước khi gọi, phép chia + hằng vùng chết
//  + hằng bão hoà sẽ nằm rải rác ở 3 nơi khác nhau — đúng cái bẫy HĐ-6 mô tả: lexicon send-risk
//  từng trôi lệch thật giữa macOS và iOS vì đúng kiểu "chia nhỏ logic ra nhiều vỏ" này. Nhận cả hai
//  tham số thô thì phép chia nằm DUY NHẤT trong thân hàm C++ dùng chung — vỏ chỉ đọc CPM + ngưỡng
//  rồi gọi thẳng, không còn phép tính nào để tự diễn giải khác nhau.
//
//  VÌ SAO BÃO HOÀ TIỆM CẬN — KHÔNG kẹp cứng tại ngưỡng (như bản `risk` cũ làm ở risk=1.0):
//  Kẹp cứng nghĩa là CPM 400/500/800/2000 (với ngưỡng 400) đều vẽ ra CÙNG một biên độ 1.0 — mất
//  hẳn khả năng phân biệt "vừa chạm ngưỡng" với "vượt ngưỡng rất xa", đúng lúc đó là thông tin sóng
//  nên thể hiện. Bão hoà tiệm cận (Hill n=2) giữ tính đơn điệu liên tục xuyên suốt: 800 CPM
//  (~0.959) và 2000 CPM (~0.995) vẫn khác nhau về số, chỉ là khác biệt nhỏ dần — không bao giờ
//  "phẳng lì" ở 1.0. Đây là mất thông tin có chủ đích ở vùng xa, không phải lỗi.
//
//  VÌ SAO VÙNG CHẾT LÀ TỈ LỆ (kCadenceWaveDeadZoneRatio, so với NGƯỠNG) — KHÔNG phải một giá trị
//  CPM tuyệt đối: người dùng chọn một trong ba ngưỡng (300/400/500). Vùng chết tuyệt đối (vd "dưới
//  120 CPM luôn phẳng") sẽ không co giãn theo lựa chọn đó — với ngưỡng 300 nó chiếm 40% khoảng, với
//  ngưỡng 500 chỉ còn 24%, tức nhìn "phẳng" khác hẳn nhau giữa hai người dùng dù cùng một trải
//  nghiệm tương đối. Vùng chết theo TỈ LỆ (0.3 × ngưỡng) tự co giãn: mọi ngưỡng đều bắt đầu dâng
//  sóng ở đúng 30% quãng đường tới ngưỡng của mình.
//
//  Công thức đầy đủ + bảng mốc số: docs/tasks/typing-cadence-bell-execution.md §2 (Q4, 2026-08-02).
//
//  🟡 CHỐT TẠM — `kCadenceWaveSaturationK = 0.1225` suy ngược từ mốc "biên độ = 0.80 đúng tại
//  cpm == threshold" (docs/tasks/MOOD-WAVE-MECHANISM.md:192, ba mốc 0.12/0.45/0.80). Nhưng chính
//  tài liệu đó ghi rõ ba mốc này là "mốc hình học đang dùng, KHÔNG PHẢI kết quả của công thức đã
//  chốt" — tức là MỤC TIÊU hiệu chỉnh, không phải bằng chứng đã có ai gõ thật để kiểm. Cần chủ dự
//  án nhìn sóng thật ở vài mốc CPM trước khi khoá con số này. Xem spec/typing-cadence-bell/README.md
//  §5 Q4.
//
//  KHÔNG có nhánh "Tắt chuông" trong hàm này. Hàm LUÔN đòi một `thresholdCpm` cụ thể — "Tắt chuông"
//  chỉ tắt TIẾNG (thuộc BellPolicy), KHÔNG làm biến mất mốc quy đổi của sóng: con sóng là nhận diện
//  lõi, độc lập với việc chuông có kêu hay không (docs/01-intent.md §4.1). Vỏ giữ ngưỡng tham chiếu
//  của sóng (`waveReferenceThresholdCpm`) tách biệt khỏi cờ bật/tắt chuông (`bellEnabled`).

#ifndef CadenceWaveAmplitude_h
#define CadenceWaveAmplitude_h

#ifdef __cplusplus
extern "C" {
#endif

// Vùng chết là TỈ LỆ so với `thresholdCpm`, không phải một giá trị CPM tuyệt đối — xem giải trình
// ở trên. cpm < 0.3 * thresholdCpm luôn cho biên độ = 0.0 ("mặt hồ phẳng").
extern const double kCadenceWaveDeadZoneRatio; // 0.3

// (cpm, thresholdCpm) -> biên độ CHUẨN HOÁ [0.0, 1.0]:
//   - cpm < kCadenceWaveDeadZoneRatio * thresholdCpm  -> 0.0 (vùng chết, gồm cả cpm âm)
//   - trên vùng chết                                  -> tăng ĐƠN ĐIỆU, LIÊN TỤC, bão hoà tiệm cận
//                                                        về 1.0 khi cpm vượt ngưỡng rất xa, KHÔNG
//                                                        bao giờ chạm hay vượt 1.0
//   - cpm == thresholdCpm                             -> ~0.80 (🟡 chốt tạm, xem giải trình ở trên)
//
// `thresholdCpm <= 0` không crash/NaN — kẹp về 1.0 nội bộ trước khi chia (cùng phong cách kẹp
// chia-0 của TypingCadence::currentCPM). Đây là kẹp AN TOÀN VẬN HÀNH, không phải cách biểu đạt
// "Tắt chuông" — xem giải trình "KHÔNG có nhánh Tắt chuông" ở trên.
//
// Bên gọi (view) tự nhân kết quả này với biên độ pixel tối đa của khung vẽ — hàm này không biết
// gì về UIKit/AppKit/GDI+/kích thước view.
double CadenceWaveAmplitude(double cpm, double thresholdCpm);

#ifdef __cplusplus
}
#endif

#endif /* CadenceWaveAmplitude_h */
