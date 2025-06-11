# Wallpaper Changer v1.0.2 - Release Workflow Fix

## Overview

This is a maintenance release that fixes the GitHub Actions release workflow. The application functionality remains the same as v1.0.1, but the automated release process has been improved.

## Features

- **Custom URL Protocol Handler**: Use `wallpaper0-changer:` links to easily set wallpapers
- **API Integration**: Downloads images from aiwp.me API endpoints
- **Windows Integration**: Sets desktop wallpaper using Windows API
- **System Tray Application**: Runs in the system tray with a custom logo icon for minimal interference
- **Caching System**: Caches downloaded images to avoid re-downloading

## What's Fixed in This Release

- **GitHub Actions Release Workflow**: Fixed the automated release workflow that was failing due to incorrect build output paths
- **Self-Contained Deployment**: Improved the release process to properly create self-contained executables
- **Build Path Corrections**: Updated workflow to use the correct paths for .NET 9 with RuntimeIdentifier=win-x64
- **CI/CD Improvements**: Enhanced the continuous integration and deployment pipeline

## Installation

### Easy Installation (Recommended)

1. Download the release zip file
2. Extract all files
3. Run the `install.ps1` script
4. Follow the on-screen instructions

The installer will:
- Copy the self-contained application to the installation directory
- Create a Start Menu shortcut
- Register the protocol handler
- Create an uninstaller

**Note**: This release includes a self-contained executable that doesn't require .NET runtime installation.

### Manual Installation

If you prefer to install manually:

1. Extract `WallpaperChanger.exe` to your desired location
2. Copy the `Resources` folder to the same location as the executable
3. Run the `register_protocol.ps1` script with administrator privileges (or `register_protocol_user.ps1` for current user only)
4. The application will start automatically when you click on a `wallpaper0-changer:` link

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
