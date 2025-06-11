# Create a standalone release package for GitHub
# This script creates a zip file containing a self-contained deployment
# that doesn't require .NET runtime to be installed on the target machine

param (
    [string]$Version = "1.1.0",
    [string]$Runtime = "win-x64",
    [string]$Configuration = "Release"
)

# Function to show a message with color
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

Write-ColorMessage "===== Creating Standalone Release Package =====" "Cyan"
Write-ColorMessage "Version: $Version" "Yellow"
Write-ColorMessage "Runtime: $Runtime" "Yellow"
Write-ColorMessage "Configuration: $Configuration" "Yellow"
Write-ColorMessage ""

# Create output directory
$outputDir = "release"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Define the release package name
$releasePackage = Join-Path -Path $outputDir -ChildPath "WallpaperChanger-Standalone-v$Version.zip"

# Build the self-contained application first
Write-ColorMessage "Building self-contained application..." "Yellow"
dotnet publish WallpaperChanger/WallpaperChanger.csproj `
    -c $Configuration `
    -r $Runtime `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:DebugType=none `
    -p:DebugSymbols=false

if ($LASTEXITCODE -ne 0) {
    Write-ColorMessage "Build failed. Please check the error messages above." "Red"
    exit 1
}

# Find the published application
$publishFolder = "WallpaperChanger\bin\$Configuration\net9.0-windows\$Runtime\publish"
$exePath = Join-Path -Path $publishFolder -ChildPath "WallpaperChanger.exe"

if (-not (Test-Path $exePath)) {
    Write-ColorMessage "Published executable not found at: $exePath" "Red"
    exit 1
}

$fileSize = (Get-Item $exePath).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
Write-ColorMessage "Self-contained executable built successfully ($fileSizeMB MB)" "Green"

# Define the files to include in the release
$filesToInclude = @(
    # Main executable (self-contained)
    @{
        Source = $exePath
        Destination = "WallpaperChanger.exe"
    },
    
    # Icon file
    @{
        Source = "WallpaperChanger\Resources\wallpaper_icon.ico"
        Destination = "Resources\wallpaper_icon.ico"
    },
    
    # Standalone installer
    @{
        Source = "install_standalone.ps1"
        Destination = "install.ps1"
    },
    
    # Protocol registration scripts
    @{
        Source = "register_protocol.ps1"
        Destination = "register_protocol.ps1"
    },
    @{
        Source = "register_protocol_user.ps1"
        Destination = "register_protocol_user.ps1"
    },
    
    # Test files
    @{
        Source = "test_protocol.html"
        Destination = "test_protocol.html"
    },
    
    # Documentation
    @{
        Source = "README.md"
        Destination = "README.md"
    },
    @{
        Source = "logo-120.png"
        Destination = "logo-120.png"
    }
)

# Check if all files exist
$missingFiles = @()
foreach ($fileInfo in $filesToInclude) {
    if (-not (Test-Path $fileInfo.Source)) {
        $missingFiles += $fileInfo.Source
    }
}

if ($missingFiles.Count -gt 0) {
    Write-ColorMessage "The following files are missing:" "Red"
    foreach ($file in $missingFiles) {
        Write-ColorMessage "  - $file" -ForegroundColor Red
    }
    exit 1
}

# Create a temporary directory for the release files
$tempDir = Join-Path -Path $outputDir -ChildPath "temp_standalone"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Copy files to the temporary directory
Write-ColorMessage "Copying files to release package..." "Yellow"
foreach ($fileInfo in $filesToInclude) {
    $destPath = Join-Path -Path $tempDir -ChildPath $fileInfo.Destination
    
    # Create directory if needed
    $destDir = Split-Path -Path $destPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }
    
    Copy-Item -Path $fileInfo.Source -Destination $destPath -Force
    Write-ColorMessage "  Copied: $($fileInfo.Source) -> $($fileInfo.Destination)" "Gray"
}

