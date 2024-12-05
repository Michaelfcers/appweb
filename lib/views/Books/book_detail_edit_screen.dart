import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../styles/colors.dart';
import '../../services/user_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  final Function(String) onDelete; // Callback para notificar la eliminación del libro

  const BookDetailsScreen({
    super.key,
    required this.book,
    required this.onDelete,
  });

  @override
  BookDetailsScreenState createState() => BookDetailsScreenState();
}

class BookDetailsScreenState extends State<BookDetailsScreen> {
  final UserService _userService = UserService();
  bool isExpanded = false;
  bool _isDeleting = false;

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
                Navigator.of(context).pop(); // Cierra el diálogo
                _deleteBook(); // Llama a la función de eliminar
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
      await _userService.deleteBook(widget.book.id);

      if (!mounted) return;

      // Notificar al perfil que se eliminó el libro
      widget.onDelete(widget.book.id);

      // Mostrar el SnackBar de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Libro eliminado con éxito.",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.cardBackground,
        ),
      );

      // Regresar a la pantalla anterior
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      // Mostrar el SnackBar con el error
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

  @override
  Widget build(BuildContext context) {
    final Book book = widget.book;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen del libro
            Container(
              width: 160,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.shadow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: book.thumbnail.isNotEmpty
                  ? Image.network(book.thumbnail, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        '160 x 220',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
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

            // Calificación
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Calificación:",
                  style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 24,
                      color: index < (book.rating ?? 4) ? Colors.amber : AppColors.shadow,
                    );
                  }),
                ),
                const SizedBox(width: 5),
                Text(
                  "${book.rating ?? 4.5}/5",
                  style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                ),
              ],
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppColors.iconSelected.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isExpanded ? "Ver menos" : "Ver más",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.iconSelected,
                  ),
                ),
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
                  onPressed: () {
                    // Ir a la pantalla de edición
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
      ),
    );
  }
}
