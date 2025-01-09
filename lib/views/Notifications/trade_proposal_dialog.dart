import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TradeProposalDialog extends StatelessWidget {
  final String proposerNickname;
  final String proposerName;
  final String barterId;
  final List<Map<String, dynamic>> books; // Libros ofrecidos
  final Map<String, dynamic>? targetBook; // Libro objetivo (puede ser nulo)
  final String status; // Estado del trueque

  const TradeProposalDialog({
    super.key,
    required this.proposerNickname,
    required this.proposerName,
    required this.barterId,
    required this.books,
    this.targetBook, // Asegúrate de aceptar este parámetro
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
              'Libro objetivo:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            targetBook != null
                ? ListTile(
                    title: Text(
                      targetBook!['title'] ?? 'Título no disponible',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      targetBook!['author'] ?? 'Autor no disponible',
                      style: const TextStyle(fontSize: 12),
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _determineThumbnail(targetBook!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  )
                : const Text(
                    'No se pudo encontrar el libro objetivo.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _determineThumbnail(book),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
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
              : () async {
                  await _respondToProposal(context, barterId, 'accepted');
                },
          child: const Text('Aceptar Trueque'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDecisionMade ? Colors.grey : Colors.red,
          ),
          onPressed: isDecisionMade
              ? null
              : () async {
                  await _respondToProposal(context, barterId, 'rejected');
                },
          child: const Text('Rechazar Trueque'),
        ),
      ],
    );
  }

  Future<void> _respondToProposal(
    BuildContext context, String barterId, String response) async {
  try {
    final supabase = Supabase.instance.client;

    // Verificar si el trueque sigue pendiente
    final barter = await supabase
        .from('barters')
        .select('status, target_book_id')
        .eq('id', barterId)
        .single();

    if (barter == null || barter['status'] != 'pending') {
      _showErrorDialog(
        context,
        'El trueque ya no está disponible para esta acción.',
      );
      return;
    }

    // Actualizar el estado del trueque
    await supabase
        .from('barters')
        .update({'status': response})
        .eq('id', barterId);

    if (response == 'accepted') {
      // Obtener el ID del libro objetivo
      final targetBookId = barter['target_book_id'];
      debugPrint('ID del libro objetivo a deshabilitar: $targetBookId');

      // Bloquear el libro objetivo
      final targetUpdateResponse = await supabase
          .from('books')
          .update({'status': 'disabled'}) // Cambiado a `status`
          .eq('id', targetBookId)
          .select(); // Esto devuelve los datos actualizados

      debugPrint('Resultado actualización libro objetivo: $targetUpdateResponse');

      // Obtener los libros ofrecidos del trueque
      final bookDetails = await supabase
          .from('barter_details')
          .select('book_id')
          .eq('barter_id', barterId);

      for (final bookDetail in bookDetails) {
        final bookId = bookDetail['book_id'];
        debugPrint('Deshabilitando libro ofrecido: $bookId');

        // Bloquear los libros ofrecidos
        final offerUpdateResponse = await supabase
            .from('books')
            .update({'status': 'disabled'}) // Cambiado a `status`
            .eq('id', bookId)
            .select(); // Esto devuelve los datos actualizados

        debugPrint('Resultado actualización libro ofrecido ($bookId): $offerUpdateResponse');
      }
    }

    // Enviar notificación al proponente
    final proposerId = (await supabase
        .from('barters')
        .select('proposer_id')
        .eq('id', barterId)
        .single())['proposer_id'];

    await supabase.from('notifications').insert({
      'user_id': proposerId,
      'type': response == 'accepted' ? 'trade_accepted' : 'trade_rejected',
      'content': response == 'accepted'
          ? 'Tu propuesta de trueque ha sido aceptada.'
          : 'Tu propuesta de trueque ha sido rechazada.',
      'barter_id': barterId,
    });

    if (!context.mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response == 'accepted'
              ? 'Has aceptado el trueque.'
              : 'Has rechazado el trueque.',
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error al procesar el trueque: $e');
    _showErrorDialog(
        context, 'Error al procesar la respuesta al trueque: ${e.toString()}');
  }
}





  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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

  String _determineThumbnail(Map<String, dynamic> book) {
    // Prioriza las imágenes subidas manualmente.
    if (book['photos'] != null && (book['photos'] as List).isNotEmpty) {
      return _sanitizeImageUrl((book['photos'] as List).first);
    }

    // Si no hay imágenes subidas, usa el `cover_url` de la base de datos.
    if (book['cover_url'] != null && (book['cover_url'] as String).isNotEmpty) {
      return _sanitizeImageUrl(book['cover_url']);
    }

    // Si no hay ninguna imagen, usa una imagen predeterminada.
    return 'https://via.placeholder.com/150';
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
  }
}
