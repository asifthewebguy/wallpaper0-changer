#Requires -Version 5.1

<#
.SYNOPSIS
    Build Windows Installer (MSI) for Wallpaper Changer

.DESCRIPTION
    This script builds a professional Windows Installer package using WiX Toolset.
    It requires WiX Toolset to be installed on the system.

.PARAMETER SourceDir
    Directory containing the built application files

.PARAMETER OutputDir
    Directory where the MSI file will be created

.PARAMETER Version
    Version number for the installer

.EXAMPLE
    .\Build-MSI.ps1 -SourceDir "..\WallpaperChanger\bin\Release\net9.0-windows" -OutputDir ".\output"
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
$script:WixToolsetPath = "${env:ProgramFiles(x86)}\WiX Toolset v3.11\bin"
$script:WixToolsetPath4 = "${env:ProgramFiles}\dotnet\tools"
$script:ProjectName = "WallpaperChanger"

function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-WixToolset {
    # Check for WiX 3.x
    $candle3 = Join-Path $script:WixToolsetPath "candle.exe"
    $light3 = Join-Path $script:WixToolsetPath "light.exe"
    
    if ((Test-Path $candle3) -and (Test-Path $light3)) {
        Write-ColorMessage "Found WiX Toolset 3.x at: $script:WixToolsetPath" "Green"
        return @{
            Version = "3.x"
            CandlePath = $candle3
            LightPath = $light3
        }
    }
    
    # Check for WiX 4.x (dotnet tool)
    try {
        $wixOutput = & dotnet wix --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "Found WiX Toolset 4.x (dotnet tool)" "Green"
            return @{
                Version = "4.x"
                CandlePath = "dotnet"
                LightPath = "dotnet"
            }
        }
    }
    catch {
        # WiX 4.x not found
    }
    
    return $null
}

function Install-WixToolset {
    Write-ColorMessage "WiX Toolset not found. You can install it using one of these methods:" "Yellow"
    Write-ColorMessage ""
    Write-ColorMessage "Option 1 - Install WiX 4.x as .NET tool (Recommended):" "Cyan"
    Write-ColorMessage "  dotnet tool install --global wix" "White"
    Write-ColorMessage ""
    Write-ColorMessage "Option 2 - Download WiX 3.x from:" "Cyan"
    Write-ColorMessage "  https://github.com/wixtoolset/wix3/releases" "White"
    Write-ColorMessage ""
    
    $install = Read-Host "Would you like to install WiX 4.x now? (y/n)"
    if ($install -eq 'y' -or $install -eq 'Y') {
        Write-ColorMessage "Installing WiX 4.x..." "Yellow"
        & dotnet tool install --global wix
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "WiX 4.x installed successfully!" "Green"
            return Test-WixToolset
        } else {
            Write-ColorMessage "Failed to install WiX 4.x" "Red"
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

function New-LicenseFile {
    $licenseContent = @"
{\rtf1\ansi\deff0 {\fonttbl {\f0 Times New Roman;}}
\f0\fs24
Wallpaper Changer License Agreement

Copyright (c) 2024 ATWG

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}
"@
    
    $licenseFile = Join-Path (Split-Path -Parent $MyInvocation.ScriptName) "license.rtf"
    Set-Content -Path $licenseFile -Value $licenseContent -Encoding ASCII
    return $licenseFile
}

function Build-WixInstaller {
    param (
        [hashtable]$WixInfo,
        [string]$SourceDirectory,
        [string]$OutputDirectory
    )
    
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $wxsFile = Join-Path $scriptDir "WallpaperChanger.wxs"
    $wixObjFile = Join-Path $OutputDirectory "WallpaperChanger.wixobj"
    $msiFile = Join-Path $OutputDirectory "WallpaperChanger-v$Version.msi"
    
    # Create output directory
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Create license file
    $licenseFile = New-LicenseFile
    
    try {
        if ($WixInfo.Version -eq "4.x") {
            # WiX 4.x build process
            Write-ColorMessage "Building with WiX 4.x..." "Yellow"
            
            & dotnet wix build $wxsFile -o $msiFile -d "SourceDir=$SourceDirectory" -d "Version=$Version"
            
            if ($LASTEXITCODE -ne 0) {
                throw "WiX build failed"
            }
        } else {
            # WiX 3.x build process
            Write-ColorMessage "Compiling WiX source..." "Yellow"
            
            & $WixInfo.CandlePath -dSourceDir="$SourceDirectory" -dVersion="$Version" -out $wixObjFile $wxsFile
            
            if ($LASTEXITCODE -ne 0) {
                throw "Candle compilation failed"
            }
            
            Write-ColorMessage "Linking MSI package..." "Yellow"
            
            & $WixInfo.LightPath -out $msiFile $wixObjFile -ext WixUIExtension
            
            if ($LASTEXITCODE -ne 0) {
                throw "Light linking failed"
            }
        }
        
        Write-ColorMessage "MSI package created successfully!" "Green"
        Write-ColorMessage "Output: $msiFile" "Green"
        
        # Get file size
        $fileInfo = Get-Item $msiFile
        $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
        Write-ColorMessage "Size: $sizeInMB MB" "Gray"
        
        return $msiFile
    }
    finally {
        # Clean up temporary files
        if (Test-Path $wixObjFile) {
            Remove-Item $wixObjFile -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $licenseFile) {
            Remove-Item $licenseFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main execution
try {
    Write-ColorMessage "=== Wallpaper Changer MSI Builder ===" "Cyan"
    
    # Check for WiX Toolset
    $wixInfo = Test-WixToolset
    if (-not $wixInfo) {
        $wixInfo = Install-WixToolset
        if (-not $wixInfo) {
            throw "WiX Toolset is required to build MSI packages"
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
    
    # Build the installer
    $msiPath = Build-WixInstaller -WixInfo $wixInfo -SourceDirectory $sourceDirectory -OutputDirectory $OutputDir
    
    Write-ColorMessage "`nBuild completed successfully!" "Green"
    Write-ColorMessage "MSI installer: $msiPath" "Green"
}
catch {
    Write-ColorMessage "Build failed: $($_.Exception.Message)" "Red"
    exit 1
}
