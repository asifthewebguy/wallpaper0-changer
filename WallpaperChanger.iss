; Wallpaper Changer - Inno Setup Script
; This script creates a professional Windows installer for the Wallpaper Changer application

#define MyAppName "Wallpaper Changer"
#define MyAppVersion "1.1.3"
#define MyAppPublisher "ATWG"
#define MyAppURL "https://github.com/asifthewebguy/wallpaper0-changer"
#define MyAppExeName "WallpaperChanger.exe"
#define MyAppProtocol "wallpaper0-changer"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
AppId={{8F9A3B2C-1D5E-4F6A-9B2C-3D4E5F6A7B8C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
; Uncomment the following line to allow user-mode installation (no admin required)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=installer\output\InnoSetup
OutputBaseFilename=WallpaperChanger-Setup-v{#MyAppVersion}
SetupIconFile=WallpaperChanger\Resources\wallpaper_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
; Version information
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoCopyright=Copyright (C) 2024 {#MyAppPublisher}
; Wizard images (optional - uncomment if you have custom images)
;WizardImageFile=installer\assets\wizard-large.bmp
;WizardSmallImageFile=installer\assets\wizard-small.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startup"; Description: "Start {#MyAppName} automatically when Windows starts"; GroupDescription: "Startup Options:"; Flags: unchecked

[Files]
; Main application files
Source: "publish\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "publish\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "publish\*.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "publish\Resources\*"; DestDir: "{app}\Resources"; Flags: ignoreversion recursesubdirs

; Documentation and support files
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "RELEASE_NOTES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "test_protocol.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "logo-120.png"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu shortcut
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\Resources\wallpaper_icon.ico"
Name: "{group}\Test Protocol Handler"; Filename: "{app}\test_protocol.html"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

; Desktop shortcut (optional)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\Resources\wallpaper_icon.ico"; Tasks: desktopicon

; Startup shortcut (optional)
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startup

[Registry]
; Register the custom protocol handler
; For user-level installation (HKCU)
Root: HKCU; Subkey: "Software\Classes\{#MyAppProtocol}"; ValueType: string; ValueName: ""; ValueData: "URL:Wallpaper Changer Protocol"; Flags: uninsdeletekey; Check: not IsAdmin
Root: HKCU; Subkey: "Software\Classes\{#MyAppProtocol}"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Check: not IsAdmin
Root: HKCU; Subkey: "Software\Classes\{#MyAppProtocol}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"",0"; Check: not IsAdmin
Root: HKCU; Subkey: "Software\Classes\{#MyAppProtocol}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Check: not IsAdmin

; For system-level installation (HKLM)
Root: HKLM; Subkey: "Software\Classes\{#MyAppProtocol}"; ValueType: string; ValueName: ""; ValueData: "URL:Wallpaper Changer Protocol"; Flags: uninsdeletekey; Check: IsAdmin
Root: HKLM; Subkey: "Software\Classes\{#MyAppProtocol}"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Check: IsAdmin
Root: HKLM; Subkey: "Software\Classes\{#MyAppProtocol}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"",0"; Check: IsAdmin
Root: HKLM; Subkey: "Software\Classes\{#MyAppProtocol}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Check: IsAdmin

; Add to Windows uninstall list
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}"; ValueType: string; ValueName: "DisplayName"; ValueData: "{#MyAppName}"; Check: not IsAdmin
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}"; ValueType: string; ValueName: "DisplayVersion"; ValueData: "{#MyAppVersion}"; Check: not IsAdmin
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}"; ValueType: string; ValueName: "Publisher"; ValueData: "{#MyAppPublisher}"; Check: not IsAdmin
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}"; ValueType: string; ValueName: "URLInfoAbout"; ValueData: "{#MyAppURL}"; Check: not IsAdmin

[Run]
; Option to launch the application after installation
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Close the application before uninstalling
Filename: "{cmd}"; Parameters: "/c taskkill /f /im {#MyAppExeName}"; Flags: runhidden; RunOnceId: "KillApp"

[UninstallDelete]
; Clean up cache directory
Type: filesandordirs; Name: "{localappdata}\WallpaperChanger\Cache"
Type: dirifempty; Name: "{localappdata}\WallpaperChanger"

[Code]
// Check if running as administrator
function IsAdmin: Boolean;
begin
  Result := IsAdminInstallMode;
end;

// Check if .NET 9 Runtime is installed
function IsDotNetInstalled: Boolean;
var
  ResultCode: Integer;
begin
  // Check if dotnet command works and can find .NET 9
  Result := Exec('cmd.exe', '/c dotnet --list-runtimes | findstr "Microsoft.WindowsDesktop.App 9."', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

// Initialize setup - check prerequisites
function InitializeSetup: Boolean;
var
  ErrorCode: Integer;
  DotNetURL: String;
begin
  Result := True;

  // Note: This installer includes a self-contained build, so .NET runtime check is optional
  // Uncomment the following code if you want to enforce .NET runtime installation

  (*
  if not IsDotNetInstalled then
  begin
    if MsgBox('.NET 9 Runtime is not installed. This application requires .NET 9 to run.' + #13#10#13#10 +
              'Would you like to download it now?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      DotNetURL := 'https://aka.ms/dotnet/9.0/windowsdesktop-runtime-win-x64.exe';
      ShellExec('open', DotNetURL, '', '', SW_SHOW, ewNoWait, ErrorCode);
    end;
    Result := False;
  end;
  *)
end;

// Check if application is already running
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Result := '';

  // Try to close the application gracefully
  if Exec('cmd.exe', '/c taskkill /im {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Sleep(1000); // Wait for the application to close
  end;

  // Force close if still running
  Exec('cmd.exe', '/c taskkill /f /im {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

// Initialize uninstall - check if app is running
function InitializeUninstall: Boolean;
var
  ResultCode: Integer;
begin
  Result := True;

  // Close the application before uninstalling
  if Exec('cmd.exe', '/c taskkill /f /im {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Sleep(1000); // Wait for the application to close
  end;
end;

// Customize the finish page
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    WizardForm.FinishedLabel.Caption :=
      'Setup has finished installing {#MyAppName} on your computer.' + #13#10#13#10 +
      'The custom protocol handler "wallpaper0-changer:" has been registered.' + #13#10 +
      'You can now click links with this protocol to change your wallpaper.' + #13#10#13#10 +
      'Click Finish to exit Setup.';
  end;
end;
