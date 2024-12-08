import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<String>> fetchGenres() async {
    try {
      final response = await _client
          .from('books')
          .select('genre')
          .neq('genre', null); // Filtra géneros que no sean nulos

      final genres = (response as List)
          .map((item) => item['genre'] as String)
          .toSet()
          .toList();

      return genres;
    } catch (e) {
      throw Exception('Error al obtener géneros: $e');
    }
  }

  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await _client
          .from('books')
          .select('*')
          .ilike('title', '%$query%'); // Busca títulos que contengan el texto

      return (response as List)
          .map((item) => Book.fromSupabaseJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar libros: $e');
    }
  }

  Future<List<Book>> searchBooksByGenre(String genre) async {
    try {
      final response = await _client
          .from('books')
          .select('*')
          .ilike('genre', '%$genre%'); // Filtra por género

      return (response as List)
          .map((item) => Book.fromSupabaseJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar libros por género: $e');
    }
  }
}
