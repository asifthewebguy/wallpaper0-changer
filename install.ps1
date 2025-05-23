# Wallpaper Changer Installer Script
# This script builds the application, copies it to the installation directory,
# and registers the protocol handler.

param (
    [string]$InstallDir = "$env:LOCALAPPDATA\WallpaperChanger",
    [switch]$NoPrompt = $false
)

# Function to show a message with color
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Function to get user confirmation
function Get-UserConfirmation {
    param (
        [string]$Message,
        [bool]$DefaultYes = $true
    )
    
    if ($NoPrompt) {
        return $true
    }
    
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Proceed with the operation.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Cancel the operation.")
    )
    
    $defaultChoice = if ($DefaultYes) { 0 } else { 1 }
    
    $result = $host.UI.PromptForChoice("Confirmation", $Message, $choices, $defaultChoice)
    
    return $result -eq 0
}

# Show welcome message
Write-ColorMessage "===== Wallpaper Changer Installer =====" "Cyan"
Write-ColorMessage "This script will install the Wallpaper Changer application." "Cyan"
Write-ColorMessage "Installation directory: $InstallDir" "Yellow"
Write-ColorMessage ""

# Check if running as administrator for system-wide installation option
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Confirm installation
if (-not (Get-UserConfirmation "Do you want to continue with the installation?")) {
    Write-ColorMessage "Installation cancelled." "Red"
    exit
}

# Create installation directory if it doesn't exist
if (-not (Test-Path $InstallDir)) {
    Write-ColorMessage "Creating installation directory..." "Yellow"
    New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
}

# Build the application
Write-ColorMessage "Building the application..." "Yellow"
dotnet build -c Release

# Check if build was successful
if ($LASTEXITCODE -ne 0) {
    Write-ColorMessage "Build failed. Please check the error messages above." "Red"
    exit 1
}

# Find the built application
$releaseFolder = Join-Path -Path $PSScriptRoot -ChildPath "WallpaperChanger\bin\Release"
$netFolders = Get-ChildItem -Path $releaseFolder -Directory -Filter "net*-windows"

if ($netFolders.Count -eq 0) {
    Write-ColorMessage "Could not find the built application." "Red"
    exit 1
}

$sourceDir = $netFolders[0].FullName
Write-ColorMessage "Found application at: $sourceDir" "Green"

# Copy files to installation directory
Write-ColorMessage "Copying files to installation directory..." "Yellow"
Copy-Item -Path "$sourceDir\*" -Destination $InstallDir -Recurse -Force

# Create a shortcut in the Start Menu
$startMenuFolder = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs")
$shortcutPath = [System.IO.Path]::Combine($startMenuFolder, "Wallpaper Changer.lnk")

Write-ColorMessage "Creating Start Menu shortcut..." "Yellow"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = [System.IO.Path]::Combine($InstallDir, "WallpaperChanger.exe")
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description = "Wallpaper Changer Application"
$Shortcut.IconLocation = [System.IO.Path]::Combine($InstallDir, "Resources\wallpaper_icon.ico")
$Shortcut.Save()

# Register protocol handler
Write-ColorMessage "Registering protocol handler..." "Yellow"

$appPath = [System.IO.Path]::Combine($InstallDir, "WallpaperChanger.exe")
$protocolName = "wallpaper0-changer"

if ($isAdmin) {
    # Ask if user wants system-wide or user-only installation
    $systemWide = Get-UserConfirmation "Do you want to install the protocol handler system-wide? (Requires administrator privileges)" $false
    
    if ($systemWide) {
        # System-wide registration (HKLM)
        Write-ColorMessage "Registering protocol handler system-wide..." "Yellow"
        
        New-Item -Path "HKLM:\SOFTWARE\Classes\$protocolName" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName" -Name "(Default)" -Value "URL:Wallpaper Changer Protocol" -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName" -Name "URL Protocol" -Value "" -Force
        
        New-Item -Path "HKLM:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Name "(Default)" -Value "$appPath,0" -Force
        
        New-Item -Path "HKLM:\SOFTWARE\Classes\$protocolName\shell\open\command" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName\shell\open\command" -Name "(Default)" -Value "`"$appPath`" `"%1`"" -Force
    } else {
        # User-only registration (HKCU)
        Write-ColorMessage "Registering protocol handler for current user only..." "Yellow"
        
        New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "(Default)" -Value "URL:Wallpaper Changer Protocol" -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "URL Protocol" -Value "" -Force
        
        New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Name "(Default)" -Value "$appPath,0" -Force
        
        New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Name "(Default)" -Value "`"$appPath`" `"%1`"" -Force
    }
} else {
    # User-only registration (HKCU)
    Write-ColorMessage "Registering protocol handler for current user only..." "Yellow"
    
    New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "(Default)" -Value "URL:Wallpaper Changer Protocol" -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "URL Protocol" -Value "" -Force
    
    New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Name "(Default)" -Value "$appPath,0" -Force
    
    New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Name "(Default)" -Value "`"$appPath`" `"%1`"" -Force
    
    Write-ColorMessage "Note: To install system-wide, run this script as Administrator." "Yellow"
}

