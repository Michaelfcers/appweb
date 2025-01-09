import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene el ID del usuario actual
  String getCurrentUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }
    return user.id;
  }

  // Obtener géneros únicos desde Supabase
  Future<List<String>> fetchGenres() async {
    try {
      final response = await _client
          .from('books')
          .select('genre')
          .neq('genre', null)
          .neq('status', 'disabled') // Excluir libros con status "disabled"
          .execute();

      if (response.status != 200) {
        throw Exception('Error al obtener géneros: ${response.status}');
      }

      final genres = (response.data as List)
          .map((item) => item['genre'] as String)
          .toSet()
          .toList();
      return genres;
    } catch (e) {
      throw Exception('Error al obtener géneros: $e');
    }
  }

  // Obtener géneros desde la base de datos utilizando RPC
  Future<List<String>> fetchGenresFromDatabase() async {
    try {
      final response = await _client.rpc('get_book_genres').execute();

      if (response.status != 200 || response.data == null) {
        throw Exception('Error al obtener géneros: ${response.status}');
      }

      final genres = (response.data as List)
          .map((e) => e['genre'].toString())
          .toList();

      return genres;
    } catch (e) {
      throw Exception('Error al cargar géneros: $e');
    }
  }

  // Buscar libros por título excluyendo los propios y con estado "enabled"
  Future<List<Book>> searchBooks(String query) async {
    try {
      final userId = getCurrentUserId();
      final response = await _client
          .from('books')
          .select('*')
          .ilike('title', '%$query%')
          .neq('user_id', userId) // Excluir libros del usuario actual
          .eq('status', 'enabled') // Incluir solo libros con status "enabled"
          .execute();

      if (response.data != null) {
        return (response.data as List)
            .map((item) => Book.fromSupabaseJson(item))
            .toList();
      } else {
        throw Exception('Error al buscar libros: Datos no encontrados.');
      }
    } catch (e) {
      throw Exception('Error al buscar libros: $e');
    }
  }

  // Buscar libros por género excluyendo los propios y con estado "enabled"
  Future<List<Book>> searchBooksByGenre(String genre) async {
    try {
      final userId = getCurrentUserId();
      final response = await _client
          .from('books')
          .select('*')
          .eq('genre', genre)
          .neq('user_id', userId) // Excluir libros del usuario actual
          .eq('status', 'enabled') // Incluir solo libros con status "enabled"
          .execute();

      if (response.data != null) {
        return (response.data as List)
            .map((item) => Book.fromSupabaseJson(item))
            .toList();
      } else {
        throw Exception('Error al buscar libros por género: Datos no encontrados.');
      }
    } catch (e) {
      throw Exception('Error al buscar libros por género: $e');
    }
  }

  // Buscar libros por autor excluyendo los propios y con estado "enabled"
  Future<List<Book>> searchBooksByAuthor(String author) async {
    try {
      final userId = getCurrentUserId();
      final response = await _client
          .from('books')
          .select('*')
          .ilike('author', '%$author%')
          .neq('user_id', userId) // Excluir libros del usuario actual
          .eq('status', 'enabled') // Incluir solo libros con status "enabled"
          .execute();

      if (response.data != null) {
        return (response.data as List)
            .map((item) => Book.fromSupabaseJson(item))
            .toList();
      } else {
        throw Exception('Error al buscar libros por autor: Datos no encontrados.');
      }
    } catch (e) {
      throw Exception('Error al buscar libros por autor: $e');
    }
  }

  // Buscar usuarios por nombre o nickname excluyendo al usuario actual
  Future<List<Map<String, String>>> searchUsers(String query) async {
    try {
      final userId = getCurrentUserId();
      final response = await _client
          .from('users')
          .select('id, name, nickname')
          .or('name.ilike.%$query%,nickname.ilike.%$query%')
          .neq('id', userId) // Excluir al usuario actual
          .execute();

      if (response.data != null) {
        return (response.data as List).map((item) {
          return {
            'id': item['id'] as String,
            'name': item['name'] as String? ?? 'Sin nombre',
            'nickname': item['nickname'] as String? ?? 'Sin nickname',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  // Subir fotos a Supabase
  Future<List<String>> uploadPhotos(List<File> photos) async {
    List<String> photoUrls = [];
    try {
      for (var photo in photos) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final response =
            await _client.storage.from('books').upload(fileName, photo);

        if (response.isEmpty) {
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
        'photos': book.photos ?? [],
        'user_id': getCurrentUserId(), // Asociar el libro al usuario actual
        'status': book.status ?? 'enabled', // Asignar status por defecto
      }).execute();

      if (response.status != 200) {
        throw Exception('Error al agregar libro: ${response.status}');
      }
    } catch (e) {
      throw Exception('Error al agregar libro: $e');
    }
  }
}
