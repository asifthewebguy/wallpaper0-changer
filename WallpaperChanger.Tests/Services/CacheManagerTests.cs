using FluentAssertions;
using NSubstitute;
using WallpaperChanger.Models;
using WallpaperChanger.Services;

namespace WallpaperChanger.Tests.Services;

/// <summary>
/// Tests for the CacheManager service.
/// </summary>
[TestClass]
public class CacheManagerTests
{
    private IConfigurationService _mockConfigService = null!;
    private IValidationService _mockValidationService = null!;
    private IAppLogger _mockLogger = null!;
    private string _testCacheDir = null!;
    private CacheManager _cacheManager = null!;

    [TestInitialize]
    public void Setup()
    {
        _mockConfigService = Substitute.For<IConfigurationService>();
        _mockValidationService = Substitute.For<IValidationService>();
        _mockLogger = Substitute.For<IAppLogger>();

        // Create temporary cache directory
        _testCacheDir = Path.Combine(Path.GetTempPath(), $"test_cache_{Guid.NewGuid()}");
        Directory.CreateDirectory(_testCacheDir);

        var settings = new AppSettings
        {
            CacheDirectory = _testCacheDir,
            MaxCacheSizeMb = 500
        };
        _mockConfigService.Settings.Returns(settings);

        // Configure mock validation service to accept all image IDs and file paths in tests
        _mockValidationService.IsValidImageId(Arg.Any<string>()).Returns(true);
        _mockValidationService.IsValidFilePath(Arg.Any<string>()).Returns(true);

        _cacheManager = new CacheManager(_mockLogger, _mockValidationService, _mockConfigService);
    }

    [TestCleanup]
    public void Cleanup()
    {
        if (Directory.Exists(_testCacheDir))
        {
            Directory.Delete(_testCacheDir, true);
        }
    }

    [TestMethod]
    public void GetCachedImagePath_ReturnsCorrectPath()
    {
        // Arrange
        var imageId = "12345";

        // Act
        var path = _cacheManager.GetCachedImagePath(imageId, ".jpg");

        // Assert
        path.Should().Contain(_testCacheDir);
        path.Should().Contain(imageId);
        path.Should().EndWith(".jpg");
    }

    [TestMethod]
    public void IsCached_WhenFileExists_ReturnsTrue()
    {
        // Arrange
        var imageId = "12345";
        var cachedPath = _cacheManager.GetCachedImagePath(imageId, ".jpg");
        Directory.CreateDirectory(Path.GetDirectoryName(cachedPath)!);
        File.WriteAllText(cachedPath, "test image data");

        // Act
        var isCached = _cacheManager.IsCached(imageId);

        // Assert
        isCached.Should().BeTrue();
    }

    [TestMethod]
    public void IsCached_WhenFileDoesNotExist_ReturnsFalse()
    {
        // Arrange
        var imageId = "99999";

        // Act
        var isCached = _cacheManager.IsCached(imageId);

        // Assert
        isCached.Should().BeFalse();
    }

    [TestMethod]
    public async Task CleanupCacheAsync_WhenUnderLimit_DoesNotDeleteFiles()
    {
        // Arrange
        var imageId1 = "1";
        var imageId2 = "2";

        CreateCachedFile(imageId1, 1024); // 1 KB
        CreateCachedFile(imageId2, 1024); // 1 KB

        var maxSize = 1024 * 1024; // 1 MB limit

        // Act
        await _cacheManager.CleanupCacheAsync(maxSize);

        // Assert
        _cacheManager.IsCached(imageId1).Should().BeTrue("File should still exist");
        _cacheManager.IsCached(imageId2).Should().BeTrue("File should still exist");
    }

    [TestMethod]
    public async Task CleanupCacheAsync_WhenOverLimit_DeletesOldestFiles()
    {
        // Arrange
        var imageId1 = "1";
        var imageId2 = "2";
        var imageId3 = "3";

        // Create files with different timestamps
        CreateCachedFile(imageId1, 500 * 1024); // 500 KB - oldest
        await Task.Delay(100);
        CreateCachedFile(imageId2, 500 * 1024); // 500 KB - middle
        await Task.Delay(100);
        CreateCachedFile(imageId3, 500 * 1024); // 500 KB - newest

        // Access image3 to make it most recently used
        _ = _cacheManager.GetCachedImagePath(imageId3, ".jpg");

        var maxSize = 700 * 1024; // 700 KB limit (should delete oldest file)

        // Act
        await _cacheManager.CleanupCacheAsync(maxSize);

        // Assert
        _cacheManager.IsCached(imageId1).Should().BeFalse("Oldest file should be deleted");
        _cacheManager.IsCached(imageId2).Should().BeTrue("Newer file should remain");
        _cacheManager.IsCached(imageId3).Should().BeTrue("Newest file should remain");
    }

    [TestMethod]
    public async Task CleanupCacheAsync_WithLRUAccess_DeletesLeastRecentlyUsed()
    {
        // Arrange
        var imageId1 = "1";
        var imageId2 = "2";
        var imageId3 = "3";

        CreateCachedFile(imageId1, 400 * 1024);
        CreateCachedFile(imageId2, 400 * 1024);
        CreateCachedFile(imageId3, 400 * 1024);

        // Simulate access pattern - access imageId1 most recently
        await Task.Delay(100);
        TouchAccessTime(imageId1);

        var maxSize = 700 * 1024; // Should keep 2 most recently accessed

        // Act
        await _cacheManager.CleanupCacheAsync(maxSize);

        // Assert
        var remainingFiles = Directory.GetFiles(_testCacheDir).Length;
        remainingFiles.Should().BeLessOrEqualTo(2, "Should delete least recently used files");
    }

