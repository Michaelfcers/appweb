import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';
import '../Layout/layout.dart'; // Importamos el Layout
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final response = await _supabase
          .from('barters')
          .select(
              'id, proposer_id, receiver_id, messages (message, created_at, sender_id)')
          .eq('status', 'accepted')
          .or(
            'proposer_id.eq.${_supabase.auth.currentUser!.id},receiver_id.eq.${_supabase.auth.currentUser!.id}',
          );

      if (!mounted) return;

      final List<Map<String, dynamic>> rawChats =
          List<Map<String, dynamic>>.from(response);

      final Map<String, Map<String, dynamic>> groupedChats = {};

      for (var chat in rawChats) {
        final isProposer = chat['proposer_id'] == _supabase.auth.currentUser!.id;
        final otherUserId = isProposer ? chat['receiver_id'] : chat['proposer_id'];

        if (otherUserId == null) continue;

        if (!groupedChats.containsKey(otherUserId)) {
          groupedChats[otherUserId] = {
            'user_id': otherUserId,
            'barter_ids': [chat['id']],
            'messages': chat['messages'] ?? [],
          };
        } else {
          groupedChats[otherUserId]!['barter_ids']!.add(chat['id']);
          groupedChats[otherUserId]!['messages']!.addAll(chat['messages'] ?? []);
        }
      }

      for (final entry in groupedChats.entries) {
        // Ordenamos los mensajes por fecha de creación más reciente
        entry.value['messages']!.sort(
          (a, b) => DateTime.parse(b['created_at'] ?? "")
              .compareTo(DateTime.parse(a['created_at'] ?? "")),
        );
      }

      setState(() {
        chats = groupedChats.values.toList();
      });
    } catch (e) {
      debugPrint('Error al obtener chats: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();
      return response;
    } catch (e) {
      debugPrint('Error al obtener detalles del usuario: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      currentIndex: 0, // Indica que estamos en la pestaña de mensajes
      body: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            "Mensajes",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: chats.isEmpty
            ? const Center(
                child: Text(
                  "No tienes chats disponibles",
                  style: TextStyle(fontSize: 16, color: AppColors.grey),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _fetchUserDetails(chat['user_id']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final user = snapshot.data!;
                      final lastMessage = (chat['messages'] as List).isNotEmpty
                          ? chat['messages'].first['message']
                          : "Sin mensajes aún";
                      final lastTime = (chat['messages'] as List).isNotEmpty
                          ? DateTime.parse(chat['messages'].first['created_at'])
                          : null;

                      return _ChatItem(
                        chatTitle: user['nickname'] ?? 'Usuario',
                        lastMessage: lastMessage,
                        time: lastTime != null
                            ? "${lastTime.hour}:${lastTime.minute.toString().padLeft(2, '0')}"
                            : "N/A",
                        barterId: chat['barter_ids'].first,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _ChatItem extends StatelessWidget {
  final String chatTitle;
  final String lastMessage;
  final String time;
  final String barterId;

  const _ChatItem({
    required this.chatTitle,
    required this.lastMessage,
    required this.time,
    required this.barterId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatTitle: chatTitle, barterId: barterId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.shadow,
              radius: 28,
              child: Icon(Icons.person, color: AppColors.textPrimary, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
