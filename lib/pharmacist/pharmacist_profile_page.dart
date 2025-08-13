import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PharmacistProfilePage extends StatelessWidget {
  const PharmacistProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Page de gestion du profil', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Logique pour rediriger vers l'écran de connexion
              // Par exemple: Navigator.of(context).pushAndRemoveUntil(...)
            },
            child: const Text('Se déconnecter'),
          )
        ],
      ),
    );
  }
}