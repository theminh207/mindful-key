//
//  ReflectionScreenMac.mm
//  ModernKey
//
//  [MINDFUL] Xem ReflectionScreenMac.h.
//

#import "ReflectionScreenMac.h"
#import <Cocoa/Cocoa.h>
#import "MoodStoreMac.h"

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

void ReflectionScreenMac_Show(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.window.level = NSStatusWindowLevel;

        if (!MoodStoreMac_HasConsent()) {
            alert.messageText = @"Chưa có nhật ký để soi lại";
            alert.informativeText =
                @"Bạn chưa bật \"nhật ký cảm xúc\" nên chưa có gì để xem hôm nay. Bạn có thể bật "
                 "trong lần khởi động app tiếp theo, hoặc bất cứ lúc nào qua cài đặt.";
            [alert addButtonWithTitle:@"Đã hiểu"];
            [alert runModal];
            return;
        }

        NSDictionary *summary = MoodStoreMac_FetchTodaySummary();
        int count = [summary[@"gatekeeperCount"] intValue];
        int sendAnyway = [summary[@"sendAnywayCount"] intValue];
        int wait = [summary[@"waitCount"] intValue];
        int peakHour = [summary[@"peakHour"] intValue];
        NSString *topApp = summary[@"topAppBundleID"];

        // [MINDFUL] Trọng tâm là CÂU HỎI PHẢN CHIẾU, không phải con số — số liệu chỉ làm bối
        // cảnh phụ (informativeText), không phải messageText (thứ người đọc thấy đầu tiên).
        alert.messageText = RandomFrom(ReflectivePrompts());

        NSMutableString *info = [NSMutableString string];
        if (count == 0) {
            [info appendString:@"Hôm nay chưa có lần \"gác cổng\" nào được ghi nhận — một ngày nhẹ nhàng, hoặc đơn giản là hôm nay bạn chưa cần tới nó.\n\n"];
        } else {
            [info appendFormat:@"Hôm nay: %d lần gác cổng", count];
            if (peakHour >= 0) {
                [info appendFormat:@", nhiều nhất quanh %d giờ", peakHour];
            }
            if (topApp.length > 0) {
                [info appendFormat:@", chủ yếu ở %@", topApp];
            }
            [info appendString:@".\n"];
            if (wait > 0 || sendAnyway > 0) {
                [info appendFormat:@"Trong đó %d lần bạn chọn đợi chút, %d lần vẫn gửi.\n", wait, sendAnyway];
            }
            [info appendString:@"\n"];
        }
        [info appendFormat:@"💡 %@", RandomFrom(TinySuggestions())];
        alert.informativeText = info;

        [alert addButtonWithTitle:@"Đóng"];
        [alert runModal];
    });
}
