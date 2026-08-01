// test_cadence.cpp
// Khoá hành vi của core/mood/TypingCadence — phép đo DÙNG CHUNG cho macOS · iOS · Windows.
// Nó lệch là cả ba vỏ reo chuông lệch nhau, và nhật ký giữa các máy hết so được.
//
// Vì sao con số kỳ vọng ở đây tự tin: phép đo là ĐỊNH NGHĨA, không phải ước lượng —
// CPM = (số nhịp trong cửa sổ) / (độ dài cửa sổ tính bằng phút). Với cửa sổ 30 giây thì
// 1 nhịp = 2.0 CPM chẵn, nên mọi số dưới đây tính tay ra được, không cần chạy đối chiếu
// như test_send_risk.cpp phải làm.
//
// KHÔNG có sleep, KHÔNG đọc đồng hồ thật: thời điểm do test truyền vào, nên chạy tất định
// và nhanh. Đó chính là lý do TypingCadence không tự gọi đồng hồ hệ thống.
//
// Build: xem tests/core/cadence_build.sh

#include <cmath>
#include <cstdio>
#include "TypingCadence.h"

static int gFail = 0;   // exit code != 0 để make/CI gate được khi có regression

static void checkCPM(const char* name, double got, double want) {
    if (std::fabs(got - want) < 1e-9) {
        printf("  ✅ %-52s CPM = %.2f\n", name, got);
    } else {
        printf("  ❌ SAI  %-52s CPM = %.6f, mong đợi %.6f\n", name, got, want);
        gFail++;
    }
}

static void checkCount(const char* name, int got, int want) {
    if (got == want) {
        printf("  ✅ %-52s nhịp = %d\n", name, got);
    } else {
        printf("  ❌ SAI  %-52s nhịp = %d, mong đợi %d\n", name, got, want);
        gFail++;
    }
}

// Gõ n phím, mỗi phím cách nhau stepMs, bắt đầu tại startMs. Trả về thời điểm phím cuối.
static int64_t typeKeys(TypingCadence& c, int n, int64_t startMs, int64_t stepMs) {
    int64_t t = startMs;
    for (int i = 0; i < n; i++) {
        c.registerKeystroke(t);
        if (i + 1 < n) t += stepMs;
    }
    return t;
}

