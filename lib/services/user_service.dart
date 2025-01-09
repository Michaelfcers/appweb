import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';
import 'dart:io';

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

// Obtener géneros dinámicamente desde la base de datos
Future<List<String>> fetchGenresFromDatabase() async {
  try {
    final response = await _supabase.rpc('get_book_genres').execute();

    // Verificar si hubo un error en la respuesta
    if (response.status != 200 || response.data == null) {
      throw Exception('Error al obtener géneros: ${response.status}');
    }

    // Procesar la respuesta para extraer únicamente los valores de 'genre'
    final genres = (response.data as List)
        .map((e) => e['genre'].toString()) // Accede al campo 'genre'
        .toList();

    return genres;
  } catch (e) {
    print('Error al cargar géneros: $e');
    throw Exception('Error al cargar géneros.');
  }
}





// Obtener libros subidos por el usuario autenticado
Future<List<Book>> getUploadedBooks({String? status}) async {
  final userId = getCurrentUserId();

  if (userId == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    // Construir la consulta inicial
    final query = _supabase
        .from('books')
        .select('*') // Seleccionamos todos los campos
        .eq('user_id', userId); // Filtrar por usuario

    // Aplicar el filtro de estado si se proporciona
    if (status != null) {
      query.eq('status', status);
    }

    // Ejecutar la consulta
    final response = await query.order('created_at', ascending: false);

    // Verificar si la respuesta contiene datos
    if (response.isEmpty) {
      print('No se encontraron libros subidos.');
      return [];
    }

    // Convertir la respuesta en una lista de objetos `Book`
    return (response as List<dynamic>)
        .map((bookData) => Book.fromSupabaseJson(bookData as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Error al obtener los libros subidos: $e');
    rethrow;
  }
}


Future<void> updateBook({
  required String bookId,
  required String title,
  required String description,
  required String condition,
  List<String>? photos, // Lista de fotos actualizadas
  List<String>? deletedPhotos, // Lista de fotos eliminadas
    required String author, // Add this
  required String genre,  // Add this
}) async {
  try {
    // Construye el mapa de actualizaciones
    final updates = {
      'title': title,
      'synopsis': description,
      'condition': condition,
      'updated_at': DateTime.now().toIso8601String(),
       'author': author, // Include author in the update
      'genre': genre,   // Include genre in the update
    };

    // Si hay fotos, conviértelas a JSON y agrégalas al mapa de actualizaciones
    if (photos != null && photos.isNotEmpty) {
      updates['photos'] = jsonEncode(photos); // Convierte la lista a JSON
    }

    // Maneja la eliminación de fotos si es necesario
    if (deletedPhotos != null && deletedPhotos.isNotEmpty) {
      for (final photoUrl in deletedPhotos) {
        await _supabase.storage.from('books').remove([photoUrl]);
      }
    }

    // Realiza la actualización en la base de datos
    final response = await _supabase
        .from('books') // Asegúrate de que 'books' sea el nombre de tu tabla
        .update(updates)
        .eq('id', bookId)
        .select();

    if (response == null || response.isEmpty) {
      throw Exception('No se pudo actualizar el libro. Respuesta inesperada.');
    }

    print("Libro actualizado correctamente.");
  } catch (e) {
    print('Error al actualizar el libro: $e');
    rethrow;
  }
}

Future<Book> getBookById(String bookId) async {
  final response = await _supabase
      .from('books')
      .select()
      .eq('id', bookId)
      .single();

  if (response == null || response.isEmpty) {
    throw Exception('No se encontró el libro.');
  }

  return Book.fromSupabaseJson(response);
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


Future<String> uploadImageToStorage(String filePath, String fileName) async {
  try {
    // Realiza la subida de la imagen
    final String uploadedPath = await _supabase.storage
        .from('books') // Asegúrate de que el bucket sea 'books'
        .upload(fileName, File(filePath)); // Asegúrate de que filePath sea correcto

    // Obtén la URL pública de la imagen
    final String publicUrl = _supabase.storage
        .from('books')
        .getPublicUrl(uploadedPath);

    return publicUrl; // Retorna la URL pública
  } catch (e) {
    print('Error al subir imagen: $e');
    throw Exception('Error al subir imagen: $e');
  }
}

//Cargar imágenes a la BD
Future<String> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the image to the Supabase storage bucket
      final response = await _supabase.storage
          .from('books') // Replace 'books' with your bucket name
          .upload(fileName, file);

      // Check if the response is a valid file name
      if (response.isEmpty || response.contains('error')) {
        throw Exception('Error uploading image: $response');
      }

      // Get the public URL of the uploaded image
      final publicUrl = _supabase.storage.from('books').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Obtener perfil y libros de un usuario específico
Future<Map<String, dynamic>> getUserProfileAndBooks(String userId) async {
  try {
    // Obtener detalles del usuario
    final userDetailsResponse = await _supabase
        .from('users')
        .select('nickname, name, experience')
        .eq('id', userId)
        .single();

    if (userDetailsResponse == null || userDetailsResponse.isEmpty) {
      throw Exception('Usuario no encontrado.');
    }

    // Obtener libros subidos por el usuario y habilitados
    final booksResponse = await _supabase
        .from('books')
        .select('*')
        .eq('user_id', userId)
        .eq('status', 'enabled') // Usar 'status' en lugar de 'book_status'
        .order('created_at', ascending: false);

    List<Book> books = [];
    if (booksResponse is List && booksResponse.isNotEmpty) {
      books = booksResponse.map((book) => Book.fromSupabaseJson(book)).toList();
    }

    return {
      'userDetails': userDetailsResponse as Map<String, dynamic>,
      'userBooks': books,
    };
  } catch (error) {
    print('Error al obtener perfil y libros del usuario: $error');
    throw Exception('Error al obtener perfil y libros del usuario: $error');
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
        .neq('user_id', userId) // Excluye los libros del usuario actual
        .eq('status', 'enabled'); // Usar 'status' en lugar de 'book_status'

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
  required String targetBookId, // ID del libro objetivo
}) async {
  try {
    // Crear el trueque
    final barterResponse = await _supabase.from('barters').insert({
      'proposer_id': proposerId,
      'receiver_id': receiverId,
      'target_book_id': targetBookId, // Guardar el libro objetivo en la base de datos
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    final barterId = barterResponse['id'] as String;

    // Agregar el detalle del libro objetivo
    await addBarterDetail(
      barterId: barterId,
      bookId: targetBookId,
      offeredBy: receiverId,
    );

    return barterId;
  } catch (e) {
    print('Error al crear el trueque: $e');
    throw Exception('Error al crear el trueque.');
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


// Obtener información del usuario que subió un libro
Future<Map<String, String?>> getUserDetailsByBookId(String bookId) async {
  try {
    final response = await _supabase
        .from('books')
        .select('user_id, users(nickname, name)')
        .eq('id', bookId)
        .single();

    if (response == null || response.isEmpty) {
      throw Exception('No se encontró información del usuario.');
    }

    return {
      'nickname': response['users']?['nickname'],
      'name': response['users']?['name'],
    };
  } catch (e) {
    print('Error al obtener detalles del usuario: $e');
    return {
      'nickname': 'Usuario desconocido',
      'name': 'Usuario desconocido',
    };
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
  try {
    // Obtener notificación con el ID
    final notificationResponse = await _supabase
        .from('notifications')
        .select('id, barter_id')
        .eq('id', notificationId)
        .maybeSingle();

    final barterId = notificationResponse['barter_id'];

    // Obtener información del trueque
    final barterResponse = await _supabase
        .from('barters')
        .select('id, proposer_id, receiver_id, status, target_book_id') // Asegúrate de incluir target_book_id
        .eq('id', barterId)
        .maybeSingle();

    // Obtener detalles del libro objetivo (targetBook)
    Map<String, dynamic>? targetBook;
    if (barterResponse['target_book_id'] != null) {
      targetBook = await _supabase
          .from('books')
          .select('id, title, author, cover_url, condition')
          .eq('id', barterResponse['target_book_id'])
          .maybeSingle();
    }

    // Obtener los libros ofrecidos por el proponente
    final barterDetailsResponse = await _supabase
        .from('barter_details')
        .select('book_id, offered_by')
        .eq('barter_id', barterId);

    final offeredBooks = barterDetailsResponse
        .where((detail) => detail['offered_by'] == barterResponse['proposer_id'])
        .toList();

    final offeredBooksResponse = await _supabase
        .from('books')
        .select('id, title, author, cover_url, condition')
        .in_('id', offeredBooks.map((b) => b['book_id']).toList());

    // Proponente
    final proposerResponse = await _supabase
        .from('users')
        .select('nickname, name')
        .eq('id', barterResponse['proposer_id'])
        .maybeSingle();

    return {
      'barter': barterResponse,
      'targetBook': targetBook,
      'books': offeredBooksResponse,
      'proposer': proposerResponse,
    };
  } catch (e) {
    throw Exception('Error al obtener detalles del trueque: $e');
  }
}



// Método para aceptar/rechazar una propuesta
Future<void> respondToTradeProposal({
  required String barterId,
  required String response, // 'accepted' o 'rejected'
}) async {
  try {
    // Actualiza el estado del trueque en la tabla "barters"
    await _supabase.from('barters').update({
      'status': response,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', barterId);

    if (response == 'accepted') {
      // Obtén los libros ofrecidos relacionados con este trueque
      final bookDetails = await _supabase
          .from('barter_details')
          .select('book_id')
          .eq('barter_id', barterId);

      for (final bookDetail in bookDetails) {
        final bookId = bookDetail['book_id'];

        // Actualiza el estado del libro ofrecido a 'disabled'
        await _supabase
            .from('books')
            .update({'status': 'disabled'}) // Usar 'status' en lugar de 'book_status'
            .eq('id', bookId);
      }

      // Deshabilita también el libro objetivo del trueque
      final barterResponse = await _supabase
          .from('barters')
          .select('target_book_id')
          .eq('id', barterId)
          .single();

      final targetBookId = barterResponse['target_book_id'];
      await _supabase
          .from('books')
          .update({'status': 'disabled'}) // Usar 'status' en lugar de 'book_status'
          .eq('id', targetBookId);
    }

    // Notificación al proponente
    final proposerResponse = await _supabase
        .from('barters')
        .select('proposer_id')
        .eq('id', barterId)
        .single();

    final proposerId = proposerResponse['proposer_id'];

    await _supabase.from('notifications').insert({
      'user_id': proposerId,
      'type': response == 'accepted' ? 'trade_accepted' : 'trade_rejected',
      'content': response == 'accepted'
          ? 'Tu propuesta de trueque ha sido aceptada.'
          : 'Tu propuesta de trueque ha sido rechazada.',
      'read': false,
      'barter_id': barterId,
      'created_at': DateTime.now().toIso8601String(),
    });

    print('Propuesta procesada con éxito: $response');
  } catch (e) {
    print('Error al procesar el trueque: $e');
    throw Exception('Error al procesar la propuesta.');
  }
}



Future<List<Book>> searchBooks(String query) async {
  final response = await _supabase
      .from('books')
      .select('*')
      .ilike('title', '%$query%')
      .eq('status', 'enabled'); // Usar 'status' en lugar de 'book_status'

  if (response is List && response.isNotEmpty) {
    return response.map((book) => Book.fromSupabaseJson(book)).toList();
  } else {
    print("No se encontraron libros para la búsqueda.");
    return [];
  }
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

      15: '34880b80-46a9-4335-97a7-9153a31d949e',
      20: '44722f83-653e-44ee-9d5b-3eeb740d6f83',
      25: '4f2cbc99-10c8-49f2-9d7f-fb071493b4ac',
      30: '804412a2-bb1d-4b88-9b4c-843d3e8c1e12',
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









//------------------------------------------
Future<void> checkTradeAchievements() async {
  final userId = getCurrentUserId();

  if (userId == null) {
    throw Exception('Usuario no autenticado.');
  }

  try {
    // Contar el número de trueques realizados por el usuario
    final tradeCountResponse = await _supabase
        .from('barters')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('proposer_id', userId)
        .eq('status', 'completed'); // Solo trueques completados

    final tradeCount = tradeCountResponse.count ?? 0;

    // Verificar los géneros diferentes involucrados en los trueques
    final genresResponse = await _supabase
        .from('barters')
        .select('barter_details(book_id)')
        .eq('proposer_id', userId)
        .eq('status', 'completed');

    final bookIds = genresResponse.map((barter) => barter['book_id']).toList();

    // Obtener géneros únicos de los libros involucrados
    final booksResponse = await _supabase
        .from('books')
        .select('genre')
        .in_('id', bookIds);

    final genres = booksResponse
        .map((book) => book['genre'])
        .toSet(); // Usar un set para eliminar duplicados

    // Lista de logros relacionados con trueques
    final tradeAchievements = {
      1: '<achievement_id_for_1_trade>',
      3: '<achievement_id_for_3_trades>',
      5: '<achievement_id_for_5_trades>',
      10: '<achievement_id_for_10_trades>',
    };

    final genreAchievements = {
      2: '<achievement_id_for_2_genres>',
      3: '<achievement_id_for_3_genres>',
      4: '<achievement_id_for_4_genres>',
    };

    // Verificar logros basados en el número de trueques
    for (final entry in tradeAchievements.entries) {
      if (tradeCount >= entry.key) {
        await completeAchievement(entry.value);
      }
    }

    // Verificar logros basados en géneros diferentes
    for (final entry in genreAchievements.entries) {
      if (genres.length >= entry.key) {
        await completeAchievement(entry.value);
      }
    }
  } catch (e) {
    print('Error al verificar logros de trueques: $e');
  }
}



Future<void> completeTrade(String barterId) async {
  try {
    await _supabase
        .from('barters')
        .update({
          'status': 'completed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', barterId);

    print('Trueque completado con éxito.');

    // Verificar logros relacionados con trueques
    await checkTradeAchievements();
  } catch (e) {
    print('Error al completar el trueque: $e');
    throw Exception('Error al completar el trueque.');
  }
}




  
}

