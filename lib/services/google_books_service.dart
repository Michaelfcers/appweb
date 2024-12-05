import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class GoogleBooksService {
  Future<String> _loadApiKey() async {
    final config = await rootBundle.loadString('config.json');
    final data = json.decode(config);
    return data['apiKey'];
  }

  Future<List<Book>> fetchBooks(String query) async {
    final apiKey = await _loadApiKey();
    final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=$query&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final books = data['items'] as List;
      return books.map((bookData) => Book.fromJson(bookData)).toList();
    } else {
      throw Exception('Error al cargar los libros');
    }
  }

  // Método para obtener los detalles de un libro específico
  Future<Book> fetchBookDetails(String title) async {
    final apiKey = await _loadApiKey();
    final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=intitle:$title&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['items'] == null || data['items'].isEmpty) {
        throw Exception('No se encontró ningún libro con ese título');
      }

      // Retorna el primer resultado encontrado
      return Book.fromJson(data['items'][0]);
    } else {
      throw Exception('Error al buscar el libro');
    }
  }
}
  