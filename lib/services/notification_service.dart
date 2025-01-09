import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Canales de suscripciones en tiempo real
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _notificationsChannel;

  /// Obtiene la cantidad de mensajes no leídos
  Future<int> getUnreadMessagesCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .is_('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('Error al obtener mensajes no leídos: $e');
      return 0;
    }
  }

  /// Obtiene la cantidad de notificaciones no leídas
  Future<int> getUnreadNotificationsCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .is_('read', false);

      return response.length;
    } catch (e) {
      debugPrint('Error al obtener notificaciones no leídas: $e');
      return 0;
    }
  }

  /// Obtiene la cantidad de chats con mensajes no leídos
  Future<int> getUnreadChatsCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _supabase
          .from('messages')
          .select('barter_id')
          .eq('receiver_id', userId)
          .is_('is_read', false);

      final unreadMessages = List<Map<String, dynamic>>.from(response);

      // Contar los barter_id únicos
      return unreadMessages.map((msg) => msg['barter_id']).toSet().length;
    } catch (e) {
      debugPrint('Error al obtener chats no leídos: $e');
      return 0;
    }
  }

  /// Suscripción en tiempo real a nuevos mensajes
void subscribeToMessages(void Function(Map<String, dynamic>) onMessageReceived) {
  _messagesChannel?.unsubscribe(); // Limpia el canal anterior si existe
  _messagesChannel = _supabase.channel('public:messages');

  _messagesChannel!.on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages'),
    (payload, [ref]) {
      if (payload != null && payload['new'] != null) {
        onMessageReceived(payload['new']);
      }
    },
  ).subscribe();
}

/// Suscripción en tiempo real a nuevas notificaciones
void subscribeToNotifications(void Function() onNotificationReceived) {
  _notificationsChannel?.unsubscribe(); // Limpia el canal anterior si existe
  _notificationsChannel = _supabase.channel('public:notifications');

  // Suscripción al evento INSERT para la tabla notifications
  _notificationsChannel!.on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'notifications',
      filter: 'user_id=eq.${_supabase.auth.currentUser?.id}', // Filtrar por usuario
    ),
    (payload, [ref]) {
      debugPrint('Evento recibido en notifications: $payload'); // Agrega un log
      if (payload != null && payload['new'] != null) {
        onNotificationReceived();
      }
    },
  ).subscribe();
}




  /// Marcar un mensaje como leído
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
      debugPrint('Mensaje marcado como leído: $messageId');
    } catch (e) {
      debugPrint('Error al marcar mensaje como leído: $e');
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      debugPrint('Notificación marcada como leída: $notificationId');
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
    }
  }

  /// Limpieza de suscripciones
  void dispose() {
    _messagesChannel?.unsubscribe();
    _notificationsChannel?.unsubscribe();
  }

  

}