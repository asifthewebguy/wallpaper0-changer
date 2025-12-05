using System.Text.Json;
using Polly;
using Polly.Retry;
using WallpaperChanger.Exceptions;
using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// HTTP client for communicating with the wallpaper API with retry logic.
/// </summary>
public class ApiClient : IApiClient
{
    private const string API_BASE_URL = "https://aiwp.me/api/";
    private const string IMAGE_DETAILS_URL = API_BASE_URL + "images/{0}.json";

    private readonly HttpClient _httpClient;
    private readonly IValidationService _validationService;
    private readonly IAppLogger _logger;
    private readonly AsyncRetryPolicy<HttpResponseMessage> _retryPolicy;

    /// <summary>
    /// Initializes a new instance of the <see cref="ApiClient"/> class.
    /// </summary>
    /// <param name="httpClient">The HTTP client instance.</param>
    /// <param name="validationService">The validation service.</param>
    /// <param name="logger">The logger instance.</param>
    /// <param name="configService">The configuration service.</param>
    public ApiClient(HttpClient httpClient, IValidationService validationService, IAppLogger logger, IConfigurationService configService)
    {
        _httpClient = httpClient;
        _validationService = validationService;
        _logger = logger;

        // Configure timeout
        _httpClient.Timeout = TimeSpan.FromSeconds(configService.Settings.ApiTimeoutSeconds);
        _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("WallpaperChanger/1.0");

        // Configure retry policy with exponential backoff
        _retryPolicy = Policy
            .HandleResult<HttpResponseMessage>(r => !r.IsSuccessStatusCode)
            .Or<HttpRequestException>()
            .WaitAndRetryAsync(
                configService.Settings.MaxRetries,
                retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    string reason = outcome.Exception != null 
                        ? outcome.Exception.Message 
                        : $"Status Code: {outcome.Result?.StatusCode}";
                        
                    _logger.LogWarning($"API request retry {retryCount} after {timespan.TotalSeconds}s delay. Reason: {reason}");
                });
    }

    /// <summary>
    /// Gets image details from the API.
    /// </summary>
    public async Task<ImageDetails> GetImageDetailsAsync(string imageId, CancellationToken cancellationToken = default)
    {
        if (!_validationService.IsValidImageId(imageId))
        {
            throw new WallpaperException(ErrorCode.InvalidImageId, $"Invalid image ID: {imageId}")
                .WithContext("ImageId", imageId);
        }

        try
        {
            string apiUrl = string.Format(IMAGE_DETAILS_URL, imageId);

            _logger.LogInfo("Fetching image details from API", new Dictionary<string, object>
            {
                { "ImageId", imageId },
                { "ApiUrl", apiUrl }
            });

            // Execute request with retry policy
            HttpResponseMessage response = await _retryPolicy.ExecuteAsync(async () =>
            {
                return await _httpClient.GetAsync(apiUrl, cancellationToken);
            });

            if (!response.IsSuccessStatusCode)
            {
                throw new WallpaperException(ErrorCode.ApiError, $"API returned status code: {response.StatusCode}")
                    .WithContext("StatusCode", (int)response.StatusCode)
                    .WithContext("ImageId", imageId);
            }

            string json = await response.Content.ReadAsStringAsync(cancellationToken);

            using (JsonDocument doc = JsonDocument.Parse(json))
            {
                JsonElement root = doc.RootElement;
                string? imageUrl = null;

                // Try to get the URL from different possible properties
                if (root.TryGetProperty("path", out JsonElement pathElement))
                {
                    imageUrl = pathElement.GetString();
                }
                else if (root.TryGetProperty("url", out JsonElement urlElement))
                {
                    imageUrl = urlElement.GetString();
                }
                else if (root.TryGetProperty("thumbnailUrl", out JsonElement thumbnailUrlElement))
                {
                    imageUrl = thumbnailUrlElement.GetString();
                }

                if (string.IsNullOrEmpty(imageUrl))
                {
                    throw new WallpaperException(ErrorCode.ApiError, "No valid image URL found in API response")
                        .WithContext("ImageId", imageId);
                }

                // Validate the URL
                if (!_validationService.IsValidImageUrl(imageUrl))
                {
                    throw new WallpaperException(ErrorCode.InvalidImageId, "API returned an invalid or untrusted URL")
                        .WithContext("ImageId", imageId)
                        .WithContext("Url", imageUrl);
                }

                // Try to get FileSize from the response
                long fileSize = 0;
                if (root.TryGetProperty("size", out JsonElement sizeElement))
                {
                    fileSize = sizeElement.GetInt64();
                }

                var imageDetails = new ImageDetails
                {
                    ImageId = imageId,
                    ImageUrl = imageUrl,
                    Format = Path.GetExtension(imageUrl).TrimStart('.'),
                    FileSize = fileSize
                };

                _logger.LogInfo("Successfully retrieved image details", new Dictionary<string, object>
                {
                    { "ImageId", imageId },
                    { "ImageUrl", imageUrl }
                });

                return imageDetails;
            }
        }
        catch (TaskCanceledException ex)
        {
            throw new WallpaperException(ErrorCode.Timeout, "API request timed out", ex)
                .WithContext("ImageId", imageId);
        }
        catch (HttpRequestException ex)
        {
            throw new WallpaperException(ErrorCode.NetworkError, "Network error while accessing API", ex)
                .WithContext("ImageId", imageId);
        }
        catch (JsonException ex)
        {
            throw new WallpaperException(ErrorCode.ApiError, "Invalid JSON response from API", ex)
                .WithContext("ImageId", imageId);
        }
        catch (WallpaperException)
        {
            throw; // Re-throw WallpaperException as-is
        }
        catch (Exception ex)
        {
            _logger.LogError("Unexpected error in GetImageDetailsAsync", ex);
            throw new WallpaperException(ErrorCode.Unknown, "An unexpected error occurred", ex)
                .WithContext("ImageId", imageId);
        }
    }


    /// <summary>
    /// Gets a random image ID from the API.
    /// </summary>
    public async Task<string> GetRandomImageIdAsync(CancellationToken cancellationToken = default)
    {
        const string RANDOM_LIST_URL = API_BASE_URL + "images.json";
        
        try
        {
            _logger.LogInfo("Fetching random image list from API");

            // Execute request with retry policy
            HttpResponseMessage response = await _retryPolicy.ExecuteAsync(async () =>
            {
                return await _httpClient.GetAsync(RANDOM_LIST_URL, cancellationToken);
            });

            if (!response.IsSuccessStatusCode)
            {
                throw new WallpaperException(ErrorCode.ApiError, $"API returned status code: {response.StatusCode} when fetching random list");
            }

            string json = await response.Content.ReadAsStringAsync(cancellationToken);
            
            // Parse array of strings
            var images = JsonSerializer.Deserialize<List<string>>(json);
            
            if (images == null || images.Count == 0)
            {
                throw new WallpaperException(ErrorCode.ApiError, "API returned empty image list");
            }

            // Pick random
            var random = new Random();
            string selectedFile = images[random.Next(images.Count)];
            
            // API expects the full filename including extension (e.g. "ID.jpg")
            string imageId = selectedFile;

            _logger.LogInfo($"Selected random image ID: {imageId}");
            
            return imageId;
        }
        catch (Exception ex)
        {
             _logger.LogError("Error getting random image ID", ex);
             throw new WallpaperException(ErrorCode.NetworkError, "Failed to get random image from API", ex);
        }
    }
}
