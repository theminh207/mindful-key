//
//  ConvertToolViewController.mm
//  OpenKey
//
//  Created by Tuyen on 9/4/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import "AppDelegate.h"
#import "ConvertToolViewController.h"
#import "OpenKeyManager.h"
#import "ConvertTool.h"

extern AppDelegate* appDelegate;

@interface ConvertToolViewController ()

@end

@implementation ConvertToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.SHotKey.Parent = self;
    [self fillData];
    [self applyBrandCardStyleToOptionBoxes];
}

// [MINDFUL] Story 1.9 — bọc 2 nhóm checkbox ("Tùy chọn chung"/"Lựa chọn") vào card NOW BRAND OS
// (bo góc 16px + bóng ngọc bích, xem BrandControls.h). `transparent = YES` tắt cả fill/viền LẪN
// title vẽ sẵn của NSBox (xác nhận bằng build thật) — nên phải tự vẽ lại tiêu đề bằng 1 NSTextField
// riêng, xem -addSectionHeader:toBox:contentTop:.
-(void)applyBrandCardStyleToOptionBoxes {
    NSString *commonTitle = self.CommonOptionsBox.title;
    NSString *selectionTitle = self.SelectionBox.title;
    for (NSBox *box in @[self.CommonOptionsBox, self.SelectionBox]) {
        box.boxType = NSBoxCustom;
        box.transparent = YES;   // tắt fill/viền gốc (thay borderType — deprecated trên NSBoxCustom)
        [box applyBrandCardStyle];
    }
    // contentTop = mép trên cùng của hàng cao nhất trong mỗi box, SAU KHI đã dời các hàng
    // checkbox xuống 1 chút để nhường chỗ cho header (xem các rect vừa sửa trong storyboard —
    // box1: 6 hàng dời xuống 15pt, hàng cao nhất còn lại top=92; box2: chỉ dời riêng hàng
    // "Chuyển mã trong Clipboard" xuống 6pt, top=134 — KHÔNG đụng 4 nút ⇧⌃⌥⌘/ô bắt phím tắt).
    [self addSectionHeader:commonTitle toBox:self.CommonOptionsBox contentTop:92.0];
    [self addSectionHeader:selectionTitle toBox:self.SelectionBox contentTop:134.0];
}

// `transparent = YES` tắt cả fill/viền LẪN title vẽ sẵn của NSBox (xác nhận bằng build thật) —
// nên phải tự vẽ lại tiêu đề. Neo header THEO NỘI DUNG bên dưới (contentTop), không theo mép
// trên của box — 2 lần thử trước (neo theo mép trên, rồi gap 6pt/font 13) đều bị đè lên hàng
// checkbox đầu tiên khi build thật (dấu tiếng Việt cần nhiều khoảng hở hơn ước lượng ban đầu).
- (void)addSectionHeader:(NSString *)title toBox:(NSBox *)box contentTop:(CGFloat)contentTop {
    const CGFloat gapAboveContent = 10.0;
    const CGFloat headerHeight = 13.0;
    NSTextField *header = [NSTextField labelWithString:title];
    header.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
    header.textColor = [NSColor labelColor];
    header.frame = NSMakeRect(9, contentTop + gapAboveContent, NSWidth(box.bounds) - 18, headerHeight);
    [box addSubview:header];
}

-(void)fillData {
    NSArray* codeData = [OpenKeyManager getTableCodes];
    [self.FromCode removeAllItems];
    [self.FromCode addItemsWithTitles:codeData];
    [self.ToCode removeAllItems];
    [self.ToCode addItemsWithTitles:codeData];
    
    [self.AlertWhenComplete setOn:!convertToolDontAlertWhenCompleted animated:NO];

    [self.ToAllCaps setOn:convertToolToAllCaps animated:NO];
    [self.ToNonCaps setOn:convertToolToAllNonCaps animated:NO];
    [self.ToCapsFirstLetter setOn:convertToolToCapsFirstLetter animated:NO];
    [self.ToCapsCharEachWord setOn:convertToolToCapsEachWord animated:NO];

    [self.ToRemoveSign setOn:convertToolRemoveMark animated:NO];
    
    [self.FromCode selectItemAtIndex:convertToolFromCode];
    [self.ToCode selectItemAtIndex:convertToolToCode];
    
    [self.SControl setOn:(convertToolHotKey & 0x100) != 0 animated:NO];
    [self.SOption setOn:(convertToolHotKey & 0x200) != 0 animated:NO];
    [self.SCommand setOn:(convertToolHotKey & 0x400) != 0 animated:NO];
    [self.SShift setOn:(convertToolHotKey & 0x800) != 0 animated:NO];
    [self.SHotKey setTextByChar:((convertToolHotKey>>24) & 0xFF)];
}

-(void)turnOffAllOption {
    convertToolToAllCaps = false;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolToAllCaps forKey:@"convertToolToAllCaps"];
    convertToolToAllNonCaps = false;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolToAllNonCaps forKey:@"convertToolToAllNonCaps"];
    convertToolToCapsFirstLetter = false;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolToCapsFirstLetter forKey:@"convertToolToCapsFirstLetter"];
    convertToolToCapsEachWord = false;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolToCapsEachWord forKey:@"convertToolToCapsEachWord"];
}

