@echo off
setlocal enabledelayedexpansion

:: Wallpaper Changer Batch Installer
:: Simple installer for users who prefer batch files

title Wallpaper Changer Installer

:: Configuration
set "APP_NAME=Wallpaper Changer"
set "APP_VERSION=1.1.0"
set "PROTOCOL_NAME=wallpaper0-changer"
set "PUBLISHER=ATWG"

:: Colors (if supported)
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    set "IS_ADMIN=1"
    set "INSTALL_TYPE=System-wide"
    set "INSTALL_DIR=%ProgramFiles%\%APP_NAME%"
    set "REGISTRY_ROOT=HKLM"
) else (
    set "IS_ADMIN=0"
    set "INSTALL_TYPE=User-level"
    set "INSTALL_DIR=%LOCALAPPDATA%\%APP_NAME%"
    set "REGISTRY_ROOT=HKCU"
)

echo.
echo %CYAN%===== %APP_NAME% Installer =====%RESET%
echo.
echo %BLUE%Version:%RESET% %APP_VERSION%
echo %BLUE%Installation Type:%RESET% %INSTALL_TYPE%
echo %BLUE%Installation Directory:%RESET% %INSTALL_DIR%
echo.

:: Check for source files
set "SCRIPT_DIR=%~dp0"
set "SOURCE_DIR="

:: Look for built application
if exist "%SCRIPT_DIR%..\publish\WallpaperChanger.exe" (
    set "SOURCE_DIR=%SCRIPT_DIR%..\publish"
    echo %GREEN%Found self-contained application in publish directory%RESET%
) else if exist "%SCRIPT_DIR%..\WallpaperChanger\bin\Release" (
    for /d %%d in ("%SCRIPT_DIR%..\WallpaperChanger\bin\Release\net*-windows") do (
        if exist "%%d\WallpaperChanger.exe" (
            set "SOURCE_DIR=%%d"
            echo %GREEN%Found framework-dependent application in release directory%RESET%
            goto :found_source
        )
    )
) else (
    echo %RED%Error: Could not find built application files.%RESET%
    echo %YELLOW%Please build the application first using:%RESET%
    echo   dotnet build --configuration Release
    echo   or
    echo   dotnet publish --configuration Release --self-contained true --runtime win-x64
    pause
    exit /b 1
)

:found_source
echo %BLUE%Source Directory:%RESET% %SOURCE_DIR%
echo.

:: Get user confirmation
set /p "CONFIRM=Do you want to continue with the installation? (Y/N): "
if /i not "%CONFIRM%"=="Y" if /i not "%CONFIRM%"=="YES" (
    echo %YELLOW%Installation cancelled.%RESET%
    pause
    exit /b 0
)

echo.
echo %YELLOW%Starting installation...%RESET%

:: Create installation directory
echo %BLUE%Creating installation directory...%RESET%
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" 2>nul
    if !errorlevel! neq 0 (
        echo %RED%Error: Failed to create installation directory.%RESET%
        pause
        exit /b 1
    )
)

:: Copy application files
echo %BLUE%Copying application files...%RESET%
xcopy "%SOURCE_DIR%\*" "%INSTALL_DIR%\" /E /I /Y >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%Error: Failed to copy application files.%RESET%
    pause
    exit /b 1
)

:: Create Start Menu shortcut
echo %BLUE%Creating Start Menu shortcut...%RESET%
if %IS_ADMIN%==1 (
    set "START_MENU_DIR=%ProgramData%\Microsoft\Windows\Start Menu\Programs"
) else (
    set "START_MENU_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
)

powershell -Command "& {$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU_DIR%\%APP_NAME%.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\WallpaperChanger.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Desktop wallpaper changer with web protocol support'; $Shortcut.IconLocation = '%INSTALL_DIR%\Resources\wallpaper_icon.ico'; $Shortcut.Save()}" >nul 2>&1

:: Create Desktop shortcut (optional)
set /p "DESKTOP_SHORTCUT=Create Desktop shortcut? (Y/N): "
if /i "%DESKTOP_SHORTCUT%"=="Y" if /i "%DESKTOP_SHORTCUT%"=="YES" (
    echo %BLUE%Creating Desktop shortcut...%RESET%
    if %IS_ADMIN%==1 (
        set "DESKTOP_DIR=%PUBLIC%\Desktop"
    ) else (
        set "DESKTOP_DIR=%USERPROFILE%\Desktop"
    )
    
    powershell -Command "& {$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('!DESKTOP_DIR!\%APP_NAME%.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\WallpaperChanger.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Desktop wallpaper changer with web protocol support'; $Shortcut.IconLocation = '%INSTALL_DIR%\Resources\wallpaper_icon.ico'; $Shortcut.Save()}" >nul 2>&1
)

