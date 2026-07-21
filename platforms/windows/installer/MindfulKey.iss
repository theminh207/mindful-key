; MindfulKey.iss — bộ cài Windows (Inno Setup 6).
;
; Sinh ra MindfulKey_<ver>_x64-setup.exe, tương đương vai trò của scripts/build-dmg.sh bên macOS.
; CI gọi: iscc /DMyAppVersion=$(VERSION) /DSourceExe=<đường dẫn MindfulKey.exe> MindfulKey.iss
;
; Tên file thật = MindfulKey.exe (chủ dự án chốt 2026-07-17, nới lằn ranh "không đổi tên file"
; ban đầu). `TargetName` trong MindfulKey.vcxproj đặt MindfulKey cho cả 4 cấu hình. Tên PROJECT/
; SOLUTION/class vẫn giữ nguyên MindfulKey — chỉ tên file xuất ra đổi.
;
; GPL v3: kèm LICENSE và giữ credit Mai Vũ Tuyên (MindfulKey) trong trang giới thiệu của bộ cài —
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
AppPublisher=The MindfulKey Project
AppPublisherURL=https://github.com/theminh207/mindful-key
DefaultDirName={autopf}\Mindful Key
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\..\LICENSE
OutputDir=..\..\..\release-out
OutputBaseFilename=MindfulKey_{#MyAppVersion}_x64-setup
; Icon đúng nhận diện, sinh từ SVG nguồn qua brand/export-platform.sh (KHÔNG dùng
; win32/MindfulKey/MindfulKey/icon.ico — đó vẫn là icon MindfulKey gốc, chưa rebrand).
SetupIconFile=..\..\..\brand\platform\windows\AppIcon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

; Bộ gõ móc bàn phím toàn hệ thống -> phải là bản 64-bit chạy trên Windows 64-bit.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; [MINDFUL] 2026-07-18 — vá sự cố người dùng thật báo (cài xong không mở, xoá setup không được),
; audit theo dõi lộ thêm: KHÔNG có cơ chế nào khiến Cài-LẠI hay Gỡ-cài nhận ra + đóng được app đang
; chạy trước đó. AppMutex tên PHẢI khớp CHÍNH XÁC mutex app tạo lúc khởi động (AppDelegate.cpp
; run(), "MindfulKeyboardAppMutex") — Setup VÀ Uninstall đều tự kiểm mutex này (tài liệu Inno 6:
; jrsoftware.org/ishelp/topic_setup_appmutex.htm), thấy app đang sống thì CHẶN CỨNG bằng hộp thoại
; "hãy đóng ứng dụng trước", không lặng lẽ ghi đè file đang bị khoá nữa.
; CloseApplications=yes là giá trị MẶC ĐỊNH của Inno 6 (jrsoftware.org/is6help/
; topic_setup_closeapplications.htm) — viết tường minh ở đây để không phụ thuộc ngầm vào việc
; JRSoftware không đổi mặc định trong bản Inno tương lai. Cơ chế này giờ MỚI thật sự hoạt động:
; app đã biết trả lời WM_QUERYENDSESSION/WM_ENDSESSION (SystemTrayHelper.cpp) — trước đây Restart
; Manager của Inno gửi tín hiệu đóng vào khoảng không, Inno báo "không tự đóng được ứng dụng".
AppMutex=MindfulKeyboardAppMutex
CloseApplications=yes
; SetupMutex (KHÁC AppMutex — đây là mutex của chính chương trình CÀI ĐẶT, không phải app) chặn
; HAI BẢN SETUP chạy chồng nhau. Đúng phản xạ người dùng thật đã có: "cài xong không thấy gì mở
; lên" (vì app treo vô hình, bug đã vá ở trên) → bấm chạy lại CHÍNH file cài đặt vừa tải. Không có
; dòng này, hai Setup ghi đè `{app}\MindfulKey.exe` cùng lúc → tranh chấp, dữ liệu cài nửa vời.
SetupMutex=MindfulKeyboardSetupMutex

[Languages]
; Inno Setup 6 KHÔNG kèm sẵn tiếng Việt (bản Vietnamese.isl là của cộng đồng, không nằm trong
; bộ cài chuẩn) -> khung wizard tạm dùng tiếng Anh. Chuỗi RIÊNG của app thì Việt hoá ở [Messages]
; dưới. Chờ chủ dự án chốt có kéo Vietnamese.isl về hay không — xem docs/FRICTION-LOG.md.
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
english.WelcomeLabel2=Sắp cài [name/ver] vào máy bạn.%n%nMindful Key là bộ gõ tiếng Việt chánh niệm, xây trên engine MindfulKey của Mai Vũ Tuyên (GPL v3).%n%nKhuyến nghị đóng các ứng dụng khác trước khi tiếp tục.

[Tasks]
Name: "desktopicon"; Description: "Tạo lối tắt ngoài màn hình"; GroupDescription: "Lối tắt:"

[Files]
Source: "{#SourceExe}"; DestDir: "{app}"; Flags: ignoreversion
; [MINDFUL] 2026-07-18 — trang wizard CHỈ HIỆN LICENSE lúc cài (LicenseFile ở trên), không kèm
; bản trên máy. Comment đầu file này tự gọi việc kèm LICENSE là "nghĩa vụ pháp lý kế thừa, không
; phải phép lịch sự" (GPL v3) — nay mới thật sự đúng lời đó.
Source: "..\..\..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"
Name: "{group}\Gỡ {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyExeName}"; Description: "Mở {#MyAppName} ngay"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; App tự ghi cài đặt vào registry qua MindfulKeyHelper (APP_SET_DATA) — cố ý KHÔNG xoá khi gỡ:
; người dùng cài lại thì còn nguyên gõ tắt/tuỳ chỉnh. Nhật ký cảm xúc cũng KHÔNG đụng tới ở đây
; (riêng tư mặc định: xoá dữ liệu là hành vi người dùng chủ động chọn trong app, không phải
; tác dụng phụ của việc gỡ cài đặt).
Type: dirifempty; Name: "{app}"

[Code]
// [MINDFUL] Tự động dò tìm và gỡ cài đặt phiên bản cũ (OpenKey) trước khi cài bản mới
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  UninstallStr: String;
begin
  if CurStep = ssInstall then
  begin
    // AppId của bản cũ và bản mới đều giống nhau: {7C4E2A16-9E3B-4E51-A0D7-3F1B6C2D8E94}
    // Ưu tiên tìm ở HKLM (All Users) hoặc HKCU (Current User)
    if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{7C4E2A16-9E3B-4E51-A0D7-3F1B6C2D8E94}_is1', 'UninstallString', UninstallStr) or
       RegQueryStringValue(HKCU, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{7C4E2A16-9E3B-4E51-A0D7-3F1B6C2D8E94}_is1', 'UninstallString', UninstallStr) then
    begin
      // Xoá dấu ngoặc kép bọc chuỗi (nếu có)
      UninstallStr := RemoveQuotes(UninstallStr);
      // Gọi trình gỡ cài đặt trong im lặng tuyệt đối, ngắt tiến trình đang chạy của bản cũ
      Exec(UninstallStr, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;
