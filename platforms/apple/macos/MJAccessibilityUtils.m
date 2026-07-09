//
//  MJAccessibilityUtils.m
//  OpenKey
//
//  Created by Nguyen Tan Thong on 18/9/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//
//  Source: https://github.com/Hammerspoon/hammerspoon/blob/master/Hammerspoon/MJAccessibilityUtils.m
//  License: MIT


#import "MJAccessibilityUtils.h"
#import <Cocoa/Cocoa.h>
#import <IOKit/hidsystem/IOHIDLib.h>
// #import "HSLogger.h"

extern Boolean AXAPIEnabled(void);
extern Boolean AXIsProcessTrustedWithOptions(CFDictionaryRef options) __attribute__((weak_import));
extern CFStringRef kAXTrustedCheckOptionPrompt __attribute__((weak_import));


BOOL MJAccessibilityIsEnabled(void) {
    BOOL isEnabled = NO;
    if (AXIsProcessTrustedWithOptions != NULL)
        isEnabled = AXIsProcessTrustedWithOptions(NULL);
    else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        isEnabled = AXAPIEnabled();
#pragma clang diagnostic pop

//    HSNSLOG(@"Accessibility is: %@", isEnabled ? @"ENABLED" : @"DISABLED");
    return isEnabled;
}

void MJAccessibilityOpenPanel(void) {
    if (AXIsProcessTrustedWithOptions != NULL) {
        AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{(__bridge id)kAXTrustedCheckOptionPrompt: @YES});
    }
    else {
        static NSString* script = @"tell application \"System Preferences\"\nactivate\nset current pane to pane \"com.apple.preference.universalaccess\"\nend tell";
        [[[NSAppleScript alloc] initWithSource:script] executeAndReturnError:nil];
    }
}

// [MINDFUL] Input Monitoring (kTCCServiceListenEvent) — gate riêng từ macOS 10.15, ÁP DỤNG
// NGOÀI Accessibility cho việc nghe sự kiện bàn phím toàn cục qua CGEventTap. Không có API
// tương đương AXIsProcessTrustedWithOptions với prompt=YES; phải gọi IOHIDRequestAccess riêng.
BOOL MJInputMonitoringIsEnabled(void) {
    if (@available(macOS 10.15, *)) {
        return IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted;
    }
    return YES; // macOS cũ hơn không có gate này
}

void MJInputMonitoringRequestAccess(void) {
    if (@available(macOS 10.15, *)) {
        // Idempotent: nếu đã cấp/từ chối trước đó, gọi lại không hiện popup nữa — chỉ hiện
        // đúng 1 lần đầu tiên app cần quyền này (đúng hành vi TCC chuẩn của Apple).
        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent);
    }
}

void MJInputMonitoringOpenPanel(void) {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"];
    if (url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}
