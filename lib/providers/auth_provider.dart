import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _user != null;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    print(
      'AuthProvider - onAuthStateChanged: ${firebaseUser?.email ?? 'null'}',
    );

    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _setState(AuthState.unauthenticated, user: null);
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      print('AuthProvider - Loading user data for: $userId');
      _setState(AuthState.loading);

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = UserModel.fromMap(userDoc.data()!, userId);
        print('AuthProvider - User data loaded: ${userData.name}');

        // Mettre à jour la dernière connexion
        await _updateLastLogin(userId);

        _setState(AuthState.authenticated, user: userData);
      } else {
        print('AuthProvider - User document not found in Firestore');
        _setState(
          AuthState.error,
          errorMessage: 'Données utilisateur introuvables',
        );
      }
    } catch (e) {
      print('AuthProvider - Error loading user data: $e');
      _setState(
        AuthState.error,
        errorMessage: 'Erreur lors du chargement des données: $e',
      );
    }
  }

  // Méthode pour forcer le rechargement des données utilisateur
  Future<void> reloadUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _setState(AuthState.unauthenticated, user: null);
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Erreur silencieuse pour ne pas bloquer l'authentification
      debugPrint('Erreur mise à jour dernière connexion: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      print('AuthProvider - Début de la connexion pour: $email');
      _setState(AuthState.loading);

      final user = await _authService.signIn(email.trim(), password);

      if (user != null) {
        print('AuthProvider - Connexion réussie pour: ${user.email}');

        // Force le chargement des données utilisateur pour être sûr
        await _loadUserData(user.uid);

        return true;
      } else {
        print('AuthProvider - Échec de la connexion');
        _setState(
          AuthState.unauthenticated,
          errorMessage: 'Email ou mot de passe incorrect',
        );
        return false;
      }
    } catch (e) {
      print('AuthProvider - Erreur lors de la connexion: $e');
      _setState(AuthState.error, errorMessage: 'Erreur de connexion: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      _setState(AuthState.loading);

      final user = await _authService.register(
        name.trim(),
        email.trim(),
        password,
      );

      if (user != null) {
        // _onAuthStateChanged sera appelé automatiquement
        return true;
      } else {
        _setState(
          AuthState.unauthenticated,
          errorMessage: 'Erreur lors de l\'inscription',
        );
        return false;
      }
    } catch (e) {
      _setState(AuthState.error, errorMessage: 'Erreur d\'inscription: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      print('AuthProvider - Début de la déconnexion');
      _setState(AuthState.loading);
      await _authService.signOut();
      print('AuthProvider - Déconnexion réussie');
      // _onAuthStateChanged sera appelé automatiquement et mettra l'état à unauthenticated
    } catch (e) {
      print('AuthProvider - Erreur lors de la déconnexion: $e');
      _setState(AuthState.error, errorMessage: 'Erreur de déconnexion: $e');
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_user == null) return false;

    try {
      _setState(AuthState.loading);

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(_user!.id).update(updates);

      // Recharger les données utilisateur
      await _loadUserData(_user!.id);

      return true;
    } catch (e) {
      _setState(AuthState.error, errorMessage: 'Erreur de mise à jour: $e');
      return false;
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    if (_user == null) return false;

    try {
      await _firestore.collection('users').doc(_user!.id).update({
        'preferences': preferences,
      });

      // Mettre à jour localement
      _user = _user!.copyWith(preferences: preferences);
      notifyListeners();

      return true;
    } catch (e) {
      _setState(
        AuthState.error,
        errorMessage: 'Erreur de mise à jour des préférences: $e',
      );
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(AuthState newState, {UserModel? user, String? errorMessage}) {
    _state = newState;
    if (user != null) _user = user;
    if (user == null && newState == AuthState.unauthenticated) _user = null;
    _errorMessage = errorMessage;
    notifyListeners();
  }
}
