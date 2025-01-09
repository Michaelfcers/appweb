import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';

class ChatScreen extends StatefulWidget {
  final String chatTitle;
  final String barterId;
  final String proposerId; // ID del usuario que propuso el trueque
  final String receiverId; // ID del usuario receptor del trueque

  const ChatScreen({
    super.key,
    required this.chatTitle,
    required this.barterId,
    required this.proposerId,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  late RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _setupRealtimeListener();
  }

  Future<void> _fetchMessages() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('messages')
          .select()
          .eq('barter_id', widget.barterId)
          .order('created_at', ascending: true);

      final fetchedMessages = List<Map<String, dynamic>>.from(response);

      // Identificar y marcar mensajes no leídos
      final unreadMessageIds = fetchedMessages
          .where((msg) =>
              msg['receiver_id'] == userId && msg['is_read'] == false)
          .map((msg) => msg['id'])
          .toList();

      if (unreadMessageIds.isNotEmpty) {
        await _supabase
            .from('messages')
            .update({'is_read': true})
            .in_('id', unreadMessageIds);
      }

      setState(() {
        messages = fetchedMessages;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error al obtener mensajes: $e');
    }
  }

  void _setupRealtimeListener() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = _supabase.channel('public:messages');

    _realtimeChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: 'barter_id=eq.${widget.barterId}',
      ),
      (payload, [ref]) async {
        if (payload == null || payload['new'] == null) return;

        final newMessage = payload['new'] as Map<String, dynamic>;

        // Marcar mensaje como leído si es para el usuario actual
        if (newMessage['receiver_id'] == userId && !newMessage['is_read']) {
          await _supabase
              .from('messages')
              .update({'is_read': true})
              .eq('id', newMessage['id']);
        }

        setState(() {
          messages.add(newMessage);
          messages.sort((a, b) => DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));
        });

        _scrollToBottom();
      },
    );

    try {
      _realtimeChannel.subscribe();
    } catch (e) {
      debugPrint('Error al suscribirse al canal de mensajes: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final senderId = _supabase.auth.currentUser?.id; // ID del remitente
    if (senderId == null) return;

    // Obtén el ID del receptor basado en la lógica de tu aplicación
    final receiverId = obtenerReceiverId(); // Ajusta esto a tu lógica

    if (receiverId == null) {
      debugPrint('Error: El ID del receptor no puede ser NULL');
      return;
    }

    final newMessage = {
      'barter_id': widget.barterId, // ID del trueque o chat
      'sender_id': senderId, // El remitente
      'receiver_id': receiverId, // El receptor
      'message': messageText, // Texto del mensaje
      'is_read': false, // El mensaje comienza como no leído
      'created_at': DateTime.now().toIso8601String(), // Fecha de creación
    };

    try {
      await _supabase.from('messages').insert(newMessage);
      _messageController.clear();
    } catch (e) {
      debugPrint('Error al enviar mensaje: $e');
    }
  }

  String? obtenerReceiverId() {
    final userId = _supabase.auth.currentUser?.id;

    // Determina si el usuario actual es el que propuso el trueque
    if (userId == widget.proposerId) {
      return widget.receiverId; // Si es el proponente, el receptor es el otro
    } else {
      return widget.proposerId; // Si no, es el proponente
    }
  }

  @override
  void dispose() {
    _realtimeChannel.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.chatTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSender =
                    message['sender_id'] == _supabase.auth.currentUser!.id;
                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: BubbleMessage(
                    message: message['message'] ?? '',
                    isSender: isSender,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.iconSelected),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleMessage extends StatelessWidget {
  final String message;
  final bool isSender;

  const BubbleMessage({super.key, required this.message, required this.isSender});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isSender ? AppColors.iconSelected : AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isSender ? const Radius.circular(20) : Radius.zero,
          bottomRight: isSender ? Radius.zero : const Radius.circular(20),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: isSender ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
