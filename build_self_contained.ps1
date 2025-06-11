# Build Self-Contained Wallpaper Changer
# This script builds the application as a self-contained deployment
# that doesn't require .NET runtime to be installed on the target machine

param (
    [string]$Configuration = "Release",
    [string]$Runtime = "win-x64",
    [switch]$Clean = $false
)

# Function to show a message with color
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

Write-ColorMessage "===== Building Self-Contained Wallpaper Changer =====" "Cyan"
Write-ColorMessage "Configuration: $Configuration" "Yellow"
Write-ColorMessage "Runtime: $Runtime" "Yellow"
Write-ColorMessage ""

# Clean if requested
if ($Clean) {
    Write-ColorMessage "Cleaning previous builds..." "Yellow"
    dotnet clean
    if ($LASTEXITCODE -ne 0) {
        Write-ColorMessage "Clean failed." "Red"
        exit 1
    }
}

# Restore packages
Write-ColorMessage "Restoring packages..." "Yellow"
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Write-ColorMessage "Package restore failed." "Red"
    exit 1
}

# Build the self-contained application
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

if (Test-Path $exePath) {
    $fileSize = (Get-Item $exePath).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    
    Write-ColorMessage "Build successful!" "Green"
    Write-ColorMessage "Self-contained executable: $exePath" "Green"
    Write-ColorMessage "File size: $fileSizeMB MB" "Green"
    Write-ColorMessage ""
    Write-ColorMessage "This executable can run on Windows machines without .NET runtime installed." "Cyan"
} else {
    Write-ColorMessage "Build completed but executable not found at expected location." "Red"
    exit 1
}
