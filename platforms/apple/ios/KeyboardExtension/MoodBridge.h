//
//  MoodBridge.h
//  mindful-key — iOS keyboard extension (Round 2, story 2.2)
//
//  Cầu nối engine (vOnWordCommitted) <-> lớp cảm xúc iOS. Gom từ qua core/mood/MoodBuffer rồi
//  tính send-risk bằng SendRiskAnalyzer (platforms/apple/shared/), CHẠY BẤT ĐỒNG BỘ trên 1
//  serial queue riêng — callback engine gọi (đồng bộ, SÂU bên trong vKeyHandleEvent(), trên
//  cùng thread xử lý phím) chỉ đọc 1 cờ đã cache rồi dispatch_async, KHÔNG BAO GIỜ chạy lexicon
//  trên thread đó (AC#2, NFR-02).
//
//  RIÊNG TƯ (cứng, AC#3): khi cờ ô bảo mật đang bật, callback trả về NGAY — không đẩy từ vào
//  buffer, không phân tích, không cập nhật risk đang phơi ra. KHÔNG NSLog/os_log nội dung đã gõ
//  ở đâu trong cầu nối này.
//
//  Story 2.2 KHÔNG hiển thị gì (không thanh gợi ý, không sóng, không chuông) — chỉ phơi
//  MoodBridge_LastSendRisk() cho story 2.5/2.6 tiêu thụ sau này.
//

#ifndef MoodBridge_h
#define MoodBridge_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// Gọi 1 lần lúc extension khởi động (viewDidLoad, cạnh KeyboardBridge_Init()). Tạo serial queue
// riêng (nếu chưa có) rồi set con trỏ vOnWordCommitted của engine trỏ tới callback MoodBridge.
void MoodBridge_Init(void);

// Setter cache — KeyboardViewController (nơi DUY NHẤT có textDocumentProxy) gọi hàm này truyền
// [self mk_isSecureField] NGAY TRƯỚC mỗi lần đưa phím vào KeyboardBridge_Handle*. Callback engine
// gọi không có tham chiếu tới UIKit nên không tự hỏi được — đây là đường DUY NHẤT để trạng thái
// ô bảo mật tới được MoodBridge (đúng hợp đồng "gọi cổng TRƯỚC" đã khoá ở story 1.4 AC#6).
void MoodBridge_SetSecureFieldActive(BOOL active);

// Getter — risk [0.0, 1.0] mới nhất do SendRiskAnalyzer tính, mặc định 0.0 tới khi có phân tích
// đầu tiên. Hàm THUẦN, không side-effect.
double MoodBridge_LastSendRisk(void);

// CHỈ DÙNG TRONG TEST (tests/ios/mood_bridge_test.mm). Chặn (block) cho tới khi mọi việc đã
// dispatch_async vào serial queue riêng của MoodBridge TÍNH TỚI THỜI ĐIỂM GỌI chạy xong —
// dispatch_sync 1 block rỗng vào CHÍNH queue đó, đúng nguyên tắc "đồng bộ hoá test qua
// dispatch_sync no-op, không sleep()/polling" (testing-master + Learnings story 2.2). KHÔNG gọi
// hàm này từ code sản phẩm (KeyboardViewController/MoodBridge nội bộ) — chỉ test được phép gọi.
void MoodBridge_FlushForTesting(void);

#ifdef __cplusplus
}
#endif

#endif /* MoodBridge_h */
