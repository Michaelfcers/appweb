import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TradeProposalDialog extends StatelessWidget {
  final String proposerNickname;
  final String proposerName;
  final String barterId;
  final List<Map<String, dynamic>> books;
  final String status; // Estado actual del trueque

  const TradeProposalDialog({
    super.key,
    required this.proposerNickname,
    required this.proposerName,
    required this.barterId,
    required this.books,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDecisionMade = status == 'accepted' || status == 'rejected';

    return AlertDialog(
      title: Text(
        'Propuesta de Trueque',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Proponente: $proposerName ($proposerNickname)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            const Text(
              'Libros ofrecidos:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            books.isNotEmpty
                ? Column(
                    children: books.map((book) {
                      return ListTile(
                        title: Text(
                          book['title'] ?? 'Título no disponible',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          book['author'] ?? 'Autor no disponible',
                          style: const TextStyle(fontSize: 12),
                        ),
                        leading: book['cover_url'] != null
                            ? Image.network(
                                book['cover_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.book, size: 50),
                      );
                    }).toList(),
                  )
                : const Text(
                    'No hay libros ofrecidos.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isDecisionMade
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(
            'Decidir más tarde',
            style: TextStyle(
              color: isDecisionMade ? Colors.grey : Colors.blue,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDecisionMade ? Colors.grey : Colors.green,
          ),
          onPressed: isDecisionMade
              ? null
              : () {
                  _respondToProposal(context, barterId, 'accepted');
                },
          child: const Text('Aceptar Trueque'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDecisionMade ? Colors.grey : Colors.red,
          ),
          onPressed: isDecisionMade
              ? null
              : () {
                  _respondToProposal(context, barterId, 'rejected');
                },
          child: const Text('Rechazar Trueque'),
        ),
      ],
    );
  }

  void _respondToProposal(BuildContext context, String barterId, String response) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('barters').update({'status': response}).eq('id', barterId);

      if (!context.mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 'accepted' ? 'Has aceptado el trueque.' : 'Has rechazado el trueque.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      _showErrorDialog(context, 'Error al procesar la respuesta al trueque.');
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
}
