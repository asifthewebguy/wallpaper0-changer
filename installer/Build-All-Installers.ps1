#Requires -Version 5.1

<#
.SYNOPSIS
    Master build script for all Wallpaper Changer installers

.DESCRIPTION
    This script builds all available installer types for the Wallpaper Changer application:
    - Enhanced PowerShell installer
    - Windows Installer (MSI) using WiX Toolset
    - NSIS installer
    - Batch file installer

.PARAMETER SourceDir
    Directory containing the built application files

.PARAMETER OutputDir
    Directory where all installers will be created

.PARAMETER Version
    Version number for the installers

.PARAMETER BuildTypes
    Comma-separated list of installer types to build: PowerShell,MSI,NSIS,Batch,All

.EXAMPLE
    .\Build-All-Installers.ps1
    Build all installer types using default settings

.EXAMPLE
    .\Build-All-Installers.ps1 -BuildTypes "PowerShell,NSIS" -Version "1.2.0"
    Build only PowerShell and NSIS installers with version 1.2.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceDir = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\output",
    
    [Parameter(Mandatory = $false)]
    [string]$Version = "1.1.0",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("PowerShell", "MSI", "NSIS", "Batch", "All")]
    [string[]]$BuildTypes = @("All")
)

# Script configuration
$script:ScriptDir = if ($MyInvocation.ScriptName) {
    Split-Path -Parent $MyInvocation.ScriptName
} else {
    $PSScriptRoot
}
$script:ProjectName = "WallpaperChanger"
$script:BuildResults = @()

