import 'dart:convert';
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
  required String condition,
  required List<String> photos,
  required String thumbnail,
}) async {
  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('Usuario no autenticado');
  }

  // Serializar las fotos como JSON
  final photosJson = jsonEncode(photos);

  // Log de los datos que se están enviando
  final bookData = {
    'user_id': userId,
    'title': title,
    'author': author,
    'genre': genre,
    'synopsis': description,
    'rating': 0,
    'cover_url': thumbnail,
    'condition': condition,
    'photos': photosJson,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  print("Datos enviados a Supabase:");
  print(bookData);

  try {
    // Realiza la inserción y selecciona los datos insertados
    final response = await _supabase.from('books').insert(bookData).select();

    // Verificar si la respuesta es válida y no está vacía
    if (response is List && response.isNotEmpty) {
      print("Libro agregado exitosamente a Supabase. Respuesta:");
      print(response);
    } else {
      print("Error: Respuesta inesperada de Supabase. Respuesta:");
      print(response);
      throw Exception("Error al agregar libro: Respuesta inesperada de Supabase.");
    }
  } catch (e) {
    print("Error al agregar libro: $e");
    throw Exception("Error al agregar libro: $e");
  }
}

}