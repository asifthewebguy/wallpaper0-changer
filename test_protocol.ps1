# Test the wallpaper0-changer protocol
# This script simulates a protocol activation

# Find the application executable
$releaseFolder = Join-Path -Path $PSScriptRoot -ChildPath "WallpaperChanger\bin\Release"
$exePath = $null

# Look for the executable in any .NET version folder
if (Test-Path $releaseFolder) {
    $netFolders = Get-ChildItem -Path $releaseFolder -Directory -Filter "net*-windows"

    if ($netFolders.Count -gt 0) {
        foreach ($folder in $netFolders) {
            $testPath = Join-Path -Path $folder.FullName -ChildPath "WallpaperChanger.exe"
            if (Test-Path $testPath) {
                $exePath = $testPath
                break
            }
        }
    }
}

# If not found, try to find it directly
if (-not $exePath) {
    $exeFiles = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter "WallpaperChanger.exe" -ErrorAction SilentlyContinue
    if ($exeFiles.Count -gt 0) {
        $exePath = $exeFiles[0].FullName
    }
}

# Set the application path
$appPath = $exePath

# Ensure the path exists
if (-not $appPath -or -not (Test-Path $appPath)) {
    Write-Error "Application not found. Please build the application in Release mode first."
    Write-Error "Expected path: $releaseFolder\net*-windows\WallpaperChanger.exe"
    exit 1
}

Write-Host "Found application at: $appPath"

# Simulate a protocol activation
$imageId = "005TN27O78.png"  # Replace with a valid image ID from aiwp.me
$protocolUrl = "wallpaper0-changer:$imageId"

Write-Host "Starting application with protocol URL: $protocolUrl"
Start-Process -FilePath $appPath -ArgumentList $protocolUrl

Write-Host "Protocol activation simulated successfully."

