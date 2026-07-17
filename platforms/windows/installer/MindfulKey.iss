; MindfulKey.iss — bộ cài Windows (Inno Setup 6).
;
; Sinh ra MindfulKey_<ver>_x64-setup.exe, tương đương vai trò của scripts/build-dmg.sh bên macOS.
; CI gọi: iscc /DMyAppVersion=$(VERSION) /DSourceExe=<đường dẫn MindfulKey.exe> MindfulKey.iss
;
; Tên file thật = MindfulKey.exe (chủ dự án chốt 2026-07-17, nới lằn ranh "không đổi tên file"
; ban đầu). `TargetName` trong OpenKey.vcxproj đặt MindfulKey cho cả 4 cấu hình. Tên PROJECT/
; SOLUTION/class vẫn giữ nguyên OpenKey — chỉ tên file xuất ra đổi.
;
; GPL v3: kèm LICENSE và giữ credit Mai Vũ Tuyên (OpenKey) trong trang giới thiệu của bộ cài —
; đây là nghĩa vụ pháp lý kế thừa, không phải phép lịch sự.

#ifndef MyAppVersion
  #error Thiếu MyAppVersion — CI phải truyền /DMyAppVersion=$(VERSION) đọc từ version.env
#endif
#ifndef SourceExe
  #error Thiếu SourceExe — CI phải truyền /DSourceExe=<đường dẫn tới MindfulKey.exe>
#endif

#define MyAppName "Mindful Key"
#define MyExeName "MindfulKey.exe"

[Setup]
AppId={{7C4E2A16-9E3B-4E51-A0D7-3F1B6C2D8E94}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=The OpenKey Project
AppPublisherURL=https://github.com/theminh207/mindful-key
DefaultDirName={autopf}\Mindful Key
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\..\LICENSE
OutputDir=..\..\..\release-out
OutputBaseFilename=MindfulKey_{#MyAppVersion}_x64-setup
; Icon đúng nhận diện, sinh từ SVG nguồn qua brand/export-platform.sh (KHÔNG dùng
; win32/OpenKey/OpenKey/icon.ico — đó vẫn là icon OpenKey gốc, chưa rebrand).
SetupIconFile=..\..\..\brand\platform\windows\AppIcon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

; Bộ gõ móc bàn phím toàn hệ thống -> phải là bản 64-bit chạy trên Windows 64-bit.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
; Inno Setup 6 KHÔNG kèm sẵn tiếng Việt (bản Vietnamese.isl là của cộng đồng, không nằm trong
; bộ cài chuẩn) -> khung wizard tạm dùng tiếng Anh. Chuỗi RIÊNG của app thì Việt hoá ở [Messages]
; dưới. Chờ chủ dự án chốt có kéo Vietnamese.isl về hay không — xem docs/FRICTION-LOG.md.
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
english.WelcomeLabel2=Sắp cài [name/ver] vào máy bạn.%n%nMindful Key là bộ gõ tiếng Việt chánh niệm, xây trên engine OpenKey của Mai Vũ Tuyên (GPL v3).%n%nKhuyến nghị đóng các ứng dụng khác trước khi tiếp tục.

[Tasks]
Name: "desktopicon"; Description: "Tạo lối tắt ngoài màn hình"; GroupDescription: "Lối tắt:"

[Files]
Source: "{#SourceExe}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"
Name: "{group}\Gỡ {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyExeName}"; Description: "Mở {#MyAppName} ngay"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; App tự ghi cài đặt vào registry qua OpenKeyHelper (APP_SET_DATA) — cố ý KHÔNG xoá khi gỡ:
; người dùng cài lại thì còn nguyên gõ tắt/tuỳ chỉnh. Nhật ký cảm xúc cũng KHÔNG đụng tới ở đây
; (riêng tư mặc định: xoá dữ liệu là hành vi người dùng chủ động chọn trong app, không phải
; tác dụng phụ của việc gỡ cài đặt).
Type: dirifempty; Name: "{app}"
