//
//  BrandControls.m
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.1 — xem BrandControls.h cho hợp đồng + ràng buộc hiến chương.
//

#import "BrandControls.h"
#import "BrandColors.h"

// Kích thước dùng chung (điểm), không hard-code rải rác.
static const CGFloat kPillWidth   = 40.0;
static const CGFloat kPillHeight  = 24.0;
static const CGFloat kPillKnobPad = 3.0;
static const CGFloat kDotSize     = 10.0;
static const CGFloat kCornerCTA   = 8.0;
static const CGFloat kFocusRing   = 2.0;   // viền focus 2px
static const CGFloat kFocusInset  = 2.0;   // offset 2px
static const CGFloat kDisabledAlpha = 0.4; // 40% opacity khi disabled

#pragma mark - PillSwitch

@implementation PillSwitch {
    BOOL _focused;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        _on = NO;
        _focused = NO;
    }
    return self;
}

- (NSSize)intrinsicContentSize { return NSMakeSize(kPillWidth, kPillHeight); }

- (BOOL)acceptsFirstResponder { return self.isEnabled; }

- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    if (_on == on) return;
    _on = on;
    // Animation nhẹ của knob để phản hồi tương tác; tôn trọng "Giảm chuyển động".
    if (animated && ![[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceMotion]) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
            ctx.duration = 0.15;
            [self.animator setNeedsDisplay:YES];
        } completionHandler:nil];
    } else {
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDown:(NSEvent *)event {
    if (!self.isEnabled) return;
    [self setOn:!_on animated:YES];
    [self sendAction:self.action to:self.target];  // click người dùng mới bắn action
}

- (void)keyDown:(NSEvent *)event {
    if (self.isEnabled && ([event.characters isEqualToString:@" "] || [event.characters isEqualToString:@"\r"])) {
        [self setOn:!_on animated:YES];
        [self sendAction:self.action to:self.target];
        return;
    }
    [super keyDown:event];
}

- (void)drawRect:(NSRect)dirtyRect {
    CGFloat alpha = self.isEnabled ? 1.0 : kDisabledAlpha;

    NSRect track = NSMakeRect(0, 0, kPillWidth, kPillHeight);
    NSBezierPath *trackPath = [NSBezierPath bezierPathWithRoundedRect:track
                                                             xRadius:kPillHeight / 2.0
                                                             yRadius:kPillHeight / 2.0];
    NSColor *trackColor = _on ? [Brand teal] : [Brand divider];
    [[trackColor colorWithAlphaComponent:alpha] setFill];
    [trackPath fill];

    CGFloat knobDiameter = kPillHeight - 2 * kPillKnobPad;
    CGFloat knobX = _on ? (kPillWidth - knobDiameter - kPillKnobPad) : kPillKnobPad;
    NSRect knob = NSMakeRect(knobX, kPillKnobPad, knobDiameter, knobDiameter);
    [[[NSColor whiteColor] colorWithAlphaComponent:alpha] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:knob] fill];

    if (_focused) {
        NSRect ring = NSInsetRect(track, -kFocusInset, -kFocusInset);
        NSBezierPath *ringPath = [NSBezierPath bezierPathWithRoundedRect:ring
                                                                xRadius:(kPillHeight / 2.0) + kFocusInset
                                                                yRadius:(kPillHeight / 2.0) + kFocusInset];
        ringPath.lineWidth = kFocusRing;
        [[Brand teal] setStroke];
        [ringPath stroke];
    }
}

- (BOOL)becomeFirstResponder { _focused = YES;  [self setNeedsDisplay:YES]; return YES; }
- (BOOL)resignFirstResponder  { _focused = NO;   [self setNeedsDisplay:YES]; return YES; }

- (void)setEnabled:(BOOL)enabled { [super setEnabled:enabled]; [self setNeedsDisplay:YES]; }

- (NSString *)accessibilityRole { return NSAccessibilityCheckBoxRole; }
- (id)accessibilityValue { return @(_on); }

@end

#pragma mark - StatusDot

@implementation StatusDot

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) { _on = NO; }
    return self;
}

- (NSSize)intrinsicContentSize { return NSMakeSize(kDotSize, kDotSize); }

- (void)setOn:(BOOL)on {
    if (_on == on) return;
    _on = on;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect r = NSInsetRect(self.bounds, 1.0, 1.0);
    // Giữ hình tròn vuông vắn ở giữa.
    CGFloat d = MIN(NSWidth(r), NSHeight(r));
    NSRect dot = NSMakeRect(NSMidX(r) - d / 2.0, NSMidY(r) - d / 2.0, d, d);
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:dot];
    if (_on) {
        [[Brand teal] setFill];
        [path fill];
    } else {
        path.lineWidth = 1.0;
        [[Brand divider] setStroke];
        [path stroke];
    }
}

