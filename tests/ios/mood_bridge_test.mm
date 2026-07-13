//
//  mood_bridge_test.mm
//  mindful-key — test tự động cho lớp cảm xúc iOS (story 2.2: MoodBridge + SendRiskAnalyzer).
//
//  4 phần, theo đúng chiến lược đã khoá ở story 2.2 Testing:
//   1) Analyzer thuần: gọi thẳng SendRiskAnalyzer_Analyze() với câu tiếng Việt đã biết trước —
//      kỳ vọng khớp công thức 1 - e^(-raw/5) trích từ Dev Notes, không đoán số tuỳ ý.
//   2) Wiring: gõ Telex qua KeyboardBridge (giống bridge_test.mm) sau khi MoodBridge_Init(), rồi
//      đọc MoodBridge_LastSendRisk() sau khi đồng bộ hàng đợi serial bằng
//      MoodBridge_FlushForTesting() (dispatch_sync no-op — không sleep()/polling, đúng Learnings).
//   3) Cổng ô bảo mật (PHỦ ĐỊNH — chỗ dễ sai nhất, privacy-critical): bật secure field rồi gõ câu
//      chắc chắn kích risk cao — risk KHÔNG được đổi.
//   4) Edge case: chuỗi rỗng/khoảng trắng, ký tự lặp qua collapseRuns, chuyển đổi secure↔không
//      NGAY GIỮA phiên gõ.
//
//  Chạy trên HOST (macOS) như bridge_test.mm — không cần Simulator. Xem mood_bridge_build.sh.

#import <Foundation/Foundation.h>
#include <cmath>
#import "Engine.h"          // startNewSession()
#import "EngineKeyMap.h"
#import "KeyboardBridge.h"
#import "MoodBridge.h"
#import "SendRiskAnalyzer.h"

static int gFail = 0;

static void expectNear(const char *label, double got, double want, double eps) {
    BOOL ok = std::fabs(got - want) <= eps;
    if (!ok) gFail++;
    printf("  %-52s got=%.6f  want=%.6f (+-%.6f)  %s\n", label, got, want, eps, ok ? "OK" : "SAI <<<");
}

static void expectTrue(const char *label, BOOL cond) {
    if (!cond) gFail++;
    printf("  %-52s %s\n", label, cond ? "OK" : "SAI <<<");
}