:: Register protocol handler
echo %BLUE%Registering protocol handler...%RESET%
reg add "%REGISTRY_ROOT%\SOFTWARE\Classes\%PROTOCOL_NAME%" /ve /d "URL:%APP_NAME% Protocol" /f >nul 2>&1
reg add "%REGISTRY_ROOT%\SOFTWARE\Classes\%PROTOCOL_NAME%" /v "URL Protocol" /d "" /f >nul 2>&1
reg add "%REGISTRY_ROOT%\SOFTWARE\Classes\%PROTOCOL_NAME%\DefaultIcon" /ve /d "\"%INSTALL_DIR%\WallpaperChanger.exe\",0" /f >nul 2>&1
reg add "%REGISTRY_ROOT%\SOFTWARE\Classes\%PROTOCOL_NAME%\shell\open\command" /ve /d "\"\"%INSTALL_DIR%\WallpaperChanger.exe\"\" \"\"%%1\"\"" /f >nul 2>&1

:: Add to Add/Remove Programs (if admin)
if %IS_ADMIN%==1 (
    echo %BLUE%Adding to Add/Remove Programs...%RESET%
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "DisplayName" /d "%APP_NAME%" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "UninstallString" /d "\"%INSTALL_DIR%\uninstall.bat\"" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "InstallLocation" /d "%INSTALL_DIR%" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "DisplayIcon" /d "%INSTALL_DIR%\Resources\wallpaper_icon.ico" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "Publisher" /d "%PUBLISHER%" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "DisplayVersion" /d "%APP_VERSION%" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "HelpLink" /d "https://github.com/asifthewebguy/wallpaper0-changer" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "URLInfoAbout" /d "https://github.com/asifthewebguy/wallpaper0-changer" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "NoModify" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /v "NoRepair" /t REG_DWORD /d 1 /f >nul 2>&1
)

:: Create uninstaller
echo %BLUE%Creating uninstaller...%RESET%
(
echo @echo off
echo setlocal enabledelayedexpansion
echo.
echo title %APP_NAME% Uninstaller
echo.
echo echo Uninstalling %APP_NAME%...
echo.
echo :: Remove protocol registration
echo reg delete "HKCU\SOFTWARE\Classes\%PROTOCOL_NAME%" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Classes\%PROTOCOL_NAME%" /f ^>nul 2^>^&1
echo.
echo :: Remove shortcuts
echo del "%START_MENU_DIR%\%APP_NAME%.lnk" ^>nul 2^>^&1
echo del "%USERPROFILE%\Desktop\%APP_NAME%.lnk" ^>nul 2^>^&1
echo del "%PUBLIC%\Desktop\%APP_NAME%.lnk" ^>nul 2^>^&1
echo.
echo :: Remove from Add/Remove Programs
echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%APP_NAME%" /f ^>nul 2^>^&1
echo.
echo :: Remove installation directory
echo echo Removing installation directory...
echo timeout /t 2 /nobreak ^>nul
echo rd /s /q "%INSTALL_DIR%"
echo.
echo echo %APP_NAME% has been uninstalled.
echo pause
) > "%INSTALL_DIR%\uninstall.bat"

echo.
echo %GREEN%Installation completed successfully!%RESET%
echo.
echo %CYAN%Installation Summary:%RESET%
echo %BLUE%- Application installed to:%RESET% %INSTALL_DIR%
echo %BLUE%- Start Menu shortcut:%RESET% Created
echo %BLUE%- Desktop shortcut:%RESET% %DESKTOP_SHORTCUT%
echo %BLUE%- Protocol handler:%RESET% Registered
echo %BLUE%- Uninstaller:%RESET% %INSTALL_DIR%\uninstall.bat
echo.

:: Ask to start the application
set /p "START_APP=Would you like to start %APP_NAME% now? (Y/N): "
if /i "%START_APP%"=="Y" if /i "%START_APP%"=="YES" (
    echo %YELLOW%Starting %APP_NAME%...%RESET%
    start "" "%INSTALL_DIR%\WallpaperChanger.exe"
)

echo.
echo %GREEN%Thank you for installing %APP_NAME%!%RESET%
pause
