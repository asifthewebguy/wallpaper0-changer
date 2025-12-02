# Wallpaper Changer - Installer Guide

This guide explains how to build and use the Inno Setup installer for Wallpaper Changer.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building the Installer Locally](#building-the-installer-locally)
- [Installer Features](#installer-features)
- [Installation Modes](#installation-modes)
- [CI/CD Integration](#cicd-integration)
- [Code Signing](#code-signing)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### For Local Development

1. **Inno Setup 6** (required)
   - Download from: https://jrsoftware.org/isdl.php
   - Install to default location: `C:\Program Files (x86)\Inno Setup 6`

2. **.NET 9 SDK** (required)
   - Download from: https://dotnet.microsoft.com/download/dotnet/9.0
   - Verify installation: `dotnet --version`

3. **PowerShell 5.1 or later** (included with Windows 10+)

### For CI/CD (GitHub Actions)

The workflow automatically installs all prerequisites, including Inno Setup.

## Building the Installer Locally

### Quick Build

Run the automated build script:

```powershell
.\build-installer.ps1
```

This script will:
1. Restore NuGet dependencies
2. Build the application in Release mode
3. Run tests
4. Publish a self-contained executable
5. Update version in the Inno Setup script
6. Compile the installer using Inno Setup
7. Output the installer to `installer\output\InnoSetup\`

### Build Options

```powershell
# Build specific version
.\build-installer.ps1 -Version "1.2.0"

# Skip building (use existing publish folder)
.\build-installer.ps1 -SkipBuild

# Specify custom Inno Setup path
.\build-installer.ps1 -InnoSetupPath "C:\Path\To\ISCC.exe"

# Build Debug version
.\build-installer.ps1 -Configuration Debug
```

### Manual Build Steps

If you prefer to build manually:

1. Build and publish the application:
   ```powershell
   dotnet publish WallpaperChanger --configuration Release --self-contained true --runtime win-x64 --output publish
   ```

2. Update version in `WallpaperChanger.iss` (line 5):
   ```
   #define MyAppVersion "1.1.0"
   ```

3. Compile the installer:
   ```powershell
   & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" WallpaperChanger.iss
   ```

4. Find the installer in: `installer\output\InnoSetup\WallpaperChanger-Setup-v1.1.0.exe`

## Installer Features

### What the Installer Does

1. **Application Installation**
   - Installs all application files
   - Creates application directory (user or system-wide)
   - Includes .NET 9 runtime (self-contained build)

2. **Protocol Registration**
   - Registers `wallpaper0-changer:` custom URL protocol
   - Configures protocol handler in Windows Registry
   - Supports both HKCU (user) and HKLM (system-wide) registration

3. **Shortcuts**
   - Start Menu program group
   - Optional desktop shortcut
   - Optional startup entry (run at Windows startup)
   - Quick access to test protocol handler

4. **Documentation**
   - Includes README.md
   - Includes RELEASE_NOTES.md
   - Includes test_protocol.html for testing

5. **Uninstaller**
   - Registered in Windows "Programs and Features"
   - Removes all installed files
   - Cleans up registry entries
   - Removes cache directory (`%LOCALAPPDATA%\WallpaperChanger\Cache`)
   - Closes running application before uninstalling

### Installation Options

During installation, users can choose:

- **Installation Type**: User-level or System-wide (if admin)
- **Desktop Icon**: Create a desktop shortcut (optional)
- **Start with Windows**: Auto-start application on login (optional)
- **Launch Application**: Run the app after installation completes

## Installation Modes

### User-Level Installation (Recommended)

- **No admin rights required**
- Installs to: `%LOCALAPPDATA%\Programs\Wallpaper Changer`
- Protocol registered in: `HKEY_CURRENT_USER`
- Only available to the current user
- Safer and more portable

### System-Wide Installation

- **Requires administrator privileges**
- Installs to: `C:\Program Files\Wallpaper Changer`
- Protocol registered in: `HKEY_LOCAL_MACHINE`
- Available to all users on the system
- Useful for enterprise deployments

## CI/CD Integration

### GitHub Actions Workflow

The installer is automatically built by GitHub Actions when you create a release.

**Trigger a release:**

```bash
# Push a version tag
git tag v1.2.0
git push origin v1.2.0

# Or use GitHub web interface
# Repository → Releases → Create a new release
```

**Manual workflow dispatch:**

1. Go to Actions → Create Release
2. Click "Run workflow"
3. Enter version (e.g., `1.2.0`)
4. Choose prerelease option if needed

### Workflow Steps

The workflow ([.github/workflows/release.yml](.github/workflows/release.yml)):

1. Validates version number
2. Builds and tests the application
3. Publishes self-contained executable
4. Installs Inno Setup on the runner
5. Compiles the installer
6. Creates GitHub release
7. Uploads installer as release asset

### Release Artifacts

Each release includes:

- **WallpaperChanger-Setup-v{version}.exe** - Inno Setup installer (recommended)
- **WallpaperChanger-v{version}.zip** - Framework-dependent package (requires .NET 9)
- **WallpaperChanger-Standalone-v{version}.zip** - Self-contained package
- Optional: WiX MSI installer (if configured)

## Code Signing

### Why Sign the Installer?

Code signing provides:
- User trust (no SmartScreen warnings)
- Verification of publisher identity
- Protection against tampering

### Signing Process

1. **Obtain a Code Signing Certificate**
   - Purchase from: DigiCert, Sectigo, GlobalSign, etc.
   - Or use EV code signing for instant trust

2. **Add Signing to Build Script**

   Update `WallpaperChanger.iss` to include:

   ```pascal
   [Setup]
   SignTool=signtool
   SignedUninstaller=yes
   ```

   Add this to the build script:

   ```powershell
   # Sign the installer
   $certPath = "path\to\certificate.pfx"
   $certPassword = "your-password"

   & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
     /f $certPath `
     /p $certPassword `
     /tr http://timestamp.digicert.com `
     /td SHA256 `
     /fd SHA256 `
     "installer\output\InnoSetup\WallpaperChanger-Setup-v$Version.exe"
   ```

3. **Add Secrets to GitHub Actions**

   In GitHub repository settings → Secrets:
   - `CODE_SIGNING_CERT_BASE64` (base64-encoded certificate)
   - `CODE_SIGNING_CERT_PASSWORD` (certificate password)

4. **Update GitHub Workflow**

   Add signing step after building installer:

   ```yaml
   - name: Sign installer
     shell: pwsh
     run: |
       $certBytes = [Convert]::FromBase64String("${{ secrets.CODE_SIGNING_CERT_BASE64 }}")
       [IO.File]::WriteAllBytes("cert.pfx", $certBytes)

       & "signtool.exe" sign `
         /f "cert.pfx" `
         /p "${{ secrets.CODE_SIGNING_CERT_PASSWORD }}" `
         /tr http://timestamp.digicert.com `
         /td SHA256 `
         /fd SHA256 `
         "installer\output\InnoSetup\WallpaperChanger-Setup-v${{ needs.validate-version.outputs.version }}.exe"

       Remove-Item "cert.pfx"
   ```

## Troubleshooting

### Common Issues

#### 1. Inno Setup Not Found

**Error:** `ERROR: Inno Setup not found!`

**Solution:**
- Install Inno Setup 6 from https://jrsoftware.org/isdl.php
- Or specify path: `.\build-installer.ps1 -InnoSetupPath "C:\Path\To\ISCC.exe"`

#### 2. Build Failed

**Error:** `ERROR: Build failed`

**Solution:**
- Check .NET SDK is installed: `dotnet --version`
- Ensure version is 9.0 or later
- Try restoring packages manually: `dotnet restore`

#### 3. Installer Won't Run

**Error:** Windows SmartScreen warning

**Solution:**
- This is normal for unsigned installers
- Click "More info" → "Run anyway"
- Or sign the installer (see Code Signing section)

#### 4. Protocol Not Registered

**Error:** `wallpaper0-changer:` links don't work

**Solution:**
- Restart your browser after installation
- Check registry: `HKCU\Software\Classes\wallpaper0-changer`
- Run installer with admin rights for system-wide registration

#### 5. Application Won't Start

**Error:** Application fails to launch

**Solution:**
- Check Windows Event Viewer for errors
- Verify .NET 9 runtime (for framework-dependent version)
- Try self-contained installer (includes .NET runtime)

### Debug Mode

To enable detailed logging during installation:

```powershell
WallpaperChanger-Setup-v1.1.0.exe /LOG="install.log"
```

Check `install.log` for detailed installation steps and errors.

## Advanced Configuration

### Silent Installation

For automated/enterprise deployments:

```powershell
# Very silent (no UI)
WallpaperChanger-Setup-v1.1.0.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

# Silent (progress bar only)
WallpaperChanger-Setup-v1.1.0.exe /SILENT /SUPPRESSMSGBOXES /NORESTART

# With specific options
WallpaperChanger-Setup-v1.1.0.exe /VERYSILENT /TASKS="desktopicon,startup" /DIR="C:\CustomPath"
```

### Customizing the Installer

Edit `WallpaperChanger.iss` to customize:

- **Application name/version** (lines 4-6)
- **Default installation path** (line 17)
- **Required privileges** (line 20)
- **Compression settings** (line 27)
- **Additional files** (lines 44-53)
- **Shortcuts** (lines 55-64)
- **Registry keys** (lines 66-79)
- **Custom Pascal code** (lines 95-172)

### Multi-Language Support

To add additional languages, add to `[Languages]` section:

```pascal
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
```

## Support

For issues or questions:

1. Check this guide and [README.md](README.md)
2. Search [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues)
3. Open a new issue with:
   - Windows version
   - Installation log (if available)
   - Steps to reproduce
   - Error messages/screenshots
