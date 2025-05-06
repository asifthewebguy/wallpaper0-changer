# Test the wallpaper0-changer protocol
# This script simulates a protocol activation

# Get the full path to the application
$appPath = Join-Path -Path $PSScriptRoot -ChildPath "WallpaperChanger\bin\Release\net9.0-windows\WallpaperChanger.exe"

# Ensure the path exists
if (-not (Test-Path $appPath)) {
    Write-Error "Application not found at path: $appPath"
    Write-Error "Please build the application in Release mode first."
    exit 1
}

# Simulate a protocol activation
$imageId = "005TN27O78.png"  # Replace with a valid image ID from aiwp.me
$protocolUrl = "wallpaper0-changer:$imageId"

Write-Host "Starting application with protocol URL: $protocolUrl"
Start-Process -FilePath $appPath -ArgumentList $protocolUrl

Write-Host "Protocol activation simulated successfully."