// ===== Phần 1: analyzer thuần =====
// Công thức trích từ SendRiskAnalyzer.mm (rút nguyên xi từ MoodWatchMac.mm): raw tính từ lexicon
// có trọng số theo category (giận=1.0, +=0.6, còn lại=0.35), risk = 1 - e^(-raw/5), kẹp <= 1.0.
static void testAnalyzerPure() {
    printf("\n-- Phần 1: SendRiskAnalyzer_Analyze() thuần --\n");

    // "bực" đơn lẻ (score -2, category "giận" -> weight 1.0), không kèm "mình" nên KHÔNG khớp
    // thêm needle "bực mình" — chỉ 1 match sạch, tránh bẫy nhiều needle lexicon chồng lên nhau
    // (vd "giận" đứng RIÊNG cũng là 1 entry LEX ngoài "tức"/"tức giận" — câu chứa cả 3 sẽ cộng
    // dồn cả 3, không phải chỉ needle dài nhất).
    // raw = |(-2)|*1.0 = 2.0 -> risk = 1 - e^(-2/5).
    {
        double risk = SendRiskAnalyzer_Analyze(L"tôi đang bực quá");
        double want = 1.0 - std::exp(-2.0 / 5.0);
        expectNear("\"...bực...\" (giận, weight 1.0, match đơn)", risk, want, 1e-9);
    }

    // "vui" (score +2, category "+", weight 0.6) và "cảm ơn" (score +2, category "+", weight 0.6)
    // đều dương -> trừ vào raw. raw tổng = -(2*0.6) - (2*0.6) = -2.4 -> raw<0 nên chốt về 0 -> risk=0.
    {
        double risk = SendRiskAnalyzer_Analyze(L"cảm ơn bạn nhiều, hôm nay tôi rất vui");
        expectNear("\"cảm ơn...vui\" (toàn tích cực, raw chốt 0)", risk, 0.0, 1e-9);
    }

    // Câu trung tính, không khớp từ nào trong LEX/LEX_SUB -> raw=0 chính xác -> risk=0.0 CHÍNH XÁC
    // (không phải xấp xỉ — không có phép tính nào chạy khi không match).
    {
        double risk = SendRiskAnalyzer_Analyze(L"hôm nay trời nắng đẹp đi dạo công viên");
        expectNear("câu trung tính không khớp LEX (raw=0 chính xác)", risk, 0.0, 0.0);
    }

    // "vcl" nằm trong LEX_SUB (chửi thề, KHÁC mảng LEX — "đm"/"dm"/"đéo" mới là LEX thường có
    // score riêng, không tự động hardHit) -> hardHit=true -> raw=max(raw,9.0) dù raw từ vòng LEX
    // = 0 (không từ nào trong "sao mà chậm thế" khớp LEX) -> risk = 1 - e^(-9/5), gần 1.0.
    {
        double risk = SendRiskAnalyzer_Analyze(L"vcl sao mà chậm thế");
        double want = 1.0 - std::exp(-9.0 / 5.0);
        expectNear("\"vcl...\" (LEX_SUB hardHit, raw=max(raw,9))", risk, want, 1e-9);
    }
}

// ===== Phần 2/3/4: wiring qua MoodBridge — đồng bộ bằng MoodBridge_FlushForTesting() =====

static void typeTelexThroughBridge(const char *telex) {
    startNewSession();
    NSString *input = [NSString stringWithUTF8String:telex];
    for (NSUInteger i = 0; i < input.length; i++) {
        unichar c = [input characterAtIndex:i];
        if (c == ' ') {
            KeyboardBridge_HandleSpace();
            continue;
        }
        NSString *ch = [NSString stringWithCharacters:&c length:1];
        NSNumber *keyCode = EngineKeyMap_CharacterToKeyCode()[ch];
        if (keyCode == nil) continue;
        KeyboardBridge_HandleKeyTap(keyCode.unsignedShortValue, NO);
    }
    // Verify chạy thật (xem Dev Agent Record): engine hoãn commit từ CUỐI CÙNG tới khi phím kế
    // tiếp được xử lý hoặc startNewSession() được gọi tường minh — 1 khoảng trắng cuối chuỗi
    // KHÔNG tự flush. Gọi startNewSession() lần nữa ở đây để buộc flush từ cuối cùng ngay trong
    // helper này (không dựa vào lần gọi startNewSession() ở ĐẦU lệnh gõ kế tiếp) — không gây hại
    // khi không còn gì đang dở (emitCommittedWord() tự no-op nếu _index<=0).
    startNewSession();
    MoodBridge_FlushForTesting(); // chờ mọi dispatch_async do các từ vừa commit trong lúc gõ xong
}

static void testWiring() {
    printf("\n-- Phần 2: wiring MoodBridge_Init()/vOnWordCommitted --\n");

    MoodBridge_SetSecureFieldActive(NO);
    double before = MoodBridge_LastSendRisk();
    // "tuwsc giaanj " gõ Telex ra "tức giận " (verify chạy thật, xem Dev Agent Record) -> commit
    // đủ từ căng để chắc chắn risk > baseline.
    typeTelexThroughBridge("tuwsc giaanj ");
    double after = MoodBridge_LastSendRisk();
    expectTrue("risk đổi (tăng) sau khi gõ câu căng qua bridge", after > before);
}

