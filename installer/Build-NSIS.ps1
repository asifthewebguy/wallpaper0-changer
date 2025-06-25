#Requires -Version 5.1

<#
.SYNOPSIS
    Build NSIS installer for Wallpaper Changer

.DESCRIPTION
    This script builds a lightweight installer using NSIS (Nullsoft Scriptable Install System).
    It requires NSIS to be installed on the system.

.PARAMETER SourceDir
    Directory containing the built application files

.PARAMETER OutputDir
    Directory where the installer will be created

.PARAMETER Version
    Version number for the installer

.EXAMPLE
    .\Build-NSIS.ps1 -SourceDir "..\WallpaperChanger\bin\Release\net9.0-windows" -OutputDir ".\output"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceDir = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\output",
    
    [Parameter(Mandatory = $false)]
    [string]$Version = "1.1.0"
)

# Configuration
$script:NSISPath = "${env:ProgramFiles(x86)}\NSIS"
$script:NSISPath64 = "${env:ProgramFiles}\NSIS"
$script:ProjectName = "WallpaperChanger"

function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-NSISInstallation {
    # Check for NSIS in Program Files (x86)
    $makensis32 = Join-Path $script:NSISPath "makensis.exe"
    if (Test-Path $makensis32) {
        Write-ColorMessage "Found NSIS at: $script:NSISPath" "Green"
        return $makensis32
    }
    
    # Check for NSIS in Program Files
    $makensis64 = Join-Path $script:NSISPath64 "makensis.exe"
    if (Test-Path $makensis64) {
        Write-ColorMessage "Found NSIS at: $script:NSISPath64" "Green"
        return $makensis64
    }
    
    return $null
}

function Install-NSIS {
    Write-ColorMessage "NSIS not found. You can download it from:" "Yellow"
    Write-ColorMessage "https://nsis.sourceforge.io/Download" "White"
    Write-ColorMessage ""
    Write-ColorMessage "Or install using Chocolatey:" "Cyan"
    Write-ColorMessage "  choco install nsis" "White"
    Write-ColorMessage ""
    Write-ColorMessage "Or install using winget:" "Cyan"
    Write-ColorMessage "  winget install NSIS.NSIS" "White"
    Write-ColorMessage ""
    
    $install = Read-Host "Would you like to install NSIS using winget now? (y/n)"
    if ($install -eq 'y' -or $install -eq 'Y') {
        Write-ColorMessage "Installing NSIS..." "Yellow"
        & winget install NSIS.NSIS
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "NSIS installed successfully!" "Green"
            # Refresh PATH
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            return Test-NSISInstallation
        } else {
            Write-ColorMessage "Failed to install NSIS" "Red"
            return $null
        }
    }
    
    return $null
}