- (IBAction)onAlertWhenCompleted:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"convertToolDontAlertWhenCompleted"];
    convertToolDontAlertWhenCompleted = (int)!val;
}

- (IBAction)onToAllCaps:(PillSwitch *)sender {
    [self turnOffAllOption];
    NSInteger val = [self setCustomValue:sender keyToSet:@"convertToolToAllCaps"];
    convertToolToAllCaps = (int)val;
    [self fillData];
}

- (IBAction)onToNonCaps:(PillSwitch *)sender {
    [self turnOffAllOption];
    NSInteger val = [self setCustomValue:sender keyToSet:@"convertToolToAllNonCaps"];
    convertToolToAllNonCaps = (int)val;
    [self fillData];
}

- (IBAction)onToCapsFirstLetter:(PillSwitch *)sender {
    [self turnOffAllOption];
    NSInteger val = [self setCustomValue:sender keyToSet:@"convertToolToCapsFirstLetter"];
    convertToolToCapsFirstLetter = (int)val;
    [self fillData];
}

- (IBAction)onToCapsCharEachWord:(PillSwitch *)sender {
    [self turnOffAllOption];
    NSInteger val = [self setCustomValue:sender keyToSet:@"convertToolToCapsEachWord"];
    convertToolToCapsEachWord = (int)val;
    [self fillData];
}

- (IBAction)onToRemoveSign:(PillSwitch *)sender {
    NSInteger val = [self setCustomValue:sender keyToSet:@"convertToolRemoveMark"];
    convertToolRemoveMark = (int)val;
}

- (IBAction)onFromCodeSelected:(NSPopUpButton *)sender {
    convertToolFromCode = [self.FromCode indexOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolFromCode forKey:@"convertToolFromCode"];
}

- (IBAction)onToCodeSelected:(NSPopUpButton *)sender {
    convertToolToCode = [self.ToCode indexOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolToCode forKey:@"convertToolToCode"];
}

- (NSInteger)setCustomValue:(PillSwitch*)sender keyToSet:(NSString*) key {
    NSInteger val = 0;
    if (sender.isOn) {
        val = 1;
    } else {
        val = 0;
    }
    if (key != nil)
        [[NSUserDefaults standardUserDefaults] setInteger:val forKey:key];
    return val;
}

- (IBAction)onReverseCode:(id)sender {
    NSInteger code = [self.ToCode indexOfSelectedItem];
    [self.ToCode selectItemAtIndex:[self.FromCode indexOfSelectedItem]];
    [self.FromCode selectItemAtIndex:code];
    convertToolFromCode = [self.FromCode indexOfSelectedItem];
    convertToolToCode = [self.ToCode indexOfSelectedItem];
}

- (IBAction)onSControl:(PillSwitch *)sender {
    NSInteger val = sender.isOn ? 1 : 0;
    convertToolHotKey &= (~0x100);
    convertToolHotKey |= val << 8;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolHotKey forKey:@"convertToolHotKey"];
    [appDelegate setQuickConvertString];
}

- (IBAction)onSOption:(PillSwitch *)sender {
    NSInteger val = sender.isOn ? 1 : 0;
    convertToolHotKey &= (~0x200);
    convertToolHotKey |= val << 9;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolHotKey forKey:@"convertToolHotKey"];
    [appDelegate setQuickConvertString];
}

- (IBAction)onSCommand:(PillSwitch *)sender {
    NSInteger val = sender.isOn ? 1 : 0;
    convertToolHotKey &= (~0x400);
    convertToolHotKey |= val << 10;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolHotKey forKey:@"convertToolHotKey"];
    [appDelegate setQuickConvertString];
}

- (IBAction)onSShift:(PillSwitch *)sender {
    NSInteger val = sender.isOn ? 1 : 0;
    convertToolHotKey &= (~0x800);
    convertToolHotKey |= val << 11;
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolHotKey forKey:@"convertToolHotKey"];
    [appDelegate setQuickConvertString];
}

-(void)onMyTextFieldKeyChange:(unsigned short)keyCode character:(unsigned short)character {
    convertToolHotKey &= 0xFFFFFF00;
    convertToolHotKey |= keyCode;
    convertToolHotKey &= 0x00FFFFFF;
    convertToolHotKey |= ((unsigned int)character<<24);
    [[NSUserDefaults standardUserDefaults] setInteger:convertToolHotKey forKey:@"convertToolHotKey"];
    [appDelegate setQuickConvertString];
}

- (IBAction)onConvertButton:(id)sender {
    if ([OpenKeyManager quickConvert]) {
        if (!convertToolDontAlertWhenCompleted) {
            [OpenKeyManager showMessage: self.view.window message:@"Chuyển mã thành công!" subMsg:@"Kết quả đã được lưu trong clipboard."];
        }
    } else {
        [OpenKeyManager showMessage: self.view.window message:@"Không có dữ liệu trong clipboard!" subMsg:@"Hãy sao chép một đoạn text để chuyển đổi!"];
    }
}

- (IBAction)onOKButton:(id)sender {
    [self.view.window close];
}


@end
