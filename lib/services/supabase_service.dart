import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Obtener géneros únicos desde Supabase
  Future<List<String>> fetchGenres() async {
    try {
      final response = await _client
          .from('books')
          .select('genre')
          .neq('genre', null);

      if (response is List) {
        final genres = response
            .map((item) => item['genre'] as String)
            .toSet()
            .toList();
        return genres;
      } else {
        throw Exception('Error al obtener géneros: Datos inesperados');
      }
    } catch (e) {
      throw Exception('Error al obtener géneros: $e');
    }
  }

  // Buscar libros por título
  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await _client
          .from('books')
          .select('*')
          .ilike('title', '%$query%');

      if (response is List) {
        return response.map((item) => Book.fromSupabaseJson(item)).toList();
      } else {
        throw Exception('Error al buscar libros: Datos inesperados');
      }
    } catch (e) {
      throw Exception('Error al buscar libros: $e');
    }
  }

  // Buscar libros por género
  Future<List<Book>> searchBooksByGenre(String genre) async {
    try {
      final response = await _client
          .from('books')
          .select('*')
          .ilike('genre', '%$genre%');

      if (response is List) {
        return response.map((item) => Book.fromSupabaseJson(item)).toList();
      } else {
        throw Exception('Error al buscar libros por género: Datos inesperados');
      }
    } catch (e) {
      throw Exception('Error al buscar libros por género: $e');
    }
  }

  // Subir fotos a Supabase
  Future<List<String>> uploadPhotos(List<File> photos) async {
  List<String> photoUrls = [];
  try {
    for (var photo in photos) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await _client.storage.from('books').upload(fileName, photo);

      if (response.isEmpty) {
        // Supabase SDK retorna una URL vacía si hay errores
        throw Exception('Error al subir imagen: No se pudo completar la subida.');
      } else {
        final publicUrl = _client.storage.from('books').getPublicUrl(fileName);
        photoUrls.add(publicUrl);
      }
    }
  } catch (e) {
    throw Exception('Error al subir fotos: $e');
  }
  return photoUrls;
}

  // Agregar libro a la base de datos
  Future<void> addBook(Book book) async {
    try {
      final response = await _client.from('books').insert({
        'title': book.title,
        'author': book.author,
        'genre': book.genre,
        'description': book.description,
        'condition': book.condition,
        'thumbnail': book.thumbnail,
        'photos': book.photos != null ? book.photos : [],
      });

      if (response.error != null) {
        throw Exception('Error al agregar libro: ${response.error!.message}');
      }
    } catch (e) {
      throw Exception('Error al agregar libro: $e');
    }
  }
}