@end

#pragma mark - CTAButton

@implementation CTAButton {
    BOOL _hovering;
    BOOL _pressed;
    NSTrackingArea *_tracking;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) { [self commonInit]; }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) { [self commonInit]; }
    return self;
}

- (void)commonInit {
    self.wantsLayer = YES;
    self.bordered = NO;
    self.bezelStyle = NSBezelStyleRegularSquare;
    self.layer.cornerRadius = kCornerCTA;
    self.layer.masksToBounds = YES;
    [self applyTitleColor];
}

// Chữ TỐI (charcoal) ở MỌI state — không bao giờ chữ trắng trên cam (WCAG 2.61:1).
- (void)applyTitleColor {
    NSString *text = self.title ?: @"";
    NSDictionary *attrs = @{ NSForegroundColorAttributeName : [Brand charcoal],
                             NSFontAttributeName : (self.font ?: [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold]) };
    self.attributedTitle = [[NSAttributedString alloc] initWithString:text attributes:attrs];
}

- (void)setTitle:(NSString *)title { [super setTitle:title]; [self applyTitleColor]; }

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_tracking) [self removeTrackingArea:_tracking];
    _tracking = [[NSTrackingArea alloc] initWithRect:self.bounds
                                             options:(NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited)
                                               owner:self userInfo:nil];
    [self addTrackingArea:_tracking];
}

- (void)mouseEntered:(NSEvent *)event { _hovering = YES; [self setNeedsDisplay:YES]; }
- (void)mouseExited:(NSEvent *)event  { _hovering = NO;  [self setNeedsDisplay:YES]; }

- (void)mouseDown:(NSEvent *)event {
    if (!self.isEnabled) return;
    _pressed = YES; [self setNeedsDisplay:YES];
    [super mouseDown:event];   // xử lý click + gửi action theo cơ chế NSButton
    _pressed = NO;  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    CGFloat alpha = self.isEnabled ? 1.0 : kDisabledAlpha;

    // Active: dịch xuống 1px lúc nhấn.
    NSRect body = self.bounds;
    if (_pressed) body = NSOffsetRect(body, 0, -1);

    NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:body xRadius:kCornerCTA yRadius:kCornerCTA];
    NSColor *fill = [Brand orange];
    if (_hovering) fill = [fill blendedColorWithFraction:0.10 ofColor:[NSColor blackColor]]; // hover: cam đậm nhẹ
    [[fill colorWithAlphaComponent:alpha] setFill];
    [bg fill];

    // Focus: viền teal 2px, offset 2px.
    if (self.window.firstResponder == self) {
        NSRect ring = NSInsetRect(self.bounds, -kFocusInset, -kFocusInset);
        NSBezierPath *ringPath = [NSBezierPath bezierPathWithRoundedRect:ring
                                                                xRadius:kCornerCTA + kFocusInset
                                                                yRadius:kCornerCTA + kFocusInset];
        ringPath.lineWidth = kFocusRing;
        [[Brand teal] setStroke];
        [ringPath stroke];
    }

    // Vẽ tiêu đề (chữ tối) căn giữa.
    NSAttributedString *title = self.attributedTitle;
    NSSize sz = [title size];
    NSPoint p = NSMakePoint(NSMidX(body) - sz.width / 2.0, NSMidY(body) - sz.height / 2.0);
    [title drawAtPoint:p];
}

- (BOOL)acceptsFirstResponder { return self.isEnabled; }
- (BOOL)becomeFirstResponder { [self setNeedsDisplay:YES]; return [super becomeFirstResponder]; }
- (BOOL)resignFirstResponder  { [self setNeedsDisplay:YES]; return [super resignFirstResponder]; }

@end

#pragma mark - SecondaryButton

// [MINDFUL] Story 1.9 — cùng khung vẽ tay như CTAButton (tracking area hover, mouseDown pressed,
// focus ring teal) nhưng bảng màu trung tính: nền trắng, viền divider, chữ charcoal. KHÔNG cam.
@implementation SecondaryButton {
    BOOL _hovering;
    BOOL _pressed;
    NSTrackingArea *_tracking;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) { [self commonInit]; }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) { [self commonInit]; }
    return self;
}

- (void)commonInit {
    self.wantsLayer = YES;
    self.bordered = NO;
    self.bezelStyle = NSBezelStyleRegularSquare;
    self.layer.cornerRadius = kCornerCTA;
    self.layer.masksToBounds = YES;
    [self applyTitleColor];
}

