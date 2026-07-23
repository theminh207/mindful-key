//
//  EmotionRiverView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Áo mới v2 — xem EmotionRiverView.h cho hợp đồng + ràng buộc hiến chương.
//

#import "EmotionRiverView.h"
#import "BrandColors.h"
#import "BrandControls.h"
#import <math.h>

static const CGFloat kPad        = 14.0;
static const CGFloat kWaveAreaH  = 44.0;
static const CGFloat kAxisGap    = 4.0;
static const CGFloat kAxisH      = 13.0;
static const CGFloat kCaptionGap = 8.0;
static const CGFloat kCaptionH   = 32.0;   // tối đa 2 dòng

#pragma mark - MKRiverCanvas (vẽ tay: đường sông NẾU có mẫu, TRỐNG nếu chưa)

// Tách riêng phần vẽ khỏi EmotionRiverView để giữ đúng 1 trách nhiệm: view cha lo layout/nhãn,
// canvas này chỉ lo vẽ — và tự khoá luật "không mẫu = không vẽ gì" ngay tại nguồn.
//
// [MINDFUL] Vá trục thời gian (2026-07-16, chủ dự án chốt sau khi bắt được lỗi trên máy thật):
// canvas KHÔNG còn tự suy vị trí từ THỨ TỰ mẫu nữa. Trước đây `mx = m/(k-1)*w` — chấm cuối LUÔN
// dính mép phải, tức luôn nằm dưới nhãn "Tối", kể cả khi nó được ghi lúc 10h sáng. Máy chủ dự án
// có 7 mẫu trong 48 phút buổi sáng mà sông vẽ ra như trọn một ngày. Nhãn Sáng/Trưa/Chiều/Tối
// thành ra nói dối, và cãi luôn màn Soi lại (màn đó đọc giờ THẬT từ peakTs).
// Nay view cha tính sẵn VỊ TRÍ (xf = 0..1 trên bề ngang) cho từng mẫu rồi đưa xuống:
//   - Hôm nay  → xf từ giờ thật  ⇒ nhãn giờ nói thật.
//   - Tuần/Tháng → xf = m/(k-1)  ⇒ 1 chấm = 1 ngày, giãn đều VẪN ĐÚNG, hành vi y như cũ.
// [MINDFUL] 2026-07-20 — mỗi entry giờ là NSDictionary {@"pt": NSValue(NSPoint), @"checkin":
// NSNumber BOOL} thay vì NSValue trần, để mang thêm "chấm này tự thuật hay tự đoán" tới tận vòng
// vẽ. NSNull cho quãng trống giữ NGUYÊN không đổi. 2 hàm inline sau là NƠI DUY NHẤT unwrap —
// ampAt:/drawRect: gọi qua đây, không tự bóc tay để lỡ đổi format sau này chỉ sửa 1 chỗ.
static inline NSPoint MKEntryPoint(id entry) {
    return [(NSValue *)((NSDictionary *)entry)[@"pt"] pointValue];
}
static inline BOOL MKEntryIsCheckin(id entry) {
    return [((NSDictionary *)entry)[@"checkin"] boolValue];
}
static inline NSDictionary *MKMakeEntry(CGFloat xf, double value, BOOL isCheckin) {
    return @{@"pt": [NSValue valueWithPoint:NSMakePoint(xf, value)], @"checkin": @(isCheckin)};
}

@interface MKRiverCanvas : NSView
/// Dict {@"pt": NSValue(NSPoint{x = vị trí 0..1 trên bề ngang, y = biên độ 0..1}), @"checkin":
/// NSNumber BOOL}, hoặc NSNull = NGẮT nước giữa 2 mẫu kề nó (quãng không gõ). Rỗng/nil = chưa có
/// mẫu → KHÔNG vẽ gì (dec.4). checkin=YES vẽ vòng RỖNG (tự thuật), NO vẽ chấm ĐẶC (tự đoán).
@property (nonatomic, copy, nullable) NSArray *entries;
@end

@implementation MKRiverCanvas

- (void)setEntries:(NSArray *)entries {
    _entries = entries;
    [self setNeedsDisplay:YES];
}

