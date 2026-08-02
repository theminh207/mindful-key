//
//  BellPolicy.h
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ: macOS · iOS · Windows)
//
//  CHÍNH SÁCH CHUÔNG: nhận CPM hiện tại (đã tính sẵn ở TypingCadence) + ngưỡng người dùng chọn,
//  trả lời đúng MỘT câu — "NGAY BÂY GIỜ có nên ngân chuông không". Đây là bước **Bell** của vòng
//  lặp `Measure → Bell → Reflect` (docs/01-intent.md §3).
//
//  ┌─────────────────────────────────────────────────────────────────────────────────────┐
//  │ [MINDFUL] KHÔNG NHẬN NỘI DUNG — cùng luật với TypingCadence.h (HĐ-1). Tham số ở đây   │
//  │ chỉ là số đo (CPM, ngưỡng, thời điểm, hai lá cờ bool) — không có đường nào cho chữ đi │
//  │ vào lớp chuông. scripts/check_hd1.py soi file này y hệt TypingCadence.h.               │
//  └─────────────────────────────────────────────────────────────────────────────────────┘
//
//  DẠNG LỚP, KHÔNG PHẢI HÀM TỰ DO — lệch so với phác thảo issue #7 (`BellPolicy_Evaluate` hàm tự
//  do trả `struct BellDecision`) và hợp đồng HĐ-2 cũ (`BellPolicy_ShouldRing` / `BellPolicy_NoteRung`,
//  hai hàm tự do). Cooldown + trạng thái chống rung là STATE — hàm tự do buộc phải giữ state đó
//  trong biến toàn cục, và ba vỏ (macOS, Windows, iOS) dùng CHUNG một biến toàn cục thì test của
//  vỏ này rò rỉ sang vỏ kia, test viết cho core cũng không dựng được nhiều thể hiện độc lập. Cùng
//  lý do TypingCadence đã chốt thành lớp ở #6 (Q3, spec/typing-cadence-bell/README.md §5). Nội
//  dung tuyên bố của HĐ-2 KHÔNG đổi (chuông ngân thì được, chặn thì không; cooldown nằm trong
//  core) — chỉ hình dạng API đổi, và `docs/04-contracts.md` đã cập nhật khối code theo đúng lớp
//  này (kèm giải trình y hệt đoạn này).
//
//  MỘT HÀM DUY NHẤT, KHÔNG PHẢI HAI — issue phác thảo tách "hỏi" (`ShouldRing`) và "báo đã reo"
//  (`NoteRung`) thành hai lời gọi riêng, trả thêm một struct `{shouldRing, cpmAtDecision}`. Gộp
//  lại thành `evaluate()` trả thẳng `bool` để loại một cách lỗi: vỏ hỏi rồi QUÊN gọi báo lại
//  (cooldown/chống rung không bao giờ nạp, chuông reo liên tục — đúng thứ lớp này tồn tại để
//  ngăn) hoặc gọi báo lại mà không thực sự phát tiếng (core nghĩ đã reo, vỏ thì im, hai bên lệch
//  trạng thái). `evaluate()` trả `true` nghĩa là "phát một tiếng NGAY, và core đã tự ghi nhận" —
//  vỏ không có bước thứ hai nào phải nhớ gọi. `cpmAtDecision` trong struct đề xuất cũng thừa: nơi
//  gọi đã tự truyền `cpm` vào, không cần core trả lại đúng giá trị đó.
//
//  THỜI ĐIỂM LÀ int64_t MILI-GIÂY, KHÔNG PHẢI double GIÂY — issue phác thảo `double nowSeconds`.
//  Đổi sang int64_t mili-giây để cùng đơn vị với `TypingCadence::registerKeystroke(int64_t nowMs)`
//  (đã chốt ở #6): vỏ có sẵn một mốc thời gian nguyên mili-giây từ hook bàn phím, dùng lại nguyên
//  con số đó cho cả hai lớp thay vì phải đổi đơn vị + chịu sai số dấu phẩy động ở một hợp đồng lõi.
//
//  KHÔNG cấp phát, KHÔNG khóa, KHÔNG ngoại lệ, KHÔNG tự đọc đồng hồ/settings — mọi thứ do nơi gọi
//  truyền vào. Vỏ tự đọc ngưỡng người dùng chọn + trạng thái bật/tắt/tạm hoãn từ settings của
//  mình; lớp này không biết gì về UserDefaults/Registry/App Group, và không tự chọn con số cooldown
//  mặc định nào — vỏ truyền cooldownMs vào constructor. (Giá trị 45 giây đang chạy thật ở
//  NudgeCoordinatorMac/IOS là cho MÔ HÌNH CŨ — đếm chuỗi câu căng liên tiếp — chưa có quyết định
//  nào chốt lại con số cho mô hình CPM mới; xem docs/tasks/FRICTION-LOG.md.)
//

