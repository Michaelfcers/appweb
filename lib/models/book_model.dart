import 'dart:convert';

class Book {
  final String id; // Identificador único del libro
  final String title;
  final String author;
  final String thumbnail;
  final String? genre;
  final double? rating;
  final String? description;
  final String? condition;
  final String? userId;
  final List<String>? photos;

  Book({
    required this.id, // Ahora incluye el campo `id`
    required this.title,
    required this.author,
    required this.thumbnail,
    this.genre,
    this.rating,
    this.description,
    this.condition,
    this.userId,
    this.photos,
  });

  // Método para crear una instancia de Book desde JSON de Google Books API
  factory Book.fromGoogleJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    return Book(
      id: '', // Google Books API no tiene `id`, lo dejamos vacío
      title: volumeInfo['title'] ?? 'Título desconocido',
      author: (volumeInfo['authors'] != null && volumeInfo['authors'].isNotEmpty)
          ? volumeInfo['authors'][0]
          : 'Autor desconocido',
      thumbnail: volumeInfo['imageLinks'] != null
          ? volumeInfo['imageLinks']['thumbnail']
          : 'https://via.placeholder.com/150',
      genre: (volumeInfo['categories'] != null && volumeInfo['categories'].isNotEmpty)
          ? volumeInfo['categories'][0]
          : 'Sin género especificado',
      rating: volumeInfo['averageRating'] != null
          ? (volumeInfo['averageRating'] as num).toDouble()
          : null,
      description: volumeInfo['description'],
    );
  }

  // Método para crear una instancia de Book desde JSON de Supabase
  factory Book.fromSupabaseJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '', // Recuperamos el id del libro desde Supabase
      title: json['title'] ?? 'Título desconocido',
      author: json['author'] ?? 'Autor desconocido',
      thumbnail: json['cover_url'] ?? 'https://via.placeholder.com/150',
      genre: json['genre'] ?? 'Sin género especificado',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      description: json['synopsis'],
      condition: json['condition'],
      userId: json['user_id'],
      photos: (json['photos'] != null)
          ? List<String>.from(jsonDecode(json['photos']))
          : null,
    );
  }

  // Método para convertir un objeto Book a JSON (útil para actualizar libros)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover_url': thumbnail,
      'genre': genre,
      'rating': rating,
      'synopsis': description,
      'condition': condition,
      'user_id': userId,
      'photos': photos != null ? jsonEncode(photos) : null,
    };
  }
}