// Biên độ nội suy tại vị trí xf, hoặc NO nếu chỗ đó là quãng trống (không có nước).
// Trả NO ở: trước mẫu đầu, sau mẫu cuối, và giữa 2 mẫu bị NSNull ngăn — đúng luật dec.4
// "không bịa nước giả ở chỗ không có dữ liệu".
- (BOOL)ampAt:(CGFloat)xf out:(CGFloat *)outAmp {
    NSUInteger k = _entries.count;
    NSInteger i = -1;
    for (NSUInteger m = 0; m < k; m++) {
        id e = _entries[m];
        if (e == [NSNull null]) continue;
        if (MKEntryPoint(e).x <= xf) i = (NSInteger)m; else break;
    }
    if (i < 0) return NO;                       // xf nằm trước mẫu đầu tiên

    NSPoint a = MKEntryPoint(_entries[(NSUInteger)i]);
    NSUInteger n = (NSUInteger)i + 1;
    id nx = (n < k) ? _entries[n] : nil;

    // Hết mẫu phía sau, hoặc mẫu kế bị NSNull ngăn → chỉ còn đúng điểm mẫu đó có nước.
    if (nx == nil || nx == [NSNull null]) {
        if (fabs(xf - a.x) < 1e-6) { *outAmp = a.y; return YES; }
        return NO;
    }

    NSPoint b = MKEntryPoint(nx);
    if (b.x <= a.x) { *outAmp = a.y; return YES; }   // 2 mẫu trùng vị trí — khỏi chia cho 0
    *outAmp = a.y + (b.y - a.y) * ((xf - a.x) / (b.x - a.x));
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSUInteger k = _entries.count;
    if (k == 0) return;   // trống thật — KHÔNG vẽ đường/chấm giả (HIẾN CHƯƠNG §2.2, decision-log dec.4)

    NSRect b = self.bounds;
    CGFloat midY = NSMidY(b);
    CGFloat w = NSWidth(b);
    CGFloat maxWaveH = NSHeight(b) * 0.42;

    if (w <= 0) return;

    NSColor *teal = [[Brand teal] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];

    NSBezierPath *axis = [NSBezierPath bezierPath];
    axis.lineWidth = 1.0;
    CGFloat axisDash[2] = {2.0, 4.0};
    [axis setLineDash:axisDash count:2 phase:0];
    [axis moveToPoint:NSMakePoint(0, midY)];
    [axis lineToPoint:NSMakePoint(w, midY)];
    [[[Brand stone] colorWithAlphaComponent:0.5] setStroke];
    [axis stroke];

    // Thu thập các điểm thật để vẽ sóng cong nối tiếp
    NSMutableArray<NSMutableArray<NSDictionary*>*> *segments = [NSMutableArray array];
    NSMutableArray<NSDictionary*> *currentSeg = [NSMutableArray array];
    
    for (NSUInteger m = 0; m < k; m++) {
        id e = _entries[m];
        if (e == [NSNull null]) {
            if (currentSeg.count > 0) {
                [segments addObject:currentSeg];
                currentSeg = [NSMutableArray array];
            }
        } else {
            [currentSeg addObject:e];
        }
    }
    if (currentSeg.count > 0) {
        [segments addObject:currentSeg];
    }

    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = 2.2;
    path.lineCapStyle = NSLineCapStyleRound;
    path.lineJoinStyle = NSLineJoinStyleRound;

    // [MINDFUL] 2026-07-23 (chủ dự án chốt "sửa cách vẽ sóng") — độ cao mỗi điểm = ĐÚNG biên độ
    // của nó (midY + value * maxWaveH), luôn NHÔ LÊN từ đường trục. Trước đây điểm chẵn nhô, điểm
    // lẻ chìm theo THỨ TỰ trong mảng → thêm/bớt một điểm là đảo nhô-chìm của mọi điểm sau nó, mỗi
    // lần refresh sông "nhảy" một kiểu (đúng cái chập chờn chủ dự án thấy). Nay vị trí đứng của một
    // điểm chỉ phụ thuộc GIÁ TRỊ + thời điểm thật của chính nó → thêm điểm mới không dịch điểm cũ.
    // Đường trục nét đứt = mặt hồ phẳng lặng; câu êm (risk≈0) → chấm sát trục; câu gắt → gợn nhô cao.
    for (NSArray<NSDictionary*> *seg in segments) {
        if (seg.count == 0) continue;

        // Tính toạ độ các điểm trong segment
        NSMutableArray<NSValue*> *pts = [NSMutableArray array];
        for (NSUInteger i = 0; i < seg.count; i++) {
            NSPoint s = MKEntryPoint(seg[i]);
            CGFloat mx = s.x * w;
            NSPoint p = NSMakePoint(mx, midY + s.y * maxWaveH);
            [pts addObject:[NSValue valueWithPoint:p]];
        }
        
        NSPoint p0 = [pts[0] pointValue];
        [path moveToPoint:p0];
        
        for (NSUInteger i = 1; i < pts.count; i++) {
            NSPoint pPrev = [pts[i-1] pointValue];
            NSPoint pCurr = [pts[i] pointValue];
            
            // Bezier cong mượt với tiếp tuyến ngang
            NSPoint cp1 = NSMakePoint(pPrev.x + (pCurr.x - pPrev.x) * 0.5, pPrev.y);
            NSPoint cp2 = NSMakePoint(pCurr.x - (pCurr.x - pPrev.x) * 0.5, pCurr.y);
            
            [path curveToPoint:pCurr controlPoint1:cp1 controlPoint2:cp2];
        }
    }
    [teal setStroke];
    [path stroke];

    // Vẽ các chấm — cùng phép đặt độ cao với đường sóng (nhô lên theo giá trị thật), để chấm luôn
    // nằm ĐÚNG trên đường, không lệch.
    for (NSArray<NSDictionary*> *seg in segments) {
        for (NSUInteger i = 0; i < seg.count; i++) {
            NSDictionary *e = seg[i];
            NSPoint s = MKEntryPoint(e);
            CGFloat mx = s.x * w;
            NSPoint closestP = NSMakePoint(mx, midY + s.y * maxWaveH);

            NSRect dot = NSMakeRect(closestP.x - 3.3, closestP.y - 3.3, 6.6, 6.6);
            NSBezierPath *dotPath = [NSBezierPath bezierPathWithOvalInRect:dot];
            if (MKEntryIsCheckin(e)) {
                dotPath.lineWidth = 1.8;
                [[NSColor windowBackgroundColor] setFill];
                [dotPath fill];
                [teal setStroke];
                [dotPath stroke];
            } else {
                [teal setFill];
                [dotPath fill];
            }
        }
    }
}

