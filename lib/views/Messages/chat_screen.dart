import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';

class ChatScreen extends StatefulWidget {
  final String chatTitle;
  final String barterId;

  const ChatScreen({super.key, required this.chatTitle, required this.barterId});

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
      final response = await _supabase
          .from('messages')
          .select()
          .eq('barter_id', widget.barterId)
          .order('created_at', ascending: true);

      setState(() {
        messages = List<Map<String, dynamic>>.from(response);
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error al obtener mensajes: $e');
    }
  }

  void _setupRealtimeListener() {
    _realtimeChannel = _supabase.channel('public:messages');

    _realtimeChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: 'barter_id=eq.${widget.barterId}',
      ),
      (payload, [ref]) {
        debugPrint('Nuevo mensaje recibido: $payload');
        final newMessage = payload['new'] as Map<String, dynamic>;

        // Verifica si el mensaje ya está en la lista para evitar duplicados
        final messageExists = messages.any((message) => message['id'] == newMessage['id']);

        if (!messageExists) {
          setState(() {
            messages.add(newMessage);
            messages.sort((a, b) => DateTime.parse(a['created_at'])
                .compareTo(DateTime.parse(b['created_at'])));
          });
          _scrollToBottom();
        }
      },
    );

    try {
      _realtimeChannel.subscribe();
    } catch (error) {
      debugPrint('Error al suscribirse al canal: $error');
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

    final newMessage = {
      'barter_id': widget.barterId,
      'sender_id': _supabase.auth.currentUser!.id,
      'receiver_id': null,
      'message': messageText,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase
          .from('messages')
          .insert(newMessage)
          .select()
          .single(); // Selecciona el mensaje insertado.
    } catch (e) {
      debugPrint('Error al enviar mensaje: $e');
    } finally {
      setState(() {
        _messageController.clear();
      });
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
                  alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
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
