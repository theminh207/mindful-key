// test_cadence_wave.cpp
// Khoá hành vi của core/mood/CadenceWaveAmplitude — quy đổi NHỊP GÕ (CPM) + ngưỡng người dùng
// chọn thành biên độ con sóng `~` DÙNG CHUNG cho macOS · iOS · Windows (issue #8, Q4).
//
// DỜI từ tests/ios/emotion_wave_test.mm (bản cũ test hàm `EmotionWaveAmplitude(risk)`, một tham
// số [0,1] từ mô hình đọc cảm xúc đã chết). File này viết lại HOÀN TOÀN cho chữ ký mới (cpm,
// thresholdCpm) — không phải đổi tên biến, vì `risk` tự nhiên bị chặn [0,1] còn `cpm` thì không
// (xem giải trình ở CadenceWaveAmplitude.h).
//
// Mọi mốc số ở "Loại 3" dưới đây được TÍNH TAY từ công thức trước khi viết — không đoán, không
// chép ngược từ code (bài học #6: commit `e529c70` từng viết sai kỳ vọng vì không tính tay).
// Công thức: s = cpm/thresholdCpm - kCadenceWaveDeadZoneRatio(0.3); amplitude = s^2/(s^2+k),
// k = kCadenceWaveSaturationK = 0.1225. Các mốc dùng PHÂN SỐ chính xác (vd 81.0/130.0) thay vì số
// thập phân làm tròn tay, để so sánh không lẫn sai số làm tròn của người viết test vào bài test.
//
// KHÔNG có sleep, KHÔNG đọc đồng hồ thật — hàm thuần, không side-effect, chạy tất định và nhanh.
//
// Build: xem tests/core/cadence_wave_build.sh

#include <cmath>
#include <cstdio>
#include "CadenceWaveAmplitude.h"

static int gFail = 0;   // exit code != 0 để make/CI gate được khi có regression
static const double kEps = 1e-9;

static void checkAmp(const char* name, double got, double want) {
    if (std::fabs(got - want) < kEps) {
        printf("  OK   %-70s = %.9f\n", name, got);
    } else {
        printf("  SAI  %-70s = %.9f, mong doi %.9f\n", name, got, want);
        gFail++;
    }
}

static void checkTrue(const char* name, bool cond) {
    if (cond) {
        printf("  OK   %s\n", name);
    } else {
        printf("  SAI  %s\n", name);
        gFail++;
    }
}

