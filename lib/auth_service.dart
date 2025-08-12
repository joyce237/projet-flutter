import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inscription
  Future<User?> register(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Enregistrer les informations supplémentaires dans Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'user', // Rôle par défaut
        });
      }
      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Connexion
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      print('AuthService - Déconnexion en cours...');
      await _auth.signOut();
      print('AuthService - Déconnexion réussie');
    } catch (e) {
      print('AuthService - Erreur lors de la déconnexion: $e');
      throw e; // Relancer l'erreur pour que l'AuthProvider puisse la gérer
    }
  }
}
