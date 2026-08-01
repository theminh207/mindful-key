//
//  TypingCadence.cpp
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ)
//
//  Xem TypingCadence.h cho hợp đồng đầy đủ và lý do "không tham số chuỗi".
//

#include "TypingCadence.h"

const int64_t kTypingCadenceDefaultWindowMs = 30000;   // 30 giây — ADR-0013

// Định nghĩa out-of-line cho hằng static trong lớp. C++14 vẫn đòi nó nếu hằng bị odr-use
// (truyền qua tham chiếu, lấy địa chỉ) ở đâu đó; C++17 mới tự ngầm `inline`. Thiếu dòng này
// thì có compiler dịch được mà link hỏng — mà máy dev không chạy được linker nào cả.
const int TypingCadence::kCapacity;

TypingCadence::TypingCadence(int64_t windowMs)
    : _windowMs(windowMs > 0 ? windowMs : 1),
      _head(0),
      _count(0),
      _lastMs(0),
      _hasLast(false) {
    // Không cần xoá _ts: _count = 0 nên không ô nào được đọc tới.
}

void TypingCadence::reset() {
    _head = 0;
    _count = 0;
    _lastMs = 0;
    _hasLast = false;
}

void TypingCadence::registerKeystroke(int64_t nowMs) {
    // ĐỒNG HỒ NHẢY LÙI. Xảy ra thật: đổi múi giờ, NTP hiệu chỉnh, máy ngủ dậy. Nếu cứ ghi
    // tiếp thì cửa sổ chứa lẫn lộn hai mốc thời gian khác nhau, và phép trừ ra khoảng âm →
    // CPM vô nghĩa. Chọn XOÁ SẠCH thay vì cố vá: nhịp đo trước cú nhảy không còn so được
    // với nhịp sau nó, giữ lại là bịa dữ liệu (HĐ-8). Mất tối đa một cửa sổ 30 giây.
    if (_hasLast && nowMs < _lastMs) {
        reset();
    }

    _ts[_head] = nowMs;
    _head = (_head + 1) % kCapacity;
    if (_count < kCapacity) {
        _count++;
    }
    // _count == kCapacity: vòng tròn đã đầy, ô vừa ghi đè lên nhịp cũ nhất. Đúng ý đồ —
    // xem ghi chú kCapacity ở header.

    _lastMs = nowMs;
    _hasLast = true;
}

int TypingCadence::keystrokesInWindow(int64_t nowMs) const {
    const int64_t lowerBound = nowMs - _windowMs;   // nửa mở: (lowerBound, nowMs]

    int n = 0;
    for (int i = 0; i < _count; i++) {
        // Duyệt từ ô mới nhất lùi dần. CÓ THỂ dừng sớm khi gặp ô đầu tiên ngoài cửa sổ —
        // `registerKeystroke` xoá sạch mỗi khi đồng hồ nhảy lùi, nên dãy này luôn không tăng
        // theo chiều duyệt, kể cả sau khi vòng tròn quấn. Cố ý KHÔNG tối ưu: duyệt hết 1024 ô
        // là dưới một micro-giây, còn dừng sớm thì đúng-sai phụ thuộc vào một bất biến ở HÀM
        // KHÁC (nhánh reset). Đổi nhánh đó mà quên đây là sinh lỗi đếm thiếu, im lặng.
        // Đánh đổi có chủ đích: chậm không đo được, đổi lấy đúng không phụ thuộc.
        const int idx = (_head - 1 - i + kCapacity * 2) % kCapacity;
        const int64_t t = _ts[idx];
        if (t > lowerBound && t <= nowMs) {
            n++;
        }
    }
    return n;
}

double TypingCadence::currentCPM(int64_t nowMs) const {
    const int n = keystrokesInWindow(nowMs);
    if (n == 0) {
        return 0.0;   // "chưa có nhịp nào" — nơi gọi đừng ghi mẫu (HĐ-8)
    }

    // Chia cho ĐỘ DÀI CỬA SỔ, không phải khoảng giữa nhịp đầu và nhịp cuối. Lý do đầy đủ ở
    // header — tóm tắt: chia theo khoảng giữa hai nhịp thì gõ 2 phím cách nhau 100ms ra
    // 1200 CPM và chuông reo oan ngay phím thứ hai.
    return (double)n * 60000.0 / (double)_windowMs;
}
