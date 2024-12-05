import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/google_books_service.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';

class AddBookDialog extends StatefulWidget {
  const AddBookDialog({super.key});

  @override
  _AddBookDialogState createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final UserService _userService = UserService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  String? _thumbnailUrl;
  bool _isLoading = false;
  bool _showFullDescription = false;
  List<Book> _searchResults = [];

  Future<void> _fetchBookDetails(Book book) async {
    setState(() {
      _isLoading = true;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _genreController.text = book.genre ?? '';
      _descriptionController.text = book.description ?? '';
      _thumbnailUrl = book.thumbnail;
      _isLoading = false;
    });
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final books = await _googleBooksService.fetchBooks(query);
      setState(() {
        _searchResults = books;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar libros: $e')),
      );
    }
  }

  Future<void> _addBookToUser() async {
    try {
      if (_titleController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _conditionController.text.trim().isEmpty) {
        throw Exception('Por favor, completa todos los campos obligatorios');
      }

      await _userService.addBookToUser(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        description: _descriptionController.text.trim(),
        thumbnail: _thumbnailUrl ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Libro agregado con éxito')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar el libro: $e')),
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
          "Agregar Libro",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
              child: _thumbnailUrl != null
                  ? Image.network(_thumbnailUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        '160 x 220',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Campo de título con autocompletado
            Autocomplete<Book>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Book>.empty();
                }
                await _searchBooks(textEditingValue.text);
                return _searchResults;
              },
              displayStringForOption: (Book book) => book.title,
              onSelected: (Book selectedBook) {
                _fetchBookDetails(selectedBook);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _titleController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (value) {
                    _searchBooks(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Título',
                    labelStyle: TextStyle(color: AppColors.iconSelected),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.iconSelected),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                );
              },
            ),
            const SizedBox(height: 10),

            // Campos de autor y género (solo lectura)
            _buildReadOnlyField(_authorController, 'Autor'),
            const SizedBox(height: 10),
            _buildReadOnlyField(_genreController, 'Género'),
            const SizedBox(height: 10),

            // Campo de descripción editable
            _buildExpandableDescription(),
            const SizedBox(height: 10),

            // Campo para el estado del libro
            TextField(
              controller: _conditionController,
              decoration: InputDecoration(
                labelText: 'Condición',
                labelStyle: TextStyle(color: AppColors.iconSelected),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.iconSelected),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),

            // Botón de agregar libro
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoading ? null : _addBookToUser,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Agregar Libro",
                      style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.iconSelected),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.iconSelected),
        ),
      ),
      style: TextStyle(color: AppColors.textPrimary),
    );
  }

  Widget _buildExpandableDescription() {
    final isLongDescription = _descriptionController.text.length > 150;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _descriptionController,
          maxLines: _showFullDescription ? null : 6,
          decoration: InputDecoration(
            labelText: 'Descripción / Sinopsis',
            labelStyle: TextStyle(color: AppColors.iconSelected),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.iconSelected),
            ),
          ),
          style: TextStyle(color: AppColors.textPrimary),
        ),
        if (isLongDescription)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showFullDescription = !_showFullDescription;
                });
              },
              child: Text(
                _showFullDescription ? 'Ver menos' : 'Ver más',
                style: TextStyle(color: AppColors.iconSelected),
              ),
            ),
          ),
      ],
    );
  }
}
