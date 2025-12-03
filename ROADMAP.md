# Wallpaper Changer - Development Roadmap

This document outlines the planned features and improvements for future versions of Wallpaper Changer.

**Current Version:** [v1.1.3](https://github.com/asifthewebguy/wallpaper0-changer/releases/latest)

**Other Documentation:**
- [README](README.md) - User guide
- [Development Guide](DEVELOPMENT.md) - Build and contribute
- [DevOps Guide](DEVOPS.md) - CI/CD and releases
- [Release Notes](RELEASE_NOTES.md) - Version history

## ✅ Completed Features (v1.1.3)

### Installation & Deployment
- ✅ Professional Inno Setup installer
- ✅ Self-contained build (includes .NET 9 runtime)
- ✅ User-level installation (no admin required)
- ✅ Smart uninstaller with automatic cleanup
- ✅ GitHub Actions CI/CD pipeline
- ✅ Automated release workflow

### Application Features
- ✅ Custom URL protocol handler (`wallpaper0-changer:`)
- ✅ Single instance application with named pipe IPC
- ✅ System tray integration with custom icon
- ✅ Automatic wallpaper download and caching
- ✅ Windows API integration for wallpaper setting
- ✅ Protocol handler registration scripts

### Documentation
- ✅ Comprehensive README
- ✅ Development guide
- ✅ DevOps guide
- ✅ Installer guide
- ✅ Release notes

## Version 1.2.0 (Planned)

**Focus:** Enhanced User Experience & Settings

### Core Features
- [ ] **Settings Page**
  - [ ] Create modern settings UI with tabs
  - [ ] Add option to start with Windows
  - [ ] Add option to change cache location
  - [ ] Add option to configure download behavior
  - [ ] Persist settings in JSON configuration file
  - [ ] Add settings import/export

### Enhancements
- [ ] **Improved Error Handling**
  - [ ] Add detailed error messages with recovery suggestions
  - [ ] Implement retry logic for failed downloads (3 attempts)
  - [ ] Add structured logging system (file-based)
  - [ ] Add error reporting option

### User Experience
- [ ] **Enhanced System Tray Menu**
  - [ ] Add option to view recently set wallpapers (last 10)
  - [ ] Add quick access to settings
  - [ ] Add "About" dialog with version info
  - [ ] Add "Check for updates" functionality
  - [ ] Add pause/resume functionality

### Technical Improvements
- [ ] **Code Quality**
  - [ ] Increase test coverage to >80%
  - [ ] Add XML documentation for all public APIs
  - [ ] Implement dependency injection
  - [ ] Add telemetry (opt-in)

### Security
- [ ] **Code Signing**
  - [ ] Sign the installer with a code signing certificate
  - [ ] Sign the main executable
  - [ ] Eliminate Windows SmartScreen warnings

**Target Release:** Q1 2026

## Version 1.3.0

**Focus:** Multiple Monitors & Wallpaper Management

### Core Features
- [ ] **Multiple Monitor Support**
  - [ ] Detect all connected monitors
  - [ ] Set different wallpapers on different monitors
  - [ ] Per-monitor settings and preferences
  - [ ] Span wallpaper across multiple monitors
  - [ ] Remember monitor configurations

### Enhancements
- [ ] **Wallpaper Management**
  - [ ] Favorites system with tags
  - [ ] Wallpaper history with search
  - [ ] Cache management UI
  - [ ] Bulk operations (delete, export)
  - [ ] Statistics (most used, total downloads, etc.)

### User Experience
- [ ] **Preview System**
  - [ ] Preview window before setting wallpaper
  - [ ] Thumbnail grid view of cached wallpapers
  - [ ] Quick preview in system tray tooltip
  - [ ] Fullscreen preview mode

**Target Release:** Q2 2026

## Version 1.4.0

**Focus:** Automation & Scheduling

### Core Features
- [ ] **Scheduled Wallpaper Changes**
  - [ ] Timer-based rotation (hourly, daily, weekly)
  - [ ] Time-of-day based changes
  - [ ] Random wallpaper from collection
  - [ ] Custom schedules (weekday/weekend)
  - [ ] Playlist mode (sequential)

### Enhancements
- [ ] **Additional Wallpaper Sources**
  - [ ] Unsplash API integration
  - [ ] Local folder monitoring
  - [ ] Bing daily wallpaper
  - [ ] Reddit wallpaper subreddits
  - [ ] Custom API endpoints

### User Experience
- [ ] **Collections & Organization**
  - [ ] Create wallpaper collections
  - [ ] Import/export collections
  - [ ] Share collections via URL
  - [ ] Smart collections (rules-based)

**Target Release:** Q4 2026

## Version 2.0.0 (Long-term Vision)

**Focus:** Advanced Features & Cloud Integration

### Core Features
- [ ] **Cloud Synchronization**
  - [ ] Sync settings across devices
  - [ ] Sync favorites and history
  - [ ] Optional user accounts
  - [ ] End-to-end encryption

### Enhancements
- [ ] **Advanced Customization**
  - [ ] Wallpaper effects (blur, tint, vignette, etc.)
  - [ ] Dynamic wallpapers (time-based themes)
  - [ ] Slideshow wallpapers with transitions
  - [ ] Custom wallpaper positions (fill, fit, stretch, tile)
  - [ ] Multi-layered wallpapers

### User Experience
- [ ] **Advanced UI**
  - [ ] Full-featured wallpaper browser
  - [ ] Advanced search and filtering
  - [ ] Categories, tags, and ratings
  - [ ] Color-based search
  - [ ] AI-powered recommendations

### Platform Expansion
- [ ] **Mobile Companion App**
  - [ ] Android/iOS app for remote control
  - [ ] QR code sharing of wallpapers
  - [ ] Push notifications
  - [ ] Mobile-to-desktop wallpaper transfer

**Target Release:** 2027

## Community Requests

Based on user feedback and community requests:

### High Priority
- [ ] macOS version
- [ ] Linux version
- [ ] Portable version (no installation)
- [ ] Dark mode for all UI
- [ ] Keyboard shortcuts

### Under Consideration
- [ ] Video wallpapers
- [ ] Live wallpapers
- [ ] Widget system for desktop
- [ ] Browser extension
- [ ] Discord Rich Presence

## How to Contribute

Interested in working on a feature? Here's how:

### 1. Choose a Feature
- Check [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues) for existing tasks
- Look for issues tagged with `good first issue` or `help wanted`
- Comment on the issue to claim it

### 2. Development Process
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/feature-name`
3. Follow the [Development Guide](DEVELOPMENT.md)
4. Write tests for new functionality
5. Update documentation
6. Submit a pull request

### 3. Feature Proposals
If you want to propose a new feature:
1. Open an issue with the `feature request` label
2. Describe the feature in detail
3. Explain the use case and benefits
4. Provide mockups or examples if possible
5. Wait for community feedback and maintainer approval

See [DEVELOPMENT.md#contributing](DEVELOPMENT.md#contributing) for detailed guidelines.

## Feature Requests

Have an idea not listed here? We'd love to hear it!

**Submit a feature request:**
1. Go to [GitHub Issues](https://github.com/asifthewebguy/wallpaper0-changer/issues/new)
2. Select "Feature Request" template
3. Provide:
   - Clear description of the feature
   - Use cases and examples
   - Expected behavior
   - Potential challenges
   - Any relevant mockups or references

## Roadmap Updates

This roadmap is regularly updated based on:
- Community feedback and requests
- Technical feasibility
- Development priorities
- Resource availability

**Last Updated:** December 2025

---

**Quick Links:**
- [Back to README](README.md)
- [Development Guide](DEVELOPMENT.md)
- [DevOps Guide](DEVOPS.md)
- [Release Notes](RELEASE_NOTES.md)
