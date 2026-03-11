# Pump Radar iOS

> **Mobile-first crypto pump intelligence** — Detect potential pump-and-dump activity before it peaks.

[![iOS CI](https://github.com/jonnb1/pump-radar-ios/actions/workflows/ios.yml/badge.svg)](https://github.com/jonnb1/pump-radar-ios/actions/workflows/ios.yml)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS 15+](https://img.shields.io/badge/iOS-15%2B-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Overview

Pump Radar is a SwiftUI iPhone app that surfaces suspicious cryptocurrency activity in real time. It connects to the [Pump Radar backend](https://github.com/jonnb1/pump-radar-backend) to fetch pump scores, flag reasons, and signal history for tracked coins.

### Key Features

| Feature | Description |
|---------|-------------|
| **Home Screen** | Ranked list of suspicious coins with pump score (0–100), activity stage, and signal change |
| **Coin Detail** | Full breakdown: score ring, price/volume metrics, flagged reasons, signal history chart |
| **Watchlist** | Add/remove coins to track; swipe-to-remove; real-time signal updates |
| **Alerts** | Push notifications and in-app alert feed when pump scores spike for tracked coins |
| **Authentication** | Sign Up / Login backed by JWT-secured REST API |
| **Settings** | Configurable detection thresholds; account management |

---

## Screenshots

> Screenshots will be added once connected to the live backend.

---

## Architecture

The app follows the **MVVM** pattern with Combine for reactive data flow:

```
PumpRadar/
├── App/                    # @main entry point and RootView
├── Models/                 # Codable data structures (Coin, User, PumpAlert, APIModels)
├── ViewModels/             # ObservableObject view models (one per screen)
├── Views/
│   ├── Home/               # HomeView + CoinRowView
│   ├── CoinDetail/         # CoinDetailView + MetricCard + SignalHistoryChart
│   ├── Watchlist/          # WatchlistView
│   ├── Alerts/             # AlertsView + AlertRowView
│   ├── Auth/               # LoginView + SignUpView
│   ├── Settings/           # SettingsView
│   └── MainTabView.swift   # Root tab bar
├── Services/
│   ├── APIService.swift    # URLSession-backed REST client (protocol-driven)
│   ├── AuthService.swift   # Login / register / refresh-token logic
│   ├── KeychainService.swift # Secure token storage
│   └── NotificationService.swift # Local + remote push notifications
└── Utilities/
    ├── Constants.swift     # API base URL, keychain keys, scoring thresholds
    └── Extensions.swift    # Double/Color/View/String helpers
```

### Design Decisions

- **Protocol-driven services** — `APIServiceProtocol` / `AuthServiceProtocol` enable full mock injection in tests.
- **Optimistic UI updates** — Watchlist toggles update immediately; failures are automatically reverted.
- **Keychain storage** — Auth tokens are stored in the iOS Keychain (never in UserDefaults).
- **Combine throughout** — All async operations use `AnyPublisher`, making the data flow explicit and testable.
- **XcodeGen** — The `.xcodeproj` is generated from `project.yml` so it stays out of version control and avoids merge conflicts.

---

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 15.0+ |
| iOS Simulator | iPhone 15 / iOS 17 |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | 2.40+ |
| [SwiftLint](https://github.com/realm/SwiftLint) | 0.54+ |
| macOS | 13 Ventura+ |

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/jonnb1/pump-radar-ios.git
cd pump-radar-ios
```

### 2. Install dependencies

```bash
# Install XcodeGen (generates the .xcodeproj from project.yml)
brew install xcodegen

# Install SwiftLint (for code quality checks)
brew install swiftlint
```

### 3. Generate the Xcode project

```bash
xcodegen generate
```

### 4. Configure the backend URL

The app reads the API base URL from the `PUMP_RADAR_API_BASE_URL` environment variable. For development:

1. Open the scheme editor in Xcode (**Product › Scheme › Edit Scheme…**).
2. Under **Run › Arguments**, add an environment variable:
   - Name: `PUMP_RADAR_API_BASE_URL`
   - Value: `http://localhost:8787/v1` (or your deployed backend URL)

Alternatively, edit `PumpRadar/Utilities/Constants.swift` to hard-code a development URL:

```swift
static let baseURL = "http://localhost:8787/v1"
```

> **Note:** In `DEBUG` builds without a backend connection, the app falls back to sample data so you can explore the UI without a running server.

### 5. Open and run

```bash
open PumpRadar.xcodeproj
```

Select the **PumpRadar** scheme and an iPhone 15 simulator, then press **⌘R**.

---

## Running Tests

```bash
xcodebuild test \
  -scheme PumpRadar \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

Or press **⌘U** in Xcode after generating the project.

### Test Coverage

| Suite | Tests |
|-------|-------|
| `ModelTests` | `Coin`, `PumpAlert`, `User` encoding/decoding, computed properties, equatability |
| `ViewModelTests` | `HomeViewModel`, `CoinDetailViewModel`, `WatchlistViewModel`, `AlertsViewModel`, `AuthViewModel` with mock services |
| `APIServiceTests` | URL construction, auth header injection, HTTP error mapping, JSON decoding |

---

## Code Quality

```bash
swiftlint lint
```

SwiftLint rules are configured in `.swiftlint.yml`. The CI pipeline enforces lint checks on every push.

---

## CI/CD Pipeline

GitHub Actions runs automatically on every push to `main`, `develop`, and feature branches:

1. **Lint** — SwiftLint code quality checks.
2. **Build** — Debug build for iPhone 15 simulator (no code signing).
3. **Test** — Full XCTest suite with test-result artifact upload.

See `.github/workflows/ios.yml` for the full workflow definition.

---

## Backend Integration

This app is designed to work with the [Pump Radar Backend](https://github.com/jonnb1/pump-radar-backend).

### REST API Endpoints Used

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/v1/coins?page=1&page_size=20` | Paginated list of suspicious coins |
| `GET` | `/v1/coins/:id` | Single coin detail |
| `POST` | `/v1/auth/login` | Authenticate user |
| `POST` | `/v1/auth/register` | Create new account |
| `POST` | `/v1/auth/refresh` | Refresh access token |
| `GET` | `/v1/watchlist` | Fetch user's watchlist |
| `POST` | `/v1/watchlist/:coinId` | Add coin to watchlist |
| `DELETE` | `/v1/watchlist/:coinId` | Remove coin from watchlist |
| `GET` | `/v1/alerts` | Fetch pump alerts |
| `POST` | `/v1/alerts/:id/read` | Mark alert as read |

---

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes, add tests, and run `swiftlint lint`.
4. Push and open a pull request against `develop`.

---

## License

[MIT](LICENSE) © Jonathan Balint