#ifndef BellPolicy_h
#define BellPolicy_h

#include <stdint.h>

// CHỐNG RUNG (hysteresis): sau khi đã reo, CPM phải tụt xuống DƯỚI `thresholdCpm *
// kBellPolicyHysteresisFactor` thì mới được coi là "đợt vượt ngưỡng mới" và có cơ hội reo lần
// nữa. Vì sao cần biên trễ thay vì chỉ đòi "tụt xuống dưới ngưỡng" (margin bằng 0): CPM dao động
// sát ngưỡng là chuyện thường — nhịp gõ người không phẳng lì — và với margin 0, một cú tụt rất
// nhỏ (chỉ 1-2 CPM, đúng mức nhiễu của một phím đơn lẻ trên cửa sổ 30 giây) đã đủ để "tái vũ
// trang" chuông, khiến hai gợn nhịp sát nhau vẫn tách thành hai đợt riêng và reo hai lần cách
// nhau vài giây — đúng thứ "chống rung" phải ngăn. 0.9 (10% dưới ngưỡng) cho ngưỡng mặc định 400
// nghĩa là phải tụt xuống dưới 360 — mất thật khoảng 20 phím/30 giây — mới tính là "đã chậm tay
// lại": đủ xa nhiễu một phím, nhưng vẫn đủ gần để phản ứng kịp khi người dùng THẬT SỰ chậm tay lại.
//
// Cố ý viết "đã chậm tay lại", KHÔNG phải "đã dịu lại"/"đã bình tĩnh": lớp này chỉ biết nhịp tay,
// không biết gì về tâm người gõ (HĐ-3). Comment cũng phải giữ luật đó — câu chữ trong code là thứ
// người viết UI sau đọc rồi chép thẳng ra màn hình.
extern const double kBellPolicyHysteresisFactor;   // 0.9

// Khoảng lặng tối thiểu MẶC ĐỊNH giữa hai lần chuông. Vỏ vẫn truyền giá trị vào constructor (lớp
// này không tự đọc settings) — hằng này chỉ để cả ba vỏ lấy CÙNG một con số mà không phải chép
// `45000` ba lần. "Một con số chép vào ba vỏ rồi trôi lệch" là kiểu hỏng dự án đã trả giá bốn lần;
// `git grep kBellPolicyDefaultCooldownMs` thấy hết mọi nơi dùng.
//
// 🟡 CHỐT TẠM (Q10, spec/typing-cadence-bell/README.md §5) — 45 giây là con số kế thừa từ MÔ HÌNH
// CŨ (đếm chuỗi câu căng liên tiếp), và không có ADR/ghi chú nào giải thích vì sao là 45 chứ không
// phải 30 hay 60. Research 2026-08-02 giữ nó lại có lý do, không phải vì quán tính: với cổng vũ
// trang + cửa sổ trượt 30 giây, một chu kỳ "gõ nhanh → nghỉ tay ngắn → gõ nhanh lại" tự nó đã mất
// ~15-30 giây mới vượt ngưỡng lần nữa. Nên cooldown DƯỚI ~20-30 giây gần như vô nghĩa (cơ chế khác
// đã chặn từ trước), còn 45 giây cắt thêm ~15-30 giây thật — có tác dụng, mà vẫn xa mức "ép nghỉ"
// hàng phút kiểu công cụ chống RSI, đúng tinh thần "chuông là lời mời, không phải kết luận".
// Chưa ai gõ thật để kiểm; xem docs/tasks/typing-cadence-bell-execution.md §2.
extern const int64_t kBellPolicyDefaultCooldownMs;  // 45000