@end

#pragma mark - EmotionRiverView

// [MINDFUL] Vá trục thời gian (2026-07-16) — mốc GIỜ của 4 nhãn, khớp đúng ranh giới buổi mà
// ReflectionScreenMac.mm/TimeOfDayLabel() đang dùng (sáng 5-11, trưa 11-13, chiều 13-18, tối 18-24).
// Hai nơi phải cùng một ranh giới, lệch là màn Soi lại nói "buổi sáng" mà chấm nằm chỗ khác.
static const CGFloat kDayStartHour       = 5.0;    // sông bắt đầu lúc 5h — trước đó gần như không ai gõ
static const CGFloat kDayEndHour         = 24.0;
static const CGFloat kAxisHourMorning    = 8.0;    // giữa buổi sáng  (5-11)
static const CGFloat kAxisHourNoon       = 12.0;   // giữa buổi trưa  (11-13)
static const CGFloat kAxisHourAfternoon  = 15.5;   // giữa buổi chiều (13-18)
static const CGFloat kAxisHourEvening    = 21.0;   // giữa buổi tối   (18-24)

@implementation EmotionRiverView {
    MKRiverCanvas *_riverArea;
    NSTextField *_axisMorning, *_axisNoon, *_axisAfternoon, *_axisEvening;
    NSTextField *_caption;
    BOOL _captionHidden;
    // Chế độ trục: NO = giãn đều theo thứ tự (Tuần/Tháng — 1 chấm = 1 ngày, giãn đều là ĐÚNG).
    // YES = đặt theo giờ thật trong ngày (Hôm nay) → nhãn cũng nhảy về đúng mốc giờ của nó.
    BOOL _timeBased;
    CGFloat _axisFractions[4];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self applyThinCardStyle];

        _riverArea = [[MKRiverCanvas alloc] initWithFrame:NSZeroRect];
        [self addSubview:_riverArea];

        _axisMorning   = [self axisLabel:@"Sáng"   align:NSTextAlignmentLeft];
        _axisNoon      = [self axisLabel:@"Trưa"   align:NSTextAlignmentCenter];
        _axisAfternoon = [self axisLabel:@"Chiều"  align:NSTextAlignmentCenter];
        _axisEvening   = [self axisLabel:@"Tối"    align:NSTextAlignmentRight];

        _caption = [NSTextField labelWithString:@""];
        _caption.font = [NSFont systemFontOfSize:11.5 weight:NSFontWeightRegular];
        _caption.textColor = [Brand muted];
        _caption.backgroundColor = [NSColor clearColor];
        _caption.bordered = NO;
        _caption.editable = NO;
        _caption.lineBreakMode = NSLineBreakByWordWrapping;
        _caption.maximumNumberOfLines = 2;
        [self addSubview:_caption];

        [self setSamples:nil];   // trạng thái mặc định: TRỐNG thật thà (Bước 3 chưa có nguồn thật)
    }
    return self;
}

