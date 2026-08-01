//
//  TypingCadence.h
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ: macOS · iOS · Windows)
//
//  ĐO NHỊP GÕ: đếm thời điểm bấm phím trên một cửa sổ trượt, trả về CPM (ký tự/phút).
//  Đây là bước **Measure** của vòng lặp `Measure → Bell → Reflect` (docs/01-intent.md §3).
//
//  ┌─────────────────────────────────────────────────────────────────────────────────────┐
//  │ [MINDFUL] LUẬT SỐ MỘT CỦA FILE NÀY — không có tham số chuỗi, không bao giờ.          │
//  │                                                                                     │
//  │ Hiến chương §4.2 hứa "sản phẩm KHÔNG ĐỌC nội dung người dùng gõ". Lời hứa đó chỉ     │
//  │ thật khi người đọc code NHÌN THẤY ĐƯỢC rằng không có đường nào cho chữ đi vào.       │
//  │ Vì vậy API dưới đây chỉ nhận DẤU THỜI GIAN. Không `wstring`, không `char*`,          │
//  │ không `NSString`. Nhận chuỗi rồi chỉ dùng `.length()` VẪN LÀ VI PHẠM — người review  │
//  │ vẫn thấy lớp này cầm text, và lời hứa tụt xuống "có nhận nhưng hứa không dùng".      │
//  │                                                                                     │
//  │ Cụ thể: KHÔNG tái dùng callback `vOnWordCommitted` của engine (chữ ký của nó là      │
//  │ `void (*)(const wstring& word)`). Ba vỏ đã nối sẵn vào đó nên nuôi nhịp từ đấy là    │
//  │ đường ít sửa nhất — và đã bị BÁC BỎ CÓ CHỦ ĐÍCH. Vỏ phải gọi từ hook bàn phím,       │
//  │ từng phím một. Q3, chốt 2026-08-01, spec/typing-cadence-bell/README.md §5.           │
//  │                                                                                     │
//  │ Hợp đồng: docs/04-contracts.md HĐ-1. Được CƯỠNG CHẾ BẰNG MÁY, không chỉ bằng lời:    │
//  │ bước "Cổng HĐ-1" trong .github/workflows/macos.yml grep thư mục này và làm ĐỎ CI     │
//  │ nếu có API nào của lớp nhịp gõ/chuông mọc ra tham số kiểu chuỗi.                     │
//  │                                                                                     │
//  │ (Mẫu grep cố ý KHÔNG chép vào đây: chính dòng chép nó sẽ tự khớp và làm đỏ CI oan —  │
//  │  đã vấp thật khi dựng cổng này. Pattern giữ ĐÚNG MỘT BẢN, ở workflow.)               │
//  └─────────────────────────────────────────────────────────────────────────────────────┘
//
//  KHÔNG I/O, KHÔNG log, KHÔNG API riêng OS, KHÔNG tự đọc đồng hồ hệ thống — thời điểm do
//  nơi gọi truyền vào. Nhờ vậy test được tất định, không cần sleep, không cần Simulator.
//
//  RẺ TỚI MỨC CHẠY THẲNG TRONG HOOK BÀN PHÍM ĐƯỢC (docs/04-contracts.md HĐ-3):
//  `registerKeystroke` là O(1), `currentCPM` là O(số nhịp ĐÃ GHI, tối đa 1024 — không phải chỉ
//  số nhịp còn trong cửa sổ) trên mảng cố định —
//  KHÔNG cấp phát, KHÔNG khóa, KHÔNG ngoại lệ. Đây là khác biệt lớn so với lớp chấm điểm cũ
//  (SendRiskAnalyzer) vốn buộc phải đẩy sang luồng riêng. Nhưng PHÁT TIẾNG CHUÔNG thì vẫn
//  KHÔNG được chạy trong hook — đó là việc của vỏ, đẩy sang luồng khác.
//
//  Đơn vị là CPM chứ KHÔNG phải WPM: Telex/VNI gõ dấu tốn thêm phím ("aa" → "â" là 2 nhịp),
//  nên gom thành "từ" rồi đếm sẽ méo — cùng một tốc độ tay, câu nhiều dấu ra số từ thấp hơn
//  hẳn câu ít dấu. Chốt ở ADR-0013.

#ifndef TypingCadence_h
#define TypingCadence_h

#include <stdint.h>

// Cửa sổ trượt mặc định: 30 giây (ADR-0013).
// Ngắn hơn thì một tràng gõ dồn rồi nghỉ cũng đủ vượt ngưỡng; dài hơn thì chuông tới sau khi
// nhịp đã lắng.
extern const int64_t kTypingCadenceDefaultWindowMs;

