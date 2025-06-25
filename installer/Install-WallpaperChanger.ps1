#Requires -Version 5.1

<#
.SYNOPSIS
    Enhanced Wallpaper Changer Installer

.DESCRIPTION
    This script provides a comprehensive installation experience for the Wallpaper Changer application.
    It supports both user-level and system-wide installations, creates shortcuts, registers protocol handlers,
    and includes proper error handling and logging.

.PARAMETER InstallDir
    Custom installation directory. Defaults to %LOCALAPPDATA%\WallpaperChanger for user install
    or %PROGRAMFILES%\WallpaperChanger for system install.

.PARAMETER SystemWide
    Install for all users (requires administrator privileges)

.PARAMETER Silent
    Run installation silently without user prompts

.PARAMETER CreateDesktopShortcut
    Create a desktop shortcut (default: true)

.PARAMETER CreateStartMenuShortcut
    Create a start menu shortcut (default: true)

.PARAMETER RegisterProtocol
    Register the wallpaper0-changer:// protocol handler (default: true)

.PARAMETER LogFile
    Path to log file for installation details

.EXAMPLE
    .\Install-WallpaperChanger.ps1
    Standard user installation with prompts

.EXAMPLE
    .\Install-WallpaperChanger.ps1 -SystemWide -Silent
    Silent system-wide installation (requires admin)

.EXAMPLE
    .\Install-WallpaperChanger.ps1 -InstallDir "C:\MyApps\WallpaperChanger" -CreateDesktopShortcut:$false
    Custom installation directory without desktop shortcut
#>

[CmdletBinding()]
param (
    [string]$InstallDir = "",
    [switch]$SystemWide = $false,
    [switch]$Silent = $false,
    [bool]$CreateDesktopShortcut = $true,
    [bool]$CreateStartMenuShortcut = $true,
    [bool]$RegisterProtocol = $true,
    [string]$LogFile = ""
)

# Script configuration
$script:AppName = "Wallpaper Changer"
$script:AppVersion = "1.1.0"
$script:ProtocolName = "wallpaper0-changer"
$script:PublisherName = "ATWG"
$script:AppDescription = "Desktop wallpaper changer with web protocol support"

# Initialize logging
if (-not $LogFile) {
    $LogFile = Join-Path $env:TEMP "WallpaperChanger-Install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
}

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    # Write to console if not silent
    if (-not $Silent) {
        switch ($Level) {
            "ERROR" { Write-Host $Message -ForegroundColor Red }
            "WARN"  { Write-Host $Message -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $Message -ForegroundColor Green }
            default { Write-Host $Message -ForegroundColor $Color }
        }
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-UserConfirmation {
    param (
        [string]$Message,
        [bool]$DefaultYes = $true
    )
    
    if ($Silent) {
        return $true
    }
    
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Proceed")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Cancel")
    )
    
    $defaultChoice = if ($DefaultYes) { 0 } else { 1 }
    $result = $host.UI.PromptForChoice("Confirmation", $Message, $choices, $defaultChoice)
    
    return $result -eq 0
}

function Find-ApplicationExecutable {
    # Look for the built application
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $parentDir = Split-Path -Parent $scriptDir
    
    # Check publish directory first (self-contained)
    $publishDir = Join-Path $parentDir "publish"
    if (Test-Path $publishDir) {
        $exePath = Join-Path $publishDir "WallpaperChanger.exe"
        if (Test-Path $exePath) {
            Write-Log "Found self-contained executable: $exePath"
            return $exePath
        }
    }
    
    # Check release build directory
    $releaseDir = Join-Path $parentDir "WallpaperChanger\bin\Release"
    if (Test-Path $releaseDir) {
        $netDirs = Get-ChildItem -Path $releaseDir -Directory -Filter "net*-windows"
        foreach ($netDir in $netDirs) {
            $exePath = Join-Path $netDir.FullName "WallpaperChanger.exe"
            if (Test-Path $exePath) {
                Write-Log "Found framework-dependent executable: $exePath"
                return $exePath
            }
        }
    }
    
    throw "Application executable not found. Please build the application first."
}