// [MINDFUL] Story 3.7 — không đổi tên/chữ ký setSamples:/preferredHeight đã khoá từ 2.4, chỉ
// thêm method MỚI. Không gọi method này → giữ nguyên "Sáng/Trưa/Chiều/Tối" như trước giờ.
- (void)setAxisLabels:(NSArray<NSString *> *)labels {
    if (labels.count != 4) return;
    _axisMorning.stringValue   = labels[0];
    _axisNoon.stringValue      = labels[1];
    _axisAfternoon.stringValue = labels[2];
    _axisEvening.stringValue   = labels[3];
}

// [MINDFUL] Story 3.6 v2 — xem EmotionRiverView.h. Mặc định NO (giữ nguyên hành vi cũ cho
// popover + cửa sổ Cài đặt), ReflectionScreenMac bật YES vì tự viết câu quan sát riêng.
- (void)setCaptionHidden:(BOOL)hidden {
    _captionHidden = hidden;
    _caption.hidden = hidden;
    self.needsLayout = YES;
}

- (NSTextField *)axisLabel:(NSString *)s align:(NSTextAlignment)align {
    NSTextField *l = [NSTextField labelWithString:s];
    l.font = [NSFont systemFontOfSize:10.5 weight:NSFontWeightRegular];
    l.textColor = [Brand stone];
    l.backgroundColor = [NSColor clearColor];
    l.bordered = NO;
    l.editable = NO;
    l.alignment = align;
    [self addSubview:l];
    return l;
}

// Chốt trạng thái sau khi đã dựng xong `entries`: dưới 3 mẫu thật thì coi như chưa đủ nét.
// Dùng chung cho cả 2 lối vào (setSamples: và setTodaySamples:gapSeconds:) để luật "chưa đủ nét"
// chỉ tồn tại ở ĐÚNG một chỗ.
- (void)applyEntries:(nullable NSArray *)entries validCount:(NSInteger)validCount {
    if (validCount < 3) {
        _riverArea.entries = nil;
        // [MINDFUL] Story 3.6 v2 — khớp tông ấm hơn của thiết kế duyệt (artifact "Vòng Soi lại"
        // panel 3 "Ngày gõ ít"): vẫn 1 câu mô tả (không phán xét), chỉ đổi giọng bớt khô.
        _caption.stringValue = @"Hôm nay bàn phím nghỉ nhiều — và điều đó cũng chẳng sao.";
    } else {
        _riverArea.entries = entries;
        _caption.stringValue = @"Mỗi vòng tròn là một nhịp chuông — lúc app lặng lẽ ghi một điểm.";
    }
    self.needsLayout = YES;
}

