import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/google_books_service.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';

class BookEditScreen extends StatefulWidget {
  final Book book;

  const BookEditScreen({super.key, required this.book});

  @override
  _BookEditScreenState createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _synopsisController;
  late TextEditingController _conditionController;
  late TextEditingController _authorController;
  late TextEditingController _genreController;

  final UserService _userService = UserService();
  final GoogleBooksService _googleBooksService = GoogleBooksService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos actuales del libro
    _titleController = TextEditingController(text: widget.book.title);
    _synopsisController =
        TextEditingController(text: widget.book.description ?? '');
    _conditionController =
        TextEditingController(text: widget.book.condition ?? '');
    _authorController = TextEditingController(text: widget.book.author);
    _genreController = TextEditingController(text: widget.book.genre ?? '');
  }

  @override
  void dispose() {
    // Liberar los controladores al salir de la pantalla
    _titleController.dispose();
    _synopsisController.dispose();
    _conditionController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al servicio para actualizar el libro
      await _userService.updateBook(
        bookId: widget.book.id,
        title: _titleController.text.trim(),
        description: _synopsisController.text.trim(),
        condition: _conditionController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Libro editado con éxito',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.cardBackground,
        ),
      );

      Navigator.pop(context, true); // Indica que se realizaron cambios
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al editar el libro: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchBook(String title) async {
    try {
      final book = await _googleBooksService.fetchBookDetails(title);
      setState(() {
        _authorController.text = book.author;
        _genreController.text = book.genre ?? '';
        _synopsisController.text = book.description ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al buscar el libro: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Editar Libro",
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22),
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
              child: widget.book.thumbnail.isNotEmpty
                  ? Image.network(widget.book.thumbnail, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        '160 x 220',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Campo para el título con búsqueda
            _buildTextField(
              _titleController,
              'Título',
              onChanged: (value) {
                if (value.isNotEmpty) _searchBook(value);
              },
              isEditable: true,
            ),
            const SizedBox(height: 10),

            // Campos no editables
            _buildTextField(_authorController, 'Autor', isEditable: false),
            const SizedBox(height: 10),
            _buildTextField(_genreController, 'Género', isEditable: false),
            const SizedBox(height: 10),
            _buildTextField(
              _synopsisController,
              'Sinopsis',
              isEditable: false,
              maxLines: 3,
            ),

            const SizedBox(height: 10),

            // Campo editable
            _buildTextField(
              _conditionController,
              'Condición',
              isEditable: true,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Botón de Guardar Cambios
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Guardar cambios",
                      style:
                          TextStyle(fontSize: 18, color: AppColors.textPrimary),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    required bool isEditable,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: isEditable,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.iconSelected),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.iconSelected),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.iconSelected),
        ),
      ),
      style: TextStyle(color: AppColors.textPrimary),
    );
  }
}
