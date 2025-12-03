# DevOps Guide

This guide is for maintainers and contributors managing CI/CD pipelines, releases, and deployments for Wallpaper Changer.

**Other Documentation:**
- [README](README.md) - User guide and installation
- [Development Guide](DEVELOPMENT.md) - Building and contributing
- [Installer Guide](INSTALLER_GUIDE.md) - Building installers locally

## Table of Contents

- [CI/CD Overview](#cicd-overview)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Release Process](#release-process)
- [Version Management](#version-management)
- [Building Installers in CI](#building-installers-in-ci)
- [Deployment](#deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting CI/CD](#troubleshooting-cicd)

## CI/CD Overview

Wallpaper Changer uses **GitHub Actions** for continuous integration and deployment:

- **CI Pipeline** - Automated testing on every push and PR
- **Release Pipeline** - Automated installer builds and GitHub releases
- **Code Quality** - CodeQL analysis for security scanning

### Workflow Files

All workflows are located in [.github/workflows/](.github/workflows/):

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **CI** | [ci.yml](.github/workflows/ci.yml) | Push/PR to master | Build, test, create installer |
| **Release** | [release.yml](.github/workflows/release.yml) | Version tag push | Create GitHub release with assets |
| **CodeQL** | [codeql-analysis.yml](.github/workflows/codeql-analysis.yml) | Push/PR/Schedule | Security and code quality analysis |
| **Version Check** | [version-check.yml](.github/workflows/version-check.yml) | PR to master | Verify version numbers |
| **Update Version** | [update-version.yml](.github/workflows/update-version.yml) | Manual dispatch | Bulk version updates |

## GitHub Actions Workflows

### CI Workflow ([ci.yml](.github/workflows/ci.yml))

**Triggers:**
- Push to `master` branch
- Pull requests to `master`
- Manual workflow dispatch

**Jobs:**

#### 1. Build and Test
```yaml
- Checkout code
- Setup .NET 9.0
- Cache NuGet packages
- Restore dependencies
- Build (Release)
- Run tests
- Publish test results
- Upload build artifacts
```

**Outputs:**
- Framework-dependent build
- Self-contained build
- Test results

#### 2. Build Installer (master only)
```yaml
- Download self-contained build
- Install Inno Setup
- Build Inno Setup installer
- Upload installer artifact
```

**Outputs:**
- `WallpaperChanger-Setup-v1.1.3.exe`

**Permissions Required:**
```yaml
permissions:
  contents: read
  actions: read
  checks: write  # For test-reporter
```

### Release Workflow ([release.yml](.github/workflows/release.yml))

**Triggers:**
- Push of version tags (`v*`)
- Manual workflow dispatch with version input

**Jobs:**

#### 1. Validate Version
```yaml
- Extract version from tag
- Check if release already exists
- Output version and tag
```

#### 2. Build and Test
```yaml
- Update version in .csproj
- Build application
- Run tests
- Publish self-contained executable
- Upload artifact
```

#### 3. Build Installers
```yaml
- Download build artifact
- Install Inno Setup
- Update version in .iss file
- Build Inno Setup installer
- Upload installers
```

#### 4. Create Release
```yaml
- Create legacy ZIP packages
- Create self-contained ZIP
- Create GitHub release
- Upload all assets:
  - WallpaperChanger-Setup-v{version}.exe
  - WallpaperChanger-v{version}.zip
  - WallpaperChanger-Standalone-v{version}.zip
```

**Permissions Required:**
```yaml
permissions:
  contents: write
  packages: write
  actions: read
```

### CodeQL Analysis ([codeql-analysis.yml](.github/workflows/codeql-analysis.yml))

**Triggers:**
- Push to master
- Pull requests
- Weekly schedule (Mondays at 00:00 UTC)

**Purpose:**
- Scan for security vulnerabilities
- Detect code quality issues
- Find common coding errors

## Release Process

### Creating a New Release

#### Step 1: Update Version Numbers

Update version in these files:
- [WallpaperChanger/WallpaperChanger.csproj](WallpaperChanger/WallpaperChanger.csproj#L10-L12)
- [WallpaperChanger.iss](WallpaperChanger.iss#L5)
- [.github/workflows/ci.yml](.github/workflows/ci.yml#L18)
- [README.md](README.md#L34) (if referencing specific version)

Example:
```xml
<!-- WallpaperChanger.csproj -->
<Version>1.2.0</Version>
<AssemblyVersion>1.2.0.0</AssemblyVersion>
<FileVersion>1.2.0.0</FileVersion>
```

```pascal
; WallpaperChanger.iss
#define MyAppVersion "1.2.0"
```

#### Step 2: Update Release Notes

Update [RELEASE_NOTES.md](RELEASE_NOTES.md) with:
- Version number
- Release date
- New features
- Bug fixes
- Breaking changes

#### Step 3: Commit and Tag

```powershell
# Commit changes
git add .
git commit -m "Release v1.2.0: Description

- Feature 1
- Feature 2
- Bug fixes"

# Create annotated tag
git tag -a v1.2.0 -m "Wallpaper Changer v1.2.0

Brief description of release.

Full release notes: https://github.com/asifthewebguy/wallpaper0-changer/releases/tag/v1.2.0"

# Push commit and tag
git push origin master
git push origin v1.2.0
```

#### Step 4: Monitor Release Workflow

1. Go to [GitHub Actions](https://github.com/asifthewebguy/wallpaper0-changer/actions)
2. Watch the "Create Release" workflow
3. Verify all jobs complete successfully
4. Check the [Releases page](https://github.com/asifthewebguy/wallpaper0-changer/releases)

#### Step 5: Verify Release Assets

Check that the release includes:
- ✅ `WallpaperChanger-Setup-v1.2.0.exe` - Inno Setup installer
- ✅ `WallpaperChanger-v1.2.0.zip` - Framework-dependent package
- ✅ `WallpaperChanger-Standalone-v1.2.0.zip` - Self-contained package
- ✅ Release notes from RELEASE_NOTES.md

### Manual Release (Workflow Dispatch)

If you need to create a release without pushing a tag:

1. Go to [Actions → Create Release](https://github.com/asifthewebguy/wallpaper0-changer/actions/workflows/release.yml)
2. Click "Run workflow"
3. Enter version (e.g., `1.2.0`)
4. Choose prerelease option if needed
5. Click "Run workflow"

### Hotfix Release Process

For urgent fixes:

```powershell
# Create hotfix branch
git checkout -b hotfix/v1.1.4

# Make fixes
# Update version to 1.1.4
# Update release notes

# Commit and tag
git commit -m "Hotfix v1.1.4: Fix critical bug"
git tag -a v1.1.4 -m "Hotfix release"

# Merge to master
git checkout master
git merge hotfix/v1.1.4

# Push
git push origin master
git push origin v1.1.4
```

## Version Management

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

1.2.3
│ │ │
│ │ └─ Patch: Bug fixes, no new features
│ └─── Minor: New features, backwards compatible
└───── Major: Breaking changes
```

**Examples:**
- `1.0.0` → `1.0.1` - Bug fix
- `1.0.1` → `1.1.0` - New feature
- `1.9.0` → `2.0.0` - Breaking change

### Version Sync Script

To update versions across all files:

```powershell
# Update all version references to 1.2.0
$newVersion = "1.2.0"

# Update .csproj
$csproj = "WallpaperChanger/WallpaperChanger.csproj"
(Get-Content $csproj) -replace '<Version>.*</Version>', "<Version>$newVersion</Version>" `
  -replace '<AssemblyVersion>.*</AssemblyVersion>', "<AssemblyVersion>$newVersion.0</AssemblyVersion>" `
  -replace '<FileVersion>.*</FileVersion>', "<FileVersion>$newVersion.0</FileVersion>" `
  | Set-Content $csproj

# Update .iss
$iss = "WallpaperChanger.iss"
(Get-Content $iss) -replace '#define MyAppVersion ".*"', "#define MyAppVersion ""$newVersion""" `
  | Set-Content $iss

# Update ci.yml
$ci = ".github/workflows/ci.yml"
(Get-Content $ci) -replace "APP_VERSION: '.*'", "APP_VERSION: '$newVersion'" `
  | Set-Content $ci
```

## Building Installers in CI

### Inno Setup in GitHub Actions

The CI automatically installs and uses Inno Setup:

```yaml
- name: Install Inno Setup
  shell: pwsh
  run: |
    $innoSetupUrl = "https://jrsoftware.org/download.php/is.exe"
    $installerPath = "$env:TEMP\innosetup.exe"

    Invoke-WebRequest -Uri $innoSetupUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -Args "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" -Wait

- name: Build Inno Setup installer
  shell: pwsh
  run: |
    $isccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    & $isccPath "WallpaperChanger.iss"
```

### Build Artifacts

CI uploads artifacts that persist for 90 days:

**From CI workflow:**
- `WallpaperChanger-framework-dependent` - Framework-dependent build
- `WallpaperChanger-self-contained` - Self-contained build
- `WallpaperChanger-installer` - Inno Setup .exe

**From Release workflow:**
- `WallpaperChanger-self-contained-{version}` - Used by installer job
- `WallpaperChanger-installers-{version}` - All installers

## Deployment

### GitHub Releases

Releases are automatically published to:
https://github.com/asifthewebguy/wallpaper0-changer/releases

### Latest Release Badge

The README displays the latest release badge:
```markdown
![Latest Release](https://img.shields.io/github/v/release/asifthewebguy/wallpaper0-changer)
```

### Download URLs

Users can download from:
- **Latest**: `https://github.com/asifthewebguy/wallpaper0-changer/releases/latest`
- **Specific**: `https://github.com/asifthewebguy/wallpaper0-changer/releases/tag/v1.2.0`

## Monitoring and Maintenance

### CI Health Checks

Monitor workflow status:
- [Actions Dashboard](https://github.com/asifthewebguy/wallpaper0-changer/actions)
- Status badges on README
- Email notifications (configured in GitHub settings)

### Regular Maintenance Tasks

**Weekly:**
- ✅ Check for failed workflows
- ✅ Review CodeQL security alerts
- ✅ Update dependencies if needed

**Monthly:**
- ✅ Review and close stale issues
- ✅ Update documentation
- ✅ Check for .NET SDK updates

**Quarterly:**
- ✅ Review and update dependencies
- ✅ Audit GitHub Actions versions
- ✅ Review and optimize workflows

### Dependency Updates

Check for updates:
```powershell
# Check for outdated packages
dotnet list package --outdated

# Update specific package
dotnet add package PackageName --version x.y.z

# Update all packages (use with caution)
dotnet list package --outdated | Select-String ">" | ForEach-Object {
  $package = ($_ -split "\s+")[1]
  dotnet add package $package
}
```

### GitHub Actions Updates

Keep actions up to date in workflows:
```yaml
# Before
- uses: actions/checkout@v3

# After
- uses: actions/checkout@v4
```

Use [Dependabot](.github/dependabot.yml) to automatically create PRs for action updates.

## Troubleshooting CI/CD

### Common CI Failures

#### Build Failure

**Symptom:** Build job fails with compilation errors

**Solution:**
1. Check if local build works: `dotnet build -c Release`
2. Verify all files are committed
3. Check for platform-specific code
4. Review build logs in GitHub Actions

#### Test Failure

**Symptom:** Tests pass locally but fail in CI

**Common causes:**
- Path differences (Windows vs Linux)
- Missing test dependencies
- Race conditions in tests
- Environment variables

**Solution:**
```powershell
# Run tests in Release mode like CI does
dotnet test -c Release --verbosity normal
```

#### Test Reporter Permission Error

**Symptom:** `Error: HttpError: Resource not accessible by integration`

**Solution:** Ensure workflow has `checks: write` permission:
```yaml
permissions:
  contents: read
  actions: read
  checks: write  # Required for test-reporter
```

#### Installer Build Failure

**Symptom:** Inno Setup build fails

**Common causes:**
- Missing `publish/` directory
- Incorrect file paths in .iss
- Version mismatch

**Solution:**
1. Check artifact downloads completed
2. Verify file paths in WallpaperChanger.iss
3. Test locally: `.\build-installer.ps1`

### Release Workflow Issues

#### Release Already Exists

**Symptom:** Workflow fails with "Release already exists"

**Solution:**
```powershell
# Delete the existing tag and release
git tag -d v1.2.0
git push origin :refs/tags/v1.2.0

# Delete release on GitHub (via web UI or gh CLI)
gh release delete v1.2.0

# Recreate tag and push
git tag -a v1.2.0 -m "Release message"
git push origin v1.2.0
```

#### Missing Release Assets

**Symptom:** Release created but missing installer

**Solution:**
1. Check "Build Installers" job logs
2. Verify artifact upload succeeded
3. Check file paths in release upload step
4. Re-run the workflow if needed

### Debugging Workflows

#### Enable Debug Logging

Add secrets to your repository:
- `ACTIONS_RUNNER_DEBUG`: `true`
- `ACTIONS_STEP_DEBUG`: `true`

#### Download Artifacts Locally

```powershell
# Using gh CLI
gh run download <run-id>

# Or download from Actions UI
# Actions → Workflow → Run → Artifacts section
```

#### Test Workflow Locally

Use [act](https://github.com/nektos/act) to run workflows locally:
```powershell
# Install act
choco install act-cli

# Run CI workflow
act -j build-and-test
```

## Security Considerations

### Secrets Management

Never commit sensitive data. Use GitHub Secrets for:
- Code signing certificates
- API keys
- Credentials

### Code Signing

To add code signing to releases:

1. Add certificate as base64-encoded secret:
```powershell
# Convert certificate to base64
$bytes = [System.IO.File]::ReadAllBytes("cert.pfx")
$base64 = [Convert]::ToBase64String($bytes)
# Add as CODE_SIGNING_CERT_BASE64 secret
```

2. Add signing step to workflow:
```yaml
- name: Sign installer
  shell: pwsh
  run: |
    $certBytes = [Convert]::FromBase64String("${{ secrets.CODE_SIGNING_CERT_BASE64 }}")
    [IO.File]::WriteAllBytes("cert.pfx", $certBytes)

    signtool.exe sign /f cert.pfx /p "${{ secrets.CERT_PASSWORD }}" `
      /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 `
      "installer/output/InnoSetup/WallpaperChanger-Setup-v*.exe"

    Remove-Item cert.pfx
```

### Security Scanning

CodeQL scans run automatically. To trigger manually:
```powershell
# Via GitHub CLI
gh workflow run codeql-analysis.yml
```

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Inno Setup Documentation](https://jrsoftware.org/ishelp/)
- [Semantic Versioning](https://semver.org/)
- [.NET CLI Reference](https://docs.microsoft.com/en-us/dotnet/core/tools/)

---

**Quick Links:**
- [Back to README](README.md)
- [Development Guide](DEVELOPMENT.md)
- [Installer Guide](INSTALLER_GUIDE.md)
