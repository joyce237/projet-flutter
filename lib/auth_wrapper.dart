import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'welcome_screen.dart';
import 'pharmacist_home_screen.dart';
import 'user_home_screen.dart';
import 'providers/auth_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print('AuthWrapper - État: ${authProvider.state}');
        print('AuthWrapper - isAuthenticated: ${authProvider.isAuthenticated}');
        print('AuthWrapper - user: ${authProvider.user?.name ?? 'null'}');

        // État de chargement
        if (authProvider.isLoading || authProvider.state == AuthState.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Utilisateur non connecté ou erreur
        if (!authProvider.isAuthenticated || authProvider.user == null) {
          return const WelcomeScreen();
        }

        final user = authProvider.user!;

        // Aiguiller vers le bon écran en fonction du rôle
        if (user.role == 'pharmacist') {
          return PharmacistHomeScreen(pharmacyId: user.pharmacyId ?? '');
        } else if (user.role == 'user') {
          return const UserHomeScreen();
        } else {
          // Pour l'admin ou cas non géré
          return const UserHomeScreen();
        }
      },
    );
  }
}
