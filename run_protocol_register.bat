@echo off
echo Registering Wallpaper Changer URL Protocol...

:: Check for admin rights
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% neq 0 (
    echo Administrator privileges required!
    echo Right-click on this file and select "Run as administrator"
    pause
    exit /b 1
)

:: Get the current directory with full path
set CURRENT_DIR=%~dp0
set CURRENT_DIR=%CURRENT_DIR:~0,-1%
echo Current directory: %CURRENT_DIR%

:: Run the PowerShell script with the correct path
powershell -ExecutionPolicy Bypass -File "%CURRENT_DIR%\register_protocol.ps1"

echo.
echo If the script ran successfully, you can now use the URL protocol.
echo Try opening test_protocol.html in your browser to test it.
echo.

pause
