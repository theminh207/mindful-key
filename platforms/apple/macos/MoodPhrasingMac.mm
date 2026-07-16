//
//  MoodPhrasingMac.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Xem MoodPhrasingMac.h cho lý do tồn tại + ràng buộc hiến chương.
//

#import "MoodPhrasingMac.h"

const double kMoodRippleThreshold = 0.4;

// Ranh giới buổi — NGUỒN DUY NHẤT. Khớp `kAxisHour*` (EmotionRiverView.mm) đang đặt nhãn trục:
// sáng 5-11, trưa 11-13, chiều 13-18, tối 18-24. Đổi ở đây thì phải đổi kèm bên đó, và ngược lại.
typedef NS_ENUM(NSInteger, MKTimeOfDay) {
    MKTimeOfDayMorning = 0,
    MKTimeOfDayNoon,
    MKTimeOfDayAfternoon,
    MKTimeOfDayEvening,
    MKTimeOfDayCount
};

static MKTimeOfDay TimeOfDayOf(long long epochSeconds) {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger hour = [cal components:NSCalendarUnitHour
                            fromDate:[NSDate dateWithTimeIntervalSince1970:epochSeconds]].hour;
    if (hour >= 5 && hour < 11)  return MKTimeOfDayMorning;
    if (hour >= 11 && hour < 13) return MKTimeOfDayNoon;
    if (hour >= 13 && hour < 18) return MKTimeOfDayAfternoon;
    return MKTimeOfDayEvening;
}

NSString *MoodPhrasing_TimeOfDayLabel(long long epochSeconds) {
    switch (TimeOfDayOf(epochSeconds)) {
        case MKTimeOfDayMorning:   return @"buổi sáng";
        case MKTimeOfDayNoon:      return @"buổi trưa";
        case MKTimeOfDayAfternoon: return @"buổi chiều";
        default:                   return @"buổi tối";
    }
}

// Tên buổi dạng NGẮN để ghép vào câu ("Sáng và chiều có gợn"), khác dạng dài "buổi sáng" dùng khi
// đứng một mình ("Mặt hồ gợn nhiều nhất vào buổi sáng").
static NSString *ShortLabel(MKTimeOfDay t) {
    switch (t) {
        case MKTimeOfDayMorning:   return @"sáng";
        case MKTimeOfDayNoon:      return @"trưa";
        case MKTimeOfDayAfternoon: return @"chiều";
        default:                   return @"tối";
    }
}

static NSString *CapitalizeFirst(NSString *s) {
    if (s.length == 0) return s;
    return [[[s substringToIndex:1] uppercaseString] stringByAppendingString:[s substringFromIndex:1]];
}

// Nối kiểu người nói: "sáng" · "sáng và chiều" · "sáng, trưa và chiều".
static NSString *JoinNatural(NSArray<NSString *> *parts) {
    if (parts.count == 0) return @"";
    if (parts.count == 1) return parts[0];
    NSArray *head = [parts subarrayWithRange:NSMakeRange(0, parts.count - 1)];
    return [NSString stringWithFormat:@"%@ và %@",
            [head componentsJoinedByString:@", "], parts.lastObject];
}

NSString *MoodPhrasing_DayShapeSentence(NSArray<NSDictionary *> *todaySamples) {
    if (todaySamples.count == 0) {
        // Thật thà: chưa có gì thì nói chưa có gì. KHÔNG suy ra "hôm nay êm" từ chỗ không có dữ
        // liệu — im lặng của bàn phím không phải bằng chứng của sự bình yên (dec.4 cùng tinh thần).
        return @"Chưa có nhịp nào hôm nay";
    }

    BOOL rippled[MKTimeOfDayCount] = {NO, NO, NO, NO};
    NSInteger calmCount = 0;
    for (NSDictionary *s in todaySamples) {
        double v = [s[@"value"] doubleValue];
        if (v >= kMoodRippleThreshold) {
            rippled[TimeOfDayOf([s[@"ts"] longLongValue])] = YES;
        } else {
            calmCount++;
        }
    }

    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSInteger i = 0; i < MKTimeOfDayCount; i++) {
        if (rippled[i]) [names addObject:ShortLabel((MKTimeOfDay)i)];
    }

    if (names.count == 0) {
        return @"Hôm nay tới giờ vẫn êm";
    }

    NSString *s = [NSString stringWithFormat:@"%@ có gợn", CapitalizeFirst(JoinNatural(names))];
    // "phần lớn êm" chỉ nói khi ĐÚNG là phần lớn — nói bừa cho dịu tai là phán xét trá hình, và
    // sai sự thật thì người dùng mất tin vào mọi câu khác của app.
    if (calmCount * 2 > (NSInteger)todaySamples.count) {
        s = [s stringByAppendingString:@", phần lớn êm"];
    }
    return s;
}
