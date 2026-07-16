//
//  NotesHistoryMac.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Xem NotesHistoryMac.h cho lý do tồn tại + ràng buộc hiến chương (CỨNG).
//
//  Gate "mô tả hay phán xét?" (HIẾN CHƯƠNG §5.8) — mọi copy trong file này đã tự soi:
//    "Những dòng bạn đã viết" (tên màn: mô tả nội dung, không khen "bạn chăm quá") ·
//    "Chỉ nằm trên máy · đã mã hoá" (sự thật kỹ thuật) · ngày tháng (dữ kiện) ·
//    câu hỏi hôm đó (chính chữ app đã hỏi). KHÔNG có câu nào chấm điểm/thúc giục. ✅
//
//  Cố ý KHÔNG có ở màn này: sóng · số đo · số đếm ngày · chuỗi ngày · ô trống cho ngày không viết ·
//  nút "viết ngay". Xem .h — mỗi cái đều có lý do, đừng thêm lại.
//

#import "NotesHistoryMac.h"
#import "MoodStoreMac.h"
#import "BrandColors.h"
#import <Cocoa/Cocoa.h>

// Layout (điểm) — theo ngôn ngữ thẻ trắng viền mảnh của các màn brand khác.
static const CGFloat kWinW      = 560.0;
static const CGFloat kWinH      = 620.0;
static const CGFloat kPad       = 28.0;   // lề trái/phải nội dung
static const CGFloat kTopPad    = 24.0;
static const CGFloat kFooterH   = 34.0;
static const CGFloat kDateH     = 15.0;   // dòng ngày (eyebrow)
static const CGFloat kDateGap   = 7.0;    // ngày → câu hỏi (hoặc chữ nếu không có câu hỏi)
static const CGFloat kQGap      = 5.0;    // câu hỏi → chữ
static const CGFloat kEntryGap  = 26.0;   // giữa 2 ghi chú
static const CGFloat kRuleGap   = 13.0;   // chữ → đường ngăn → ngày kế

static NSArray<NSString *> *MKWeekdayNames(void) {
    return @[@"Chủ Nhật", @"Thứ Hai", @"Thứ Ba", @"Thứ Tư", @"Thứ Năm", @"Thứ Sáu", @"Thứ Bảy"];
}

// "THỨ NĂM 16·07" — cùng khuôn với tiêu đề cửa sổ Soi lại (ReflectionWindowTitle), để 2 màn nói
// cùng một kiểu ngày. Cố ý KHÔNG có "hôm nay"/"hôm qua"/"3 ngày trước": khoảng-cách-tới-hôm-nay là
// thứ mời người ta đếm xem mình bỏ bao lâu rồi (§2.4).
static NSString *DateLabelFor(long long ts) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)ts];
    NSDateComponents *c = [cal components:(NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear)
                                 fromDate:d];
    NSString *weekday = MKWeekdayNames()[(NSUInteger)c.weekday - 1];
    NSInteger nowYear = [cal component:NSCalendarUnitYear fromDate:[NSDate date]];
    if (c.year != nowYear) {
        // Năm chỉ hiện khi KHÁC năm nay — đủ để không nhầm, không biến dòng ngày thành mã số.
        return [NSString stringWithFormat:@"%@ %02ld·%02ld·%ld", weekday, (long)c.day, (long)c.month, (long)c.year];
    }
    return [NSString stringWithFormat:@"%@ %02ld·%02ld", weekday, (long)c.day, (long)c.month];
}

static CGFloat HeightForText(NSString *s, NSFont *font, CGFloat width) {
    NSRect r = [s boundingRectWithSize:NSMakeSize(width, 10000)
                               options:NSStringDrawingUsesLineFragmentOrigin
                            attributes:@{NSFontAttributeName: font}];
    return ceil(r.size.height);
}

#pragma mark - Cửa sổ

@interface MKNotesHistoryWindowController : NSWindowController
@end
@implementation MKNotesHistoryWindowController
@end

static MKNotesHistoryWindowController *g_notesWC = nil;

BOOL NotesHistoryMac_HasAnyNote(void) {
    // FetchAllNotes tự trả @[] khi chưa consent, nên không cần check consent riêng ở đây.
    return MoodStoreMac_FetchAllNotes().count > 0;
}