// Lối CŨ, giữ nguyên nghĩa: mẫu giãn ĐỀU theo thứ tự. Đúng cho Tuần/Tháng (1 chấm = 1 ngày, các
// ngày vốn cách đều nhau). KHÔNG dùng cho "Hôm nay" — nhịp chuông trong ngày cách nhau không đều.
- (void)setSamples:(nullable NSArray *)samples {
    _timeBased = NO;
    NSArray *src = samples.count > 0 ? [samples copy] : nil;

    NSMutableArray *entries = [NSMutableArray arrayWithCapacity:src.count];
    NSInteger validCount = 0;
    NSUInteger k = src.count;
    for (NSUInteger m = 0; m < k; m++) {
        id val = src[m];
        if (val == [NSNull null]) {
            [entries addObject:[NSNull null]];
            continue;
        }
        validCount++;
        CGFloat xf = (k > 1) ? (CGFloat)m / (CGFloat)(k - 1) : 0.5;
        // checkin luôn NO ở đây: Tuần/Tháng là TRUNG BÌNH theo ngày (1 chấm = 1 ngày, đã gộp mọi
        // nhịp trong ngày đó lại) — "chấm này tự thuật hay tự đoán" không còn ý nghĩa ở mức 1 ngày.
        [entries addObject:MKMakeEntry(xf, [val doubleValue], NO)];
    }
    [self applyEntries:entries validCount:validCount];
}

// [MINDFUL] Vá trục thời gian (2026-07-16) — lối MỚI cho "Hôm nay": đặt mẫu theo GIỜ THẬT.
// Nhận thẳng dạng MoodStoreMac_FetchTodaySamples() trả về, nên 3 màn (popover / cửa sổ Hôm nay /
// Soi lại) hết phải mỗi nơi tự chép một vòng lặp gom NSNull rồi vứt mất timestamp.
- (void)setTodaySamples:(nullable NSArray<NSDictionary *> *)samples gapSeconds:(double)gapSeconds {
    _timeBased = YES;

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *midnight = [cal startOfDayForDate:[NSDate date]];
    double dayOrigin = [midnight timeIntervalSince1970];

    // Cửa sổ ngày = [kDayStartHour, 24h]. Nếu có mẫu trước mốc đó (người gõ đêm, hoặc chuông được
    // đặt reo sớm hơn) thì NỚI cửa sổ về 0h — thà trục dài hơn còn hơn đặt sai chỗ một cái chấm.
    CGFloat startHour = kDayStartHour;
    for (NSDictionary *s in samples) {
        double h = ([s[@"ts"] doubleValue] - dayOrigin) / 3600.0;
        if (h < startHour) startHour = 0.0;
    }
    double spanSec = (kDayEndHour - startHour) * 3600.0;
    double originSec = dayOrigin + startHour * 3600.0;

    _axisFractions[0] = (kAxisHourMorning   - startHour) / (kDayEndHour - startHour);
    _axisFractions[1] = (kAxisHourNoon      - startHour) / (kDayEndHour - startHour);
    _axisFractions[2] = (kAxisHourAfternoon - startHour) / (kDayEndHour - startHour);
    _axisFractions[3] = (kAxisHourEvening   - startHour) / (kDayEndHour - startHour);

    NSMutableArray *entries = [NSMutableArray arrayWithCapacity:samples.count];
    NSInteger validCount = 0;
    long long prevTs = 0;
    for (NSUInteger m = 0; m < samples.count; m++) {
        long long ts = [samples[m][@"ts"] longLongValue];
        // Cách mẫu trước quá xa = quãng không gõ → chèn dấu NGẮT, nước không nối qua (dec.4).
        if (m > 0 && gapSeconds > 0 && (double)(ts - prevTs) > gapSeconds) {
            [entries addObject:[NSNull null]];
        }
        prevTs = ts;
        validCount++;
        CGFloat xf = (CGFloat)(((double)ts - originSec) / spanSec);
        xf = MAX(0.0, MIN(1.0, xf));
        // "checkin" vắng mặt (caller cũ chưa cập nhật) -> boolValue trên nil = NO an toàn, không crash.
        BOOL isCheckin = [samples[m][@"checkin"] boolValue];
        [entries addObject:MKMakeEntry(xf, [samples[m][@"value"] doubleValue], isCheckin)];
    }
    [self applyEntries:entries validCount:validCount];
}

