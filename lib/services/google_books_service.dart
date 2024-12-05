import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class GoogleBooksService {
  // Método para cargar la clave API desde el archivo config.json
  Future<String> _loadApiKey() async {
    try {
      final config = await rootBundle.loadString('config.json');
      final data = json.decode(config);
      return data['apiKey'];
    } catch (e) {
      throw Exception('Error al cargar la clave API: $e');
    }
  }

  // Método para buscar libros usando la API de Google Books
  Future<List<Book>> fetchBooks(String query) async {
    final apiKey = await _loadApiKey();
    final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=$query&key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] == null || data['items'].isEmpty) {
          throw Exception('No se encontraron libros para la consulta: $query');
        }

        final books = data['items'] as List;
        return books
            .map((bookData) => Book.fromGoogleJson(bookData))
            .toList();
      } else {
        throw Exception(
            'Error al cargar los libros. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al buscar libros: $e');
    }
  }

  // Método para obtener los detalles de un libro específico
  Future<Book> fetchBookDetails(String title) async {
    final apiKey = await _loadApiKey();
    final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=intitle:$title&key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] == null || data['items'].isEmpty) {
          throw Exception('No se encontró ningún libro con el título: $title');
        }

        // Retorna el primer resultado encontrado
        return Book.fromGoogleJson(data['items'][0]);
      } else {
        throw Exception(
            'Error al buscar el libro. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al buscar los detalles del libro: $e');
    }
  }
}
