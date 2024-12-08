import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener el ID del usuario autenticado
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Obtener datos del perfil del usuario
  Future<Map<String, dynamic>> getUserProfile() async {
    final userId = getCurrentUserId();

    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await _supabase
          .from('users')
          .select('nickname, name, experience')
          .eq('id', userId)
          .maybeSingle();

      if (response == null || response.isEmpty) {
        throw Exception('No se encontraron datos para este usuario.');
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
  final userId = getCurrentUserId();

  if (userId == null) {
    throw Exception('Usuario no autenticado.');
  }

  final photosJson = jsonEncode(photos);

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

  try {
    final response = await _supabase.from('books').insert(bookData).select();

    if (response == null || response.isEmpty) {
      throw Exception("Error al agregar libro. Respuesta inesperada.");
    }

    print("Libro agregado exitosamente.");

    // Verificar logros relacionados con subir libros
    await checkBookUploadAchievements();
  } catch (e) {
    print("Error al agregar libro: $e");
    throw Exception("Error al agregar libro: $e");
  }
}


  // Obtener libros subidos por el usuario autenticado
  Future<List<Book>> getUploadedBooks() async {
    final userId = getCurrentUserId();

    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await _supabase
          .from('books')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response is List && response.isNotEmpty) {
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

      if (response == null || response.isEmpty) {
        throw Exception('No se pudo actualizar el libro. Respuesta inesperada.');
      }

      print("Libro actualizado correctamente.");
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
      rethrow;
    }
  }

  // Método para obtener libros de otros usuarios
  Future<List<Book>> getBooksFromOtherUsers() async {
    try {
      final userId = getCurrentUserId();

      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final response = await _supabase
          .from('books')
          .select('*')
          .neq('user_id', userId); // Excluye los libros del usuario actual

      if (response is List && response.isNotEmpty) {
        return response.map((book) => Book.fromSupabaseJson(book)).toList();
      } else {
        print("No se encontraron libros de otros usuarios.");
        return [];
      }
    } catch (e) {
      print('Error al obtener libros de otros usuarios: $e');
      rethrow;
    }
  }

  // Crear una nueva propuesta de trueque
  Future<String> createBarter({
  required String proposerId,
  required String receiverId,
}) async {
  try {
    // Cambia "activo" por un valor aceptado por el ENUM, como "pending"
    final response = await _supabase.from('barters').insert({
      'proposer_id': proposerId,
      'receiver_id': receiverId,
      'status': 'pending', // Cambia a un valor válido para el ENUM
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return response['id'] as String;
  } catch (e) {
    print("Error al crear el trueque: $e");
    throw Exception("Error al crear el trueque: $e");
  }
}

  // Agregar un detalle de trueque
  Future<void> addBarterDetail({
    required String barterId,
    required String bookId,
    required String offeredBy,
  }) async {
    try {
      await _supabase.from('barter_details').insert({
        'barter_id': barterId,
        'book_id': bookId,
        'offered_by': offeredBy,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error al agregar detalle de trueque: $e");
      throw Exception("Error al agregar detalle de trueque: $e");
    }
  }

// Notificar a un usuario sobre una propuesta
Future<void> notifyUser({
  required String receiverId,
  required String content,
  required String type, // Tipo de notificación, asegurarte que sea válido
  String? barterId, // Agregamos barterId como opcional
}) async {
  try {
    await _supabase.from('notifications').insert({
      'user_id': receiverId,
      'type': type,
      'content': content,
      'read': false,
      'barter_id': barterId, // Incluimos el barter_id si está disponible
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print("Error al enviar notificación: $e");
    throw Exception("Error al enviar notificación: $e");
  }
}


Future<Map<String, dynamic>> fetchTradeDetails(String notificationId) async {
  print('Obteniendo detalles para la notificación: $notificationId');
  try {
    final notificationResponse = await _supabase
        .from('notifications')
        .select('id, type, content, read, user_id, barter_id')
        .eq('id', notificationId)
        .maybeSingle();

    print('Respuesta de notificación: $notificationResponse');

    if (notificationResponse == null || notificationResponse['barter_id'] == null) {
      throw Exception('No se encontró el trueque asociado a la notificación.');
    }

    final barterId = notificationResponse['barter_id'];
    print('Barter ID: $barterId');

    final barterResponse = await _supabase
        .from('barters')
        .select('id, proposer_id, receiver_id, status')
        .eq('id', barterId)
        .maybeSingle();
    print('Respuesta de trueque: $barterResponse');

    final barterDetailsResponse = await _supabase
        .from('barter_details')
        .select('book_id, offered_by')
        .eq('barter_id', barterId);
    print('Detalles del trueque: $barterDetailsResponse');

    final bookIds = barterDetailsResponse.map((detail) => detail['book_id']).toList();
    final booksResponse = await _supabase
        .from('books')
        .select('id, title, author, cover_url, condition')
        .in_('id', bookIds);
    print('Libros involucrados: $booksResponse');

    final proposerResponse = await _supabase
        .from('users')
        .select('nickname, name')
        .eq('id', barterResponse['proposer_id'])
        .maybeSingle();
    print('Datos del proponente: $proposerResponse');

    return {
      'barter': barterResponse,
      'details': barterDetailsResponse,
      'books': booksResponse,
      'proposer': proposerResponse,
    };
  } catch (e) {
    print('Error al obtener detalles: $e');
    throw Exception('Error al obtener detalles del trueque.');
  }
}



Future<void> updateBarterStatus({
  required String barterId,
  required String status,
}) async {
  try {
    // Actualizar estado
    final response = await _supabase
        .from('barters')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', barterId)
        .select()
        .single();

    final proposerId = response['proposer_id'];

    // Enviar notificación al proponente
    await _supabase.from('notifications').insert({
      'user_id': proposerId,
      'type': status == 'accepted' ? 'trade_accepted' : 'trade_rejected',
      'content': 'Tu propuesta ha sido ${status == 'accepted' ? 'aceptada' : 'rechazada'}.',
      'read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('Error al actualizar el estado del trueque: $e');
    throw Exception('Error al actualizar el estado del trueque.');
  }
}

// Método para aceptar/rechazar una propuesta
Future<void> respondToTradeProposal({
  required String barterId,
  required String response, // 'accepted' o 'rejected'
}) async {
  try {
    // Actualiza el estado de la propuesta
    await _supabase.from('barters').update({
      'status': response,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', barterId);

    // Obtén el ID del proponente
    final responseData = await _supabase
        .from('barters')
        .select('proposer_id')
        .eq('id', barterId)
        .single();

    final proposerId = responseData['proposer_id'];

    // Envía una notificación al proponente
    await _supabase.from('notifications').insert({
      'user_id': proposerId,
      'type': response == 'accepted' ? 'trade_accepted' : 'trade_rejected',
      'content': response == 'accepted'
          ? 'Tu propuesta de trueque ha sido aceptada.'
          : 'Tu propuesta de trueque ha sido rechazada.',
      'read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('Error al responder a la propuesta: $e');
    throw Exception('Error al responder a la propuesta.');
  }
}

Future<List<Book>> searchBooks(String query) async {
    final response = await _supabase
        .from('books')
        .select()
        .ilike('title', '%$query%'); // Busca por título de forma insensible a mayúsculas

    if (response.error != null) {
      throw Exception('Error al buscar libros: ${response.error!.message}');
    }

    return (response.data as List).map((book) => Book.fromSupabaseJson(book)).toList();
  }
  


//----------------------------------------------------------------
// LOGROS

// Obtener todos los logros disponibles
Future<List<Map<String, dynamic>>> fetchAllAchievements() async {
  try {
    final response = await _supabase
        .from('achievements')
        .select('id, name, description, xp')
        .order('created_at', ascending: true);

    if (response == null || response.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Error al obtener todos los logros: $e');
    rethrow;
  }
}

// Obtener los logros completados por el usuario
Future<List<Map<String, dynamic>>> fetchUserAchievements() async {
  final userId = getCurrentUserId();

  if (userId == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    final response = await _supabase
        .from('user_achievements')
        .select('achievement_id')
        .eq('user_id', userId);

    if (response == null || response.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Error al obtener los logros del usuario: $e');
    rethrow;
  }
}

// Registrar un logro como completado

Future<void> completeAchievement(String achievementId) async {
  final userId = getCurrentUserId();

  if (userId == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    // Verificar si el logro ya está completado
    final existingAchievement = await _supabase
        .from('user_achievements')
        .select('id')
        .eq('user_id', userId)
        .eq('achievement_id', achievementId)
        .maybeSingle();

    if (existingAchievement != null) {
      print('El logro ya está completado.');
      return;
    }

    // Registrar el logro como completado
    await _supabase.from('user_achievements').insert({
      'user_id': userId,
      'achievement_id': achievementId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Obtener los puntos de experiencia del logro
    final achievementData = await _supabase
        .from('achievements')
        .select('xp')
        .eq('id', achievementId)
        .maybeSingle();

    if (achievementData == null || achievementData['xp'] == null) {
      throw Exception('No se encontraron datos del logro.');
    }

    final xp = achievementData['xp'];

    // Actualizar la experiencia del usuario
    await _supabase
        .from('users')
        .update({
          'experience': xp,
        })
        .eq('id', userId);
  } catch (e) {
    print('Error al completar el logro: $e');
    rethrow;
  }
}

// Obtener el progreso de logros combinando todos los logros con los completados
Future<List<Map<String, dynamic>>> fetchAchievementsWithProgress() async {
  try {
    // Obtener todos los logros
    final allAchievements = await fetchAllAchievements();

    // Obtener logros completados
    final completedAchievements = await fetchUserAchievements();
    final completedIds = completedAchievements
        .map((achievement) => achievement['achievement_id'])
        .toSet();

    // Combinar todos los logros y marcar los completados
    return allAchievements.map((achievement) {
      return {
        'id': achievement['id'],
        'name': achievement['name'],
        'description': achievement['description'],
        'xp': achievement['xp'],
        'completed': completedIds.contains(achievement['id']),
      };
    }).toList();
  } catch (e) {
    print('Error al combinar logros con progreso: $e');
    rethrow;
  }
}

//------------------

Future<void> checkBookUploadAchievements() async {
  final userId = getCurrentUserId();

  if (userId == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    // Contar el número de libros subidos por el usuario
    final response = await _supabase
        .from('books')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId);

    final bookCount = response.count ?? 0;

    // Lista de logros relacionados con subir libros
    final achievements = {
      1: 'ffd07138-4020-4ca5-b1ef-fa199042db23', 
      3: '847f3fe1-29cd-45ee-bbad-3ebcb75d0659',
      5: '608fc2ee-7c5d-47f7-a7f0-4e7517c95fc6',
      10: '68dc0a4a-3a3c-4ad3-8e92-a2b20cea0c44',
      15: '89adec7d-c7cb-4cbc-b0a3-fa4a18aeca99',
    };

    // Verificar y completar logros basados en el número de libros subidos
    for (final entry in achievements.entries) {
      if (bookCount >= entry.key) {
        await completeAchievement(entry.value);
      }
    }
  } catch (e) {
    print('Error al verificar logros de libros: $e');
  }
}



  
}

