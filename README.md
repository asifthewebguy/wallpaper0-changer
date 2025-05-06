# Wallpaper Changer

A Windows application that changes desktop wallpapers using images from aiwp.me via a custom URL protocol.

## Features

- Custom URL protocol handler (`wallpaper0-changer:`) for easy wallpaper setting
- Downloads images from aiwp.me API
- Sets desktop wallpaper using Windows API
- Runs in the system tray for minimal interference
- Caches downloaded images to avoid re-downloading

## Installation

1. Build the application in Release mode
2. Run the `register_protocol.ps1` script with administrator privileges to register the custom URL protocol
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
