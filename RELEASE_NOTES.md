# Wallpaper Changer v1.2.2 - Release Notes

## Overview

Wallpaper Changer is a Windows application that changes desktop wallpapers using images from aiwp.me via a custom URL protocol. This release introduces a professional Inno Setup installer and major improvements to the installation experience.

## What's New in v1.2.2

### 🚀 New Features
- **Minimize to Tray**: Application now keeps running in the background. Right-click the tray icon to exit or restore.
- **Scheduler**: Automatically rotate wallpapers at set intervals (1 min to 24 hours).
- **Smart Caching**: Significantly improved performance by skipping redundant downloads for existing wallpapers.
- **Improved Validation**: Enhanced security and validation for image IDs and URLs.
- **Tray "Rotate Now"**: Right-click the tray icon to force an immediate rotation from the API.

### 📦 Installation Improvements
- **Professional Inno Setup Installer**: Wizard-style setup.
- **No Admin Required**: Installs to local user profile.
- **Self-Contained**: Includes .NET 9 runtime.

## Features

- **Custom URL Protocol Handler**: Use `wallpaper0-changer:` links to easily set wallpapers
- **API Integration**: Downloads images from aiwp.me API endpoints
- **Windows Integration**: Sets desktop wallpaper using Windows API
- **System Tray Application**: Runs in the system tray with a custom logo icon
- **Caching System**: Caches downloaded images to avoid re-downloading
- **Single Instance**: Automatically forwards requests to running instance

## Installation

### Windows Installer (Recommended)

1. Download `WallpaperChanger-Setup-v1.2.2.exe`
2. Run the installer and follow the setup wizard
3. Choose installation options (desktop icon, auto-start, etc.)
4. Click Install

**Features:**
- No administrator rights required
- Optional system-wide installation
- Automatic protocol handler registration
- Professional uninstaller

**Note:** Windows SmartScreen may show a warning for unsigned installers. Click "More info" → "Run anyway" to proceed.

### Alternative Installation Methods

**PowerShell Script** (for advanced users):
1. Download and extract the ZIP package
2. Run `install.ps1` in PowerShell
3. Follow the on-screen instructions

**Manual Installation** (for developers):
1. Build: `dotnet build -c Release`
2. Register protocol: `.\register_protocol_user.ps1`

See [README.md](README.md) for detailed installation instructions.

## Usage

### Setting a Wallpaper

Use a link with the following format:
```
wallpaper0-changer:image_id
```

Where `image_id` is the ID of the image on aiwp.me.

### Testing

Open `test_protocol.html` in your browser to test the protocol handler with a beautiful UI.

### System Tray

The application runs in the system tray. Right-click the icon to exit.

## Technical Details

- **Platform**: Windows 10 or later
- **Runtime**: .NET 9.0 (included in installer)
- **Architecture**: x64
- **Installer**: Inno Setup 6
- **Size**: ~65 MB (self-contained)

## Documentation

- [README.md](README.md) - User guide and feature overview
- [INSTALLER_GUIDE.md](INSTALLER_GUIDE.md) - Detailed installation and build instructions
- [ROADMAP.md](ROADMAP.md) - Future plans and features

## Known Issues

- Windows SmartScreen may show a warning (installer is not code-signed)
- Some browsers may require permission to open the custom protocol
- Antivirus software may need to allow the protocol handler

## Troubleshooting

If you encounter issues:
1. Check [README.md](README.md#troubleshooting) for common problems
2. Review [INSTALLER_GUIDE.md](INSTALLER_GUIDE.md#troubleshooting) for detailed solutions
3. Report issues on [GitHub](https://github.com/asifthewebguy/wallpaper0-changer/issues)

## Future Plans

- Settings page for configuration options
- Support for multiple monitors
- Scheduled wallpaper changes
- Additional wallpaper sources
- Image preview before setting
- Wallpaper history and favorites
- Code signing for installer

## Acknowledgements

- [aiwp.me](https://aiwp.me) for providing the wallpaper API
- [Inno Setup](https://jrsoftware.org/isinfo.php) for the excellent installer framework
- All contributors and users who provided feedback

## Feedback and Contributions

Feedback and contributions are welcome! Please submit issues and pull requests on [GitHub](https://github.com/asifthewebguy/wallpaper0-changer).

## License

MIT License - See [LICENSE](LICENSE) file for details.
