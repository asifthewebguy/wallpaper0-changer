# Wallpaper Changer

<p align="center">
  <img src="logo-120.png" alt="Wallpaper Changer Logo" width="120" height="120">
</p>

<p align="center">
  <a href="https://github.com/asifthewebguy/wallpaper0-changer/releases/latest">
    <img src="https://img.shields.io/github/v/release/asifthewebguy/wallpaper0-changer" alt="Latest Release">
  </a>
  <a href="https://github.com/asifthewebguy/wallpaper0-changer/actions/workflows/ci.yml">
    <img src="https://github.com/asifthewebguy/wallpaper0-changer/actions/workflows/ci.yml/badge.svg" alt="CI Status">
  </a>
  <a href="https://github.com/asifthewebguy/wallpaper0-changer/actions/workflows/codeql-analysis.yml">
    <img src="https://github.com/asifthewebguy/wallpaper0-changer/actions/workflows/codeql-analysis.yml/badge.svg" alt="CodeQL Analysis">
  </a>
  <a href="https://github.com/asifthewebguy/wallpaper0-changer/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/asifthewebguy/wallpaper0-changer" alt="License">
  </a>
</p>

A Windows application that changes desktop wallpapers using images from aiwp.me via a custom URL protocol. Simply click on a `wallpaper0-changer:` link, and the application will download and set the wallpaper automatically.

## Features

- Custom URL protocol handler (`wallpaper0-changer:`) for easy wallpaper setting
- Downloads images from aiwp.me API
- Sets desktop wallpaper using Windows API
- Runs in the system tray with a custom logo icon for minimal interference
- Caches downloaded images to avoid re-downloading

## Latest Release

The latest version is [Wallpaper Changer v1.1.3](https://github.com/asifthewebguy/wallpaper0-changer/releases/latest), which includes:

- Professional Inno Setup installer
- Self-contained build (no .NET runtime required)
- Custom logo icon
- Improved system tray integration
- Automatic protocol handler registration
- Clean uninstallation support

See the [Release Notes](RELEASE_NOTES.md) for more details.

## Installation

### Windows Installer (Recommended)

**Download and run the installer:**

1. Go to the [latest release](https://github.com/asifthewebguy/wallpaper0-changer/releases/latest)
2. Download `WallpaperChanger-Setup-v1.1.3.exe`
3. Run the installer and follow the setup wizard

**Features:**
- No administrator rights required (installs for current user)
- Optional system-wide installation (requires admin)
- Automatic protocol handler registration
- Start Menu shortcuts
- Optional desktop icon and startup entry
- Professional uninstaller

**Note:** Windows SmartScreen may show a warning for unsigned installers. Click "More info" → "Run anyway" to proceed.

### PowerShell Script Installation (Alternative)

For advanced users or automated deployments:

1. Download the [latest release package](https://github.com/asifthewebguy/wallpaper0-changer/releases/latest)
2. Extract the ZIP file
3. Run the `install.ps1` script in PowerShell
4. Follow the on-screen instructions

The script will:
- Build the application (if needed)
- Copy files to the installation directory
- Create a Start Menu shortcut
- Register the protocol handler
- Create an uninstaller

### Manual Installation

For developers or manual installation:

1. Build the application:
   ```powershell
   dotnet build -c Release
   ```

2. Register the protocol handler:
   ```powershell
   # For current user only
   .\register_protocol_user.ps1

   # For system-wide (requires admin)
   .\register_protocol.ps1
   ```

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

## Development

### Prerequisites

- .NET 9.0 SDK
- Windows 10 or later
- Inno Setup 6 (for building installer)

### Building

Build the application:
```powershell
dotnet build -c Release
```

Build the installer:
```powershell
.\build-installer.ps1
```

See [INSTALLER_GUIDE.md](INSTALLER_GUIDE.md) for detailed build instructions.

### Running

```powershell
dotnet run
```

## Troubleshooting

### Common Issues

#### Windows SmartScreen Warning

Windows may show a SmartScreen warning for unsigned installers:

1. Click "More info"
2. Click "Run anyway"
3. Alternatively, see [INSTALLER_GUIDE.md](INSTALLER_GUIDE.md#code-signing) for code signing instructions

#### Protocol Handler Not Working

If clicking on `wallpaper0-changer:` links doesn't work:

1. Make sure the application is installed correctly
2. Restart your browser after installation
3. Check Windows Registry: `HKCU\Software\Classes\wallpaper0-changer`
4. Try reinstalling or running the installer as administrator
5. Check if your browser is blocking custom protocol handlers

#### Application Not Starting

If the application doesn't start:

1. Use the self-contained installer (includes .NET runtime)
2. Check Windows Event Viewer for error messages
3. Try running the application as administrator
4. Verify antivirus isn't blocking the application

#### Installation Issues

For detailed troubleshooting and installation help:

- See [INSTALLER_GUIDE.md](INSTALLER_GUIDE.md#troubleshooting)
- Check installation logs (run installer with `/LOG="install.log"`)

### Getting Help

If you encounter any issues:

1. Check the [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues) to see if your problem has been reported
2. Review the [Installer Guide](INSTALLER_GUIDE.md) for detailed documentation
3. Open a new issue with:
   - Windows version
   - Installation method used
   - Steps to reproduce
   - Error messages or screenshots

## Contributing

Contributions are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

Please make sure your code follows the existing style and includes appropriate tests.

## Roadmap

Future plans for Wallpaper Changer include:

- [ ] Settings page for configuration options
- [ ] Support for multiple monitors
- [ ] Scheduled wallpaper changes
- [ ] Additional wallpaper sources
- [ ] Image preview before setting as wallpaper
- [ ] Wallpaper history and favorites

## Acknowledgements

- [aiwp.me](https://aiwp.me) for providing the wallpaper API
- All contributors who have helped with the project

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
