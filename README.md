# Wallpaper Changer

<p align="center">
  <img src="logo-120.png" alt="Wallpaper Changer Logo" width="120" height="120">
</p>

A Windows application that changes desktop wallpapers using images from aiwp.me via a custom URL protocol.

## Features

- Custom URL protocol handler (`wallpaper0-changer:`) for easy wallpaper setting
- Downloads images from aiwp.me API
- Sets desktop wallpaper using Windows API
- Runs in the system tray with a custom logo icon for minimal interference
- Caches downloaded images to avoid re-downloading

## Installation

### Easy Installation (Recommended)

1. Download the latest release
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

## License

MIT
