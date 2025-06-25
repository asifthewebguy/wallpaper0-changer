# GitHub Actions CI/CD Pipeline

This directory contains the complete CI/CD pipeline for the Wallpaper Changer project, ensuring automated builds, testing, version management, and releases.

## 🚀 Workflows Overview

### 1. **CI Workflow** (`ci.yml`)
**Triggers**: Push to master, Pull requests, Manual dispatch

**Jobs**:
- **Build and Test**: Compiles both framework-dependent and self-contained builds, runs tests
- **Build Installers**: Creates all installer types (PowerShell, MSI, NSIS, Batch)

**Features**:
- ✅ .NET 9.0 build and test
- ✅ NuGet package caching
- ✅ Test result reporting
- ✅ Artifact uploads for builds and installers
- ✅ Automatic installer building on master branch

### 2. **Release Workflow** (`release.yml`)
**Triggers**: Git tags (v*), Manual dispatch with version input

**Jobs**:
- **Validate Version**: Checks for version conflicts and existing releases
- **Build and Test**: Compiles application with version updates
- **Build Installers**: Creates all installer packages
- **Create Release**: Publishes GitHub release with all assets

**Features**:
- ✅ Version conflict prevention
- ✅ Automatic version injection into project files
- ✅ Multiple installer formats
- ✅ Comprehensive release packages
- ✅ Pre-release support

### 3. **Version Check Workflow** (`version-check.yml`)
**Triggers**: Pull requests affecting version-related files

**Jobs**:
- **Check Version Consistency**: Validates version consistency across all files
- **Suggest Next Version**: Analyzes changes and suggests appropriate version increment

**Features**:
- ✅ Cross-file version validation
- ✅ Semantic versioning suggestions
- ✅ Change impact analysis
- ✅ Version conflict detection

### 4. **Update Version Workflow** (`update-version.yml`)
**Triggers**: Manual dispatch with version input

**Jobs**:
- **Update Version**: Updates version across all project files and creates PR

**Features**:
- ✅ Project-wide version updates
- ✅ Installer script updates
- ✅ CI/CD workflow updates
- ✅ Documentation updates
- ✅ Automatic PR creation

## 🔄 Development Workflow

### Standard Development Process

1. **Feature Development**:
   ```bash
   git checkout -b feature/my-feature
   # Make changes
   git commit -m "feat: add new feature"
   git push origin feature/my-feature
   ```

2. **Create Pull Request**:
   - CI workflow runs automatically
   - Version check validates consistency
   - Tests must pass before merge

3. **Version Update** (when ready for release):
   - Go to Actions → "Update Version"
   - Enter new version (e.g., 1.2.0)
   - Workflow creates PR with version updates
   - Review and merge the version PR

4. **Create Release**:
   - Go to Actions → "Create Release"
   - Enter version and release options
   - Workflow builds and publishes release

### Alternative: Tag-based Release

```bash
git tag v1.2.0
git push origin v1.2.0
# Release workflow triggers automatically
```

## 📦 Build Artifacts

### CI Builds
- `WallpaperChanger-framework-dependent`: Requires .NET 9.0 runtime
- `WallpaperChanger-self-contained`: Standalone executable
- `WallpaperChanger-installers`: All installer packages

### Release Assets
- `WallpaperChanger-v{version}.zip`: Legacy framework-dependent package
- `WallpaperChanger-Standalone-v{version}.zip`: Self-contained package
- `WallpaperChanger-PowerShell-v{version}.zip`: PowerShell installer package
- `WallpaperChanger-Batch-v{version}.zip`: Batch installer package
- `WallpaperChanger-Setup-v{version}.exe`: NSIS installer
- `WallpaperChanger-v{version}.msi`: MSI installer (when available)

## 🔧 Configuration

### Environment Variables
- `DOTNET_VERSION`: .NET version (currently 9.0.x)
- `BUILD_CONFIGURATION`: Build configuration (Release)
- `APP_VERSION`: Application version (1.1.0)

