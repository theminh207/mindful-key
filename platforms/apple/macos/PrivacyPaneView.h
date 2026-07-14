#import <Cocoa/Cocoa.h>

@interface PrivacyPaneView : NSView

@property (nonatomic, copy, nullable) void (^onLayoutChanged)(void);
- (CGFloat)preferredHeight;
- (void)refresh;

@end
