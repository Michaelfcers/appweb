import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Para animaciones

import '../../styles/colors.dart';

class TradeManagementScreen extends StatefulWidget {
  const TradeManagementScreen({super.key});

  @override
  State<TradeManagementScreen> createState() => _TradeManagementScreenState();
}

class _TradeManagementScreenState extends State<TradeManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> trades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrades();
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
  }

  Future<void> _fetchTrades() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('barters')
          .select(
              '''
              id, status, proposer_id, receiver_id, target_book_id,
              users!proposer_id(name, nickname, avatar_url),
              books!target_book_id(title, author, cover_url),
              barter_details(book_id, books(title, author, cover_url, status))
              ''')
          .or('proposer_id.eq.$userId,receiver_id.eq.$userId')
          .in_('status', ['pending', 'accepted'])
          .order('created_at', ascending: false);

      setState(() {
        trades = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error al cargar trueques: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsCompleted(String tradeId) async {
    await _executeWithLoading(
      action: () async {
        await _supabase.from('barters').update({'status': 'completed'}).eq('id', tradeId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trueque marcado como completado.')),
        );

        _fetchTrades();
      },
    );
  }

  Future<void> _cancelTrade(String tradeId) async {
    await _executeWithLoading(
      action: () async {
        await _supabase.from('barters').update({'status': 'cancelled'}).eq('id', tradeId);

        final barterDetails = await _supabase
            .from('barter_details')
            .select('book_id')
            .eq('barter_id', tradeId);

        for (final detail in barterDetails) {
          final bookId = detail['book_id'];
          await _supabase.from('books').update({'status': 'enabled'}).eq('id', bookId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trueque cancelado exitosamente.')),
        );

        _fetchTrades();
      },
    );
  }

  Future<void> _executeWithLoading({required Future<void> Function() action}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await action();
    } catch (e) {
      debugPrint('Error durante la operación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error. Intenta nuevamente.')),
      );
    } finally {
      Navigator.of(context).pop(); // Cierra el diálogo de progreso
    }
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      onConfirm();
    }
  }

  void _showTradeDetails(Map<String, dynamic> trade) {
    final targetBook = trade['books'] ?? {};
    final offeredBooks = trade['barter_details'] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalles del Trueque'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(trade['status'] ?? 'No disponible'),
                const SizedBox(height: 10),
                const Text('Libro objetivo:', style: TextStyle(fontWeight: FontWeight.bold)),
                targetBook.isNotEmpty
                    ? ListTile(
                        leading: targetBook['cover_url'] != null
                            ? Image.network(
                                _sanitizeImageUrl(targetBook['cover_url']),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.book, size: 50),
                        title: Text(targetBook['title'] ?? 'Título no disponible'),
                        subtitle: Text(targetBook['author'] ?? 'Autor no disponible'),
                      )
                    : const Text('No hay libro objetivo disponible.'),
                const SizedBox(height: 10),
                const Text('Libros ofrecidos:', style: TextStyle(fontWeight: FontWeight.bold)),
                offeredBooks.isNotEmpty
                    ? Column(
                        children: offeredBooks.map<Widget>((book) {
                          final offeredBook = book['books'] ?? {};
                          return ListTile(
                            leading: offeredBook['cover_url'] != null
                                ? Image.network(
                                    _sanitizeImageUrl(offeredBook['cover_url']),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.book, size: 50),
                            title: Text(offeredBook['title'] ?? 'Título no disponible'),
                            subtitle: Text(offeredBook['author'] ?? 'Autor no disponible'),
                          );
                        }).toList(),
                      )
                    : const Text('No hay libros ofrecidos.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Gestión de Trueques",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : trades.isEmpty
              ? Center(
                  child: Text(
                    "No tienes trueques activos.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    final trade = trades[index];
                    final user = trade['users'] ?? {};
                    final status = trade['status'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['avatar_url'] != null
                              ? NetworkImage(user['avatar_url'])
                              : null,
                          child: user['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          "Trueque con ${user['nickname'] ?? 'Desconocido'}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Estado: $status"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cancel),
                              color: Colors.red,
                              tooltip: 'Cancelar Trueque',
                              onPressed: () {
                                _showConfirmationDialog(
                                  title: 'Cancelar Trueque',
                                  content: '¿Estás seguro de que deseas cancelar este trueque?',
                                  onConfirm: () => _cancelTrade(trade['id']),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle),
                              color: status == 'accepted' ? Colors.green : Colors.grey,
                              tooltip: 'Completar Trueque',
                              onPressed: () {
                                if (status == 'accepted') {
                                  _showConfirmationDialog(
                                    title: 'Completar Trueque',
                                    content: '¿Estás seguro de que deseas marcar este trueque como completado?',
                                    onConfirm: () => _markAsCompleted(trade['id']),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () => _showTradeDetails(trade),
                      ),
                    );
                  },
                ),
    );
  }
}
