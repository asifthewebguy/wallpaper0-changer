# Register the wallpaper0-changer URL protocol
# This script must be run as administrator

# Get the current directory
$currentDir = (Get-Location).Path
Write-Host "Current directory: $currentDir"

# Create the registry entries
Write-Host "Creating registry entries..."

# Create the main protocol key
New-Item -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer" -Name "(Default)" -Value "URL:Wallpaper Changer Protocol"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer" -Name "URL Protocol" -Value ""

# Create the DefaultIcon key
New-Item -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer\DefaultIcon" -Name "(Default)" -Value "$currentDir\run.bat,0"

# Create the shell\open\command key
New-Item -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer\shell\open\command" -Force | Out-Null

# Create the command that will be executed when the protocol is invoked
$command = "cmd.exe /c `"cd /d `"$currentDir`" && python main.py `"%1`"`""
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer\shell\open\command" -Name "(Default)" -Value $command

# Verify the registry entries
Write-Host "Verifying registry entries..."
Get-ItemProperty -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer"
Get-ItemProperty -Path "HKLM:\SOFTWARE\Classes\wallpaper0-changer\shell\open\command"

Write-Host "URL Protocol registration complete!"
Write-Host "You can now use links like: wallpaper0-changer:005TN27O78.png"

# Create a test HTML file
Write-Host "Creating test HTML file..."
$testHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Wallpaper Changer URL Protocol</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
        h1 { color: #4a6984; }
        a { display: inline-block; background-color: #4a6984; color: white; padding: 10px 15px; 
            text-decoration: none; margin: 5px; border-radius: 4px; }
        a:hover { background-color: #3a5874; }
    </style>
</head>
<body>
    <h1>Test Wallpaper Changer URL Protocol</h1>
    <p>Click on a link below to test the URL protocol:</p>
    <p>
        <a href="wallpaper0-changer:005TN27O78.png">Set Wallpaper 1</a>
        <a href="wallpaper0-changer:022DNLE6U1.png">Set Wallpaper 2</a>
        <a href="wallpaper0-changer:02FRCLAUKC.jpg">Set Wallpaper 3</a>
        <a href="wallpaper0-changer:03RBW0BRFO.png">Set Wallpaper 4</a>
    </p>
</body>
</html>
"@

$testHtml | Out-File -FilePath "test_protocol.html" -Encoding utf8

Write-Host "Test HTML file created: test_protocol.html"
Write-Host "Open this file in your browser to test the URL protocol."
