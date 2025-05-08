# Wallpaper Changer

<p align="center">
  <img src="logo-120.png" alt="Wallpaper Changer Logo" width="120" height="120">
</p>

<p align="center">
  <a href="https://github.com/asifthewebguy/wallpaper0-changer/releases/latest">
    <img src="https://img.shields.io/github/v/release/asifthewebguy/wallpaper0-changer" alt="Latest Release">
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

The latest version is [Wallpaper Changer v1.0.0](https://github.com/asifthewebguy/wallpaper0-changer/releases/tag/v1.0.0), which includes:

- Custom logo icon
- Improved system tray integration
- Comprehensive installer with uninstaller
- Enhanced protocol handler registration

See the [Release Notes](https://github.com/asifthewebguy/wallpaper0-changer/releases/tag/v1.0.0) for more details.

## Installation

### Easy Installation (Recommended)

1. Download the [latest release](https://github.com/asifthewebguy/wallpaper0-changer/releases/latest)
2. Run the `install.ps1` script
3. Follow the on-screen instructions

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

## Development

### Prerequisites

- .NET 8.0 SDK
- Windows 10 or later

### Building

```
dotnet build -c Release
```

### Running

```
dotnet run
```

## Troubleshooting

### Common Issues

#### Protocol Handler Not Working

If clicking on `wallpaper0-changer:` links doesn't work:

1. Make sure the application is installed correctly
2. Run the registration script again (`register_protocol.ps1` or `register_protocol_user.ps1`)
3. Restart your browser
4. Check if your browser is blocking custom protocol handlers

#### Application Not Starting

If the application doesn't start:

1. Check if .NET Runtime is installed
2. Try running the application as administrator
3. Check Windows Event Viewer for any error messages

### Getting Help

If you encounter any issues:

1. Check the [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues) to see if your problem has been reported
2. Open a new issue with detailed information about your problem
3. Include steps to reproduce the issue and any error messages

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
