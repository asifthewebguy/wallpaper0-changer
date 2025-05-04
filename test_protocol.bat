@echo off
echo Testing Wallpaper Changer URL Protocol...

:: Test with a direct command
echo.
echo Testing direct command...
python main.py "wallpaper0-changer:005TN27O78.png"

echo.
echo If the wallpaper changed successfully, the URL protocol is working correctly.
echo.
echo Now try opening test_protocol.html in your browser to test the actual URL protocol.
echo.

pause
