# Alphanumeric Image ID Support - Fix Documentation

## Issue

The application was rejecting valid wallpaper links from aiwp.me with the error:

```
Invalid wallpaper ID: HNVOO3GJH7. Please check the link and try again.
```

**Example failing link:** `wallpaper0-changer:HNVOO3GJH7.jpg`

## Root Cause

The `ValidationService` was configured to only accept **numeric-only** image IDs:

```csharp
// OLD - Only digits allowed
private static readonly Regex ImageIdRegex = new(@"^[0-9]+$", RegexOptions.Compiled);

// Validation rejected:
// - Letters (HNVOO3GJH7)
// - Hyphens (image-123)
// - Underscores (image_456)
// - File extensions (.jpg)
```

This was based on the initial assumption that aiwp.me used numeric IDs like `1`, `2`, `123`, etc.

However, aiwp.me actually uses **alphanumeric IDs** like:
- `HNVOO3GJH7`
- `ABC123DEF`
- `image-test-01`

## Solution

### 1. Updated Validation Pattern

**File:** `WallpaperChanger\Services\ValidationService.cs`

**Changes:**
- Updated regex to support alphanumeric characters, hyphens, and underscores
- Increased max length from 10 to 50 characters
- Updated documentation

```csharp
// NEW - Alphanumeric, hyphens, and underscores allowed
private static readonly Regex ImageIdRegex = new(@"^[a-zA-Z0-9_-]+$", RegexOptions.Compiled);

public bool IsValidImageId(string imageId)
{
    if (string.IsNullOrWhiteSpace(imageId))
        return false;

    // Increased limit to 50 to support longer alphanumeric IDs
    if (imageId.Length > 50 || imageId.Length == 0)
        return false;

    return ImageIdRegex.IsMatch(imageId);
}
```

**Now accepts:**
- ✅ `123` (numeric - backwards compatible)
- ✅ `HNVOO3GJH7` (alphanumeric)
- ✅ `abc123` (mixed case)
- ✅ `image-test` (with hyphens)
- ✅ `image_456` (with underscores)
- ✅ `Test-Image_1` (combination)

**Still rejects:**
- ❌ `test.jpg` (periods not allowed - file extensions stripped separately)
- ❌ `test/path` (slashes not allowed - security)
- ❌ `test space` (spaces not allowed)
- ❌ `test@#$` (special characters not allowed)

### 2. Added File Extension Stripping

**File:** `WallpaperChanger\Form1.cs`

**Changes:**
Added logic to automatically strip common image file extensions from the image ID.

```csharp
// Strip file extension if present (handles .jpg, .png, .jpeg, etc.)
if (imageId.Contains('.'))
{
    int dotIndex = imageId.LastIndexOf('.');
    string extension = imageId.Substring(dotIndex).ToLowerInvariant();

    // Only strip if it's a common image extension
    if (extension == ".jpg" || extension == ".jpeg" || extension == ".png" ||
        extension == ".bmp" || extension == ".gif" || extension == ".webp")
    {
        imageId = imageId.Substring(0, dotIndex);
        _logger.LogDebug($"Stripped file extension '{extension}' from image ID");
    }
}
```

**Examples:**
- `wallpaper0-changer:HNVOO3GJH7.jpg` → Image ID: `HNVOO3GJH7` ✅
- `wallpaper0-changer:test123.png` → Image ID: `test123` ✅
- `wallpaper0-changer:ABC.jpeg` → Image ID: `ABC` ✅

### 3. Updated Tests

**File:** `WallpaperChanger.Tests\Services\ValidationServiceTests.cs`

**Changes:**
- Split `IsValidImageId_WithNonNumericCharacters_ReturnsFalse` into two tests:
  1. `IsValidImageId_WithInvalidCharacters_ReturnsFalse` - Tests truly invalid characters
  2. `IsValidImageId_WithAlphanumericCharacters_ReturnsTrue` - Tests now-valid alphanumeric IDs

- Updated `IsValidImageId_WithTooLongId_ReturnsFalse` to test 51 characters (new limit is 50)

**Test Results:**
- ✅ **60/60 tests passing (100%)**
- Added test for real example: `HNVOO3GJH7`

## Technical Details

### Security Considerations

The new validation pattern `^[a-zA-Z0-9_-]+$` is still secure because:

