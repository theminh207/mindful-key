//
//  ReflectionScreenMac.mm
//  ModernKey
//
//  [MINDFUL] Xem ReflectionScreenMac.h.
//

#import "ReflectionScreenMac.h"
#import <Cocoa/Cocoa.h>
#import "MoodStoreMac.h"
#import "MoodPhrasingMac.h"
#import "EmotionRiverView.h"
#import "BrandColors.h"
// Cho link chuông gọi onBellSettingsSelected. Cùng lối ViewController.m / InputMethodCardView.mm /
// ConvertToolViewController.mm / OpenKey.mm đã dùng: import AppDelegate.h + global `appDelegate`.
#import "AppDelegate.h"

extern AppDelegate* appDelegate;

static NSInteger HourOf(long long epochSeconds) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    return [cal components:NSCalendarUnitHour fromDate:[NSDate dateWithTimeIntervalSince1970:epochSeconds]].hour;
}

// [MINDFUL] Story 3.6 (AC3) — mô tả THỜI ĐIỂM trong ngày, không phải ĐỘ LỚN bằng số (xem
// DESIGN.md §1.2/§2.2 "KHÔNG nhãn số").
// [MINDFUL] 2026-07-16 — ranh giới buổi ĐÃ dời sang `MoodPhrasingMac` (nguồn duy nhất): thẻ Gác
// cổng nay cũng đọc buổi, giữ bản chép riêng ở đây là sắp có 3 bản trôi lệch nhau — đúng thứ
// comment cũ tại chỗ này đã tự cảnh báo. Giữ tên hàm cũ để phần dưới file không phải sửa theo.
static NSString *TimeOfDayLabel(long long epochSeconds) {
    return MoodPhrasing_TimeOfDayLabel(epochSeconds);
}

// [MINDFUL] Soi lại v2.1 (2026-07-16) — HÌNH DẠNG NGÀY. Trước đây câu hỏi + gợi ý bốc ngẫu nhiên
// từ 1 rổ chung, nên ngày phẳng lặng vẫn bị hỏi "điều gì khiến bạn dễ nóng lên nhất?" — câu hỏi
// cãi thẳng cái quan sát nằm ngay trên nó ("Hôm nay mặt hồ khá phẳng lặng"). Nay phân 3 hình dạng
// từ dữ liệu ĐÃ CÓ (peakAmp/gkCount) rồi hỏi đúng cái ngày đó thật sự có. Xem decision-log
// 2026-07-16 "Cải tiến 3 màn cảm xúc", mục 2.
typedef NS_ENUM(NSInteger, MKDayShape) {
    MKDayShapeCalm = 0,   // không gợn đáng kể cả ngày
    MKDayShapeRippled,    // có gợn thật, nhưng gác cổng chưa lần nào phải dừng
    MKDayShapeGated,      // gác cổng đã dừng ≥ 1 lần — bằng chứng mạnh nhất, thắng mọi thứ khác
};

// Ngưỡng "có gợn hay không". DÙNG CHUNG với ObservationParagraph có chủ đích: câu quan sát và
// câu hỏi phải đọc cùng một ngày, lệch ngưỡng là chúng nói ngược nhau ngay trên cùng màn hình.
// [MINDFUL] 2026-07-16 — nay trỏ về `MoodPhrasingMac` (nguồn duy nhất), vì thẻ Gác cổng cũng đọc
// cùng ngưỡng này: màn Soi lại nói "phẳng lặng" mà thẻ nói "có gợn" thì người dùng tin ai?
static const double kRippleThreshold = kMoodRippleThreshold;

static MKDayShape DayShapeOf(double peakAmp, int gkCount) {
    if (gkCount > 0) return MKDayShapeGated;
    if (peakAmp >= kRippleThreshold) return MKDayShapeRippled;
    return MKDayShapeCalm;
}

