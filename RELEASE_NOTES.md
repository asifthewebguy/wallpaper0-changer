# Wallpaper Changer v1.0.0 - Release Notes

## Overview

Wallpaper Changer is a Windows application that changes desktop wallpapers using images from aiwp.me via a custom URL protocol. This first official release includes all core functionality and several enhancements.

## Features

- **Custom URL Protocol Handler**: Use `wallpaper0-changer:` links to easily set wallpapers
- **API Integration**: Downloads images from aiwp.me API endpoints
- **Windows Integration**: Sets desktop wallpaper using Windows API
- **System Tray Application**: Runs in the system tray with a custom logo icon for minimal interference
- **Caching System**: Caches downloaded images to avoid re-downloading

## What's New in This Release

- **Custom Logo Icon**: Added a distinctive logo that appears in the application window, taskbar, and system tray
- **Improved System Tray Integration**: Enhanced notification system and context menu
- **Comprehensive Installer**: Added an installer script that handles all setup tasks
- **Uninstaller**: Included an uninstaller for easy removal
- **Enhanced Protocol Handler**: Improved protocol registration for better browser integration
- **Documentation**: Updated README and added detailed release notes

## Installation

### Easy Installation (Recommended)

1. Download the release zip file
2. Extract all files
3. Run the `install.ps1` script
4. Follow the on-screen instructions

The installer will:
- Build the application (if needed)
- Copy files to the installation directory
- Create a Start Menu shortcut
- Register the protocol handler
- Create an uninstaller

### Manual Installation

If you prefer to install manually:

1. Build the application in Release mode
2. Run the `register_protocol.ps1` script with administrator privileges (or `register_protocol_user.ps1` for current user only)
3. The application will start automatically when you click on a `wallpaper0-changer:` link

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