# Create an uninstaller
$uninstallerPath = Join-Path -Path $InstallDir -ChildPath "uninstall.ps1"
$uninstallerContent = @"
# Wallpaper Changer Uninstaller
Write-Host "Uninstalling Wallpaper Changer..." -ForegroundColor Cyan

# Remove protocol registration
`$protocolName = "wallpaper0-changer"
if (Test-Path "HKCU:\SOFTWARE\Classes\`$protocolName") {
    Write-Host "Removing protocol registration for current user..." -ForegroundColor Yellow
    Remove-Item -Path "HKCU:\SOFTWARE\Classes\`$protocolName" -Recurse -Force
}

# Check if we can access HKLM (admin rights)
`$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (`$isAdmin) {
    if (Test-Path "HKLM:\SOFTWARE\Classes\`$protocolName") {
        Write-Host "Removing system-wide protocol registration..." -ForegroundColor Yellow
        Remove-Item -Path "HKLM:\SOFTWARE\Classes\`$protocolName" -Recurse -Force
    }
}

# Remove Start Menu shortcut
`$startMenuShortcut = [System.IO.Path]::Combine(`$env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Wallpaper Changer.lnk")
if (Test-Path `$startMenuShortcut) {
    Write-Host "Removing Start Menu shortcut..." -ForegroundColor Yellow
    Remove-Item -Path `$startMenuShortcut -Force
}

# Remove installation directory
`$installDir = "$InstallDir"
if (Test-Path `$installDir) {
    Write-Host "Removing installation directory..." -ForegroundColor Yellow
    # Use cmd.exe to delete the directory after the script exits
    Start-Process cmd.exe -ArgumentList "/c timeout /t 2 /nobreak > nul & rd /s /q `"`$installDir`"" -WindowStyle Hidden
}

Write-Host "Wallpaper Changer has been uninstalled." -ForegroundColor Green
"@

Write-ColorMessage "Creating uninstaller..." "Yellow"
Set-Content -Path $uninstallerPath -Value $uninstallerContent -Force

# Create a test HTML file
$testHtmlPath = Join-Path -Path $InstallDir -ChildPath "test_protocol.html"
$testHtmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Wallpaper Changer Protocol Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        h1 {
            color: #333;
        }
        .button {
            display: inline-block;
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            text-align: center;
            text-decoration: none;
            font-size: 16px;
            margin: 4px 2px;
            cursor: pointer;
            border-radius: 4px;
        }
        .note {
            background-color: #f8f9fa;
            border-left: 6px solid #2196F3;
            padding: 10px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>Wallpaper Changer Protocol Test</h1>
    
    <p>Click the button below to test the wallpaper0-changer protocol:</p>
    
    <p><a href="wallpaper0-changer:test" class="button">Test Protocol</a></p>
    
    <div class="note">
        <p><strong>Note:</strong> This will attempt to launch the Wallpaper Changer application. If it doesn't work, make sure the protocol handler is properly registered.</p>
    </div>
    
    <p>You can also test with specific image IDs from aiwp.me:</p>
    
    <p><a href="wallpaper0-changer:1" class="button">Set Wallpaper ID 1</a></p>
    <p><a href="wallpaper0-changer:2" class="button">Set Wallpaper ID 2</a></p>
    <p><a href="wallpaper0-changer:3" class="button">Set Wallpaper ID 3</a></p>
</body>
</html>
"@

Write-ColorMessage "Creating test HTML file..." "Yellow"
Set-Content -Path $testHtmlPath -Value $testHtmlContent -Force

# Installation complete
Write-ColorMessage "Installation complete!" "Green"
Write-ColorMessage "The application has been installed to: $InstallDir" "Green"
Write-ColorMessage "A shortcut has been added to the Start Menu." "Green"
Write-ColorMessage "The protocol handler has been registered." "Green"
Write-ColorMessage ""
Write-ColorMessage "To test the protocol handler, open the test HTML file:" "Yellow"
Write-ColorMessage "$testHtmlPath" "Yellow"
Write-ColorMessage ""
Write-ColorMessage "To uninstall, run the uninstaller script:" "Yellow"
Write-ColorMessage "$uninstallerPath" "Yellow"

# Ask if user wants to run the application now
if (Get-UserConfirmation "Do you want to run the application now?") {
    Write-ColorMessage "Starting Wallpaper Changer..." "Yellow"
    Start-Process -FilePath $appPath
}
