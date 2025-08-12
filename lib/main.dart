import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'HomePharma',
            theme: ThemeData(
              primarySwatch: Colors.teal,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.teal,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            themeMode: appProvider.themeMode,
            locale: appProvider.locale,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

