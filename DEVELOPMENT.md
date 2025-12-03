# Development Guide

This guide is for developers who want to contribute to Wallpaper Changer or build it from source.

**Other Documentation:**
- [README](README.md) - User guide and installation
- [DevOps Guide](DEVOPS.md) - CI/CD and release management
- [Installer Guide](INSTALLER_GUIDE.md) - Building installers

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Building](#building)
- [Running](#running)
- [Testing](#testing)
- [Code Architecture](#code-architecture)
- [Contributing](#contributing)
- [Development Troubleshooting](#development-troubleshooting)

## Prerequisites

### Required

- **.NET 9.0 SDK** or later
  - Download from: https://dotnet.microsoft.com/download/dotnet/9.0
  - Verify installation: `dotnet --version`

- **Windows 10 or later**
  - The application uses Windows-specific APIs

- **Git**
  - For version control and collaboration

### Optional

- **Visual Studio 2022** or **VS Code**
  - For IDE support with IntelliSense

- **Inno Setup 6** (for building installer)
  - Download from: https://jrsoftware.org/isdl.php
  - Only needed if you want to build the installer locally

## Installation

### Clone the Repository

```powershell
git clone https://github.com/asifthewebguy/wallpaper0-changer.git
cd wallpaper0-changer
```

### Restore Dependencies

```powershell
dotnet restore
```

### PowerShell Script Installation

If you want to install the app locally for testing:

```powershell
.\install.ps1
```

This will:
- Build the application
- Copy files to `%LOCALAPPDATA%\WallpaperChanger`
- Create a Start Menu shortcut
- Register the protocol handler
- Create an uninstaller

### Manual Protocol Registration

For development, you can register the protocol handler manually:

```powershell
# For current user only (recommended for development)
.\register_protocol_user.ps1

# For system-wide (requires admin)
.\register_protocol.ps1
```

## Project Structure

```
wallpaper0-changer/
├── .github/
│   └── workflows/          # GitHub Actions CI/CD workflows
├── WallpaperChanger/       # Main application
│   ├── Program.cs          # Entry point, single-instance logic
│   ├── Form1.cs            # Main form, wallpaper logic
│   ├── Form1.Designer.cs   # Form designer code
│   ├── Resources/          # Application resources
│   │   └── wallpaper_icon.ico
│   └── WallpaperChanger.csproj
├── WallpaperChanger.Tests/ # Unit tests
│   ├── Test1.cs
│   ├── MSTestSettings.cs
│   └── WallpaperChanger.Tests.csproj
├── WallpaperChanger.iss    # Inno Setup installer script
├── build-installer.ps1     # Script to build Inno Setup installer
├── install.ps1             # PowerShell installer script
├── register_protocol*.ps1  # Protocol registration scripts
├── test_protocol.html      # Protocol testing page
└── *.md                    # Documentation files
```

### Key Files

- **[Program.cs](WallpaperChanger/Program.cs)** - Application entry point, handles single-instance logic via mutex and named pipes
- **[Form1.cs](WallpaperChanger/Form1.cs)** - Main application logic, handles protocol URL processing and wallpaper setting
- **[WallpaperChanger.iss](WallpaperChanger.iss)** - Inno Setup script for creating the installer

## Building

### Build Release Version

```powershell
dotnet build -c Release
```

Output: `WallpaperChanger/bin/Release/net9.0-windows/`

### Build Debug Version

```powershell
dotnet build -c Debug
```

Output: `WallpaperChanger/bin/Debug/net9.0-windows/`

### Build Self-Contained Executable

Build a version that includes the .NET runtime (no installation required):

```powershell
dotnet publish WallpaperChanger `
  --configuration Release `
  --self-contained true `
  --runtime win-x64 `
  --output publish
```

Output: `publish/` directory

### Build Installer

Build the Inno Setup installer:

```powershell
.\build-installer.ps1
```

This will:
1. Build and publish the application
2. Run tests
3. Compile the Inno Setup installer
4. Output to: `installer/output/InnoSetup/WallpaperChanger-Setup-v1.1.3.exe`

See [INSTALLER_GUIDE.md](INSTALLER_GUIDE.md) for more details.

## Running

### Run from Source

```powershell
dotnet run --project WallpaperChanger
```

### Run with Protocol Argument

To test protocol handling:

```powershell
dotnet run --project WallpaperChanger -- "wallpaper0-changer:123"
```

### Debug in Visual Studio

1. Open `wallpaper0-changer.sln` in Visual Studio
2. Set `WallpaperChanger` as the startup project
3. Press F5 to run with debugging

To test with protocol arguments:
1. Right-click `WallpaperChanger` → Properties
2. Go to Debug → General → Open debug launch profiles UI
3. Add to Command line arguments: `wallpaper0-changer:123`

## Testing

### Run All Tests

```powershell
dotnet test
```

### Run Tests with Detailed Output

```powershell
dotnet test --verbosity normal
```

### Run Tests in CI Mode

```powershell
dotnet test --logger trx --results-directory TestResults
```

### Test Protocol Handler

1. Build and install the application
2. Open `test_protocol.html` in a browser
3. Click on test links to verify protocol handling

## Code Architecture

### Single Instance Pattern

The application uses a **Mutex** to ensure only one instance runs at a time:

- **First instance**: Creates mutex, starts main form, listens on named pipe
- **Second instance**: Detects mutex, forwards args via named pipe, exits

See [Program.cs:22-32](WallpaperChanger/Program.cs#L22-L32)

### Named Pipe Communication

Inter-process communication using named pipes:
- **Server**: Running instance listens on `WallpaperChangerPipe`
- **Client**: New instances send protocol URLs to the server

See [Program.cs:71-133](WallpaperChanger/Program.cs#L71-L133)

### Protocol URL Processing

Flow when a `wallpaper0-changer:` link is clicked:

1. Windows launches app with URL as argument
2. App parses image ID from URL
3. Fetches image details from `aiwp.me/api/images/{id}.json`
4. Downloads image to cache directory
5. Sets as wallpaper using `SystemParametersInfo` Win32 API

See [Form1.cs:96-159](WallpaperChanger/Form1.cs#L96-L159)

### Caching Strategy

Downloaded images are cached to avoid re-downloads:
- **Location**: `%LOCALAPPDATA%\WallpaperChanger\Cache`
- **Naming**: `{image_id}{extension}` (e.g., `123.jpg`)
- **Persistence**: Cache persists across app restarts

See [Form1.cs:194-213](WallpaperChanger/Form1.cs#L194-L213)

## Contributing

We welcome contributions! Here's how to get started:

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:
   ```powershell
   git clone https://github.com/YOUR_USERNAME/wallpaper0-changer.git
   cd wallpaper0-changer
   ```

### Create a Feature Branch

```powershell
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

### Make Changes

1. Write clean, readable code
2. Follow existing code style and conventions
3. Add tests for new functionality
4. Update documentation as needed

### Code Style Guidelines

- Use meaningful variable and method names
- Add XML comments for public APIs
- Keep methods focused and concise
- Handle errors gracefully with try-catch
- Use async/await for I/O operations

### Commit Changes

```powershell
git add .
git commit -m "Add feature: description of changes"
```

Commit message format:
```
<type>: <subject>

<body>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Push and Create PR

```powershell
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear description of changes
- Reference to related issues
- Screenshots/GIFs if UI changes

### Code Review Process

1. Automated checks run (CI, tests, CodeQL)
2. Maintainers review the code
3. Address feedback if requested
4. Once approved, PR will be merged

## Development Troubleshooting

### Build Errors

#### Error: SDK not found

```
The current .NET SDK does not support targeting .NET 9.0
```

**Solution:** Install .NET 9.0 SDK from https://dotnet.microsoft.com/download/dotnet/9.0

#### Error: Missing dependencies

```
error NU1101: Unable to find package
```

**Solution:**
```powershell
dotnet restore --force
dotnet clean
dotnet build
```

### Runtime Errors

#### Protocol Handler Not Registered

If the app doesn't respond to protocol links:

```powershell
# Re-register the protocol
.\register_protocol_user.ps1
```

#### App Won't Start

Check for another instance:
```powershell
# Kill all instances
taskkill /F /IM WallpaperChanger.exe
```

#### Mutex Already Owned

If you see mutex errors in debug mode:
- Close all running instances
- Clean and rebuild
- Delete cache: `%LOCALAPPDATA%\WallpaperChanger\Cache`

### Testing Issues

#### Tests Fail in CI

Make sure:
- Tests don't depend on user-specific paths
- Tests don't require GUI interaction
- Tests clean up after themselves

#### Cache Issues

Clear the cache directory:
```powershell
Remove-Item "$env:LOCALAPPDATA\WallpaperChanger\Cache" -Recurse -Force
```

## Additional Resources

- [DevOps Guide](DEVOPS.md) - Learn about CI/CD and release process
- [Installer Guide](INSTALLER_GUIDE.md) - Advanced installer building
- [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues) - Report bugs or request features
- [Discussions](https://github.com/asifthewebguy/wallpaper0-changer/discussions) - Ask questions and share ideas

## Getting Help

If you need help with development:

1. Check existing documentation
2. Search [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues)
3. Ask in [Discussions](https://github.com/asifthewebguy/wallpaper0-changer/discussions)
4. Open a new issue with the `question` label

---

**Quick Links:**
- [Back to README](README.md)
- [DevOps Guide](DEVOPS.md)
- [Installer Guide](INSTALLER_GUIDE.md)
