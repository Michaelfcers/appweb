import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../styles/colors.dart';
import '../../services/user_service.dart';
import 'book_edit_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;
  final Function(String) onDelete;

  BookDetailsScreen({
    Key? key,
    required this.bookId,
    required this.onDelete,
  }) : super(key: key);

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final UserService _userService = UserService();
  late Future<Book> _bookFuture;
  bool isExpanded = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  void _loadBook() {
    setState(() {
      _bookFuture = _userService.getBookById(widget.bookId);
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            "Eliminar Libro",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            "¿Estás seguro de que deseas eliminar este libro?",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancelar",
                style: TextStyle(color: AppColors.iconSelected),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBook();
              },
              child: Text(
                "Eliminar",
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBook() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _userService.deleteBook(widget.bookId);

      if (!mounted) return;

      widget.onDelete(widget.bookId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Libro eliminado con éxito.",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.cardBackground,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error al eliminar el libro: $e",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Detalles del Libro",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Book>(
        future: _bookFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error al cargar el libro."));
          } else if (!snapshot.hasData) {
            return Center(child: Text("No se encontró el libro."));
          } else {
            final book = snapshot.data!;
            return _buildBookDetails(book);
          }
        },
      ),
    );
  }

  Widget _buildBookDetails(Book book) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen principal del libro
          Container(
            width: 160,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.shadow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.network(
              _sanitizeImageUrl(book.thumbnail),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            book.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Autor y género
          Text(
            "Autor: ${book.author}",
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            "Género: ${book.genre ?? 'Sin género especificado'}",
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Sinopsis
          Text(
            "Sinopsis",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.iconSelected,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            book.description ?? "Sin descripción disponible.",
            textAlign: TextAlign.justify,
            maxLines: isExpanded ? null : 5,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          if (book.description != null && book.description!.length > 100)
            TextButton(
              onPressed: () => setState(() => isExpanded = !isExpanded),
              child: Text(
                isExpanded ? "Ver menos" : "Ver más",
                style: TextStyle(color: AppColors.iconSelected),
              ),
            ),
          const SizedBox(height: 24),

          // Condición
          if (book.condition != null && book.condition!.isNotEmpty) ...[
            Text(
              "Condición",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.iconSelected,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              book.condition!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
          ],

          // Imágenes adicionales
          if (book.photos != null && book.photos!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Imágenes del libro",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.iconSelected,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: book.photos!.length,
                  itemBuilder: (context, index) {
                    final photoUrl = book.photos![index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _sanitizeImageUrl(photoUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: AppColors.textPrimary.withOpacity(0.7),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Botones de Editar y Eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iconSelected,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final updatedBook = await Navigator.push<Book?>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookEditScreen(book: book),
                    ),
                  );

                  if (updatedBook != null) {
                    _loadBook();
                  }
                },
                child: Icon(Icons.edit, color: AppColors.textPrimary, size: 32),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isDeleting ? null : () => _showDeleteConfirmationDialog(context),
                child: _isDeleting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Icon(Icons.delete, color: AppColors.textPrimary, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
