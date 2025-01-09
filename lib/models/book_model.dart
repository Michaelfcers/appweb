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
  final String status; // Nueva propiedad para el estado del libro

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnail,
    this.genre,
    this.rating,
    this.description,
    this.condition,
    this.userId,
    this.photos,
    this.status = 'enabled', // Valor por defecto solo para el modelo
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
      id: json['id'] ?? '',
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
      status: json['status'] ?? 'enabled', // Mapea el campo desde Supabase
    );
  }

  String get primaryImage {
    if (thumbnail.isNotEmpty) {
      return thumbnail;
    } else if (photos != null && photos!.isNotEmpty) {
      return photos!.first;
    }
    return 'https://via.placeholder.com/150'; // Imagen por defecto
  }

  // Método para convertir un objeto Book a JSON (útil para actualizar libros)
  Map<String, dynamic> toJson() {
    final data = {
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

    // `status` solo se envía si es necesario actualizarlo explícitamente
    if (status != 'enabled') {
      data['status'] = status;
    }

    return data;
  }
}
