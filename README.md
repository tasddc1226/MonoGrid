# MonoGrid

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0%2B-blue?logo=apple" alt="iOS 17.0+"/>
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift" alt="Swift 5.9+"/>
  <img src="https://img.shields.io/badge/SwiftUI-blue?logo=swift" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/SwiftData-green?logo=swift" alt="SwiftData"/>
</p>

## 소개

**MonoGrid**는 GitHub Contribution Graph 스타일의 미니멀리즘 습관 추적 iOS 앱입니다. 최대 3개의 핵심 습관만 관리하며, 위젯, 제어센터, 단축어를 통해 앱 실행 없이 기록하는 "Invisible Tracking" 철학을 구현합니다.

## Features

- **Focused Habit Tracking** - Manage up to 3 core habits only
- **GitHub-Style Grid Visualization** - 365-day contribution-style heatmap
- **Invisible Tracking** - Log habits without opening the app
  - Home screen widgets (Small, Medium, Large)
  - Lock screen widgets (Circular, Inline)
  - Control Center integration (iOS 18+)
  - Siri Shortcuts & Action Button support
- **iCloud Sync** - Automatic sync across all your devices
- **Dark Mode** - Full support for iOS light/dark themes
- **Accessibility** - Complete VoiceOver support
- **Bilingual** - Korean and English localization

## MonoGrid Pro

MonoGrid Pro는 더 아름답고 개인화된 습관 추적 경험을 제공합니다.

### Pro Features

| Feature | Description |
|---------|-------------|
| **Signature Colors** | 12 premium color palettes |
| **Grid Customization** | Corner radius & border adjustments |
| **Pro App Icons** | 5+ exclusive app icons |
| **Weekday Analysis** | Day-of-week completion patterns |
| **Streak Statistics** | Current, longest, and average streaks |
| **HD Export** | 1080x1080 Instagram-ready exports |

### Pricing

| Plan | Price | Description |
|------|-------|-------------|
| **Lifetime** | $10 | One-time purchase, forever access |
| **Monthly** | $2.99/mo | Cancel anytime |

### Offline Support

All Pro features work 100% offline with local license verification via iOS Keychain.

> 📚 See [Pro Documentation](docs/pro-subscription.md) for details.

## Tech Stack

| Category | Technology |
|----------|------------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI |
| **Data Persistence** | SwiftData + CloudKit |
| **Architecture** | MVVM + Repository Pattern |
| **Widgets** | WidgetKit |
| **Shortcuts** | AppIntents |
| **Payments** | Polar REST API |
| **License Storage** | iOS Keychain |
| **Minimum iOS** | iOS 17.0 |

## Getting Started

### Requirements

- Xcode 15.0+
- iOS 17.0+
- Apple Developer Account (for CloudKit & Widgets)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/MonoGrid.git
cd MonoGrid
```

2. Open the project in Xcode
```bash
open MonoGrid.xcodeproj
```

3. Configure signing
   - Select the MonoGrid target
   - Set your development team
   - Update the bundle identifier

4. Configure App Group
   - Enable App Groups capability for all targets
   - Use the same App Group identifier across targets

5. Configure iCloud
   - Enable iCloud capability
   - Configure CloudKit container

6. Build and run
```bash
# Or use Xcode's Run button (Cmd + R)
xcodebuild -scheme MonoGrid -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

