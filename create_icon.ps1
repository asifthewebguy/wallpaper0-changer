# This script creates a simple icon file for the Wallpaper Changer app
# It requires the System.Drawing assembly to create the icon

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Create output directory if it doesn't exist
$resourcesDir = Join-Path -Path $PSScriptRoot -ChildPath "WallpaperChanger\Resources"
if (-not (Test-Path $resourcesDir)) {
    New-Item -Path $resourcesDir -ItemType Directory -Force | Out-Null
}

$iconPath = Join-Path -Path $resourcesDir -ChildPath "wallpaper_icon.ico"

# Create a bitmap for the icon
$bitmap = New-Object System.Drawing.Bitmap 64, 64
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Fill background with a gradient
$brush = New-Object Drawing.Drawing2D.LinearGradientBrush(
    (New-Object Drawing.Point 0, 0),
    (New-Object Drawing.Point 64, 64),
    [System.Drawing.Color]::DodgerBlue,
    [System.Drawing.Color]::MediumPurple
)
$graphics.FillRectangle($brush, 0, 0, 64, 64)

# Draw a simple picture frame
$pen = New-Object Drawing.Pen([System.Drawing.Color]::White, 3)
$graphics.DrawRectangle($pen, 10, 10, 44, 44)

# Draw a refresh arrow
$refreshPen = New-Object Drawing.Pen([System.Drawing.Color]::White, 2)
$graphics.DrawArc($refreshPen, 20, 20, 24, 24, 0, 270)
$graphics.DrawLine($refreshPen, 44, 32, 44, 24)
$graphics.DrawLine($refreshPen, 44, 24, 38, 28)

# Save as icon
$icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
$fileStream = New-Object System.IO.FileStream($iconPath, [System.IO.FileMode]::Create)
$icon.Save($fileStream)
$fileStream.Close()

# Clean up
$graphics.Dispose()
$bitmap.Dispose()
$icon.Dispose()

Write-Host "Icon created at: $iconPath"