class TypingCadence {
public:
    // Sức chứa cố định — KHÔNG cấp phát động (HĐ-3). Vượt số này trong cùng một cửa sổ thì
    // nhịp CŨ NHẤT bị đẩy ra, nên CPM bão hòa quanh 2048 với cửa sổ 30 giây. Kỷ lục gõ của
    // người ~1000 CPM, còn ngưỡng chuông cao nhất là 500 — nên trần này ở rất xa mọi ngưỡng
    // thật và không bao giờ làm chuông câm.
    static const int kCapacity = 1024;

    // CỐ Ý không có tham số mặc định: vỏ phải nói rõ nó đang đo trên cửa sổ nào, và giá trị
    // mặc định chỉ có MỘT chỗ giữ là `kTypingCadenceDefaultWindowMs` ở trên. Để default ở
    // đây nữa là chép số 30000 thành hai bản — đúng loại trôi lệch dự án đã trả giá.
    //
    // windowMs <= 0 bị kẹp về 1 để không chia cho 0. Không ném ngoại lệ, không assert —
    // file này chạy trong hook bàn phím, chết ở đây là chết cả bàn phím.
    explicit TypingCadence(int64_t windowMs);

    // Một phím vừa được bấm tại thời điểm nowMs. KHÔNG nhận biết phím nào — xem khối
    // [MINDFUL] ở đầu file.
    //
    // Vỏ phải tự chặn ô mật khẩu TRƯỚC khi gọi hàm này (HĐ-4, mặc định fail-closed):
    // không xác định được ô hiện tại có phải ô mật khẩu không thì coi LÀ ô mật khẩu và
    // không gọi. Lớp này cố ý không biết gì về ô nhập — nó không có cách nào biết.
    void registerKeystroke(int64_t nowMs);

    // Ký tự mỗi phút trong cửa sổ trượt kết thúc tại nowMs.
    //
    // CÔNG THỨC: (số nhịp trong cửa sổ) / (độ dài cửa sổ tính bằng phút).
    // Cố ý chia cho ĐỘ DÀI CỬA SỔ, không phải cho "khoảng từ nhịp đầu tới nhịp cuối".
    // Nếu chia cho khoảng giữa hai nhịp thì gõ 2 phím cách nhau 100ms sẽ ra 1200 CPM —
    // vượt mọi ngưỡng, chuông reo oan ngay phím thứ hai. Chia cho cửa sổ thì 2 phím trong
    // cửa sổ 30 giây ra đúng 4 CPM, và muốn chạm ngưỡng 400 phải gõ thật 200 phím trong
    // 30 giây. Không có cách nào thổi phồng, nên KHÔNG cần thêm luật "tối thiểu N phím".
    //
    // Hệ quả cố ý: 30 giây đầu sau khi khởi động (hoặc sau reset) con số bị BÁO THẤP hơn
    // thực tế, vì cửa sổ chưa đầy. Đây là chiều an toàn — nó nghiêng về IM LẶNG, đúng tinh
    // thần "chuông là lời mời để ý, không phải kết luận".
    //
    // Cửa sổ là nửa mở `(nowMs - windowMs, nowMs]`: nhịp đúng ngay mép dưới KHÔNG được tính,
    // nhịp đúng tại nowMs thì có. Nhịp ở TƯƠNG LAI so với nowMs cũng bị bỏ (đồng hồ nhảy).
    //
    // Không gõ gì → trả 0.0. Đây là "chưa có nhịp nào", KHÔNG phải "nhịp bằng 0" — nơi gọi
    // đừng ghi mẫu vào kho khi CPM = 0 và cũng không có nhịp nào (HĐ-8, không bịa dữ liệu).
    double currentCPM(int64_t nowMs) const;

    // Số nhịp còn nằm trong cửa sổ tại nowMs. Cùng phép đếm mà currentCPM dùng, phơi ra để
    // test khẳng định được bằng SỐ NGUYÊN CHÍNH XÁC thay vì so sánh số thực, và để vỏ hiển
    // thị "đã gõ bao nhiêu phím" mà không phải nhân ngược lại từ CPM.
    int keystrokesInWindow(int64_t nowMs) const;

    // Xoá sạch mọi nhịp đã ghi. Vỏ nên gọi khi bộ gõ bị tắt hoặc người dùng tắt tính năng —
    // để nhịp trước lúc tắt không cộng dồn vào lúc bật lại.
    void reset();

    int64_t windowMs() const { return _windowMs; }

private:
    int64_t _windowMs;
    int64_t _ts[kCapacity];   // vòng tròn, không cấp phát
    int     _head;            // vị trí ghi kế tiếp
    int     _count;           // số ô đang giữ giá trị thật (tối đa kCapacity)
    int64_t _lastMs;          // thời điểm nhịp gần nhất, để phát hiện đồng hồ nhảy lùi
    bool    _hasLast;
};

#endif /* TypingCadence_h */
