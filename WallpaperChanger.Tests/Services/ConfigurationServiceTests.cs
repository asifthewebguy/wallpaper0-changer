using FluentAssertions;
using NSubstitute;
using WallpaperChanger.Models;
using WallpaperChanger.Services;

namespace WallpaperChanger.Tests.Services;

/// <summary>
/// Tests for the ConfigurationService.
/// </summary>
[TestClass]
public class ConfigurationServiceTests
{
    private IAppLogger _mockLogger = null!;
    private string _testConfigPath = null!;

    [TestInitialize]
    public void Setup()
    {
        _mockLogger = Substitute.For<IAppLogger>();
        _testConfigPath = Path.Combine(Path.GetTempPath(), $"test_config_{Guid.NewGuid()}.json");
    }

    [TestCleanup]
    public void Cleanup()
    {
        if (File.Exists(_testConfigPath))
        {
            File.Delete(_testConfigPath);
        }
    }

    [TestMethod]
    public async Task LoadSettingsAsync_WhenFileDoesNotExist_CreatesDefaultSettings()
    {
        // Arrange
        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        // Act
        await configService.LoadSettingsAsync();

        // Assert
        configService.Settings.Should().NotBeNull();
        configService.Settings.MaxCacheSizeMb.Should().Be(500);
        configService.Settings.DownloadTimeoutSeconds.Should().Be(60);
        configService.Settings.MaxRetries.Should().Be(3);
        configService.Settings.ShowNotifications.Should().BeTrue();
        configService.Settings.StartWithWindows.Should().BeFalse();
    }

    [TestMethod]
    public async Task LoadSettingsAsync_WhenFileDoesNotExist_SavesDefaultSettings()
    {
        // Arrange
        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        // Act
        await configService.LoadSettingsAsync();

        // Assert
        File.Exists(_testConfigPath).Should().BeTrue("Config file should be created");
    }

    [TestMethod]
    public async Task SaveSettingsAsync_CreatesValidJsonFile()
    {
        // Arrange
        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);
        configService.Settings.MaxCacheSizeMb = 1000;
        configService.Settings.ShowNotifications = false;

        // Act
        await configService.SaveSettingsAsync();