# Create installation instructions
$installInstructionsPath = Join-Path -Path $tempDir -ChildPath "INSTALL_INSTRUCTIONS.md"
$installInstructions = @"
# Wallpaper Changer - Standalone Installation

## Quick Start
1. Extract all files from this zip archive to a folder
2. Right-click on `install.ps1` and select "Run with PowerShell"
3. Follow the on-screen instructions

## What's Included
- **WallpaperChanger.exe** - Self-contained application (no .NET runtime required)
- **install.ps1** - Standalone installer script
- **Resources/wallpaper_icon.ico** - Application icon
- **test_protocol.html** - Protocol handler test page

## System Requirements
- Windows 10 or later (x64)
- PowerShell (included with Windows)
- No .NET runtime installation required

## Features
- Self-contained deployment - runs without installing .NET
- Custom URL protocol handler (`wallpaper0-changer:`)
- Downloads images from aiwp.me API
- Sets desktop wallpaper using Windows API
- System tray integration with custom icon
- Automatic image caching

## Manual Installation
If you prefer not to use the installer script:

1. Copy `WallpaperChanger.exe` to your desired location
2. Copy the `Resources` folder to the same location
3. Run the application directly

To register the protocol handler manually, run:
```powershell
.\register_protocol_user.ps1
```

## Testing
After installation, open `test_protocol.html` in your browser to test the protocol handler.

## Uninstalling
Run the uninstaller script created during installation, or manually delete the installation folder and remove the Start Menu shortcut.

## File Size
The executable is approximately $fileSizeMB MB because it includes the .NET runtime and all dependencies.
"@

Set-Content -Path $installInstructionsPath -Value $installInstructions -Force

# Create release notes
$releaseNotesPath = Join-Path -Path $tempDir -ChildPath "RELEASE_NOTES.md"
$releaseNotes = @"
# Wallpaper Changer v$Version - Standalone Release

## What's New
- **Self-contained deployment** - No .NET runtime installation required
- **Simplified installation** - Just extract and run the installer
- **Smaller download** - Single executable with all dependencies included
- **Better compatibility** - Works on any Windows 10+ machine

## Features
- Custom URL protocol handler (`wallpaper0-changer:`) for easy wallpaper setting
- Downloads images from aiwp.me API
- Sets desktop wallpaper using Windows API
- Runs in the system tray with a custom logo icon
- Caches downloaded images to avoid re-downloading
- Self-contained - no external dependencies

## Installation
1. Extract all files from the zip archive
2. Run `install.ps1` (right-click and "Run with PowerShell")
3. Follow the on-screen instructions

## Technical Details
- Runtime: $Runtime
- File size: $fileSizeMB MB (includes .NET runtime)
- Single-file deployment with trimming enabled
- Optimized for size and performance

## Compatibility
- Windows 10 or later (x64)
- No .NET runtime installation required
- PowerShell (included with Windows)
"@

Set-Content -Path $releaseNotesPath -Value $releaseNotes -Force

# Create the zip file
if (Test-Path $releasePackage) {
    Remove-Item -Path $releasePackage -Force
}

Write-ColorMessage "Creating release package: $releasePackage" "Green"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $releasePackage)

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

# Show results
$packageSize = (Get-Item $releasePackage).Length
$packageSizeMB = [math]::Round($packageSize / 1MB, 2)

Write-ColorMessage "Release package created successfully!" "Green"
Write-ColorMessage "Package: $releasePackage" "Green"
Write-ColorMessage "Package size: $packageSizeMB MB" "Green"
Write-ColorMessage ""
Write-ColorMessage "This package contains a self-contained deployment that:" "Cyan"
Write-ColorMessage "- Doesn't require .NET runtime installation" "Cyan"
Write-ColorMessage "- Can be installed on any Windows 10+ machine" "Cyan"
Write-ColorMessage "- Includes all necessary dependencies" "Cyan"
