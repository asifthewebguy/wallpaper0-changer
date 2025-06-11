# Upload Release Asset to GitHub Release v1.0.1
# This script uploads the standalone release package to the GitHub release

param (
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$ReleaseId = "224686540",
    [string]$AssetPath = "release\WallpaperChanger-Standalone-v1.1.0.zip",
    [string]$AssetName = "WallpaperChanger-Standalone-v1.0.1.zip"
)

# Function to show a message with color
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

Write-ColorMessage "===== Uploading Release Asset to GitHub =====" "Cyan"
Write-ColorMessage "Release ID: $ReleaseId" "Yellow"
Write-ColorMessage "Asset Path: $AssetPath" "Yellow"
Write-ColorMessage "Asset Name: $AssetName" "Yellow"
Write-ColorMessage ""

# Check if the asset file exists
if (-not (Test-Path $AssetPath)) {
    Write-ColorMessage "Error: Asset file not found at $AssetPath" "Red"
    exit 1
}

# Get file size
$fileSize = (Get-Item $AssetPath).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
Write-ColorMessage "File size: $fileSizeMB MB" "Green"

# Check if GitHub token is provided
if (-not $GitHubToken) {
    Write-ColorMessage "Error: GitHub token not provided. Set GITHUB_TOKEN environment variable or pass as parameter." "Red"
    exit 1
}

# GitHub API endpoint for uploading assets
$uploadUrl = "https://uploads.github.com/repos/asifthewebguy/wallpaper0-changer/releases/$ReleaseId/assets?name=$AssetName&label=Standalone%20Release%20Package%20(Recommended)"

Write-ColorMessage "Uploading asset to GitHub..." "Yellow"

try {
    # Read the file content
    $fileBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $AssetPath))
    
    # Create headers
    $headers = @{
        "Authorization" = "token $GitHubToken"
        "Content-Type" = "application/zip"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    # Upload the asset
    $response = Invoke-RestMethod -Uri $uploadUrl -Method POST -Headers $headers -Body $fileBytes
    
    Write-ColorMessage "Asset uploaded successfully!" "Green"
    Write-ColorMessage "Download URL: $($response.browser_download_url)" "Green"
    Write-ColorMessage "Asset ID: $($response.id)" "Green"
    
} catch {
    Write-ColorMessage "Error uploading asset: $($_.Exception.Message)" "Red"
    
    # Show more details if available
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-ColorMessage "HTTP Status Code: $statusCode" "Red"
        
        try {
            $responseBody = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseBody)
            $errorDetails = $reader.ReadToEnd()
            Write-ColorMessage "Error Details: $errorDetails" "Red"
        } catch {
            Write-ColorMessage "Could not read error details" "Red"
        }
    }
    
    exit 1
}

Write-ColorMessage ""
Write-ColorMessage "Release v1.0.1 is now ready with the standalone package!" "Green"
Write-ColorMessage "Users can download and install without any .NET dependencies." "Green"