int main() {
    const int64_t W = 30000;   // cửa sổ 30 giây — mặc định đã chốt ở ADR-0013

    printf("=== TypingCadence — cửa sổ trượt %lld ms ===\n", (long long)W);

    printf("\n--- Loại 1: chưa gõ gì ---\n");
    {
        TypingCadence c(W);
        checkCPM("cửa sổ rỗng -> 0, KHÔNG phải chia cho 0", c.currentCPM(0), 0.0);
        checkCPM("cửa sổ rỗng, thời điểm khác 0",           c.currentCPM(999999), 0.0);
        checkCount("cửa sổ rỗng -> 0 nhịp",                 c.keystrokesInWindow(999999), 0);
    }

    printf("\n--- Loại 2: đếm cơ bản (1 nhịp = 2.0 CPM với cửa sổ 30s) ---\n");
    {
        TypingCadence c(W);
        c.registerKeystroke(1000);
        checkCPM("1 nhịp",  c.currentCPM(1000), 2.0);
        c.registerKeystroke(2000);
        checkCPM("2 nhịp",  c.currentCPM(2000), 4.0);
        c.registerKeystroke(3000);
        checkCPM("3 nhịp",  c.currentCPM(3000), 6.0);
    }

    printf("\n--- Loại 3: KHÔNG được thổi phồng khi mới gõ vài phím (ca hồi quy quan trọng nhất) ---\n");
    {
        // Nếu ai đó "sửa" thành chia cho khoảng-giữa-hai-nhịp thì ca này ra 1200 CPM và
        // chuông reo oan ngay phím thứ hai. Ca này tồn tại để chặn đúng cú sửa đó.
        TypingCadence c(W);
        c.registerKeystroke(0);
        c.registerKeystroke(100);          // 2 phím cách nhau 100ms
        checkCPM("2 phím cách 100ms -> 4 CPM, KHÔNG phải 1200", c.currentCPM(100), 4.0);

        TypingCadence c2(W);
        typeKeys(c2, 10, 0, 50);           // 10 phím trong nửa giây
        checkCPM("10 phím trong 500ms -> 20 CPM, KHÔNG phải 1200", c2.currentCPM(500), 20.0);
    }

    printf("\n--- Loại 4: chạm đúng các ngưỡng đã chốt (ADR-0013) ---\n");
    {
        // Ngưỡng người dùng chọn được: Nhanh 300 · Rất nhanh 400 (mặc định) · Cực nhanh 500.
        // Muốn chạm 400 CPM phải gõ THẬT 200 phím trong 30 giây — đây là bằng chứng bằng số
        // rằng ngưỡng mặc định không dễ chạm oan.
        TypingCadence c(W);
        typeKeys(c, 150, 0, 100);
        checkCPM("150 nhịp trong cửa sổ -> đúng mức 'Nhanh'",      c.currentCPM(W), 300.0);
    }
    {
        TypingCadence c(W);
        typeKeys(c, 200, 0, 100);
        checkCPM("200 nhịp trong cửa sổ -> đúng mức 'Rất nhanh'",  c.currentCPM(W), 400.0);
    }
    {
        TypingCadence c(W);
        typeKeys(c, 250, 0, 100);
        checkCPM("250 nhịp trong cửa sổ -> đúng mức 'Cực nhanh'",  c.currentCPM(W), 500.0);
    }

    printf("\n--- Loại 5: cửa sổ trượt đẩy nhịp cũ ra ---\n");
    {
        TypingCadence c(W);
        c.registerKeystroke(0);
        c.registerKeystroke(10000);
        c.registerKeystroke(20000);
        checkCPM("3 nhịp, xét tại 20s -> cả 3 còn trong cửa sổ", c.currentCPM(20000), 6.0);
        checkCPM("xét tại 31s -> nhịp t=0 đã rơi ra",            c.currentCPM(31000), 4.0);
        checkCPM("xét tại 41s -> chỉ còn nhịp t=20000",          c.currentCPM(41000), 2.0);
        checkCPM("xét tại 51s -> cửa sổ rỗng lại",               c.currentCPM(51000), 0.0);
    }

    printf("\n--- Loại 6: mép cửa sổ là nửa mở (lowerBound, now] ---\n");
    {
        TypingCadence c(W);
        c.registerKeystroke(1000);
        checkCount("nhịp ĐÚNG tại now -> có tính",        c.keystrokesInWindow(1000), 1);
        checkCount("now = ts + window - 1 -> vẫn trong",  c.keystrokesInWindow(1000 + W - 1), 1);
        checkCount("now = ts + window -> ĐÚNG mép, loại", c.keystrokesInWindow(1000 + W), 0);
        checkCount("now = ts + window + 1 -> ngoài",      c.keystrokesInWindow(1000 + W + 1), 0);
    }

    printf("\n--- Loại 7: nghỉ dài rồi gõ lại, KHÔNG cộng dồn ---\n");
    {
        TypingCadence c(W);
        typeKeys(c, 100, 0, 100);                       // gõ dồn 100 phím trong 10 giây
        checkCPM("vừa gõ xong tràng 1", c.currentCPM(9900), 200.0);

        // Nghỉ 1 tiếng rồi gõ lại 5 phím.
        const int64_t later = 3600000;
        typeKeys(c, 5, later, 100);
        checkCPM("sau 1 tiếng nghỉ, 5 nhịp mới -> 10 CPM (tràng cũ đã rơi hết)",
                 c.currentCPM(later + 400), 10.0);
    }

    printf("\n--- Loại 8: đồng hồ nhảy LÙI -> không crash, không CPM âm ---\n");
    {
        TypingCadence c(W);
        typeKeys(c, 10, 100000, 100);
        checkCPM("trước cú nhảy", c.currentCPM(100900), 20.0);

        // NTP kéo đồng hồ lùi 50 giây. registerKeystroke phát hiện và xoá sạch.
        c.registerKeystroke(50000);
        checkCPM("sau cú nhảy lùi -> chỉ còn đúng nhịp vừa ghi", c.currentCPM(50000), 2.0);

        c.registerKeystroke(50100);
        checkCPM("gõ tiếp sau cú nhảy -> đếm bình thường", c.currentCPM(50100), 4.0);
    }
    {
        // Đồng hồ lùi giữa lúc ĐỌC (nhịp nằm ở "tương lai" so với nowMs) -> bỏ qua, không âm.
        TypingCadence c(W);
        c.registerKeystroke(100000);
        checkCPM("nhịp ở tương lai so với now -> bỏ qua", c.currentCPM(90000), 0.0);
        checkCount("và cũng không đếm",                   c.keystrokesInWindow(90000), 0);
    }

    printf("\n--- Loại 9: reset() ---\n");
    {
        TypingCadence c(W);
        typeKeys(c, 50, 0, 100);
        checkCPM("trước reset", c.currentCPM(4900), 100.0);
        c.reset();
        checkCPM("sau reset -> sạch", c.currentCPM(4900), 0.0);
        c.registerKeystroke(5000);
        checkCPM("gõ lại sau reset",  c.currentCPM(5000), 2.0);
    }

    printf("\n--- Loại 10: vượt sức chứa vòng tròn (bão hòa, KHÔNG crash) ---\n");
    {
        // kCapacity = 1024. Gõ 1500 phím trong 30 giây (~3000 CPM — nhanh gấp 3 kỷ lục người).
        // Vòng tròn giữ lại 1024 nhịp mới nhất -> CPM bão hòa quanh 2048, vẫn xa trên mọi
        // ngưỡng (cao nhất 500), nên chuông vẫn reo đúng. Ca này chứng minh KHÔNG crash và
        // KHÔNG tụt về 0 khi tràn.
        TypingCadence c(W);
        typeKeys(c, 1500, 0, 20);
        const int n = c.keystrokesInWindow(29980);
        checkCount("tràn vòng tròn -> giữ đúng kCapacity nhịp", n, TypingCadence::kCapacity);
        checkCPM("CPM bão hòa, vẫn TRÊN mọi ngưỡng",
                 c.currentCPM(29980), (double)TypingCadence::kCapacity * 60000.0 / (double)W);
    }

    printf("\n--- Loại 11: cửa sổ khác 30s + tham số hỏng ---\n");
    {
        TypingCadence c(60000);   // 1 phút
        typeKeys(c, 60, 0, 500);
        checkCPM("cửa sổ 60s, 60 nhịp -> 60 CPM", c.currentCPM(29500), 60.0);
    }
    {
        TypingCadence c(0);       // hỏng -> kẹp về 1ms, KHÔNG chia cho 0
        c.registerKeystroke(5);
        const double cpm = c.currentCPM(5);
        if (cpm == cpm && !std::isinf(cpm)) {
            printf("  ✅ %-52s CPM = %.0f (không NaN/inf)\n", "windowMs = 0 bị kẹp an toàn", cpm);
        } else {
            printf("  ❌ SAI  %-52s CPM = %f\n", "windowMs = 0 bị kẹp an toàn", cpm);
            gFail++;
        }
    }
    {
        TypingCadence c(-1000);   // âm -> cũng kẹp
        c.registerKeystroke(0);
        const double cpm = c.currentCPM(0);
        if (cpm > 0.0 && cpm == cpm && !std::isinf(cpm)) {
            printf("  ✅ %-52s CPM = %.0f\n", "windowMs âm bị kẹp an toàn", cpm);
        } else {
            printf("  ❌ SAI  %-52s CPM = %f\n", "windowMs âm bị kẹp an toàn", cpm);
            gFail++;
        }
    }

    printf("\n--- Loại 12: thời điểm âm (đồng hồ đơn điệu có thể bắt đầu từ số âm) ---\n");
    {
        TypingCadence c(W);
        c.registerKeystroke(-10000);
        c.registerKeystroke(-9000);
        checkCPM("thời điểm âm vẫn đếm đúng", c.currentCPM(-9000), 4.0);
        checkCPM("và vẫn trượt đúng",         c.currentCPM(25000), 0.0);
    }

    if (gFail == 0)
        printf("\n=== XONG — TẤT CẢ PASS ===\n");
    else
        printf("\n=== XONG — %d CA SAI (make test sẽ đỏ) ===\n", gFail);
    return gFail == 0 ? 0 : 1;
}