// TIỀN ĐIỀU KIỆN CỦA `thresholdCpm`: phải > 0. Mức "Tắt chuông" (Q1) biểu đạt bằng `enabled=false`,
// **KHÔNG** bằng `thresholdCpm=0`. Vì sao phải nói ra: với `thresholdCpm=0` thì cổng chống rung là
// `cpm < 0` — không bao giờ đúng — nên chuông reo đúng MỘT lần rồi CÂM VĨNH VIỄN. Đây là ca một vỏ
// (#9/#15/#17) rất dễ tự nghĩ ra khi implement "Tắt chuông". Cố ý KHÔNG thêm code kẹp: thêm nhánh
// xử một trạng thái đã có đường biểu đạt đúng là dựng lỗi cho tình huống bất khả
// (.claude/rules/02-simplicity-first.md). Nói rõ ở hợp đồng rẻ hơn và không giấu lỗi.

class BellPolicy {
public:
    // cooldownMs <= 0 bị kẹp về 0 (nghĩa là "không có khoảng lặng tối thiểu") thay vì ném lỗi —
    // file này chạy gần mạch quyết định chuông ngay sau hook bàn phím, không được phép chết vì
    // một con số cấu hình sai. Cùng triết lý "không assert/throw" với TypingCadence.h.
    explicit BellPolicy(int64_t cooldownMs);

    // Đánh giá NGAY tại thời điểm nowMs. Trả `true` ĐÚNG MỘT LẦN cho mỗi đợt CPM vượt ngưỡng —
    // gọi liền là phát một tiếng chuông, không cần gọi gì thêm (xem giải trình "MỘT HÀM DUY NHẤT"
    // ở trên). Trả `false` thì vỏ không làm gì cả — không khung rỗng, không thông báo im (HĐ-2).
    //
    // Thứ tự sáu cổng bên trong (đọc để biết cổng nào chặn gì, đừng đoán — thứ tự quyết định kết
    // quả của test "chống rung" và test "tắt/tạm hoãn không tiêu lượt vũ trang"):
    //   1. Chống rung (hysteresis ở trên) — cpm tụt đủ sâu thì TÁI VŨ TRANG. Chạy TRƯỚC MỌI cổng
    //      khác, kể cả enabled/snoozed: đây là tín hiệu thuần về NHỊP GÕ, tách biệt khỏi cấu hình
    //      người dùng tại thời điểm đánh giá.
    //   2. cpm < thresholdCpm -> chưa chạm ngưỡng, không có gì để xét, trả về false ngay.
    //      cpm == thresholdCpm THÌ CÓ tính là đã chạm (so sánh là >=, không phải >): ngưỡng do
    //      chính người dùng đặt, "đạt đúng mức mình đặt" phải được coi là đã tới, không phải còn
    //      thiếu một chút mới tính.
    //   3. Chưa tái vũ trang kể từ lần reo trước -> không reo lại, dù ngưỡng vẫn đang bị vượt.
    //      Đây là lý do MỘT tràng gõ nhanh dài liên tục (CPM không bao giờ tụt xuống) chỉ reo
    //      ĐÚNG MỘT LẦN — không phải một lần mỗi khi cooldown hết, vì "đã vũ trang" và "hết
    //      cooldown" là hai cổng ĐỘC LẬP, cổng 3 chặn trước khi cổng 6 (cooldown) kịp được xét.
    //   4. enabled == false -> không reo. KHÔNG tiêu lượt vũ trang: bật chuông lại thì cơ hội reo
    //      vẫn còn nguyên, không phải chờ CPM tụt xuống rồi vượt lên lại từ đầu.
    //   5. snoozed == true -> không reo, cùng lý do không tiêu lượt vũ trang như cổng 4.
    //   6. Còn trong khoảng lặng (cooldown) kể từ LẦN REO THẬT gần nhất -> không reo. Không tính
    //      những lần "suýt reo" bị chặn ở cổng 3/4/5 — cooldown chỉ đếm từ tiếng chuông thật.
    //   Qua hết cả sáu cổng -> reo: tự ghi nhận nowMs là lần reo gần nhất, tự tiêu lượt vũ trang.
    bool evaluate(double cpm, double thresholdCpm, int64_t nowMs, bool enabled, bool snoozed);

private:
    int64_t _cooldownMs;
    int64_t _lastRungMs;
    bool    _hasRung;
    bool    _armed;
};

#endif /* BellPolicy_h */
