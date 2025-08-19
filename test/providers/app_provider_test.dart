import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homepharma/providers/app_provider.dart';

void main() {
  group('AppProvider', () {
    late AppProvider appProvider;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      appProvider = AppProvider();
      // Wait for initial loading to complete
      await Future.delayed(Duration(milliseconds: 100));
    });

    test('should initialize with default values', () {
      expect(appProvider.themeMode, ThemeMode.system);
      expect(appProvider.locale, const Locale('fr', 'FR'));
      expect(appProvider.notificationsEnabled, true);
      expect(appProvider.locationEnabled, true);
      expect(appProvider.isDarkMode, false);
    });

    test('should toggle theme correctly', () async {
      // Act
      await appProvider.toggleTheme();

      // Assert
      expect(appProvider.themeMode, ThemeMode.dark);
      expect(appProvider.isDarkMode, true);

      // Act again
      await appProvider.toggleTheme();

      // Assert
      expect(appProvider.themeMode, ThemeMode.light);
      expect(appProvider.isDarkMode, false);
    });

    test('should set theme mode correctly', () async {
      // Act
      await appProvider.setThemeMode(ThemeMode.dark);

      // Assert
      expect(appProvider.themeMode, ThemeMode.dark);
      expect(appProvider.isDarkMode, true);
    });

    test('should set locale correctly', () async {
      // Act
      await appProvider.setLocale(const Locale('en', 'US'));

      // Assert
      expect(appProvider.locale, const Locale('en', 'US'));
    });

    test('should set notifications enabled correctly', () async {
      // Act
      await appProvider.setNotificationsEnabled(false);

      // Assert
      expect(appProvider.notificationsEnabled, false);
    });

    test('should set location enabled correctly', () async {
      // Act
      await appProvider.setLocationEnabled(false);

      // Assert
      expect(appProvider.locationEnabled, false);
    });

    test('should get correct theme labels', () {
      expect(appProvider.getThemeLabel(), 'Automatique');

      appProvider.setThemeMode(ThemeMode.light);
      expect(appProvider.getThemeLabel(), 'Clair');

      appProvider.setThemeMode(ThemeMode.dark);
      expect(appProvider.getThemeLabel(), 'Sombre');
    });

    test('should get correct language labels', () {
      expect(appProvider.getLanguageLabel(), 'Français');

      appProvider.setLocale(const Locale('en'));
      expect(appProvider.getLanguageLabel(), 'English');

      appProvider.setLocale(const Locale('ar'));
      expect(appProvider.getLanguageLabel(), 'العربية');
    });

    test('should reset to defaults correctly', () async {
      // Arrange - change some values
      await appProvider.setThemeMode(ThemeMode.dark);
      await appProvider.setLocale(const Locale('en'));
      await appProvider.setNotificationsEnabled(false);
      await appProvider.setLocationEnabled(false);

      // Act
      await appProvider.resetToDefaults();

      // Assert
      expect(appProvider.themeMode, ThemeMode.system);
      expect(appProvider.locale, const Locale('fr', 'FR'));
      expect(appProvider.notificationsEnabled, true);
      expect(appProvider.locationEnabled, true);
    });

    test('should not notify listeners if value is the same', () async {
      var notificationCount = 0;
      appProvider.addListener(() {
        notificationCount++;
      });

      // Wait for initialization to complete
      await Future.delayed(Duration(milliseconds: 10));

      // Reset counter after initialization
      notificationCount = 0;

      // Act - set same theme mode
      await appProvider.setThemeMode(ThemeMode.system);

      // Assert - should not notify since it's already the default
      expect(notificationCount, 0);
    });
  });
}