// [MINDFUL] Story 3.6 v2 (2026-07-16, khớp artifact "Vòng Soi lại" chủ dự án gửi) — tiêu đề cửa
// sổ dùng thứ+ngày thật thay vì chuỗi tĩnh "Soi lại hôm nay", khớp mockup "Soi lại · Thứ Hai 13·07".
static NSArray<NSString *> *WeekdayNames(void) {
    return @[@"Chủ Nhật", @"Thứ Hai", @"Thứ Ba", @"Thứ Tư", @"Thứ Năm", @"Thứ Sáu", @"Thứ Bảy"];
}

static NSString *ReflectionWindowTitle(void) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:(NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitMonth)
                                      fromDate:[NSDate date]];
    NSString *weekday = WeekdayNames()[(NSUInteger)comps.weekday - 1];
    return [NSString stringWithFormat:@"Soi lại · %@ %02ld·%02ld", weekday, (long)comps.day, (long)comps.month];
}

static NSString *CapitalizeFirst(NSString *s) {
    if (s.length == 0) return s;
    return [[[s substringToIndex:1] uppercaseString] stringByAppendingString:[s substringFromIndex:1]];
}

// [MINDFUL] Story 3.6 v2 — gộp "đỉnh gợn vào buổi nào" + "quãng lặng dài nhất vào buổi nào"
// thành 1 đoạn quan sát tường thuật (khớp mockup: 2 câu, cùng giọng thời-điểm-trong-ngày, không
// số thô). Thay cho 2 dòng tách rời trước đây (peakDescription riêng + "Quãng lặng dài nhất: N
// phút" riêng — dòng phút đã bỏ hẳn, thông tin gộp vào đây dưới dạng mô tả buổi, không phải số).
static NSString *ObservationParagraph(double peakAmp, long long peakTs,
                                       long long maxQuietStart, long long maxQuietEnd) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (peakAmp < kRippleThreshold) {
        [parts addObject:@"Hôm nay mặt hồ khá phẳng lặng."];
    } else {
        [parts addObject:[NSString stringWithFormat:@"Mặt hồ gợn nhiều nhất vào %@.", TimeOfDayLabel(peakTs)]];
    }
    if (maxQuietStart >= 0 && maxQuietEnd > maxQuietStart) {
        [parts addObject:[NSString stringWithFormat:@"%@ là quãng lặng dài nhất.",
                           CapitalizeFirst(TimeOfDayLabel(maxQuietStart))]];
    }
    return [parts componentsJoinedByString:@" "];
}

// [MINDFUL] Story 3.6 v2 — nhãn mục kiểu "eyebrow" (hoa, giãn chữ nhẹ, tông đá trung tính) khớp
// mockup .sect. Dùng NSKernAttributeName để giãn chữ — NSTextField không có thuộc tính riêng.
static NSTextField *EyebrowLabel(NSString *title) {
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:10.5 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [Brand stone],
        NSKernAttributeName: @(1.0),
    };
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:title.uppercaseString attributes:attrs];
    NSTextField *l = [NSTextField labelWithAttributedString:attr];
    l.bordered = NO;
    l.editable = NO;
    l.backgroundColor = [NSColor clearColor];
    return l;
}

// [MINDFUL] Story 3.6 v2 — layout tính "khoảng cách TỪ ĐỈNH nội dung xuống" (dễ đọc/dễ chèn thêm
// nhịp hơn cộng-dồn số âm), rồi lật toạ độ sang hệ NSView (gốc dưới-trái) qua ĐÚNG 1 hàm này —
// tránh lớp lỗi vừa vá ở SettingsWindowController (2 công thức tưởng giống nhau nhưng lệch).
static inline CGFloat ReflY(CGFloat contentH, CGFloat topOffset, CGFloat elemH) {
    return contentH - topOffset - elemH;
}

