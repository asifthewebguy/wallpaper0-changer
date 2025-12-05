$appPath = "e:\ag-projects\wallpaper0-changer\WallpaperChanger\bin\Debug\net9.0-windows\WallpaperChanger.exe"
$protocolName = "wallpaper0-changer"

Write-Host "Registering $protocolName for $appPath"

# Force create keys
New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "(Default)" -Value "URL:Wallpaper Changer Protocol" -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName" -Name "URL Protocol" -Value "" -Force

New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\DefaultIcon" -Name "(Default)" -Value "$appPath,0" -Force

New-Item -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\$protocolName\shell\open\command" -Name "(Default)" -Value "`"$appPath`" `"%1`"" -Force

Write-Host "Done."