- (void)applyTitleColor {
    NSString *text = self.title ?: @"";
    NSDictionary *attrs = @{ NSForegroundColorAttributeName : [Brand charcoal],
                             NSFontAttributeName : (self.font ?: [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold]) };
    self.attributedTitle = [[NSAttributedString alloc] initWithString:text attributes:attrs];
}

- (void)setTitle:(NSString *)title { [super setTitle:title]; [self applyTitleColor]; }

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_tracking) [self removeTrackingArea:_tracking];
    _tracking = [[NSTrackingArea alloc] initWithRect:self.bounds
                                             options:(NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited)
                                               owner:self userInfo:nil];
    [self addTrackingArea:_tracking];
}

- (void)mouseEntered:(NSEvent *)event { _hovering = YES; [self setNeedsDisplay:YES]; }
- (void)mouseExited:(NSEvent *)event  { _hovering = NO;  [self setNeedsDisplay:YES]; }

- (void)mouseDown:(NSEvent *)event {
    if (!self.isEnabled) return;
    _pressed = YES; [self setNeedsDisplay:YES];
    [super mouseDown:event];   // xử lý click + gửi action theo cơ chế NSButton
    _pressed = NO;  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    CGFloat alpha = self.isEnabled ? 1.0 : kDisabledAlpha;

    // Active: dịch xuống 1px lúc nhấn (giống CTAButton).
    NSRect body = self.bounds;
    if (_pressed) body = NSOffsetRect(body, 0, -1);

    NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:body xRadius:kCornerCTA yRadius:kCornerCTA];
    NSColor *fill = [NSColor whiteColor];
    if (_hovering) fill = [fill blendedColorWithFraction:0.5 ofColor:[Brand divider]]; // hover: xám nhạt, không cam
    [[fill colorWithAlphaComponent:alpha] setFill];
    [bg fill];

    NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(body, 0.5, 0.5)
                                                             xRadius:kCornerCTA
                                                             yRadius:kCornerCTA];
    border.lineWidth = 1.0;
    [[[Brand divider] colorWithAlphaComponent:alpha] setStroke];
    [border stroke];

    // Focus: viền teal 2px, offset 2px — cùng ngôn ngữ focus với CTAButton/PillSwitch.
    if (self.window.firstResponder == self) {
        NSRect ring = NSInsetRect(self.bounds, -kFocusInset, -kFocusInset);
        NSBezierPath *ringPath = [NSBezierPath bezierPathWithRoundedRect:ring
                                                                xRadius:kCornerCTA + kFocusInset
                                                                yRadius:kCornerCTA + kFocusInset];
        ringPath.lineWidth = kFocusRing;
        [[Brand teal] setStroke];
        [ringPath stroke];
    }

    // Vẽ tiêu đề (chữ charcoal) căn giữa.
    NSAttributedString *title = self.attributedTitle;
    NSSize sz = [title size];
    NSPoint p = NSMakePoint(NSMidX(body) - sz.width / 2.0, NSMidY(body) - sz.height / 2.0);
    [title drawAtPoint:p];
}

- (BOOL)acceptsFirstResponder { return self.isEnabled; }
- (BOOL)becomeFirstResponder { [self setNeedsDisplay:YES]; return [super becomeFirstResponder]; }
- (BOOL)resignFirstResponder  { [self setNeedsDisplay:YES]; return [super resignFirstResponder]; }

@end

#pragma mark - NSView (BrandCard)

// [MINDFUL] Story 1.9 — helper dùng chung, thuần CALayer nên áp được lên bất kỳ NSView nào
// (kể cả NSBox, miễn đã tắt fill/border gốc trước — xem ConvertToolViewController.mm).
@implementation NSView (BrandCard)

- (void)applyBrandCardStyle {
    self.wantsLayer = YES;
    self.layer.cornerRadius = 16.0;
    self.layer.masksToBounds = NO;   // để bóng đổ ra ngoài viền, không bị cắt
    self.layer.backgroundColor = [NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor; // bg.card #FFFFFF

    // Bóng ngọc bích NOW BRAND OS: 0 8px 30px rgba(29,124,145,0.08).
    self.layer.shadowColor = [Brand teal].CGColor;
    self.layer.shadowOpacity = 0.08;
    self.layer.shadowRadius = 15.0;             // blur CSS 30px ~ bán kính Core Animation /2
    self.layer.shadowOffset = CGSizeMake(0, -8.0); // AppKit: trục Y hướng lên → đổ "xuống" = offset âm

    CGPathRef shadowPath = CGPathCreateWithRoundedRect(self.bounds, 16.0, 16.0, NULL);
    self.layer.shadowPath = shadowPath;
    CGPathRelease(shadowPath);
}

@end
