// test_bell_policy.cpp
// Khoá hành vi của core/mood/BellPolicy — chính sách chuông DÙNG CHUNG cho macOS · iOS · Windows.
// Nó lệch là mỗi vỏ tự quyết định "có reo không" theo luật riêng — đúng cái bẫy dự án đã trả giá
// (NudgeCoordinatorIOS.h tự thú "sao y bản chính từ macOS", Windows sắp thành bản thứ ba).
//
// KHÔNG có sleep, KHÔNG đọc đồng hồ thật: thời điểm do test truyền vào, nên chạy tất định và
// nhanh — cùng lý do BellPolicy không tự gọi đồng hồ hệ thống (xem BellPolicy.h).
//
// Mọi ca dưới đây dùng cooldownMs = 45000 (45 giây) và thresholdCpm = 400 trừ khi nói khác, để dễ
// tính tay: mức tái vũ trang = 400 * kBellPolicyHysteresisFactor(0.9) = 360.
//
// Build: xem tests/core/bell_policy_build.sh

#include <cstdio>
#include "BellPolicy.h"

static int gFail = 0;   // exit code != 0 để make/CI gate được khi có regression

static void checkBool(const char* name, bool got, bool want) {
    if (got == want) {
        printf("  ✅ %-74s = %s\n", name, got ? "true" : "false");
    } else {
        printf("  ❌ SAI  %-74s = %s, mong đợi %s\n", name, got ? "true" : "false", want ? "true" : "false");
        gFail++;
    }
}