### Secrets Required
- `GITHUB_TOKEN`: Automatically provided by GitHub

### Permissions
All workflows are configured with the minimum required permissions:
- **CI Workflow**: `contents: read`, `actions: read`
- **Release Workflow**: `contents: write`, `packages: write`, `actions: read`
- **Version Check**: `contents: read`, `actions: read`
- **Update Version**: `contents: write`, `pull-requests: write`, `issues: write`, `actions: read`

### Dependencies
- **WiX Toolset**: Auto-installed for MSI builds
- **NSIS**: Auto-installed for NSIS builds
- **.NET 9.0 SDK**: Provided by GitHub runners

## 🛡️ Version Management

### Version Consistency
The pipeline ensures version consistency across:
- `WallpaperChanger/WallpaperChanger.csproj`
- `installer/Install-WallpaperChanger.ps1`
- `installer/WallpaperChanger.wxs`
- `installer/WallpaperChanger.nsi`
- `installer/Build-*.ps1` scripts
- `.github/workflows/ci.yml`

### Version Format
- **Semantic Versioning**: `MAJOR.MINOR.PATCH` (e.g., 1.2.0)
- **Assembly Version**: `MAJOR.MINOR.PATCH.0` (e.g., 1.2.0.0)
- **Git Tags**: `vMAJOR.MINOR.PATCH` (e.g., v1.2.0)

### Conflict Prevention
- ✅ Checks for existing releases before creating new ones
- ✅ Validates version format
- ✅ Ensures cross-file consistency
- ✅ Prevents duplicate releases

## 🚨 Troubleshooting

### Common Issues

1. **Version Mismatch Errors**:
   - Use "Update Version" workflow to sync all files
   - Check version-check.yml output for specific conflicts

2. **Build Failures**:
   - Check .NET version compatibility
   - Verify all required files are present
   - Review test failures in CI output

3. **Installer Build Failures**:
   - WiX/NSIS installation issues in CI
   - Missing source files
   - Version format problems

4. **Release Creation Failures**:
   - Version already exists
   - Missing required artifacts
   - Permission issues

5. **Permission Errors**:
   - "Resource not accessible by integration"
   - Check workflow permissions in `.github/workflows/*.yml`
   - Ensure repository settings allow Actions to create PRs

### Debug Steps

1. **Check Workflow Logs**:
   - Go to Actions tab
   - Click on failed workflow
   - Review job logs for errors

2. **Local Testing**:
   ```bash
   # Test build locally
   dotnet clean && dotnet restore && dotnet build --configuration Release
   
   # Test installers locally
   cd installer
   .\Build-All-Installers.ps1 -BuildTypes "PowerShell"
   ```

3. **Version Validation**:
   ```bash
   # Check current versions
   grep -r "1\.[0-9]\+\.[0-9]\+" . --include="*.csproj" --include="*.ps1" --include="*.wxs" --include="*.nsi"
   ```

## 📈 Monitoring

### Success Metrics
- ✅ All CI builds pass
- ✅ All tests pass
- ✅ Installers build successfully
- ✅ Releases deploy without errors
- ✅ Version consistency maintained

### Notifications
- GitHub notifications for workflow failures
- PR status checks prevent merging broken code
- Release notifications for successful deployments

## 🔮 Future Enhancements

### Planned Improvements
- [ ] Code signing for executables and installers
- [ ] Automated security scanning
- [ ] Performance benchmarking
- [ ] Multi-platform builds (if needed)
- [ ] Automated changelog generation
- [ ] Integration testing with real wallpaper APIs

### Maintenance
- Regular updates to GitHub Actions versions
- .NET version updates as needed
- Installer framework updates
- Security patch management

---

**Need Help?** Check the workflow logs in the Actions tab or review the individual workflow files for detailed configuration.
