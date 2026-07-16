//
//  PrivacyPaneView.mm
//  Mindful Keyboard — based on OpenKey
//

#import "PrivacyPaneView.h"
#import "BrandControls.h"
#import "BrandColors.h"
#import "MoodStoreMac.h"

// Layout (tương tự BellSettingsView)
static const CGFloat kEbH        = 13.0;
static const CGFloat kEbGap      = 8.0;
static const CGFloat kSectionGap = 16.0;
static const CGFloat kCardPadX   = 14.0;
static const CGFloat kCardPadY   = 13.0;
static const CGFloat kRowH       = 20.0;
static const CGFloat kGapSm      = 9.0;
static const CGFloat kNoteH      = 32.0;
static const CGFloat kSwitchH    = 24.0;
static const CGFloat kBtnH       = 32.0;

@implementation PrivacyPaneView {
    // 1. Bật/tắt
    NSTextField *_ebToggle;
    NSView      *_cardToggle;
    NSTextField *_lblToggle;
    PillSwitch  *_switchToggle;
    NSTextField *_noteToggle;

    // 2. Xuất CSV
    NSTextField *_ebExport;
    NSView      *_cardExport;
    NSTextField *_lblExport;
    SecondaryButton *_btnExport;
    NSTextField *_noteExport;

    // 3. Tự xóa định kỳ
    NSTextField *_ebPurge;
    NSView      *_cardPurge;
    NSTextField *_lblPurge;
    NSPopUpButton *_popPurge;
    NSTextField *_notePurge;

    // 4. Xóa toàn bộ
    NSTextField *_ebDelete;
    NSView      *_cardDelete;
    NSTextField *_lblDelete;
    SecondaryButton *_btnDelete;
    NSTextField *_noteDelete;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.wantsLayer = YES;

        [self buildToggleSection];
        [self buildExportSection];
        [self buildPurgeSection];
        [self buildDeleteSection];

        [self refresh];
        MoodStoreMac_RunAutoPurgeIfNeeded(); // Đạt MVP: kiểm tra và tự xóa 1 lần khi mở pane
    }
    return self;
}

#pragma mark - Helpers

- (NSTextField *)label:(NSString *)s font:(NSFont *)f color:(NSColor *)c {
    NSTextField *l = [NSTextField labelWithString:s];
    l.font = f;
    l.textColor = c;
    l.backgroundColor = [NSColor clearColor];
    l.bordered = NO;
    l.editable = NO;
    [self addSubview:l];
    return l;
}

- (NSFont *)fFieldLbl { return [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold]; }
- (NSFont *)fCaption  { return [NSFont systemFontOfSize:11.5 weight:NSFontWeightRegular]; }

- (NSView *)addCard {
    NSView *v = [[NSView alloc] initWithFrame:NSZeroRect];
    [v applyThinCardStyle];
    [self addSubview:v];
    return v;
}

#pragma mark - Build subviews

- (void)buildToggleSection {
    _ebToggle = [NSTextField mk_eyebrowLabelWithTitle:@"Nhật ký cảm xúc"];
    [self addSubview:_ebToggle];
    _cardToggle = [self addCard];

    _lblToggle = [self label:@"Lưu điểm gợn cục bộ" font:[self fFieldLbl] color:[Brand charcoal]];
    
    _switchToggle = [[PillSwitch alloc] initWithFrame:NSZeroRect];
    _switchToggle.target = self;
    _switchToggle.action = @selector(onToggle:);
    [self addSubview:_switchToggle];

    _noteToggle = [self label:@"Ghi lại số đo cảm xúc vào đĩa máy tính (mã hóa). Tắt sẽ lập tức XÓA SẠCH mọi dữ liệu đã lưu."
                         font:[self fCaption] color:[Brand muted]];
    _noteToggle.lineBreakMode = NSLineBreakByWordWrapping;
    _noteToggle.maximumNumberOfLines = 3;
}

- (void)buildExportSection {
    _ebExport = [NSTextField mk_eyebrowLabelWithTitle:@"Cầm trịch dữ liệu"];
    [self addSubview:_ebExport];
    _cardExport = [self addCard];

    _lblExport = [self label:@"Dữ liệu là của bạn, vẫn nằm trên máy bạn." font:[self fCaption] color:[Brand muted]];
    _lblExport.lineBreakMode = NSLineBreakByWordWrapping;
    
    _btnExport = [[SecondaryButton alloc] initWithFrame:NSZeroRect];
    _btnExport.title = @"Xuất CSV...";
    _btnExport.target = self;
    _btnExport.action = @selector(onExport:);
    [self addSubview:_btnExport];
    
    _noteExport = [self label:@"Bản sao (không chứa chữ gõ) được lưu ra ngoài thư mục an toàn của app để bạn tự giữ."
                         font:[self fCaption] color:[Brand muted]];
    _noteExport.lineBreakMode = NSLineBreakByWordWrapping;
    _noteExport.maximumNumberOfLines = 3;
}