int main() {
    printf("=== CadenceWaveAmplitude - bien do song tu CPM + nguong (issue #8, Q4) ===\n");

    printf("\n--- Loai 1: vung chet la TI LE so voi nguong, khong phai gia tri CPM tuyet doi ---\n");
    {
        const double T = 400.0;
        checkAmp("cpm=0, threshold=400 -> 0 (vung chet)",         CadenceWaveAmplitude(0.0, T), 0.0);
        checkAmp("cpm=100, threshold=400 (ti le 0.25 < 0.3) -> 0", CadenceWaveAmplitude(100.0, T), 0.0);
        checkAmp("cpm=119.999, threshold=400 -> con duoi 0.3*400=120 -> 0",
                 CadenceWaveAmplitude(119.999, T), 0.0);
        // DUNG mep vung chet: cpm == 0.3 * threshold -> s == 0 -> nhanh s<=0 tra ve 0.
        checkAmp("cpm=120 (dung mep 0.3*400), threshold=400 -> 0", CadenceWaveAmplitude(120.0, T), 0.0);
        checkTrue("cpm=120.001 (vua qua mep) -> bat dau > 0",
                  CadenceWaveAmplitude(120.001, T) > 0.0);
        // Am van la vung chet, khong chi la "khong crash".
        checkAmp("cpm am (-500), threshold=400 -> 0 (van la vung chet)",
                 CadenceWaveAmplitude(-500.0, T), 0.0);
    }

    printf("\n--- Loai 2: don dieu tang + LIEN TUC (quet mau day, khong buoc nhay) ---\n");
    {
        const double T = 400.0;
        // Quet r = cpm/threshold tu 0.30 (mep vung chet) den 6.0 (rat xa nguong), buoc 0.01.
        // Ham la don dieu tang chat tren toan mien s > 0 (dao ham s^2/(s^2+k) luon duong) --
        // khong duoc co diem nao cur <= prev, va khong duoc co buoc nhay > 0.05 (dao ham cuc dai
        // quanh s ~ sqrt(k/3) ~ 0.20, uoc luong ~0.91/don vi s -> voi buoc 0.01 thi buoc toi da
        // ~0.0091, con xa duoi 0.05 -- nguong 0.05 du chat de bat loi "bac thang", du rong de
        // khong bao dong gia vi sai so dau phay dong).
        bool monotonic = true;
        double maxJump = 0.0;
        double prev = CadenceWaveAmplitude(0.30 * T, T);
        for (double r = 0.30; r <= 6.0 + 1e-9; r += 0.01) {
            double cur = CadenceWaveAmplitude(r * T, T);
            if (cur < prev - kEps) monotonic = false;
            double jump = std::fabs(cur - prev);
            if (jump > maxJump) maxJump = jump;
            prev = cur;
        }
        checkTrue("don dieu tang tren toan mien [0.30T, 6.0T], khong diem nao tut", monotonic);
        checkTrue("khong buoc nhay > 0.05 giua 2 mau cach nhau 0.01T", maxJump < 0.05);

        // Khong nhay dot ngot ngay QUANH mep vung chet 0.3T (sample day sat mep, khong chi 2 dau mut).
        double a30   = CadenceWaveAmplitude(0.300 * T, T);
        double a3001 = CadenceWaveAmplitude(0.3001 * T, T);
        double a301  = CadenceWaveAmplitude(0.301 * T, T);
        checkTrue("khong buoc nhay dot ngot ngay tai mep 0.3T", std::fabs(a3001 - a30) < 0.01);
        checkTrue("don dieu ngay sat mep: a(0.301T) > a(0.3001T)", a301 > a3001);
    }

    printf("\n--- Loai 3: bang moc so THAT voi threshold=400 (tinh tay truoc khi viet) ---\n");
    {
        const double T = 400.0;
        // cpm=300: s = 300/400 - 0.3 = 0.45. s^2 = 0.2025. amp = 0.2025/(0.2025+0.1225)
        //         = 0.2025/0.325 = 81/130 (rut gon) ~ 0.623077.
        checkAmp("cpm=300, threshold=400 -> 81/130 (~0.623)", CadenceWaveAmplitude(300.0, T), 81.0 / 130.0);
        // cpm=400 (== threshold): s = 1 - 0.3 = 0.7. s^2 = 0.49. amp = 0.49/0.6125 = 0.8 DUNG (chot tam).
        checkAmp("cpm=400 (== threshold) -> 0.8 dung (chot tam, cho nhin song that)",
                 CadenceWaveAmplitude(400.0, T), 0.8);
        // cpm=500: s = 1.25 - 0.3 = 0.95. s^2 = 0.9025. amp = 0.9025/1.025 = 361/410 ~ 0.880488.
        checkAmp("cpm=500, threshold=400 -> 361/410 (~0.880)", CadenceWaveAmplitude(500.0, T), 361.0 / 410.0);
        // cpm=800: s = 2 - 0.3 = 1.7. s^2 = 2.89. amp = 2.89/3.0125 = 1156/1205 ~ 0.959336.
        checkAmp("cpm=800, threshold=400 -> 1156/1205 (~0.959)", CadenceWaveAmplitude(800.0, T), 1156.0 / 1205.0);
        // cpm=2000: s = 5 - 0.3 = 4.7. s^2 = 22.09. amp = 22.09/22.2125 = 8836/8885 ~ 0.994485.
        checkAmp("cpm=2000, threshold=400 -> 8836/8885 (~0.994)", CadenceWaveAmplitude(2000.0, T), 8836.0 / 8885.0);
    }

    printf("\n--- Loai 4: TU CO GIAN theo nguong -- cung ti le cpm/threshold cho cung bien do ---\n");
    {
        // Ba nguong nguoi dung chon duoc: 300, 400, 500 (ADR-0013). Cung mot ti le r=1.25 (vd
        // "vuot nguong 25%") phai cho DUNG cung mot bien do, du con so CPM tuyet doi khac hau.
        const double r = 1.25;
        double amp300 = CadenceWaveAmplitude(r * 300.0, 300.0);
        double amp400 = CadenceWaveAmplitude(r * 400.0, 400.0);
        double amp500 = CadenceWaveAmplitude(r * 500.0, 500.0);
        checkAmp("ti le 1.25: nguong 300 va 400 cho cung bien do", amp300, amp400);
        checkAmp("ti le 1.25: nguong 400 va 500 cho cung bien do", amp400, amp500);

        // Va tai chinh diem "== nguong" (r=1.0): moi nguong deu ra 0.8 nhu nhau.
        checkAmp("nguong 300, cpm=300 -> van 0.8 dung (tu co gian)", CadenceWaveAmplitude(300.0, 300.0), 0.8);
        checkAmp("nguong 500, cpm=500 -> van 0.8 dung (tu co gian)", CadenceWaveAmplitude(500.0, 500.0), 0.8);
    }

    printf("\n--- Loai 5: KHONG BAO GIO vuot 1.0, khong NaN, ke ca cpm rat lon ---\n");
    {
        const double T = 400.0;
        double huge = CadenceWaveAmplitude(1e12, T);
        checkTrue("cpm=1e12 -> khong NaN", !std::isnan(huge));
        checkTrue("cpm=1e12 -> khong Inf", !std::isinf(huge));
        // KHONG kiem "< 1.0". Ve TOAN HOC thi s^2/(s^2+k) tiem can 1.0 va khong bao gio cham;
        // ve SO THUC DAU PHAY DONG thi co. Voi cpm=1e12, s ~ 2.5e9 nen s^2 ~ 6.25e18, ma ULP
        // cua double o do lon do la ~1024 -- lon hon k=0.1225 hang nghin lan. Nen `s*s + k`
        // lam tron ve DUNG BANG `s*s`, va thuong ra DUNG BANG 1.0. Bat "< 1.0" la doi mot dieu
        // IEEE754 khong the giu (CI da do dung o day, run 30727859811).
        //
        // Hop dong THAT su quan trong voi noi goi la KHONG VUOT QUA 1.0 -- view nhan gia tri nay
        // roi nhan voi bien do pixel toi da, vuot 1.0 la ve tran khung. Do la thu kiem o day.
        checkTrue("cpm=1e12 -> khong bao gio VUOT 1.0 (view nhan gia tri nay de nhan pixel)", huge <= 1.0);
        checkTrue("cpm=1e12 -> phai rat gan 1.0", huge > 0.999999);
        // Bao hoa bang 1.0 chi xay ra o vung KHONG THE CO THAT: TypingCadence bao hoa quanh
        // 2048 CPM (kCapacity=1024 tren cua so 30s), tai do bien do moi la ~0.995. Muon cham
        // 1.0 that su phai gia lap cpm lon hon hang ty lan ky luc go cua nguoi.
        checkTrue("o dai CPM CO THAT (<= 2048) thi van chua cham 1.0",
                  CadenceWaveAmplitude(2048.0, T) < 1.0);

        // 800 va 2000 (Loai 3) van khac nhau ro -- KHONG "phang li" o 1.0, dung y do thiet ke.
        checkTrue("800 CPM va 2000 CPM van phan biet duoc (khong phang li o 1.0)",
                  CadenceWaveAmplitude(2000.0, T) > CadenceWaveAmplitude(800.0, T));
    }

    printf("\n--- Loai 6: thresholdCpm <= 0 -- khong crash, khong chia 0 ---\n");
    {
        // t bi kep ve 1.0 khi thresholdCpm <= 0 (cung phong cach TypingCadence::currentCPM).
        checkAmp("threshold=0, cpm=0 -> kep t=1, s=-0.3<=0 -> 0", CadenceWaveAmplitude(0.0, 0.0), 0.0);
        checkTrue("threshold=0, cpm rat lon -> khong NaN", !std::isnan(CadenceWaveAmplitude(1e6, 0.0)));
        checkTrue("threshold am (-400), cpm=1 -> khong NaN", !std::isnan(CadenceWaveAmplitude(1.0, -400.0)));
        // threshold=-400 cung kep ve t=1.0 y het threshold=0 -- hai loi goi phai cho CUNG ket qua.
        checkAmp("threshold=0 va threshold=-400 kep ve CUNG mot t=1.0",
                 CadenceWaveAmplitude(2.0, 0.0), CadenceWaveAmplitude(2.0, -400.0));
    }

    if (gFail == 0) {
        printf("\n=== XONG - TAT CA PASS ===\n");
    } else {
        printf("\n=== XONG - %d CA SAI (make test se do) ===\n", gFail);
    }
    return gFail == 0 ? 0 : 1;
}