void NotesHistoryMac_Show(void) {
    NSArray<NSDictionary *> *notes = MoodStoreMac_FetchAllNotes();

    // Không có gì để đọc ⇒ nói thẳng, KHÔNG mở cửa sổ rỗng và KHÔNG rủ rê "viết đi".
    // Lối vào lẽ ra đã ẩn khi chưa có note (HasAnyNote), nên nhánh này chỉ chạy khi ai đó gọi
    // thẳng — giữ lại cho chắc, chứ không phải đường đi thường ngày.
    if (notes.count == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Chưa có dòng nào để đọc lại";
        alert.informativeText = @"Ô ghi nằm ở cuối màn Soi lại — nếu có lúc muốn, bạn ghi lại một dòng cho hôm nay.";
        [alert addButtonWithTitle:@"Đã hiểu"];
        alert.window.level = NSStatusWindowLevel;
        [alert runModal];
        return;
    }

    if (g_notesWC) {
        // Đang mở rồi thì dựng lại nội dung cho tươi (vừa viết thêm ở Soi lại xong chẳng hạn).
        [g_notesWC close];
        g_notesWC = nil;
    }

    NSRect frame = NSMakeRect(0, 0, kWinW, kWinH);
    NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                                styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                  backing:NSBackingStoreBuffered defer:NO];
    win.title = @"Những dòng bạn đã viết";
    win.minSize = NSMakeSize(420, 320);
    [win center];
    win.releasedWhenClosed = NO;

    NSView *content = [[NSView alloc] initWithFrame:frame];
    content.wantsLayer = YES;
    content.layer.backgroundColor = [NSColor whiteColor].CGColor;
    win.contentView = content;

    // Chân trang: cùng lời hứa đang đứng dưới ô ghi ở màn Soi lại — người ta đang đọc nhật ký của
    // chính mình, nhắc lại "chữ này không đi đâu cả" đúng lúc đó là đúng chỗ nhất.
    NSTextField *footer = [NSTextField labelWithString:@"Chỉ nằm trên máy · đã mã hoá · xoá được bất cứ lúc nào."];
    footer.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    footer.textColor = [Brand stone];
    footer.alignment = NSTextAlignmentCenter;
    footer.frame = NSMakeRect(kPad, 11, kWinW - 2 * kPad, kFooterH - 11);
    footer.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    [content addSubview:footer];

    NSView *divider = [[NSView alloc] initWithFrame:NSMakeRect(0, kFooterH, kWinW, 1)];
    divider.wantsLayer = YES;
    divider.layer.backgroundColor = [Brand divider].CGColor;
    divider.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    [content addSubview:divider];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:
                            NSMakeRect(0, kFooterH + 1, kWinW, kWinH - kFooterH - 1)];
    scroll.hasVerticalScroller = YES;
    scroll.hasHorizontalScroller = NO;
    scroll.drawsBackground = NO;
    scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [content addSubview:scroll];

    CGFloat textW = kWinW - 2 * kPad;
    NSFont *qFont    = [NSFont systemFontOfSize:12 weight:NSFontWeightRegular];
    NSFont *bodyFont = [NSFont systemFontOfSize:15 weight:NSFontWeightRegular];

    // Đo trước tổng chiều cao để dựng documentView đúng cỡ (view lật, gốc ở TRÊN — mới nhất trên
    // cùng, đọc từ trên xuống như một chồng giấy).
    CGFloat total = kTopPad;
    NSMutableArray<NSNumber *> *qHeights = [NSMutableArray array];
    NSMutableArray<NSNumber *> *bHeights = [NSMutableArray array];
    for (NSDictionary *n in notes) {
        NSString *q = n[@"question"];
        CGFloat qh = q.length > 0 ? HeightForText(q, qFont, textW) : 0;
        CGFloat bh = HeightForText(n[@"text"], bodyFont, textW);
        [qHeights addObject:@(qh)];
        [bHeights addObject:@(bh)];
        total += kDateH + kDateGap + (qh > 0 ? qh + kQGap : 0) + bh + kEntryGap;
    }
    total += kTopPad;

    NSView *doc = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWinW, MAX(total, kWinH - kFooterH))];
    scroll.documentView = doc;
    CGFloat docH = NSHeight(doc.frame);

    CGFloat y = kTopPad;   // tính từ TRÊN xuống, đổi sang toạ độ AppKit lúc đặt frame
    for (NSUInteger i = 0; i < notes.count; i++) {
        NSDictionary *n = notes[i];
        CGFloat qh = qHeights[i].doubleValue;
        CGFloat bh = bHeights[i].doubleValue;

        NSDictionary *ebAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:10.5 weight:NSFontWeightSemibold],
            NSForegroundColorAttributeName: [Brand stone],
            NSKernAttributeName: @(1.0),
        };
        NSAttributedString *ebStr =
            [[NSAttributedString alloc] initWithString:DateLabelFor([n[@"ts"] longLongValue]).uppercaseString
                                            attributes:ebAttrs];
        NSTextField *dateLbl = [NSTextField labelWithAttributedString:ebStr];
        dateLbl.frame = NSMakeRect(kPad, docH - y - kDateH, textW, kDateH);
        dateLbl.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [doc addSubview:dateLbl];
        y += kDateH + kDateGap;

        // Câu hỏi hôm đó — mờ hơn hẳn chữ người viết. Note ghi trước bản này KHÔNG có câu hỏi lưu
        // kèm; lúc đó bỏ hẳn dòng này, KHÔNG suy ra câu khác nhét vào (suy sai = bịa ra một câu
        // hỏi mà app chưa từng hỏi, và người đọc không có cách nào biết).
        NSString *q = n[@"question"];
        if (q.length > 0) {
            NSTextField *qLbl = [NSTextField wrappingLabelWithString:q];
            qLbl.font = qFont;
            qLbl.textColor = [Brand stone];
            qLbl.frame = NSMakeRect(kPad, docH - y - qh, textW, qh);
            qLbl.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
            [doc addSubview:qLbl];
            y += qh + kQGap;
        }

        // Chữ người viết — to nhất, đậm màu nhất trên màn này. Nó là nhân vật chính.
        NSTextField *body = [NSTextField wrappingLabelWithString:n[@"text"]];
        body.font = bodyFont;
        body.textColor = [Brand charcoal];
        body.selectable = YES;   // chữ của họ — phải copy được ra chỗ khác nếu muốn
        body.frame = NSMakeRect(kPad, docH - y - bh, textW, bh);
        body.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [doc addSubview:body];
        y += bh;

        if (i + 1 < notes.count) {
            NSView *rule = [[NSView alloc] initWithFrame:
                            NSMakeRect(kPad, docH - y - kRuleGap, textW, 1)];
            rule.wantsLayer = YES;
            rule.layer.backgroundColor = [Brand divider].CGColor;
            rule.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
            [doc addSubview:rule];
        }
        y += kEntryGap;
    }

    g_notesWC = [[MKNotesHistoryWindowController alloc] initWithWindow:win];
    [g_notesWC showWindow:nil];
    [win makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];   // app chạy accessory, không có Dock icon
}
