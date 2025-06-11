# Wallpaper Changer - Standalone Installation Guide

## Overview
This is a **self-contained** version of Wallpaper Changer that doesn't require .NET runtime to be installed on your computer. Everything needed to run the application is included in the executable file.

## What's Different About This Version?
- ✅ **No .NET installation required** - Works on any Windows 10+ machine
- ✅ **Single executable** - All dependencies included
- ✅ **Easy installation** - Multiple installer options
- ✅ **Smaller download** - Optimized for distribution
- ✅ **Better compatibility** - Runs on more systems

## System Requirements
- Windows 10 or later (64-bit)
- PowerShell (included with Windows) - for full installer only
- No .NET runtime installation required
- No Visual Studio or development tools required

## Installation Options

### Option 1: Full Installation (Recommended)
**Best for: Users who want browser integration and protocol handler**

1. Extract all files from the zip archive
2. Right-click on `install.ps1` and select "Run with PowerShell"
3. Follow the on-screen instructions
4. The installer will:
   - Copy the application to your local folder
   - Create Start Menu and desktop shortcuts
   - Register the browser protocol handler
   - Create an uninstaller

### Option 2: Simple Installation
**Best for: Users who prefer basic installation without PowerShell**

1. Extract all files from the zip archive
2. Double-click `install_simple.bat`
3. Follow the prompts
4. This will:
   - Copy the application to your local folder
   - Create desktop and Start Menu shortcuts
   - Create a basic uninstaller
   - **Note:** Does not register protocol handler

### Option 3: Manual Installation
**Best for: Advanced users or portable usage**

1. Extract `WallpaperChanger.exe` to any folder
2. Copy the `Resources` folder to the same location
3. Run `WallpaperChanger.exe` directly
4. Optionally run `register_protocol_user.ps1` for browser integration

## Features
- **Custom URL Protocol**: Use `wallpaper0-changer:` links in browsers
- **API Integration**: Downloads images from aiwp.me
- **System Tray**: Runs minimized in the system tray
- **Image Caching**: Avoids re-downloading images
- **Windows Integration**: Sets desktop wallpaper using Windows API

## Testing the Installation
After installation, you can test the protocol handler:
1. Open `test_protocol.html` in your browser
2. Click the test buttons
3. The application should launch and set wallpapers

## File Sizes
- **WallpaperChanger.exe**: ~65-80 MB (includes .NET runtime)
- **Total package**: ~70-85 MB

The larger size is because this version includes the entire .NET runtime, making it completely self-contained.

## Troubleshooting

### "Windows protected your PC" message
If Windows Defender SmartScreen shows a warning:
1. Click "More info"
2. Click "Run anyway"
3. This happens because the executable isn't digitally signed

### PowerShell execution policy error
If you get an execution policy error:
1. Open PowerShell as Administrator
2. Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Try the installation again

### Application won't start
1. Make sure you extracted ALL files from the zip
2. Check that the `Resources` folder is in the same location as the executable
3. Try running as Administrator

### Protocol handler not working
1. Make sure you used the full installer (`install.ps1`)
2. Try running `register_protocol_user.ps1` manually
3. Restart your browser after installation

## Uninstalling
- **Full installation**: Run the uninstaller created during installation
- **Simple installation**: Run the uninstaller bat file
- **Manual installation**: Simply delete the application folder

## Comparison with Regular Version

| Feature | Standalone Version | Regular Version |
|---------|-------------------|-----------------|
| .NET Runtime Required | ❌ No | ✅ Yes |
| File Size | ~70-85 MB | ~5-10 MB |
| Installation Complexity | Simple | Requires .NET SDK |
| Compatibility | High | Medium |
| Performance | Same | Same |
| Features | Same | Same |

## Security Notes
- The executable is not digitally signed (would require expensive certificate)
- Windows may show security warnings - this is normal
- The application only connects to aiwp.me API for images
- No personal data is collected or transmitted

## Support
If you encounter issues:
1. Check this README for troubleshooting steps
2. Try the different installation options
3. Report issues on the GitHub repository

## Technical Details
- Built with .NET 9.0
- Self-contained deployment with trimming
- Single-file executable
- Windows Forms application
- Optimized for size and performance
