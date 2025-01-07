import 'package:flutter/material.dart';

class TradeStatusDialog extends StatelessWidget {
  final String proposerNickname;
  final String proposerName;
  final List<Map<String, dynamic>> books;
  final Map<String, dynamic>? targetBook;
  final String statusMessage;

  const TradeStatusDialog({
    Key? key,
    required this.proposerNickname,
    required this.proposerName,
    required this.books,
    this.targetBook,
    required this.statusMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        statusMessage.contains('aceptada') ? 'Trueque Aceptado' : 'Trueque Rechazado',
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
            if (targetBook != null) ...[
              const Text(
                'Libro objetivo:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: targetBook!['cover_url'] != null &&
                        (targetBook!['cover_url'] as String).isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          targetBook!['cover_url'] ?? '',
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
                      )
                    : const Icon(Icons.book, size: 50),
                title: Text(
                  targetBook!['title'] ?? 'Título no disponible',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  targetBook!['author'] ?? 'Autor no disponible',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
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
                        leading: book['cover_url'] != null &&
                                (book['cover_url'] as String).isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  book['cover_url'] ?? '',
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
                              )
                            : const Icon(Icons.book, size: 50),
                        title: Text(
                          book['title'] ?? 'Título no disponible',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          book['author'] ?? 'Autor no disponible',
                          style: const TextStyle(fontSize: 12),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
