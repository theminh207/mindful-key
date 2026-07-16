//
//  AppDelegate.h
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

#define OPENKEY_BUNDLE @"com.tuyenmai.openkey"

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