// Câu hỏi phản chiếu — MỞ, không phán xét, không chấm điểm. Mỗi hình dạng ngày có rổ riêng: ngày
// phẳng lặng được hỏi về cái đã giữ cho nó nhẹ, KHÔNG bị hỏi về cơn nóng không hề xảy ra.
static NSArray<NSString *> *ReflectivePromptsFor(MKDayShape shape) {
    if (shape == MKDayShapeGated) {
        return @[
            @"Có lúc bạn dừng lại trước khi gửi. Lúc đó trong người bạn đang có gì?",
            @"Điều gì đang thật sự nằm sau những lúc căng hôm nay — mệt, áp lực, hay điều gì khác?",
            @"Nếu ngày mai gặp lại đúng tình huống đó, bạn muốn mình phản ứng khác đi thế nào?",
            @"Nhìn lại, khoảng dừng đó đã đổi được gì — hay không đổi gì cả?",
        ];
    }
    if (shape == MKDayShapeRippled) {
        return @[
            @"Có lúc mặt hồ gợn lên hôm nay — bạn còn nhớ mình đang làm gì lúc đó không?",
            @"Cơn gợn hôm nay đến từ đâu — người, việc, hay chỉ là mệt?",
            @"Sau lúc gợn nhất, điều gì đã giúp bạn lắng lại?",
            @"Nếu ngày mai gợn lên đúng như vậy, bạn muốn mình để ý điều gì sớm hơn?",
        ];
    }
    return @[
        @"Hôm nay mặt hồ khá phẳng. Điều gì đã giữ cho ngày nhẹ như vậy?",
        @"Ngày êm cũng đáng nhìn lại: hôm nay bạn đã làm gì khác với những ngày căng?",
        @"Có điều gì của hôm nay bạn muốn giữ lại cho ngày mai không?",
        @"Khi ngày trôi êm, bạn thường đang ở cùng ai, làm việc gì?",
    ];
}

// Gợi ý nhỏ — nhỏ thật sự, làm được ngay, không phải lời khuyên to tát. Cũng khớp hình dạng ngày:
// ngày êm thì không có gì để "khắc phục", gợi ý là giữ lấy cái đang tốt.
static NSArray<NSString *> *TinySuggestionsFor(MKDayShape shape) {
    if (shape == MKDayShapeGated) {
        return @[
            @"Nhắn cho chính mình 1 câu nhẹ nhàng, như cách bạn sẽ an ủi một người bạn.",
            @"Trước khi trả lời một tin nhắn khó, thử đọc lại một lượt rồi mới bấm gửi.",
            @"Uống một ly nước, hít thở sâu 3 lần trước khi đóng máy tối nay.",
        ];
    }
    if (shape == MKDayShapeRippled) {
        return @[
            @"Lúc thấy gợn lên, thử đứng dậy đi vài bước trước khi gõ tiếp.",
            @"Uống một ly nước, hít thở sâu 3 lần trước khi đóng máy tối nay.",
            @"Ngày mai, thử để điện thoại xa tay hơn quanh khung giờ dễ căng nhất.",
        ];
    }
    return @[
        @"Trước khi ngủ, thử viết 1 câu về điều bạn biết ơn hôm nay.",
        @"Ngày êm là lúc dễ tập thở nhất — thử 3 hơi thật sâu trước khi đóng máy.",
        @"Nếu ngày mai bận hơn, thử giữ lại một quãng trống giống hôm nay.",
    ];
}

// [MINDFUL] Soi lại v2.1 — chọn câu theo NGÀY, không bốc lại mỗi lần mở. Mở Soi lại lần thứ hai
// trong cùng một ngày phải thấy ĐÚNG câu hỏi đó: câu nhảy giữa chừng biến việc được hỏi thành
// việc bị máy quay số, và làm mất luôn cái "mang câu hỏi theo cả ngày" mà chân trang đang hứa.
static NSUInteger DaySeed(void) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *c = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                 fromDate:[NSDate date]];
    return (NSUInteger)(c.year * 10000 + c.month * 100 + c.day);
}