function Find-SourceDirectory {
    if ($SourceDir -and (Test-Path $SourceDir)) {
        return $SourceDir
    }
    
    # Look for built application
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $parentDir = Split-Path -Parent $scriptDir
    
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

function New-NSISBuildDirectory {
    param (
        [string]$SourceDirectory,
        [string]$BuildDirectory
    )
    
    # Create build directory
    if (Test-Path $BuildDirectory) {
        Remove-Item -Path $BuildDirectory -Recurse -Force
    }
    New-Item -Path $BuildDirectory -ItemType Directory -Force | Out-Null
    
    # Copy application files
    Copy-Item -Path "$SourceDirectory\*" -Destination $BuildDirectory -Recurse -Force
    
    # Create license file
    $licenseContent = @"
Wallpaper Changer License Agreement

Copyright (c) 2024 ATWG

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"@
    
    $licenseFile = Join-Path $BuildDirectory "license.txt"
    Set-Content -Path $licenseFile -Value $licenseContent -Encoding UTF8
    
    # Copy icon file to build directory root for NSIS
    $iconSource = Join-Path $BuildDirectory "Resources\wallpaper_icon.ico"
    $iconDest = Join-Path $BuildDirectory "wallpaper_icon.ico"
    if (Test-Path $iconSource) {
        Copy-Item -Path $iconSource -Destination $iconDest -Force
    }
    
    return $BuildDirectory
}

function Build-NSISInstaller {
    param (
        [string]$MakeNSISPath,
        [string]$BuildDirectory,
        [string]$OutputDirectory
    )
    
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $nsiFile = Join-Path $scriptDir "WallpaperChanger.nsi"
    $outputFile = Join-Path $OutputDirectory "WallpaperChanger-Setup-v$Version.exe"
    
    # Create output directory
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Update NSI file with current version and paths
    $nsiContent = Get-Content $nsiFile -Raw
    $nsiContent = $nsiContent -replace 'OutFile ".*"', "OutFile `"$outputFile`""
    $nsiContent = $nsiContent -replace 'VIProductVersion ".*"', "VIProductVersion `"$Version.0`""
    $nsiContent = $nsiContent -replace 'FileVersion" ".*"', "FileVersion`" `"$Version.0`""
    $nsiContent = $nsiContent -replace 'ProductVersion" ".*"', "ProductVersion`" `"$Version.0`""
    $nsiContent = $nsiContent -replace 'DisplayVersion" ".*"', "DisplayVersion`" `"$Version`""
    
    $tempNsiFile = Join-Path $BuildDirectory "WallpaperChanger_temp.nsi"
    Set-Content -Path $tempNsiFile -Value $nsiContent -Encoding UTF8
    
    try {
        Write-ColorMessage "Building NSIS installer..." "Yellow"
        
        # Change to build directory so relative paths work
        Push-Location $BuildDirectory
        
        # Run makensis
        $arguments = @(
            "/V2"  # Verbosity level
            $tempNsiFile
        )
        
        & $MakeNSISPath @arguments
        
        if ($LASTEXITCODE -ne 0) {
            throw "NSIS build failed with exit code $LASTEXITCODE"
        }
        
        Write-ColorMessage "NSIS installer created successfully!" "Green"
        Write-ColorMessage "Output: $outputFile" "Green"
        
        # Get file size
        if (Test-Path $outputFile) {
            $fileInfo = Get-Item $outputFile
            $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
            Write-ColorMessage "Size: $sizeInMB MB" "Gray"
        }
        
        return $outputFile
    }
    finally {
        Pop-Location
        
        # Clean up temporary file
        if (Test-Path $tempNsiFile) {
            Remove-Item $tempNsiFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main execution
try {
    Write-ColorMessage "=== Wallpaper Changer NSIS Builder ===" "Cyan"
    
    # Check for NSIS
    $makeNSISPath = Test-NSISInstallation
    if (-not $makeNSISPath) {
        $makeNSISPath = Install-NSIS
        if (-not $makeNSISPath) {
            throw "NSIS is required to build installers"
        }
    }
    
    # Find source directory
    $sourceDirectory = Find-SourceDirectory
    Write-ColorMessage "Source directory: $sourceDirectory" "Gray"
    
    # Validate required files
    $requiredFiles = @("WallpaperChanger.exe", "WallpaperChanger.dll")
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $sourceDirectory $file
        if (-not (Test-Path $filePath)) {
            throw "Required file not found: $filePath"
        }
    }
    
    # Create build directory
    $buildDirectory = Join-Path $OutputDir "nsis_build"
    $buildDirectory = New-NSISBuildDirectory -SourceDirectory $sourceDirectory -BuildDirectory $buildDirectory
    
    # Build the installer
    $installerPath = Build-NSISInstaller -MakeNSISPath $makeNSISPath -BuildDirectory $buildDirectory -OutputDirectory $OutputDir
    
    # Clean up build directory
    Remove-Item -Path $buildDirectory -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-ColorMessage "`nBuild completed successfully!" "Green"
    Write-ColorMessage "NSIS installer: $installerPath" "Green"
}
catch {
    Write-ColorMessage "Build failed: $($_.Exception.Message)" "Red"
    exit 1
}
