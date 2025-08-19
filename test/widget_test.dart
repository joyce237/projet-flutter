import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homepharma/providers/app_provider.dart';
import 'package:homepharma/providers/auth_provider.dart';
import 'package:homepharma/providers/cart_provider.dart';
import 'package:homepharma/auth_wrapper.dart';

void main() {
  testWidgets('HomePharma app loads without crashing', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame without Firebase
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(listenAuthChanges: false),
          ),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: MaterialApp(title: 'HomePharma', home: AuthWrapper()),
      ),
    );

    // Verify that our app starts properly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