static void testSecureFieldGateNegative() {
    printf("\n-- Phần 3: cổng ô bảo mật (PHỦ ĐỊNH) --\n");

    MoodBridge_SetSecureFieldActive(NO);
    typeTelexThroughBridge("vui vui "); // câu trung tính/tích cực trước — thiết lập baseline
    double baseline = MoodBridge_LastSendRisk();

    MoodBridge_SetSecureFieldActive(YES);
    // "vcl" nằm trong LEX_SUB -> chắc chắn kích hardHit (risk cao) NẾU cổng không chặn.
    typeTelexThroughBridge("vcl ");
    double afterSecure = MoodBridge_LastSendRisk();

    expectTrue("risk KHÔNG đổi khi secure field=YES dù gõ câu kích risk cao",
               afterSecure == baseline);

    MoodBridge_SetSecureFieldActive(NO); // dọn trạng thái cho ca sau
}

static void testEdgeCases() {
    printf("\n-- Phần 4: edge case --\n");

    // 4a. Chuỗi rỗng/chỉ khoảng trắng vào analyzer trực tiếp — không crash, risk = 0.0.
    expectNear("analyzer chuỗi rỗng", SendRiskAnalyzer_Analyze(L""), 0.0, 0.0);
    expectNear("analyzer chỉ khoảng trắng", SendRiskAnalyzer_Analyze(L"   "), 0.0, 0.0);

    // 4b. Ký tự lặp ("đmmmmm") qua collapseRuns đã rút — rút gọn về "đm" (run>=3 -> 1 ký tự) nên
    // vẫn khớp LEX y hệt "đm" thường ("đm" là 1 entry LEX thường, score -4, KHÔNG phải LEX_SUB).
    {
        double riskRepeated = SendRiskAnalyzer_Analyze(L"đmmmmm sao chậm thế");
        double riskNormal = SendRiskAnalyzer_Analyze(L"đm sao chậm thế");
        expectNear("\"đmmmmm\" qua collapseRuns == \"đm\" thường", riskRepeated, riskNormal, 1e-9);
    }

    // 4c. Chuyển đổi secure<->không-secure NGAY GIỮA phiên gõ: bật secure field rồi gõ 1 từ căng
    // (bị bỏ qua) — chỉ từ commit SAU khi cờ chuyển về NO mới được tính vào risk mới nhất.
    printf("  -- 4c. chuyển đổi secure<->không-secure giữa phiên gõ --\n");
    MoodBridge_SetSecureFieldActive(NO);
    typeTelexThroughBridge("oorn "); // "ổn " — trung tính/tích cực nhẹ, thiết lập baseline
    double baseline = MoodBridge_LastSendRisk();

    MoodBridge_SetSecureFieldActive(YES);
    typeTelexThroughBridge("vcl "); // từ căng (LEX_SUB) gõ TRONG lúc đang secure — phải bị bỏ qua
    double stillSecure = MoodBridge_LastSendRisk();
    expectTrue("risk giữ nguyên trong lúc đang secure", stillSecure == baseline);

    MoodBridge_SetSecureFieldActive(NO);
    typeTelexThroughBridge("vcl "); // cùng từ, gõ SAU khi cờ đã về NO — phải được tính
    double afterUnsecure = MoodBridge_LastSendRisk();
    expectTrue("risk đổi cho từ commit SAU khi cờ về NO", afterUnsecure != baseline);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        KeyboardBridge_Init();
        MoodBridge_Init();

        printf("=== TEST LỚP CẢM XÚC iOS (story 2.2: MoodBridge + SendRiskAnalyzer) ===\n");

        testAnalyzerPure();
        testWiring();
        testSecureFieldGateNegative();
        testEdgeCases();

        if (gFail == 0) {
            printf("\n=== XONG — TẤT CẢ PASS ===\n");
        } else {
            printf("\n=== XONG — %d CA SAI (make test-ios sẽ đỏ) ===\n", gFail);
        }
    }
    return gFail == 0 ? 0 : 1;
}
