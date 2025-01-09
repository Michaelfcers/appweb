import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/book_model.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _existingPhotos = [];
  List<File> _newPhotos = [];
  List<String> _deletedPhotos = [];
  List<String> _genres = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _synopsisController = TextEditingController(text: widget.book.description ?? '');
    _conditionController = TextEditingController(text: widget.book.condition ?? '');
    _authorController = TextEditingController(text: widget.book.author);
    _genreController = TextEditingController(text: widget.book.genre ?? '');

    // Sanitizar URLs de imágenes existentes
    _existingPhotos = widget.book.photos?.map(_sanitizeImageUrl).toList() ?? [];

    // Cargar géneros desde la base de datos
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    try {
      _genres = await _userService.fetchGenresFromDatabase();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los géneros: $e')),
      );
    }
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    _conditionController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _imagePicker.pickMultiImage();
    if (images != null) {
      setState(() {
        _newPhotos.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _removePhoto(String photoUrl) {
    setState(() {
      _existingPhotos.remove(photoUrl);
      _deletedPhotos.add(photoUrl);
    });
  }

  void _removeNewPhoto(File photo) {
    setState(() {
      _newPhotos.remove(photo);
    });
  }

  Future<void> _saveChanges() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Subir las nuevas imágenes
    List<String> uploadedPhotos = [];
    for (File photo in _newPhotos) {
      final String imageUrl = await _userService.uploadImageToStorage(
        photo.path,
        'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      uploadedPhotos.add(imageUrl);
    }

    // Actualizar el libro, incluyendo autor y género
    await _userService.updateBook(
      bookId: widget.book.id,
      title: _titleController.text.trim(),
      description: _synopsisController.text.trim(),
      condition: _conditionController.text.trim(),
      author: _authorController.text.trim(), // Autor añadido
      genre: _genreController.text.trim(),   // Género añadido
      photos: [..._existingPhotos, ...uploadedPhotos],
      deletedPhotos: _deletedPhotos,
    );

    final updatedBook = Book(
      id: widget.book.id,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      thumbnail: widget.book.thumbnail,
      genre: _genreController.text.trim(),
      description: _synopsisController.text.trim(),
      condition: _conditionController.text.trim(),
      userId: widget.book.userId,
      photos: [..._existingPhotos, ...uploadedPhotos],
    );

    if (!mounted) return;

    await _showSaveSuccessDialog();
    Navigator.pop(context, updatedBook);
  } catch (e) {
    if (!mounted) return;
    await _showSaveErrorDialog();
  } finally {
    setState(() {
      _isLoading = false;
    });
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
            // Imagen del libro (thumbnail)
            Container(
              width: 160,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.shadow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _existingPhotos.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _existingPhotos.first, // Usa la primera imagen como principal
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
                    )
                  : Center(
                      child: Icon(
                        Icons.book,
                        size: 50,
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
            ),

            // Campos de texto
            _buildTextField(_titleController, 'Título', isEditable: true),
            const SizedBox(height: 10),
            _buildTextField(_authorController, 'Autor', isEditable: true),
            const SizedBox(height: 10),
            _buildGenreField(_genreController), // Campo de Género
            const SizedBox(height: 10),
            _buildTextField(
              _synopsisController,
              'Sinopsis',
              isEditable: true,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              _conditionController,
              'Condición',
              isEditable: true,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Gestión de imágenes existentes
            if (_existingPhotos.isNotEmpty) ...[
              Text(
                "Imágenes existentes",
                style: TextStyle(
                  fontSize: 18,
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
                itemCount: _existingPhotos.length,
                itemBuilder: (context, index) {
                  final photoUrl = _existingPhotos[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removePhoto(photoUrl),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Subir nuevas imágenes
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.upload_file),
              label: const Text("Subir Imágenes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
              ),
            ),

            if (_newPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _newPhotos.length,
                itemBuilder: (context, index) {
                  final photo = _newPhotos[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          photo,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeNewPhoto(photo),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Botón de guardar cambios
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Guardar cambios",
                      style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreField(TextEditingController controller) {
    return GestureDetector(
      onTap: () => _showGenreSelector(controller),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Seleccionar Género',
            labelStyle: TextStyle(color: AppColors.iconSelected),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.iconSelected),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.iconSelected,
            ),
          ),
        ),
      ),
    );
  }

  void _showGenreSelector(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona un Género',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            controller.text = genre;
                          });
                          Navigator.pop(context); // Cierra el modal
                        },
                        child: Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.cardBackground,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            child: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSaveSuccessDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.dialogBackground,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              "Éxito",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.dialogTitleText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "El libro se guardó con éxito.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.dialogBodyText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Aceptar",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFF1EFE7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildTextField(
    TextEditingController controller,
    String label, {
    required bool isEditable,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: isEditable,
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
      style: const TextStyle(color: Colors.black),
    );
  }
  Future<void> _showSaveErrorDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.dialogBackground,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              "Error",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.dialogTitleText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No se pudo guardar el libro. Por favor, intenta de nuevo.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.dialogBodyText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Aceptar",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFF1EFE7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
