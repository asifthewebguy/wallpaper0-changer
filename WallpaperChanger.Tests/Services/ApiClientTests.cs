using System.Net;
using FluentAssertions;
using NSubstitute;
using WallpaperChanger.Exceptions;
using WallpaperChanger.Models;
using WallpaperChanger.Services;

namespace WallpaperChanger.Tests.Services;

/// <summary>
/// Tests for the ApiClient service.
/// </summary>
[TestClass]
public class ApiClientTests
{
    private IValidationService _mockValidationService = null!;
    private IConfigurationService _mockConfigService = null!;
    private IAppLogger _mockLogger = null!;
    private HttpClient _httpClient = null!;
    private TestHttpMessageHandler _testHandler = null!;

    [TestInitialize]
    public void Setup()
    {
        _mockValidationService = Substitute.For<IValidationService>();
        _mockConfigService = Substitute.For<IConfigurationService>();
        _mockLogger = Substitute.For<IAppLogger>();

        // Setup default configuration
        var settings = new AppSettings
        {
            ApiTimeoutSeconds = 30,
            MaxRetries = 3
        };
        _mockConfigService.Settings.Returns(settings);

        // Configure mock validation service - by default accept image IDs, URLs can be overridden per test
        _mockValidationService.IsValidImageId(Arg.Any<string>()).Returns(true);

        // Setup test HTTP handler
        _testHandler = new TestHttpMessageHandler();
        _httpClient = new HttpClient(_testHandler)
        {
            BaseAddress = new Uri("https://aiwp.me/")
        };
    }

    [TestCleanup]
    public void Cleanup()
    {
        _httpClient?.Dispose();
        _testHandler?.Dispose();
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_WithValidResponse_ReturnsImageDetails()
    {
        // Arrange
        var imageId = "123";
        var expectedUrl = "https://aiwp.me/images/123.jpg";
        var jsonResponse = $$"""
        {
            "id": "{{imageId}}",
            "url": "{{expectedUrl}}",
            "thumbnail": "https://aiwp.me/thumbnails/123.jpg",
            "size": 1024000,
            "format": "jpg"
        }
        """;

        _mockValidationService.IsValidImageUrl(Arg.Any<string>()).Returns(true);
        _testHandler.SetResponse(HttpStatusCode.OK, jsonResponse);

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        var result = await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        result.Should().NotBeNull();
        result.ImageId.Should().Be(imageId);
        result.ImageUrl.Should().Be(expectedUrl);
        result.FileSize.Should().Be(1024000);
        result.Format.Should().Be("jpg");
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_WithInvalidUrl_ThrowsWallpaperException()
    {
        // Arrange
        var imageId = "123";
        var jsonResponse = """
        {
            "id": "123",
            "url": "https://evil.com/malicious.jpg",
            "thumbnail": "https://evil.com/thumb.jpg",
            "size": 1024000,
            "format": "jpg"
        }
        """;

        _mockValidationService.IsValidImageUrl(Arg.Any<string>()).Returns(false);
        _testHandler.SetResponse(HttpStatusCode.OK, jsonResponse);

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        Func<Task> act = async () => await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        await act.Should().ThrowAsync<WallpaperException>()
            .Where(ex => ex.ErrorCode == ErrorCode.InvalidImageId);
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_With404Response_ThrowsWallpaperException()
    {
        // Arrange
        var imageId = "999";
        _testHandler.SetResponse(HttpStatusCode.NotFound, "Not Found");

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        Func<Task> act = async () => await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        await act.Should().ThrowAsync<WallpaperException>()
            .Where(ex => ex.ErrorCode == ErrorCode.ApiError);
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_With500Response_ThrowsWallpaperException()
    {
        // Arrange
        var imageId = "123";
        _testHandler.SetResponse(HttpStatusCode.InternalServerError, "Server Error");

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        Func<Task> act = async () => await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        await act.Should().ThrowAsync<WallpaperException>()
            .Where(ex => ex.ErrorCode == ErrorCode.ApiError);
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_WithInvalidJson_ThrowsWallpaperException()
    {
        // Arrange
        var imageId = "123";
        var invalidJson = "{ invalid json }";

        _testHandler.SetResponse(HttpStatusCode.OK, invalidJson);

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        Func<Task> act = async () => await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        await act.Should().ThrowAsync<WallpaperException>()
            .Where(ex => ex.ErrorCode == ErrorCode.ApiError);
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_WithMissingFields_ThrowsWallpaperException()
    {
        // Arrange
        var imageId = "123";
        var incompleteJson = """
        {
            "id": "123"
        }
        """;

        _testHandler.SetResponse(HttpStatusCode.OK, incompleteJson);

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        Func<Task> act = async () => await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        await act.Should().ThrowAsync<WallpaperException>()
            .Where(ex => ex.ErrorCode == ErrorCode.ApiError);
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_WithNetworkError_ThrowsWallpaperException()
    {
        // Arrange
        var imageId = "123";
        _testHandler.SetException(new HttpRequestException("Network error"));

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        Func<Task> act = async () => await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        await act.Should().ThrowAsync<WallpaperException>()
            .Where(ex => ex.ErrorCode == ErrorCode.NetworkError);
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_WithTimeout_ThrowsWallpaperException()
    {
        // Arrange
        var imageId = "123";
        _testHandler.SetException(new TaskCanceledException("Request timeout"));

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        Func<Task> act = async () => await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        await act.Should().ThrowAsync<WallpaperException>()
            .Where(ex => ex.ErrorCode == ErrorCode.Timeout);
    }

    [TestMethod]
    public async Task GetImageDetailsAsync_LogsApiCall()
    {
        // Arrange
        var imageId = "123";
        var jsonResponse = """
        {
            "id": "123",
            "url": "https://aiwp.me/images/123.jpg",
            "thumbnail": "https://aiwp.me/thumbnails/123.jpg",
            "size": 1024000,
            "format": "jpg"
        }
        """;

        _mockValidationService.IsValidImageUrl(Arg.Any<string>()).Returns(true);
        _testHandler.SetResponse(HttpStatusCode.OK, jsonResponse);

        var apiClient = new ApiClient(_httpClient, _mockValidationService, _mockLogger, _mockConfigService);

        // Act
        await apiClient.GetImageDetailsAsync(imageId);

        // Assert
        _mockLogger.Received(1).LogInfo(
            Arg.Is<string>(s => s.Contains("Fetching image details")),
            Arg.Any<Dictionary<string, object>>()
        );
    }
}

/// <summary>
/// Test HTTP message handler for mocking HTTP responses.
/// </summary>
public class TestHttpMessageHandler : HttpMessageHandler
{
    private HttpStatusCode _statusCode = HttpStatusCode.OK;
    private string _content = string.Empty;
    private Exception? _exception;

    public void SetResponse(HttpStatusCode statusCode, string content)
    {
        _statusCode = statusCode;
        _content = content;
        _exception = null;
    }

    public void SetException(Exception exception)
    {
        _exception = exception;
    }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        if (_exception != null)
        {
            throw _exception;
        }

        var response = new HttpResponseMessage(_statusCode)
        {
            Content = new StringContent(_content)
        };

        return Task.FromResult(response);
    }
}
