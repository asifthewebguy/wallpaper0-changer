@echo off
setlocal enabledelayedexpansion

:: Get the URL parameter
set url=%~1

:: Log the URL
echo %date% %time% - URL received: %url% >> url_handler.log

:: Extract the image ID from the URL
set url=%url:wallpaper0-changer:=%
set url=%url:"=%
set url=%url:'=%

:: Log the extracted ID
echo %date% %time% - Image ID extracted: %url% >> url_handler.log

:: Run the application with the URL
echo %date% %time% - Running: python main.py wallpaper0-changer:%url% >> url_handler.log
python main.py "wallpaper0-changer:%url%"

:: Log completion
echo %date% %time% - Handler completed >> url_handler.log

endlocal
