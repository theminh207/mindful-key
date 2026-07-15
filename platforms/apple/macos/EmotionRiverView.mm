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
@interface MKRiverCanvas : NSView
@property (nonatomic, copy, nullable) NSArray *samples;
@end

@implementation MKRiverCanvas

- (void)setSamples:(NSArray *)samples {
    _samples = samples;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSUInteger k = _samples.count;
    if (k == 0) return;   // trống thật — KHÔNG vẽ đường/chấm giả (HIẾN CHƯƠNG §2.2, decision-log dec.4)

    NSRect b = self.bounds;
    CGFloat midY = NSMidY(b);
    CGFloat w = NSWidth(b);
    CGFloat maxWaveH = NSHeight(b) * 0.42;

    NSColor *teal = [[Brand teal] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];

    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = 2.2;
    path.lineCapStyle = NSLineCapStyleRound;
    path.lineJoinStyle = NSLineJoinStyleRound;

    NSMutableArray<NSValue *> *points = [NSMutableArray arrayWithCapacity:(NSUInteger)(w / 3.0) + 1];
    BOOL lastWasGap = YES;
    for (CGFloat x = 0; x <= w; x += 3.0) {
        CGFloat f = (k > 1) ? (x / w) * (CGFloat)(k - 1) : 0;
        NSUInteger i = (NSUInteger)floor(f);
        CGFloat fr = f - (CGFloat)i;
        
        id val0 = _samples[i];
        id val1 = _samples[MIN(i + 1, k - 1)];
        
        if (val0 == [NSNull null] || (fr > 0 && val1 == [NSNull null])) {
            lastWasGap = YES;
            continue;
        }
        
        CGFloat a0 = [val0 doubleValue];
        CGFloat a1 = [val1 doubleValue];
        CGFloat amp = a0 + (a1 - a0) * fr;
        CGFloat y = midY - amp * maxWaveH * sin(x * 0.19);
        NSPoint p = NSMakePoint(x, y);
        [points addObject:[NSValue valueWithPoint:p]];
        
        if (lastWasGap) {
            [path moveToPoint:p];
            lastWasGap = NO;
        } else {
            [path lineToPoint:p];
        }
    }
    [teal setStroke];
    [path stroke];

    // Chấm trắng-viền-teal đúng vị trí mỗi mẫu (1 nhịp chuông = 1 điểm ghi lên dòng sông).
    for (NSUInteger m = 0; m < k; m++) {
        if (_samples[m] == [NSNull null]) continue;
        CGFloat mx = (k == 1) ? w / 2.0 : (CGFloat)m / (CGFloat)(k - 1) * w;
        
        // Find closest drawn point to mx
        NSPoint closestP = NSZeroPoint;
        CGFloat minDiff = CGFLOAT_MAX;
        for (NSValue *val in points) {
            NSPoint p = val.pointValue;
            if (fabs(p.x - mx) < minDiff) {
                minDiff = fabs(p.x - mx);
                closestP = p;
            }
        }
        
        if (minDiff > 5.0) continue; // Should not happen, but safeguard
        
        NSRect dot = NSMakeRect(closestP.x - 2.6, closestP.y - 2.6, 5.2, 5.2);
        NSBezierPath *dotPath = [NSBezierPath bezierPathWithOvalInRect:dot];
        [[NSColor whiteColor] setFill];
        [dotPath fill];
        dotPath.lineWidth = 1.6;
        [teal setStroke];
        [dotPath stroke];
    }
}

@end

#pragma mark - EmotionRiverView

@implementation EmotionRiverView {
    MKRiverCanvas *_riverArea;
    NSTextField *_axisMorning, *_axisNoon, *_axisAfternoon, *_axisEvening;
    NSTextField *_caption;
    NSArray<NSNumber *> *_samples;
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

- (void)setSamples:(nullable NSArray *)samples {
    _samples = samples.count > 0 ? [samples copy] : nil;
    _riverArea.samples = _samples;
    
    // Đếm số mẫu có dữ liệu thật (bỏ qua NSNull)
    NSInteger validCount = 0;
    if (_samples) {
        for (id val in _samples) {
            if (val != [NSNull null]) validCount++;
        }
    }
    
    // Nếu dưới 3 mẫu, coi như chưa đủ nét
    if (validCount < 3) {
        _riverArea.samples = nil;
        _caption.stringValue = @"Hồ chưa đủ nét — ngày mới bắt đầu.";
    } else {
        _caption.stringValue = @"Mỗi vòng tròn là một nhịp chuông — lúc app lặng lẽ ghi một điểm.";
    }
    self.needsLayout = YES;
}

- (CGFloat)preferredHeight {
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
    _axisMorning.frame   = NSMakeRect(kPad, top - kAxisH, axisW, kAxisH);
    _axisNoon.frame      = NSMakeRect(kPad + axisW, top - kAxisH, axisW, kAxisH);
    _axisAfternoon.frame = NSMakeRect(kPad + 2 * axisW, top - kAxisH, axisW, kAxisH);
    _axisEvening.frame   = NSMakeRect(kPad + 3 * axisW, top - kAxisH, axisW, kAxisH);
    top -= kAxisH + kCaptionGap;

    _caption.frame = NSMakeRect(kPad, top - kCaptionH, w - 2 * kPad, kCaptionH);
}

@end
