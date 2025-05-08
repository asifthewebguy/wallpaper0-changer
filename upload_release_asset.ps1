# Upload release asset to GitHub
# This script uploads the release package to GitHub

# GitHub repository information
$owner = "asifthewebguy"
$repo = "wallpaper0-changer"
$releaseId = "217256635"  # The ID of the release we just created
$assetPath = "release\WallpaperChanger-v1.0.0.zip"
$assetName = "WallpaperChanger-v1.0.0.zip"
$assetContentType = "application/zip"

# Check if the asset file exists
if (-not (Test-Path $assetPath)) {
    Write-Host "Asset file not found: $assetPath" -ForegroundColor Red
    exit 1
}

# GitHub Personal Access Token
# Note: You'll need to provide your GitHub token when running this script
$token = Read-Host -Prompt "Enter your GitHub Personal Access Token" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
$plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Upload the asset
$uploadUrl = "https://uploads.github.com/repos/$owner/$repo/releases/$releaseId/assets?name=$assetName"

Write-Host "Uploading asset: $assetPath" -ForegroundColor Green
Write-Host "To URL: $uploadUrl" -ForegroundColor Green

try {
    $headers = @{
        "Authorization" = "token $plainToken"
        "Content-Type" = $assetContentType
        "Accept" = "application/vnd.github.v3+json"
    }

    $fileContent = [System.IO.File]::ReadAllBytes($assetPath)
    
    $response = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $headers -Body $fileContent
    
    Write-Host "Asset uploaded successfully!" -ForegroundColor Green
    Write-Host "Download URL: $($response.browser_download_url)" -ForegroundColor Green
}
catch {
    Write-Host "Error uploading asset: $_" -ForegroundColor Red
}
finally {
    # Clear the token from memory
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}
