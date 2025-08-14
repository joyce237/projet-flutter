# HomePharma Flutter Application

HomePharma is a Flutter mobile application for finding medications at nearby pharmacies. The app supports two user roles: regular users who search for medications and pharmacists who manage inventory. It integrates Firebase for authentication and Firestore for data storage, with geolocation services for finding nearby pharmacies.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Setup
- Install Flutter SDK (recommended version 3.24.3+):
  - Linux: `snap install flutter --classic` or download from https://flutter.dev/docs/get-started/install
  - macOS: `brew install flutter` or download from https://flutter.dev/docs/get-started/install
  - Windows: Download from https://flutter.dev/docs/get-started/install
- Verify installation: `flutter doctor`
- Accept Android licenses: `flutter doctor --android-licenses`

### Bootstrap and Build Process
- **CRITICAL**: Always run these commands in sequence for a fresh setup:
  - `flutter doctor` - Check environment and dependencies
  - `flutter pub get` - Install dependencies (takes 30-60 seconds)
  - `flutter clean` - Clean build artifacts if needed
  - `flutter pub deps` - Verify dependency tree
- **Build Commands** - NEVER CANCEL these operations:
  - `flutter build apk` - Build Android APK (takes 3-8 minutes). NEVER CANCEL. Set timeout to 15+ minutes.
  - `flutter build ios` - Build iOS app (takes 5-15 minutes on macOS). NEVER CANCEL. Set timeout to 25+ minutes.
  - `flutter build web` - Build web version (takes 2-5 minutes). NEVER CANCEL. Set timeout to 10+ minutes.
- **Debug Build**:
  - `flutter run` - Run in debug mode (takes 2-5 minutes for first build). NEVER CANCEL. Set timeout to 10+ minutes.
  - `flutter run --hot-reload` - Enable hot reload for development

### Testing and Analysis
- **Unit Tests**:
  - `flutter test` - Run all unit tests (takes 30-90 seconds). NEVER CANCEL. Set timeout to 5+ minutes.
  - `flutter test test/widget_test.dart` - Run specific test file
- **Static Analysis**:
  - `flutter analyze` - Analyze code for issues (takes 10-30 seconds)
  - `flutter format .` - Format all Dart code
- **Integration Testing**:
  - `flutter drive --target=test_driver/app.dart` - Run integration tests if available

## Project Structure

### Core Application Files
- `lib/main.dart` - App entry point with Firebase initialization
- `lib/auth_wrapper.dart` - Authentication and role-based routing
- `lib/firebase_options.dart` - Firebase configuration (auto-generated)

### Key Services and Providers
- `lib/auth_service.dart` - Firebase authentication logic
- `lib/providers/auth_provider.dart` - Authentication state management
- `lib/providers/app_provider.dart` - App-wide state (theme, locale)
- `lib/providers/cart_provider.dart` - Shopping cart functionality
- `lib/services/` - Additional business logic services
- `lib/models/` - Data models (user_model.dart, cart_item.dart, order.dart)

### Screens and UI
- `lib/welcome_screen.dart` - Initial welcome/landing screen
- `lib/login_screen.dart` - User authentication
- `lib/register_screen.dart` - User registration
- `lib/user_home_screen.dart` - Main screen for regular users
- `lib/pharmacist_home_screen.dart` - Main screen for pharmacists
- `lib/screens/` - Additional screen components

### Platform Configuration
- `android/app/google-services.json` - Firebase Android configuration (present)
- `ios/Runner/GoogleService-Info.plist` - Firebase iOS configuration (may need setup)
- `web/index.html` - Web platform entry point
- `analysis_options.yaml` - Dart/Flutter linting rules

## Dependencies and Configuration

### Critical Dependencies (in pubspec.yaml)
- **Firebase**: `firebase_core: ^4.0.0`, `firebase_auth: ^6.0.0`, `cloud_firestore: ^6.0.0`
- **State Management**: `provider: ^6.1.2`
- **Geolocation**: `geolocator: ^11.0.0`, `flutter_map: ^6.1.0`, `latlong2: ^0.9.0`
- **UI/UX**: `cupertino_icons: ^1.0.8`, `flutter_native_splash: ^2.4.0`, `cached_network_image: ^3.3.0`
- **Utils**: `intl: ^0.18.1`, `http: ^1.1.0`, `shared_preferences: ^2.2.2`

### Assets Configuration
- Logo: `assets/logo.png`
- Native splash screen configured with white background
- Material Icons enabled: `uses-material-design: true`

### Known Issues and Fixes
- **VERIFIED**: Dependencies in `pubspec.yaml` are correctly placed under `dependencies` section
- Widget tests may reference non-existent counter functionality and need updates for HomePharma context
- Firebase versions are slightly older - consider upgrading to latest stable versions
- Location permissions must be configured in platform-specific files for geolocator to work

## Validation and Testing Scenarios

### ALWAYS Validate These User Scenarios After Changes:

#### Critical Authentication Scenarios
1. **New User Registration**:
   - Open app and tap "Register" from Welcome screen
   - Fill form with valid email/password
   - Verify account creation in Firebase Console
   - Confirm automatic login after registration
   - Check user role defaulted to 'user'

