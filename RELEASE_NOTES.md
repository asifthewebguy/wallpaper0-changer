# Wallpaper Changer v1.0.3 - Complete Installation Solution

## Overview

This is a comprehensive release that includes all the best features from previous versions plus significant improvements to the installation experience and automated release process. This version provides multiple installation options to ensure compatibility across different Windows environments.

## Features

- **Custom URL Protocol Handler**: Use `wallpaper0-changer:` links to easily set wallpapers
- **API Integration**: Downloads images from aiwp.me API endpoints
- **Windows Integration**: Sets desktop wallpaper using Windows API
- **System Tray Application**: Runs in the system tray with a custom logo icon for minimal interference
- **Caching System**: Caches downloaded images to avoid re-downloading

## What's New and Improved in This Release

### 🚀 Installation Experience
- **Multiple Installation Options**: Choose from PowerShell script, batch file, or manual installation
- **PowerShell Execution Policy Solutions**: Added `install.bat` to bypass common "digitally signed" errors
- **Comprehensive Troubleshooting Guide**: Detailed solutions for common installation issues
- **Self-Contained Deployment**: No .NET runtime installation required

### 🔧 Technical Improvements
- **GitHub Actions Release Workflow**: Fixed automated release workflow with proper permissions
- **Build Path Corrections**: Updated workflow to use correct paths for .NET 9 with RuntimeIdentifier=win-x64
- **CI/CD Pipeline**: Enhanced continuous integration and deployment process
- **Workflow Robustness**: Improved error handling and re-run capabilities

### 📚 Documentation
- **Installation Troubleshooting Guide**: `INSTALLATION_TROUBLESHOOTING.md` with detailed solutions
- **Updated README**: Clear installation instructions with multiple options
- **Enhanced Release Notes**: Comprehensive documentation of all features and fixes

## Installation

### 🚀 Easy Installation (Recommended)

**Option 1: Batch File (Bypasses PowerShell Issues)**
1. Download the release zip file
2. Extract all files
3. **Double-click `install.bat`** (easiest method)
4. Follow the on-screen instructions

**Option 2: PowerShell Script**
1. Download the release zip file
2. Extract all files
3. Right-click `install.ps1` and select "Run with PowerShell"
4. If you get execution policy errors, see `INSTALLATION_TROUBLESHOOTING.md`

The installer will:
- Copy the self-contained application to the installation directory
- Create a Start Menu shortcut
- Register the protocol handler
- Create an uninstaller

**Note**: This release includes a self-contained executable that doesn't require .NET runtime installation.

### 🔧 Manual Installation

If you prefer to install manually:

1. Extract `WallpaperChanger.exe` to your desired location
2. Copy the `Resources` folder to the same location as the executable
3. Run the `register_protocol.ps1` script with administrator privileges (or `register_protocol_user.ps1` for current user only)
4. The application will start automatically when you click on a `wallpaper0-changer:` link

### 🆘 Having Installation Issues?

If you encounter "execution policy" or "digitally signed" errors, check out `INSTALLATION_TROUBLESHOOTING.md` for detailed solutions including:
- PowerShell execution policy fixes
- Alternative installation methods
- Common error solutions
- Manual installation steps

## Usage

### Setting a Wallpaper

To set a wallpaper, use a link with the following format:

```
wallpaper0-changer:image_id
```

Where `image_id` is the ID of the image on aiwp.me.

### System Tray

The application runs in the system tray. Right-click the icon to:
- Exit the application

## Testing

The package includes a test HTML file (`test_protocol.html`) that you can use to test the protocol handler. Open this file in your browser and click on the test links to verify that the application works correctly.

## Known Issues

- The application may not work with some browsers that have strict security settings for custom protocols
- Some antivirus software may block the protocol handler registration

## Future Plans

- Add a settings page for configuration options
- Add support for multiple monitors
- Implement scheduled wallpaper changes
- Add more sources for wallpapers

## Feedback and Contributions

Feedback and contributions are welcome! Please submit issues and pull requests on GitHub.

## License

MIT