        // Assert
        File.Exists(_testConfigPath).Should().BeTrue();
        var fileContent = await File.ReadAllTextAsync(_testConfigPath);
        fileContent.Should().Contain("1000");
        fileContent.Should().Contain("ShowNotifications");
    }

    [TestMethod]
    public async Task LoadSettingsAsync_WithValidJson_LoadsSettings()
    {
        // Arrange
        var jsonContent = """
        {
            "CacheDirectory": "C:\\TestCache",
            "MaxCacheSizeMb": 750,
            "StartWithWindows": true,
            "ShowNotifications": false,
            "DownloadTimeoutSeconds": 90,
            "MaxRetries": 5,
            "ApiTimeoutSeconds": 45
        }
        """;
        await File.WriteAllTextAsync(_testConfigPath, jsonContent);

        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        // Act
        await configService.LoadSettingsAsync();

        // Assert
        configService.Settings.CacheDirectory.Should().Be("C:\\TestCache");
        configService.Settings.MaxCacheSizeMb.Should().Be(750);
        configService.Settings.StartWithWindows.Should().BeTrue();
        configService.Settings.ShowNotifications.Should().BeFalse();
        configService.Settings.DownloadTimeoutSeconds.Should().Be(90);
        configService.Settings.MaxRetries.Should().Be(5);
        configService.Settings.ApiTimeoutSeconds.Should().Be(45);
    }

    [TestMethod]
    public async Task LoadSettingsAsync_WithInvalidJson_UsesDefaultSettings()
    {
        // Arrange
        var invalidJson = "{ invalid json content }";
        await File.WriteAllTextAsync(_testConfigPath, invalidJson);

        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        // Act
        await configService.LoadSettingsAsync();

        // Assert
        configService.Settings.Should().NotBeNull();
        configService.Settings.MaxCacheSizeMb.Should().Be(500, "Should use default value");
        _mockLogger.Received(1).LogWarning(
            Arg.Is<string>(s => s.Contains("Failed to load")),
            Arg.Any<Exception>()
        );
    }

    [TestMethod]
    public async Task LoadSettingsAsync_WithPartialJson_MergesWithDefaults()
    {
        // Arrange - Only specify some fields
        var partialJson = """
        {
            "MaxCacheSizeMb": 999
        }
        """;
        await File.WriteAllTextAsync(_testConfigPath, partialJson);

        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        // Act
        await configService.LoadSettingsAsync();

        // Assert
        configService.Settings.MaxCacheSizeMb.Should().Be(999, "Specified value should be loaded");
        configService.Settings.DownloadTimeoutSeconds.Should().Be(60, "Unspecified values should use defaults");
    }

    [TestMethod]
    public async Task SaveAndLoad_RoundTrip_PreservesAllSettings()
    {
        // Arrange
        var configService1 = new TestableConfigurationService(_mockLogger, _testConfigPath);
        configService1.Settings.CacheDirectory = "C:\\CustomCache";
        configService1.Settings.MaxCacheSizeMb = 888;
        configService1.Settings.StartWithWindows = true;
        configService1.Settings.ShowNotifications = false;
        configService1.Settings.DownloadTimeoutSeconds = 120;
        configService1.Settings.MaxRetries = 7;
        configService1.Settings.ApiTimeoutSeconds = 60;

        // Act - Save
        await configService1.SaveSettingsAsync();

        // Act - Load in new instance
        var configService2 = new TestableConfigurationService(_mockLogger, _testConfigPath);
        await configService2.LoadSettingsAsync();

        // Assert
        configService2.Settings.CacheDirectory.Should().Be(configService1.Settings.CacheDirectory);
        configService2.Settings.MaxCacheSizeMb.Should().Be(configService1.Settings.MaxCacheSizeMb);
        configService2.Settings.StartWithWindows.Should().Be(configService1.Settings.StartWithWindows);
        configService2.Settings.ShowNotifications.Should().Be(configService1.Settings.ShowNotifications);
        configService2.Settings.DownloadTimeoutSeconds.Should().Be(configService1.Settings.DownloadTimeoutSeconds);
        configService2.Settings.MaxRetries.Should().Be(configService1.Settings.MaxRetries);
        configService2.Settings.ApiTimeoutSeconds.Should().Be(configService1.Settings.ApiTimeoutSeconds);
    }

    [TestMethod]
    public async Task Settings_ModifyAndSave_PersistsChanges()
    {
        // Arrange
        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);
        await configService.LoadSettingsAsync();

        // Act - Modify settings
        configService.Settings.MaxCacheSizeMb = 1500;
        await configService.SaveSettingsAsync();

        // Load in new instance
        var configService2 = new TestableConfigurationService(_mockLogger, _testConfigPath);
        await configService2.LoadSettingsAsync();

        // Assert
        configService2.Settings.MaxCacheSizeMb.Should().Be(1500);
    }

    [TestMethod]
    public async Task LoadSettingsAsync_WithReadOnlyFile_LogsWarning()
    {
        // Arrange
        await File.WriteAllTextAsync(_testConfigPath, "{}");
        File.SetAttributes(_testConfigPath, FileAttributes.ReadOnly);

        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        try
        {
            // Act
            await configService.LoadSettingsAsync();
            configService.Settings.MaxCacheSizeMb = 999;
            await configService.SaveSettingsAsync();

            // Assert - Should log warning about inability to save
            _mockLogger.Received().LogWarning(
                Arg.Any<string>(),
                Arg.Any<Exception>()
            );
        }
        finally
        {
            // Cleanup
            File.SetAttributes(_testConfigPath, FileAttributes.Normal);
        }
    }

    [TestMethod]
    public void Settings_DefaultCacheDirectory_UsesLocalAppData()
    {
        // Arrange
        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        // Act
        var defaultSettings = configService.Settings;

        // Assert
        defaultSettings.CacheDirectory.Should().Contain("WallpaperChanger");
        defaultSettings.CacheDirectory.Should().Contain("Cache");
    }

    [TestMethod]
    public async Task LoadSettingsAsync_WithNegativeValues_UsesDefaults()
    {
        // Arrange
        var invalidJson = """
        {
            "MaxCacheSizeMb": -100,
            "DownloadTimeoutSeconds": -30,
            "MaxRetries": -5
        }
        """;
        await File.WriteAllTextAsync(_testConfigPath, invalidJson);

        var configService = new TestableConfigurationService(_mockLogger, _testConfigPath);

        // Act
        await configService.LoadSettingsAsync();

        // Assert - Should either reject negative values or clamp them
        configService.Settings.MaxCacheSizeMb.Should().BeGreaterThan(0);
        configService.Settings.DownloadTimeoutSeconds.Should().BeGreaterThan(0);
        configService.Settings.MaxRetries.Should().BeGreaterThan(0);
    }
}

/// <summary>
/// Testable version of ConfigurationService that allows custom config path.
/// </summary>
internal class TestableConfigurationService : ConfigurationService
{
    public TestableConfigurationService(IAppLogger logger, string configPath)
        : base(logger, configPath)
    {
    }
}
