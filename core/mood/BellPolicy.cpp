//
//  BellPolicy.cpp
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ)
//
//  Xem BellPolicy.h cho hợp đồng đầy đủ, thứ tự sáu cổng, và lý do chống rung dùng biên trễ 10%.
//

#include "BellPolicy.h"

const double kBellPolicyHysteresisFactor = 0.9;   // 10% dưới ngưỡng mới tái vũ trang — xem header

BellPolicy::BellPolicy(int64_t cooldownMs)
    : _cooldownMs(cooldownMs > 0 ? cooldownMs : 0),
      _lastRungMs(0),
      _hasRung(false),
      _armed(true) {
    // Không cần khởi tạo gì thêm: _armed = true nghĩa là "sẵn sàng reo cho đợt vượt ngưỡng đầu
    // tiên", và _hasRung = false nghĩa là "chưa từng reo" nên cổng cooldown (6) không chặn lần
    // đầu, bất kể cooldownMs lớn tới đâu.
}

bool BellPolicy::evaluate(double cpm, double thresholdCpm, int64_t nowMs, bool enabled, bool snoozed) {
    // Cổng 1 — chống rung: tụt đủ sâu thì tái vũ trang, KHÔNG phụ thuộc enabled/snoozed. Đây là
    // tín hiệu thuần về NHỊP GÕ, tách biệt khỏi cấu hình người dùng tại thời điểm đánh giá.
    if (cpm < thresholdCpm * kBellPolicyHysteresisFactor) {
        _armed = true;
    }

    // Cổng 2 — chưa chạm ngưỡng. cpm == thresholdCpm ĐƯỢC tính là đã chạm (so sánh sau đây là
    // "cpm < thresholdCpm", nên bằng nhau thì KHÔNG rơi vào nhánh return false).
    if (cpm < thresholdCpm) {
        return false;
    }

    // Cổng 3 — đã reo cho đợt vượt ngưỡng NÀY rồi, chưa tái vũ trang. Lý do một tràng gõ nhanh
    // dài liên tục chỉ reo đúng MỘT LẦN: cổng này chặn TRƯỚC khi cooldown (cổng 6) kịp được xét,
    // nên cooldown hết hạn không tự động mở lại cơ hội reo.
    if (!_armed) {
        return false;
    }

    // Cổng 4, 5 — tắt / tạm hoãn. KHÔNG tiêu lượt vũ trang: bật lại hoặc hết hoãn thì cơ hội vẫn
    // còn nguyên, không phải chờ CPM tụt xuống rồi vượt lại từ đầu.
    if (!enabled) {
        return false;
    }
    if (snoozed) {
        return false;
    }

    // ĐỒNG HỒ NHẢY LÙI — cùng ca TypingCadence.cpp đã xử có chủ đích (`nowMs < _lastMs -> reset()`),
    // và hai lớp dùng CHUNG một nguồn nowMs từ hook bàn phím, nên bỏ qua ở đây là để lại một lỗ mà
    // lớp kia đã bịt. Đổi múi giờ / NTP kéo lùi / máy ngủ dậy đều làm `nowMs - _lastRungMs` ÂM →
    // luôn nhỏ hơn _cooldownMs → chuông CÂM suốt cả khoảng bị nhảy lùi (có thể hàng giờ).
    // Kéo mốc về hiện tại là cách rẻ nhất: mất nhiều nhất một lần chờ cooldown, không bao giờ câm dài.
    if (_hasRung && nowMs < _lastRungMs) {
        _lastRungMs = nowMs;
    }

    // Cổng 6 — khoảng lặng tối thiểu kể từ LẦN REO THẬT gần nhất. Không tính các lần "suýt reo"
    // bị cổng 3/4/5 chặn ở trên — cooldown chỉ đếm từ tiếng chuông thật đã phát.
    if (_hasRung && (nowMs - _lastRungMs) < _cooldownMs) {
        return false;
    }

    _armed = false;
    _hasRung = true;
    _lastRungMs = nowMs;
    return true;
}
