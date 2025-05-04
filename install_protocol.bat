@echo off
echo Installing Wallpaper Changer URL Protocol...

:: Get the current directory
set CURRENT_DIR=%~dp0
set CURRENT_DIR=%CURRENT_DIR:\=\\%

:: Create a temporary registry file
echo Windows Registry Editor Version 5.00 > temp_protocol.reg
echo. >> temp_protocol.reg
echo [HKEY_CLASSES_ROOT\wallpaper0-changer] >> temp_protocol.reg
echo @="URL:Wallpaper Changer Protocol" >> temp_protocol.reg
echo "URL Protocol"="" >> temp_protocol.reg
echo. >> temp_protocol.reg
echo [HKEY_CLASSES_ROOT\wallpaper0-changer\shell] >> temp_protocol.reg
echo. >> temp_protocol.reg
echo [HKEY_CLASSES_ROOT\wallpaper0-changer\shell\open] >> temp_protocol.reg
echo. >> temp_protocol.reg
echo [HKEY_CLASSES_ROOT\wallpaper0-changer\shell\open\command] >> temp_protocol.reg
echo @="\\\"C:\\\\Windows\\\\System32\\\\cmd.exe\\\" /c \\\"cd /d %CURRENT_DIR% ^& python main.py \\\"%%1\\\"\\\"" >> temp_protocol.reg

:: Import the registry file
regedit /s temp_protocol.reg

:: Clean up
del temp_protocol.reg

echo.
echo URL Protocol installed successfully!
echo You can now use links like: wallpaper0-changer:UQ0VJ5GNQ1.jpg
echo.

pause