int main() {
    const int64_t COOLDOWN = 45000;   // 45 giây, khớp cooldown đang chạy thật ở NudgeCoordinatorMac
    const double THRESHOLD = 400.0;   // "Rất nhanh" — mặc định chốt ở ADR-0013

    printf("=== BellPolicy — cooldown %lldms, ngưỡng %.0f CPM ===\n", (long long)COOLDOWN, THRESHOLD);

    printf("\n--- Loại 1: một tràng gõ nhanh dài liên tục chỉ reo ĐÚNG MỘT LẦN ---\n");
    {
        // CPM không bao giờ tụt xuống dưới ngưỡng trong suốt tràng gõ: không bao giờ tái vũ
        // trang, nên dù thời gian trôi qua bao lâu (kể cả vượt hẳn cooldown), vẫn không reo lần
        // thứ hai. Đây là ca hồi quy quan trọng nhất: nếu ai đó "sửa" thành chỉ dựa vào cooldown
        // (bỏ cổng 3 "đã vũ trang") thì ca này sẽ reo lại ở t=45000, sai với issue #7 đòi hỏi.
        BellPolicy p(COOLDOWN);
        checkBool("t=0 cpm=450 -> reo lần đầu",                p.evaluate(450.0, THRESHOLD, 0,      true, false), true);
        checkBool("t=1000 cpm=450 -> không reo (chưa tụt)",    p.evaluate(450.0, THRESHOLD, 1000,   true, false), false);
        checkBool("t=10000 cpm=460 -> vẫn không reo",          p.evaluate(460.0, THRESHOLD, 10000,  true, false), false);
        checkBool("t=45000 cpm=450 -> cooldown đã hết NHƯNG vẫn không reo (chưa tái vũ trang)",
                                                                p.evaluate(450.0, THRESHOLD, 45000,  true, false), false);
        checkBool("t=120000 cpm=500 -> vẫn im, đúng 1 lần duy nhất cho cả tràng gõ",
                                                                p.evaluate(500.0, THRESHOLD, 120000, true, false), false);
    }

    printf("\n--- Loại 2: cooldown chặn RIÊNG, tách biệt khỏi trạng thái đã vũ trang ---\n");
    {
        // Khác Loại 1 ở chỗ: CPM CÓ tụt đủ sâu (300 < mức tái vũ trang 360) sau lần reo đầu, nên
        // tái vũ trang thật sự xảy ra — nhưng tiếp đó vẫn không reo lần hai cho tới khi cooldown
        // hết HẲN.
        BellPolicy p(COOLDOWN);
        checkBool("t=0 cpm=450 -> reo lần 1",                          p.evaluate(450.0, THRESHOLD, 0,     true, false), true);
        checkBool("t=1000 cpm=300 (< mức tái vũ trang 360) -> tái vũ trang, nhưng dưới ngưỡng nên không reo",
                                                                        p.evaluate(300.0, THRESHOLD, 1000,  true, false), false);
        checkBool("t=2000 cpm=450, đã vũ trang NHƯNG còn trong cooldown -> không reo",
                                                                        p.evaluate(450.0, THRESHOLD, 2000,  true, false), false);
        checkBool("t=44999 cpm=450 -> còn thiếu 1ms nữa mới hết cooldown -> không reo",
                                                                        p.evaluate(450.0, THRESHOLD, 44999, true, false), false);
        checkBool("t=45000 cpm=450 -> ĐÚNG 45000ms sau lần reo trước -> hết cooldown, reo lần 2",
                                                                        p.evaluate(450.0, THRESHOLD, 45000, true, false), true);
    }

    printf("\n--- Loại 3: chống rung — tụt KHÔNG đủ sâu thì KHÔNG tính là đợt mới ---\n");
    {
        // Đây là ca khoá cơ chế hysteresis: tụt xuống 380 (dưới ngưỡng 400 nhưng KHÔNG dưới mức
        // tái-vũ-trang 360) không đủ để mở lại cơ hội reo, dù thời gian trôi qua rất xa (t=100000,
        // gấp hơn 2 lần cooldown). Chỉ khi tụt thật sự xuống dưới 360 thì chuông mới sẵn sàng lại.
        BellPolicy p(COOLDOWN);
        checkBool("t=0 cpm=450 -> reo lần 1",                         p.evaluate(450.0, THRESHOLD, 0,      true, false), true);
        checkBool("t=1000 cpm=380 (dưới ngưỡng, KHÔNG dưới mức tái vũ trang 360) -> không tái vũ trang",
                                                                       p.evaluate(380.0, THRESHOLD, 1000,  true, false), false);
        checkBool("t=100000 cpm=450, đã qua cooldown RẤT xa NHƯNG chưa tái vũ trang -> vẫn im",
                                                                       p.evaluate(450.0, THRESHOLD, 100000, true, false), false);
        checkBool("t=100001 cpm=350 (< mức tái vũ trang 360) -> LẦN NÀY tái vũ trang thật",
                                                                       p.evaluate(350.0, THRESHOLD, 100001, true, false), false);
        checkBool("t=100002 cpm=450 -> đã vũ trang + qua cooldown từ lâu -> reo lần 2",
                                                                       p.evaluate(450.0, THRESHOLD, 100002, true, false), true);
    }

    printf("\n--- Loại 4: tắt chuông (enabled=false) KHÔNG tiêu lượt vũ trang ---\n");
    {
        BellPolicy p(COOLDOWN);
        checkBool("t=0 cpm=450, enabled=false -> không reo",          p.evaluate(450.0, THRESHOLD, 0,    false, false), false);
        checkBool("t=1000 cpm=450, vẫn tắt -> vẫn không reo",         p.evaluate(450.0, THRESHOLD, 1000, false, false), false);
        checkBool("t=2000 cpm=450, BẬT lại -> reo NGAY, cơ hội còn nguyên (không phải chờ tụt rồi vượt lại)",
                                                                       p.evaluate(450.0, THRESHOLD, 2000, true,  false), true);
    }

    printf("\n--- Loại 5: tạm hoãn (snoozed=true) KHÔNG tiêu lượt vũ trang ---\n");
    {
        BellPolicy p(COOLDOWN);
        checkBool("t=0 cpm=450, snoozed=true -> không reo",           p.evaluate(450.0, THRESHOLD, 0,    true, true),  false);
        checkBool("t=1000 cpm=450, vẫn hoãn -> vẫn không reo",        p.evaluate(450.0, THRESHOLD, 1000, true, true),  false);
        checkBool("t=2000 cpm=450, HẾT hoãn -> reo NGAY, cơ hội còn nguyên",
                                                                       p.evaluate(450.0, THRESHOLD, 2000, true, false), true);
    }

    printf("\n--- Loại 6: ca biên — CPM ĐÚNG BẰNG ngưỡng ---\n");
    {
        // Chốt: "đạt đúng mức người dùng đặt" tính là đã chạm (>=), không phải chờ vượt hẳn lên.
        BellPolicy p(COOLDOWN);
        checkBool("cpm == threshold (400.0 == 400.0) -> CÓ reo",      p.evaluate(400.0, THRESHOLD, 0, true, false), true);

        BellPolicy p2(COOLDOWN);
        checkBool("cpm = 399.0, dưới ngưỡng 1 CPM -> không reo",      p2.evaluate(399.0, THRESHOLD, 0, true, false), false);
    }

    printf("\n--- Loại 7: cooldownMs <= 0 kẹp về 0 — không có khoảng lặng tối thiểu ---\n");
    {
        BellPolicy p(0);
        checkBool("t=0 cpm=450 -> reo lần 1",                          p.evaluate(450.0, THRESHOLD, 0, true, false), true);
        checkBool("t=1 cpm=300 (< mức tái vũ trang 360) -> tái vũ trang", p.evaluate(300.0, THRESHOLD, 1, true, false), false);
        checkBool("t=2 cpm=450, cooldown=0 -> reo lần 2 chỉ 2ms sau",  p.evaluate(450.0, THRESHOLD, 2, true, false), true);
    }
    {
        BellPolicy p(-500);
        checkBool("cooldownMs âm -> cũng kẹp về 0: reo lần 1",         p.evaluate(450.0, THRESHOLD, 0, true, false), true);
        checkBool("tụt dưới mức tái vũ trang -> tái vũ trang",         p.evaluate(300.0, THRESHOLD, 1, true, false), false);
        checkBool("reo lần 2 ngay sau, không bị cooldown chặn",        p.evaluate(450.0, THRESHOLD, 2, true, false), true);
    }

    if (gFail == 0)
        printf("\n=== XONG — TẤT CẢ PASS ===\n");
    else
        printf("\n=== XONG — %d CA SAI (make test sẽ đỏ) ===\n", gFail);
    return gFail == 0 ? 0 : 1;
}
