import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener datos del perfil del usuario
  Future<Map<String, dynamic>> getUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    final response = await _supabase
        .from('users')
        .select('nickname, name, experience')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('No se encontraron datos para este usuario');
    }

    return response as Map<String, dynamic>;
  }

  // Agregar un libro asociado al usuario logueado
 Future<void> addBookToUser({
  required String title,
  required String author,
  String? genre,
  String? description,
  required String thumbnail,
}) async {
  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('Usuario no autenticado');
  }

final response = await _supabase.from('books').insert({
  'user_id': userId,
  'title': title,
  'author': author,
  'genre': genre,
  'synopsis': description,
  'rating': 0, // Si rating puede ser opcional
  'cover_url': thumbnail,
  'condition': 'Nuevo', // Agregar un valor predeterminado
  'created_at': DateTime.now().toIso8601String(),
});


  // Verificar si hubo un error basado en el status y los datos
  if (response.status != 201 && response.status != 200) {
    throw Exception('Error al agregar libro: ${response.data ?? "Error desconocido"}');
  }
}
}