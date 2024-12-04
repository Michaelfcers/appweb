import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  AuthNotifier() {
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Comprobar si ya hay una sesión activa al iniciar la app
    final session = _supabase.auth.currentSession;
    _isLoggedIn = session != null;
    notifyListeners();
  }

  Future<void> logIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Si el usuario se autentica correctamente
      if (response.session != null) {
        _isLoggedIn = true;
        notifyListeners();
      } else {
        throw Exception('Inicio de sesión fallido. Por favor, verifica tus credenciales.');
      }
    } catch (e) {
      throw Exception('Error de autenticación: $e');
    }
  }

  Future<void> logOut() async {
    await _supabase.auth.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }
}
