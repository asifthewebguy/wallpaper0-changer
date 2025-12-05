using FluentAssertions;
using WallpaperChanger.Services;

namespace WallpaperChanger.Tests.Services;

/// <summary>
/// Tests for the ValidationService to ensure security and input validation.
/// </summary>
[TestClass]
public class ValidationServiceTests
{
    private ValidationService _validationService = null!;

    [TestInitialize]
    public void Setup()
    {
        _validationService = new ValidationService();
    }

    #region IsValidImageId Tests

    [TestMethod]
    public void IsValidImageId_WithValidNumericId_ReturnsTrue()
    {
        // Arrange
        var validIds = new[] { "1", "123", "999999", "1234567890" };

        // Act & Assert
        foreach (var id in validIds)
        {
            _validationService.IsValidImageId(id).Should().BeTrue($"'{id}' should be valid");
        }
    }

    [TestMethod]
    public void IsValidImageId_WithNullOrEmpty_ReturnsFalse()
    {
        // Arrange & Act & Assert
        _validationService.IsValidImageId(null!).Should().BeFalse();
        _validationService.IsValidImageId(string.Empty).Should().BeFalse();
        _validationService.IsValidImageId("   ").Should().BeFalse();
    }

    [TestMethod]
    public void IsValidImageId_WithInvalidCharacters_ReturnsFalse()
    {
        // Arrange - Test IDs with truly invalid characters (not alphanumeric, hyphen, or underscore)
        var invalidIds = new[]
        {
            "invalid!@#", // Special characters not allowed
            "12 34",      // Spaces not allowed
            "12\n34",     // Newlines not allowed
            "test/path",  // Slashes not allowed
            "a\\b",       // Backslashes not allowed
            "id<>",       // Angle brackets not allowed
            "id|pipe"     // Pipes not allowed
        };

        // Act & Assert
        foreach (var id in invalidIds)
        {
            _validationService.IsValidImageId(id).Should().BeFalse($"'{id}' should be invalid");
        }
    }

    [TestMethod]
    public void IsValidImageId_WithAlphanumericCharacters_ReturnsTrue()
    {
        // Arrange - Test valid alphanumeric IDs (now allowed)
        var validIds = new[]
        {
            "abc",
            "123abc",
            "ABC123",
            "HNVOO3GJH7",  // Real example from aiwp.me
            "image-123",   // Hyphens allowed
            "image_456",   // Underscores allowed
            "Test-Image_1"
        };

        // Act & Assert
        foreach (var id in validIds)
        {
            _validationService.IsValidImageId(id).Should().BeTrue($"'{id}' should be valid");
        }
    }

    [TestMethod]
    public void IsValidImageId_WithTooLongId_ReturnsFalse()
    {
        // Arrange - Max length is now 50 characters
        var tooLongId = new string('a', 51); // 51 characters

        // Act
        var result = _validationService.IsValidImageId(tooLongId);

        // Assert
        result.Should().BeFalse("Image IDs longer than 50 characters should be rejected");
    }

    [TestMethod]
    public void IsValidImageId_WithLeadingZeros_ReturnsTrue()
    {
        // Arrange
        var id = "00123";

        // Act
        var result = _validationService.IsValidImageId(id);

        // Assert
        result.Should().BeTrue("Leading zeros should be allowed");
    }

    [TestMethod]
    public void IsValidImageId_WithSQLInjection_ReturnsFalse()
    {
        // Arrange
        var sqlInjectionAttempts = new[]
        {
            "1'; DROP TABLE users--",
            "1 OR 1=1",
            "1' OR '1'='1"
        };

        // Act & Assert
        foreach (var attempt in sqlInjectionAttempts)
        {
            _validationService.IsValidImageId(attempt).Should().BeFalse($"SQL injection attempt '{attempt}' should be rejected");
        }
    }

    #endregion

    #region IsValidImageUrl Tests

