@echo off
echo Installing Wallpaper Changer...

:: Check if Python is installed
python --version > nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed. Please install Python 3.7 or later.
    echo You can download Python from https://www.python.org/downloads/
    pause
    exit /b 1
)

:: Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

echo.
echo Installation complete!
echo To run the application, use: python main.py
echo.

:: Ask if user wants to register the URL protocol
set /p register_protocol="Do you want to register the URL protocol for direct wallpaper links? (y/n): "
if /i "%register_protocol%"=="y" (
    echo.
    echo To register the URL protocol, you need administrator privileges.
    echo The registry file will be opened for you to import.
    echo.
    start wallpaper_protocol.reg
)

:: Ask if user wants to run the application now
set /p run_now="Do you want to run the application now? (y/n): "
if /i "%run_now%"=="y" (
    python main.py
)

echo.
echo You can also open wallpaper_links.html to see example wallpaper links.
echo.

pause
