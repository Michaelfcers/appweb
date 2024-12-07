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

}
