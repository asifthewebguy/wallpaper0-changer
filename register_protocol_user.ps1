# Register the wallpaper0-changer: protocol handler for the current user only
# This script does NOT require administrator privileges

# Find the application executable
$releaseFolder = Join-Path -Path $PSScriptRoot -ChildPath "WallpaperChanger\bin\Release"
$exePath = $null

# Look for the executable in any .NET version folder
if (Test-Path $releaseFolder) {
    $netFolders = Get-ChildItem -Path $releaseFolder -Directory -Filter "net*-windows"

    if ($netFolders.Count -gt 0) {
        foreach ($folder in $netFolders) {
            $testPath = Join-Path -Path $folder.FullName -ChildPath "WallpaperChanger.exe"
            if (Test-Path $testPath) {
                $exePath = $testPath
                break
            }
        }
    }
}

# If not found, try to find it directly
if (-not $exePath) {
    $exeFiles = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter "WallpaperChanger.exe" -ErrorAction SilentlyContinue
    if ($exeFiles.Count -gt 0) {
        $exePath = $exeFiles[0].FullName
    }
}

# Set the application path
$appPath = $exePath

# Ensure the path exists
if (-not $appPath -or -not (Test-Path $appPath)) {
    Write-Error "Application not found. Please build the application in Release mode first."
    Write-Error "Expected path: $releaseFolder\net*-windows\WallpaperChanger.exe"
    exit 1
}

Write-Host "Found application at: $appPath"

# Create the registry entries
$protocolName = "wallpaper0-changer"

# Create the protocol key in HKCU (current user) instead of HKLM (local machine)
New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "(Default)" -Value "URL:Wallpaper Changer Protocol" -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "URL Protocol" -Value "" -Force

# Create the DefaultIcon key
New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Force | Out-Null
# Use the application's icon (0 is the first icon in the executable)
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Name "(Default)" -Value "$appPath,0" -Force

# Create the shell\open\command key
New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Name "(Default)" -Value "`"$appPath`" `"%1`"" -Force

Write-Host "Protocol $protocolName has been registered successfully for the current user."
Write-Host "You can now use links like $protocolName:image_id to set wallpapers."
Write-Host "You may need to restart your browser for the changes to take effect."
