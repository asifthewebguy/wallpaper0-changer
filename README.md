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

## 📚 Documentation

- **[Development Guide](DEVELOPMENT.md)** - For developers who want to contribute or build from source
- **[DevOps Guide](DEVOPS.md)** - For maintainers managing CI/CD and releases
- **[Installer Guide](INSTALLER_GUIDE.md)** - Detailed installation and building instructions
- **[Release Notes](RELEASE_NOTES.md)** - What's new in each version
- **[Roadmap](ROADMAP.md)** - Future plans and features

## ✨ Features

- **Custom URL Protocol Handler** - Use `wallpaper0-changer:` links to easily set wallpapers
- **Automatic Downloads** - Downloads images from aiwp.me API
- **Windows Integration** - Sets desktop wallpaper using Windows API
- **System Tray Application** - Runs minimized with a custom logo icon
- **Smart Caching** - Caches downloaded images to avoid re-downloading
- **Single Instance** - Automatically forwards requests to running instance

## 📦 Latest Release

The latest version is [Wallpaper Changer v1.1.3](https://github.com/asifthewebguy/wallpaper0-changer/releases/latest), which includes:

- Professional Inno Setup installer
- Self-contained build (no .NET runtime required)
- Custom logo icon
- Improved system tray integration
- Automatic protocol handler registration
- Clean uninstallation support

See the [Release Notes](RELEASE_NOTES.md) for more details.

## 🚀 Installation

### Windows Installer (Recommended)

**Download and run the installer:**

1. Go to the [latest release](https://github.com/asifthewebguy/wallpaper0-changer/releases/latest)
2. Download `WallpaperChanger-Setup-v1.1.3.exe`
3. Run the installer and follow the setup wizard

**Features:**
- ✅ No administrator rights required (installs for current user)
- ✅ Optional system-wide installation (requires admin)
- ✅ Automatic protocol handler registration
- ✅ Start Menu shortcuts
- ✅ Optional desktop icon and startup entry
- ✅ Professional uninstaller

**Note:** Windows SmartScreen may show a warning for unsigned installers. Click "More info" → "Run anyway" to proceed.

### Alternative Installation Methods

For advanced users, developers, or automated deployments, see the [Installation section in DEVELOPMENT.md](DEVELOPMENT.md#installation).

## 📖 Usage

### Setting a Wallpaper

To set a wallpaper, use a link with the following format:

```
wallpaper0-changer:image_id
```

Where `image_id` is the ID of the image on aiwp.me.

**Example:**
```html
<a href="wallpaper0-changer:123">Set Wallpaper #123</a>
```

### Testing the Protocol Handler

Open `test_protocol.html` (included in the installer) in your browser to test the protocol handler with an interactive UI.

### System Tray

The application runs in the system tray. Right-click the icon to:
- Exit the application

## 🔧 Troubleshooting

### Common Issues

#### Windows SmartScreen Warning

Windows may show a SmartScreen warning for unsigned installers:

1. Click "More info"
2. Click "Run anyway"
3. Alternatively, see [code signing instructions](INSTALLER_GUIDE.md#code-signing)

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

### Getting Help

If you encounter any issues:

1. Check the [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues) to see if your problem has been reported
2. Review the [Installer Guide](INSTALLER_GUIDE.md) for detailed troubleshooting
3. Open a new issue with:
   - Windows version
   - Installation method used
   - Steps to reproduce
   - Error messages or screenshots

## 🤝 Contributing

Contributions are welcome! Please see [DEVELOPMENT.md](DEVELOPMENT.md#contributing) for detailed guidelines on how to contribute to this project.

Quick start:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 🙏 Acknowledgements

- [aiwp.me](https://aiwp.me) for providing the wallpaper API
- [Inno Setup](https://jrsoftware.org/isinfo.php) for the excellent installer framework
- All contributors who have helped with the project

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Quick Links:**
- [Development Guide](DEVELOPMENT.md) - Build from source, contribute code
- [DevOps Guide](DEVOPS.md) - CI/CD, releases, deployment
- [Installer Guide](INSTALLER_GUIDE.md) - Advanced installation options
- [Release Notes](RELEASE_NOTES.md) - Version history
- [Roadmap](ROADMAP.md) - Future features
