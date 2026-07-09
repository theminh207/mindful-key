//
//  MJAccessibilityUtils.h
//  OpenKey
//
//  Created by Nguyen Tan Thong on 18/9/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//
//  Source: https://github.com/Hammerspoon/hammerspoon/blob/master/Hammerspoon/MJAccessibilityUtils.h
//  License: MIT

#ifndef MJAccessibilityUtils_h

#import <Foundation/Foundation.h>

BOOL MJAccessibilityIsEnabled(void);
void MJAccessibilityOpenPanel(void);

// [MINDFUL] macOS 10.15+ gate riêng cho việc nghe sự kiện HID toàn cục (CGEventTap) —
// TÁCH BIỆT với Accessibility ở trên, cả 2 đều phải được cấp quyền thì bộ gõ mới bắt phím được.
// Xem docs/PRD.md (onboarding) + skill platform-porting.
BOOL MJInputMonitoringIsEnabled(void);
void MJInputMonitoringRequestAccess(void); // kích hoạt popup xin quyền lần đầu (idempotent)
void MJInputMonitoringOpenPanel(void);     // mở thẳng System Settings > Privacy & Security > Input Monitoring

#define MJAccessibilityUtils_h


#endif /* MJAccessibilityUtils_h */
