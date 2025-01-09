import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, List<Map<String, dynamic>>> tradeHistory = {
    'pending': [],
    'accepted': [],
    'completed': [],
    'rejected': [],
    'cancelled': [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTradeHistory();
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
  }

  Future<void> _fetchTradeHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;

      // Fetch all trade history
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
          .order('created_at', ascending: false);

      final groupedData = {
        'pending': <Map<String, dynamic>>[],
        'accepted': <Map<String, dynamic>>[],
        'completed': <Map<String, dynamic>>[],
        'rejected': <Map<String, dynamic>>[],
        'cancelled': <Map<String, dynamic>>[],
      };

      for (var trade in response as List<dynamic>) {
        final status = trade['status'] as String;
        if (groupedData.containsKey(status)) {
          groupedData[status]!.add(trade as Map<String, dynamic>);
        }
      }

      setState(() {
        tradeHistory = groupedData;
      });
    } catch (e) {
      debugPrint('Error al cargar el historial de trueques: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'accepted':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'completed':
        return 'Completado';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  Widget _buildSection(String status, List<Map<String, dynamic>> trades) {
    return trades.isEmpty
        ? const SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
              ...trades.map((trade) => _buildTradeCard(trade)).toList(),
            ],
          );
  }

  Widget _buildTradeCard(Map<String, dynamic> trade) {
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
          child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
        ),
        title: Text(
          "Trueque con ${user['nickname'] ?? 'Desconocido'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(_getStatusIcon(status), color: _getStatusColor(status)),
            const SizedBox(width: 8),
            Text(
              _getStatusText(status),
              style: TextStyle(color: _getStatusColor(status)),
            ),
          ],
        ),
        onTap: () => _showTradeDetails(trade),
      ),
    );
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
                Text(_getStatusText(trade['status'])),
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
          "Historial de Trueques",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : tradeHistory.values.every((list) => list.isEmpty)
              ? Center(
                  child: Text(
                    "No tienes historial de trueques.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: tradeHistory.entries
                      .map((entry) => _buildSection(entry.key, entry.value))
                      .toList(),
                ),
    );
  }
}
