# HabitBanao (HabitForge)

HabitForge is a Flutter app focused on helping users build better daily routines through habit tracking, reminders, analytics, mood/journal reflection, and lightweight focus tools.

## Highlights

- Create and manage habits with different frequencies and types.
- Track daily completion history and streaks.
- Calendar and statistics views for progress insights.
- Local notifications with actionable options:
	- Mark a habit as done from the notification.
	- Snooze a reminder by 15 minutes.
- Focus timer support.
- Mood tracking and journal logging.
- Onboarding flow, settings, and achievements screens.
- Offline-first local storage using Hive.

## Tech Stack

- Flutter (SDK constraint in project: `^3.29.0`)
- Dart (SDK constraint in project: `^3.7.0`)
- Riverpod for state management
- GoRouter for navigation
- Hive + SharedPreferences for local persistence
- flutter_local_notifications + timezone for reminders
- fl_chart for visualization

See full dependency details in [pubspec.yaml](pubspec.yaml).

## Project Structure

Core app code is in [lib](lib), with major areas organized as:

- [lib/main.dart](lib/main.dart): App bootstrap, Hive init, adapter registration, startup flow.
- [lib/app.dart](lib/app.dart): Root `MaterialApp.router` setup.
- [lib/router](lib/router): Route configuration with GoRouter.
- [lib/providers](lib/providers): Riverpod providers and app state.
- [lib/models](lib/models): Data models (Hive objects/adapters).
- [lib/services](lib/services): Services such as local notifications.
- [lib/screens](lib/screens): UI screens and user flows.

## Run Locally

### Prerequisites

- Flutter SDK installed and available in PATH
- Android Studio or VS Code with Flutter/Dart extensions
- A connected device/emulator/simulator

### Setup

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Test

```bash
flutter test
```

## Platform Notes

- Android and iOS are configured in [android](android) and [ios](ios).
- Notifications require runtime permission on newer Android versions and iOS.
- Timezone-aware scheduling is initialized during app startup.

## Build Examples

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (from macOS)
flutter build ios --release
```

## Development Tips

- Keep model changes in sync with Hive adapters.
- If adding new route flows, update GoRouter config in [lib/router/app_router.dart](lib/router/app_router.dart).
- Notification behavior is centralized in [lib/services/notification_service.dart](lib/services/notification_service.dart).

## Repository

- GitHub: https://github.com/vishal8526/Habitbanao

## License

No license file is currently included in this repository. Add a LICENSE file if you want to define open-source usage terms.