function New-InstallationDirectory {
    param ([string]$Path)
    
    try {
        if (-not (Test-Path $Path)) {
            Write-Log "Creating installation directory: $Path"
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
        
        # Test write permissions
        $testFile = Join-Path $Path "test.tmp"
        "test" | Out-File -FilePath $testFile -ErrorAction Stop
        Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
        
        return $true
    }
    catch {
        Write-Log "Failed to create or access directory: $Path - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Copy-ApplicationFiles {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    try {
        $sourceDir = Split-Path -Parent $SourcePath
        Write-Log "Copying application files from: $sourceDir"
        Write-Log "To: $DestinationPath"
        
        # Copy all files from source directory
        Copy-Item -Path "$sourceDir\*" -Destination $DestinationPath -Recurse -Force
        
        Write-Log "Application files copied successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to copy application files: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function New-Shortcut {
    param (
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$WorkingDirectory,
        [string]$Description,
        [string]$IconPath = ""
    )
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.WorkingDirectory = $WorkingDirectory
        $shortcut.Description = $Description
        
        if ($IconPath -and (Test-Path $IconPath)) {
            $shortcut.IconLocation = $IconPath
        }
        
        $shortcut.Save()
        Write-Log "Created shortcut: $ShortcutPath" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to create shortcut: $ShortcutPath - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main installation logic starts here
Write-Log "Starting $script:AppName v$script:AppVersion installation" "INFO" "Cyan"
Write-Log "Log file: $LogFile" "INFO" "Gray"

try {
    # Check prerequisites
    $isAdmin = Test-Administrator
    
    if ($SystemWide -and -not $isAdmin) {
        throw "System-wide installation requires administrator privileges. Please run as administrator or use user-level installation."
    }
    
    # Determine installation directory
    if (-not $InstallDir) {
        if ($SystemWide) {
            $InstallDir = Join-Path $env:ProgramFiles $script:AppName
        } else {
            $InstallDir = Join-Path $env:LOCALAPPDATA $script:AppName
        }
    }
    
    Write-Log "Installation type: $(if ($SystemWide) { 'System-wide' } else { 'User-level' })"
    Write-Log "Installation directory: $InstallDir"
    
    # Get user confirmation
    if (-not $Silent) {
        $confirmMessage = "Install $script:AppName to $InstallDir?"
        if (-not (Get-UserConfirmation $confirmMessage)) {
            Write-Log "Installation cancelled by user" "WARN"
            exit 0
        }
    }
    
    # Find application executable
    $sourceExePath = Find-ApplicationExecutable
    
    # Create installation directory
    if (-not (New-InstallationDirectory $InstallDir)) {
        throw "Failed to create installation directory"
    }
    
    # Copy application files
    if (-not (Copy-ApplicationFiles $sourceExePath $InstallDir)) {
        throw "Failed to copy application files"
    }
    
    $installedExePath = Join-Path $InstallDir "WallpaperChanger.exe"
    
    # Create shortcuts
    if ($CreateStartMenuShortcut) {
        $startMenuDir = if ($SystemWide) {
            Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs"
        } else {
            Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
        }
        
        $startMenuShortcut = Join-Path $startMenuDir "$script:AppName.lnk"
        $iconPath = Join-Path $InstallDir "Resources\wallpaper_icon.ico"
        
        New-Shortcut -ShortcutPath $startMenuShortcut -TargetPath $installedExePath -WorkingDirectory $InstallDir -Description $script:AppDescription -IconPath $iconPath
    }
    
    if ($CreateDesktopShortcut) {
        $desktopDir = if ($SystemWide) {
            Join-Path $env:PUBLIC "Desktop"
        } else {
            [Environment]::GetFolderPath("Desktop")
        }
        
        $desktopShortcut = Join-Path $desktopDir "$script:AppName.lnk"
        $iconPath = Join-Path $InstallDir "Resources\wallpaper_icon.ico"
        
        New-Shortcut -ShortcutPath $desktopShortcut -TargetPath $installedExePath -WorkingDirectory $InstallDir -Description $script:AppDescription -IconPath $iconPath
    }
    
    # Register protocol handler
    if ($RegisterProtocol) {
        try {
            Write-Log "Registering protocol handler: $script:ProtocolName"

            $registryRoot = if ($SystemWide) { "HKLM:\SOFTWARE\Classes" } else { "HKCU:\SOFTWARE\Classes" }
            $protocolKey = "$registryRoot\$script:ProtocolName"

            New-Item -Path $protocolKey -Force | Out-Null
            Set-ItemProperty -Path $protocolKey -Name "(Default)" -Value "URL:$script:AppName Protocol" -Force
            Set-ItemProperty -Path $protocolKey -Name "URL Protocol" -Value "" -Force

            New-Item -Path "$protocolKey\DefaultIcon" -Force | Out-Null
            Set-ItemProperty -Path "$protocolKey\DefaultIcon" -Name "(Default)" -Value "$installedExePath,0" -Force

            New-Item -Path "$protocolKey\shell\open\command" -Force | Out-Null
            Set-ItemProperty -Path "$protocolKey\shell\open\command" -Name "(Default)" -Value "`"$installedExePath`" `"%1`"" -Force

            Write-Log "Protocol handler registered successfully" "SUCCESS"
        }
        catch {
            Write-Log "Failed to register protocol handler: $($_.Exception.Message)" "WARN"
        }
    }

    # Create uninstaller
    try {
        $uninstallerPath = Join-Path $InstallDir "Uninstall.ps1"
        $uninstallerContent = @"
# $script:AppName Uninstaller
# Generated on $(Get-Date)

Write-Host "Uninstalling $script:AppName..." -ForegroundColor Cyan

# Remove protocol registration
if (Test-Path "HKCU:\SOFTWARE\Classes\$script:ProtocolName") {
    Remove-Item -Path "HKCU:\SOFTWARE\Classes\$script:ProtocolName" -Recurse -Force -ErrorAction SilentlyContinue
}

if (Test-Path "HKLM:\SOFTWARE\Classes\$script:ProtocolName") {
    try {
        Remove-Item -Path "HKLM:\SOFTWARE\Classes\$script:ProtocolName" -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Warning "Could not remove system-wide protocol registration. Run as administrator to remove completely."
    }
}

# Remove shortcuts
`$shortcuts = @(
    [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "$script:AppName.lnk"),
    [System.IO.Path]::Combine([Environment]::GetFolderPath("Programs"), "$script:AppName.lnk"),
    [System.IO.Path]::Combine(`$env:PUBLIC, "Desktop", "$script:AppName.lnk"),
    [System.IO.Path]::Combine(`$env:ProgramData, "Microsoft\Windows\Start Menu\Programs", "$script:AppName.lnk")
)

foreach (`$shortcut in `$shortcuts) {
    if (Test-Path `$shortcut) {
        Remove-Item -Path `$shortcut -Force -ErrorAction SilentlyContinue
        Write-Host "Removed shortcut: `$shortcut"
    }
}

# Remove installation directory
Write-Host "Removing installation directory..."
Start-Process cmd.exe -ArgumentList "/c timeout /t 2 /nobreak > nul & rd /s /q `"$InstallDir`"" -WindowStyle Hidden

Write-Host "$script:AppName has been uninstalled." -ForegroundColor Green
"@

        Set-Content -Path $uninstallerPath -Value $uninstallerContent -Force
        Write-Log "Created uninstaller: $uninstallerPath" "SUCCESS"
    }
    catch {
        Write-Log "Failed to create uninstaller: $($_.Exception.Message)" "WARN"
    }

    Write-Log "$script:AppName has been installed successfully!" "SUCCESS"
    Write-Log "Installation completed at: $(Get-Date)" "SUCCESS"

    if (-not $Silent) {
        Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
        Write-Host "- Application installed to: $InstallDir" -ForegroundColor Green
        Write-Host "- Start Menu shortcut: $(if ($CreateStartMenuShortcut) { 'Created' } else { 'Skipped' })" -ForegroundColor Green
        Write-Host "- Desktop shortcut: $(if ($CreateDesktopShortcut) { 'Created' } else { 'Skipped' })" -ForegroundColor Green
        Write-Host "- Protocol handler: $(if ($RegisterProtocol) { 'Registered' } else { 'Skipped' })" -ForegroundColor Green
        Write-Host "- Uninstaller: Created" -ForegroundColor Green
        Write-Host "- Log file: $LogFile" -ForegroundColor Gray

        if (Get-UserConfirmation "`nWould you like to start $script:AppName now?") {
            Start-Process -FilePath $installedExePath
        }
    }
}
catch {
    Write-Log "Installation failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
