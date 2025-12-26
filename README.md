# Jin's Credit Card Manager

A native iOS app built with SwiftUI to help manage credit card payment reminders.

## Features

- 💳 **Card Management**: Add and manage multiple credit cards
- 🔔 **Payment Reminders**: Get notified about upcoming payment due dates
- ⚙️ **Customizable Settings**: Configure reminder window (1-30 days ahead)
- 🎨 **Color Coding**: Assign colors to cards for easy identification
- 💾 **Local Storage**: All data stored securely on device using SwiftData

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Open `Jin's Credit Card Manager.xcodeproj` in Xcode
2. Select a simulator or connected device
3. Press `Cmd + R` to build and run

## Project Structure

This app follows the **MVVM (Model-View-ViewModel)** architecture:

```
Jin's Credit Card Manager/
├── Models/              # Data models (SwiftData)
│   ├── CreditCard.swift
│   └── AppSettings.swift
├── ViewModels/          # Business logic
│   └── CardViewModel.swift
└── Views/               # UI components
    ├── MainTabView.swift
    ├── ReminderTabView.swift
    ├── CardsTabView.swift
    └── SettingsTabView.swift
```

## Architecture: MVVM

- **Models**: Data structures with SwiftData persistence
- **ViewModels**: Business logic and data management
- **Views**: SwiftUI views for UI presentation

### Data Flow

```
User Action → View → ViewModel → Model → SwiftData
                ↓                         ↓
            UI Update ← Observable ← Save Complete
```

## Technologies

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's persistence framework
- **@Observable**: Swift's observation system
- **MVVM**: Clean architecture pattern

## Features Overview

### 1. Reminders Tab
- View upcoming payment reminders
- Color-coded urgency badges:
  - 🔴 Red: Due today
  - 🟠 Orange: Due within 3 days
  - 🔵 Blue: Due within configured window
- Sorted by urgency

### 2. Cards Tab
- View all credit cards
- Add new cards with:
  - Card name
  - Last 4 digits
  - Due date (1-31)
  - Color selection
- Delete cards

### 3. Settings Tab
- Configure reminder window (1-30 days)
- Adjust with slider control
- Changes save automatically

## Data Persistence

All data is stored locally using **SwiftData**:
- Cards persist across app launches
- Settings saved automatically
- No cloud sync (privacy-focused)
- No internet connection required

## Privacy

- ✅ All data stored locally on device
- ✅ No network requests
- ✅ No analytics or tracking
- ✅ No data collection

## Development

### Adding New Features

1. **New Data Model**: Add to `Models/`
2. **New Business Logic**: Update `ViewModels/CardViewModel.swift`
3. **New UI**: Add to `Views/`

### Testing

Run the app in simulator and test:
- Adding/deleting cards
- Viewing reminders with different due dates
- Adjusting settings
- App restart (data persistence)

## License

See `ATTRIBUTIONS.md` for third-party acknowledgments.

## Version

**v1.0** - Initial Release

---

Built with ❤️ using SwiftUI

