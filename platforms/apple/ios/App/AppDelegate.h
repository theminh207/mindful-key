//
//  AppDelegate.h
//  mindful-key — iOS container app (Round 1 walking skeleton)
//
//  Cố ý KHÔNG dùng UIScene (không có UIApplicationSceneManifest trong Info.plist) — app
//  đơn giản, tự quản lý UIWindow qua AppDelegate cổ điển, giống mức độ tối giản mà macOS
//  đang làm (main.m + AppDelegate, không storyboard scene phức tạp).

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
