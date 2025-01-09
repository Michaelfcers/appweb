import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';
import 'trade_proposal_dialog.dart';
import '../../services/user_service.dart';
import '../Notifications/trade_status_dialog.dart';


class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  List<Map<String, dynamic>> notifications = [];
  late RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupRealtimeListener();
  }


  Future<void> _fetchNotifications() async {
  try {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('read', ascending: true) // No leídas primero
        .order('created_at', ascending: false); // Más recientes primero dentro de cada grupo

    if (!mounted) return;

    setState(() {
      notifications = List<Map<String, dynamic>>.from(response);
    });

    debugPrint('Notificaciones obtenidas: $notifications');
  } catch (e) {
    debugPrint('Error al obtener notificaciones: $e');
  }
}



  void _setupRealtimeListener() {
  _realtimeChannel = _supabase.channel('public:notifications');

  _realtimeChannel.on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'notifications',
      filter: 'user_id=eq.${_supabase.auth.currentUser?.id}',
    ),
    (payload, [ref]) {
      if (payload == null || payload['new'] == null) {
        debugPrint('Payload vacío o inválido.');
        return;
      }

      final newNotification = payload['new'] as Map<String, dynamic>;
      if (!mounted) return;

      setState(() {
        // Agregar la nueva notificación al inicio
        notifications.insert(0, newNotification);
      });

      // Mostrar mensaje emergente para la nueva notificación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nueva notificación: ${newNotification['content']}'),
        ),
      );
    },
  );

  // Suscribirse al canal (no asignar el resultado ya que devuelve void)
  try {
    _realtimeChannel.subscribe();
  } catch (e) {
    debugPrint('Error al suscribirse al canal de notificaciones: $e');
  }
}




  Future<void> _markAsRead(String notificationId) async {
  try {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);

    if (!mounted) return;

    setState(() {
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['read'] = true;
      }
    });

    debugPrint('Notification marked as read: $notificationId');
  } catch (e) {
    debugPrint('Error marking notification as read: $e');
  }
}


  Future<void> _openTradeProposalDialog(Map<String, dynamic> notification) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final tradeDetails = await _userService.fetchTradeDetails(notification['id']);
      Navigator.of(context).pop(); // Cierra el indicador de carga

      debugPrint('Detalles obtenidos: $tradeDetails');
      if (!mounted) return;

      final books = List<Map<String, dynamic>>.from(tradeDetails['books']);
      final barterStatus = tradeDetails['barter']['status'];
      final proposerName = tradeDetails['proposer']['name'];
      final proposerNickname = tradeDetails['proposer']['nickname'];
      final targetBook = tradeDetails['targetBook'];


      if (notification['type'] == 'trade_request') {
        // Mostrar el diálogo de propuesta
        showDialog(
          context: context,
          builder: (context) => TradeProposalDialog(
            proposerNickname: proposerNickname,
            proposerName: proposerName,
            barterId: tradeDetails['barter']['id'],
            books: books,
            targetBook: targetBook, // Pasa el libro objetivo
            status: barterStatus,
          ),
        );
      } else {
        // Mostrar el diálogo para 'trade_accepted' o 'trade_rejected'
        final String statusMessage = notification['type'] == 'trade_accepted'
            ? 'Tu propuesta de trueque ha sido aceptada.'
            : 'Tu propuesta de trueque ha sido rechazada.';

        showDialog(
          context: context,
          builder: (context) => TradeStatusDialog(
            proposerNickname: proposerNickname,
            proposerName: proposerName,
            books: books,
            targetBook: targetBook,
            statusMessage: statusMessage,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el indicador de carga en caso de error
      debugPrint('Error al abrir el diálogo: $e');
      _showErrorDialog(context, 'No se pudo abrir los detalles del trueque.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'trade_request':
        return Icons.mail;
      case 'trade_accepted':
        return Icons.thumb_up;
      case 'trade_rejected':
        return Icons.thumb_down;
      default:
        return Icons.notifications;
    }
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'trade_request':
        return 'Nueva solicitud de trueque';
      case 'trade_accepted':
        return 'Tu trueque ha sido aceptado';
      case 'trade_rejected':
        return 'Tu trueque ha sido rechazado';
      default:
        return 'Notificación';
    }
  }

  @override
  void dispose() {
    _supabase.removeChannel(_realtimeChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Notificaciones",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                "No tienes notificaciones",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationCard(
                  icon: _getIconForType(notification['type']),
                  title: _getTitleForType(notification['type']),
                  subtitle: notification['content'] ?? '',
                  isRead: notification['read'],
                  type: notification['type'], // Pasar el tipo aquí
                  onTap: () {
                    debugPrint('Notificación seleccionada: $notification');
                    if (!notification['read']) {
                      _markAsRead(notification['id']);
                    }
                    _openTradeProposalDialog(notification);
                  },
                );
              },
            ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isRead;
  final String type; // Nuevo: para determinar el tipo
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isRead,
    required this.type, // Pasamos el tipo
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar color de fondo según el estado y tipo
    Color backgroundColor;
    if (type == 'trade_accepted') {
      backgroundColor = Colors.green[100]!;
    } else if (type == 'trade_rejected') {
      backgroundColor = Colors.red[100]!;
    } else {
      backgroundColor = isRead ? Colors.grey[200]! : Colors.white;
    }

    // Determinar color del borde
    Color borderColor = isRead
        ? Colors.grey
        : (type == 'trade_accepted'
            ? Colors.green
            : (type == 'trade_rejected' ? Colors.red : Colors.blue));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isRead ? Colors.grey : borderColor,
          size: 30,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isRead ? Colors.grey[700] : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
