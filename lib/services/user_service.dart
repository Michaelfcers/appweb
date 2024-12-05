import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener datos del perfil del usuario
  Future<Map<String, dynamic>> getUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final response = await _supabase
          .from('users')
          .select('nickname, name, experience')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception('No se encontraron datos para este usuario');
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error al obtener el perfil del usuario: $e');
      rethrow;
    }
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

    // Datos del libro
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

    print("Datos enviados a Supabase para agregar libro:");
    print(bookData);

    try {
      // Inserta el libro en la tabla "books" y devuelve los datos insertados
      final response = await _supabase.from('books').insert(bookData).select();

      if (response is List && response.isNotEmpty) {
        print("Libro agregado exitosamente. Respuesta:");
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

  // Obtener libros subidos por el usuario autenticado
  Future<List<Book>> getUploadedBooks() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final response = await _supabase
          .from('books')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response is List && response.isNotEmpty) {
        // Convertir los datos a una lista de objetos Book
        return response.map((book) => Book.fromSupabaseJson(book)).toList();
      } else {
        print('No se encontraron libros subidos.');
        return [];
      }
    } catch (e) {
      print('Error al obtener los libros subidos: $e');
      rethrow;
    }
  }

  // Actualizar un libro existente
 Future<void> updateBook({
  required String bookId,
  required String title,
  required String description,
  required String condition, // Incluye el campo condición
}) async {
  try {
    final response = await _supabase.from('books').update({
      'title': title,
      'synopsis': description,
      'condition': condition, // Actualización de condición
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', bookId).select();

    // Verifica si la respuesta es una lista vacía o no válida
    if (response == null || (response is List && response.isEmpty)) {
      throw Exception('No se pudo actualizar el libro. Respuesta inesperada.');
    }

    print("Libro actualizado correctamente. Respuesta:");
    print(response);
  } catch (e) {
    print('Error al actualizar el libro: $e');
    rethrow;
  }
}

// Método para eliminar un libro
Future<void> deleteBook(String bookId) async {
  try {
    final response = await _supabase
        .from('books')
        .delete()
        .eq('id', bookId)
        .select();

    if (response == null || response.isEmpty) {
      throw Exception("No se pudo eliminar el libro. Respuesta inesperada.");
    }

    print("Libro eliminado correctamente.");
  } catch (e) {
    print("Error al eliminar el libro: $e");
    rethrow; // Vuelve a lanzar la excepción para manejarla en el UI
  }
}


}
