//
//  ReflectionScreenMac.mm
//  ModernKey
//
//  [MINDFUL] Xem ReflectionScreenMac.h.
//

#import "ReflectionScreenMac.h"
#import <Cocoa/Cocoa.h>
#import "MoodStoreMac.h"
#import "EmotionRiverView.h"
#import "BrandColors.h"

// [MINDFUL] Story 3.6 (AC3) — mô tả THỜI ĐIỂM trong ngày, không phải ĐỘ LỚN bằng số (xem
// DESIGN.md §1.2/§2.2 "KHÔNG nhãn số"). Ranh giới buổi dùng giờ THẬT (NSCalendar), độc lập với
// cách EmotionRiverView tự chia trục 4 phần đều theo vị trí vẽ (view không biết giờ thật —
// xem EmotionRiverView.mm dòng 197-200, chỉ chia đều bề rộng, không theo mốc giờ) — 2 cách chia
// khác nhau có chủ đích, câu mô tả ưu tiên đúng giờ thật hơn là khớp tuyệt đối với trục vẽ.
static NSString *TimeOfDayLabel(long long epochSeconds) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSCalendarUnitHour fromDate:[NSDate dateWithTimeIntervalSince1970:epochSeconds]];
    NSInteger hour = comps.hour;
    if (hour >= 5 && hour < 11)  return @"buổi sáng";
    if (hour >= 11 && hour < 13) return @"buổi trưa";
    if (hour >= 13 && hour < 18) return @"buổi chiều";
    return @"buổi tối";
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
    if (peakAmp < 0.4) {
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

// Câu hỏi phản chiếu — MỞ, không phán xét, không chấm điểm. Chọn ngẫu nhiên 1 câu mỗi lần xem,
// để không nhàm và không biến thành "câu cố định máy móc".
static NSArray<NSString *> *ReflectivePrompts(void) {
    return @[
        @"Nhìn lại hôm nay, điều gì khiến bạn dễ nóng lên nhất?",
        @"Có khoảnh khắc nào hôm nay bạn ước mình đã chậm lại một nhịp trước khi phản ứng?",
        @"Nếu ngày mai gặp lại đúng tình huống đó, bạn muốn mình phản ứng khác đi thế nào?",
        @"Điều gì đang thật sự nằm sau những lúc căng thẳng hôm nay — mệt, áp lực, hay điều gì khác?",
    ];
}

// Gợi ý nhỏ — nhỏ thật sự, làm được ngay, không phải lời khuyên to tát.
static NSArray<NSString *> *TinySuggestions(void) {
    return @[
        @"Trước khi ngủ, thử viết 1 câu về điều bạn biết ơn hôm nay.",
        @"Ngày mai, thử để điện thoại xa tay hơn trong khung giờ dễ căng thẳng nhất.",
        @"Uống một ly nước, hít thở sâu 3 lần trước khi đóng máy tối nay.",
        @"Nhắn cho chính mình 1 câu nhẹ nhàng, như cách bạn sẽ an ủi một người bạn.",
    ];
}

static NSString *RandomFrom(NSArray<NSString *> *items) {
    if (items.count == 0) return @"";
    return items[arc4random_uniform((uint32_t)items.count)];
}

@interface MKReflectionWindowController : NSWindowController
@end

@implementation MKReflectionWindowController

- (void)onClose:(id)sender {
    [self.window close];
}

- (void)onSuggestAction:(id)sender {
    // Hành động nuôi dưỡng: mở Cài đặt -> Chuông
    // [NSApp sendAction:@selector(onSettingsSelected) to:nil from:nil];
    // Dùng URL scheme hoặc trực tiếp. Chúng ta lưu mặc định trước nếu cần.
    [[NSUserDefaults standardUserDefaults] setInteger:15 forKey:@"vBellFrom"];
    [[NSUserDefaults standardUserDefaults] setInteger:17 forKey:@"vBellTo"];
    [self.window close];
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

        NSMutableArray *samples = [NSMutableArray array];
        double peakAmp = -1;
        long long peakTs = -1;
        long long maxQuietStart = -1, maxQuietEnd = -1, curQuietStart = -1;
        
        for (int i = 0; i < raw.count; i++) {
            double v = [raw[i][@"value"] doubleValue];
            long long ts = [raw[i][@"ts"] longLongValue];
            [samples addObject:@(v)];
            
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
                    [samples addObject:[NSNull null]];
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
        int gkCount = [summary[@"gatekeeperCount"] intValue];
        int gkWait = [summary[@"waitCount"] intValue];
        NSString *gkLine;
        if (gkCount <= 0) {
            gkLine = @"Gác cổng chưa cần dừng anh lần nào hôm nay.";
        } else {
            gkLine = [NSString stringWithFormat:@"Gác cổng đã cùng anh dừng lại %d lần — %d lần anh chọn đợi.", gkCount, gkWait];
        }

        NSString *obsText = ObservationParagraph(peakAmp, peakTs, maxQuietStart, maxQuietEnd);

        // [MINDFUL] Story 3.6 (AC1/AC2) — sông thật thay khung chữ phẳng. TÁI DÙNG nguyên
        // EmotionRiverView (đã chạy ở popover + cửa sổ Cài đặt từ 2.4), nhồi CHÍNH mảng `samples`
        // vừa build ở vòng lặp trên — không fetch/transform lại lần 2. Story 3.6 v2 — ẩn caption
        // tự sinh của view (obsText bên dưới đã thay thế, tránh 2 câu chồng nhau).
        EmotionRiverView *riverView = [[EmotionRiverView alloc] initWithFrame:NSZeroRect];
        [riverView setSamples:samples];
        [riverView setCaptionHidden:YES];
        CGFloat riverH = [riverView preferredHeight];

        // [MINDFUL] Story 3.6 v2 (2026-07-16) — viết lại theo artifact "Vòng Soi lại" chủ dự án
        // gửi: 3 nhịp Nhận ra/Soi/Nuôi dưỡng (bỏ nhịp "Cho phép" riêng — nội dung của nó gộp vào
        // obsText ở nhịp 1), có đường ngăn giữa các nhịp, câu hỏi kèm caption phụ, thẻ gợi ý tách
        // nền + 2 nút (CTA cam + "Để sau"), chân trang 3 dòng tin cậy. Mọi khoảng cách cộng dồn
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
        CGFloat cardPad = 14.0, sugTextH = 34.0, btnGap = 10.0, btnH = 30.0;
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
        CGFloat cardH     = cardPad * 2 + sugTextH + btnGap + btnH;
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

        NSTextField *qLabel = [NSTextField wrappingLabelWithString:RandomFrom(ReflectivePrompts())];
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

        NSTextField *sugLabel = [NSTextField wrappingLabelWithString:RandomFrom(TinySuggestions())];
        sugLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightRegular];
        sugLabel.textColor = [Brand charcoal];
        sugLabel.backgroundColor = [NSColor clearColor];
        sugLabel.frame = NSMakeRect(cardPad, cardH - cardPad - sugTextH, contentW - 2 * cardPad, sugTextH);
        [card addSubview:sugLabel];

        NSButton *ctaBtn = [NSButton buttonWithTitle:@"Đặt chuông 15-17h" target:g_reflWC action:@selector(onSuggestAction:)];
        ctaBtn.bezelStyle = NSBezelStyleRounded;
        ctaBtn.bezelColor = [Brand orange];
        ctaBtn.frame = NSMakeRect(cardPad, 0, 150, btnH);
        [card addSubview:ctaBtn];

        // "Để sau" — bỏ qua gợi ý, KHÔNG đổi giờ chuông. Tái dùng nguyên onClose: (đã đúng nghĩa
        // "đóng, không làm gì thêm"), không cần thêm action mới.
        NSButton *ghostBtn = [NSButton buttonWithTitle:@"" target:g_reflWC action:@selector(onClose:)];
        ghostBtn.bordered = NO;
        ghostBtn.bezelStyle = NSBezelStyleInline;
        [(NSButtonCell *)ghostBtn.cell setBackgroundColor:[NSColor clearColor]];
        ghostBtn.attributedTitle = [[NSAttributedString alloc] initWithString:@"Để sau" attributes:@{
            NSForegroundColorAttributeName : [Brand stone],
            NSFontAttributeName : [NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium],
        }];
        ghostBtn.frame = NSMakeRect(cardPad + 150.0 + btnGap, 0, 100, btnH);
        [card addSubview:ghostBtn];

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