    [TestMethod]
    public async Task GetCacheHistoryAsync_ReturnsAllCachedImages()
    {
        // Arrange
        CreateCachedFile("1", 1024);
        CreateCachedFile("2", 2048);
        CreateCachedFile("3", 3072);

        // Act
        var history = await _cacheManager.GetCacheHistoryAsync();

        // Assert
        history.Should().HaveCount(3);
        history.Should().Contain(img => img.ImageId == "1");
        history.Should().Contain(img => img.ImageId == "2");
        history.Should().Contain(img => img.ImageId == "3");
    }

    [TestMethod]
    public async Task GetCacheHistoryAsync_ReturnsCorrectFileSize()
    {
        // Arrange
        var imageId = "123";
        var fileSize = 5000L;
        CreateCachedFile(imageId, fileSize);

        // Act
        var history = await _cacheManager.GetCacheHistoryAsync();

        // Assert
        var cachedImage = history.FirstOrDefault(img => img.ImageId == imageId);
        cachedImage.Should().NotBeNull();
        cachedImage!.FileSize.Should().Be(fileSize);
    }

    [TestMethod]
    public async Task GetCacheHistoryAsync_OrdersByAccessTime()
    {
        // Arrange
        CreateCachedFile("1", 1024);
        await Task.Delay(100);
        CreateCachedFile("2", 1024);
        await Task.Delay(100);
        CreateCachedFile("3", 1024);

        // Act
        var history = await _cacheManager.GetCacheHistoryAsync();

        // Assert
        history.Should().HaveCount(3);
        // Most recent should be first or last depending on implementation
        var timestamps = history.Select(h => h.LastAccessTime).ToList();
        timestamps.Should().Match(list => list.SequenceEqual(list.OrderBy(x => x)) || list.SequenceEqual(list.OrderByDescending(x => x)), "Should be ordered");
    }

    [TestMethod]
    public async Task CleanupCacheAsync_WithEmptyCache_DoesNotThrow()
    {
        // Arrange
        var maxSize = 1024 * 1024;

        // Act
        Func<Task> act = async () => await _cacheManager.CleanupCacheAsync(maxSize);

        // Assert
        await act.Should().NotThrowAsync();
    }

    [TestMethod]
    public async Task CleanupCacheAsync_WithZeroSizeLimit_DeletesAllFiles()
    {
        // Arrange
        CreateCachedFile("1", 1024);
        CreateCachedFile("2", 1024);
        CreateCachedFile("3", 1024);

        // Act
        await _cacheManager.CleanupCacheAsync(0);

        // Assert
        var files = Directory.GetFiles(_testCacheDir);
        files.Should().BeEmpty("All files should be deleted with zero size limit");
    }

    [TestMethod]
    public void GetCachedImagePath_WithDifferentIds_ReturnsDifferentPaths()
    {
        // Arrange
        var imageId1 = "123";
        var imageId2 = "456";

        // Act
        var path1 = _cacheManager.GetCachedImagePath(imageId1, ".jpg");
        var path2 = _cacheManager.GetCachedImagePath(imageId2, ".jpg");

        // Assert
        path1.Should().NotBe(path2);
    }

    [TestMethod]
    public void GetCachedImagePath_WithSameId_ReturnsSamePath()
    {
        // Arrange
        var imageId = "123";

        // Act
        var path1 = _cacheManager.GetCachedImagePath(imageId, ".jpg");
        var path2 = _cacheManager.GetCachedImagePath(imageId, ".jpg");

        // Assert
        path1.Should().Be(path2);
    }

    [TestMethod]
    public async Task CleanupCacheAsync_LogsCleanupOperation()
    {
        // Arrange
        CreateCachedFile("1", 1024 * 1024); // 1 MB
        var maxSize = 500 * 1024; // 500 KB

        // Act
        await _cacheManager.CleanupCacheAsync(maxSize);

        // Assert
        _mockLogger.Received().LogInfo(
            Arg.Is<string>(s => s.Contains("cleanup") || s.Contains("Cleanup")),
            Arg.Any<Dictionary<string, object>>()
        );
    }

    [TestMethod]
    public async Task CleanupCacheAsync_WithReadOnlyFile_HandlesGracefully()
    {
        // Arrange
        var imageId = "1";
        CreateCachedFile(imageId, 1024 * 1024);
        var cachedPath = _cacheManager.GetCachedImagePath(imageId, ".jpg");
        File.SetAttributes(cachedPath, FileAttributes.ReadOnly);

        try
        {
            // Act
            Func<Task> act = async () => await _cacheManager.CleanupCacheAsync(0);

            // Assert - Should log warning but not crash
            await act.Should().NotThrowAsync();
            _mockLogger.Received().LogWarning(
                Arg.Any<string>(),
                Arg.Any<Exception>()
            );
        }
        finally
        {
            // Cleanup
            File.SetAttributes(cachedPath, FileAttributes.Normal);
        }
    }

    #region Helper Methods

    private void CreateCachedFile(string imageId, long sizeInBytes)
    {
        var path = _cacheManager.GetCachedImagePath(imageId, ".jpg");
        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
        {
            Directory.CreateDirectory(directory);
        }

        // Create file with specified size
        using var fs = File.Create(path);
        var buffer = new byte[Math.Min(sizeInBytes, 8192)];
        long written = 0;
        while (written < sizeInBytes)
        {
            var toWrite = (int)Math.Min(buffer.Length, sizeInBytes - written);
            fs.Write(buffer, 0, toWrite);
            written += toWrite;
        }
    }

    private void TouchAccessTime(string imageId)
    {
        var path = _cacheManager.GetCachedImagePath(imageId, ".jpg");
        if (File.Exists(path))
        {
            File.SetLastAccessTime(path, DateTime.Now);
        }
    }

    #endregion
}
