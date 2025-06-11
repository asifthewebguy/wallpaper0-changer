@echo off
REM Simple Wallpaper Changer Installer
REM This batch file provides an alternative to the PowerShell installer
REM for users who prefer a simpler installation method

echo ===== Wallpaper Changer Simple Installer =====
echo.
echo This installer will copy the application to your local folder
echo and create a desktop shortcut.
echo.

REM Check if WallpaperChanger.exe exists
if not exist "WallpaperChanger.exe" (
    echo ERROR: WallpaperChanger.exe not found in the current directory.
    echo Please make sure you extracted all files from the zip archive.
    echo.
    pause
    exit /b 1
)

REM Set installation directory
set "INSTALL_DIR=%LOCALAPPDATA%\WallpaperChanger"

echo Installation directory: %INSTALL_DIR%
echo.

REM Ask for confirmation
set /p "CONFIRM=Do you want to continue? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Installation cancelled.
    pause
    exit /b 0
)

echo.
echo Installing Wallpaper Changer...

REM Create installation directory
if not exist "%INSTALL_DIR%" (
    echo Creating installation directory...
    mkdir "%INSTALL_DIR%"
)

REM Copy executable
echo Copying application files...
copy "WallpaperChanger.exe" "%INSTALL_DIR%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy WallpaperChanger.exe
    pause
    exit /b 1
)

REM Copy icon if it exists
if exist "Resources\wallpaper_icon.ico" (
    if not exist "%INSTALL_DIR%\Resources" mkdir "%INSTALL_DIR%\Resources"
    copy "Resources\wallpaper_icon.ico" "%INSTALL_DIR%\Resources\" >nul
    echo Icon copied.
)

REM Create desktop shortcut
echo Creating desktop shortcut...
set "SHORTCUT_PATH=%USERPROFILE%\Desktop\Wallpaper Changer.lnk"

REM Use PowerShell to create shortcut (more reliable than VBScript)
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%INSTALL_DIR%\WallpaperChanger.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Wallpaper Changer Application'; $Shortcut.Save()"

if exist "%SHORTCUT_PATH%" (
    echo Desktop shortcut created.
) else (
    echo Warning: Could not create desktop shortcut.
)

REM Create Start Menu shortcut
echo Creating Start Menu shortcut...
set "START_MENU_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Wallpaper Changer.lnk"

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU_PATH%'); $Shortcut.TargetPath = '%INSTALL_DIR%\WallpaperChanger.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'Wallpaper Changer Application'; $Shortcut.Save()"

if exist "%START_MENU_PATH%" (
    echo Start Menu shortcut created.
) else (
    echo Warning: Could not create Start Menu shortcut.
)

REM Create uninstaller
echo Creating uninstaller...
set "UNINSTALLER_PATH=%INSTALL_DIR%\uninstall.bat"

(
echo @echo off
echo echo Uninstalling Wallpaper Changer...
echo.
echo REM Remove shortcuts
echo if exist "%USERPROFILE%\Desktop\Wallpaper Changer.lnk" del "%USERPROFILE%\Desktop\Wallpaper Changer.lnk"
echo if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Wallpaper Changer.lnk" del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Wallpaper Changer.lnk"
echo.
echo echo Shortcuts removed.
echo echo.
echo echo To complete uninstallation, please manually delete this folder:
echo echo %INSTALL_DIR%
echo echo.
echo echo Wallpaper Changer has been uninstalled.
echo pause
) > "%UNINSTALLER_PATH%"

echo.
echo ===== Installation Complete! =====
echo.
echo The application has been installed to: %INSTALL_DIR%
echo Desktop shortcut created: %USERPROFILE%\Desktop\Wallpaper Changer.lnk
echo Start Menu shortcut created.
echo.
echo To uninstall, run: %UNINSTALLER_PATH%
echo.
echo Note: This simple installer does not register the protocol handler.
echo For full functionality including browser integration, please run:
echo   install.ps1 (PowerShell installer)
echo.

REM Ask if user wants to run the application
set /p "RUN_APP=Do you want to run Wallpaper Changer now? (Y/N): "
if /i "%RUN_APP%"=="Y" (
    echo Starting Wallpaper Changer...
    start "" "%INSTALL_DIR%\WallpaperChanger.exe"
)

echo.
echo Installation complete!
pause
