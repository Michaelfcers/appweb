import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TradeProposalDialog extends StatelessWidget {
  final String proposerNickname;
  final String proposerName;
  final String barterId;
  final List<Map<String, dynamic>> books;

  const TradeProposalDialog({
    super.key,
    required this.proposerNickname,
    required this.proposerName,
    required this.barterId,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('Construyendo TradeProposalDialog...');
    debugPrint('Proponente: $proposerName ($proposerNickname)');
    debugPrint('Barter ID: $barterId');
    debugPrint('Libros: $books');

    return AlertDialog(
      title: Text(
        'Propuesta de Trueque',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Proponente: $proposerName ($proposerNickname)',
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
          onPressed: () {
            debugPrint('Cerrando el diálogo.');
            Navigator.of(context).pop();
          },
          child: const Text('Decidir más tarde'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            debugPrint('Aceptar Trueque presionado.');
            _respondToProposal(context, barterId, 'accepted');
          },
          child: const Text('Aceptar Trueque'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            debugPrint('Rechazar Trueque presionado.');
            _respondToProposal(context, barterId, 'rejected');
          },
          child: const Text('Rechazar Trueque'),
        ),
      ],
    );
  }

  void _respondToProposal(BuildContext context, String barterId, String response) async {
    debugPrint('Procesando respuesta al trueque...');
    debugPrint('Barter ID: $barterId');
    debugPrint('Respuesta: $response');

    try {
      final supabase = Supabase.instance.client;

      // Actualizar el estado del trueque en la base de datos
      await supabase.from('barters').update({'status': response}).eq('id', barterId);

      if (!context.mounted) {
        debugPrint('Contexto no está montado, cancelando operación.');
        return;
      }

      Navigator.of(context).pop(); // Cierra el diálogo

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 'accepted'
                ? 'Has aceptado el trueque.'
                : 'Has rechazado el trueque.',
          ),
        ),
      );

      debugPrint('Respuesta procesada exitosamente.');
    } catch (e) {
      debugPrint('Error al procesar la respuesta al trueque: $e');

      if (!context.mounted) {
        debugPrint('Contexto no está montado, cancelando operación.');
        return;
      }

      _showErrorDialog(context, 'Error al procesar la respuesta al trueque.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    debugPrint('Mostrando diálogo de error con mensaje: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Cerrando diálogo de error.');
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
