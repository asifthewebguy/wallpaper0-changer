# Installation Troubleshooting Guide

## PowerShell Execution Policy Issues

If you encounter errors like:
- "File is not digitally signed"
- "Cannot run this script on the current system"
- "Execution policy" errors

### Quick Solutions

#### Option 1: Use the Batch File (Easiest)
1. Double-click `install.bat` instead of `install.ps1`
2. This automatically bypasses the execution policy

#### Option 2: PowerShell with Bypass (Recommended)
1. Right-click on PowerShell and select "Run as Administrator"
2. Navigate to the extracted folder
3. Run these commands:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\install.ps1
   ```

#### Option 3: Direct Bypass
Open Command Prompt or PowerShell and run:
```cmd
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

#### Option 4: Unblock the File
1. Right-click on `install.ps1`
2. Select "Properties"
3. Check the "Unblock" checkbox at the bottom
4. Click "OK"
5. Try running the script again

### Manual Installation (If Scripts Don't Work)

If all else fails, you can install manually:

1. **Extract the Files**
   - Create a folder: `%LOCALAPPDATA%\WallpaperChanger`
   - Copy `WallpaperChanger.exe` and `Resources` folder to this location

2. **Register Protocol Handler**
   - Run `register_protocol_user.ps1` (for current user only)
   - Or run `register_protocol.ps1` as Administrator (for all users)

3. **Create Shortcut**
   - Right-click on `WallpaperChanger.exe`
   - Select "Create shortcut"
   - Move the shortcut to your Start Menu or Desktop

## Common Issues and Solutions

### "dotnet command not found"
- Install .NET 9.0 Runtime from: https://dotnet.microsoft.com/download
- Or use the self-contained version from releases (no .NET required)

### "Access Denied" Errors
- Run PowerShell as Administrator
- Or use the user-only installation option

### Protocol Handler Not Working
1. Check if the application is properly installed
2. Try running `register_protocol_user.ps1` again
3. Test with the included `test_protocol.html` file

### Antivirus Blocking Installation
- Some antivirus software may block unsigned PowerShell scripts
- Add an exception for the installation folder
- Or use the manual installation method

## Getting Help

If you continue to have issues:
1. Check the GitHub Issues page
2. Create a new issue with:
   - Your Windows version
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Exact error message
   - Steps you've tried

## Alternative Installation Methods

### Using Windows Package Manager (winget)
*Coming soon - we're working on getting the app in the Microsoft Store*

### Using Chocolatey
*Coming soon - we're working on a Chocolatey package*

### Portable Version
Download the release zip and run `WallpaperChanger.exe` directly without installation.
You'll need to manually register the protocol handler if you want browser integration.
