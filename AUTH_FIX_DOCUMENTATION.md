# Auth Redirection Fix

## Problem
When users successfully logged in, the application remained frozen on the login page, forcing them to refresh or exit and reopen the app to access the home screen.

## Root Cause
After successful authentication, the login screen used `Navigator.of(context).pop()` which returned the user to the WelcomeScreen instead of allowing the AuthWrapper to detect the authentication state change and redirect appropriately.

## Navigation Flow Before Fix
1. WelcomeScreen → LoginScreen (via `pushReplacement`)
2. Successful login → `Navigator.pop()` → back to WelcomeScreen  
3. User stuck on WelcomeScreen despite being authenticated

## Solution
Replaced `Navigator.pop()` with `Navigator.pushAndRemoveUntil()` to clear the navigation stack and return directly to AuthWrapper.

### Changes Made

#### login_screen.dart
**Before:**
```dart
Navigator.of(context).pop();
```

**After:**
```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (context) => const AuthWrapper()),
  (route) => false,
);
```

#### register_screen.dart  
**Before:**
```dart
Navigator.of(context).popUntil((route) => route.isFirst);
```

**After:**
```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (context) => const AuthWrapper()),
  (route) => false,
);
```

## Navigation Flow After Fix
1. WelcomeScreen → LoginScreen
2. Successful login → Clear navigation stack → AuthWrapper
3. AuthWrapper detects authenticated state → Redirects to appropriate home screen based on user role

## Benefits
- Eliminates the freezing issue on login page
- Provides consistent navigation behavior for both login and registration
- Ensures clean navigation stack without residual screens
- Maintains user experience with success message display (800ms delay)
- Leverages existing AuthWrapper logic for role-based redirection

## Testing
The fix maintains the existing authentication flow while resolving the navigation issue. The AuthWrapper will detect the authenticated state and redirect users to the appropriate home screen (UserHomeScreen or PharmacistHomeScreen) based on their role.