function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Section {
    param ([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Find-SourceDirectory {
    if ($SourceDir -and (Test-Path $SourceDir)) {
        return $SourceDir
    }
    
    # Look for built application
    $parentDir = Split-Path -Parent $script:ScriptDir
    
    # Check publish directory first (self-contained)
    $publishDir = Join-Path $parentDir "publish"
    if (Test-Path $publishDir) {
        $exePath = Join-Path $publishDir "WallpaperChanger.exe"
        if (Test-Path $exePath) {
            Write-ColorMessage "Found application in publish directory: $publishDir" "Green"
            return $publishDir
        }
    }
    
    # Check release build directory
    $releaseDir = Join-Path $parentDir "WallpaperChanger\bin\Release"
    if (Test-Path $releaseDir) {
        $netDirs = Get-ChildItem -Path $releaseDir -Directory -Filter "net*-windows"
        foreach ($netDir in $netDirs) {
            $exePath = Join-Path $netDir.FullName "WallpaperChanger.exe"
            if (Test-Path $exePath) {
                Write-ColorMessage "Found application in release directory: $($netDir.FullName)" "Green"
                return $netDir.FullName
            }
        }
    }
    
    throw "Could not find built application. Please build the application first or specify -SourceDir parameter."
}

function Test-Prerequisites {
    param ([string]$SourceDirectory)
    
    Write-ColorMessage "Validating prerequisites..." "Yellow"
    
    # Check required files
    $requiredFiles = @("WallpaperChanger.exe", "WallpaperChanger.dll")
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $SourceDirectory $file
        if (-not (Test-Path $filePath)) {
            throw "Required file not found: $filePath"
        }
    }
    
    # Check icon file
    $iconPath = Join-Path $SourceDirectory "Resources\wallpaper_icon.ico"
    if (-not (Test-Path $iconPath)) {
        Write-ColorMessage "Warning: Icon file not found at $iconPath" "Yellow"
    }
    
    Write-ColorMessage "Prerequisites validated successfully" "Green"
}

function Build-PowerShellInstaller {
    param (
        [string]$SourceDirectory,
        [string]$OutputDirectory
    )
    
    try {
        Write-ColorMessage "Building Enhanced PowerShell Installer..." "Yellow"
        
        $installerScript = Join-Path $script:ScriptDir "Install-WallpaperChanger.ps1"
        $outputFile = Join-Path $OutputDirectory "Install-WallpaperChanger.ps1"
        
        # Copy the installer script to output directory
        Copy-Item -Path $installerScript -Destination $outputFile -Force
        
        # Create a package with the installer and application files
        $packageDir = Join-Path $OutputDirectory "PowerShell-Package"
        if (Test-Path $packageDir) {
            Remove-Item -Path $packageDir -Recurse -Force
        }
        New-Item -Path $packageDir -ItemType Directory -Force | Out-Null
        
        # Copy installer script
        Copy-Item -Path $installerScript -Destination $packageDir -Force
        
        # Copy application files
        $appDir = Join-Path $packageDir "app"
        New-Item -Path $appDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$SourceDirectory\*" -Destination $appDir -Recurse -Force
        
        # Create README
        $readmeContent = @"
# Wallpaper Changer PowerShell Installer Package

## Installation Instructions

1. Right-click on 'Install-WallpaperChanger.ps1' and select "Run with PowerShell"
   OR
   Open PowerShell as Administrator and run:
   .\Install-WallpaperChanger.ps1

## Installation Options

- **User Installation**: .\Install-WallpaperChanger.ps1
- **System-wide Installation**: .\Install-WallpaperChanger.ps1 -SystemWide (requires admin)
- **Silent Installation**: .\Install-WallpaperChanger.ps1 -Silent
- **Custom Directory**: .\Install-WallpaperChanger.ps1 -InstallDir "C:\MyApps\WallpaperChanger"

## Features

- Automatic application detection
- User-level or system-wide installation
- Start Menu and Desktop shortcuts
- Protocol handler registration
- Comprehensive logging
- Built-in uninstaller

Version: $Version
"@
        
        Set-Content -Path (Join-Path $packageDir "README.md") -Value $readmeContent -Encoding UTF8
        
        # Create ZIP package
        $zipFile = Join-Path (Resolve-Path $OutputDirectory) "WallpaperChanger-PowerShell-v$Version.zip"
        if (Test-Path $zipFile) {
            Remove-Item $zipFile -Force
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($packageDir, $zipFile)
        
        # Clean up temp directory
        Remove-Item -Path $packageDir -Recurse -Force
        
        Write-ColorMessage "PowerShell installer created: $zipFile" "Green"
        return @{
            Type = "PowerShell"
            Path = $zipFile
            Success = $true
            Size = [math]::Round((Get-Item $zipFile).Length / 1MB, 2)
        }
    }
    catch {
        Write-ColorMessage "PowerShell installer build failed: $($_.Exception.Message)" "Red"
        return @{
            Type = "PowerShell"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Build-MSIInstaller {
    param (
        [string]$SourceDirectory,
        [string]$OutputDirectory
    )
    
    try {
        Write-ColorMessage "Building MSI Installer..." "Yellow"
        
        $buildScript = Join-Path $script:ScriptDir "Build-MSI.ps1"
        if (-not (Test-Path $buildScript)) {
            throw "Build-MSI.ps1 script not found"
        }
        
        & $buildScript -SourceDir $SourceDirectory -OutputDir $OutputDirectory -Version $Version
        
        if ($LASTEXITCODE -eq 0) {
            $msiFile = Join-Path $OutputDirectory "WallpaperChanger-v$Version.msi"
            if (Test-Path $msiFile) {
                Write-ColorMessage "MSI installer created: $msiFile" "Green"
                return @{
                    Type = "MSI"
                    Path = $msiFile
                    Success = $true
                    Size = [math]::Round((Get-Item $msiFile).Length / 1MB, 2)
                }
            }
        }
        
        throw "MSI build completed but output file not found"
    }
    catch {
        Write-ColorMessage "MSI installer build failed: $($_.Exception.Message)" "Red"
        return @{
            Type = "MSI"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Build-NSISInstaller {
    param (
        [string]$SourceDirectory,
        [string]$OutputDirectory
    )
    
    try {
        Write-ColorMessage "Building NSIS Installer..." "Yellow"
        
        $buildScript = Join-Path $script:ScriptDir "Build-NSIS.ps1"
        if (-not (Test-Path $buildScript)) {
            throw "Build-NSIS.ps1 script not found"
        }
        
        & $buildScript -SourceDir $SourceDirectory -OutputDir $OutputDirectory -Version $Version
        
        if ($LASTEXITCODE -eq 0) {
            $nsisFile = Join-Path $OutputDirectory "WallpaperChanger-Setup-v$Version.exe"
            if (Test-Path $nsisFile) {
                Write-ColorMessage "NSIS installer created: $nsisFile" "Green"
                return @{
                    Type = "NSIS"
                    Path = $nsisFile
                    Success = $true
                    Size = [math]::Round((Get-Item $nsisFile).Length / 1MB, 2)
                }
            }
        }
        
        throw "NSIS build completed but output file not found"
    }
    catch {
        Write-ColorMessage "NSIS installer build failed: $($_.Exception.Message)" "Red"
        return @{
            Type = "NSIS"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Build-BatchInstaller {
    param (
        [string]$SourceDirectory,
        [string]$OutputDirectory
    )
    
    try {
        Write-ColorMessage "Building Batch Installer..." "Yellow"
        
        $batchScript = Join-Path $script:ScriptDir "install.bat"
        $outputFile = Join-Path $OutputDirectory "install.bat"
        
        # Copy the batch installer
        Copy-Item -Path $batchScript -Destination $outputFile -Force
        
        # Create a package with the installer and application files
        $packageDir = Join-Path $OutputDirectory "Batch-Package"
        if (Test-Path $packageDir) {
            Remove-Item -Path $packageDir -Recurse -Force
        }
        New-Item -Path $packageDir -ItemType Directory -Force | Out-Null
        
        # Copy installer script
        Copy-Item -Path $batchScript -Destination $packageDir -Force
        
        # Copy application files
        $appDir = Join-Path $packageDir "app"
        New-Item -Path $appDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$SourceDirectory\*" -Destination $appDir -Recurse -Force
        
        # Create README
        $readmeContent = @"
# Wallpaper Changer Batch Installer Package

## Installation Instructions

1. Right-click on 'install.bat' and select "Run as administrator" (for system-wide installation)
   OR
   Double-click 'install.bat' for user-level installation

## Features

- Automatic application detection
- User-level or system-wide installation (based on admin privileges)
- Start Menu and Desktop shortcuts
- Protocol handler registration
- Built-in uninstaller
- Simple and lightweight

Version: $Version
"@
        
        Set-Content -Path (Join-Path $packageDir "README.txt") -Value $readmeContent -Encoding UTF8
        
        # Create ZIP package
        $zipFile = Join-Path (Resolve-Path $OutputDirectory) "WallpaperChanger-Batch-v$Version.zip"
        if (Test-Path $zipFile) {
            Remove-Item $zipFile -Force
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($packageDir, $zipFile)
        
        # Clean up temp directory
        Remove-Item -Path $packageDir -Recurse -Force
        
        Write-ColorMessage "Batch installer created: $zipFile" "Green"
        return @{
            Type = "Batch"
            Path = $zipFile
            Success = $true
            Size = [math]::Round((Get-Item $zipFile).Length / 1MB, 2)
        }
    }
    catch {
        Write-ColorMessage "Batch installer build failed: $($_.Exception.Message)" "Red"
        return @{
            Type = "Batch"
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Main execution
try {
    Write-Section "Wallpaper Changer Installer Builder v$Version"
    
    # Determine which installers to build
    if ($BuildTypes -contains "All") {
        $BuildTypes = @("PowerShell", "MSI", "NSIS", "Batch")
    }
    
    Write-ColorMessage "Building installer types: $($BuildTypes -join ', ')" "Cyan"
    
    # Find source directory
    $sourceDirectory = Find-SourceDirectory
    Write-ColorMessage "Source directory: $sourceDirectory" "Gray"
    
    # Validate prerequisites
    Test-Prerequisites -SourceDirectory $sourceDirectory
    
    # Create output directory
    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    Write-ColorMessage "Output directory: $OutputDir" "Gray"
    
    # Build each installer type
    foreach ($buildType in $BuildTypes) {
        Write-Section "Building $buildType Installer"
        
        switch ($buildType) {
            "PowerShell" { $result = Build-PowerShellInstaller -SourceDirectory $sourceDirectory -OutputDirectory $OutputDir }
            "MSI"        { $result = Build-MSIInstaller -SourceDirectory $sourceDirectory -OutputDirectory $OutputDir }
            "NSIS"       { $result = Build-NSISInstaller -SourceDirectory $sourceDirectory -OutputDirectory $OutputDir }
            "Batch"      { $result = Build-BatchInstaller -SourceDirectory $sourceDirectory -OutputDirectory $OutputDir }
        }
        
        $script:BuildResults += $result
    }
    
    # Summary
    Write-Section "Build Summary"
    
    $successCount = ($script:BuildResults | Where-Object { $_.Success }).Count
    $totalCount = $script:BuildResults.Count
    
    Write-ColorMessage "Successfully built $successCount of $totalCount installers" "Cyan"
    Write-Host ""
    
    foreach ($result in $script:BuildResults) {
        if ($result.Success) {
            Write-ColorMessage "✓ $($result.Type): $($result.Path) ($($result.Size) MB)" "Green"
        } else {
            Write-ColorMessage "✗ $($result.Type): $($result.Error)" "Red"
        }
    }
    
    if ($successCount -gt 0) {
        Write-Host ""
        Write-ColorMessage "All installers are available in: $OutputDir" "Green"
    }
}
catch {
    Write-ColorMessage "Build process failed: $($_.Exception.Message)" "Red"
    exit 1
}
