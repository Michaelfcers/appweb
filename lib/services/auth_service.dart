import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isNicknameAvailable(String nickname) async {
    final response = await _supabase
        .from('users')
        .select('id')
        .eq('nickname', nickname)
        .maybeSingle();
    return response == null;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
    required String name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Error al crear la cuenta.');
    }

    await _supabase.from('users').insert({
      'id': response.user!.id,
      'nickname': nickname,
      'name': name,
    });
  }
}
