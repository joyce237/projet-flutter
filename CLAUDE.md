# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HomePharma is a Flutter mobile application for finding medications at nearby pharmacies. The app supports two user roles: regular users who search for medications and pharmacists who manage inventory. It integrates Firebase for authentication and Firestore for data storage, with geolocation services for finding nearby pharmacies.

## Development Commands

### Core Flutter Commands
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter test` - Run unit tests
- `flutter analyze` - Analyze code for issues
- `flutter doctor` - Check Flutter installation and dependencies

### Firebase Setup
The project uses Firebase with configuration files already generated. Android includes `google-services.json` for Firebase integration.

## Architecture

### Authentication Flow
The app uses Firebase Auth with a custom `AuthWrapper` that routes users based on their role:
- `main.dart` → `AuthWrapper` → Role-based routing
- Unauthenticated users: `WelcomeScreen`
- Users with role 'user': `UserHomeScreen`
- Users with role 'pharmacist': `PharmacistHomeScreen`

### Core Services
- `AuthService` - Firebase authentication (register, signIn, signOut)
- `SearchService` - Medication search with geolocation filtering
- `LocationService` - GPS location handling with permission management

### Data Structure
The app expects these Firestore collections:
- `users` - User profiles with role field ('user' or 'pharmacist')
- `pharmacies` - Pharmacy information with location (GeoPoint)
- `inventory` - Medication stock by pharmacy

### Key Dependencies
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`
- Geolocation: `geolocator`, `flutter_map`, `latlong2`
- State Management: `provider`
- UI: `cupertino_icons`, `flutter_native_splash`

Note: Dependencies in `pubspec.yaml` are incorrectly placed under `dev_dependencies` but should be under `dependencies`.

### File Structure
- `lib/main.dart` - App entry point with Firebase initialization
- `lib/auth_wrapper.dart` - Authentication and role-based routing
- `lib/auth_service.dart` - Authentication logic
- `lib/search_service.dart` - Medication search with distance calculation
- `lib/location_service.dart` - GPS and permission handling
- Screen files: `welcome_screen.dart`, `login_screen.dart`, `register_screen.dart`, `user_home_screen.dart`, `pharmacist_home_screen.dart`

## Testing

Run tests with `flutter test`. The default widget test needs to be updated as it references a counter that doesn't exist in the current app.

## Firebase Configuration

Firebase is configured for Android (google-services.json present). iOS and web configurations may need setup for those platforms.