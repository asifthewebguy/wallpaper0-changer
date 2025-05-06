# Register the wallpaper0-changer: protocol handler
# This script must be run with administrator privileges

# Get the full path to the application
$appPath = Join-Path -Path $PSScriptRoot -ChildPath "WallpaperChanger\bin\Release\net8.0-windows\WallpaperChanger.exe"

# Ensure the path exists
if (-not (Test-Path $appPath)) {
    Write-Error "Application not found at path: $appPath"
    Write-Error "Please build the application in Release mode first."
    exit 1
}

# Create the registry entries
$protocolName = "wallpaper0-changer"

# Create the protocol key
New-Item -Path "HKLM:\SOFTWARE\Classes\$protocolName" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName" -Name "(Default)" -Value "URL:Wallpaper Changer Protocol" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName" -Name "URL Protocol" -Value "" -Force

# Create the DefaultIcon key
New-Item -Path "HKLM:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Name "(Default)" -Value "$appPath,1" -Force

# Create the shell\open\command key
New-Item -Path "HKLM:\SOFTWARE\Classes\$protocolName\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$protocolName\shell\open\command" -Name "(Default)" -Value "`"$appPath`" `"%1`"" -Force

Write-Host "Protocol $protocolName has been registered successfully."
Write-Host "You can now use links like $protocolName:image_id to set wallpapers."
