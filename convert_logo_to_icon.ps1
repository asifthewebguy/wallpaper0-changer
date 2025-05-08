# This script converts the logo PNG file to an ICO file for the Wallpaper Changer app
# It requires the System.Drawing assembly to create the icon

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Source logo file
$logoPath = Join-Path -Path $PSScriptRoot -ChildPath "logo-120.png"

# Create output directory if it doesn't exist
$resourcesDir = Join-Path -Path $PSScriptRoot -ChildPath "WallpaperChanger\Resources"
if (-not (Test-Path $resourcesDir)) {
    New-Item -Path $resourcesDir -ItemType Directory -Force | Out-Null
}

$iconPath = Join-Path -Path $resourcesDir -ChildPath "wallpaper_icon.ico"

# Check if the logo file exists
if (-not (Test-Path $logoPath)) {
    Write-Error "Logo file not found at: $logoPath"
    exit 1
}

Write-Host "Converting logo from: $logoPath"
Write-Host "To icon at: $iconPath"

# Load the source image
$sourceImage = [System.Drawing.Image]::FromFile($logoPath)

# Create icon sizes
$sizes = @(16, 32, 48, 64, 128, 256)
$bitmaps = @()

foreach ($size in $sizes) {
    Write-Host "Creating $size x $size icon..."
    $bitmap = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Set high quality scaling
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    
    # Draw the source image scaled to the target size
    $graphics.DrawImage($sourceImage, 0, 0, $size, $size)
    
    $bitmaps += $bitmap
    $graphics.Dispose()
}

# Save as multi-size icon
try {
    # Create a temporary file for each bitmap
    $tempFiles = @()
    for ($i = 0; $i -lt $bitmaps.Count; $i++) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $tempFiles += $tempFile
        $icon = [System.Drawing.Icon]::FromHandle($bitmaps[$i].GetHicon())
        $fileStream = New-Object System.IO.FileStream($tempFile, [System.IO.FileMode]::Create)
        $icon.Save($fileStream)
        $fileStream.Close()
        $icon.Dispose()
    }
    
    # Use the first bitmap to create the main icon file
    $icon = [System.Drawing.Icon]::FromHandle($bitmaps[0].GetHicon())
    $fileStream = New-Object System.IO.FileStream($iconPath, [System.IO.FileMode]::Create)
    $icon.Save($fileStream)
    $fileStream.Close()
    $icon.Dispose()
    
    Write-Host "Icon created successfully!"
}
catch {
    Write-Error "Error creating icon: $_"
}
finally {
    # Clean up
    foreach ($bitmap in $bitmaps) {
        $bitmap.Dispose()
    }
    $sourceImage.Dispose()
    
    # Remove temp files
    foreach ($tempFile in $tempFiles) {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

Write-Host "Icon created at: $iconPath"
