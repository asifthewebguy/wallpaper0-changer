# Wallpaper Changer Installers

This directory contains multiple installer options for the Wallpaper Changer application. Choose the installer type that best fits your needs and environment.

## 🚀 Quick Start

**For most users, we recommend the Enhanced PowerShell Installer:**

```powershell
.\Build-All-Installers.ps1 -BuildTypes "PowerShell"
```

Then run the generated installer:
```powershell
.\output\Install-WallpaperChanger.ps1
```

## 📦 Available Installer Types

### 1. Enhanced PowerShell Installer (Recommended)
- **File**: `Install-WallpaperChanger.ps1`
- **Best for**: Most Windows users, IT administrators
- **Features**:
  - User-level or system-wide installation
  - Comprehensive logging
  - Silent installation support
  - Automatic application detection
  - Built-in uninstaller
  - Protocol handler registration
  - Start Menu and Desktop shortcuts

**Usage:**
```powershell
# Standard installation
.\Install-WallpaperChanger.ps1

# System-wide installation (requires admin)
.\Install-WallpaperChanger.ps1 -SystemWide

# Silent installation
.\Install-WallpaperChanger.ps1 -Silent

# Custom directory
.\Install-WallpaperChanger.ps1 -InstallDir "C:\MyApps\WallpaperChanger"
```

### 2. Windows Installer (MSI)
- **File**: `WallpaperChanger.wxs` + `Build-MSI.ps1`
- **Best for**: Enterprise environments, Group Policy deployment
- **Features**:
  - Professional Windows Installer package
  - Add/Remove Programs integration
  - Upgrade/downgrade handling
  - Windows Installer logging
  - Group Policy deployment support

**Requirements**: WiX Toolset (automatically installed if missing)

**Usage:**
```powershell
.\Build-MSI.ps1
```

### 3. NSIS Installer
- **File**: `WallpaperChanger.nsi` + `Build-NSIS.ps1`
- **Best for**: Lightweight distribution, custom branding
- **Features**:
  - Small installer size
  - Custom UI and branding
  - Component selection
  - Uninstaller included
  - Multi-language support ready

**Requirements**: NSIS (Nullsoft Scriptable Install System)

**Usage:**
```powershell
.\Build-NSIS.ps1
```

### 4. Batch File Installer
- **File**: `install.bat`
- **Best for**: Simple environments, users who prefer batch files
- **Features**:
  - No external dependencies
  - Simple and straightforward
  - Automatic admin detection
  - Built-in uninstaller
  - Lightweight

**Usage:**
```batch
install.bat
```

## 🔧 Building All Installers

Use the master build script to create all installer types:

```powershell
# Build all installer types
.\Build-All-Installers.ps1

# Build specific types only
.\Build-All-Installers.ps1 -BuildTypes "PowerShell,NSIS"

# Specify custom version
.\Build-All-Installers.ps1 -Version "1.2.0"

# Use custom source directory
.\Build-All-Installers.ps1 -SourceDir "..\publish"
```

## 📋 Prerequisites

Before building installers, ensure you have:

1. **Built the application**:
   ```powershell
   dotnet build --configuration Release
   # OR for self-contained
   dotnet publish --configuration Release --self-contained true --runtime win-x64
   ```

2. **Required tools** (automatically installed if missing):
   - **For MSI**: WiX Toolset
   - **For NSIS**: NSIS (Nullsoft Scriptable Install System)
   - **For PowerShell/Batch**: No additional tools required

## 🎯 Installer Comparison

| Feature | PowerShell | MSI | NSIS | Batch |
|---------|------------|-----|------|-------|
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Professional Look** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Enterprise Features** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Size** | Small | Medium | Small | Tiny |
| **Dependencies** | None | WiX | NSIS | None |
| **Customization** | High | Medium | Very High | Low |
| **Logging** | Excellent | Good | Good | Basic |
| **Uninstaller** | Yes | Yes | Yes | Yes |

## 🔍 Installation Features

All installers provide:

- ✅ Application file installation
- ✅ Start Menu shortcuts
- ✅ Desktop shortcuts (optional)
- ✅ Protocol handler registration (`wallpaper0-changer://`)
- ✅ Uninstaller creation
- ✅ Registry entries for Add/Remove Programs
- ✅ User-level and system-wide installation options

## 🛠️ Troubleshooting

### Common Issues

1. **"Application not found" error**:
   - Ensure you've built the application first
   - Check that `WallpaperChanger.exe` exists in the expected location

2. **"Access denied" errors**:
   - Run PowerShell as Administrator for system-wide installation
   - Use user-level installation if admin rights are not available

3. **"WiX not found" error**:
   - The build script will offer to install WiX automatically
   - Or manually install: `dotnet tool install --global wix`

4. **"NSIS not found" error**:
   - Install NSIS from: https://nsis.sourceforge.io/Download
   - Or use winget: `winget install NSIS.NSIS`

### PowerShell Execution Policy

If you get execution policy errors:

```powershell
# Temporarily allow script execution
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Or permanently for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 📁 Output Structure

After building, the `output` directory will contain:

```
output/
├── Install-WallpaperChanger.ps1           # PowerShell installer
├── WallpaperChanger-PowerShell-v1.1.0.zip # PowerShell package
├── WallpaperChanger-v1.1.0.msi           # MSI installer
├── WallpaperChanger-Setup-v1.1.0.exe     # NSIS installer
├── WallpaperChanger-Batch-v1.1.0.zip     # Batch package
└── install.bat                           # Batch installer
```

## 🔗 Related Files

- `../install.ps1` - Original PowerShell installer (legacy)
- `../register_protocol.ps1` - Standalone protocol registration
- `../create_release_package.ps1` - Release packaging script

## 📝 License

All installer scripts are provided under the same license as the main application.

## 🤝 Contributing

To improve the installers:

1. Test on different Windows versions
2. Add support for additional installer frameworks
3. Improve error handling and user experience
4. Add localization support

---

**Need help?** Check the main project README or open an issue on GitHub.
