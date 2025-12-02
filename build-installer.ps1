# Build Wallpaper Changer Installer using Inno Setup
# This script builds the application and creates an Inno Setup installer

param (
    [string]$Version = "1.1.0",
    [string]$Configuration = "Release",
    [switch]$SkipBuild = $false,
    [string]$InnoSetupPath = ""
)

# Function to write colored messages
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Function to find Inno Setup compiler
function Find-InnoSetup {
    $possiblePaths = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

# Main script
Write-ColorMessage "===== Wallpaper Changer Installer Builder =====" "Cyan"
Write-ColorMessage "Version: $Version" "Yellow"
Write-ColorMessage ""

# Check if Inno Setup is installed
if ([string]::IsNullOrEmpty($InnoSetupPath)) {
    Write-ColorMessage "Searching for Inno Setup..." "Yellow"
    $InnoSetupPath = Find-InnoSetup
}

if ([string]::IsNullOrEmpty($InnoSetupPath) -or -not (Test-Path $InnoSetupPath)) {
    Write-ColorMessage "ERROR: Inno Setup not found!" "Red"
    Write-ColorMessage "Please install Inno Setup 6 from: https://jrsoftware.org/isdl.php" "Yellow"
    Write-ColorMessage "Or specify the path using -InnoSetupPath parameter" "Yellow"
    exit 1
}

Write-ColorMessage "Found Inno Setup at: $InnoSetupPath" "Green"
Write-ColorMessage ""

# Build the application if not skipped
if (-not $SkipBuild) {
    Write-ColorMessage "Building application..." "Yellow"

    # Restore dependencies
    Write-ColorMessage "Restoring dependencies..." "Yellow"
    dotnet restore
    if ($LASTEXITCODE -ne 0) {
        Write-ColorMessage "ERROR: Failed to restore dependencies" "Red"
        exit 1
    }

    # Build the application (framework-dependent for testing)
    Write-ColorMessage "Building framework-dependent version..." "Yellow"
    dotnet build --no-restore --configuration $Configuration
    if ($LASTEXITCODE -ne 0) {
        Write-ColorMessage "ERROR: Build failed" "Red"
        exit 1
    }

    # Run tests
    Write-ColorMessage "Running tests..." "Yellow"
    dotnet test --no-build --verbosity normal --configuration $Configuration
    if ($LASTEXITCODE -ne 0) {
        Write-ColorMessage "WARNING: Tests failed" "Yellow"
    }

    # Publish self-contained version
    Write-ColorMessage "Publishing self-contained version..." "Yellow"
    dotnet publish WallpaperChanger `
        --configuration $Configuration `
        --self-contained true `
        --runtime win-x64 `
        --output publish `
        /p:PublishSingleFile=false `
        /p:IncludeNativeLibrariesForSelfExtract=true `
        /p:Version=$Version

    if ($LASTEXITCODE -ne 0) {
        Write-ColorMessage "ERROR: Publish failed" "Red"
        exit 1
    }

    Write-ColorMessage "Build completed successfully!" "Green"
    Write-ColorMessage ""
} else {
    Write-ColorMessage "Skipping build (using existing publish folder)" "Yellow"
    Write-ColorMessage ""
}

# Check if publish folder exists
if (-not (Test-Path "publish")) {
    Write-ColorMessage "ERROR: publish folder not found. Run without -SkipBuild to build the application first." "Red"
    exit 1
}

# Update version in Inno Setup script
Write-ColorMessage "Updating version in Inno Setup script..." "Yellow"
$issFile = "WallpaperChanger.iss"
$issContent = Get-Content $issFile -Raw

# Update version
$issContent = $issContent -replace '#define MyAppVersion ".*"', "#define MyAppVersion ""$Version"""

# Save updated script
Set-Content $issFile $issContent -NoNewline

Write-ColorMessage "Version updated to $Version" "Green"
Write-ColorMessage ""

# Create output directory
$outputDir = "installer\output\InnoSetup"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Build the installer
Write-ColorMessage "Building Inno Setup installer..." "Yellow"
Write-ColorMessage "This may take a few minutes..." "Gray"
Write-ColorMessage ""

& $InnoSetupPath $issFile

if ($LASTEXITCODE -ne 0) {
    Write-ColorMessage "ERROR: Installer build failed" "Red"
    exit 1
}

# Check if installer was created
$installerName = "WallpaperChanger-Setup-v$Version.exe"
$installerPath = Join-Path -Path $outputDir -ChildPath $installerName

if (Test-Path $installerPath) {
    Write-ColorMessage "SUCCESS! Installer created successfully!" "Green"
    Write-ColorMessage ""
    Write-ColorMessage "Installer location:" "Yellow"
    Write-ColorMessage $installerPath "Cyan"
    Write-ColorMessage ""

    # Get file size
    $fileSize = (Get-Item $installerPath).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-ColorMessage "Installer size: $fileSizeMB MB" "Gray"
    Write-ColorMessage ""

    # Show next steps
    Write-ColorMessage "Next steps:" "Yellow"
    Write-ColorMessage "1. Test the installer on a clean system" "White"
    Write-ColorMessage "2. (Optional) Code sign the installer for production release" "White"
    Write-ColorMessage "3. Upload to GitHub releases or distribute to users" "White"
    Write-ColorMessage ""

    # Ask if user wants to run the installer
    $response = Read-Host "Do you want to run the installer now? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-ColorMessage "Launching installer..." "Yellow"
        Start-Process -FilePath $installerPath
    }
} else {
    Write-ColorMessage "ERROR: Installer file not found at expected location" "Red"
    Write-ColorMessage "Expected: $installerPath" "Yellow"
    exit 1
}