- (void)buildPurgeSection {
    _ebPurge = [NSTextField mk_eyebrowLabelWithTitle:@"Tự động dọn dẹp"];
    [self addSubview:_ebPurge];
    _cardPurge = [self addCard];

    _lblPurge = [self label:@"Tự xóa nhật ký cũ hơn" font:[self fFieldLbl] color:[Brand charcoal]];
    
    _popPurge = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    NSMenu *menu = [[NSMenu alloc] init];
    [self addMenuItem:menu title:@"30 ngày" tag:30];
    [self addMenuItem:menu title:@"60 ngày" tag:60];
    [self addMenuItem:menu title:@"90 ngày" tag:90];
    [self addMenuItem:menu title:@"Không bao giờ" tag:0];
    _popPurge.menu = menu;
    _popPurge.target = self;
    _popPurge.action = @selector(onPurgeChange:);
    [self addSubview:_popPurge];

    // [MINDFUL] 2026-07-16 — câu này PHẢI nói rõ ô ghi được chừa ra, vì auto-purge nay bỏ qua dòng
    // 'note' (MoodStoreMac_RunAutoPurgeIfNeeded). Không nói = app hứa xoá mà giữ lại, tệ hơn hẳn
    // chiều ngược lại: người dùng tưởng chữ mình viết đã tự bay, thật ra vẫn nằm trên đĩa.
    _notePurge = [self label:@"Quên có chủ đích — các số đo cũ sẽ tự biến mất để tâm trí nhẹ nhàng hơn. Riêng chữ bạn viết trong ô ghi thì được giữ lại; xoá bằng nút bên dưới."
                        font:[self fCaption] color:[Brand muted]];
    _notePurge.lineBreakMode = NSLineBreakByWordWrapping;
    _notePurge.maximumNumberOfLines = 2;   // đo thật: câu mới cao 28.0pt @11.5pt/572pt = 2 dòng, vừa kNoteH(32)
}

- (void)addMenuItem:(NSMenu *)menu title:(NSString *)title tag:(NSInteger)tag {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    item.tag = tag;
    [menu addItem:item];
}

- (void)buildDeleteSection {
    _ebDelete = [NSTextField mk_eyebrowLabelWithTitle:@"Xóa bỏ"];
    [self addSubview:_ebDelete];
    _cardDelete = [self addCard];

    _lblDelete = [self label:@"Bắt đầu lại từ một trang trắng." font:[self fCaption] color:[Brand muted]];
    
    _btnDelete = [[SecondaryButton alloc] initWithFrame:NSZeroRect];
    _btnDelete.title = @"Xóa toàn bộ nhật ký";
    _btnDelete.target = self;
    _btnDelete.action = @selector(onDeleteAll:);
    [self addSubview:_btnDelete];
    
    _noteDelete = [self label:@"Nhật ký hiện tại trên máy tính này sẽ bị xóa khỏi đĩa vĩnh viễn."
                         font:[self fCaption] color:[Brand muted]];
    _noteDelete.lineBreakMode = NSLineBreakByWordWrapping;
    _noteDelete.maximumNumberOfLines = 2;
}

#pragma mark - State

- (void)refresh {
    [_switchToggle setOn:MoodStoreMac_HasConsent() animated:NO];
    NSInteger days = MoodStoreMac_AutoPurgeDays();
    [_popPurge selectItemWithTag:days];
}

#pragma mark - Actions

- (void)onToggle:(PillSwitch *)sender {
    BOOL on = sender.isOn;
    MoodStoreMac_SetConsent(on);
    if (!on) {
        // Applegate xóa là tự động xóa mọi dữ liệu
        MoodStoreMac_DeleteAll();
    }
}

- (void)onExport:(SecondaryButton *)sender {
    if (!MoodStoreMac_HasConsent()) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Nhật ký đang tắt";
        alert.informativeText = @"Bạn chưa bật ghi nhật ký hoặc không có dữ liệu để xuất.";
        [alert addButtonWithTitle:@"Đóng"];
        alert.window.level = NSStatusWindowLevel;
        [alert runModal];
        return;
    }
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.title = @"Xuất nhật ký cảm xúc";
    panel.allowedFileTypes = @[@"csv"];
    panel.nameFieldStringValue = @"mindful_keyboard_export.csv";
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK && panel.URL != nil) {
            BOOL success = MoodStoreMac_ExportCSVToURL(panel.URL);
            NSAlert *alert = [[NSAlert alloc] init];
            if (success) {
                alert.messageText = @"Xuất thành công";
                alert.informativeText = @"Nhật ký của bạn đã được ghi ra tệp CSV.";
            } else {
                alert.messageText = @"Lỗi khi xuất";
                alert.informativeText = @"Không thể lưu tệp CSV lúc này.";
            }
            [alert addButtonWithTitle:@"Đóng"];
            alert.window.level = NSStatusWindowLevel;
            [alert runModal];
        }
    }];
}