// [MINDFUL] 2026-07-16 — zoom-in "Ngay bây giờ": cửa sổ TRƯỢT, mép phải = khoảnh khắc này.
// Xem hợp đồng đầy đủ ở EmotionRiverView.h (kể cả cảnh báo liveHead chỉ là ảnh chụp lúc mở).
- (void)setRecentSamples:(nullable NSArray<NSDictionary *> *)samples
           windowSeconds:(double)windowSeconds
              gapSeconds:(double)gapSeconds
                liveHead:(double)liveHead {
    if (windowSeconds <= 0) return;
    _timeBased = YES;

    double now = [[NSDate date] timeIntervalSince1970];
    double originSec = now - windowSeconds;

    // [MINDFUL] 2026-07-19 (chủ dự án chốt) — QUÁ KHỨ · HIỆN TẠI · TƯƠNG LAI: "bây giờ" KHÔNG còn
    // dính mép phải (nửa chấm bị khung cắt, đầu sóng hết chỗ thở). Cửa sổ dữ liệu (windowSeconds =
    // 3h quá khứ) chỉ chiếm 0..kNowFrac; phần kNowFrac..1 là "tương lai để trống" — chỉ có trục nét
    // đứt (đã vẽ suốt bề ngang ở MKRiverCanvas), TUYỆT ĐỐI không vẽ nước giả (dec.4). 3h + 1h tương
    // lai = "bây giờ" ở 3/4.
    static const CGFloat kNowFrac = 0.75;

    // Mốc tương đối, chia đều theo ĐÚNG tỉ lệ thời gian thật (không phải 4 cột đều nhau). Chốt với
    // chủ dự án 2026-07-16 — cố ý KHÔNG dùng giờ đồng hồ ("05:00 · 07:00…") vì đọc thành biểu đồ,
    // mất chất quan sát. 4 nhãn GIỮ NGUYÊN CHỮ, chỉ dời vị trí về [0, kNowFrac].
    double hrs = windowSeconds / 3600.0;
    _axisFractions[0] = 0.0;
    _axisFractions[1] = kNowFrac / 3.0;
    _axisFractions[2] = 2.0 * kNowFrac / 3.0;
    _axisFractions[3] = kNowFrac;
    [self setAxisLabels:@[
        [NSString stringWithFormat:@"%g giờ trước", hrs],
        [NSString stringWithFormat:@"%g giờ", hrs * 2.0 / 3.0],
        [NSString stringWithFormat:@"%g giờ", hrs / 3.0],
        @"bây giờ",
    ]];

    NSMutableArray *entries = [NSMutableArray array];
    NSInteger validCount = 0;
    long long prevTs = 0;
    BOOL hasPrev = NO;
    for (NSDictionary *s in samples) {
        long long ts = [s[@"ts"] longLongValue];
        if ((double)ts < originSec) continue;   // ngoài cửa sổ — bỏ, không kéo lê vào mép trái
        if (hasPrev && gapSeconds > 0 && (double)(ts - prevTs) > gapSeconds) {
            [entries addObject:[NSNull null]];  // quãng không gõ — nước KHÔNG nối qua (dec.4)
        }
        prevTs = ts;
        hasPrev = YES;
        validCount++;
        // Nén quá khứ vào [0, kNowFrac] (thay vì [0,1]) để chừa chỗ cho tương lai bên phải.
        CGFloat xf = (CGFloat)(((double)ts - originSec) / windowSeconds) * kNowFrac;
        BOOL isCheckin = [s[@"checkin"] boolValue];
        [entries addObject:MKMakeEntry(MAX(0.0, MIN(kNowFrac, xf)), [s[@"value"] doubleValue], isCheckin)];
    }

    // Đầu sóng "bây giờ" = mốc kNowFrac (KHÔNG phải mép phải). liveHead < 0 (đã im/chưa gõ) thì
    // KHÔNG cắm gì — mặt hồ phẳng lặng ở hiện tại là sự thật, hơn là giữ điểm cũ. Nếu mẫu lưu gần
    // nhất đã quá xa (nghỉ gõ lâu) thì NGẮT trước khi cắm — bịa nước nối tới bây giờ là dec.4 cấm.
    if (liveHead >= 0.0) {
        if (hasPrev && gapSeconds > 0 && (now - (double)prevTs) > gapSeconds) {
            [entries addObject:[NSNull null]];
        }
        validCount++;
        // liveHead luôn tự-đoán (MoodWatchMac_LiveAmplitude) — không phải câu tự thuật.
        [entries addObject:MKMakeEntry(kNowFrac, liveHead, NO)];
    }

    [self applyEntries:entries validCount:validCount];
}

