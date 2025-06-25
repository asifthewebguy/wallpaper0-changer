; Wallpaper Changer NSIS Installer Script
; This creates a lightweight installer using NSIS (Nullsoft Scriptable Install System)

;--------------------------------
; Includes
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "WinVer.nsh"

;--------------------------------
; General Configuration
Name "Wallpaper Changer"
OutFile "WallpaperChanger-Setup-v1.1.0.exe"
Unicode True

; Default installation folder
InstallDir "$PROGRAMFILES\Wallpaper Changer"

; Get installation folder from registry if available
InstallDirRegKey HKCU "Software\ATWG\WallpaperChanger" "InstallDir"

; Request application privileges
RequestExecutionLevel admin

; Compression
SetCompressor /SOLID lzma

;--------------------------------
; Version Information
VIProductVersion "1.1.0.0"
VIAddVersionKey "ProductName" "Wallpaper Changer"
VIAddVersionKey "CompanyName" "ATWG"
VIAddVersionKey "LegalCopyright" "© 2024 ATWG"
VIAddVersionKey "FileDescription" "Wallpaper Changer Installer"
VIAddVersionKey "FileVersion" "1.1.0.0"
VIAddVersionKey "ProductVersion" "1.1.0.0"

;--------------------------------
; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "wallpaper_icon.ico"
!define MUI_UNICON "wallpaper_icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"

;--------------------------------
; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\WallpaperChanger.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Start Wallpaper Changer"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "Core Application" SecCore
  SectionIn RO  ; Read-only section (always installed)
  
  ; Set output path to the installation directory
  SetOutPath $INSTDIR
  
  ; Copy application files
  File "WallpaperChanger.exe"
  File "WallpaperChanger.dll"
  File "WallpaperChanger.runtimeconfig.json"
  File "WallpaperChanger.deps.json"
  File /nonfatal "WallpaperChanger.pdb"
  
  ; Create Resources subdirectory
  SetOutPath $INSTDIR\Resources
  File "Resources\wallpaper_icon.ico"
  
  ; Store installation folder
  WriteRegStr HKCU "Software\ATWG\WallpaperChanger" "InstallDir" $INSTDIR
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "DisplayName" "Wallpaper Changer"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "DisplayIcon" "$INSTDIR\Resources\wallpaper_icon.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "Publisher" "ATWG"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "DisplayVersion" "1.1.0"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "HelpLink" "https://github.com/asifthewebguy/wallpaper0-changer"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "URLInfoAbout" "https://github.com/asifthewebguy/wallpaper0-changer"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "NoRepair" 1
  
  ; Calculate and store size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "EstimatedSize" "$0"
  
SectionEnd

Section "Protocol Handler" SecProtocol
  ; Register wallpaper0-changer:// protocol
  WriteRegStr HKLM "SOFTWARE\Classes\wallpaper0-changer" "" "URL:Wallpaper Changer Protocol"
  WriteRegStr HKLM "SOFTWARE\Classes\wallpaper0-changer" "URL Protocol" ""
  WriteRegStr HKLM "SOFTWARE\Classes\wallpaper0-changer\DefaultIcon" "" "$INSTDIR\WallpaperChanger.exe,0"
  WriteRegStr HKLM "SOFTWARE\Classes\wallpaper0-changer\shell\open\command" "" '"$INSTDIR\WallpaperChanger.exe" "%1"'
SectionEnd

Section "Start Menu Shortcuts" SecStartMenu
  CreateDirectory "$SMPROGRAMS\Wallpaper Changer"
  CreateShortcut "$SMPROGRAMS\Wallpaper Changer\Wallpaper Changer.lnk" "$INSTDIR\WallpaperChanger.exe" "" "$INSTDIR\Resources\wallpaper_icon.ico"
  CreateShortcut "$SMPROGRAMS\Wallpaper Changer\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Desktop Shortcut" SecDesktop
  CreateShortcut "$DESKTOP\Wallpaper Changer.lnk" "$INSTDIR\WallpaperChanger.exe" "" "$INSTDIR\Resources\wallpaper_icon.ico"
SectionEnd

;--------------------------------
; Section Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "Core application files (required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecProtocol} "Register wallpaper0-changer:// protocol handler for web integration"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} "Add shortcuts to Start Menu"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Add shortcut to Desktop"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Installer Functions

Function .onInit
  ; Check Windows version
  ${IfNot} ${AtLeastWin10}
    MessageBox MB_OK|MB_ICONSTOP "This application requires Windows 10 or later."
    Abort
  ${EndIf}
  
  ; Check if already installed
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger" "UninstallString"
  StrCmp $R0 "" done
  
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Wallpaper Changer is already installed. $\n$\nClick OK to remove the previous version or Cancel to cancel this upgrade." IDOK uninst
  Abort
  
  uninst:
    ClearErrors
    ExecWait '$R0 /S _?=$INSTDIR'
    
    IfErrors no_remove_uninstaller done
    no_remove_uninstaller:
  
  done:
FunctionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"
  ; Remove protocol registration
  DeleteRegKey HKLM "SOFTWARE\Classes\wallpaper0-changer"
  
  ; Remove from Add/Remove Programs
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\WallpaperChanger"
  
  ; Remove user settings
  DeleteRegKey HKCU "Software\ATWG\WallpaperChanger"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\Wallpaper Changer\Wallpaper Changer.lnk"
  Delete "$SMPROGRAMS\Wallpaper Changer\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Wallpaper Changer"
  Delete "$DESKTOP\Wallpaper Changer.lnk"
  
  ; Remove files
  Delete "$INSTDIR\WallpaperChanger.exe"
  Delete "$INSTDIR\WallpaperChanger.dll"
  Delete "$INSTDIR\WallpaperChanger.runtimeconfig.json"
  Delete "$INSTDIR\WallpaperChanger.deps.json"
  Delete "$INSTDIR\WallpaperChanger.pdb"
  Delete "$INSTDIR\Resources\wallpaper_icon.ico"
  Delete "$INSTDIR\Uninstall.exe"
  
  ; Remove directories
  RMDir "$INSTDIR\Resources"
  RMDir "$INSTDIR"
  
SectionEnd

;--------------------------------
; Uninstaller Functions

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove Wallpaper Changer and all of its components?" IDYES +2
  Abort
FunctionEnd

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "Wallpaper Changer was successfully removed from your computer."
FunctionEnd
