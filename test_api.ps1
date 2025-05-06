# Test the aiwp.me API endpoints
# This script tests the API endpoints used by the application

# API endpoints
$API_BASE_URL = "https://aiwp.me/api/"
$IMAGES_DATA_URL = $API_BASE_URL + "images-data.json"

# Test the images-data endpoint
Write-Host "Testing the images-data endpoint..."
try {
    $response = Invoke-WebRequest -Uri $IMAGES_DATA_URL -Method Get

    if ($response.StatusCode -eq 200) {
        Write-Host "Success! Status code: $($response.StatusCode)"

        # Parse the JSON response
        $data = $response.Content | ConvertFrom-Json

        # Get the first image ID
        if ($data.Count -gt 0) {
            $firstImageId = $data[0].id
            Write-Host "First image ID: $firstImageId"

            # Test the image details endpoint
            $IMAGE_DETAILS_URL = $API_BASE_URL + "images/$firstImageId.json"
            Write-Host "Testing the image details endpoint for ID: $firstImageId..."

            $detailsResponse = Invoke-WebRequest -Uri $IMAGE_DETAILS_URL -Method Get

            if ($detailsResponse.StatusCode -eq 200) {
                Write-Host "Success! Status code: $($detailsResponse.StatusCode)"

                # Parse the JSON response
                $imageDetails = $detailsResponse.Content | ConvertFrom-Json

                # Display the image URL (check different possible properties)
                if ($imageDetails.path) {
                    Write-Host "Image URL (path): $($imageDetails.path)"

                    # Update the test_protocol.ps1 script with the valid image ID
                    $testProtocolPath = Join-Path -Path $PSScriptRoot -ChildPath "test_protocol.ps1"
                    if (Test-Path $testProtocolPath) {
                        $content = Get-Content -Path $testProtocolPath -Raw
                        $content = $content -replace 'test_image_id', $firstImageId
                        Set-Content -Path $testProtocolPath -Value $content
                        Write-Host "Updated test_protocol.ps1 with valid image ID: $firstImageId"
                    }
                }
                elseif ($imageDetails.url) {
                    Write-Host "Image URL (url): $($imageDetails.url)"

                    # Update the test_protocol.ps1 script with the valid image ID
                    $testProtocolPath = Join-Path -Path $PSScriptRoot -ChildPath "test_protocol.ps1"
                    if (Test-Path $testProtocolPath) {
                        $content = Get-Content -Path $testProtocolPath -Raw
                        $content = $content -replace 'test_image_id', $firstImageId
                        Set-Content -Path $testProtocolPath -Value $content
                        Write-Host "Updated test_protocol.ps1 with valid image ID: $firstImageId"
                    }
                }
                elseif ($imageDetails.thumbnailUrl) {
                    Write-Host "Image URL (thumbnailUrl): $($imageDetails.thumbnailUrl)"

                    # Update the test_protocol.ps1 script with the valid image ID
                    $testProtocolPath = Join-Path -Path $PSScriptRoot -ChildPath "test_protocol.ps1"
                    if (Test-Path $testProtocolPath) {
                        $content = Get-Content -Path $testProtocolPath -Raw
                        $content = $content -replace 'test_image_id', $firstImageId
                        Set-Content -Path $testProtocolPath -Value $content
                        Write-Host "Updated test_protocol.ps1 with valid image ID: $firstImageId"
                    }
                }
                else {
                    Write-Host "Error: Image URL not found in the response"
                    Write-Host "Available properties: $($imageDetails | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)"
                }
            } else {
                Write-Host "Error: Failed to get image details. Status code: $($detailsResponse.StatusCode)"
            }
        } else {
            Write-Host "Error: No images found in the response"
        }
    } else {
        Write-Host "Error: Failed to get images data. Status code: $($response.StatusCode)"
    }
} catch {
    Write-Host "Error: $_"
}
