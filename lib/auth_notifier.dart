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
  final session = _supabase.auth.currentSession;
  _isLoggedIn = session != null;
  notifyListeners();
}

  String? get userId {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }

  User? get currentUser {
    return _supabase.auth.currentUser; // Getter para obtener el usuario actual
  }

  Future<void> logIn(String email, String password) async {
  try {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session != null) {
      _isLoggedIn = true;
      notifyListeners();
    } else {
      throw Exception('Inicio de sesión fallido.');
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
