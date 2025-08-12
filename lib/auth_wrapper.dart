import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'pharmacist_home_screen.dart';
import 'user_home_screen.dart'; 

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // L'utilisateur n'est pas connecté
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // L'utilisateur est connecté, on vérifie son rôle
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            // En attendant de connaître le rôle
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Si on ne trouve pas l'utilisateur dans Firestore ou s'il n'a pas de rôle
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // On peut le déconnecter ou afficher une page d'erreur
              return const WelcomeScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final String role = userData['role'];

            // Aiguiller vers le bon écran en fonction du rôle
            if (role == 'pharmacist') {
              return PharmacistHomeScreen(pharmacyId: userData['pharmacyId']);
            } else if (role == 'user') {
              return const UserHomeScreen(); // L'écran d'accueil pour l'utilisateur normal
            } else {
              // Pour l'admin ou cas non géré, on peut renvoyer vers un écran spécifique
              // ou simplement l'écran utilisateur par défaut.
              return const UserHomeScreen();
            }
          },
        );
      },
    );
  }
}