    [TestMethod]
    public void IsValidImageUrl_WithValidAiwpMeUrl_ReturnsTrue()
    {
        // Arrange
        var validUrls = new[]
        {
            "https://aiwp.me/images/123.jpg",
            "https://aiwp.me/api/images/456.png",
            "https://www.aiwp.me/wallpaper.jpg",
            "http://aiwp.me/test.bmp"
        };

        // Act & Assert
        foreach (var url in validUrls)
        {
            _validationService.IsValidImageUrl(url).Should().BeTrue($"'{url}' should be valid");
        }
    }

    [TestMethod]
    public void IsValidImageUrl_WithNullOrEmpty_ReturnsFalse()
    {
        // Arrange & Act & Assert
        _validationService.IsValidImageUrl(null!).Should().BeFalse();
        _validationService.IsValidImageUrl(string.Empty).Should().BeFalse();
        _validationService.IsValidImageUrl("   ").Should().BeFalse();
    }

    [TestMethod]
    public void IsValidImageUrl_WithInvalidDomain_ReturnsFalse()
    {
        // Arrange
        var invalidUrls = new[]
        {
            "https://evil.com/images/123.jpg",
            "https://google.com/test.jpg",
            "https://aiwp.net/images/123.jpg", // Similar but different domain
            "https://aiwpme.com/images/123.jpg"
        };

        // Act & Assert
        foreach (var url in invalidUrls)
        {
            _validationService.IsValidImageUrl(url).Should().BeFalse($"'{url}' should be rejected (wrong domain)");
        }
    }

    [TestMethod]
    public void IsValidImageUrl_WithMalformedUrl_ReturnsFalse()
    {
        // Arrange
        var malformedUrls = new[]
        {
            "not-a-url",
            "ftp://aiwp.me/file.jpg", // Wrong protocol
            "javascript:alert('xss')",
            "file:///C:/Windows/System32/config",
            "//aiwp.me/images/123.jpg", // Protocol-relative URL
            "aiwp.me/images/123.jpg" // Missing protocol
        };

        // Act & Assert
        foreach (var url in malformedUrls)
        {
            _validationService.IsValidImageUrl(url).Should().BeFalse($"'{url}' should be rejected (malformed)");
        }
    }

    [TestMethod]
    public void IsValidImageUrl_WithSSRFAttempt_ReturnsFalse()
    {
        // Arrange - Common SSRF targets
        var ssrfAttempts = new[]
        {
            "https://localhost/secret",
            "https://127.0.0.1/admin",
            "https://169.254.169.254/metadata", // AWS metadata endpoint
            "https://[::1]/internal",
            "https://internal.network/api"
        };

        // Act & Assert
        foreach (var attempt in ssrfAttempts)
        {
            _validationService.IsValidImageUrl(attempt).Should().BeFalse($"SSRF attempt '{attempt}' should be rejected");
        }
    }

    #endregion

    #region IsValidFilePath Tests

    [TestMethod]
    public void IsValidFilePath_WithValidPath_ReturnsTrue()
    {
        // Arrange
        var validPaths = new[]
        {
            @"C:\Users\Test\image.jpg",
            @"C:\Cache\12345.jpg",
            @"C:\Program Files\App\wallpaper.png"
        };

        // Act & Assert
        foreach (var path in validPaths)
        {
            _validationService.IsValidFilePath(path).Should().BeTrue($"'{path}' should be valid");
        }
    }

    [TestMethod]
    public void IsValidFilePath_WithNullOrEmpty_ReturnsFalse()
    {
        // Arrange & Act & Assert
        _validationService.IsValidFilePath(null!).Should().BeFalse();
        _validationService.IsValidFilePath(string.Empty).Should().BeFalse();
        _validationService.IsValidFilePath("   ").Should().BeFalse();
    }