- (void)onPurgeChange:(NSPopUpButton *)sender {
    NSInteger days = sender.selectedTag;
    MoodStoreMac_SetAutoPurgeDays(days);
    MoodStoreMac_RunAutoPurgeIfNeeded();
}

- (void)onDeleteAll:(SecondaryButton *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Xóa toàn bộ nhật ký?";
    alert.informativeText = @"Hành động này không thể hoàn tác. Mọi điểm lấy mẫu, sự kiện gác cổng và ghi chú cảm xúc đã lưu trên máy tính này sẽ bị xóa khỏi đĩa vĩnh viễn.";
    [alert addButtonWithTitle:@"Hủy"];
    [alert addButtonWithTitle:@"Xóa"];
    alert.window.level = NSStatusWindowLevel;

    NSModalResponse res = [alert runModal];
    if (res == NSAlertSecondButtonReturn) {
        MoodStoreMac_DeleteAll();
        
        NSAlert *done = [[NSAlert alloc] init];
        done.messageText = @"Đã xóa";
        done.informativeText = @"Mọi dữ liệu trên máy tính này đã được làm sạch.";
        [done addButtonWithTitle:@"Đóng"];
        done.window.level = NSStatusWindowLevel;
        [done runModal];
    }
}

#pragma mark - Layout

- (CGFloat)preferredHeight { return [self relayout:NO]; }

- (void)layout {
    [super layout];
    [self relayout:YES];
}

- (CGFloat)relayout:(BOOL)apply {
    CGFloat W = NSWidth(self.bounds);
    CGFloat H = NSHeight(self.bounds);
    CGFloat top = 0;

#define SET(v, x, t, w, h) if (apply && (v)) { (v).frame = NSMakeRect((x), H - (t) - (h), (w), (h)); }

    // 1. Bật/tắt
    SET(_ebToggle, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat toggleTop = top;
    CGFloat cy = kCardPadY;

    SET(_lblToggle, kCardPadX, toggleTop + cy, W - 2 * kCardPadX - 60.0, kRowH);
    if (apply) {
        _switchToggle.frame = NSMakeRect(W - kCardPadX - 40.0, H - (toggleTop + cy) - kRowH + (kRowH - kSwitchH) / 2.0, 40.0, kSwitchH);
    }
    cy += kRowH + kGapSm;
    SET(_noteToggle, kCardPadX, toggleTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardToggle, 0, toggleTop, W, cy);
    top = toggleTop + cy + kSectionGap;

    // 2. Xuất CSV
    SET(_ebExport, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat exportTop = top;
    cy = kCardPadY;

    SET(_lblExport, kCardPadX, exportTop + cy, W - 2 * kCardPadX, kRowH);
    cy += kRowH + kGapSm;
    SET(_btnExport, kCardPadX, exportTop + cy, 120.0, kBtnH);
    cy += kBtnH + kGapSm;
    SET(_noteExport, kCardPadX, exportTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardExport, 0, exportTop, W, cy);
    top = exportTop + cy + kSectionGap;

    // 3. Tự xóa định kỳ
    SET(_ebPurge, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat purgeTop = top;
    cy = kCardPadY;

    SET(_lblPurge, kCardPadX, purgeTop + cy, 140.0, kRowH);
    SET(_popPurge, kCardPadX + 140.0 + 10.0, purgeTop + cy - 2.0, 150.0, 24.0);
    cy += kRowH + kGapSm;
    SET(_notePurge, kCardPadX, purgeTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardPurge, 0, purgeTop, W, cy);
    top = purgeTop + cy + kSectionGap;

    // 4. Xóa toàn bộ
    SET(_ebDelete, 0, top, W, kEbH);
    top += kEbH + kEbGap;
    CGFloat deleteTop = top;
    cy = kCardPadY;

    SET(_lblDelete, kCardPadX, deleteTop + cy, W - 2 * kCardPadX, kRowH);
    cy += kRowH + kGapSm;
    SET(_btnDelete, kCardPadX, deleteTop + cy, 160.0, kBtnH);
    cy += kBtnH + kGapSm;
    SET(_noteDelete, kCardPadX, deleteTop + cy, W - 2 * kCardPadX, kNoteH);
    cy += kNoteH + kCardPadY;
    SET(_cardDelete, 0, deleteTop, W, cy);
    top = deleteTop + cy;

#undef SET
    return top;
}

@end