1. **No path traversal:** Doesn't allow `/`, `\`, or `.` (except when stripped as file extension)
2. **No command injection:** Doesn't allow spaces, pipes, semicolons, or other shell metacharacters
3. **No SQL injection:** Alphanumeric with hyphens/underscores is safe
4. **Length limited:** Maximum 50 characters prevents buffer overflow attacks

### Backwards Compatibility

✅ **Fully backwards compatible** - All previously valid numeric IDs still work:
- `wallpaper0-changer:1` ✅
- `wallpaper0-changer:123` ✅
- `wallpaper0-changer:999999` ✅

### API Integration

The image ID is used in the API URL:
```
Input:  wallpaper0-changer:HNVOO3GJH7.jpg
Parsed: HNVOO3GJH7
API:    https://aiwp.me/api/images/HNVOO3GJH7.json
```

## Testing

### Manual Test Cases

Test these URLs to verify the fix:

```
wallpaper0-changer:HNVOO3GJH7.jpg          ✅ Should work
wallpaper0-changer:HNVOO3GJH7              ✅ Should work
wallpaper0-changer:123                      ✅ Should work (backwards compatible)
wallpaper0-changer:test-image-01           ✅ Should work
wallpaper0-changer:ABC_123.png             ✅ Should work
wallpaper0-changer:test.invalid!@#         ❌ Should fail (special chars)
wallpaper0-changer:../../../etc/passwd     ❌ Should fail (security)
```

### Automated Tests

Run the test suite:
```powershell
dotnet test
```

**Expected output:**
```
Total tests: 60
     Passed: 60
     Failed: 0
```

## Files Modified

| File | Changes | Lines |
|------|---------|-------|
| `WallpaperChanger\Services\ValidationService.cs` | Updated regex pattern, increased max length, updated docs | 15-45 |
| `WallpaperChanger\Form1.cs` | Added file extension stripping logic | 124-137 |
| `WallpaperChanger.Tests\Services\ValidationServiceTests.cs` | Split test, added alphanumeric test cases | 44-100 |

## Deployment

### Option 1: Quick Test (Run from build)

```powershell
# Build and run
dotnet build
cd WallpaperChanger\bin\Debug\net9.0-windows
.\WallpaperChanger.exe
```

### Option 2: Install New Version

```powershell
# Build release
dotnet publish WallpaperChanger/WallpaperChanger.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish

# Build installer (if you have Inno Setup)
iscc WallpaperChanger.iss

# Install
.\installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe
```

## Verification

After installing, verify the fix works:

1. **Test alphanumeric ID:**
   - Create test link: `wallpaper0-changer:TEST123.jpg`
   - Click the link
   - Should see: "Downloading wallpaper TEST123..." ✅

2. **Test with file extension:**
   - Create test link: `wallpaper0-changer:HNVOO3GJH7.jpg`
   - Click the link
   - Extension should be stripped automatically ✅

3. **Test backwards compatibility:**
   - Create test link: `wallpaper0-changer:123`
   - Click the link
   - Should work as before ✅

## Future Considerations

### If aiwp.me API Changes Further

If aiwp.me starts using IDs with other characters (e.g., periods, slashes), update the regex:

```csharp
// Current: Letters, numbers, hyphens, underscores
private static readonly Regex ImageIdRegex = new(@"^[a-zA-Z0-9_-]+$", RegexOptions.Compiled);

// Example: Add periods (but still prevent path traversal)
private static readonly Regex ImageIdRegex = new(@"^[a-zA-Z0-9._-]+$", RegexOptions.Compiled);
```

**Important:** Always validate that any new characters don't introduce security vulnerabilities!

### Logging

The application now logs when file extensions are stripped:

```
[DEBUG] Stripped file extension '.jpg' from image ID
```

Check logs at: `%LOCALAPPDATA%\WallpaperChanger\Logs\wallpaper-changer-YYYY-MM-DD.log`

## Summary

**Problem:** Application rejected alphanumeric image IDs from aiwp.me

**Solution:**
- ✅ Updated validation to accept alphanumeric IDs
- ✅ Automatically strip file extensions
- ✅ Maintained backwards compatibility
- ✅ Preserved security (no path traversal, command injection, etc.)
- ✅ All 60 tests passing

**Result:** Application now works with both numeric and alphanumeric image IDs from aiwp.me!

---

**Last Updated:** December 5, 2025
**Version:** 1.2.1 (unreleased)
