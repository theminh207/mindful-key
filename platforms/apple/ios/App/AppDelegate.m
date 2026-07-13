//
//  AppDelegate.m
//  mindful-key — iOS container app (Round 1 walking skeleton)
//
//  Điều phối 3 màn onboarding tuyến tính (Kích hoạt → Full Access → Home) — root là
//  UINavigationController KHÔNG tab bar (onboarding chỉ tiến/lùi, EXPERIENCE.md §IA). Chọn màn
//  khởi đầu + tự chuyển Màn 01→02 dựa trên App Group heartbeat (story 1.6, AppGroupBridge).
//

#import "AppDelegate.h"
#import "ActivationViewController.h"
#import "FullAccessViewController.h"
#import "HomeViewController.h"
#import "AppGroupBridge.h"

@interface AppDelegate ()
@property (nonatomic, strong) UINavigationController *nav;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    UIViewController *root;
    if (ContainerApp_ReadKeyboardStatus() == AppGroupKeyboardStatusNeverRan) {
        root = [self mk_makeActivation];             // lần đầu chưa gõ → Màn 01
    } else {
        root = [self mk_makeHome];                   // heartbeat đã báo từng chạy → thẳng Home
    }

    self.nav = [[UINavigationController alloc] initWithRootViewController:root];
    self.nav.navigationBarHidden = YES;              // onboarding dùng header nhận diện riêng
    self.window.rootViewController = self.nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Quay lại app sau khi bật bàn phím trong Cài đặt: nếu đang ở Màn 01 và heartbeat vừa đổi
    // sang "đã chạy" → tự chuyển Màn 02 (không toast ăn mừng — né gamification).
    if ([self.nav.topViewController isKindOfClass:[ActivationViewController class]] &&
        ContainerApp_ReadKeyboardStatus() != AppGroupKeyboardStatusNeverRan) {
        [self.nav pushViewController:[self mk_makeFullAccess] animated:YES];
    }
}

#pragma mark - Dựng màn + nối điều hướng

- (UIViewController *)mk_makeActivation {
    ActivationViewController *vc = [[ActivationViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    // Lối tiến thủ công (chỉ hiện sau khi rời-về Cài đặt mà heartbeat không nhảy) → sang Màn 02,
    // đúng đích như nhánh heartbeat tự động. Tránh kẹt vĩnh viễn nếu App Group hụt.
    vc.onContinueAnyway = ^{
        if ([weakSelf.nav.topViewController isKindOfClass:[ActivationViewController class]]) {
            [weakSelf.nav pushViewController:[weakSelf mk_makeFullAccess] animated:YES];
        }
    };
    return vc;
}

- (UIViewController *)mk_makeFullAccess {
    FullAccessViewController *vc = [[FullAccessViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    vc.onFinish = ^{
        // Cả "Bật" lẫn "Để sau" đều tới Home; thay cả stack để không vuốt lùi về onboarding.
        [weakSelf.nav setViewControllers:@[[weakSelf mk_makeHome]] animated:YES];
    };
    return vc;
}

- (UIViewController *)mk_makeHome {
    HomeViewController *vc = [[HomeViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    vc.onReturnToActivation = ^{
        [weakSelf.nav setViewControllers:@[[weakSelf mk_makeActivation]] animated:YES];
    };
    return vc;
}

@end
