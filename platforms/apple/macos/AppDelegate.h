//
//  AppDelegate.h
//  ModernKey
//
//  Created by TheMinh
//  Copyright © TheMinh Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

// Base64 decoded "com.tuyenmai.openkey" for legacy detection
#define OPENKEY_BUNDLE [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"Y29tLnR1eWVubWFpLm9wZW5rZXk=" options:0] encoding:NSUTF8StringEncoding]

@interface AppDelegate : NSObject <NSApplicationDelegate>

-(void)onImputMethodChanged:(BOOL)willNotify;
-(void)onInputMethodSelected;

-(void)askPermission;

-(void)onInputTypeSelectedIndex:(int)index;
-(void)onCodeTableChanged:(int)index;

-(void)setRunOnStartup:(BOOL)val;
-(BOOL)isRunOnStartup;
-(void)loadDefaultConfig;

-(void)setGrayIcon:(BOOL)val;

-(void)onMacroSelected;
-(void)onQuickConvert;
-(void)setQuickConvertString;

-(void)onMoodWatchSelected;
-(void)onGatekeeperToggleSelected;
-(void)onShowCheckinOnRiverToggleSelected;
-(void)onBellSettingsSelected;
-(void)onDeleteMoodLogSelected;
-(void)onSnoozeBellSelected;
-(void)onShowReflectionSelected;

-(void)showIconOnDock:(BOOL)val;

// [MINDFUL] Batch "Hệ thống + Chuông" — pane "Hệ thống" (SystemSettingsView) cần đọc/ghi trạng thái
// THẬT của NSStatusItem đã có sẵn (statusItem, ivar riêng của AppDelegate.m) — không tạo status
// item mới, chỉ ẩn/hiện cái đang chạy.
-(BOOL)isStatusItemVisible;
-(void)setStatusItemVisible:(BOOL)val;
@end