// salt: để câu hỏi và gợi ý không dính cứng vào nhau thành một cặp cố định.
static NSString *PickForToday(NSArray<NSString *> *items, NSUInteger salt) {
    if (items.count == 0) return @"";
    return items[(DaySeed() + salt) % items.count];
}

@interface MKReflectionWindowController : NSWindowController
@end

@implementation MKReflectionWindowController

// [MINDFUL] Soi lại v2.1 (2026-07-16) — chủ dự án chốt: link chuông MỞ Cài đặt → Chuông, KHÔNG tự
// ghi cài đặt. Bản cũ (`onSuggestAction:`) set vBellFrom=15/vBellTo=17 và sai ở 3 tầng:
//   1. vBellFrom/vBellTo là khung giờ chuông ĐƯỢC PHÉP reo (BellMac.mm isInBellRange), mặc định
//      8→22. Set 15/17 = CÂM chuông 22 tiếng còn lại — ngược hẳn nhãn "Đặt chuông 15-17h".
//   2. Chỉ ghi NSUserDefaults, không cập nhật biến in-memory (chỉ đọc 1 lần ở BellMac_Init) →
//      bấm xong không có tác dụng gì tới khi khởi động lại app.
//   3. Là UI chuông THỨ BA cùng ghi mấy key này — đúng thứ F13 (2026-07-15) vừa dọn ("2 UI đá
//      nhau"); BellSettingsView map ĐẢO CHIỀU sang "Giờ yên lặng" nên màn Cài đặt sẽ hiện
//      "giờ yên lặng 17h→15h".
// Nay tái dùng onBellSettingsSelected của AppDelegate — đúng "1 UI chuông duy nhất", và giữ đúng
// tinh thần lời-mời: app không đổi lén cài đặt người dùng đã chọn.
// Gọi thẳng qua global `appDelegate` (lối sẵn của vỏ này) chứ KHÔNG qua
// [NSApp sendAction:to:nil] — sau khi cửa sổ này đóng thì responder chain không còn gì chắc chắn
// để bám, và bản cũ từng để lại đúng một dòng sendAction bị comment lại ở chỗ này.
- (void)onOpenBellSettings:(id)sender {
    [self.window close];
    [appDelegate onBellSettingsSelected];
}

@end

static MKReflectionWindowController *g_reflWC = nil;

