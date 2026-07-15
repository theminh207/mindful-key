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

        // [MINDFUL] Epic 3 Chặng 1 (F14) — maxQuietStart/maxQuietEnd đã tính đúng ở vòng lặp trên
        // (loại quãng không gõ, đúng công thức "quãng lặng" đã chốt) nhưng trước đây KHÔNG BAO GIỜ
        // được hiển thị — l4 bên dưới hardcode chuỗi "(đã tính theo code)", một placeholder lộ ra
        // với người dùng thật. Vá bằng giá trị đã tính sẵn, không viết logic mới.
        NSString *quietStreakText;
        if (maxQuietStart >= 0 && maxQuietEnd > maxQuietStart) {
            long long quietMins = (maxQuietEnd - maxQuietStart) / 60;
            quietStreakText = [NSString stringWithFormat:@"Quãng lặng dài nhất: %lld phút", quietMins];
        } else {
            quietStreakText = @"Quãng lặng dài nhất: chưa đủ dữ liệu để thấy rõ hôm nay.";
        }

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

        // [MINDFUL] Story 3.6 (AC3/AC4) — thay số thô "Đỉnh gợn hôm nay: 0.73" (không che, cấm
        // theo DESIGN.md) bằng câu mô tả buổi. Tái dùng CHÍNH ngưỡng 0.4 đã dùng cho "êm" ở vòng
        // lặp trên (dòng ~113) — nếu đỉnh cao nhất cả ngày vẫn nằm trong vùng êm thì không có
        // "gợn" nào đáng kể, nói thẳng thay vì ép ra 1 buổi giả. Gate copy: mô tả, không phán xét.
        NSString *peakDescription;
        if (peakAmp < 0.4) {
            peakDescription = @"Hôm nay mặt hồ khá phẳng lặng.";
        } else {
            peakDescription = [NSString stringWithFormat:@"Mặt hồ gợn nhiều nhất vào %@.", TimeOfDayLabel(peakTs)];
        }

        // [MINDFUL] Story 3.6 (AC1/AC2) — sông thật thay khung chữ phẳng. TÁI DÙNG nguyên
        // EmotionRiverView (đã chạy ở popover + cửa sổ Cài đặt từ 2.4), nhồi CHÍNH mảng `samples`
        // vừa build ở vòng lặp trên — không fetch/transform lại lần 2.
        EmotionRiverView *riverView = [[EmotionRiverView alloc] initWithFrame:NSZeroRect];
        [riverView setSamples:samples];
        CGFloat riverH = [riverView preferredHeight];

        // Tạo cửa sổ — chiều cao giãn thêm đúng phần sông + 1 khoảng cách nhỏ, KHÔNG đổi bố cục
        // tương đối của nhịp 2/3/4 bên dưới (chúng chỉ bị đẩy xuống theo, không bị nén/cắt cụt).
        CGFloat extraH = riverH + 12.0;
        NSRect frame = NSMakeRect(0, 0, 480, 500 + extraH);
        NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                      backing:NSBackingStoreBuffered defer:NO];
        win.title = @"Soi lại hôm nay";
        [win center];
        win.releasedWhenClosed = NO;

        NSView *content = [[NSView alloc] initWithFrame:frame];
        content.wantsLayer = YES;
        content.layer.backgroundColor = [NSColor whiteColor].CGColor;
        win.contentView = content;

        g_reflWC = [[MKReflectionWindowController alloc] initWithWindow:win];

        // Nhịp 1: Sông thật (Nhận ra)
        CGFloat y = NSHeight(frame) - 150;
        NSTextField *l1 = [NSTextField labelWithString:@"1. Nhận ra"];
        l1.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
        l1.frame = NSMakeRect(20, y+100, 440, 20);
        [content addSubview:l1];

        CGFloat riverTop = y + 100 - 12.0;
        riverView.frame = NSMakeRect(20, riverTop - riverH, 440, riverH);
        [content addSubview:riverView];

        NSTextField *l2 = [NSTextField labelWithString:peakDescription];
        l2.frame = NSMakeRect(20, riverTop - riverH - 24.0, 440, 20);
        [content addSubview:l2];

        // [MINDFUL] Epic 3 Chặng 1 (F14) — dòng gác cổng, nối MoodStoreMac_FetchTodaySummary
        NSTextField *lgk = [NSTextField labelWithString:gkLine];
        lgk.textColor = [NSColor secondaryLabelColor];
        lgk.frame = NSMakeRect(20, riverTop - riverH - 24.0 - 22.0, 440, 18);
        [content addSubview:lgk];

        // Nhịp 2: Cho phép — [MINDFUL] Story 3.6: neo GIỮ NGUYÊN giá trị TUYỆT ĐỐI như bản gốc
        // (500-150-104=246), KHÔNG cộng thêm extraH. Lý do: cửa sổ đã giãn thêm đúng extraH ở
        // đỉnh (NSHeight(frame) = 500+extraH) VÀ nhịp 1 cũng ăn hết đúng extraH đó (river+gap
        // chèn thêm) — 2 hiệu ứng triệt tiêu nhau, đáy nhịp 1 luôn rơi về ~404 bất kể riverH lớn
        // nhỏ thế nào. Cộng thêm extraH ở đây (như bản nháp đầu) sẽ đẩy nhịp 2/3/4 xuống DƯ,
        // để lại 1 khoảng trắng lớn vô nghĩa phía trên chúng.
        y = (500.0 - 150.0) - 104.0;
        NSTextField *l3 = [NSTextField labelWithString:@"2. Cho phép"];
        l3.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
        l3.frame = NSMakeRect(20, y+40, 440, 20);
        [content addSubview:l3];
        
        NSTextField *l4 = [NSTextField labelWithString:quietStreakText];
        l4.frame = NSMakeRect(20, y+20, 440, 20);
        [content addSubview:l4];
        
        // Nhịp 3: Soi
        y -= 120;
        NSTextField *l5 = [NSTextField labelWithString:@"3. Soi"];
        l5.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
        l5.frame = NSMakeRect(20, y+80, 440, 20);
        [content addSubview:l5];
        
        NSTextField *l6 = [NSTextField labelWithString:RandomFrom(ReflectivePrompts())];
        l6.font = [NSFont systemFontOfSize:22 weight:NSFontWeightBold];
        l6.lineBreakMode = NSLineBreakByWordWrapping;
        l6.frame = NSMakeRect(20, y, 440, 80);
        [content addSubview:l6];
        
        // Nhịp 4: Nuôi dưỡng
        y -= 100;
        NSTextField *l7 = [NSTextField labelWithString:@"4. Nuôi dưỡng"];
        l7.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
        l7.frame = NSMakeRect(20, y+60, 440, 20);
        [content addSubview:l7];
        
        NSTextField *l8 = [NSTextField labelWithString:RandomFrom(TinySuggestions())];
        l8.frame = NSMakeRect(20, y+40, 440, 20);
        [content addSubview:l8];
        
        NSButton *btn = [NSButton buttonWithTitle:@"Đặt chuông 15-17h" target:g_reflWC action:@selector(onSuggestAction:)];
        btn.frame = NSMakeRect(20, y, 150, 30);
        btn.bezelStyle = NSBezelStyleRounded;
        [content addSubview:btn];

        [win makeKeyAndOrderFront:nil];
        [win setLevel:NSFloatingWindowLevel];
        [NSApp activateIgnoringOtherApps:YES];
    });
}
