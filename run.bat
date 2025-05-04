@echo off
echo Running Wallpaper Changer...

:: Check if we have a parameter (URL protocol)
if "%~1"=="" (
    :: No parameter, run normally
    python main.py
) else (
    :: Parameter provided, pass it to the application
    python main.py %1
)
