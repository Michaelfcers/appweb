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
        final newMessage = payload['new'] as Map<String, dynamic>;
        setState(() {
          messages.add(newMessage);
          messages.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        });
      },
    );

    _realtimeChannel.subscribe();
  }

Future<void> _sendMessage() async {
  final messageText = _messageController.text.trim();
  if (messageText.isEmpty) return;

  final newMessage = {
    'barter_id': widget.barterId,
    'sender_id': _supabase.auth.currentUser!.id,
    'receiver_id': null, // Puedes ajustar esto según el caso
    'message': messageText,
    'created_at': DateTime.now().toIso8601String(),
  };

  setState(() {
    // Añadir el mensaje localmente antes de enviar a la base de datos
    messages.add(newMessage);
    _messageController.clear();
  });

  try {
    // Enviar el mensaje a la base de datos
    await _supabase.from('messages').insert(newMessage);
  } catch (e) {
    debugPrint('Error al enviar mensaje: $e');
    // Opcionalmente, podrías eliminar el mensaje de la lista si la inserción falla
    setState(() {
      messages.remove(newMessage);
    });
  }
}



  @override
  void dispose() {
    _realtimeChannel.unsubscribe();
    _messageController.dispose();
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
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSender = message['sender_id'] == _supabase.auth.currentUser!.id;
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
