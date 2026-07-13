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
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *samples;
@end

@implementation MKRiverCanvas

- (void)setSamples:(NSArray<NSNumber *> *)samples {
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
    for (CGFloat x = 0; x <= w; x += 3.0) {
        CGFloat f = (k > 1) ? (x / w) * (CGFloat)(k - 1) : 0;
        NSUInteger i = (NSUInteger)floor(f);
        CGFloat fr = f - (CGFloat)i;
        CGFloat a0 = _samples[i].doubleValue;
        CGFloat a1 = _samples[MIN(i + 1, k - 1)].doubleValue;
        CGFloat amp = a0 + (a1 - a0) * fr;
        CGFloat y = midY - amp * maxWaveH * sin(x * 0.19);
        NSPoint p = NSMakePoint(x, y);
        [points addObject:[NSValue valueWithPoint:p]];
        if (x == 0) [path moveToPoint:p]; else [path lineToPoint:p];
    }
    [teal setStroke];
    [path stroke];

    // Chấm trắng-viền-teal đúng vị trí mỗi mẫu (1 nhịp chuông = 1 điểm ghi lên dòng sông).
    for (NSUInteger m = 0; m < k; m++) {
        CGFloat mx = (k == 1) ? w / 2.0 : (CGFloat)m / (CGFloat)(k - 1) * w;
        NSUInteger idx = MIN((NSUInteger)llround(mx / 3.0), points.count - 1);
        NSPoint p = points[idx].pointValue;
        NSRect dot = NSMakeRect(p.x - 2.6, p.y - 2.6, 5.2, 5.2);
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

- (void)setSamples:(nullable NSArray<NSNumber *> *)samples {
    _samples = samples.count > 0 ? [samples copy] : nil;
    _riverArea.samples = _samples;
    _caption.stringValue = _samples
        ? @"Mỗi vòng tròn là một nhịp chuông — lúc app lặng lẽ ghi một điểm."
        : @"Hồ chưa đủ nét — ngày mới bắt đầu.";
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
