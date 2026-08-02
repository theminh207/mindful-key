//
//  CadenceWaveAmplitude.cpp
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ)
//
//  Xem CadenceWaveAmplitude.h cho hợp đồng đầy đủ (issue #8, Q4).
//

#include "CadenceWaveAmplitude.h"

const double kCadenceWaveDeadZoneRatio = 0.3;

// 🟡 CHỐT TẠM (xem CadenceWaveAmplitude.h) — hiệu chỉnh để amplitude == 0.80 đúng tại cpm ==
// thresholdCpm (s == 1 - kCadenceWaveDeadZoneRatio == 0.7): 0.7^2 / (0.7^2 + k) = 0.8
// => k = 0.49 * 0.25 = 0.1225.
static const double kCadenceWaveSaturationK = 0.1225;

double CadenceWaveAmplitude(double cpm, double thresholdCpm) {
    // Kẹp chia-0: cùng phong cách TypingCadence::currentCPM (windowMs <= 0 kẹp về 1) — file này
    // không được phép ném lỗi hay chia cho 0, dù nơi gọi truyền giá trị hỏng.
    double t = thresholdCpm > 0.0 ? thresholdCpm : 1.0;

    // s = khoảng cách (theo tỉ lệ ngưỡng) từ cpm tới rìa vùng chết. s <= 0 nghĩa là cpm còn nằm
    // trong hoặc dưới vùng chết -> mặt hồ phẳng tuyệt đối.
    double s = cpm / t - kCadenceWaveDeadZoneRatio;
    if (s <= 0.0) {
        return 0.0;
    }

    // Bão hoà tiệm cận dạng Hill n=2: s^2 / (s^2 + k). Đơn điệu tăng liên tục trên toàn miền s > 0,
    // tiệm cận 1.0 khi s -> vô cực nhưng KHÔNG BAO GIỜ chạm hay vượt 1.0 — khác kẹp cứng của bản
    // risk cũ (xem giải trình ở .h), giữ được phân biệt giữa "vừa chạm ngưỡng" và "vượt ngưỡng rất
    // xa" thay vì cả hai cùng vẽ ra biên độ tối đa.
    return (s * s) / (s * s + kCadenceWaveSaturationK);
}
