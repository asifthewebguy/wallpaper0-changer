@echo off
REM Wallpaper Changer Installation Batch Script
REM This batch file helps bypass PowerShell execution policy issues

echo ===== Wallpaper Changer Installer =====
echo.
echo This script will install the Wallpaper Changer application.
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell and try again.
    pause
    exit /b 1
)

echo Running PowerShell installer with bypass execution policy...
echo.

REM Run the PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"

if errorlevel 1 (
    echo.
    echo Installation failed. Please check the error messages above.
    echo.
    echo If you continue to have issues, try running PowerShell as Administrator and use:
    echo   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
    echo   .\install.ps1
    echo.
    pause
    exit /b 1
)

echo.
echo Installation completed successfully!
pause
