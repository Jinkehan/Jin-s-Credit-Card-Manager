# J Due

A native iOS app built with SwiftUI to help manage credit card payment reminders.

## Features

- 💳 **Card Management**: Add, edit, and manage multiple credit cards
- 🔔 **Payment Reminders**: Get notified about upcoming payment due dates
- ⏰ **Smart Notifications**: Receive push notifications at 8 AM on reminder days
- ⚙️ **Per-Card Reminders**: Configure reminder window for each card individually (1-30 days ahead, default 5 days)
- 🎨 **Color Coding**: Assign colors to cards for easy identification
- 💾 **Local Storage**: All data stored securely on device using SwiftData
- 🔄 **Auto-Scheduling**: Notifications automatically scheduled for the next 12 months
- ✨ **AI-Powered Rewards**: Get personalized card recommendations for maximum rewards using Perplexity AI

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
J Due/
├── Models/              # Data models (SwiftData)
│   ├── CreditCard.swift
│   ├── CardBenefit.swift
│   └── PredefinedCard.swift
├── ViewModels/          # Business logic
│   ├── CardViewModel.swift
│   ├── BenefitsViewModel.swift
│   └── RewardsViewModel.swift
├── Views/               # UI components
│   ├── MainTabView.swift
│   ├── ReminderTabView.swift
│   ├── CardsTabView.swift
│   ├── BenefitsTabView.swift
│   ├── BenefitsListView.swift
│   ├── RewardsTabView.swift
│   ├── SettingsView.swift
│   ├── TestBenefitsView.swift
│   └── SharedComponents.swift
└── Services/            # System services
    ├── NotificationManager.swift
    ├── CardBenefitsService.swift
    ├── ImageCacheService.swift
    ├── LocalBenefitsStore.swift
    └── PerplexityService.swift
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
- **UserNotifications**: Local push notifications
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
- Tap any card to edit its details
- Add new cards with:
  - Card name
  - Last 4 digits
  - Due date (1-31 or last day of month)
  - Color selection
  - Reminder days ahead (1-30 days, default 5)
- Edit existing cards to update any field
- Delete cards (automatically cancels associated notifications)

### 3. Rewards Tab (NEW!)
- **AI-Powered Recommendations**: Enter any store name and get personalized card recommendations
- **Maximize Rewards**: Find the best card for each purchase based on your wallet
- **Smart Analysis**: Considers category bonuses, merchant-specific rewards, and cashback rates
- **Multiple Options**: Get up to 3 ranked recommendations with estimated reward rates
- **Perplexity Integration**: Powered by Perplexity AI for accurate, real-time recommendations
- **Easy Setup**: Simple API key configuration in-app

### 4. Notification System
- **Automatic Scheduling**: Notifications are automatically scheduled when you add or edit a card
- **8 AM Delivery**: All notifications are delivered at 8:00 AM on the reminder day
- **12-Month Horizon**: Notifications scheduled for the next 12 months
- **Smart Updates**: Editing a card reschedules its notifications
- **Clean Deletion**: Deleting a card cancels all its pending notifications
- **Permission Request**: App requests notification permission on first launch
- **Foreground Alerts**: Notifications appear even when app is open

## Data Persistence

All data is stored locally using **SwiftData**:
- Cards and their individual reminder settings persist across app launches
- Changes saved automatically
- No cloud sync (privacy-focused)
- No internet connection required

## Privacy

- ✅ All data stored locally on device
- ✅ No analytics or tracking
- ✅ No data collection
- ℹ️ Rewards feature requires Perplexity API (optional, user-provided API key)
- ℹ️ API key stored securely in UserDefaults on device

## Development

### Adding New Features

1. **New Data Model**: Add to `Models/`
2. **New Business Logic**: Update `ViewModels/CardViewModel.swift`
3. **New UI**: Add to `Views/`

### Testing

Run the app in simulator and test:
- Adding/editing/deleting cards
- Setting different reminder days for each card
- Viewing reminders with different due dates
- Tapping cards to edit their details
- App restart (data persistence)
- Notification permissions
- Scheduled notifications (check Settings > Notifications on device/simulator)

## License

See `ATTRIBUTIONS.md` for third-party acknowledgments.

## Setup Instructions

### Perplexity API Key (for Rewards feature)

1. Visit [perplexity.ai](https://www.perplexity.ai)
2. Sign up or log in to your account
3. Navigate to API settings
4. Generate a new API key
5. In the app, go to the Rewards tab
6. Tap the key icon in the top right
7. Enter your API key and save

The Rewards feature will not work without an API key, but all other features remain fully functional.

## Version

**v2.0** - Added AI-Powered Rewards Recommendations

---

Built with ❤️ using SwiftUI

