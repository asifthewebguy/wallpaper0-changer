# Create a release package for GitHub
# This script creates a zip file containing all the necessary files for distribution

# Set version number
$version = "1.0.0"

# Create output directory
$outputDir = "release"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Define the release package name
$releasePackage = Join-Path -Path $outputDir -ChildPath "WallpaperChanger-v$version.zip"

# Define the files to include in the release
$filesToInclude = @(
    # Executable and dependencies
    "WallpaperChanger\bin\Release\net9.0-windows\WallpaperChanger.exe",
    "WallpaperChanger\bin\Release\net9.0-windows\WallpaperChanger.dll",
    "WallpaperChanger\bin\Release\net9.0-windows\WallpaperChanger.runtimeconfig.json",
    "WallpaperChanger\bin\Release\net9.0-windows\Resources\wallpaper_icon.ico",
    
    # Scripts
    "install.ps1",
    "register_protocol.ps1",
    "register_protocol_user.ps1",
    "test_protocol.html",
    
    # Documentation
    "README.md",
    "logo-120.png"
)

# Check if all files exist
$missingFiles = @()
foreach ($file in $filesToInclude) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "The following files are missing:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Red
    }
    exit 1
}

# Create a temporary directory for the release files
$tempDir = Join-Path -Path $outputDir -ChildPath "temp"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Copy files to the temporary directory
foreach ($file in $filesToInclude) {
    $destPath = Join-Path -Path $tempDir -ChildPath (Split-Path -Path $file -Leaf)
    
    # If it's a file in a subdirectory, create the subdirectory
    if ($file -like "*\Resources\*") {
        $resourcesDir = Join-Path -Path $tempDir -ChildPath "Resources"
        if (-not (Test-Path $resourcesDir)) {
            New-Item -Path $resourcesDir -ItemType Directory -Force | Out-Null
        }
        $destPath = Join-Path -Path $resourcesDir -ChildPath (Split-Path -Path $file -Leaf)
    }
    
    Copy-Item -Path $file -Destination $destPath -Force
}

# Create release notes
$releaseNotesPath = Join-Path -Path $tempDir -ChildPath "RELEASE_NOTES.md"
$releaseNotes = @"
# Wallpaper Changer v$version

## Release Notes

### Features
- Custom URL protocol handler (`wallpaper0-changer:`) for easy wallpaper setting
- Downloads images from aiwp.me API
- Sets desktop wallpaper using Windows API
- Runs in the system tray with a custom logo icon
- Caches downloaded images to avoid re-downloading

### Installation
1. Extract all files from the zip archive
2. Run the `install.ps1` script
3. Follow the on-screen instructions

### What's New in This Release
- Added custom logo icon
- Improved system tray integration
- Added comprehensive installer with uninstaller
- Enhanced protocol handler registration
"@

Set-Content -Path $releaseNotesPath -Value $releaseNotes -Force

# Create the zip file
if (Test-Path $releasePackage) {
    Remove-Item -Path $releasePackage -Force
}

Write-Host "Creating release package: $releasePackage" -ForegroundColor Green
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $releasePackage)

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Release package created successfully!" -ForegroundColor Green
Write-Host "Package: $releasePackage" -ForegroundColor Green