// [MINDFUL] 2026-07-16 — xem EmotionRiverView.h. Nhúng sông vào trong 1 thẻ khác thì phải tắt
// viền/nền của chính nó, không thì thành hộp lồng hộp.
- (void)setCardChromeHidden:(BOOL)hidden {
    self.layer.backgroundColor = hidden ? [NSColor clearColor].CGColor : [NSColor whiteColor].CGColor;
    self.layer.borderWidth = hidden ? 0.0 : 1.0;
}

- (CGFloat)preferredHeight {
    if (_captionHidden)
        return kPad + kWaveAreaH + kAxisGap + kAxisH + kPad;
    return kPad + kWaveAreaH + kAxisGap + kAxisH + kCaptionGap + kCaptionH + kPad;
}

- (void)layout {
    [super layout];
    CGFloat w = NSWidth(self.bounds);
    CGFloat h = NSHeight(self.bounds);
    CGFloat top = h - kPad;

    _riverArea.frame = NSMakeRect(kPad, top - kWaveAreaH, w - 2 * kPad, kWaveAreaH);
    top -= kWaveAreaH + kAxisGap;

    CGFloat axisW = (w - 2 * kPad) / 4.0;
    if (_timeBased) {
        // Trục theo giờ thật: mỗi nhãn canh GIỮA quanh mốc giờ của buổi đó, thay vì chia đều 4
        // phần. Nếu vẫn chia đều thì nhãn lại nói dối lần nữa — chỉ khác là dối ở chỗ khác.
        NSTextField *labels[4] = {_axisMorning, _axisNoon, _axisAfternoon, _axisEvening};
        CGFloat innerW = w - 2 * kPad;
        for (int i = 0; i < 4; i++) {
            CGFloat cx = kPad + _axisFractions[i] * innerW;
            CGFloat x = cx - axisW / 2.0;
            NSTextAlignment al = NSTextAlignmentCenter;
            // [MINDFUL] 2026-07-16 — mốc nằm SÁT MÉP (cửa sổ trượt: "6 giờ trước" ở 0.0, "bây giờ"
            // ở 1.0) mà canh giữa thì nửa chữ lọt ra ngoài — và view có masksToBounds nên bị CẮT
            // cụt. Neo vào mép + đổi canh lề, đúng cách trục Sáng…Tối vẫn làm ở nhánh dưới.
            if (x < kPad) { x = kPad; al = NSTextAlignmentLeft; }
            if (x + axisW > w - kPad) { x = w - kPad - axisW; al = NSTextAlignmentRight; }
            labels[i].alignment = al;
            labels[i].frame = NSMakeRect(x, top - kAxisH, axisW, kAxisH);
        }
    } else {
        _axisMorning.frame   = NSMakeRect(kPad, top - kAxisH, axisW, kAxisH);
        _axisNoon.frame      = NSMakeRect(kPad + axisW, top - kAxisH, axisW, kAxisH);
        _axisAfternoon.frame = NSMakeRect(kPad + 2 * axisW, top - kAxisH, axisW, kAxisH);
        _axisEvening.frame   = NSMakeRect(kPad + 3 * axisW, top - kAxisH, axisW, kAxisH);
    }

    if (!_captionHidden) {
        top -= kAxisH + kCaptionGap;
        _caption.frame = NSMakeRect(kPad, top - kCaptionH, w - 2 * kPad, kCaptionH);
    }
}

@end