void ReflectionScreenMac_Show(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_reflWC && g_reflWC.window.isVisible) {
            [g_reflWC.window makeKeyAndOrderFront:nil];
            [NSApp activateIgnoringOtherApps:YES];
            return;
        }

        if (!MoodStoreMac_HasConsent()) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.window.level = NSStatusWindowLevel;
            alert.messageText = @"Chưa có nhật ký để soi lại";
            alert.informativeText = @"Bạn chưa bật \"nhật ký cảm xúc\" nên chưa có gì để xem hôm nay.";
            [alert addButtonWithTitle:@"Đã hiểu"];
            [alert runModal];
            return;
        }

        // Lấy dữ liệu
        extern int vBellInterval;
        int intervalMins = vBellInterval > 0 ? vBellInterval : 60;
        NSArray<NSDictionary *> *raw = MoodStoreMac_FetchTodaySamples();
        // [MINDFUL] Epic 3 Chặng 1 (F14) — trước đây hàm này KHÔNG được gọi ở đâu cả (0 nơi gọi
        // toàn repo, dù header comment của file này từ đầu đã ghi "Đọc MoodStoreMac_FetchTodaySummary()").
        // Quyết: NỐI (không xoá) — khớp đúng ý định gốc + mockup đã duyệt ("Gác cổng đã cùng anh
        // dừng lại N lần — M lần anh chọn đợi"), tái dùng SQL đã có sẵn thay vì viết mới.
        NSDictionary *summary = MoodStoreMac_FetchTodaySummary();

        if (raw.count < 3) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.window.level = NSStatusWindowLevel;
            alert.messageText = @"Hồ chưa đủ nét";
            alert.informativeText = @"Hồ chưa đủ nét — ngày mới bắt đầu.";
            [alert addButtonWithTitle:@"Đóng"];
            [alert runModal];
            return;
        }

        // [MINDFUL] Vá trục thời gian (2026-07-16) — vòng lặp này không còn dựng mảng cho sông
        // nữa (sông nhận thẳng `raw` kèm timestamp, xem setTodaySamples: bên dưới). Nó chỉ còn
        // một việc: đọc ra đỉnh + quãng lặng cho câu quan sát.
        double peakAmp = -1;
        long long peakTs = -1;
        long long maxQuietStart = -1, maxQuietEnd = -1, curQuietStart = -1;

        for (int i = 0; i < raw.count; i++) {
            double v = [raw[i][@"value"] doubleValue];
            long long ts = [raw[i][@"ts"] longLongValue];

            if (v > peakAmp) {
                peakAmp = v;
                peakTs = ts;
            }
            
            if (v < 0.4) {
                if (curQuietStart == -1) curQuietStart = ts;
                if (ts - curQuietStart > maxQuietEnd - maxQuietStart) {
                    maxQuietStart = curQuietStart;
                    maxQuietEnd = ts;
                }
            } else {
                curQuietStart = -1;
            }

            if (i < raw.count - 1) {
                long long ts1 = [raw[i][@"ts"] longLongValue];
                long long ts2 = [raw[i+1][@"ts"] longLongValue];
                if (ts2 - ts1 > intervalMins * 60.0 * 1.5) {
                    curQuietStart = -1; // Ngắt quãng lặng
                }
            }
        }

        // [MINDFUL] Story 3.6 v2 — maxQuietStart/maxQuietEnd đã tính đúng ở vòng lặp trên (loại
        // quãng không gõ, đúng công thức "quãng lặng" đã chốt). Trước đây hiện thành số thô
        // "Quãng lặng dài nhất: N phút"; nay gộp vào ObservationParagraph dưới dạng mô tả buổi,
        // khớp artifact "Vòng Soi lại" chủ dự án gửi — không còn số thô nào trong màn này.

        // [MINDFUL] Epic 3 Chặng 1 (F14) — dòng thống kê gác cổng, khớp mockup A1 đã duyệt
        // ("Gác cổng đã cùng anh dừng lại 3 lần — 2 lần anh chọn đợi."). Gate copy: mô tả, không
        // phán xét — kể cả câu 0 lần cũng chỉ nói sự thật, không khen/chê.
        // Soi lại v2.1 (2026-07-16): mockup trên xưng "anh", app xưng "bạn" ở mọi chỗ khác → đã
        // thống nhất về "bạn". Trích dẫn mockup giữ nguyên để còn truy được nguồn, ĐỪNG chép lại.
        int gkCount = [summary[@"gatekeeperCount"] intValue];
        int gkWait = [summary[@"waitCount"] intValue];
        NSString *gkLine;
        if (gkCount <= 0) {
            gkLine = @"Gác cổng chưa cần dừng bạn lần nào hôm nay.";
        } else {
            gkLine = [NSString stringWithFormat:@"Gác cổng đã cùng bạn dừng lại %d lần — %d lần bạn chọn đợi.", gkCount, gkWait];
        }

        NSString *obsText = ObservationParagraph(peakAmp, peakTs, maxQuietStart, maxQuietEnd);

        // [MINDFUL] Soi lại v2.1 — hình dạng ngày quyết định câu hỏi, gợi ý, VÀ việc có mời chỉnh
        // chuông hay không. Ngày phẳng lặng không có "giờ đỉnh" đáng để canh → không mời (mời đặt
        // chuông canh một cơn nóng không xảy ra chính là kiểu tự-tạo-vấn-đề mà màn này phải tránh).
        MKDayShape shape = DayShapeOf(peakAmp, gkCount);
        BOOL showBellLink = (shape != MKDayShapeCalm) && (peakTs >= 0);

        // [MINDFUL] Story 3.6 (AC1/AC2) — sông thật thay khung chữ phẳng. TÁI DÙNG nguyên
        // EmotionRiverView (đã chạy ở popover + cửa sổ Cài đặt từ 2.4), nhồi CHÍNH `raw` đã fetch
        // ở trên — không fetch/transform lại lần 2. Story 3.6 v2 — ẩn caption tự sinh của view
        // (obsText bên dưới đã thay thế, tránh 2 câu chồng nhau).
        // Vá trục thời gian (2026-07-16): dùng setTodaySamples: để chấm nằm đúng giờ — nếu không,
        // màn này nói "gợn nhiều nhất vào buổi sáng" (giờ thật từ peakTs) trong khi cái chấm lại
        // chường ra dưới nhãn "Tối". Hai câu cãi nhau trên cùng một màn hình.
        EmotionRiverView *riverView = [[EmotionRiverView alloc] initWithFrame:NSZeroRect];
        [riverView setTodaySamples:raw gapSeconds:intervalMins * 60.0 * 1.5];
        [riverView setCaptionHidden:YES];
        CGFloat riverH = [riverView preferredHeight];

        // [MINDFUL] Story 3.6 v2 (2026-07-16) — viết lại theo artifact "Vòng Soi lại" chủ dự án
        // gửi: 3 nhịp Nhận ra/Soi/Nuôi dưỡng (bỏ nhịp "Cho phép" riêng — nội dung của nó gộp vào
        // obsText ở nhịp 1), có đường ngăn giữa các nhịp, câu hỏi kèm caption phụ, thẻ gợi ý tách
        // nền + link chuông cam nhẹ, chân trang 3 dòng tin cậy. Mọi khoảng cách cộng dồn
        // TỪ ĐỈNH XUỐNG rồi lật toạ độ qua ReflY() — một nguồn duy nhất cho contentH lẫn vị trí
        // từng phần tử, tránh đúng lớp lỗi 2-công-thức-tưởng-khớp-nhau vừa vá ở SettingsWindowController.
        CGFloat contentW = 440.0, pad = 20.0, winW = 480.0;
        CGFloat eyebrowH = 15.0, eyebrowGap = 10.0;
        CGFloat obsGap = 10.0, obsH = 56.0;
        CGFloat gkGap = 6.0, gkH = 16.0;
        CGFloat dividerGap = 18.0, dividerH = 1.0, afterDivGap = 18.0;
        CGFloat qGap = 8.0, qH = 78.0;
        CGFloat qcapGap = 6.0, qcapH = 15.0;
        CGFloat sugGap = 10.0;
        CGFloat cardPad = 14.0, sugTextH = 34.0, linkGap = 10.0, linkH = 20.0;
        CGFloat bottomPad = 18.0, footerH = 34.0;

        CGFloat yTop = 22.0; // đỉnh nội dung -> eyebrow đầu tiên

        CGFloat eyebrow1Y = yTop; yTop += eyebrowH + eyebrowGap;
        CGFloat riverY    = yTop; yTop += riverH + obsGap;
        CGFloat obsY      = yTop; yTop += obsH + gkGap;
        CGFloat gkY       = yTop; yTop += gkH + dividerGap;
        CGFloat div1Y     = yTop; yTop += dividerH + afterDivGap;

        CGFloat eyebrow2Y = yTop; yTop += eyebrowH + qGap;
        CGFloat qY        = yTop; yTop += qH + qcapGap;
        CGFloat qcapY     = yTop; yTop += qcapH + dividerGap;
        CGFloat div2Y     = yTop; yTop += dividerH + afterDivGap;

        CGFloat eyebrow3Y = yTop; yTop += eyebrowH + sugGap;
        CGFloat cardY     = yTop;
        CGFloat cardH     = cardPad * 2 + sugTextH + (showBellLink ? (linkGap + linkH) : 0.0);
        yTop += cardH + bottomPad;

        CGFloat contentH = yTop + footerH;

        NSRect frame = NSMakeRect(0, 0, winW, contentH);
        NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                      backing:NSBackingStoreBuffered defer:NO];
        win.title = ReflectionWindowTitle();
        [win center];
        win.releasedWhenClosed = NO;

        NSView *content = [[NSView alloc] initWithFrame:frame];
        content.wantsLayer = YES;
        content.layer.backgroundColor = [NSColor whiteColor].CGColor;
        win.contentView = content;

        g_reflWC = [[MKReflectionWindowController alloc] initWithWindow:win];

        // Nhịp 1: Nhận ra
        NSTextField *ebRealize = EyebrowLabel(@"Nhận ra");
        ebRealize.frame = NSMakeRect(pad, ReflY(contentH, eyebrow1Y, eyebrowH), contentW, eyebrowH);
        [content addSubview:ebRealize];

        riverView.frame = NSMakeRect(pad, ReflY(contentH, riverY, riverH), contentW, riverH);
        [content addSubview:riverView];

        NSTextField *obsLabel = [NSTextField wrappingLabelWithString:obsText];
        obsLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightRegular];
        obsLabel.textColor = [Brand charcoal];
        obsLabel.frame = NSMakeRect(pad, ReflY(contentH, obsY, obsH), contentW, obsH);
        [content addSubview:obsLabel];

        // [MINDFUL] Epic 3 Chặng 1 (F14) — dòng gác cổng, nối MoodStoreMac_FetchTodaySummary
        NSTextField *gkLabel = [NSTextField labelWithString:gkLine];
        gkLabel.font = [NSFont systemFontOfSize:12 weight:NSFontWeightRegular];
        gkLabel.textColor = [Brand muted];
        gkLabel.frame = NSMakeRect(pad, ReflY(contentH, gkY, gkH), contentW, gkH);
        [content addSubview:gkLabel];

        NSBox *div1 = [[NSBox alloc] initWithFrame:NSMakeRect(pad, ReflY(contentH, div1Y, dividerH), contentW, dividerH)];
        div1.boxType = NSBoxSeparator;
        [content addSubview:div1];

        // Nhịp 2: Soi
        NSTextField *ebSoi = EyebrowLabel(@"Soi");
        ebSoi.frame = NSMakeRect(pad, ReflY(contentH, eyebrow2Y, eyebrowH), contentW, eyebrowH);
        [content addSubview:ebSoi];

        NSTextField *qLabel = [NSTextField wrappingLabelWithString:PickForToday(ReflectivePromptsFor(shape), 0)];
        qLabel.font = [NSFont systemFontOfSize:18 weight:NSFontWeightSemibold];
        qLabel.textColor = [Brand charcoal];
        qLabel.frame = NSMakeRect(pad, ReflY(contentH, qY, qH), contentW, qH);
        [content addSubview:qLabel];

        NSTextField *qcapLabel = [NSTextField labelWithString:@"Không cần trả lời ngay — mang câu hỏi theo cũng đủ."];
        qcapLabel.font = [NSFont systemFontOfSize:12 weight:NSFontWeightRegular];
        qcapLabel.textColor = [Brand stone];
        qcapLabel.frame = NSMakeRect(pad, ReflY(contentH, qcapY, qcapH), contentW, qcapH);
        [content addSubview:qcapLabel];

        NSBox *div2 = [[NSBox alloc] initWithFrame:NSMakeRect(pad, ReflY(contentH, div2Y, dividerH), contentW, dividerH)];
        div2.boxType = NSBoxSeparator;
        [content addSubview:div2];

        // Nhịp 3: Nuôi dưỡng
        NSTextField *ebNourish = EyebrowLabel(@"Nuôi dưỡng");
        ebNourish.frame = NSMakeRect(pad, ReflY(contentH, eyebrow3Y, eyebrowH), contentW, eyebrowH);
        [content addSubview:ebNourish];

        // [MINDFUL] Thẻ gợi ý — nền cam nhạt, CÙNG ngoại lệ "brand chrome cho khoảnh khắc con
        // người" đã dùng ở SendGatekeeperMac (docs/BRAND-ASSETS.md) — KHÔNG mã hoá trạng thái
        // cảm xúc, chỉ là nền cho nhịp "Nuôi dưỡng".
        NSView *card = [[NSView alloc] initWithFrame:NSMakeRect(pad, ReflY(contentH, cardY, cardH), contentW, cardH)];
        card.wantsLayer = YES;
        card.layer.backgroundColor = [Brand orangeLight].CGColor;
        card.layer.cornerRadius = 10.0;
        [content addSubview:card];

        NSTextField *sugLabel = [NSTextField wrappingLabelWithString:PickForToday(TinySuggestionsFor(shape), 1)];
        sugLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightRegular];
        sugLabel.textColor = [Brand charcoal];
        sugLabel.backgroundColor = [NSColor clearColor];
        sugLabel.frame = NSMakeRect(cardPad, cardH - cardPad - sugTextH, contentW - 2 * cardPad, sugTextH);
        [card addSubview:sugLabel];

        // [MINDFUL] Soi lại v2.1 — nút cam ĐẶC "Đặt chuông 15-17h" hạ xuống LINK cam nhẹ: nút đặc
        // kéo mắt khỏi câu hỏi, mà câu hỏi mới là trọng tâm màn này (chủ dự án chốt 2026-07-16).
        // Giờ trong nhãn là giờ đỉnh THẬT của ngày, đọc từ peakTs — không còn 15-17h hardcode.
        // "Để sau" đi cùng nút đặc cũng bỏ theo: một lời mời thì bỏ qua bằng cách... bỏ qua, không
        // cần nút để từ chối. Cửa sổ vẫn đóng được bằng nút đóng sẵn có.
        if (showBellLink) {
            NSString *linkTitle = [NSString stringWithFormat:@"Chỉnh chuông quanh %ldh →", (long)HourOf(peakTs)];
            NSButton *bellLink = [NSButton buttonWithTitle:@"" target:g_reflWC action:@selector(onOpenBellSettings:)];
            bellLink.bordered = NO;
            bellLink.bezelStyle = NSBezelStyleInline;
            [(NSButtonCell *)bellLink.cell setBackgroundColor:[NSColor clearColor]];
            bellLink.attributedTitle = [[NSAttributedString alloc] initWithString:linkTitle attributes:@{
                NSForegroundColorAttributeName : [Brand orange],
                NSFontAttributeName : [NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium],
            }];
            // Bề rộng đo từ chính chuỗi: NSButton canh giữa nhãn, khung rộng dư sẽ đẩy chữ ra giữa thẻ.
            CGFloat linkW = ceil(bellLink.attributedTitle.size.width) + 8.0;
            bellLink.frame = NSMakeRect(cardPad, cardPad, linkW, linkH);
            [card addSubview:bellLink];
        }

        // Chân trang — 3 dòng tin cậy tĩnh, khớp mockup .rfoot.
        NSBox *footerDiv = [[NSBox alloc] initWithFrame:NSMakeRect(0, footerH, winW, dividerH)];
        footerDiv.boxType = NSBoxSeparator;
        [content addSubview:footerDiv];

        NSTextField *footerLabel = [NSTextField labelWithString:@"Xử lý trên máy · Câu hỏi mỗi ngày một khác · Không điểm số, không chuỗi ngày"];
        footerLabel.font = [NSFont systemFontOfSize:10.5 weight:NSFontWeightRegular];
        footerLabel.textColor = [Brand stone];
        footerLabel.alignment = NSTextAlignmentCenter;
        footerLabel.frame = NSMakeRect(0, 0, winW, footerH - 10.0);
        [content addSubview:footerLabel];

        [win makeKeyAndOrderFront:nil];
        [win setLevel:NSFloatingWindowLevel];
        [NSApp activateIgnoringOtherApps:YES];
    });
}