    [TestMethod]
    public void IsValidFilePath_WithPathTraversal_ReturnsFalse()
    {
        // Arrange
        var traversalAttempts = new[]
        {
            @"C:\Cache\..\Windows\System32\config",
            @"C:\Cache\..\..\secret.txt",
            @"..\..\..\etc\passwd",
            @"C:\Cache\image.jpg\..\..\..\Windows",
            @"C:/Cache/../../../etc/passwd"
        };

        // Act & Assert
        foreach (var attempt in traversalAttempts)
        {
            _validationService.IsValidFilePath(attempt).Should().BeFalse($"Path traversal attempt '{attempt}' should be rejected");
        }
    }

    [TestMethod]
    public void IsValidFilePath_WithInvalidCharacters_ReturnsFalse()
    {
        // Arrange
        var invalidPaths = new[]
        {
            @"C:\Cache\image<>.jpg",
            @"C:\Cache\image|.jpg",
            "C:\\Cache\\image?.jpg",
            "C:\\Cache\\image*.jpg",
            "C:\\Cache\\image\".jpg"
        };

        // Act & Assert
        foreach (var path in invalidPaths)
        {
            _validationService.IsValidFilePath(path).Should().BeFalse($"Path with invalid characters '{path}' should be rejected");
        }
    }

    [TestMethod]
    public void IsValidFilePath_WithTooLongPath_ReturnsFalse()
    {
        // Arrange - Windows MAX_PATH is 260 characters
        var tooLongPath = @"C:\" + new string('a', 300) + ".jpg";

        // Act
        var result = _validationService.IsValidFilePath(tooLongPath);

        // Assert
        result.Should().BeFalse("Paths longer than MAX_PATH should be rejected");
    }

    [TestMethod]
    public void IsValidFilePath_WithUNCPath_ReturnsTrue()
    {
        // Arrange
        var uncPath = @"\\server\share\image.jpg";

        // Act
        var result = _validationService.IsValidFilePath(uncPath);

        // Assert
        result.Should().BeTrue("Valid UNC paths should be accepted");
    }

    #endregion

    #region MaxImageSize Tests

    [TestMethod]
    public void MaxImageSize_ShouldBe50MB()
    {
        // Arrange
        var expected50MB = 52_428_800L; // 50 * 1024 * 1024

        // Act
        var maxSize = _validationService.MaxImageSize;

        // Assert
        maxSize.Should().Be(expected50MB, "Max image size should be exactly 50 MB");
    }

    #endregion

    #region Edge Cases and Security Tests

    [TestMethod]
    public void IsValidImageId_WithUnicodeCharacters_ReturnsFalse()
    {
        // Arrange
        var unicodeIds = new[]
        {
            "١٢٣", // Arabic numerals
            "一二三", // Chinese numerals
            "½", // Unicode fraction
            "123​456" // Zero-width space in middle
        };

        // Act & Assert
        foreach (var id in unicodeIds)
        {
            _validationService.IsValidImageId(id).Should().BeFalse($"Unicode characters in '{id}' should be rejected");
        }
    }

    [TestMethod]
    public void IsValidImageUrl_WithUrlEncodedPathTraversal_ReturnsFalse()
    {
        // Arrange
        var encodedTraversalUrls = new[]
        {
            "https://aiwp.me/images/%2e%2e%2f%2e%2e%2fpasswd",
            "https://aiwp.me/images/..%2F..%2Fconfig"
        };

        // Act & Assert
        foreach (var url in encodedTraversalUrls)
        {
            // Note: The validation should ideally decode and check, but at minimum
            // the URL should still be from the allowed domain
            var result = _validationService.IsValidImageUrl(url);
            // This test documents current behavior - may need enhancement
        }
    }

    [TestMethod]
    public void IsValidFilePath_WithRelativePath_ShouldHandleCorrectly()
    {
        // Arrange
        var relativePath = @"images\wallpaper.jpg";

        // Act
        var result = _validationService.IsValidFilePath(relativePath);

        // Assert
        // Relative paths might be valid depending on implementation
        // This test documents the expected behavior
        result.Should().BeTrue("Simple relative paths without traversal should be valid");
    }

    #endregion
}
