//
//  EmotionWaveAmplitude.cpp
//  mindful-key — iOS keyboard extension (Round 2, story 2.5)
//
//  Xem EmotionWaveAmplitude.h cho hợp đồng đầy đủ (Q1).
//

#include "EmotionWaveAmplitude.h"

const double kEmotionWaveDeadZoneThreshold = 0.3;

double EmotionWaveAmplitude(double risk) {
    if (risk < kEmotionWaveDeadZoneThreshold) {
        return 0.0; // vùng chết (bao gồm risk âm, vd nếu 2.2 có bug) — mặt hồ phẳng, Q1
    }

    double clamped = risk > 1.0 ? 1.0 : risk;
    double t = (clamped - kEmotionWaveDeadZoneThreshold) / (1.0 - kEmotionWaveDeadZoneThreshold);

    // smoothstep (3t^2 - 2t^3): liên tục VÀ đạo hàm liên tục trên [0, 1] — đảm bảo không có bước
    // nhảy thị giác ngay tại ngưỡng 0.3 (khớp đúng 0.0 với nhánh vùng chết ở trên) lẫn không có
    // "gãy khúc" ở giữa khoảng hay tại risk=1.0 (khớp đúng 1.0, biên độ tối đa).
    return t * t * (3.0 - 2.0 * t);
}