```
MonoGrid/
├── MonoGrid/                    # Main App Target
│   ├── App/                     # App entry point & configuration
│   │   ├── MonoGridApp.swift
│   │   └── PersistenceController.swift
│   ├── Models/                  # SwiftData models
│   │   ├── Habit.swift
│   │   ├── HabitLog.swift
│   │   └── Pro/                 # Pro subscription models
│   │       ├── ProLicense.swift
│   │       ├── ProProduct.swift
│   │       └── SubscriptionState.swift
│   ├── ViewModels/              # Business logic
│   │   ├── HabitViewModel.swift
│   │   ├── OnboardingViewModel.swift
│   │   └── Pro/                 # Pro ViewModels
│   │       ├── ProViewModel.swift
│   │       └── PurchaseViewModel.swift
│   ├── Views/                   # SwiftUI views
│   │   ├── HomeView.swift
│   │   ├── SettingsView.swift
│   │   ├── HabitEditView.swift
│   │   ├── OnboardingView.swift
│   │   ├── Components/          # Reusable UI components
│   │   └── Pro/                 # Pro UI components
│   │       ├── PaywallView.swift
│   │       └── PurchaseButton.swift
│   ├── Repository/              # Data access layer
│   │   ├── HabitRepository.swift
│   │   ├── SwiftDataHabitRepository.swift
│   │   └── Pro/                 # Pro repositories
│   │       ├── LicenseRepository.swift
│   │       └── PolarRepository.swift
│   ├── Services/                # Business services
│   │   ├── LicenseManager.swift
│   │   └── AnalyticsService.swift
│   ├── Extensions/              # Swift extensions
│   └── Utils/                   # Utilities & constants
│       └── Pro/                 # Pro utilities
│           ├── KeychainHelper.swift
│           └── ProFeatureGate.swift
├── MonoGridWidget/              # Widget Extension
│   ├── Views/                   # Widget views
│   │   ├── SmallWidgetView.swift
│   │   ├── MediumWidgetView.swift
│   │   ├── LargeWidgetView.swift
│   │   ├── CircularLockWidgetView.swift
│   │   └── InlineLockWidgetView.swift
│   └── Providers/               # Timeline providers
├── Intents/                     # AppIntents for Siri & Shortcuts
│   ├── ToggleHabitIntent.swift
│   ├── HabitEntity.swift
│   └── AppShortcuts.swift
└── Tests/                       # Unit & UI tests
    ├── MonoGridTests/
    └── MonoGridUITests/
```

## Architecture

MonoGrid follows **MVVM + Repository** pattern:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐
│   Views     │ ──▶ │ ViewModels  │ ──▶ │     Repository      │
│  (SwiftUI)  │     │ (@Observable)│     │  (HabitRepository)  │
└─────────────┘     └─────────────┘     └──────────┬──────────┘
                                                    │
                                        ┌───────────▼───────────┐
                                        │      SwiftData        │
                                        │   + CloudKit Sync     │
                                        └───────────────────────┘
```

## Widget Configuration

### Home Screen Widgets

| Widget | Size | Features |
|--------|------|----------|
| Small | 158×158pt | Single habit toggle |
| Medium | 338×158pt | 3 habits list with toggles |
| Large | 338×354pt | 3 habits with mini grids |

### Lock Screen Widgets

| Widget | Type | Features |
|--------|------|----------|
| Circular | 76×76pt | Habit completion ring |
| Inline | Variable | Remaining habits count |

## Shortcuts & Siri

MonoGrid supports iOS Shortcuts with the following intents:

- **Toggle Habit** - Mark a habit as complete/incomplete
- Voice commands: "Check [habit name] in MonoGrid"

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Roadmap

### MVP (v1.0) ✅
- [x] 3 habits management with icons and colors
- [x] GitHub-style 365-day grid visualization
- [x] Interactive home screen widgets
- [x] Lock screen widgets
- [x] Siri Shortcuts integration
- [x] iCloud sync
- [x] Korean/English localization

### Pro Business Model (v1.1.0) ✅
- [x] Polar payment integration
- [x] Pro subscription (Lifetime $10 / Monthly $2.99)
- [x] 12 signature color palettes
- [x] Grid style customization
- [x] Pro app icons
- [x] Weekday analysis charts
- [x] Streak statistics
- [x] HD export (1080x1080)
- [x] Offline license verification

### Future (v1.2+)
- [ ] HealthKit integration
- [ ] Apple Watch app
- [ ] iPad support
- [ ] Habit templates

## License

MIT License

Copyright (c) 2026 MonoGrid

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

<p align="center">
  Made with ❤️ for minimalists who want to focus on what matters
</p>
