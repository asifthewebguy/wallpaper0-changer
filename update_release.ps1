# Update GitHub release with additional information
# This script updates the GitHub release with more detailed information

# GitHub repository information
$owner = "asifthewebguy"
$repo = "wallpaper0-changer"
$releaseId = "217256635"  # The ID of the release we just created

# GitHub Personal Access Token
# Note: You'll need to provide your GitHub token when running this script
$token = Read-Host -Prompt "Enter your GitHub Personal Access Token" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
$plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Read the release notes
$releaseNotes = Get-Content -Path "RELEASE_NOTES.md" -Raw

# Update the release
$updateUrl = "https://api.github.com/repos/$owner/$repo/releases/$releaseId"

Write-Host "Updating release with detailed information..." -ForegroundColor Green

try {
    $headers = @{
        "Authorization" = "token $plainToken"
        "Accept" = "application/vnd.github.v3+json"
    }

    $body = @{
        body = $releaseNotes
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $updateUrl -Method Patch -Headers $headers -Body $body -ContentType "application/json"
    
    Write-Host "Release updated successfully!" -ForegroundColor Green
    Write-Host "Release URL: $($response.html_url)" -ForegroundColor Green
}
catch {
    Write-Host "Error updating release: $_" -ForegroundColor Red
}
finally {
    # Clear the token from memory
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}
