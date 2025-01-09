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
          .neq('genre', null)
          .execute();

      // Verificar si hubo un error en la respuesta
      if (response.status != 200) {
        throw Exception('Error al obtener géneros: ${response.status}');
      }

      // Procesar los datos
      final genres = (response.data as List)
          .map((item) => item['genre'] as String)
          .toSet()
          .toList();
      return genres;
    } catch (e) {
      throw Exception('Error al obtener géneros: $e');
    }
  }

  // Método para obtener géneros desde la base de datos utilizando RPC
  Future<List<String>> fetchGenresFromDatabase() async {
    try {
      final response = await _client.rpc('get_book_genres').execute();

      // Verificar si hubo un error en la respuesta
      if (response.status != 200 || response.data == null) {
        throw Exception('Error al obtener géneros: ${response.status}');
      }

      // Procesar la respuesta para extraer únicamente los valores de 'genre'
      final genres = (response.data as List)
          .map((e) => e['genre'].toString())
          .toList();

      return genres;
    } catch (e) {
      print('Error al cargar géneros: $e');
      throw Exception('Error al cargar géneros.');
    }
  }

  /// Buscar libros por título
Future<List<Book>> searchBooks(String query) async {
  try {
    final response = await _client
        .from('books')
        .select('*')
        .ilike('title', '%$query%')
        .execute();

    // Verificar si hay datos y procesar el resultado
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

// Buscar libros por género
Future<List<Book>> searchBooksByGenre(String genre) async {
  try {
    final response = await _client
        .from('books')
        .select('*')
        .eq('genre', genre)
        .execute();

    // Verificar si hay datos y procesar el resultado
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

// Buscar libros por autor
Future<List<Book>> searchBooksByAuthor(String author) async {
  try {
    final response = await _client
        .from('books')
        .select('*')
        .ilike('author', '%$author%') // Busca autores que coincidan parcialmente
        .execute();

    // Verificar si hubo un error en el estado de la respuesta
    if (response.status != 200 || response.data == null) {
      throw Exception('Error al buscar libros por autor. Código de estado: ${response.status}');
    }

    // Procesar los resultados
    return (response.data as List)
        .map((item) => Book.fromSupabaseJson(item))
        .toList();
  } catch (e) {
    throw Exception('Error al buscar libros por autor: $e');
  }
}

// Buscar usuarios por nombre o nickname
Future<List<Map<String, String>>> searchUsers(String query) async {
  try {
    final response = await _client
        .from('users')
        .select('id, name, nickname')
        .or('name.ilike.%$query%,nickname.ilike.%$query%')
        .execute();

    // Verificar si hay datos y procesar el resultado
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
        'photos': book.photos != null ? book.photos : [],
      }).execute();

      if (response.status != 200) {
        throw Exception('Error al agregar libro: ${response.status}');
      }
    } catch (e) {
      throw Exception('Error al agregar libro: $e');
    }
  }
}
