//
//  EmotionWaveView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.2 — xem EmotionWaveView.h cho hợp đồng + ràng buộc hiến chương.
//

#import "EmotionWaveView.h"
#import "BrandColors.h"
#import <math.h>

// Ngưỡng trạng thái theo biên độ.
static const CGFloat kRestThreshold = 0.05;  // dưới mức này = phẳng lặng, tĩnh hoàn toàn
static const CGFloat kLowThreshold  = 0.50;  // ranh giới "gợn nhẹ" vs "gợn sóng"

// Kích thước.
static const CGFloat kCollapsedHeight = 24.0;
static const CGFloat kExpandedHeight  = 48.0;

// Animation biên độ (nằm trong khoảng 400–600ms theo hợp đồng).
static const NSTimeInterval kAnimDuration = 0.5;
static const NSTimeInterval kFrameStep    = 1.0 / 60.0;

static CGFloat Clamp01(CGFloat v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }
// Ease-in-out mượt (smoothstep).
static CGFloat EaseInOut(CGFloat t) { return t * t * (3.0 - 2.0 * t); }

@implementation EmotionWaveView {
    CGFloat _displayedAmplitude;   // giá trị đang vẽ (eased)
    CGFloat _animFrom;
    CGFloat _animTo;
    NSTimeInterval _animElapsed;
    NSTimer *_timer;               // chỉ tồn tại KHI đang animate; nghỉ = không có timer
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        _amplitude = 0;
        _displayedAmplitude = 0;
        _expanded = NO;
        self.wantsLayer = YES;
        [self setAccessibilityElement:YES];
    }
    return self;
}

- (void)dealloc { [_timer invalidate]; }

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoIntrinsicMetric, _expanded ? kExpandedHeight : kCollapsedHeight);
}

- (void)setExpanded:(BOOL)expanded {
    if (_expanded == expanded) return;
    _expanded = expanded;
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

#pragma mark - Amplitude / animation

- (void)setAmplitude:(CGFloat)amplitude { [self setAmplitude:amplitude animated:NO]; }

- (void)setAmplitude:(CGFloat)amplitude animated:(BOOL)animated {
    amplitude = Clamp01(amplitude);
    CGFloat old = _amplitude;
    _amplitude = amplitude;

    BOOL reduceMotion = [[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceMotion];
    if (!animated || reduceMotion) {
        [self stopTimer];
        _displayedAmplitude = amplitude;
        [self setNeedsDisplay:YES];
    } else {
        _animFrom = _displayedAmplitude;
        _animTo = amplitude;
        _animElapsed = 0;
        [self startTimer];
    }

    if (old != amplitude) [self announceStateChange];
}

- (void)startTimer {
    [self stopTimer];
    __weak EmotionWaveView *weakSelf = self;
    _timer = [NSTimer scheduledTimerWithTimeInterval:kFrameStep repeats:YES block:^(NSTimer *t) {
        [weakSelf tick];
    }];
}

- (void)stopTimer { [_timer invalidate]; _timer = nil; }

- (void)tick {
    _animElapsed += kFrameStep;
    CGFloat t = _animElapsed / kAnimDuration;
    if (t >= 1.0) {
        _displayedAmplitude = _animTo;
        [self stopTimer];          // tới đích → dừng timer (nghỉ = tĩnh, không loop)
    } else {
        _displayedAmplitude = _animFrom + (_animTo - _animFrom) * EaseInOut(t);
    }
    [self setNeedsDisplay:YES];
}

#pragma mark - Drawing (1 hue, biên độ điều khiển cao/tần số/độ dày)

- (void)drawRect:(NSRect)dirtyRect {
    NSRect b = self.bounds;
    CGFloat midY = NSMidY(b);
    CGFloat amp = _displayedAmplitude;

    // Màu: nội suy stone (thấp) -> teal (cao). CHỈ 1 trục hue trung tính, không cam/đỏ.
    NSColor *stone = [[Brand stone] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSColor *teal  = [[Brand teal]  colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSColor *waveColor = [stone blendedColorWithFraction:Clamp01(amp) ofColor:teal];
    [waveColor setStroke];

    // Nghỉ: đường gần thẳng, nét mảnh, tĩnh.
    CGFloat maxWaveHeight = (_expanded ? kExpandedHeight : kCollapsedHeight) * 0.35;
    CGFloat waveHeight = maxWaveHeight * amp;
    CGFloat lineWidth = 1.5 + 1.5 * amp;                 // 1.5 -> 3.0
    NSInteger cycles = 1 + (NSInteger)llround(amp * 2);  // 1 -> 3 nhịp (tần số theo biên độ)

    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = lineWidth;
    path.lineCapStyle = NSLineCapStyleRound;
    path.lineJoinStyle = NSLineJoinStyleRound;

    CGFloat width = NSWidth(b);
    CGFloat step = 2.0;
    for (CGFloat x = 0; x <= width; x += step) {
        CGFloat phase = (x / width) * (CGFloat)(cycles * 2.0 * M_PI);
        CGFloat y = midY + sin(phase) * waveHeight;
        if (x == 0) [path moveToPoint:NSMakePoint(x, y)];
        else        [path lineToPoint:NSMakePoint(x, y)];
    }
    [path stroke];
}

#pragma mark - State description + accessibility

- (NSString *)stateDescription {
    if (_amplitude < kRestThreshold) return @"Mặt hồ đang phẳng lặng";
    if (_amplitude < kLowThreshold)  return @"Mặt hồ đang gợn nhẹ";
    return @"Mặt hồ đang gợn sóng";
}

- (void)announceStateChange {
    NSString *desc = self.stateDescription;
    self.accessibilityLabel = desc;
    // Tương đương aria-live="polite": báo VoiceOver giá trị đổi mà không cướp focus.
    NSAccessibilityPostNotification(self, NSAccessibilityValueChangedNotification);
}

- (NSString *)accessibilityLabel { return self.stateDescription; }
- (NSAccessibilityRole)accessibilityRole { return NSAccessibilityStaticTextRole; }
- (id)accessibilityValue { return self.stateDescription; }

@end