2. **User Login Flow**:
   - Use existing credentials to login
   - Verify AuthWrapper routes correctly based on role
   - Regular users → UserHomeScreen
   - Pharmacists → PharmacistHomeScreen (with pharmacyId)
   - Test "Remember Me" functionality if implemented

3. **Role-Based Access**:
   - Login as regular user: verify medication search functionality
   - Login as pharmacist: verify inventory management features
   - Test unauthorized access prevention between roles

#### Core Application Scenarios
4. **Geolocation and Search**:
   - Grant location permissions when prompted
   - Search for common medication (e.g., "aspirin")
   - Verify nearby pharmacies appear with distances
   - Test search filters and sorting options
   - Verify map integration with flutter_map

5. **Data Persistence**:
   - Add items to cart (if implemented)
   - Logout and login again
   - Verify data persists correctly
   - Test offline behavior if supported

#### Platform-Specific Testing
6. **Android Testing**:
   - Run `flutter run` on Android emulator
   - Test location permissions dialog
   - Verify Firebase authentication works
   - Test back button navigation
   - Check app performance and memory usage

7. **Development Hot Reload**:
   - Make UI changes while app running
   - Press 'r' for hot reload, verify changes appear
   - Press 'R' for hot restart, verify full app restart
   - Test with both light and dark themes

### Manual Testing Commands
- Start Android emulator: `flutter emulators --launch <emulator-id>`
- List available devices: `flutter devices`
- Run on specific device: `flutter run -d <device-id>`
- Install APK: `flutter install` (after build)

## Firebase Configuration

### Current Setup
- Android configuration: Present (`android/app/google-services.json`)
- Project ID: `homepharma-45879`
- Firestore collections expected:
  - `users` - User profiles with role field ('user' or 'pharmacist')
  - `pharmacies` - Pharmacy information with location (GeoPoint)
  - `inventory` - Medication stock by pharmacy

### Platform Setup Required
- iOS: May need `ios/Runner/GoogleService-Info.plist`
- Web: May need Firebase web configuration
- Configure authentication methods in Firebase Console

## Development Workflow

### Before Making Changes
- Always run `flutter pub get` first
- Verify environment with `flutter doctor`
- Check current branch and pull latest changes

### After Making Changes
- Run `flutter analyze` to check for code issues
- Format code with `flutter format .`
- Run relevant tests with `flutter test`
- Test on at least one platform with `flutter run`
- ALWAYS manually test authentication and core user flows

### Common Commands Reference
- Hot reload: `r` (in debug mode)
- Hot restart: `R` (in debug mode)
- Quit debug mode: `q`
- Clear cache: `flutter clean && flutter pub get`
- Update dependencies: `flutter pub upgrade`

## Common Commands Output Reference

### Repository Structure
```
ls -la [project-root]
.git/
.github/
.metadata
CLAUDE.md
README.md
analysis_options.yaml
android/
assets/
firebase.json
ios/
lib/
linux/
macos/
pubspec.lock
pubspec.yaml
test/
web/
windows/
```

### Key Files Verified Present
- `pubspec.yaml` - Project configuration and dependencies
- `android/app/google-services.json` - Firebase Android configuration (684 bytes)
- `lib/main.dart` - App entry point
- `lib/auth_wrapper.dart` - Authentication routing
- `test/widget_test.dart` - Basic widget tests
- `test/models/user_model_test.dart` - Unit tests for user model

## Troubleshooting

### Command Timing Expectations
- `flutter doctor`: 5-15 seconds
- `flutter pub get`: 30-90 seconds (first time), 10-30 seconds (subsequent)
- `flutter clean`: 2-5 seconds
- `flutter analyze`: 10-45 seconds
- `flutter test`: 30-90 seconds for full test suite
- `flutter run` (first time): 3-8 minutes. NEVER CANCEL. Set timeout to 15+ minutes.
- `flutter build apk`: 3-8 minutes. NEVER CANCEL. Set timeout to 15+ minutes.
- `flutter build ios`: 5-15 minutes on macOS. NEVER CANCEL. Set timeout to 25+ minutes.

### Common Issues
- Build failures: Try `flutter clean && flutter pub get`
- Android license issues: Run `flutter doctor --android-licenses`
- iOS signing issues: Check Xcode configuration
- Web CORS issues: Use `flutter run -d chrome --web-renderer html`
- Firebase authentication issues: Verify configuration files and project settings
- Permission errors: Check Android permissions in `android/app/src/main/AndroidManifest.xml`
- Geolocation issues: Ensure location permissions are configured for all platforms

### Performance Optimization
- Use `flutter build apk --release` for production builds
- Profile performance: `flutter run --profile`
- Analyze bundle size: `flutter build apk --analyze-size`
- Monitor memory usage: `flutter run --observatory-port=8080`

### Environment Validation
Before starting work, always run:
```bash
flutter doctor -v
flutter --version
flutter config --list
```

Expected Flutter version: 3.24.3+ stable channel

Remember: Flutter builds can take significant time. Always set appropriate timeouts (10-25 minutes) and NEVER CANCEL long-running build operations.